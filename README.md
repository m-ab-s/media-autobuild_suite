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
        - amd amf encoders (built-in)
        - cuda (built-in)
        - cuvid (built-in)
        - libmp3lame (mingw)
        - libopus (mingw)
        - libvorbis (mingw)
        - libvpx (git)
        - libx264 (git)
        - libx265 (hg)
        - nvenc (built-in)
        - schannel with gmp (mingw)
            - enabled by default if openssl, libtls or gnutls aren't enabled
            - gmp can be switched by gcrypt (mingw) with --enable-gcrypt
        - sdl2 (2.0.5) (needed for ffplay)
            - enabled by default, use --disable-sdl2 if unneeded
    - Zeranoe-emulating build (in addition to Light)
        - avisynth (needs avisynth dll installed)
        - fontconfig (git)
        - only one of these TLS libs (including schannel) can be enabled at once:
            - openssl (mingw)
                - preferred to gnutls and to libtls if all three are in options
                - needs non-GPL license
            - gnutls (latest release)
            - libtls (from libressl) (latest release)
                - needs non-GPL license
        - libass (git)
            - by default with DirectWrite backend
            - if --enable-fontconfig, fontconfig backend included
            - with harfbuzz (git)
        - libbluray (git)
            - BD-J support requires installation of Java JDK
            - BD-J support after compilation probably only requires JRE (untested)
        - libfreetype (git)
        - libmfx (git)
        - libmodplug (mingw)
        - libopencore-amr(nb/wb) (mingw)
        - libopenjpeg2 (mingw)
        - libsnappy (mingw)
        - libsoxr (git)
        - libspeex (mingw)
        - libtheora (mingw)
        - libtwolame (mingw)
        - libvidstab (git snapshot)
        - libvo-amrwbenc (0.1.3)
        - libwavpack (mingw)
        - libwebp (git)
        - libxml2 (mingw)
        - libzimg (git)
    - Full build (in addition to Zeranoe)
        - chromaprint (mingw)
        - decklink (10.9.3)
            - needs non-free license
        - frei0r (git)
        - libbs2b (3.1.0)
        - libaom (git)
        - libcaca (mingw)
        - libcdio (mingw)
        - libfdk-aac (git)
            - needs non-free license if not LGPL
        - libflite (git)
        - libfribidi (git)
        - libgme (git snapshot)
        - libgsm (mingw)
        - libilbc (git snapshot)
        - libkvazaar (git)
        - libmysofa (git)
            - needed for sofalizer filter
        - libnpp (needs CUDA SDK installed)
            - needs non-free license
        - libopenh264 (official binaries)
        - libopenmpt (svn from beta release)
        - librtmp (git)
        - librubberband (git snapshot)
        - libsrt (git)
        - libssh (mingw)
        - libtesseract (git)
        - libvmaf (git)
        - libcodec2 (0.7)
        - libxavs (svn snapshot)
        - libxvid (mingw)
            - compiled with gnutls or openssl depending on license chosen
        - libzmq (mingw)
        - libzvbi (0.2.35)
        - opencl (from system)
        - opengl (from system)
        - scale_cuda (needs CUDA SDK and MSVC **2015** installed)
            - if it doesn't work, blame Nvidia/Microsoft, don't bother opening issues about this
            - needs non-free license and --enable-cuda-sdk

 - other tools
    - aom (git)
    - bmx (git)
    - curl (latest release) with WinSSL/LibreSSL/OpenSSL/GnuTLS backend
    - cyanrip (git)
    - faac (1.28)
    - fdk-aac (git)
    - ffmbc (git) (unsupported)
    - flac (git)
    - kvazaar (git)
    - lame (3.99.5)
    - libaacs (git) (shared)
    - libbdplus (git) (shared)
    - mediainfo cli (git)
    - mp4box (git)
    - mplayer (svn) (unsupported)
    - mpv (git) including in addition to ffmpeg libs:
        - Base build (ffmpegChoice=2 or 3)
            - ANGLE (from https://i.fsbn.eu/pub/angle/)
            - lcms2 (mingw)
            - libass (git)
            - libbluray (git)
                - BD-J support requires installation of Java JDK
                - BD-J support after compilation probably only requires JRE (untested)
            - luajit (mingw)
            - mujs (git)
            - rubberband (git snapshot)
            - uchardet (mingw)
            - vulkan, shaderc, crossc (git)
        - Full build (ffmpegChoice=4)
            - dvdread (git)
            - dvdnav (git)
            - libarchive (mingw)
            - shared libmpv
            - vapoursynth (if installed or standalone inside /local(32|64))
    - opus-tools (git)
    - redshift (git)
    - rtmpdump (git)
    - speex (git)
    - sox (14.4.2)
    - opensrt tools (git)
    - tesseract (git)
    - vorbis-tools (git snapshot)
    - vpx (VP8 and VP9 8, 10 and 12 bit) (git)
    - webp tools (git)
    - x264 (8 and 10 bit, with l-smash [mp4 output], lavf and ffms2) (git)
    - x265 (8, 10 and 12 bit) (hg)
    - xvid (1.3.5)


--------
 Requirements
--------

- Windows 32/64-bits (tested with Win10 64-bits; 32-bits is not tested at all by anyone, avoid)
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

`media-autobuild_suite.bat`
 - This file sets up the msys2 system and the compiler environment. For normal use you only have to start this file. Every time you start this batch file it runs through the process, but after the first time it only checks some variables and run updates to the MinGW environment. After that it only compiles the tools that get updates from svn/git/hg.

`/build/media-autobuild_suite.ini`
 - This file get generated after the first start and saves the settings that you have selected. Before the next run you can edit it.

`/build/media-suite_compile.sh`
 - This is the compiling script, it builds all the libs and tools we want, like ffmpeg; mplayer; etc. You can also inspect it and see how to compile your own tools. Normally you can copy the code and paste it in the mintty shell (except `make -j $cpuCount`, here you need to put your cpu count). You don't need to start this script, it's called by the batch script.

`/build/media-suite_update.sh`
 - This script runs every time you run the batch file. It checks for updates to the MinGW environment.

`/build/media-suite_helper.sh`
 - This script contains helper functions used by compile and update that can also be `source`'d by the user if desired.

`/build/ffmpeg_options.txt` & `/build/mpv_options.txt`
 - If you select the option to choose your own FFmpeg/mpv optional libraries, this file will contain options that get sent to FFmpeg/mpv's configure script before compiling. Edit this file as you wish to get a smaller FFmpeg/mpv without features you don't need or with additional features not compiled by default, if supported.


References
--------

http://ingar.satgnu.net/devenv/mingw32/base.html

http://kemovitra.blogspot.co.at/2009/08/mingw-to-compile-ffmpeg.html
