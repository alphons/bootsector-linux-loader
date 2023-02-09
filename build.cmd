@echo off
rem
rem (C) 2023 Alphons van der Heijden
rem 
rem Create a bootable disk out of kernel and initrd
rem for VMWARE player/esxi without bootloader
rem using nasm creating a bootsector
rem creating a vmdk file
rem 
rem
setlocal

set OUTPUT=linux
set KERNEL=vmlinuz64
set INITRD=corepure64.gz
set CMDLINE='loglevel=3'

rem now everything is configured, lets build the bootable disk and vmdk file

call :getsize %kernel%
set K_SZ=%size%
call :getsize %initrd%
set R_SZ=%size%
set S=512
set /a K_PAD=512-K_SZ%%S
set /a R_PAD=512-R_SZ%%s

nasm -o bsect.bin -D initRdSizeDef=%R_SZ% -D cmdLineDef=%CMDLINE% bsect.asm
fsutil file createnew "k_pad.bin" %K_PAD% > NUL
fsutil file createnew "r_pad.bin" %R_PAD% > NUL

copy bsect.bin /B + %KERNEL% /B + k_pad.bin /B + %INITRD% /B + r_pad.bin / B %OUTPUT% /B > NUL
del k_pad.bin
del r_pad.bin
del bsect.bin

call :getsize %OUTPUT%
set TOTAL=%size%
set /a SECTORS=%TOTAL% / 512
set /a CYLINDERS=%SECTORS% / 16065

(
echo version=1
echo encoding="UTF-8"
echo CID=123456789
echo parentCID=ffffffff
echo createType="vmfs"
echo RW %SECTORS% VMFS "%OUTPUT%"
echo ddb.virtualHWVersion = "8"
echo ddb.geometry.cylinders = "%CYLINDERS%"
echo ddb.geometry.heads = "255"
echo ddb.geometry.sectors = "63"
echo ddb.adapterType = "lsilogic"
)>%OUTPUT%.vmdk

echo bootsector, kernel and initrd catenated in %OUTPUT% and created %OUTPUT%.vmdk
pause

goto :eof

:getsize
set size=%~z1
goto :eof
