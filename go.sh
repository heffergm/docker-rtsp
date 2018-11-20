#!/usr/bin/env bash

count=40
nap=5
ports="8547"
hostname="hostname.something.com"

while [[ ${count} -gt 0 ]]; do
  if [[ ${count} -gt 10 ]]; then
    let "count-=10"
    batch=10
  else
    batch=${count}
    let "count-=10"
  fi

  while [[ ${batch} -gt 0 ]]; do
    random=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
    let "batch-=1"

    for port in $ports; do
      sudo docker run -d heffergm/rtsp /app/rtsp-client-record.sh --rtsp-url=rtsp://$hostname:$port/$random --video=true --audio=false

      sleep 1

      sudo docker run -d heffergm/rtsp /app/rtsp-client-player.sh --rtsp-url=rtsp://$hostname:$port/$random --video=true --audio=false
     done
  done

  if [[ ${count} -gt 0 ]]; then
    sleep ${nap}
  fi

  echo "Running clients: $(sudo docker ps | grep client | wc -l)"
done
