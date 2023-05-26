#!/bin/sh

[ $# -ne 1 ] && exit

EDITOR="${EDITOR:-vim}"
TERMINAL="xterm"
IMG_OPENER="imgd"
TTY_BROWSER="lynx"
GUI_BROWSER="firefox"
SPREADSHEETS="sc-im"
FILE_MANAGER=~/dev/cscroll/cscroll

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

browser() {
	if [ -z "$DISPLAY" ]; then
		run_term "$TTY_BROWSER" "$1"
	else
		browser_win="$(xdotool search --onlyvisible --limit 1 --class "$GUI_BROWSER")"
		if [ -z "$browser_win" ]; then
			"$GUI_BROWSER" "$1" &
			return
		fi

		xdotool key --window "$browser_win" ctrl+t
		xdotool type --window "$browser_win" "$1"
		xdotool key --window "$browser_win" enter
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

case "$(file -b "$(realpath "$1")")" in
	*image*)
		open_img "$1"
		;;
	*ASCII\ text*|*Unicode\ text*|empty)
		run_term "$EDITOR" "$1"
		;;
	*spreadsheet*|*Excel*)
		run_term "$SPREADSHEETS" "$1"
		;;
	directory)
		run_term "$FILE_MANAGER" "$1"
		;;
	*)
		exit 1
		;;
esac
