#!/bin/sh

# Copyright (C) ??? ???
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# This script was found at
# https://stegard.net/2023/11/implementing-a-time-based-one-time-password-totp-generator/
# and also at https://github.com/oyvindstegard/totp. The original script as
# shown in the above links has been modified for POSIX shell compatibility and
# general shell best practice.

TIME=

# Arg 1: string
# Arg 2: index (1 indexed)
# Arg 3: length
# prints the substring
substr() {
    start="$2"
    stop=$(( start + $3 - 1 ))
    printf '%s' "$1" | cut -b"$start-$stop"
}

# Arg 1: base32-encoded value, does not need to be padded.
# Outputs to stdout the raw decoded value.
base32_decode() {
    val="$(printf '%s' "$1" | tr '018a-z' 'OIBA-Z')"
    if [ $(( ${#val} % 8 )) -gt 0 ]; then
        pad=$(( 8 - ${#val} % 8))
        i=0
        while [ $i -lt $pad ]; do
            val="${val}="
            i=$(( i + 1 ))
        done
    fi

    printf '%s' "$val" | base32 -d
}

# Arg 1: hash function identifier
# Arg 2: base32-encoded message string
# Arg 3: base32-encoded key string
# Outputs result as hex characters, which is the HMAC code.
# Output length depends on chosen hash function.
hmac() {
    hexkey="$(base32_decode "$3" | xxd -p | tr -d '\n')"
    base32_decode "$2" | \
        openssl "$1" -hex -mac HMAC -macopt "hexkey:$hexkey" | \
        cut -d' ' -f2
}

totp() {
    totp_period_seconds=30
    key_base32="$1"
    TIME="$(date +'%s')"
    time_counter=$(( TIME / totp_period_seconds ))
    t_base32="$(printf '%016x' "$time_counter" | xxd -r -p | base32)"

    # 40 hexchars (160 bits or 20 bytes):
    hmac_hex="$(hmac sha1 "$t_base32" "$key_base32")"

    # extraction offset is lowest/rightmost 4 bits
    # of 160 bit sha1 (multiplied by 2 for hex offset):
    slice="$(substr "$hmac_hex" 40 1)"
    hotp_offset=$(( 0x$slice * 2 + 1 ))

    # Extract 32 bit unsigned int at offset:
    slice="$(substr "$hmac_hex" $hotp_offset 8)"
    hotp_code=$(( 0x$slice & 0x7fffffff ))

    printf '%06d' $(( hotp_code % 1000000 ))
}

read -r code
totp "$code"

if [ -t 1 ]; then
    echo
    echo "$(( 30 - TIME % 30 )) seconds remaining"
fi
