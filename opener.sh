#!/bin/sh

[ $# -ne 1 ] && exit

EDITOR="${EDITOR:-vim}"
TERMINAL="xterm"
IMG_OPENER="feh"
TTY_BROWSER="links"
GUI_BROWSER="firefox"
PDF_VIEWER="firefox"
SPREADSHEETS="false"
FILE_MANAGER=~/dev/cscroll/cscroll
VIDEO_PLAYER="ffplay"

errX() {
	if [ -z "$DISPLAY" ]; then
		echo "No X server running" >&2
		exit 1
	fi
}

run_term() {
	if [ -t 0 ]; then
		"$1" "$2"
	else
		errX
		"$TERMINAL" -e "$1" "$2"
	fi
}

open_img() {
	errX
	"$IMG_OPENER" "$1"
}

open_vid() {
	errX
	"$VIDEO_PLAYER" "$1"
}

browser() {
	if [ -z "$DISPLAY" ]; then
		run_term "$TTY_BROWSER" "$1"
	else
		"$GUI_BROWSER" "$1"

		# workaround for some browsers
#		browser_win="$(xdotool search --onlyvisible --limit 1 --class "$GUI_BROWSER")"
#		if [ -z "$browser_win" ]; then
#			"$GUI_BROWSER" "$1" &
#			return
#		fi
#
#		xdotool key --window "$browser_win" ctrl+t
#		xdotool type --window "$browser_win" "$1"
#		xdotool key --window "$browser_win" enter
	fi
}

if [ ! -e "$1" ]; then
	case "$1" in
		https://|http://|*.*)
			case "$1" in
				*.bmp|*.gif|*.heif|*.ico|*.jpeg|*.jpg \
				|*.png|*.svg|*.tif|*.tiff|*.webp)
					open_image "$1"
					exit
					;;
				*)
					browser "$1"
					exit
					;;
			esac
			;;
	esac
fi

case "$(file --mime-type -b "$(realpath "$1")")" in
	image/*)
		open_img "$1"
		;;
	text/*|inode/x-empty)
		run_term "$EDITOR" "$1"
		;;
	*spreadsheet*|*Excel*)
		run_term "$SPREADSHEETS" "$1"
		;;
	inode/directory)
		run_term "$FILE_MANAGER" "$1"
		;;
	application/pdf)
		"$PDF_VIEWER" "$1"
		;;
	video/*)
		open_vid "$1"
		;;
	*)
		exit 1
		;;
esac
