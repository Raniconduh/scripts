#!/bin/sh

getgeom() {
	file="$1"
	set -- $(xdotool getdisplaygeometry)
	dx=$(($1))
	dy=$(($2))

	set -- $(gm identify -format "%W %H\n" "$file" | head -n1)
	ix=$(($1))
	iy=$(($2))

	xs="100%"
	ys="100%"
	[ $ix -gt $dx ] && xs="$(($((dx * 100)) / ix))%"
	[ $iy -gt $dy ] && ys="$(($((dy * 100)) / iy))%"

	x=$((dx / 2 - ix / 2))
	y=$((dy / 2 - iy / 2))

	[ $x -lt 0 ] && x=0;
	[ $y -lt 0 ] && y=0;

	echo "${xs}x${ys}+$x+$y"
}

disp() {
	file=""
	isurl=1
	if [ "$1" = "url" ]; then
		file="$(mktemp)"
		curl "$2" -o "$file"
	else
		file="$2"
	fi

	com="display"
	case "$(file -b "$file")" in *GIF*) com="animate" ;; esac

	geom="$(getgeom "$file")"
	gm "$com" +borderwidth -geometry "$geom" "$file"

	[ "$1" = "url" ] && rm "$file"
}

while [ $# -gt 0 ]; do
	case "$1" in
		http://*|https://*)
			disp url "$1"
			;;
		*)
			disp file "$1"
			;;
	esac

	shift
done
