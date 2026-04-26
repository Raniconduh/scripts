#!/bin/sh

BATPATH=/sys/class/power_supply/BAT0

LOW_PERCENT=20

getbat() {
	cat "$BATPATH"/capacity
}

notify() {
	herbe "$@"
}

sent=
while :; do
	bat="$(getbat)"

	if [ "$bat" -le "$LOW_PERCENT" ] && [ ! "$sent" ]; then
		notify "Low Battery" " " "Battery is at $bat%"
		sent=1
	elif [ "$sent" ] && [ "$bat" -gt "$LOW_PERCENT" ]; then
		sent=
	fi

	sleep 5
done
