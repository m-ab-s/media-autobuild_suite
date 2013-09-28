---
title: ffmpeg-autobuild

description: A Windows automatic build script for ffmpeg and other media tools

author: Jonathan Baecker (jb_alvarado)

created:  2013-09-24

modified: 2013-09-28

---

ffmpeg-autobuild
=========

This tool is inspire by the very nice, linux cross compile, tool from Roger Pack(rdp):

https://github.com/rdp/ffmpeg-windows-build-helpers

I also use some jscipt parts from nu774:

https://github.com/nu774/fdkaac_autobuild

Thanks to both of them!


Download
--------

### [Click here to download latest version](https://github.com/jb-alvarado/media-autobuild_suite/archive/master.zip)

Current release is **v0.5**


Included, External, Tools
--------

 - bzip2
 - fdkaac
 - flac
 - gsm
 - lame
 - ogg
 - sdl (for ffplay)
 - speex
 - theora
 - vorbis
 - x264
 - xvid
 - zlib

more will comming... 


--------


This Windows Batchscript is for setup a compiler environment for building ffmpeg and other media tools under Windows.
After building the environment it get and compile all tools.

For using it: 
 - Download the file, and copy it in your target folder. In that folder all compiler and tools get installed. Please look that you use a folder without space characters. A good place is: c:\mingw
 - double click the ffmpeg-autobuild.bat file 
 - select if you want to compile for Windows 32 bit, 64 bit or both
 - select if you want to compile non free tools like "fdk aac"
 - select the numbers of CPU (cores) you want to use
 
 - Wait a little bit, and hopefully after a while you found all your "*.exe" Tools under local32\bin, or local64\bin 

Have fun!


References
--------

http://ingar.satgnu.net/devenv/mingw32/base.html

http://kemovitra.blogspot.co.at/2009/08/mingw-to-compile-ffmpeg.html



 