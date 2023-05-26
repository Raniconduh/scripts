#!/bin/sh

# $1 must be duration; 0 for default
[ $# -lt 1 ] && exit

args=""
[ $1 -gt 0 ] && args="-d $1"
shift

printf '%s\n' "$*" | tr -dc '[:alnum:][:special:][:punct:][:space:]' | nfy $args
