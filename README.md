---
title: media-autobuild_suite

description: A Windows automatic build script for ffmpeg and other media tools

author: Jonathan Baecker (jb_alvarado)

created:  2013-09-24

modified: 2014-07-13

---


media-autobuild_suite
=========

This tool is inspire by the very nice, linux cross compile, tool from Roger Pack(rdp):
https://github.com/rdp/ffmpeg-windows-build-helpers

It is based on msys2 and tested under Windows 7.
http://sourceforge.net/projects/msys2/

I use some jscipt parts from nu774:
https://github.com/nu774/fdkaac_autobuild

Thanks to all of them!


For Informations about the compiler environment see the wiki, there you also have a example of how to compile your own tools.

Download
--------

### [Click here to download latest version](https://github.com/jb-alvarado/media-autobuild_suite/archive/master.zip)

Current release is **v2.7**


Included Tools And Libraries
--------

 - ffmpeg (shared or static) with that libraries:
	- fdkaac
	- faac
	- fontconfig
	- freetype
	- frei0r
	- gsm
	- gnutls
	- libass
	- libbluray
	- libcaca
	- libilbc
	- libmodplug
	- libpng
	- libsoxr
	- libtiff
	- libtwolame
	- libutvideo (only in the static ffmpeg version)
	- libzvbi
	- mp3lame
	- openal
	- opencore-amr
	- openjpeg
	- ogg
	- opus
	- rtmp
	- schroedinger
	- sdl
	- speex
	- theora
	- vidstab
	- vpx
	- vo-aacenc
	- vo-amrwbenc
	- vorbis
	- wavpack
	- x264
	- x265
	- xavs
	- xvid
	
 - other tools
	- exiv2
	- fdkaac
	- faac
	- file
	- flac
	- gnutls
	- kvazaar
	- libsndfile
	- mediainfo cli
	- mp4box
	- mpg123
	- mplayer
	- mkvtoolnix
	- mpv
	- opus-tools
	- rtmp
	- speex
	- sox 
	- vpx
	- x264 (8 and 10 bit)
	- x265 (8 and 16 bit)
	- xavs	


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

For all you need ~5 GB disk space.
The script doesn't build any registry key or system variables, when you don't need it any more you can delete the folder and your system will be clean. 
Build all from the begin take around ~3 hours.

Later when you need only some new builds, delete the .exe files under local32\bin|local64\bin, some libs only produce *.a files, when you want to build them new, then delete that one. ffmpeg, x264, x265, libvpx, libbluray, sox and some other tools have automatic update from git, so by them you don't need to delete files or folders. 

For saving space you can delete, after compiling, all source folders (except the folders with a "-git", "-svn" or "-hg" on end) in build32 and build64.
Have fun!


References
--------

http://ingar.satgnu.net/devenv/mingw32/base.html


http://kemovitra.blogspot.co.at/2009/08/mingw-to-compile-ffmpeg.html
