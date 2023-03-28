# lion32
Lion FPGA CPU/Computer 32bit version

This is the 32bit version of my 16bit Lion System (lliont/lion16 repository).

lionsys.sof and lionsys.jic are the files for configuration of a QMTech Cyclone V FPGA board for Lion32.

32.zip contains files for the 30MB FAT partition on a SDCard for Lion to boot.

Lionasm.exe is an assembler for Lion32. 

Liontiny32.asm is the Basic source file that when compiled and it's output Liontiny.bin is named BOOT.BIN (exists in 32.zip) and copied to sdcard it boots lion32 in tiny basic.

Lion1.sch and Lion1.brd are eagle files for the Lion base board.

Lionc directory contains small-c for Lion files, cc.exe the compiler, Lionlink.exe - llink.exe the linker, clib.bin is the library

Hardware design and software released under the Creative Commons License BY-NC-SA

Theodoulos Liontakis.

Project Pages:

https://hackaday.io/project/162876-lion-fpga-cpucomputer

http://users.sch.gr/tliontakis/index.php/my-projects/13-vhdl-cpu




