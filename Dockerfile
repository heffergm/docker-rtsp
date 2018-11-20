FROM ubuntu:18.04

RUN apt-get update && \
    apt-get install -y \
      gstreamer1.0-rtsp \
      gstreamer1.0-tools \
      gstreamer1.0-plugins-good \
      gstreamer1.0-plugins-ugly \
      gstreamer1.0-libav \
      libgstrtspserver-1.0-dev

ADD ./app /app

CMD ["echo"]
