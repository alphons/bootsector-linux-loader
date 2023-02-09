# bootsector-linux-loader

No bootloader nor a filesystem is needed to make a linux distribution bootable from only the kernel and initrd

All is tested with versions of TinyCore but other distros should be also no problem.

- [corepure64.gz](http://www.tinycorelinux.net/13.x/x86_64/release/distribution_files/corepure64.gz)
- [vmlinuz64](http://www.tinycorelinux.net/13.x/x86_64/release/distribution_files/vmlinuz64)

At this moment, only 1 initrd can be used. (not rootfs64.gz and modules64.gz)

### Prereq NASM

Get a version of [NASM](https://www.nasm.us/) at the official site, or maybe it is installed on your unix system already.

For convienence, this repository stores the 32bit exe dos/windows version "NASM version 2.16.01 compiled on Dec 21 2022"

It will work on 64 bit systems also, but is a bit smaller ;-)

## build.sh (for unix)

Before making a bootable disk, the path to the linux kernel and initrd must be set.
Also an optional kernel command line can be set.
These are NOT kernel version specific. The kernel must handle the initrd itself from ram.

```
WORK=/mnt/sda1/somedir
OUTPUT="linux-disk"
KERNEL="$WORK/vmlinuz64"
INITRD="$WORK/corepure64.gz"
CMDLINE="'loglevel=3'"
```

Building the disk by:
```
$ ./build.sh
bootsector, kernel and initrd catenated in linux-6.1.2 and created linux-6.1.2.vmdk
```

This will produce two files:

- linux-disk
- linux-disk.vmdk

When running vmware or esxi platform, the vmdk disk can ben used as a bootable device.

## build.cmd (for dos, or windows)

Very simular to the unix variant this batch program can run to do the same task.
Configuring the needed paramers.

```
set OUTPUT=linux-6.1.2
set KERNEL=vmlinuz64
set INITRD=corepure64.gz
set CMDLINE='loglevel=3'
```

running the script from a dos prompt, or double click in windows

```
C:\> build.cmd
bootsector, kernel and initrd catenated in linux-6.1.2 and created linux-6.1.2.vmdk
```

### bsect.asm

The key to this solution is the bootsector program made by [Gareth Owen](/owenson/tiny-linux-bootloader)
with some small modifications.

There is not much room to pack it all into 512 bytes of the bootsector. At default a command line of 68 chars can be used at max.

The result is always a 512 byte bootsector which loads the (padded to 512 byte sectors) kernel in protected mode and
also loads the (also padded to 512 bytes sector) initrd into protected memory and starts executing the kernel with given command line
and memory pointer to initrd.

## Running the bootdisc

For testing one can use

```
$ qemu-system-x86 linux-disk
or for 64 bit
$ qemu-system-x86_64 linux-disk
```

In vmware only adding an 'existing disk' pointing to linux-6.1.2.vmdk should be enough
```
ide0:0.fileName = "linux-6.1.2.vmdk"
```

But also a scsi adapter can be used.
When adding the disk to Vmware player, the programs asks for converting the disk, say NO here.

Have fun.
