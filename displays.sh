#!/bin/sh


OUT="$(xrandr)"

primary="$(printf '%s\n' "$OUT" | grep -i primary | cut -d' ' -f1)"
connected="$(printf '%s' "$OUT" | sed '/disconnected/d; /connected/p; /.*/d' | cut -d' ' -f1)"

set -- $connected

echo "Connected Displays:"
for i in $(seq 1 $#); do
	eval 'con=$'$i

	printf '%s: %s' "$i" "$con"
	if [ "$con" = "$primary" ]; then
		echo " - Primary"
	else
		echo
	fi
done
echo '-----'


inv() {
	echo "Invalid Display"
}


while :; do
	printf '> '
	read -r input || exit
	set -- $input

	case $1 in
		connect|con|c)
			n=$(($2))
			set -- $connected
			if [ $n -le 0 ] || [ $n -gt $# ]; then inv; continue; fi
			
			eval 'c="$'$n'"'
			xrandr --output "$c" --auto && echo "Connected"
			;;
		disconnect|discon|d)
			n=$(($2))
			set -- $connected
			if [ $n -le 0 ] || [ $n -gt $# ]; then inv; continue; fi

			eval 'c="$'$n'"'
			xrandr --output "$c" --off && echo "Disconnected"
			;;
		exit|quit|q)
			exit
			;;
		*)
			;;
	esac
done
