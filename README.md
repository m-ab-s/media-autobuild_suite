media-autobuild_suite
=========
[![Join the chat at https://gitter.im/jb-alvarado/media-autobuild_suite](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/jb-alvarado/media-autobuild_suite)

Known Issues
--------
 - FFmpeg and FFmpeg-based (mplayer, mpv)
	- if compiled with OpenSSL instead of GnuTLS, packing doesn't work in 64-bit

Download
--------

#### [Click here to download latest version](https://github.com/jb-alvarado/media-autobuild_suite/archive/master.zip)

For information about the compiler environment see the wiki, there you also have a example of how to compile your own tools.


Included Tools And Libraries
--------

### [Information about FFmpeg external libraries](https://github.com/jb-alvarado/media-autobuild_suite/wiki/FFmpeg-external-libraries)

 - FFmpeg (shared or static) with these libraries (all optional, but compiled by default unless said otherwise):
	- decklink 10.5
	- fontconfig (2.11.94)
	- freetype (2.6.2)
	- frei0r (1.4)
	- fribidi (0.19.7)
	- SChannel, gnutls (3.4.x), or openssl
		- SChannel used by default
		- If `--enable-openssl` and license is LGPL or nonfree, openssl is preferred
	- harfbuzz (1.1.2)
	- libass (git) (with directwrite backend) (with fontconfig too if 32-bit)
	- libbs2b (3.1.0)
	- libbluray (git)
	- libcaca
	- libcdio-paranoia
	- libdcadec (git)
	- libfaac (1.28)
		- Not compiled by default
	- libfdk-aac (git)
		- Not compiled by default
	- libgsm
	- libilbc (git)
	- libkvazaar (git)
	- libmfx (git)
	- libmodplug
	- libmp3lame (3.99.5)
	- libopencore-amrwb/nb
	- libopenjpeg2 (git)
		- Not compiled by default
	- libopus (1.1.2)
	- librtmp (git)
		- Not compiled by default
	- librubberband (git)
	- libschroedinger
	- libsnappy
		- Not compiled by default
	- libsoxr (0.1.1)
	- libspeex (1.2rc2)
	- libssh
		- Not compiled by default
	- libtesseract (git)
	- libtheora
	- libtwolame (git)
	- libutvideo (git/15.1.0)
		- Not compiled by default
	- libvo-aacenc (0.1.3)
		- Not compiled by default
	- libvo-amrwbenc (0.1.2)
	- libvorbis
	- libvpx (git)
	- libwavpack
		- Not compiled by default
	- libwebp (git) (needed for webp encoding)
	- libx264 (git)
	- libx265 (hg)
	- libxavs (svn snapshot)
	- libxvid
	- libzimg (git)
	- libzvbi (0.2.35)
	- nvenc (6.0.1)
	- sdl (1.2.15)
	- vidstab (git)
	
 - other tools
 	- bmx (git)
	- f265 (git)
    - faac (1.28)
	- fdk-aac (git)
	- file (5.22)
	- flac (1.3.1)
	- kvazaar (git)
	- lame (3.99.5)
	- mediainfo cli (git)
	- mp4box (git)
	- mplayer (svn)
	- mpv (git) including in addition to ffmpeg libs:
		- uchardet
		- ANGLE (git snapshot)
		- luajit (git)
		- vapoursynth (if installed)
	- opus-tools (0.1.9)
	- rtmpdump (git)
	- speex (1.2rc2)
	- sox (git)
	- tesseract (git)
	- vorbis-tools (1.4.0)
	- vpx (VP8, VP9 and VP10 8, 10 and 12 bit) (git)
	- webp tools (git)
	- x264 (8 and 10 bit, with l-smash [mp4 output]) (git)
	- x265 (8, 10 and 12 bit) (git)


--------
 Information
--------

This tool is inspired by the very nice, linux cross-compiling tool from Roger Pack (rdp):
https://github.com/rdp/ffmpeg-windows-build-helpers

It is based on msys2 and tested under Windows 7, 8.1. and 10.
http://sourceforge.net/projects/msys2/

I use some jscript parts from nu774:
https://github.com/nu774/fdkaac_autobuild

Thanks to all of them!

This Windows Batchscript setups a MinGW/GCC compiler environment for building ffmpeg and other media tools under Windows.
After building the environment it retrieves and compiles all tools. All tools get static compiled, no external .dlls needed (with some optional exceptions)

How to use it:
 - Download the file, and extract it to your target folder or `git clone` the project. Compilers and tools will get installed there. Please make sure you use a folder without space characters. A good place is: c:\mingw
 - Double click the media-autobuild_suite.bat file
 - Select the toolchain you'll want (select the one your operating system is on, if you don't know it's probably 64-bit)
 - Select if you want to compile for Windows 32-bit, 64-bit or both
 - Select if you want to compile non-free tools like "fdk aac"
 - Select the numbers of CPU (cores) you want to use
 - Wait a little bit, and hopefully after a while you'll find all your "*.exe" tools under local32\bin-(audio/global/video) or local64\bin-(audio/global/video)
 
The Script writes a ini-file, so you only need to make these choices the first time what you want to build.

For all you need ~7 GB disk space.
The script doesn't build any registry key or system variables, when you don't need it any more you can delete the folder and your system will be clean. 
Building everything from the beginning takes around ~3 hours.

Later when you need only some new builds, delete the .exe files under local32\bin|local64\bin, some libs only produce *.a files, when you want to build them new, then delete that one under /local32/lib or /local64/lib. ffmpeg, x264, x265, libvpx, libbluray, sox and some other tools have frequent updates from git, so for them you probably don't need to delete files or folders to get updated versions. 

To save a bit of space you can delete, after compiling, all source folders (except the folders with a "-git", "-svn" or "-hg" on end) in /build. There's an option in the .bat for the script to remove these folders itself.

Have fun!


Troubleshooting
--------

If there's some error during compilation follow these steps:
 1. Make sure you're using the latest version of this suite by downloading the [latest version](https://github.com/jb-alvarado/media-autobuild_suite/archive/master.zip) and replacing all files with the new ones;
 2. If you know which part it's crashing on, delete that project's folder in /build and run the script again (ex: if f265 is failing, delete f265-git folder in /build);
 3. If it still doesn't work, [create an issue](https://github.com/jb-alvarado/media-autobuild_suite/issues/new) and pack `ffmpeg_options.txt`, `mpv_options.txt`, `media-autobuild_suite.ini`, `compile.log`, `update.log` and every `ab-suite.*.log` files in the package that fails to a .zip and attach to the issue page.
 4. If the problem isn't reproducible by the contributors of the suite, it's probably a problem on your side and/or some issue with MinGW. Delete /msys32, /msys64, /local32 and /local64 if they exist. /build is usually safe to keep and saves time;
 5. If the problem is reproducible, it could be a problem with the package itself or the contributors will find a way to probably make it work.


What The Individual Files Do
--------

media-autobuild_suite.bat
 - This file sets up the msys2 system and the compiler environment. For normal use you only have to start this file. Every time you start this batch file it runs through the process, but after the first time it only checks some variables and run updates to the MinGW environment. After that it only compiles the tools that get updates from svn/git/hg.
	
/build/media-autobuild_suite.ini
 - This file get generated after the first start and saves the settings that you have selected. Before the next run you can edit it.
	
/build/media-suite_compile.sh
 - This is the compiling script, it builds all the libs and tools we want, like ffmpeg; mplayer; etc. You can also inspect it and see how to compile your own tools. Normally you can copy the code and paste it in the mintty shell (except `make -j $cpuCount`, here you need to put your cpu count). You don't need to start this script, it's called by the batch script.
	
/build/media-suite_update.sh
 - This script runs every time you run the batch file. It checks for updates to the MinGW environment.

/build/media-suite_helper.sh
 - This script contains helper functions used by compile and update that can also be `source`'d by the user if desired.

/build/ffmpeg_options.txt
 - If you select the option to choose your own FFmpeg optional libraries, this file will contain options that get sent to FFmpeg's configure script before compiling. Edit this file as you wish to get a smaller FFmpeg without features you don't need or with additional features not compiled by default, if supported.


References
--------

http://ingar.satgnu.net/devenv/mingw32/base.html

http://kemovitra.blogspot.co.at/2009/08/mingw-to-compile-ffmpeg.html

[1]: https://github.com/rdp/ffmpeg-windows-build-helpers/commit/c48af053657e174e270249e4b28a83c35897e320


**Attention: This project is searching for a new owner. Please let it me know if you are interested to continue this project, then I transfer it to you.**
