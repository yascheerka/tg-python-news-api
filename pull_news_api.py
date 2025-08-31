import os
import hmac
import asyncio
from datetime import datetime, timedelta, timezone
from typing import List, Optional, Dict, Any

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, Query, Depends, WebSocket, WebSocketDisconnect
from pydantic import BaseModel
from telethon import TelegramClient, errors, events
from telethon.sessions import StringSession
from telethon.tl.types import Message

# Load env
load_dotenv()

# ---------- Config ----------
API_ID = int(os.getenv("TELEGRAM_API_ID", "0"))
API_HASH = os.getenv("TELEGRAM_API_HASH", "")
SESSION_STRING = os.getenv("TELEGRAM_SESSION_STRING", "")
SECRET_KEY = os.getenv("SECRET_KEY", "")

if not API_ID or not API_HASH or not SESSION_STRING:
    raise RuntimeError("Set TELEGRAM_API_ID, TELEGRAM_API_HASH, TELEGRAM_SESSION_STRING in .env")
if not SECRET_KEY:
    raise RuntimeError("Set SECRET_KEY in .env")

# ---------- App ----------
app = FastAPI(title="Telegram News Fetcher", version="2.0.0")
client: Optional[TelegramClient] = None  # shared Telethon client

# ---------- Models ----------
class FetchResult(BaseModel):
    channel: Optional[str]
    channel_id: Optional[int]
    message_id: int
    date: str
    text: str
    matched_terms: List[str]

# ---------- Helpers ----------
def iso(dt: Optional[datetime]) -> Optional[str]:
    if not dt:
        return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc).isoformat()

def clean_terms(q: Optional[str]) -> List[str]:
    if not q:
        return []
    parts = [t.strip() for t in q.split(",")]
    return [p for p in parts if p]

def text_of(msg: Message) -> str:
    return (msg.message or "").strip()

def matches(text: str, terms: List[str]) -> List[str]:
    if not terms:
        return []
    t_lower = text.lower()
    return [t for t in terms if t.lower() in t_lower]

async def resolve_entity(handle: str):
    return await client.get_entity(handle.strip())

# ---------- Auth ----------
def require_key(key: str = Query(..., description="Secret key for access")):
    if not hmac.compare_digest(str(key), str(SECRET_KEY)):
        raise HTTPException(status_code=401, detail="Unauthorized: invalid key")

async def ws_verify_key(websocket: WebSocket) -> bool:
    # WebSockets don't use normal dependencies the same way; manual check
    key = websocket.query_params.get("key", "")
    return hmac.compare_digest(str(key), str(SECRET_KEY))

# ---------- Fetch (REST) ----------
async def fetch_channel(
    handle: str,
    since: datetime,
    limit: Optional[int],
    terms: List[str],
) -> List[Dict[str, Any]]:
    out: List[Dict[str, Any]] = []
    try:
        entity = await resolve_entity(handle)
    except Exception:
        return out

    ch_username = getattr(entity, "username", None)
    ch_id = getattr(entity, "id", None)

    try:
        async for msg in client.iter_messages(entity, limit=limit, reverse=False):
            if msg.date and msg.date < since:
                break
            txt = text_of(msg)
            if not txt:
                continue
            hit = matches(txt, terms)
            if terms and not hit:
                continue
            out.append({
                "channel": ch_username,
                "channel_id": ch_id,
                "message_id": msg.id,
                "date": iso(msg.date),
                "text": txt,
                "matched_terms": hit,
            })
    except (errors.FloodWaitError, errors.ChannelPrivateError, errors.ChatAdminRequiredError):
        pass
    except Exception:
        pass

    return out

@app.get("/fetch", response_model=List[FetchResult], dependencies=[Depends(require_key)])
async def fetch(
    channels: str = Query(..., description="Comma-separated list, e.g. @bbcbreaking,@reuters"),
    days: int = Query(7, ge=1, le=365, description="Lookback window in days"),
    q: Optional[str] = Query(None, description="Comma-separated search terms, e.g. TSLA,Elon"),
    limit: Optional[int] = Query(None, ge=1, le=2000, description="Max messages per channel"),
):
    if not client:
        raise HTTPException(status_code=500, detail="Telegram client not ready.")
    handles = [h.strip() for h in channels.split(",") if h.strip()]
    if not handles:
        raise HTTPException(status_code=400, detail="Provide at least one channel in 'channels'.")
    since = datetime.now(timezone.utc) - timedelta(days=days)
    terms = clean_terms(q)
    tasks = [fetch_channel(h, since, limit, terms) for h in handles]
    results_nested = await asyncio.gather(*tasks, return_exceptions=False)
    flat: List[Dict[str, Any]] = [item for sub in results_nested for item in sub]
    flat.sort(key=lambda x: x.get("date") or "", reverse=True)
    return flat

