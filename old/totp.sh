#!/usr/bin/env bash

# The MIT License
#
# Copyright (c) 2020 Kevin Cui
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# Yet another minimal TOTP generator
#
#/ Usage:
#/   ./totp
#/ Secret taken from stdin

# Taken from github.com/KevCui/totp

read input
set -- $input
secret="${1^^}$(printf "%$(( (8-${#1}) % 8 ))s" | tr " " "=")"
key="$(base32 -d <<< "$secret" \
    | xxd -p \
    | tr -cd 0-9A-Fa-f)"
mac=$(printf "%016X" "$(( ($(date +%s)) / 30))" \
    | xxd -r -p \
    | openssl dgst -sha1 -binary -mac hmac -macopt "hexkey:$key" \
    | xxd -p)
offset="$(( 16#"${mac:39:1}" * 2))"
printf "%06d\n" "$(( (0x${mac:offset:8} & 0x7FFFFFFF) % 1000000 ))"
echo "$((30 - ($(date +%s) % 30))) seconds remaining"
