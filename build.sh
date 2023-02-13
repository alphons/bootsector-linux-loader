#!/bin/sh
#
ME="Bootsector Linux loader 1.3 (C) 2023 By Alphons van der Heijden"
#
# Making bootable disk file and an additional .vmdk file for booting in vmware
#
# For the .vmdk file see https://kb.vmware.com/s/article/1026266
# (this is handled in this script)
# HEADS=64,  SECTORS=32 ; disksize < 1GB
# HEADS=128, SECTORS=32 ; disksize > 1GB && disksize < 2GB
# HEADS=255, SECTORS=63 ; disksize > 2GB
#
# Experimental disk decoding
# for example: ./build.sh disk /tmp 
# creates kernel and initrd.gz in /tmp

# 2014- Dr Gareth Owen (www.ghowen.me). All rights reserved.
#
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

# INITRD can have multiple gz files, for example INITRD=rootfs.gz,modules.gz

WORK=/mnt/sdb1/release/iso_contents/boot
KERNEL=$WORK/vmlinuz64
INITRD=$WORK/corepure64.gz
#rootfs64.gz,$WORK/modules64.gz
CMDLINE="'loglevel=3 nozswap'"
OUTPUT=/tmp/linux

#
echo
echo $ME
echo
# some usefull constants
BOOT="bsect.asm"
TMPINITRD=/tmp/initrd.gz
SECTORSIZE=512

if [ "$#" -gt 0 ]; then
   if [ "$#" != 2 ]; then
     echo "Usage: $0 <disk> <outputdirectory>"
     echo
     exit 1
   fi
  INPUT=$1
  DIR=$2
  if [ ! -d $DIR ]; then
    echo "Directory does not exist"
    exit 1
  fi
  if [ ! -f $INPUT ]; then
    echo "Input file $INPUT not found"
    echo
    exit 1
  fi
  TOTAL=$(stat -c %s $INPUT)
  TOTALSECTORS=$(($TOTAL / $SECTORSIZE))
  echo "Decoding $INPUT to directory $DIR processing..."
  HEXADDRESS=$(hexdump $INPUT | grep '8b1f 0008 0000' | sed 's/ .*//' | tr '[a-z]' '[A-Z]')
  if [[ $HEXADDRESS == "" ]]; then
    echo "No initrd.gz found"
    exit 1
  fi
  echo
  ADDRESS=$(echo "obase=10; ibase=16; $HEXADDRESS" | bc)  
  SECTOR=$(($ADDRESS / SECTORSIZE))
  echo "writing: $DIR/kernel"
  dd if=$INPUT count=$(($SECTOR - 1)) skip=1 2>/dev/null > $DIR/kernel
  echo "writing: $DIR/initrd.gz"
  dd if=$INPUT count=$(($TOTALSECTORS - $SECTOR)) skip=$SECTOR 2>/dev/null | gunzip | gzip > $DIR/initrd.gz
  echo
  exit 0
fi

if [ ! -f $KERNEL ]; then
  echo "Error: $KERNEL not found"
  exit 1
fi

# preprocessing INITRD for multiple entries
echo -n > $TMPINITRD
for gz in ${INITRD//,/ }
do 
  if [ -f $gz ]; then
    cat $gz >> $TMPINITRD
  else
    echo "Error: $gz not found"
    echo
    exit 1
  fi
done

# size of kernel + ramdisk
K_SZ=$(stat -c %s $KERNEL)
R_SZ=$(stat -c %s $TMPINITRD)

# Padding to make it up to a sector
# Always use padding even when exact on sector boundary
K_PAD=$(($SECTORSIZE - $K_SZ % $SECTORSIZE))
R_PAD=$(($SECTORSIZE - $R_SZ % $SECTORSIZE))

nasm -o $OUTPUT -D initRdSizeDef=$R_SZ -D cmdLineDef="$CMDLINE" $BOOT

cat $KERNEL >> $OUTPUT
dd if=/dev/zero bs=1 count=$K_PAD status=none >> $OUTPUT

cat $TMPINITRD >> $OUTPUT
dd if=/dev/zero bs=1 count=$R_PAD status=none >> $OUTPUT
rm -f $TMPINITRD

TOTAL=$(stat -c %s $OUTPUT)

if [ $TOTAL -gt 2000000000 ]; then
  SECTORS=63
  HEADS=255
else
  SECTORS=32
  if [ $TOTAL -gt 1000000000 ]; then
    HEADS=128
  else
    HEADS=64
  fi
fi

TOTALSECTORS=$(($TOTAL / $SECTORSIZE))
CYLINDERS=$(($TOTALSECTORS / ($HEADS * $SECTORS)))

OUTPUTNAME=$(echo $OUTPUT | sed 's/.*\///' )

cat > $OUTPUT.vmdk <<EOF
version=1
encoding="UTF-8"
CID=123456789
parentCID=ffffffff
createType="vmfs"
RW $TOTALSECTORS VMFS "$OUTPUTNAME"
ddb.virtualHWVersion = "8"
ddb.geometry.cylinders = "$CYLINDERS"
ddb.geometry.heads = "$HEADS"
ddb.geometry.sectors = "$SECTORS"
ddb.adapterType = "lsilogic"
EOF

echo "Ready $OUTPUT ($TOTAL bytes) and $OUTPUT.vmdk"
echo
