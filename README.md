---
title: media-autobuild_suite

description: A Windows automatic build script for ffmpeg and other media tools

author: Jonathan Baecker (jb_alvarado)

created:  2013-09-24

modified: 2014-03-18

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

Current release is **v1.3**


Included Tools and Libraries
--------

 - a52dec
 - bzip2
 - fdkaac (standalone and lib for ffmpeg)
 - ffmpeg (standalone)
 - faac (standalone and lib for ffmpeg)
 - flac (standalone)
 - fontconfig
 - freetype
 - frei0r
 - gettext
 - gsm
 - gnutls (standalone and lib for ffmpeg)
 - lame (standalone and lib for ffmpeg)
 - jpeg
 - jpeg2000
 - jpegturbo
 - libass
 - libbluray
 - libcaca
 - libdvdcss
 - libdvdnav
 - libdvdread
 - libilbc
 - libmad
 - libmodplug
 - libmpeg2
 - libpng
 - libsoxr
 - libtiff
 - libtwolame
 - libutvideo
 - libxml2
 - libzvbi
 - mediainfo cli (only 32 bit)
 - mp3lame (standalone and lib for ffmpeg)
 - mp4box (standalone)
 - mplayer (standalone)
 - orc
 - opencore-amr
 - openjpeg
 - ogg
 - opus
 - opus-tools (standalone)
 - rtmp (standalone and lib for ffmpeg)
 - schroedinger
 - sdl (for ffplay)
 - sox (standalone)
 - speex (standalone and lib for ffmpeg)
 - theora
 - vidstab
 - vpx (standalone and lib for ffmpeg)
 - vo-aacenc
 - vo-amrwbenc
 - vorbis
 - x264 (standalone and lib for ffmpeg)
 - x264 10 bit (standalone)
 - x265 (standalone and lib for ffmpeg)
 - x265 16 bit (standalone)
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
 
The Script write a ini-file witch you can edit, so you don't need to follow the questions every time.

For all you need ~15 GB disk space.
The script doesn't build any registry key or system variables, when you don't need it any more you can delete the folder and your system will be clean. 
Build all from the begin take around ~7 hours (the cross compile script from rdp is much faster).

Later when you need only some new builds, delete the .exe files under local32\bin|local64\bin, some libs only produce *.a files, when you want to build them new, then delete that one. ffmpeg, ImageMagick, x264, x265, libvpx, libbluray and vlc have automatic update from git, so by them you don't need to delete files or folders. 

For saving space you can delete, after compiling, all source folders (except the folders with a "-git", "-svn" or "-hg" on end) in build32 and build64.
Have fun!


References
--------

http://ingar.satgnu.net/devenv/mingw32/base.html


http://kemovitra.blogspot.co.at/2009/08/mingw-to-compile-ffmpeg.html
