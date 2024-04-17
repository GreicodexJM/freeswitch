FROM python:alpine

WORKDIR /usr/src/app
RUN apk add --no-cache ffmpeg 
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY . .
ENV PORT=2600
ENV HOST=0.0.0.0
ENV TTS_LANG=en
CMD [ "python", "./app.py" ]