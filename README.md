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

Current release is **v3.5**


Included Tools And Libraries
--------

 - ffmpeg (shared or static) with that libraries:
	- decklink
	- fdkaac
	- faac
	- fontconfig
	- freetype
	- frei0r
	- gsm
	- gnutls
	- libass
	- libbluray
	- libcacas
	- libilbc
	- libmodplug
	- libpng
	- libsoxr
	- libtiff
	- libtwolame
	- libutvideo (only static)
	- libzvbi
	- mp3lame
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
	- f265
	- fdkaac
	- faac
	- ffmbc
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
	- x264 (8 and 10 bit, with gpac[mp4 output])
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
 
The Script write a ini-file, so you only need to choose the first time what you want to build.

For all you need ~7 GB disk space.
The script doesn't build any registry key or system variables, when you don't need it any more you can delete the folder and your system will be clean. 
Build all from the begin take around ~3 hours.

Later when you need only some new builds, delete the .exe files under local32\bin|local64\bin, some libs only produce *.a files, when you want to build them new, then delete that one. ffmpeg, x264, x265, libvpx, libbluray, sox and some other tools have automatic update from git, so by them you don't need to delete files or folders. 

For saving space you can delete, after compiling, all source folders (except the folders with a "-git", "-svn" or "-hg" on end) in build32 and build64. The selection in the batch file do this also for you.
Have fun!



What The Individual Files Do
--------

media-autobuild_suite.bat
 - This file set up the msys2 system and the compiler environment. For a normal using you only have to start this file. Every time you start this batch file it runs truth the process, but after the first time it only check some variables and run a update and after that it only compile this tools what have a new git version.
	
media-autobuild_suite.ini
 - This file get generated after the first start and save the settings what you have selected. Before the next run you can edit it.
	
media-suite_compile.sh
 - This is the compiling script, it builds all the libs and tools what we want, like ffmpeg; mplayer; etc. You also can inspect it and see how to compile your own source codes. Normally you can copy the code and past them in the mintty shell (expect make -j $cpuCount, here you need to put your cpu count). You don't need to start this script, it get calls by the batch script.
	
media-suite_update.sh
 - This script runs every time you run the batch file to. It checks that there is new packets what needs to get installed. It check the compiler profiles that if they are up to date. And it makes a msys2 system update. This you also don't need to start manuell. 
	
All scripts you can normally override with the newest Version and then rerun the batch process.
	


References
--------

http://ingar.satgnu.net/devenv/mingw32/base.html


http://kemovitra.blogspot.co.at/2009/08/mingw-to-compile-ffmpeg.html



**Attention: This project is searching for a new owner. Please let it me know if you are interested to continue this project, then I transfer it to you.**
