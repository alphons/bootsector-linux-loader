# bootsector-linux-loader

No bootloader nor a filesystem is needed to make a linux distribution bootable from only the kernel and initrd

All is tested with versions of TinyCore but other distros should be also no problem.
The program should work for 64 bit and for 32 bit systems.
Examples are all 64 bit.

Tested is with initrd of type initramfs (cpio -H newc)

The generated .vmdk file is only used in a VMWare environment, but is not needed when in Qemu or other VM application.

Running the script:

```
./build.sh
```

## Example single initrd entry

Example single initrd entry from the TinyCore 13 release.

- [corepure64.gz from www.tinycorelinux.net](http://www.tinycorelinux.net/13.x/x86_64/release/distribution_files/corepure64.gz)
- [vmlinuz64 from www.tinycorelinux.net](http://www.tinycorelinux.net/13.x/x86_64/release/distribution_files/vmlinuz64)

```
WORK=/mnt/sda1/normal
KERNEL=$WORK/vmlinuz64
INITRD=$WORK/corepure64.gz
CMDLINE="'loglevel=3'"
OUTPUT=/tmp/linux
```

## Example multiple initrd entries

Also multiple initrd entries can be used, comma seperated, as an example TinyCore 14.x (Alpha testing)

- [rootfs64.gz from www.tinycorelinux.net](http://repo.tinycorelinux.net/14.x/x86_64/release_candidates/distribution_files/rootfs64.gz)
- [modules64.gz from www.tinycorelinux.net](http://repo.tinycorelinux.net/14.x/x86_64/release_candidates/distribution_files/modules64.gz)
- [vmlinuz64 from www.tinycorelinux.net](http://repo.tinycorelinux.net/14.x/x86_64/release_candidates/distribution_files/vmlinuz64)

```
WORK=/mnt/sda1/Alpha
KERNEL=$WORK/vmlinuz64
INITRD=$WORK/rootfs64.gz,$WORK/modules64.gz
CMDLINE="'loglevel=3'"
OUTPUT=/tmp/linux
```


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
OUTPUT="linux"
KERNEL="$WORK/vmlinuz64"
INITRD="$WORK/corepure64.gz"
CMDLINE="'loglevel=3'"
```

Building the disk by:
```
$ ./build.sh
Bootsector Linux loader 1.1 (C) 2023 By Alphons van der Heijden

Ready /tmp/linux (19256832 bytes) and /tmp/linux.vmdk
```

This will produce two files:

- linux
- linux.vmdk

When running vmware or esxi platform, the vmdk disk can ben used as a bootable device.

## build.cmd (for dos, or windows)

Very simular to the unix variant this batch program can run to do the same task.
Configuring the needed paramers.

```
set OUTPUT=linux
set KERNEL=vmlinuz64
set INITRD=corepure64.gz
set CMDLINE='loglevel=3'
```

running the script from a dos prompt, or double click in windows

```
C:\> build.cmd
bootsector, kernel and initrd catenated in linux and created linux.vmdk
```

### bsect.asm

The key to this solution is the bootsector program made initially by [Gareth Owen](/owenson/tiny-linux-bootloader) which is modified.

There is not much room to pack it all into 512 bytes of the bootsector. At default a kernel command line of 68 chars can be used at max.

The result is always a 512 byte bootsector which loads the (padded to 512 byte sectors) 'kernel' in protected mode and
also loads the (also padded to 512 bytes sector) 'initrd' into protected memory and starts executing the kernel with given command line
and memory pointer to initrd.

## Running the bootdisc

For testing one can use

```
$ qemu-system-x86 linux -m 1024
or for 64 bit
$ qemu-system-x86_64 linux -m 1024
```

In vmware only adding an 'existing disk' pointing to linux.vmdk should be enough
```
ide0:0.fileName = "linux.vmdk"
```

But also a scsi adapter can be used.
When adding the disk to Vmware player, the programs asks for converting the disk, say NO here.

Have fun.

ps.

```
Kernel panic - not syncing: VFS Unable to mount root fs on unkown-block(0,0)
Kernel Offset: disabled
Rebooting in 60 seconds.
```

This simply means, give it more RAM !!!

# Decoding disk

This is experimental, distil the kernel and initrd.gz from the bootdisk
Trying this by looking for the MAGIC gz header on start of sectors. (sort of)

```
./build.sh /tmp/bootdisk /tmp

write: /tmp/kernel
write: /tmp/initrd.gz
```

