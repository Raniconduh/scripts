#!/bin/sh


DISCHARGING=0
CHARGING=1
BATSTATEOTHER=2


gettime() {
	date +"%a %b %d %I:%M %p"
}


getbat() {
	cat /sys/class/power_supply/BAT0/capacity
}


getbatstat() {
	read status </sys/class/power_supply/BAT0/status
	case "$status" in
		D*) echo $DISCHARGING ;;
		C*) echo $CHARGING ;;
		N*) echo $BATSTATEOTHER ;;
	esac
}


getmute() {
	case "$(pactl get-sink-mute @DEFAULT_SINK@)" in
		*\ no) return 1 ;;
		*) return 0 ;;
	esac
}


getvol() {
	set -- $(pactl get-sink-volume @DEFAULT_SINK@)
	left=$5
	right=${12}

	ileft="${left%%%}"
	iright="${right%%%}"

	if [ $ileft -gt $iright ]; then
		echo $ileft
	else
		echo $iright
	fi
}


hupped=0
trap 'hupped=1' HUP

cnt=5
oldvol=
while :; do
	time="$(gettime)"
	bat="$(getbat)"
	batstat="$(getbatstat)"

	batstatc=
	case $batstat in
		$DISCHARGING)   batstatc='' ;;
		$CHARGING)      batstatc='^' ;;
		$BATSTATEOTHER) batstatc='*' ;;
	esac

	oldvol="${vol:-$oldvol}"
	vol=
	if [ $cnt -eq 5 ] || [ $hupped -ne 0 ]; then
		[ $cnt -eq 5 ] && cnt=0
		hupped=0

		if getmute; then
			vol="="
		else
			vol="$(getvol)%"
		fi
	fi

	barline=" VOL: ${vol:-$oldvol} | BAT: ${batstatc}${bat}% | ${time}"
	xsetroot -name "$barline"

	cnt=$((cnt + 1))

	sleep 1 &
	wait
done
