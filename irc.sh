#!/bin/sh
# Copyright 2014 Vivien Didelot <vivien@didelot.org>
# Licensed under the terms of the GNU GPL v3, or any later version.

#alias nc='nc'
nc() {
	openssl s_client -connect $1:$2
}

NICK=""
SERVER="irc.libera.chat"
PORT=6697
CHAN=""
USER="username hostname servername realname"

if [ -z "$SERVER" ]; then
	printf "Server: "
	read SERVER
fi

if [ -z "$NICK" ]; then
	printf "Nickname: "
	read NICK
fi

{
  # join channel and say hi
  cat << IRC
NICK $NICK
USER $USER
IRC

  # forward messages from STDIN to the chan, indefinitely
  while read line; do
	case "$line" in
		"/join "*)
			CHAN="`echo "$line" | awk '{print $2}'`"
			echo $CHAN >&2
			echo "JOIN $CHAN"
			;;
		"/part")
			echo "PART $CHAN" ;;
		"/part "*)
			echo "PART `echo "$line" | cut -d' ' -f2-`" ;;
		"/nick "*)
			echo "NICK `echo "$line" | cut -d' ' -f2-`" ;;
		"/msg "*)
			recipient="`echo "$line" | cut -d' ' -f2`"
			msg="`echo "$line" | cut -d' ' -f3-`"
			echo "PRIVMSG $recipient :$msg"
			;;
		*)
			echo "$line" | sed "s/^/PRIVMSG $CHAN :/" ;;
	esac
  done

  # close connection
 # echo QUIT
} | nc $SERVER $PORT | while read line ; do
  case "$line" in
    *PRIVMSG\ \#*\ :*)
		name="`echo "$line" | cut -d! -f1 | cut -b2-`"
		msg="`echo "$line" | cut -d: -f3-`"
		printf '<%s>: %s\n' "$name" "$msg"
		;;
    \#*) echo "[IGNORE] $line" >&2 ;;
	*) echo "** $line" ;;
  esac
done
