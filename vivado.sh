#!/bin/sh

XILINX_PATH=/opt/xilinx
VERSION=2022.2

tmp="$(mktemp -d -t vivado.XXXXXXXXX)"
if [ $? != 0 ]; then
	echo "Error creating temporary directory"
	printf '%s' "$tmp"
fi;

cd "$tmp"
echo "cd $tmp"

export _JAVA_AWT_WM_NONREPARENTING=1
exec "$XILINX_PATH"/Vivado/"$VERSION"/bin/vivado
