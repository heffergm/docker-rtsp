#!/usr/bin/env bash

count=40
nap=1
ports="8547"
hostname="hostname.something.com"

while [[ ${count} -gt 0 ]]; do
  random=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

  for port in $ports; do
    sudo docker run -d heffergm/rtsp /app/rtsp-client-record.sh --rtsp-url=rtsp://$hostname:$port/$random --video=true --audio=false

    sleep 0.5

    sudo docker run -d heffergm/rtsp /app/rtsp-client-player.sh --rtsp-url=rtsp://$hostname:$port/$random --video=true --audio=false
   done

  sleep ${nap}

  echo "Running clients: $(sudo docker ps | grep client | wc -l)"
done
