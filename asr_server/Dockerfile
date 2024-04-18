#FROM python:alpine
FROM alphacep/kaldi-es

WORKDIR /opt/vosk-server/websocket
#RUN apk add --no-cache ffmpeg 
RUN apt update -y && apt install -y ffmpeg 
COPY requirements.txt /opt/vosk-server/
RUN pip install --no-cache-dir -r /opt/vosk-server/requirements.txt

COPY asr_server.py /opt/vosk-server/websocket/asr_server.py
ENV VOSK_SERVER_PORT=2700
ENV VOSK_SERVER_INTERFACE=0.0.0.0
ENV VOSK_MODEL_PATH='model'
ENV VOSK_SPK_MODEL_PATH=''
ENV VOSK_SAMPLE_RATE=8000
ENV VOSK_ALTERNATIVES=0
ENV VOSK_SHOW_WORDS=1
RUN chmod +x /opt/vosk-server/websocket/asr_server.py
