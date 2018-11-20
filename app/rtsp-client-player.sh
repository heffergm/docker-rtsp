#!/bin/sh
set -eu

# example rtsp url: rtsps://user:pass@127.0.0.1:8556/test1234
RTSP_URL=
TRANSPORT=tcp
TLS_OPTS=
WITH_AUDIO=false
WITH_VIDEO=true
VIDEOSINK=autovideosink
GST_SYNC=true
LATENCY=0
RTSP_DEBUG=
SHOW_HELP=false

if [ Darwin = "$(uname)" ]; then
	VIDEOSINK=osxvideosink
fi

while [ $# -gt 0 ]; do
	PARAM=${1%%=*}
	VALUE=${1#*=}
	case "$PARAM" in
		--rtsp-url)   RTSP_URL=$VALUE ;;
		--transport)  TRANSPORT=$VALUE ;;
		--insecure)   TLS_OPTS="tls-validation-flags=0x58" ;;  # only expired, revoked
		--rtsp-debug) RTSP_DEBUG="debug=1" ;;
		--audio)      WITH_AUDIO=$VALUE ;;
		--video)      WITH_VIDEO=$VALUE ;;
		--videosink)  VIDEOSINK=$VALUE ;;
		--sync)       GST_SYNC=$VALUE ;;
		--latency)    LATENCY=$VALUE ;;
		--help | -h)  SHOW_HELP=true  ;;
		*) printf "ERROR: unrecognized option '$1'\n" 1>&2 ; exit 1 ;;
	esac
	shift
done

if $SHOW_HELP || [ -z "$RTSP_URL" ]; then
	echo "USAGE: $0 --rtsp-url=<url> [--transport=<type>] [--insecure] [--rtsp-debug]" \
	      "[--audio=true] [--video=false] [--sync=false] [--videosink=<element>] [--latency=<ms>]" 1>&2
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

#VIDEO_PIPELINE="mux. ! rtph264depay ! avdec_h264 ! videoconvert ! $VIDEOSINK sync=$GST_SYNC"
#AUDIO_PIPELINE="mux. ! decodebin ! autoaudiosink sync=$GST_SYNC"
VIDEO_PIPELINE="mux. ! fakesink"
AUDIO_PIPELINE="mux. ! fakesink"

if ! $WITH_AUDIO; then
	AUDIO_PIPELINE=
fi
if ! $WITH_VIDEO; then
	VIDEO_PIPELINE=
fi
echo "Video gst pipeline: ${VIDEO_PIPELINE:-None}"
echo "Audio gst pipeline: ${AUDIO_PIPELINE:-None}"
echo
exec gst-launch-1.0 --gst-debug-level=2 \
        rtspsrc name=mux location="$RTSP_URL" \
                latency=$LATENCY protocols=$TRANSPORT $TLS_OPTS $RTSP_DEBUG \
                $VIDEO_PIPELINE $AUDIO_PIPELINE
