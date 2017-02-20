media-autobuild_suite
=========
[![Join the chat at https://gitter.im/jb-alvarado/media-autobuild_suite](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/jb-alvarado/media-autobuild_suite)

This source code is also mirrored in [GitLab](https://gitlab.com/RiCON/media-autobuild_suite).

Most git sources in the suite use GitHub, so if it's down, it's probably useless to run the suite at that time.


Download
--------

#### [Click here to download latest version](https://github.com/jb-alvarado/media-autobuild_suite/archive/master.zip)

For information about the compiler environment see the wiki, there you also have a example of how to compile your own tools.


Included Tools And Libraries
--------

### [Information about FFmpeg external libraries](https://github.com/jb-alvarado/media-autobuild_suite/wiki/ffmpeg_options.txt)

 - FFmpeg (shared or static) with these libraries (all optional, but compiled by default unless said otherwise):
    - Light build:
        - avisynth (built-in)
        - cuda (built-in)
        - cuvid (built-in)
        - libmp3lame (mingw)
        - libopus (git)
        - libvorbis (mingw)
        - libvpx (git)
        - libx264 (git)
        - libx265 (hg)
        - nvenc (built-in)
        - schannel with gcrypt (1.7.3)
            - enabled by default if openssl or gnutls aren't enabled
            - libgcrypt can be switched by gmp with --enable-gmp
    - Zeranoe-emulating build (in addition to Light)
        - decklink (10.8.3)
        - fontconfig (2.12.1)
        - frei0r (git)
        - gnutls (latest release)
        - libressl (latest release)
            - preferred instead of gnutls if both are in options and license is not GPL
        - libass (git)
            - by default with DirectWrite backend
            - if --enable-fontconfig or XP support required, fontconfig backend included
        - libbluray (git)
        - libbs2b (3.1.0)
        - libcaca (mingw)
        - libfreetype (2.7)
        - libfribidi (0.19.7)
        - libgme (git snapshot)
        - libgsm (mingw)
        - libilbc (git snapshot)
        - libmfx (git)
        - libmodplug (mingw)
        - libopencore-amr(nb/wb) (mingw)
        - libopenjpeg2 (mingw)
        - librtmp (git)
            - compiled with gnutls or openssl depending on license chosen
        - libschroedinger (mingw)
        - libsnappy (mingw)
        - libsoxr (git)
        - libspeex (mingw)
        - libtheora (mingw)
        - libtwolame (mingw)
        - libvidstab (git snapshot)
        - libvo-amrwbenc (0.1.3)
        - libwavpack (mingw)
        - libwebp (git)
        - libxavs (svn snapshot)
        - libxvid (mingw)
        - libzimg (git)
    - Full build (in addition to Zeranoe)
        - chromaprint (mingw)
        - libcdio (mingw)
        - libfdk-aac (git)
        - libkvazaar (git)
        - libnpp (needs CUDA SDK)
        - libopenh264 (mingw)
        - libopenmpt (git)
        - librubberband (git snapshot)
        - libssh (mingw)
        - libtesseract (git)
        - libzvbi (0.2.35)
        - netcdf (mingw)
        - opencl (from system)
        - opengl (from system)
        - sdl2 (mingw) (needed for ffplay)

 - other tools
    - aom (git)
    - bmx (git)
    - curl (latest release) with WinSSL/LibreSSL/GnuTLS backend
    - daala (git)
    - faac (1.28)
    - fdk-aac (git)
    - flac (git)
    - kvazaar (git)
    - lame (3.99.5)
    - mediainfo cli (git)
    - mp4box (git)
    - mplayer (svn) (unsupported)
    - mpv (git) including in addition to ffmpeg libs:
        - uchardet (mingw)
        - ANGLE (git)
        - luajit (mingw)
        - vapoursynth (if installed or standalone inside /local(32|64))
    - opus-tools (git)
    - rtmpdump (git)
    - speex (git)
    - sox (14.4.2)
    - tesseract (git)
    - vorbis-tools (git snapshot)
    - vpx (VP8 and VP9 8, 10 and 12 bit) (git)
    - webp tools (git)
    - x264 (8 and 10 bit, with l-smash [mp4 output], lavf and ffms2) (git)
    - x265 (8, 10 and 12 bit) (hg)


--------
 Requirements
--------

- Windows 32/64-bits (tested with 7, 8.1 and 10)
- NTFS drive
- 8GB+ disk space for a full 32 and 64-bit build
- 4GB+ RAM

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
Building everything from scratch takes about ~3 hours.

Check doc/forcing-recompilations.md to check how you can force a rebuild of all libs/binaries.

To save a bit of space you can delete, after compiling, all source folders (except the folders with a "-git", "-svn" or "-hg" on end) in /build. There's an option in the .bat for the script to remove these folders automatically.

Have fun!


Troubleshooting
--------

If there's some error during compilation follow these steps:
 1. Make sure you're using the latest version of this suite by downloading the [latest version](https://github.com/jb-alvarado/media-autobuild_suite/archive/master.zip) and replacing all files with the new ones;
 2. If you know which part it's crashing on, delete that project's folder in /build and run the script again (ex: if x264 is failing, try deleting x264-git folder in /build);
 3. If it still doesn't work, [create an issue](https://github.com/jb-alvarado/media-autobuild_suite/issues/new) and paste the URL to `logs.zip` that the script gives or attach the file yourself to the issue page.
 4. If the problem isn't reproducible by the contributors of the suite, it's probably a problem on your side. Delete /msys32, /msys64, /local32 and /local64 if they exist. /build is usually safe to keep and saves time;
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