# ---------- Live stream (WebSocket) ----------
@app.websocket("/ws")
async def ws_stream(websocket: WebSocket):
    if not await ws_verify_key(websocket):
        # Policy violation / unauthorized
        await websocket.close(code=1008)
        return

    await websocket.accept()

    # Parse params
    channels = websocket.query_params.get("channels", "")
    q = websocket.query_params.get("q", None)
    terms = clean_terms(q)

    handles = [h.strip() for h in channels.split(",") if h.strip()]
    if not handles:
        await websocket.send_json({"error": "Provide at least one channel via ?channels=@a,@b"})
        await websocket.close(code=1008)
        return

    # Resolve entities once
    try:
        entities = []
        for h in handles:
            try:
                ent = await resolve_entity(h)
                entities.append(ent)
            except Exception:
                # Skip unresolved/forbidden channels
                await websocket.send_json({"warning": f"Cannot access/resolve {h}"})
        if not entities:
            await websocket.send_json({"error": "No resolvable channels"})
            await websocket.close(code=1011)
            return
    except Exception as e:
        await websocket.send_json({"error": f"Resolve failed: {e}"})
        await websocket.close(code=1011)
        return

    # Per-connection handler
    closed = False

    async def send_safe(payload: Dict[str, Any]):
        nonlocal closed
        if closed:
            return
        try:
            await websocket.send_json(payload)
        except Exception:
            closed = True
            # remove handler below via finally in outer try/finally

    @events.register(events.NewMessage(chats=entities))
    async def on_new_message(event: events.NewMessage.Event):
        msg: Message = event.message
        txt = text_of(msg)
        if not txt:
            return
        if terms:
            hit = matches(txt, terms)
            if not hit:
                return
        else:
            hit = []

        chat = await event.get_chat()
        payload = {
            "channel": getattr(chat, "username", None),
            "channel_id": getattr(chat, "id", None),
            "message_id": msg.id,
            "date": iso(msg.date),
            "text": txt,
            "matched_terms": hit,
            "type": "new_message",
        }
        await send_safe(payload)

    # Optional: stream message edits too (comment in if wanted)
    # @events.register(events.MessageEdited(chats=entities))
    # async def on_edit(event: events.MessageEdited.Event):
    #     msg: Message = event.message
    #     txt = text_of(msg)
    #     if not txt:
    #         return
    #     if terms and not matches(txt, terms):
    #         return
    #     chat = await event.get_chat()
    #     payload = {
    #         "channel": getattr(chat, "username", None),
    #         "channel_id": getattr(chat, "id", None),
    #         "message_id": msg.id,
    #         "date": iso(msg.date),
    #         "text": txt,
    #         "matched_terms": matches(txt, terms) if terms else [],
    #         "type": "edit",
    #     }
    #     await send_safe(payload)

    # Attach handler(s)
    client.add_event_handler(on_new_message)
    # client.add_event_handler(on_edit)

    # Let the connection live until client disconnects.
    try:
        # You can optionally receive pings from client; otherwise just sleep.
        while not closed:
            await asyncio.sleep(30)
    except WebSocketDisconnect:
        pass
    finally:
        closed = True
        try:
            client.remove_event_handler(on_new_message)
            # client.remove_event_handler(on_edit)
        except Exception:
            pass
        await websocket.close()

# ---------- Lifecycle ----------
@app.on_event("startup")
async def startup_event():
    global client
    session = StringSession(SESSION_STRING)
    client = TelegramClient(session, API_ID, API_HASH)
    await client.connect()
    if not await client.is_user_authorized():
        raise RuntimeError("Telethon not authorized. Regenerate TELEGRAM_SESSION_STRING.")

@app.on_event("shutdown")
async def shutdown_event():
    if client:
        await client.disconnect()
