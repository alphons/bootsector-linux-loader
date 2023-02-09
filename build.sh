#!/bin/sh
# Tiny Linux Bootloader
# (c) 2014- Dr Gareth Owen (www.ghowen.me). All rights reserved.

#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

#
#    Updated 2023- by Alphons van der Heijden for making .vmdk disk for booting in vmware

WORK=/mnt/sda1/release/iso_contents/boot

OUTPUT="linux-6.1.2"
KERNEL="$WORK/vmlinuz64"
INITRD="$WORK/corepure64.gz"
CMDLINE="'loglevel=3'"

#bootsector assembly
BOOT="bsect.asm"

#size of kern + ramdisk
K_SZ=$(stat -c %s $KERNEL)
R_SZ=$(stat -c %s $INITRD)

#padding to make it up to a sector
K_PAD=$((512 - $K_SZ % 512))
R_PAD=$((512 - $R_SZ % 512))

nasm -o $OUTPUT -D initRdSizeDef=$R_SZ -D cmdLineDef=$CMDLINE $BOOT

cat $KERNEL >> $OUTPUT
if [[ $K_PAD -lt 512 ]]; then
    dd if=/dev/zero bs=1 count=$K_PAD status=none >> $OUTPUT
fi

cat $INITRD >> $OUTPUT
if [[ $R_PAD -lt 512 ]]; then
    dd if=/dev/zero bs=1 count=$R_PAD status=none >> $OUTPUT
fi

TOTAL=$(stat -c %s $OUTPUT)
SECTORS=$(($TOTAL / 512))
CYLINDERS=$(($SECTORS / 16065))

cat > $OUTPUT.vmdk <<EOF
version=1
encoding="UTF-8"
CID=123456789
parentCID=ffffffff
createType="vmfs"
RW $SECTORS VMFS "$OUTPUT"
ddb.virtualHWVersion = "8"
ddb.geometry.cylinders = "$CYLINDERS"
ddb.geometry.heads = "255"
ddb.geometry.sectors = "63"
ddb.adapterType = "lsilogic"
EOF

echo "bootsector, kernel and initrd catenated in $OUTPUT and created $OUTPUT.vmdk"
