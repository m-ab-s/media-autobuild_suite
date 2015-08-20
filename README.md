media-autobuild_suite
=========

This tool is inspired by the very nice, linux cross-compiling tool from Roger Pack (rdp):
https://github.com/rdp/ffmpeg-windows-build-helpers

It is based on msys2 and tested under Windows 7 and 8.1.
http://sourceforge.net/projects/msys2/

I use some jscript parts from nu774:
https://github.com/nu774/fdkaac_autobuild

Thanks to all of them!


For information about the compiler environment see the wiki, there you also have a example of how to compile your own tools.

Download
--------

### [Click here to download latest version](https://github.com/jb-alvarado/media-autobuild_suite/archive/master.zip)

Current release is **v3.6**

Known Issues
--------
 - FFmpeg and FFmpeg-based (mplayer, mpv)
	- if compiled with OpenSSL instead of GnuTLS, packing doesn't work in 64-bit
	- [libmfx is not WinXP-friendly][1], so don't use it as option if you're compiling for XP

Included Tools And Libraries
--------

 - FFmpeg (shared or static) with these libraries (all optional, but compiled by default):
	- decklink 10.4.1
	- fontconfig (2.11.92)
	- freetype (2.5.5)
	- frei0r (1.4)
	- fribidi (0.19.6)
	- gnutls (3.3.15) (3.4 doesn't work well with ffmpeg)
	- harfbuzz (git)
	- libass (git)
	- libbs2b (3.1.0)
	- libbluray (git)
	- libcaca (0.99.beta19)
	- libcdio-paranoia (git)
	- libdcadec (git)
	- libfdk-aac (git)
	- libgsm
	- libilbc (git)
	- libkvazaar (git)
	- libmfx (git)
	- libmodplug
	- libmp3lame
	- libopencore-amrwb/nb (0.1.3)
	- libopenjpeg 2.1 (git)
	- libopus (1.1)
	- librtmp (git)
	- libschroedinger
	- libsoxr (0.1.1)
	- libspeex (1.2rc2)
	- libtheora (1.1.1)
	- libtwolame (git)
	- libutvideo (git/15.1.0)
	- libvo-aacenc (0.1.3)
	- libvo-amrwbenc (0.1.2)
	- libvorbis (1.3.5)
	- libvpx (git)
	- libx264 (git)
	- libx265 (hg)
	- libxavs (svn snapshot)
	- libxvid
	- libzvbi (0.2.35)
	- nvenc (5.0.1)
	- sdl (1.2.15)
	- vidstab (git)
	
 - other tools
	- f265 (git)
	- fdkaac (git)
	- file (5.22)
	- flac (1.3.1)
	- gnutls (3.3.15) (3.4 doesn't work well with ffmpeg)
	- kvazaar (git)
	- libsndfile (git)
	- mediainfo cli (git)
	- mp4box (git)
	- mplayer (svn)
	- mpv (git) including in addition to ffmpeg libs:
		- libjpeg-turbo (git)
		- librubberband (git)
		- libuchardet (git)
		- libwaio (git)
		- luajit (git)
	- opus-tools (0.1.9)
	- rtmpdump (git)
	- speex (1.2rc2)
	- sox (git)
	- vpx (VP8 and VP9 8, 10 and 12 bit) (git)
	- x264 (8 and 10 bit, with l-smash [mp4 output]) (git)
	- x265 (8, 10 and 12 bit) (git)
	- xavs (git snapshot)


--------


This Windows Batchscript setups a MinGW/GCC compiler environment for building ffmpeg and other media tools under Windows.
After building the environment it retrieves and compiles all tools. All tools get static compiled, no external .dlls needed (with some optional exceptions)

How to use it:
 - Download the file, and extract it to your target folder or `git clone` the project. Compilers and tools will get installed there. Please make sure you use a folder without space characters. A good place is: c:\mingw
 - Double click the media-autobuild_suite.bat file
 - Select the toolchain you'll want (select the one your operating system is on, if you don't know it's probably 64-bit)
 - Select if you want to compile for Windows 32-bit, 64-bit or both
 - Select if you want to compile non-free tools like "fdk aac"
 - Select the numbers of CPU (cores) you want to use
 - Wait a little bit, and hopefully after a while you'll find all your "*.exe" tools under local32\bin-audio/global/video or local64\bin-audio/global/video
 
The Script writes a ini-file, so you only need to make these choices the first time what you want to build.

For all you need ~7 GB disk space.
The script doesn't build any registry key or system variables, when you don't need it any more you can delete the folder and your system will be clean. 
Building everything from the beginning takes around ~3 hours.

Later when you need only some new builds, delete the .exe files under local32\bin|local64\bin, some libs only produce *.a files, when you want to build them new, then delete that one under /local32/lib or /local64/lib. ffmpeg, x264, x265, libvpx, libbluray, sox and some other tools have frequent updates from git, so for them you probably don't need to delete files or folders to get updated versions. 

To save a bit of space you can delete, after compiling, all source folders (except the folders with a "-git", "-svn" or "-hg" on end) in /build. There's an option in the .bat for the script to remove these folders itself.

Have fun!



What The Individual Files Do
--------

media-autobuild_suite.bat
 - This file sets up the msys2 system and the compiler environment. For normal use you only have to start this file. Every time you start this batch file it runs through the process, but after the first time it only checks some variables and run updates to the MinGW environment. After that it only compiles the tools that get updates from svn/git/hg.
	
media-autobuild_suite.ini
 - This file get generated after the first start and saves the settings that you have selected. Before the next run you can edit it.
	
media-suite_compile.sh
 - This is the compiling script, it builds all the libs and tools we want, like ffmpeg; mplayer; etc. You can also inspect it and see how to compile your own tools. Normally you can copy the code and paste it in the mintty shell (except `make -j $cpuCount`, here you need to put your cpu count). You don't need to start this script, it get called by the batch script.
	
media-suite_update.sh
 - This script runs every time you run the batch file. It checks for updates to the MinGW environment.

/build/ffmpeg_options.txt
 - If you select the option to choose your own FFmpeg optional libraries, this file will contain options that get sent to FFmpeg's configure script before compiling. Edit this file as you wish to get a smaller FFmpeg without features you don't need.
	

Troubleshooting
--------

If there's some error during compilation follow these steps:
 1. Make sure you're using the latest version of this suite by downloading the [latest version](https://github.com/jb-alvarado/media-autobuild_suite/archive/master.zip) and replacing all files with the new ones;
 2. If you know which part it's crashing on, delete that project's folder in /build and run the script again (ex: if f265 is failing, delete f265-git folder in /build);
 3. If it still doesn't work, [create an issue](https://github.com/jb-alvarado/media-autobuild_suite/issues/new) and paste the contents of the compilation window, the contents of the .ini file and contents of ffmpeg_options.txt if you're using it;
 4. If the problem isn't reproducible by the contributors of the suite, it's probably a problem on your side and/or some issue with MinGW. Delete /msys32, /msys64, /local32 and /local64 if they exist. /build is safe to keep;
 5. If the problem is reproducible, it could be a problem with the package itself or the contributors will find a way to probably make it work.


References
--------

http://ingar.satgnu.net/devenv/mingw32/base.html

http://kemovitra.blogspot.co.at/2009/08/mingw-to-compile-ffmpeg.html

[1]: https://github.com/rdp/ffmpeg-windows-build-helpers/commit/c48af053657e174e270249e4b28a83c35897e320


**Attention: This project is searching for a new owner. Please let it me know if you are interested to continue this project, then I transfer it to you.**
