---
title: media-autobuild_suite

description: A Windows automatic build script for ffmpeg and other media tools

author: Jonathan Baecker (jb_alvarado)

created:  2013-09-24

modified: 2013-10-03

---

media-autobuild_suite
=========

This tool is inspire by the very nice, linux cross compile, tool from Roger Pack(rdp):

https://github.com/rdp/ffmpeg-windows-build-helpers

I also use some jscipt parts from nu774:

https://github.com/nu774/fdkaac_autobuild

Thanks to both of them!


Download
--------

### [Click here to download latest version](https://github.com/jb-alvarado/media-autobuild_suite/archive/master.zip)

Current release is **v0.65**


Included Tools
--------

 - bzip2
 - fdkaac (standalone and lib for ffmpeg)
 - ffmpeg
 - faac (standalone)
 - flac (standalone)
 - gsm
 - lame (standalone and lib for ffmpeg)
 - ogg
 - mp4box (standalone)
 - rtmp (standalone)
 - sdl (for ffplay)
 - speex (standalone and lib for ffmpeg)
 - theora
 - opencore-amr (lib for ffmpeg)
 - vo-aacenc (lib for ffmpeg)
 - vo-amrwbenc (lib for ffmpeg)

 - vorbis
 - x264 (standalone and lib for ffmpeg)
 - x264 10 bit (standalone)
 - xvid
 - zlib

more will comming... 


--------


This Windows Batchscript is for setup a compiler environment for building ffmpeg and other media tools under Windows.
After building the environment it get and compile all tools. All tools get static compiled, no external .dlls needed.

For using it: 
 - Download the file, and copy it in your target folder. In that folder all compiler and tools get installed. Please look that you use a folder without space characters. A good place is: c:\mingw
 - double click the media-autobuild_suite.bat file 
 - select if you want to compile for Windows 32 bit, 64 bit or both
 - select if you want to compile non free tools like "fdk aac"
 - select the numbers of CPU (cores) you want to use
 
 - Wait a little bit, and hopefully after a while you found all your "*.exe" Tools under local32\bin, or local64\bin

For all you need ~1,5 GB disk space. 
The script doesn't build any registry key or system variables, when you don't need it any more you can delete the folder and your system will be clean. 

Have fun!


References
--------

http://ingar.satgnu.net/devenv/mingw32/base.html

http://kemovitra.blogspot.co.at/2009/08/mingw-to-compile-ffmpeg.html



 
