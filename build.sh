#!/bin/sh
#
ME="Bootsector Linux loader 1.2 (C) 2023 By Alphons van der Heijden"
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

WORK=/mnt/sda1/Alpha
KERNEL=$WORK/vmlinuz64
INITRD=$WORK/rootfs64.gz,$WORK/modules64.gz
CMDLINE="'loglevel=3'"
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
  echo "(experimental) Decoding $INPUT to directory $DIR processing $TOTALSECTORS sectors"
  i=1
  while [ $i -lt $TOTALSECTORS ]
  do
    echo -e -n "$i\r"
    PROBE=$(dd if=$INPUT count=1 skip=$i 2>/dev/null | hexdump -n 4 -e '/1 "%02x"')
    if [[ "$PROBE" == "1f8b0800" ]]; then
      echo "initrd.gz found at sector $i"
      dd if=$INPUT count=$(($i - 1)) skip=1 2>/dev/null > $DIR/kernel
      dd if=$INPUT count=$(($TOTALSECTORS - $i)) skip=$i 2>/dev/null > $DIR/initrd.gz
      echo "ready"
      echo
      exit 0
    fi
    i=$(( $i + 1 ))
  done
  echo "No initrd.gz found"    
  exit 0
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
# Always use padding even when on SECTORSIZE boundary
K_PAD=$(($SECTORSIZE - $K_SZ % $SECTORSIZE))
R_PAD=$(($SECTORSIZE - $R_SZ % $SECTORSIZE))

nasm -o $OUTPUT -D initRdSizeDef=$R_SZ -D cmdLineDef=$CMDLINE $BOOT

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
