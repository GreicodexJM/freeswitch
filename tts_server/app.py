#!/usr/bin/env python
import asyncio
import websockets
from gtts import gTTS
import argparse
import os
from functools import partial
import base64
import struct
import io
from pydub import AudioSegment

async def speak(websocket, path, language):
    async for message in websocket:
        print(f"Got messsage {message}")
        try:            
            print(f"Convert text to speech using gTTS")
            tts = gTTS(text=message, lang=language)

            # Simulate sending the audio data (replace with actual transmission logic)
            print(f"Sending audio data for: {message}")
            # Convert audio data to base64 string for efficient transmission                                    
            buffer_ = io.BytesIO()
            tts.write_to_fp(buffer_)
            buffer_.seek(0)

            buffer2_ = io.BytesIO()
            AudioSegment.from_mp3(buffer_).export(buffer2_, format='sln16')

            await websocket.send(buffer2_)
        except Exception as e:
            print(f"Error during text-to-speech conversion: {e}")
            await websocket.send("Error converting text to speech")


async def main():
    parser = argparse.ArgumentParser(description="WebSocket server with text-to-speech")
    parser.add_argument("--port", type=int, default=int(os.getenv("PORT", 2600)), help="TCP port for the server")
    parser.add_argument("--host", type=str, default=os.getenv("HOST", "0.0.0.0"), help="Host IP for the server")
    parser.add_argument("--lang", type=str, default=os.getenv("TTS_LANG","en"), help="TTS language voice to user")
    args = parser.parse_args()
    print(f"Starting TTS server on {args.host}:{args.port} with language:{args.lang}")
    async with websockets.serve(partial(speak,language=args.lang), args.host, args.port):
        await asyncio.Future()  # run server forever

if __name__ == "__main__":
    asyncio.run(main())

