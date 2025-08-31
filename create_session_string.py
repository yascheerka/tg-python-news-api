import os
from dotenv import load_dotenv
from telethon import TelegramClient
from telethon.sessions import StringSession
from telethon import errors

# Load from .env
load_dotenv()

API_ID = int(os.getenv("TELEGRAM_API_ID", "0"))
API_HASH = os.getenv("TELEGRAM_API_HASH", "")
PHONE = os.getenv("TELEGRAM_PHONE", "")

if not API_ID or not API_HASH or not PHONE:
    raise RuntimeError("Please set TELEGRAM_API_ID, TELEGRAM_API_HASH, TELEGRAM_PHONE in .env")

async def main():
    # Start a temporary client with StringSession
    async with TelegramClient(StringSession(), API_ID, API_HASH) as client:
        if not await client.is_user_authorized():
            try:
                await client.send_code_request(PHONE)
                code = input("Enter the login code you received: ").strip()
                try:
                    await client.sign_in(PHONE, code)
                except errors.SessionPasswordNeededError:
                    pw = input("Two-step password: ").strip()
                    await client.sign_in(password=pw)
            except Exception as e:
                print(f"Login failed: {e}")
                return

        session_string = client.session.save()
        print("\n✅ Copy this and put it in your .env as TELEGRAM_SESSION_STRING:\n")
        print(session_string)

if __name__ == "__main__":
    import asyncio
    asyncio.run(main())
