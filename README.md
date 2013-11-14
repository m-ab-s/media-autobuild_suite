---
title: media-autobuild_suite

description: A Windows automatic build script for ffmpeg and other media tools

author: Jonathan Baecker (jb_alvarado)

created:  2013-09-24

modified: 2013-11-12

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

Current release is **v0.8**


Included Tools and Libraries
--------

 - bzip2
 - fdkaac (standalone and lib for ffmpeg)
 - ffmpeg
 - faac (standalone and lib for ffmpeg)
 - fftw
 - flac (standalone)
 - fltk
 - fontconfig
 - freetype
 - gsm
 - gnutls (standalone and lib for ffmpeg)
 - lame (standalone and lib for ffmpeg)
 - ImageMagick (standalone (32 bit))
 - jpeg
 - jpeg2000
 - jpegturbo
 - libass
 - libbluray
 - libpng
 - libtiff
 - libutvideo
 - libxml2
 - mp3lame (standalone and lib for ffmpeg)
 - mp4box (standalone)
 - mplayer (standalone)
 - opencore-amr
 - openEXR (standalone and lib for ImageMagick)
 - openjpeg
 - ogg
 - opus
 - opus-tools (standalone)
 - rtmp (standalone and lib for ffmpeg)
 - sdl (for ffplay)
 - speex (standalone and lib for ffmpeg)
 - theora
 - vpx (standalone and lib for ffmpeg)
 - vo-aacenc
 - vo-amrwbenc
 - vorbis
 - x264 (standalone and lib for ffmpeg)
 - x264 10 bit (standalone)
 - xavs (standalone and lib for ffmpeg)
 - xvid
 - zlib


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

For all you need ~7,5 GB disk space.
The script doesn't build any registry key or system variables, when you don't need it any more you can delete the folder and your system will be clean. 
Build all from the begin take around ~4 hours (the cross compile script from rdp is much faster).

Later when you need only some new builds, delete the folder in /build32 or build64, for example the ffmpeg folder. After that starting the script again and it only compile this tool new.

Have fun!


References
--------

http://ingar.satgnu.net/devenv/mingw32/base.html


http://kemovitra.blogspot.co.at/2009/08/mingw-to-compile-ffmpeg.html
