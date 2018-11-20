#!/bin/sh
set -eu

# example rtsp url: rtsps://user:pass@127.0.0.1:8556/test1234
RTSP_URL=
TRANSPORT=tcp
TLS_OPTS=
WITH_AUDIO=false
WITH_VIDEO=true
SCREEN_CAP=false
AUDIO_BUF_MS=400
RTSP_DEBUG=
SHOW_HELP=false

#VIDEO_SRC="autovideosrc"
#AUDIO_SRC="autoaudiosrc"
VIDEO_SRC="videotestsrc"
AUDIO_SRC="audiotestsrc"
SCREENCAP_SRC="avfvideosrc capture-screen=true capture-screen-cursor=true ! videoscale"

while [ $# -gt 0 ]; do
	PARAM=${1%%=*}
	VALUE=${1#*=}
	case "$PARAM" in
		--rtsp-url)   RTSP_URL=$VALUE ;;
		--transport)  TRANSPORT=$VALUE ;;
		--insecure)   TLS_OPTS=tls-validation-flags=0x58 ;;  # only expired, revoked
		--audio)      WITH_AUDIO=$VALUE ;;
		--video)      WITH_VIDEO=$VALUE ;;
		--screen-cap) VIDEO_SRC=$SCREENCAP_SRC ;;
		--audio-buf)  AUDIO_BUF_MS=$VALUE ;;
		--rtsp-debug) RTSP_DEBUG=debug=1 ;;
		--help | -h)  SHOW_HELP=true  ;;
		*) printf "ERROR: unrecognized option '$1'\n" 1>&2 ; exit 1 ;;
	esac
	shift
done

if $SHOW_HELP || [ -z "$RTSP_URL" ]; then
	echo "USAGE: $0 --rtsp-url=<url> [--transport=<type>] [--insecure]" \
	     "[--audio=true] [--video=false] [--screen-cap] [--audio-buf=<ms> [--rtsp-debug]" 1>&2
	exit 1
fi
if [ true != "$WITH_AUDIO" ] && [ false != "$WITH_AUDIO" ]; then
	printf "ERROR: audio must be true or false\n" 1>&2
	exit 1
fi
if [ true != "$WITH_VIDEO" ] && [ false != "$WITH_VIDEO" ]; then
	printf "ERROR: video must be true or false\n" 1>&2
	exit 1
fi

if [ Darwin = "$(uname)" ]; then
	AUDIO_SRC="osxaudiosrc latency-time=20000 buffer-time=${AUDIO_BUF_MS}000"
fi

X264_OPTS="bitrate=1024 key-int-max=30 tune=zerolatency speed-preset=fast threads=1"
VIDEO_CAPS="video/x-h264,profile=baseline,width=1280,height=720,framerate=30/1"
#VIDEO_PIPELINE="$VIDEO_SRC ! queue ! x264enc $X264_OPTS ! $VIDEO_CAPS ! rsink."
VIDEO_PIPELINE="filesrc location=/app/test.mp4 ! qtdemux ! video/x-h264 ! queue ! rsink."
AUDIO_PIPELINE="$AUDIO_SRC ! queue ! audioresample ! mulawenc ! rsink."

if ! $WITH_AUDIO; then
	AUDIO_PIPELINE=
fi
if ! $WITH_VIDEO; then
	VIDEO_PIPELINE=
fi
echo "Video gst pipeline: ${VIDEO_PIPELINE:-None}"
echo "Audio gst pipeline: ${AUDIO_PIPELINE:-None}"
echo
exec gst-launch-1.0 --gst-debug-level=2 $AUDIO_PIPELINE $VIDEO_PIPELINE \
         rtspclientsink name=rsink location="$RTSP_URL" \
                        latency=34 protocols=$TRANSPORT $TLS_OPTS $RTSP_DEBUG
