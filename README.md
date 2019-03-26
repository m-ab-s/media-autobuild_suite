# media-autobuild_suite

Before opening an issue, check if it's an issue directly from executing the suite. This isn't Doom9, reddit, stackoverflow or any other forum for general questions about the things being compiled. This script builds them, that's all.

This source code is also mirrored in [GitLab](https://gitlab.com/RiCON/media-autobuild_suite).

Most git sources in the suite use GitHub, so if it's down, it's probably useless to run the suite at that time.

## Download

**[Click here to download latest version](https://github.com/jb-alvarado/media-autobuild_suite/archive/master.zip)**

For information about the compiler environment see the wiki, there you also have a example of how to compile your own tools.

## Included Tools And Libraries

### [Information about FFmpeg external libraries](https://github.com/jb-alvarado/media-autobuild_suite/wiki/ffmpeg_options.txt)

- FFmpeg (shared or static) with these libraries (all optional, but compiled by default unless said otherwise):
    - Light build:
        - amd amf encoders (built-in)
        - cuda (built-in)
        - cuvid (built-in)
        - ffnvcodec (git)
        - libdav1d (git)
        - libmp3lame (mingw)
        - libopus (mingw)
        - libvorbis (mingw)
        - libvpx (git)
        - libx264 (git)
        - libx265 (hg)
        - nvdec (built-in)
        - nvenc (built-in)
        - schannel with gmp (mingw)
            - enabled by default if openssl, libtls, mbedtls or gnutls aren't enabled
            - gmp can be switched by gcrypt (mingw) with --enable-gcrypt
        - sdl2 (2.0.9) (needed for ffplay)
            - enabled by default, use --disable-sdl2 if unneeded
    - Zeranoe-emulating build (in addition to Light)
        - avisynth (needs avisynth dll installed)
        - fontconfig (2.13.1)
        - only one of these TLS libs (including schannel) can be enabled at once:
            - openssl (mingw)
                - preferred to gnutls and to libtls if all three are in options
                - needs non-GPL license
            - libtls (from libressl) (latest release)
                - needs non-GPL license
            - mbedtls (mingw)
                - preferred to gnutls if GPLv3 license is chosen
            - gnutls (latest release)
        - libaom (git)
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
        - libopenmpt (svn from beta release)
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
        - libxvid (1.3.5)
        - libzimg (git)
    - Full build (in addition to Zeranoe)
        - chromaprint (mingw)
        - cuda filters (needs CUDA SDK installed)
            - needs non-free license
        - decklink (10.9.3)
            - needs non-free license
        - frei0r (git)
        - ladspa (mingw)
        - libbs2b (3.1.0)
        - libcaca (mingw)
        - libcdio (mingw)
        - libcodec2 (0.8)
        - libdavs2 (git)
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
        - librtmp (git)
        - librubberband (git snapshot)
        - libsrt (git)
        - libssh (mingw)
        - libtesseract (git)
        - libvmaf (git)
        - libxavs (svn snapshot)
        - libxavs2 (git)
        - libzmq (mingw)
        - libzvbi (0.2.35)
        - opencl (from system)
        - opengl (from system)

- other tools
    - aom (git)
    - bmx (git)
    - curl (latest release) with WinSSL/LibreSSL/OpenSSL/mbedTLS/GnuTLS backend
    - cyanrip (git)
    - dav1d (git)
    - dssim (git)
    - faac (1.29.9.2)
    - fdk-aac (git)
    - ffmbc (git) (unsupported)
    - flac (git)
    - haisrt tools (git)
    - jq (git)
    - kvazaar (git)
    - lame (3.100)
    - libaacs (git) (shared)
    - libbdplus (git) (shared)
    - mediainfo cli (git)
    - mp4box (git)
    - mplayer (svn) (unsupported)
    - mpv (git) including in addition to ffmpeg libs:
        - Base build (ffmpegChoice=2 or 3)
            - ANGLE (from <https://i.fsbn.eu/pub/angle/>)
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
    - rav1e (git)
    - redshift (git)
    - ripgrep (git latest release)
    - rtmpdump (git)
    - sox (14.4.2)
    - speex (git)
    - tesseract (git)
    - vorbis-tools (git snapshot)
    - vpx (VP8 and VP9 8, 10 and 12 bit) (git)
    - vvc tools (git)
    - webp tools (git)
    - x264 (8 and 10 bit, with l-smash [mp4 output], lavf and ffms2) (git)
    - x265 (8, 10 and 12 bit) (hg)
    - xvid (1.3.5)

--------

## Requirements

--------

- Windows 32/64-bits (tested with Win10 64-bits; 32-bits is not tested at all by anyone, avoid)
- NTFS drive
- 13GB+ disk space for a full 32 and 64-bit build, 8GB+ for 64-bit
- 4GB+ RAM

--------

## Information

--------

This tool is inspired by the very nice, linux cross-compiling tool from Roger Pack (rdp):
<https://github.com/rdp/ffmpeg-windows-build-helpers>

It is based on msys2 and tested under Windows 7, 8.1. and 10.
<http://sourceforge.net/projects/msys2/>

I use some jscript parts from nu774:
<https://github.com/nu774/fdkaac_autobuild>

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
Building everything from scratch takes about ~3 hours depending on what is enabled.

Check [forcing-recompilations](./doc/forcing-recompilations.md) to check how you can force a rebuild of all libs/binaries.

To save a bit of space you can delete, after compiling, all source folders (except the folders with a "-git", "-svn" or "-hg" on end) in /build. There's an option in the .bat for the script to remove these folders automatically.

Have fun!

## Troubleshooting

--------

If there's some error during compilation follow these steps:

1. Make sure you're using the latest version of this suite by downloading the [latest version](https://github.com/jb-alvarado/media-autobuild_suite/archive/master.zip) and replacing all files with the new ones;
2. If you know which part it's crashing on, delete that project's folder in /build and run the script again (ex: if x264 is failing, try deleting x264-git folder in /build);
3. If it still doesn't work, [create an issue](https://github.com/jb-alvarado/media-autobuild_suite/issues/new) and paste the URL to `logs.zip` that the script gives or attach the file yourself to the issue page.
4. If the problem isn't reproducible by the contributors of the suite, it's probably a problem on your side. Delete /msys32, /msys64, /local32 and /local64 if they exist. /build is usually safe to keep and saves time;
5. If the problem is reproducible, it could be a problem with the package itself or the contributors will find a way to probably make it work.
6. If you compile with `--enable-libnpp` and/or `--enable-cuda-sdk`, see [Notes about CUDA SDK](#notes-about-cuda-sdk)

## What The Individual Files Do

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

## Optional User Files

--------

`/local32|64/etc/custom_profile` & `$HOME/custom_build_options`

- Put here any general/platform tweaks that you need for _your_ specific environment. See `/local32|64/etc/profile2.local` for example usage.

## Notes about CUDA SDK

--------

### This is for cuda-nvcc and libnpp, not for NVENC, it is built with ffmpeg by default

For `--enable-cuda-nvcc` and `--enable-libnpp` to work, you need NVIDIA's [CUDA SDK](https://developer.nvidia.com/cuda-toolkit) installed with `CUDA_PATH` variable to be set system-wide and VS2017 installed which should come with vswhere.exe. If for some reason `CUDA_PATH` isn't set and/or `vswhere.exe` isn't installed, you need to export the `CUDA_PATH` variable path using the above mentioned user files and manually export the correct `PATH` including the absolute cygpath-converted path to MSVC's `cl.exe`.

### You do not need to do the following if you installed the SDK with the default locations etc

### Nothing should be disabled manually when installing CUDA SDK as disabling random things can cause the compilation to fail

For example, if you need to manually set the CUDA_PATH and include in the PATH the binaries for MSVC `cl.exe` and `nvcc.exe`, add this bit of bash script inside a text file in `/local64/etc/custom_profile`:

```bash
# adapt these to your environment
_cuda_basepath="C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA"
_cuda_version=10.0

_msvc_basepath="C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC"
_msvc_version=14.15.26726
_msvc_hostarch=x64
_msvc_targetarch=x64

# you shouldn't need to change these unless your environment is weird or you know what you're doing
export CUDA_PATH=$(cygpath -sm "${_cuda_basepath}")/${_cuda_version}
export PATH=$PATH:$(dirname "$(cygpath -u "\\${_msvc_basepath}\\${_msvc_version}\bin\Host\\${_msvc_hostarch}\\${_msvc_targetarch}\cl.exe")")
export PATH=$PATH:$CUDA_PATH/bin
```

## References

--------

<http://ingar.satgnu.net/devenv/mingw32/base.html>

<http://kemovitra.blogspot.co.at/2009/08/mingw-to-compile-ffmpeg.html>
