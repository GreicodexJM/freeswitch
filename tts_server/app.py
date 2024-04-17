#!/usr/bin/env python
import asyncio
import websockets
from gtts import gTTS
import argparse
import os
from functools import partial
import base64
import io
from pydub import AudioSegment

async def speak(websocket, path, language):
    async for message in websocket:
        content_type = websocket.request_headers.get('Content-Type', 'text/plain')
        accept_format = websocket.request_headers.get('Accept', 'audio/sln16')
        
        print(f"Received message: {message}")
        print(f"Headers Received - Content-Type: {content_type}, Accept: {accept_format}")
        
        try:
            if content_type == "application/ssml+xml":
                # Process the SSML message if needed
                # For simplicity, we assume gTTS can handle SSML directly in this pseudo-code
                print("Processing SSML input.")
                tts = gTTS(text=message, lang=language, slow=False, tld='com', lang_check=False)
            else:
                print("Processing plain text input.")
                tts = gTTS(text=message, lang=language)

            buffer_ = io.BytesIO()
            tts.write_to_fp(buffer_)
            buffer_.seek(0)

            audio = AudioSegment.from_file(buffer_, format='mp3')
            buffer2_ = io.BytesIO()
            if 'sln16' in accept_format:
                print(f"Converting to signed 16bit pcm audio 8000hz")
                audio.export(buffer2_, format='s16', codec='pcm_s16le', parameters=["-ar", "8000"])
            else:
                print(f"Converting to mp3 audio")
                audio.export(buffer2_, format='mp3')

            buffer2_.seek(0)
            audio_data = buffer2_.read()
            print(f"Generated audio length: {len(audio_data)} bytes")

            # Send base64-encoded audio data
            await websocket.send(audio_data)
            print(f"Sent audio data for: {message[:30]}... (truncated for log)")
        except Exception as e:
            print(f"Error during text-to-speech conversion: {e}")
            await websocket.send("Error converting text to speech")

async def main():
    parser = argparse.ArgumentParser(description="WebSocket server with text-to-speech")
    parser.add_argument("--port", type=int, default=int(os.getenv("PORT", 2600)), help="TCP port for the server")
    parser.add_argument("--host", type=str, default=os.getenv("HOST", "0.0.0.0"), help="Host IP for the server")
    parser.add_argument("--lang", type=str, default=os.getenv("TTS_LANG", "en"), help="TTS language voice to use")
    args = parser.parse_args()
    
    print(f"Starting TTS server on {args.host}:{args.port} with language: {args.lang}")
    async with websockets.serve(partial(speak, language=args.lang), args.host, args.port):
        await asyncio.Future()  # run server forever

if __name__ == "__main__":
    asyncio.run(main())
