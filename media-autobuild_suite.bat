::-----------------------------------------------------------------------------
:: LICENSE --------------------------------------------------------------------
::-----------------------------------------------------------------------------
::  This Windows Batchscript is for setup a compiler environment for building
::  ffmpeg and other media tools under Windows.
::
::    Copyright (C) 2013  jb_alvarado
::
::    This program is free software: you can redistribute it and/or modify
::    it under the terms of the GNU General Public License as published by
::    the Free Software Foundation, either version 3 of the License, or
::    (at your option) any later version.
::
::    This program is distributed in the hope that it will be useful,
::    but WITHOUT ANY WARRANTY; without even the implied warranty of
::    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
::    GNU General Public License for more details.
::
::    You should have received a copy of the GNU General Public License
::    along with this program.  If not, see <https://www.gnu.org/licenses/>.
::-----------------------------------------------------------------------------

@echo off
color 80
title media-autobuild_suite

setlocal
cd /d "%~dp0"
set instdir=%CD%

if not exist %instdir% (
    echo ----------------------------------------------------------------------
    echo. You have probably run the script in a path with spaces.
    echo. This is not supported.
    echo. Please move the script to use a path without spaces. Example:
    echo. Incorrect: C:\build suite\
    echo. Correct:   C:\build_suite\
    pause
    exit
    )

if not ["%instdir:~60,1%"]==[""] (
    echo -------------------------------------------------------------------------------
    echo. The total filepath to the suite seems too large ^(larger than 60 characters^):
    echo. %instdir%
    echo. Some packages might fail building because of it.
    echo. Please move the suite directory closer to the root of your drive and maybe
    echo. rename the suite directory to a smaller name. Examples:
    echo. Avoid:  C:\Users\Administrator\Desktop\testing\media-autobuild_suite-master
    echo. Prefer: C:\media-autobuild_suite
    echo. Prefer: C:\ab-suite
    pause
    )

set _bitness=64
if %PROCESSOR_ARCHITECTURE%==x86 (
    IF NOT DEFINED PROCESSOR_ARCHITEW6432 set _bitness=32
    )

set build=%instdir%\build
if not exist %build% mkdir %build%

set msyspackages=asciidoc autoconf automake-wrapper autogen bison diffstat dos2unix help2man ^
intltool libtool patch python xmlto make zip unzip git subversion wget p7zip mercurial man-db ^
gperf winpty texinfo gyp-git doxygen autoconf-archive itstool ruby mintty flex

set mingwpackages=cmake dlfcn libpng gcc nasm pcre tools-git yasm ninja pkg-config meson

:: built-ins
set ffmpeg_options_builtin=--disable-autodetect amf bzlib cuda cuvid d3d11va dxva2 ^
iconv lzma nvenc schannel zlib sdl2 --disable-debug ffnvcodec nvdec

:: common external libs
set ffmpeg_options_basic=gmp libmp3lame libopus libvorbis libvpx libx264 libx265 ^
libdav1d

:: options used in zeranoe builds and not present above
set ffmpeg_options_zeranoe=fontconfig gnutls libass libbluray libfreetype ^
libmfx libmysofa libopencore-amrnb libopencore-amrwb libopenjpeg libsnappy ^
libsoxr libspeex libtheora libtwolame libvidstab libvo-amrwbenc libwavpack ^
libwebp libxml2 libzimg libshine gpl openssl libtls avisynth mbedtls libxvid ^
libaom version3

:: options also available with the suite
set ffmpeg_options_full=chromaprint cuda-sdk decklink frei0r libbs2b libcaca ^
libcdio libfdk-aac libflite libfribidi libgme libgsm libilbc libkvazaar ^
libmodplug libnpp libopenh264 libopenmpt librtmp librubberband libssh ^
libtesseract libxavs libzmq libzvbi opencl opengl libvmaf libcodec2 ^
libsrt ladspa #vapoursynth #liblensfun libndi_newtek

:: built-ins
set mpv_options_builtin=#cplayer #manpage-build #lua #javascript #libass ^
#libbluray #uchardet #rubberband #lcms2 #libarchive #libavdevice ^
#shaderc #crossc #d3d11 #jpeg

:: overriden defaults
set mpv_options_basic=--disable-debug-build "--lua=luajit"

:: all supported options
set mpv_options_full=dvdread dvdnav cdda egl-angle vapoursynth html-build ^
pdf-build libmpv-shared

set iniOptions=msys2Arch arch license2 vpx2 x2643 x2652 other265 flac fdkaac mediainfo soxB ffmpegB2 ffmpegUpdate ^
ffmpegChoice mp4box rtmpdump mplayer2 mpv cores deleteSource strip pack logging bmx standalone updateSuite ^
aom faac ffmbc curl cyanrip2 redshift rav1e ripgrep dav1d forceQuitBatch vvc jq dssim

set previousOptions=0
set msys2ArchINI=0
set ini=%build%\media-autobuild_suite.ini

if exist %ini% GOTO checkINI
:selectmsys2Arch
    set deleteIni=1

    if %_bitness%==64 (
        set msys2Arch=2
        ) else set msys2Arch=1

    echo.[compiler list]>%ini%
    echo.msys2Arch=^%msys2Arch%>>%ini%

    if %previousOptions%==0 for %%a in (%iniOptions%) do set %%aINI=0
    set msys2ArchINI=%msys2Arch%

    GOTO systemVars

:checkINI
set deleteIni=0
for %%a in (%iniOptions%) do (
    findstr %%a %ini% > nul
    if %ERRORLEVEL% EQU 0 (
        for /F "tokens=2 delims==" %%b in ('findstr %%a %ini%') do (
            set %%aINI=%%b
            if %%b==0 set deleteIni=1
            )
        ) else set deleteIni=1 && set %%aINI=0
    )
if %deleteINI%==1 (
    del %ini%
    set previousOptions=1
    GOTO selectmsys2Arch
    )

:systemVars
set msys2Arch=%msys2ArchINI%
if %msys2Arch%==1 set "msys2=msys32"
if %msys2Arch%==2 set "msys2=msys64"

:selectSystem
set "writeArch=no"
if %archINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Select the build target system:
    echo. 1 = both [32 bit and 64 bit]
    echo. 2 = 32 bit build system
    echo. 3 = 64 bit build system
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildEnv="Build System: "
    ) else set buildEnv=%archINI%
if %deleteINI%==1 set "writeArch=yes"

if %buildEnv%==1 (
    set "build32=yes"
    set "build64=yes"
    )
if %buildEnv%==2 (
    set "build32=yes"
    set "build64=no"
    )
if %buildEnv%==3 (
    set "build32=no"
    set "build64=yes"
    )
if %buildEnv% GTR 3 GOTO selectSystem
if %writeArch%==yes echo.arch=^%buildEnv%>>%ini%

:ffmpeglicense
set "writeLicense=no"
if %license2INI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build FFmpeg with which license?
    echo. 1 = Non-free [unredistributable, but can include anything]
    echo. 2 = GPLv3 [disables OpenSSL and FDK-AAC]
    echo. 3 = GPLv2.1
    echo.   [Same disables as GPLv3 with addition of gmp, opencore codecs]
    echo. 4 = LGPLv3
    echo.   [Disables x264, x265, XviD, GPL filters, etc.
    echo.    but reenables OpenSSL/FDK-AAC]
    echo. 5 = LGPLv2.1 [same disables as LGPLv3 + GPLv2.1]
    echo.
    echo. If building for yourself, it's OK to choose non-free.
    echo. If building to redistribute online, choose GPL or LGPL.
    echo. If building to include in a GPLv2.1 binary, choose LGPLv2.1 or GPLv2.1.
    echo. If you want to use FFmpeg together with closed source software, choose LGPL
    echo. and follow instructions in https://www.ffmpeg.org/legal.html
    echo.
    echo. OpenSSL and FDK-AAC have licenses incompatible with GPL but compatible
    echo. with LGPL, so they won't be disabled automatically if you choose LGPL.
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P ffmpegLicense="FFmpeg license: "
    ) else set ffmpegLicense=%license2INI%
if %deleteINI%==1 set "writeLicense=yes"

if %ffmpegLicense%==1 set "license2=nonfree"
if %ffmpegLicense%==2 set "license2=gplv3"
if %ffmpegLicense%==3 set "license2=gpl"
if %ffmpegLicense%==4 set "license2=lgplv3"
if %ffmpegLicense%==5 set "license2=lgpl"
if %ffmpegLicense% GTR 5 GOTO ffmpeglicense
if %writeLicense%==yes echo.license2=^%ffmpegLicense%>>%ini%

:standalone
set "writestandalone=no"
if %standaloneINI%==0 (
     echo -------------------------------------------------------------------------------
     echo -------------------------------------------------------------------------------
     echo.
     echo. Build standalone binaries for libraries included in FFmpeg?
     echo. eg. Compile opusenc.exe if --enable-libopus
     echo. 1 = Yes
     echo. 2 = No
     echo.
     echo -------------------------------------------------------------------------------
     echo -------------------------------------------------------------------------------
     set /P buildstandalone="Build standalone binaries: "
     ) else set buildstandalone=%standaloneINI%
if %deleteINI%==1 set "writestandalone=yes"

if %buildstandalone%==1 set "standalone=y"
if %buildstandalone%==2 set "standalone=n"
if %buildstandalone% GTR 2 GOTO standalone
if %writestandalone%==yes echo.standalone=^%buildstandalone%>>%ini%

:vpx
set "writevpx=no"
if %vpx2INI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build vpx [VP8/VP9/VP10 encoder]?
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo. Binaries being built depends on "standalone=y"
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildvpx="Build vpx: "
    ) else set buildvpx=%vpx2INI%
if %deleteINI%==1 set "writevpx=yes"

if %buildvpx%==1 set "vpx2=y"
if %buildvpx%==2 set "vpx2=n"
if %buildvpx% GTR 2 GOTO vpx
if %writevpx%==yes echo.vpx2=^%buildvpx%>>%ini%

:aom
set "writeaom=no"
if %aomINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build aom [Alliance for Open Media codec]?
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo. Binaries being built depends on "standalone=y"
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildaom="Build aom: "
    ) else set buildaom=%aomINI%
if %deleteINI%==1 set "writeaom=yes"

if %buildaom%==1 set "aom=y"
if %buildaom%==2 set "aom=n"
if %buildaom% GTR 2 GOTO aom
if %writeaom%==yes echo.aom=^%buildaom%>>%ini%

:rav1e
set "writerav1e=no"
if %rav1eINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build rav1e [Alternative, faster AV1 standalone encoder]?
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildrav1e="Build rav1e: "
    ) else set buildrav1e=%rav1eINI%
if %deleteINI%==1 set "writerav1e=yes"

if %buildrav1e%==1 set "rav1e=y"
if %buildrav1e%==2 set "rav1e=n"
if %buildrav1e% GTR 2 GOTO rav1e
if %writerav1e%==yes echo.rav1e=^%buildrav1e%>>%ini%

:dav1d
set "writedav1d=no"
if %dav1dINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build dav1d [Alternative, faster AV1 decoder]?
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo. Binaries being built depends on "standalone=y" and are always static.
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P builddav1d="Build dav1d: "
    ) else set builddav1d=%dav1dINI%
if %deleteINI%==1 set "writedav1d=yes"

if %builddav1d%==1 set "dav1d=y"
if %builddav1d%==2 set "dav1d=n"
if %builddav1d% GTR 2 GOTO dav1d
if %writedav1d%==yes echo.dav1d=^%builddav1d%>>%ini%

:x264
set "writex264=no"
if %x2643INI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build x264 [H.264 encoder]?
    echo. 1 = Lib/binary with 8 and 10-bit
    echo. 2 = No
    echo. 3 = Lib/binary with only 10-bit
    echo. 4 = Lib/binary with 8 and 10-bit, and libavformat and ffms2
    echo. 5 = Shared lib/binary with 8 and 10-bit
    echo. 6 = Same as 4 with video codecs only ^(can reduce size by ~3MB^)
    echo. 7 = Lib/binary with only 8-bit
    echo.
    echo. Binaries being built depends on "standalone=y" and are always static.
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildx264="Build x264: "
    ) else set buildx264=%x2643INI%
if %deleteINI%==1 set "writex264=yes"

if %buildx264%==1 set "x2643=yes"
if %buildx264%==2 set "x2643=no"
if %buildx264%==3 set "x2643=high"
if %buildx264%==4 set "x2643=full"
if %buildx264%==5 set "x2643=shared"
if %buildx264%==6 set "x2643=fullv"
if %buildx264%==7 set "x2643=o8"
if %buildx264% GTR 7 GOTO x264
if %writex264%==yes echo.x2643=^%buildx264%>>%ini%

:x265
set "writex265=no"
if %x2652INI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build x265 [H.265 encoder]?
    echo. 1 = Lib/binary with Main, Main10 and Main12
    echo. 2 = No
    echo. 3 = Lib/binary with Main10 only
    echo. 4 = Lib/binary with Main only
    echo. 5 = Lib/binary with Main, shared libs with Main10 and Main12
    echo. 6 = Same as 1 with XP support and non-XP compatible x265-numa.exe
    echo. 7 = Lib/binary with Main12 only
    echo.
    echo. Binaries being built depends on "standalone=y"
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildx265="Build x265: "
    ) else set buildx265=%x2652INI%
if %deleteINI%==1 set "writex265=yes"

if %buildx265%==1 set "x2652=y"
if %buildx265%==2 set "x2652=n"
if %buildx265%==3 set "x2652=o10"
if %buildx265%==4 set "x2652=o8"
if %buildx265%==5 set "x2652=s"
if %buildx265%==6 set "x2652=d"
if %buildx265%==7 set "x2652=o12"
if %buildx265% GTR 7 GOTO x265
if %writex265%==yes echo.x2652=^%buildx265%>>%ini%

:other265
set "writeother265=no"
if %other265INI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build Kvazaar? [H.265 encoder]
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildother265="Build kvazaar: "
    ) else set buildother265=%other265INI%
if %deleteINI%==1 set "writeother265=yes"

if %buildother265%==1 set "other265=y"
if %buildother265%==2 set "other265=n"
if %buildother265% GTR 2 GOTO other265
if %writeother265%==yes echo.other265=^%buildother265%>>%ini%

:vvc
set "writevvc=no"
if %vvcINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build Fraunhofer VVC? [H.265 successor enc/decoder]
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildvvc="Build vvc: "
    ) else set buildvvc=%vvcINI%
if %deleteINI%==1 set "writevvc=yes"

if %buildvvc%==1 set "vvc=y"
if %buildvvc%==2 set "vvc=n"
if %buildvvc% GTR 2 GOTO vvc
if %writevvc%==yes echo.vvc=^%buildvvc%>>%ini%

:flac
set "writeflac=no"
if %flacINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build FLAC? [Free Lossless Audio Codec]
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildflac="Build flac: "
    ) else set buildflac=%flacINI%
if %deleteINI%==1 set "writeflac=yes"

if %buildflac%==1 set "flac=y"
if %buildflac%==2 set "flac=n"
if %buildflac% GTR 2 GOTO flac
if %writeflac%==yes echo.flac=^%buildflac%>>%ini%

:fdkaac
set "writefdkaac=no"
if %fdkaacINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build FDK-AAC library and binary? [AAC-LC/HE/HEv2 codec]
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo. Note: FFmpeg's aac encoder is no longer experimental and considered equal or
    echo. better in quality from 96kbps and above. It still doesn't support AAC-HE/HEv2
    echo. so if you need that or want better quality at lower bitrates than 96kbps,
    echo. use FDK-AAC.
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildfdkaac="Build fdkaac: "
    ) else set buildfdkaac=%fdkaacINI%
if %deleteINI%==1 set "writefdkaac=yes"

if %buildfdkaac%==1 set "fdkaac=y"
if %buildfdkaac%==2 set "fdkaac=n"
if %buildfdkaac% GTR 2 GOTO fdkaac
if %writefdkaac%==yes echo.fdkaac=^%buildfdkaac%>>%ini%

:faac
set "writefaac=no"
if %faacINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build FAAC library and binary? [old, low-quality and nonfree AAC-LC codec]
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildfaac="Build faac: "
    ) else set buildfaac=%faacINI%
if %deleteINI%==1 set "writefaac=yes"

if %buildfaac%==1 set "faac=y"
if %buildfaac%==2 set "faac=n"
if %buildfaac% GTR 2 GOTO faac
if %writefaac%==yes echo.faac=^%buildfaac%>>%ini%

:mediainfo
set "writemediainfo=no"
if %mediainfoINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build mediainfo binaries [Multimedia file information tool]?
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildmediainfo="Build mediainfo: "
    ) else set buildmediainfo=%mediainfoINI%
if %deleteINI%==1 set "writemediainfo=yes"

if %buildmediainfo%==1 set "mediainfo=y"
if %buildmediainfo%==2 set "mediainfo=n"
if %buildmediainfo% GTR 2 GOTO mediainfo
if %writemediainfo%==yes echo.mediainfo=^%buildmediainfo%>>%ini%

:sox
set "writesox=no"
if %soxBINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build sox binaries [Sound processing tool]?
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildsox="Build sox: "
    ) else set buildsox=%soxBINI%
if %deleteINI%==1 set "writesox=yes"

if %buildsox%==1 set "sox=y"
if %buildsox%==2 set "sox=n"
if %buildsox% GTR 2 GOTO sox
if %writesox%==yes echo.soxB=^%buildsox%>>%ini%

:ffmpeg
set "writeFF=no"
if %ffmpegB2INI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build FFmpeg binaries and libraries:
    echo. 1 = Yes [static] [recommended]
    echo. 2 = No
    echo. 3 = Shared
    echo. 4 = Both static and shared [shared goes to an isolated directory]
    echo. 5 = Shared-only with some shared libs ^(libass, freetype and fribidi^)
    echo.
    echo. Note: Option 5 differs from 3 in that libass, freetype and fribidi are
    echo. compiled shared so they take less space. This one isn't tested a lot and
    echo. will fail with fontconfig enabled.
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildffmpeg="Build FFmpeg: "
    ) else set buildffmpeg=%ffmpegB2INI%
if %deleteINI%==1 set "writeFF=yes"

if %buildffmpeg%==1 set "ffmpeg=static"
if %buildffmpeg%==2 set "ffmpeg=no"
if %buildffmpeg%==3 set "ffmpeg=shared"
if %buildffmpeg%==4 set "ffmpeg=both"
if %buildffmpeg%==5 set "ffmpeg=sharedlibs"
if %buildffmpeg% GTR 5 GOTO ffmpeg
if %writeFF%==yes echo.ffmpegB2=^%buildffmpeg%>>%ini%

:ffmpegUp
set "writeFFU=no"
if %ffmpegUpdateINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Always build FFmpeg when libraries have been updated?
    echo. 1 = Yes
    echo. 2 = No
    echo. 3 = Only build FFmpeg/mpv and missing dependencies
    echo.
    echo. FFmpeg is updated a lot so you only need to select this if you
    echo. absolutely need updated external libraries in FFmpeg.
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildffmpegUp="Build ffmpeg if lib is new: "
    ) else set buildffmpegUp=%ffmpegUpdateINI%
if %deleteINI%==1 set "writeFFU=yes"

if %buildffmpegUp%==1 set "ffmpegUpdate=y"
if %buildffmpegUp%==2 set "ffmpegUpdate=n"
if %buildffmpegUp%==3 set "ffmpegUpdate=onlyFFmpeg"
if %buildffmpegUp% GTR 3 GOTO ffmpegUp
if %writeFFU%==yes echo.ffmpegUpdate=^%buildffmpegUp%>>%ini%

:ffmpegChoice
set "writeFFC=no"
if %ffmpegChoiceINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Choose ffmpeg and mpv optional libraries?
    echo. 1 = Yes
    echo. 2 = No ^(Light build^)
    echo. 3 = No ^(Mimic Zeranoe^)
    echo. 4 = No ^(All available external libs^)
    echo.
    echo. Avoid the last two unless you're really want useless libraries you'll never use.
    echo. Just because you can include a shitty codec no one uses doesn't mean you should.
    echo.
    echo. If you select yes, we will create files with the default options
    echo. we use with FFmpeg and mpv. You can remove any that you don't need or prefix
    echo. them with #
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildffmpegChoice="Choose ffmpeg and mpv optional libs: "
    ) else set buildffmpegChoice=%ffmpegChoiceINI%
if %deleteINI%==1 set "writeFFC=yes"

if %buildffmpegChoice%==1 (
    set "ffmpegChoice=y"
    if not exist %build%\ffmpeg_options.txt (
        (
            echo.# Lines starting with this character are ignored
            echo.
            echo.# Basic built-in options, can be removed if you delete "--disable-autodetect"
            call :writeOption %ffmpeg_options_builtin%
            echo.
            echo.# Common options
            call :writeOption %ffmpeg_options_basic%
            echo.
            echo.# Zeranoe
            call :writeOption %ffmpeg_options_zeranoe%
            echo.
            echo.# Full
            call :writeOption %ffmpeg_options_full%
            )>%build%\ffmpeg_options.txt
        echo -------------------------------------------------------------------------------
        echo. File with default FFmpeg options has been created in
        echo. %build%\ffmpeg_options.txt
        echo.
        echo. Edit it now or leave it unedited to compile according to defaults.
        echo -------------------------------------------------------------------------------
        pause
        )
    if not exist %build%\mpv_options.txt (
        (
            echo.# Lines starting with this character are ignored
            echo.
            echo.# Built-in options, use --disable- to disable them
            call :writeOption %mpv_options_builtin%
            echo.
            echo.# Common options or overriden defaults
            call :writeOption %mpv_options_basic%
            echo.
            echo.# Full
            call :writeOption %mpv_options_full%
            )>%build%\mpv_options.txt
        echo -------------------------------------------------------------------------------
        echo. File with default mpv options has been created in
        echo. %build%\mpv_options.txt
        echo.
        echo. Edit it now or leave it unedited to compile according to defaults.
        echo -------------------------------------------------------------------------------
        pause
        )
    )
if %buildffmpegChoice%==2 set "ffmpegChoice=n"
if %buildffmpegChoice%==3 set "ffmpegChoice=z"
if %buildffmpegChoice%==4 set "ffmpegChoice=f"
if %buildffmpegChoice% GTR 4 GOTO ffmpegChoice
if %writeFFC%==yes echo.ffmpegChoice=^%buildffmpegChoice%>>%ini%

:mp4boxStatic
set "writeMP4Box=no"
if %mp4boxINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build static mp4box [mp4 muxer/toolbox] binary?
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildMp4box="Build mp4box: "
    ) else set buildMp4box=%mp4boxINI%
if %deleteINI%==1 set "writeMP4Box=yes"

if %buildMp4box%==1 set "mp4box=y"
if %buildMp4box%==2 set "mp4box=n"
if %buildMp4box% GTR 2 GOTO mp4boxStatic
if %writeMP4Box%==yes echo.mp4box=^%buildMp4box%>>%ini%

:rtmpdump
set "writertmpdump=no"
if %rtmpdumpINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build static rtmpdump binaries [rtmp tools]?
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildrtmpdump="Build rtmpdump: "
    ) else set buildrtmpdump=%rtmpdumpINI%
if %deleteINI%==1 set "writertmpdump=yes"

if %buildrtmpdump%==1 set "rtmpdump=y"
if %buildrtmpdump%==2 set "rtmpdump=n"
if %buildrtmpdump% GTR 2 GOTO rtmpdump
if %writertmpdump%==yes echo.rtmpdump=^%buildrtmpdump%>>%ini%

:mplayer
set "writeMPlayer=no"
if %mplayer2INI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo ######### UNSUPPORTED, IF IT BREAKS, IT BREAKS ################################
    echo.
    echo. Build static mplayer/mencoder binary?
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo. Don't bother opening issues about this if it breaks, I don't fucking care
    echo. about ancient unmaintained shit code. One more issue open about this that
    echo. isn't the suite's fault and mplayer goes fucking out.
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildmplayer="Build mplayer: "
    ) else set buildmplayer=%mplayer2INI%
if %deleteINI%==1 set "writeMPlayer=yes"

if %buildmplayer%==1 set "mplayer=y"
if %buildmplayer%==2 set "mplayer=n"
if %buildmplayer% GTR 2 GOTO mplayer
if %writeMPlayer%==yes echo.mplayer2=^%buildmplayer%>>%ini%

:mpv
set "writeMPV=no"
if %mpvINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build mpv?
    echo. 1 = Yes
    echo. 2 = No
    echo. 3 = compile with Vapoursynth, if installed [see Warning]
    echo.
    echo. Note: when built with shared-only FFmpeg, mpv is also shared.
    echo. Note: Requires at least Windows Vista.
    echo. Warning: the third option isn't completely static. There's no way to include
    echo. a library dependant on Python statically. All users of the compiled binary
    echo. will need VapourSynth installed using the official package to even open mpv!
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildmpv="Build mpv: "
    ) else set buildmpv=%mpvINI%
if %deleteINI%==1 set "writeMPV=yes"

if %buildmpv%==1 set "mpv=y"
if %buildmpv%==2 set "mpv=n"
if %buildmpv%==3 set "mpv=v"
if %buildmpv% GTR 3 GOTO mpv
if %writeMPV%==yes echo.mpv=^%buildmpv%>>%ini%

:bmx
set "writeBmx=no"
if %bmxINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build static bmx tools?
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildbmx="Build bmx: "
    ) else set buildbmx=%bmxINI%
if %deleteINI%==1 set "writeBmx=yes"

if %buildbmx%==1 set "bmx=y"
if %buildbmx%==2 set "bmx=n"
if %buildbmx% GTR 2 GOTO bmx
if %writeBmx%==yes echo.bmx=^%buildbmx%>>%ini%

:curl
set "writeCurl=no"
if %curlINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build static curl?
    echo. 1 = Yes ^(same backend as FFmpeg's^)
    echo. 2 = No
    echo. 3 = SChannel backend
    echo. 4 = GnuTLS backend
    echo. 5 = OpenSSL backend
    echo. 6 = LibreSSL backend
    echo. 7 = mbedTLS backend
    echo.
    echo. A curl-ca-bundle.crt will be created to be used as trusted certificate store
    echo. for all backends except SChannel.
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildcurl="Build curl: "
    ) else set buildcurl=%curlINI%
if %deleteINI%==1 set "writeCurl=yes"

if %buildcurl%==1 set "curl=y"
if %buildcurl%==2 set "curl=n"
if %buildcurl%==3 set "curl=schannel"
if %buildcurl%==4 set "curl=gnutls"
if %buildcurl%==5 set "curl=openssl"
if %buildcurl%==6 set "curl=libressl"
if %buildcurl%==7 set "curl=mbedtls"
if %buildcurl% GTR 7 GOTO curl
if %writeCurl%==yes echo.curl=^%buildcurl%>>%ini%

:ffmbc
set "writeFFmbc=no"
if %ffmbcINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo ######### UNSUPPORTED, IF IT BREAKS, IT BREAKS ################################
    echo.
    echo. Build FFMedia Broadcast binary?
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo. Note: this is a fork of FFmpeg 0.10. As such, it's very likely to fail
    echo. to build, work, might burn your computer, kill your children, like mplayer.
    echo. Only enable it if you absolutely need it. If it breaks, complain first to
    echo. the author in #ffmbc in Freenode IRC.
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildffmbc="Build ffmbc: "
    ) else set buildffmbc=%ffmbcINI%
if %deleteINI%==1 set "writeFFmbc=yes"

if %buildffmbc%==1 set "ffmbc=y"
if %buildffmbc%==2 set "ffmbc=n"
if %buildffmbc% GTR 2 GOTO ffmbc
if %writeFFmbc%==yes echo.ffmbc=^%buildffmbc%>>%ini%

:cyanrip
set "writecyanrip=no"
if %cyanrip2INI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build cyanrip ^(CLI CD ripper^)?
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildcyanrip="Build cyanrip: "
    ) else set buildcyanrip=%cyanrip2INI%
if %deleteINI%==1 set "writecyanrip=yes"

if %buildcyanrip%==1 set "cyanrip=y"
if %buildcyanrip%==2 set "cyanrip=n"
if %buildcyanrip% GTR 2 GOTO cyanrip
if %writecyanrip%==yes echo.cyanrip2=^%buildcyanrip%>>%ini%

:redshift
set "writeredshift=no"
if %redshiftINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build redshift ^(f.lux FOSS clone^)?
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildredshift="Build redshift: "
    ) else set buildredshift=%redshiftINI%
if %deleteINI%==1 set "writeredshift=yes"

if %buildredshift%==1 set "redshift=y"
if %buildredshift%==2 set "redshift=n"
if %buildredshift% GTR 2 GOTO redshift
if %writeredshift%==yes echo.redshift=^%buildredshift%>>%ini%

:ripgrep
set "writeripgrep=no"
if %ripgrepINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build ripgrep ^(faster grep in Rust^)?
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildripgrep="Build ripgrep: "
    ) else set buildripgrep=%ripgrepINI%
if %deleteINI%==1 set "writeripgrep=yes"

if %buildripgrep%==1 set "ripgrep=y"
if %buildripgrep%==2 set "ripgrep=n"
if %buildripgrep% GTR 2 GOTO ripgrep
if %writeripgrep%==yes echo.ripgrep=^%buildripgrep%>>%ini%

:jq
set "writejq=no"
if %jqINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build jq ^(CLI JSON processor^)?
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildjq="Build jq: "
    ) else set buildjq=%jqINI%
if %deleteINI%==1 set "writejq=yes"

if %buildjq%==1 set "jq=y"
if %buildjq%==2 set "jq=n"
if %buildjq% GTR 2 GOTO jq
if %writejq%==yes echo.jq=^%buildjq%>>%ini%

:dssim
set "writedssim=no"
if %dssimINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build dssim ^(multiscale SSIM in Rust^)?
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P builddssim="Build dssim: "
    ) else set builddssim=%dssimINI%
if %deleteINI%==1 set "writedssim=yes"

if %builddssim%==1 set "dssim=y"
if %builddssim%==2 set "dssim=n"
if %builddssim% GTR 2 GOTO dssim
if %writedssim%==yes echo.dssim=^%builddssim%>>%ini%

:numCores
set "writeCores=no"
if %NUMBER_OF_PROCESSORS% GTR 1 set /a coreHalf=%NUMBER_OF_PROCESSORS%/2
if %coresINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Number of CPU Cores/Threads for compiling:
    echo. [it is non-recommended to use all cores/threads!]
    echo.
    echo. Recommended: %coreHalf%
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P cpuCores="Core/Thread Count: "
    ) else set cpuCores=%coresINI%
    for /l %%a in (1,1,%cpuCores%) do (
        set cpuCount=%%a
        )
if %deleteINI%==1 set "writeCores=yes"

if "%cpuCount%"=="" GOTO :numCores
if %writeCores%==yes echo.cores=^%cpuCount%>>%ini%

set "writeDel=no"
if %deleteSourceINI%==0 (
:delete
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Delete versioned source folders after compile is done?
    echo. 1 = Yes [recommended]
    echo. 2 = No
    echo.
    echo. This will save a bit of space for libraries not compiled from git/hg/svn.
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P deleteS="Delete source: "
    ) else set deleteS=%deleteSourceINI%
if %deleteINI%==1 set "writeDel=yes"

if %deleteS%==1 set "deleteSource=y"
if %deleteS%==2 set "deleteSource=n"
if %deleteS% GTR 2 GOTO delete
if %writeDel%==yes echo.deleteSource=^%deleteS%>>%ini%

:stripEXE
set "writeStrip=no"
if %stripINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Strip compiled files binaries?
    echo. 1 = Yes [recommended]
    echo. 2 = No
    echo.
    echo. Makes binaries smaller at only a small time cost after compiling.
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P stripF="Strip files: "
    ) else set stripF=%stripINI%
if %deleteINI%==1 set "writeStrip=yes"

if %stripF%==1 set "stripFile=y"
if %stripF%==2 set "stripFile=n"
if %stripF% GTR 2 GOTO stripEXE
if %writeStrip%==yes echo.strip=^%stripF%>>%ini%

:packEXE
set "writePack=no"
if %packINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Pack compiled files?
    echo. 1 = Yes
    echo. 2 = No [recommended]
    echo.
    echo. Attention: Some security applications may detect packed binaries as malware.
    echo. Increases delay on runtime during which files need to be unpacked.
    echo. Makes binaries smaller at a big time cost after compiling and on runtime.
    echo.
    echo. If distributing the files, consider packing them with 7-zip instead.
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P packF="Pack files: "
    ) else set packF=%packINI%
if %deleteINI%==1 set "writePack=yes"

if %packF%==1 set "packFile=y"
if %packF%==2 set "packFile=n"
if %packF% GTR 2 GOTO packEXE
if %writePack%==yes echo.pack=^%packF%>>%ini%

:logging
set "writeLogging=no"
if %loggingINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Write logs of compilation commands?
    echo. 1 = Yes [recommended]
    echo. 2 = No
    echo.
    echo Note: Setting this to yes will also hide output from these commands.
    echo On successful compilation, these logs are deleted since they aren't needed.
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P loggingF="Write logs: "
    ) else set loggingF=%loggingINI%
if %deleteINI%==1 set "writeLogging=yes"

if %loggingF%==1 set "logging=y"
if %loggingF%==2 set "logging=n"
if %loggingF% GTR 2 GOTO logging
if %writeLogging%==yes echo.logging=^%loggingF%>>%ini%

:updateSuite
set "writeUpdateSuite=no"
if %updateSuiteINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Create script to update suite files automatically?
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo If you have made changes to the scripts, they will be reset but saved to a
    echo .diff text file inside %build%
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P updateSuiteF="Create update script: "
    ) else set updateSuiteF=%updateSuiteINI%
if %deleteINI%==1 set "writeUpdateSuite=yes"

if %updateSuiteF%==1 set "updateSuite=y"
if %updateSuiteF%==2 set "updateSuite=n"
if %updateSuiteF% GTR 2 GOTO updateSuite
if %writeUpdateSuite%==yes echo.updateSuite=^%updateSuiteF%>>%ini%

:forceQuitBatch
set "writeforceQuitBatch=no"
if %forceQuitBatchINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Force quit this batch window after launching compilation script?
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo This will forcibly close this batch window. Only use this if you have the issue
    echo where the window doesn^'t close after launching the compilation script.
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P forceQuitBatchF="Forcefully close batch: "
    ) else set forceQuitBatchF=%forceQuitBatchINI%
if %deleteINI%==1 set "writeforceQuitBatch=yes"

if %forceQuitBatchF%==1 set "forceQuitBatch=y"
if %forceQuitBatchF%==2 set "forceQuitBatch=n"
if %forceQuitBatchF% GTR 2 GOTO forceQuitBatch
if %writeforceQuitBatch%==yes echo.forceQuitBatch=^%forceQuitBatchF%>>%ini%

::------------------------------------------------------------------
::download and install basic msys2 system:
::------------------------------------------------------------------
if exist "%instdir%\%msys2%\usr\bin\wget.exe" GOTO getMintty
echo -------------------------------------------------------------
echo.
echo - Download wget
echo.
echo -------------------------------------------------------------
cd build
if exist %build%\msys2-base.tar.xz GOTO unpack
if exist %build%\wget.exe if exist %build%\7za.exe if exist %build%\grep.exe GOTO checkmsys2

setlocal enabledelayedexpansion
if not exist %build%\wget.exe (
    (
        echo.[System.Net.ServicePointManager]::SecurityProtocol = 'Tls12'
        echo.$wc = New-Object System.Net.WebClient
        echo.$wc.DownloadFile^('https://i.fsbn.eu/pub/wget-pack.exe', "$PWD\wget-pack.exe"^)
        )>wget.ps1
    powershell -noprofile -executionpolicy bypass .\wget.ps1
    del wget.ps1

    for /f "tokens=1 delims=" %%a ^
in ('powershell -noprofile -command "(get-filehash -algorithm sha256 wget-pack.exe).hash"') do set _hash=%%a

    if ["!_hash!"]==["3F226318A73987227674A4FEDDE47DF07E85A48744A07C7F6CDD4F908EF28947"] (
        %build%\wget-pack.exe x
        ) else del wget-pack.exe
    )
setlocal


if not exist %build%\wget.exe (
    echo -------------------------------------------------------------------------------
    echo Script to download necessary components failed.
    echo.
    echo Download and extract this manually to inside "%build%":
    echo https://i.fsbn.eu/pub/wget-pack.exe
    echo -------------------------------------------------------------------------------
    pause
    exit
    ) else (
    del wget-pack.exe 2>nul
    )

:checkmsys2
if exist "%instdir%\%msys2%\msys2_shell.cmd" GOTO getMintty
    echo -------------------------------------------------------------------------------
    echo.
    echo.- Download and install msys2 basic system
    echo.
    echo -------------------------------------------------------------------------------
    if %msys2%==msys32 (
        set "msysprefix=i686"
        ) else set "msysprefix=x86_64"
    wget --tries=5 --retry-connrefused --waitretry=5 --continue -O msys2-base.tar.xz ^
    "http://repo.msys2.org/distrib/msys2-%msysprefix%-latest.tar.xz"

:unpack
if exist %build%\msys2-base.tar.xz (
    %build%\7za.exe x msys2-base.tar.xz -so | %build%\7za.exe x -aoa -si -ttar -o..
    del %build%\msys2-base.tar.xz
    )

if not exist %instdir%\%msys2%\usr\bin\msys-2.0.dll (
    echo -------------------------------------------------------------------------------
    echo.
    echo.- Download msys2 basic system failed,
    echo.- please download it manually from:
    echo.- http://repo.msys2.org/distrib/
    echo.- and copy the uncompressed folder to:
    echo.- %build%
    echo.- and start the batch script again!
    echo.
    echo -------------------------------------------------------------------------------
    pause
    GOTO unpack
    )

:getMintty
set "mintty=start /I /WAIT %instdir%\%msys2%\usr\bin\mintty.exe -d -i /msys2.ico"
if not exist %instdir%\mintty.lnk (
    if %msys2%==msys32 (
    echo.-------------------------------------------------------------------------------
    echo.rebase %msys2% system
    echo.-------------------------------------------------------------------------------
    call %instdir%\%msys2%\autorebase.bat
    )

    echo -------------------------------------------------------------------------------
    echo.- make a first run
    echo -------------------------------------------------------------------------------
    if exist %build%\firstrun.log del %build%\firstrun.log
    %mintty% --log 2>&1 %build%\firstrun.log /usr/bin/bash --login -c exit

    echo.-------------------------------------------------------------------------------
    echo.first update
    echo.-------------------------------------------------------------------------------
    (
        echo.echo -ne "\033]0;first msys2 update\007"
        echo.pacman --noconfirm -Sy --asdeps pacman-mirrors
        echo.sed -i "s;^^IgnorePkg.*;#&;" /etc/pacman.conf
        echo.sleep ^4
        echo.exit
        )>%build%\firstUpdate.sh
    if exist %build%\firstUpdate.log del %build%\firstUpdate.log
    %mintty% --log 2>&1 %build%\firstUpdate.log /usr/bin/bash --login %build%\firstUpdate.sh
    del %build%\firstUpdate.sh

    echo.-------------------------------------------------------------------------------
    echo.critical updates
    echo.-------------------------------------------------------------------------------
    %instdir%\%msys2%\usr\bin\sh.exe -lc "pacman -S --needed --ask=20 --noconfirm --asdeps bash pacman msys2-runtime"

    echo.-------------------------------------------------------------------------------
    echo.second update
    echo.-------------------------------------------------------------------------------
    (
        echo.echo -ne "\033]0;second msys2 update\007"
        echo.pacman --noconfirm -Syu --asdeps
        echo.exit
        )>%build%\secondUpdate.sh
    if exist %build%\secondUpdate.log del %build%\secondUpdate.log
    %mintty% --log 2>&1 %build%\secondUpdate.log /usr/bin/bash --login %build%\secondUpdate.sh
    del %build%\secondUpdate.sh

    (
        echo.Set Shell = CreateObject^("WScript.Shell"^)
        echo.Set link = Shell.CreateShortcut^("%instdir%\mintty.lnk"^)
        echo.link.Arguments = "-full-path -mingw"
        echo.link.Description = "msys2 shell console"
        echo.link.TargetPath = "%instdir%\%msys2%\msys2_shell.cmd"
        echo.link.WindowStyle = ^1
        echo.link.IconLocation = "%instdir%\%msys2%\msys2.ico"
        echo.link.WorkingDirectory = "%instdir%\%msys2%"
        echo.link.Save
        )>%build%\setlink.vbs
    cscript /nologo %build%\setlink.vbs
    del %build%\setlink.vbs
    )

    if not exist "%instdir%\%msys2%\home\%USERNAME%" mkdir "%instdir%\%msys2%\home\%USERNAME%"

    if exist "%instdir%\%msys2%\home\%USERNAME%\.minttyrc" GOTO hgsettings
    (
        echo.printf '%s\n' Locale=en_US Charset=UTF-8 ^
        Font=Consolas Columns=120 Rows=30 ^> /home/%USERNAME%/.minttyrc
        )>%build%\mintty.sh
    %mintty% /usr/bin/bash --login %build%\mintty.sh
    del %build%\mintty.sh

:hgsettings
if exist "%instdir%\%msys2%\home\%USERNAME%\.hgrc" GOTO gitsettings
    (
        echo.[ui]
        echo.username = %USERNAME%
        echo.verbose = True
        echo.editor = vim
        echo.
        echo.[web]
        echo.cacerts=/usr/ssl/cert.pem
        echo.
        echo.[extensions]
        echo.color =
        echo.
        echo.[color]
        echo.status.modified = magenta bold
        echo.status.added = green bold
        echo.status.removed = red bold
        echo.status.deleted = cyan bold
        echo.status.unknown = blue bold
        echo.status.ignored = black bold
        )>>"%instdir%\%msys2%\home\%USERNAME%\.hgrc"

:gitsettings
if exist "%instdir%\%msys2%\home\%USERNAME%\.gitconfig" GOTO installBase
    (
        echo.[user]
        echo.name = %USERNAME%
        echo.email = %USERNAME%@%COMPUTERNAME%
        echo.
        echo.[color]
        echo.ui = true
        echo.
        echo.[core]
        echo.editor = vim
        echo.autocrlf =
        echo.
        echo.[merge]
        echo.tool = vimdiff
        echo.
        echo.[push]
        echo.default = simple
        )>>"%instdir%\%msys2%\home\%USERNAME%\.gitconfig"

:installbase
if exist "%instdir%\%msys2%\etc\pac-base.pk" del "%instdir%\%msys2%\etc\pac-base.pk"
for %%i in (%msyspackages%) do echo.%%i>>%instdir%\%msys2%\etc\pac-base.pk

if exist %instdir%\%msys2%\usr\bin\make.exe GOTO sethgBat
    echo.-------------------------------------------------------------------------------
    echo.install msys2 base system
    echo.-------------------------------------------------------------------------------
    if exist %build%\install_base_failed del %build%\install_base_failed
    (
    echo.echo -ne "\033]0;install base system\007"
    echo.msysbasesystem="$(cat /etc/pac-base.pk | tr '\n\r' '  ')"
    echo.[[ "$(uname)" = *6.1* ]] ^&^& nargs="-n 4"
    echo.echo $msysbasesystem ^| xargs $nargs pacman -Sw --noconfirm --ask=20 --needed
    echo.echo $msysbasesystem ^| xargs $nargs pacman -S --noconfirm --ask=20 --needed
    echo.echo $msysbasesystem ^| xargs $nargs pacman -D --asexplicit
    echo.sleep ^3
    echo.exit
        )>%build%\pacman.sh
    if exist %build%\pacman.log del %build%\pacman.log
    %mintty% --log 2>&1 %build%\pacman.log /usr/bin/bash --login %build%\pacman.sh
    del %build%\pacman.sh

    for %%i in (%instdir%\%msys2%\usr\ssl\cert.pem) do (
        if %%~zi==0 (
            (
                echo.update-ca-trust
                echo.sleep ^3
                echo.exit
                )>%build%\cert.sh
            if exist %build%\cert.log del %build%\cert.log
            %mintty% --log 2>&1 %build%\cert.log /usr/bin/bash --login %build%\cert.sh
            del %build%\cert.sh
            )
        )

:sethgBat
if exist %instdir%\%msys2%\usr\bin\hg.bat GOTO getmingw32
(
    echo.@echo off
    echo.
    echo.setlocal
    echo.set HG=^%%~f0
    echo.
    echo.set PYTHONHOME=
    echo.set in=^%%*
    echo.set out=^%%in: ^{= ^"^{^%%
    echo.set out=^%%out:^} =^}^" ^%%
    echo.
    echo.^%%~dp0python2 ^%%~dp0hg ^%%out^%%
    )>>%instdir%\%msys2%\usr\bin\hg.bat

:getmingw32
if exist "%instdir%\%msys2%\etc\pac-mingw.pk" del "%instdir%\%msys2%\etc\pac-mingw.pk"
for %%i in (%mingwpackages%) do echo.%%i>>%instdir%\%msys2%\etc\pac-mingw.pk

if %build32%==yes (
    if exist %instdir%\%msys2%\mingw32\bin\gcc.exe GOTO getmingw64
    echo.-------------------------------------------------------------------------------
    echo.install 32 bit compiler
    echo.-------------------------------------------------------------------------------
    (
        echo.echo -ne "\033]0;install 32 bit compiler\007"
        echo.mingw32compiler="$(cat /etc/pac-mingw.pk | sed 's;.*;mingw-w64-i686-&;g' | tr '\n\r' '  ')"
        echo.[[ "$(uname)" = *6.1* ]] ^&^& nargs="-n 4"
        echo.echo $mingw32compiler ^| xargs $nargs pacman -Sw --noconfirm --ask=20 --needed
        echo.echo $mingw32compiler ^| xargs $nargs pacman -S --noconfirm --ask=20 --needed
        echo.sleep ^3
        echo.exit
        )>%build%\mingw32.sh
    if exist %build%\mingw32.log del %build%\mingw32.log
    %mintty% --log 2>&1 %build%\mingw32.log /usr/bin/bash --login %build%\mingw32.sh
    del %build%\mingw32.sh

    if not exist %instdir%\%msys2%\mingw32\bin\gcc.exe (
        echo -------------------------------------------------------------------------------
        echo.
        echo.MinGW32 GCC compiler isn't installed; maybe the download didn't work
        echo.Do you want to try it again?
        echo.
        echo -------------------------------------------------------------------------------
        set /P try32="try again [y/n]: "

        if [%try32%]==[y] (
            GOTO getmingw32
            ) else exit
        )
    )

:getmingw64
if %build64%==yes (
    if exist %instdir%\%msys2%\mingw64\bin\gcc.exe GOTO updatebase
    echo.-------------------------------------------------------------------------------
    echo.install 64 bit compiler
    echo.-------------------------------------------------------------------------------
    (
        echo.echo -ne "\033]0;install 64 bit compiler\007"
        echo.mingw64compiler="$(cat /etc/pac-mingw.pk | sed 's;.*;mingw-w64-x86_64-&;g' | tr '\n\r' '  ')"
        echo.[[ "$(uname)" = *6.1* ]] ^&^& nargs="-n 4"
        echo.echo $mingw64compiler ^| xargs $nargs pacman -Sw --noconfirm --ask=20 --needed
        echo.echo $mingw64compiler ^| xargs $nargs pacman -S --noconfirm --ask=20 --needed
        echo.sleep ^3
        echo.exit
        )>%build%\mingw64.sh
    if exist %build%\mingw64.log del %build%\mingw64.log
    %mintty% --log 2>&1 %build%\mingw64.log /usr/bin/bash --login %build%\mingw64.sh
    del %build%\mingw64.sh

    if not exist %instdir%\%msys2%\mingw64\bin\gcc.exe (
        echo -------------------------------------------------------------------------------
        echo.
        echo.MinGW64 GCC compiler isn't installed; maybe the download didn't work
        echo.Do you want to try it again?
        echo.
        echo -------------------------------------------------------------------------------
        set /P try64="try again [y/n]: "

        if [%try64%]==[y] (
            GOTO getmingw64
            ) else exit
        )
    )

:updatebase
echo.-------------------------------------------------------------------------------
echo.update autobuild suite
echo.-------------------------------------------------------------------------------

cd %build%
set scripts=compile helper update
for %%s in (%scripts%) do (
    if not exist "%build%\media-suite_%%s.sh" (
        %instdir%\%msys2%\usr\bin\wget.exe -t 20 --retry-connrefused --waitretry=2 -c ^
        https://github.com/jb-alvarado/media-autobuild_suite/raw/master/build/media-suite_%%s.sh
        )
    )
if %updateSuite%==y (
    if not exist %instdir%\update_suite.sh (
        echo -------------------------------------------------------------------------------
        echo. Creating suite update file...
        echo.
        echo. Run this file by dragging it to mintty before the next time you run
        echo. the suite and before reporting an issue.
        echo.
        echo. It needs to be run separately and with the suite not running!
        echo -------------------------------------------------------------------------------
        )
    (
        echo.#!/bin/bash
        echo.
        echo.# Run this file by dragging it to mintty shortcut.
        echo.# Be sure the suite is not running before using it!
        echo.
        echo.update=yes
        %instdir%\%msys2%\usr\bin\sed -n '/start suite update/,/end suite update/p' ^
            %build%/media-suite_update.sh
        )>%instdir%\update_suite.sh
    )

:createFolders
if %build32%==yes call :createBaseFolders local32
if %build64%==yes call :createBaseFolders local64

:checkFstab
if not exist %instdir%\%msys2%\etc\fstab. GOTO writeFstab
set "removefstab=no"

set "grep=%instdir%\%msys2%\usr\bin\grep.exe"
set fstab=%instdir%\%msys2%\etc\fstab

%grep% -q build32 %fstab% && set "removefstab=yes"
%grep% -q trunk %fstab% || set "removefstab=yes"

for /f "tokens=1 delims= " %%a in ('%grep% trunk %fstab%') do set searchRes=%%a
if not [%searchRes%]==[%instdir%\] set "removefstab=yes"

%grep% -q local32 %fstab%
if not errorlevel 1 (
    if [%build32%]==[no] set "removefstab=yes"
    ) else (
    if [%build32%]==[yes] set "removefstab=yes"
    )

%grep% -q local64 %fstab%
if not errorlevel 1 (
    if [%build64%]==[no] set "removefstab=yes"
    ) else (
    if [%build64%]==[yes] set "removefstab=yes"
    )

if [%removefstab%]==[yes] (
    del %instdir%\%msys2%\etc\fstab.
    GOTO writeFstab
    ) else (
    GOTO update
    )

    :writeFstab
    echo -------------------------------------------------------------------------------
    echo.
    echo.- write fstab mount file
    echo.
    echo -------------------------------------------------------------------------------

    set cygdrive=no

    if exist %instdir%\%msys2%\etc\fstab. (
        for /f %%b in ('findstr /i binary %instdir%\%msys2%\etc\fstab.') do set cygdrive=yes
        )
    if "%cygdrive%"=="no" echo.none / cygdrive binary,posix=0,noacl,user 0 ^0>>%instdir%\%msys2%\etc\fstab.
    (
        echo.
        echo.%instdir%\ /trunk
        echo.%instdir%\build\ /build
        echo.%instdir%\%msys2%\mingw32\ /mingw32
        echo.%instdir%\%msys2%\mingw64\ /mingw64
        )>>%instdir%\%msys2%\etc\fstab.
    if "%build32%"=="yes" echo.%instdir%\local32\ /local32>>%instdir%\%msys2%\etc\fstab.
    if "%build64%"=="yes" echo.%instdir%\local64\ /local64>>%instdir%\%msys2%\etc\fstab.

:update
if exist %build%\update.log del %build%\update.log
%mintty% -t "update autobuild suite" --log 2>&1 %build%\update.log ^
/usr/bin/bash -l /build/media-suite_update.sh --build32=%build32% --build64=%build64%

if exist "%build%\update_core" (
    echo.-------------------------------------------------------------------------------
    echo.critical updates
    echo.-------------------------------------------------------------------------------
    %instdir%\%msys2%\usr\bin\sh.exe -l -c "pacman -S --needed --noconfirm --ask=20 --asdeps bash pacman msys2-runtime"
    del "%build%\update_core"
    )

if %msys2%==msys32 (
    echo.-------------------------------------------------------------------------------
    echo.second rebase %msys2% system
    echo.-------------------------------------------------------------------------------
    call %instdir%\%msys2%\autorebase.bat
    )

::------------------------------------------------------------------
:: write config profiles:
::------------------------------------------------------------------

if %build32%==yes call :writeProfile 32
if %build64%==yes call :writeProfile 64

:loginProfile
if exist %instdir%\%msys2%\etc\profile.pacnew ^
move /y %instdir%\%msys2%\etc\profile.pacnew %instdir%\%msys2%\etc\profile
%instdir%\%msys2%\usr\bin\grep -q -e 'profile2.local' %instdir%\%msys2%\etc\profile || (
    echo.if [[ -z "$MSYSTEM" ^|^| "$MSYSTEM" = MINGW64 ]]; then
    echo.   source /local64/etc/profile2.local
    echo.elif [[ -z "$MSYSTEM" ^|^| "$MSYSTEM" = MINGW32 ]]; then
    echo.   source /local32/etc/profile2.local
    echo.fi
    )>%instdir%\%msys2%\etc\profile.d\Zab-suite.sh

:compileLocals
cd %instdir%

if [%build64%]==[yes] (
    set MSYSTEM=MINGW64
    ) else set MSYSTEM=MINGW32

title MABSbat
for /f "tokens=2" %%P in ('tasklist /v ^|findstr MABSbat') do set ourPID=%%P

if exist %build%\compile.log del %build%\compile.log
start /I %instdir%\%msys2%\usr\bin\mintty.exe -i /msys2.ico -t "media-autobuild_suite" ^
--log 2>&1 %build%\compile.log /bin/env MSYSTEM=%MSYSTEM% MSYS2_PATH_TYPE=inherit /usr/bin/bash --login ^
/build/media-suite_compile.sh --cpuCount=%cpuCount% --build32=%build32% --build64=%build64% --deleteSource=%deleteSource% ^
--mp4box=%mp4box% --vpx=%vpx2% --x264=%x2643% --x265=%x2652% --other265=%other265% --flac=%flac% --fdkaac=%fdkaac% ^
--mediainfo=%mediainfo% --sox=%sox% --ffmpeg=%ffmpeg% --ffmpegUpdate=%ffmpegUpdate% --ffmpegChoice=%ffmpegChoice% ^
--mplayer=%mplayer% --mpv=%mpv% --license=%license2%  --stripping=%stripFile% --packing=%packFile% ^
--rtmpdump=%rtmpdump% --logging=%logging% --bmx=%bmx% --standalone=%standalone% --aom=%aom% ^
--faac=%faac% --ffmbc=%ffmbc% --curl=%curl% --cyanrip=%cyanrip% --redshift=%redshift% ^
--rav1e=%rav1e% --ripgrep=%ripgrep% --dav1d=%dav1d% --vvc=%vvc% --jq=%jq% --dssim=%dssim%'

endlocal
:: if [%forceQuitBatch%]==[y] taskkill /pid %ourPID% /f
goto :EOF

:createBaseFolders
if not exist %instdir%\%1\share (
    echo.-------------------------------------------------------------------------------
    echo.creating %1-bit install folders
    echo.-------------------------------------------------------------------------------
    mkdir %instdir%\%1
    mkdir %instdir%\%1\bin
    mkdir %instdir%\%1\bin-audio
    mkdir %instdir%\%1\bin-global
    mkdir %instdir%\%1\bin-video
    mkdir %instdir%\%1\etc
    mkdir %instdir%\%1\include
    mkdir %instdir%\%1\lib
    mkdir %instdir%\%1\lib\pkgconfig
    mkdir %instdir%\%1\share
    )
goto :EOF

:writeProfile
(
    echo.MSYSTEM=MINGW%1
    echo.source /etc/msystem
    echo.
    echo.# package build directory
    echo.LOCALBUILDDIR=/build
    echo.# package installation prefix
    echo.LOCALDESTDIR=/local%1
    echo.export LOCALBUILDDIR LOCALDESTDIR
    echo.
    echo.bits='%1bit'
    echo.
    echo.alias dir='ls -la --color=auto'
    echo.alias ls='ls --color=auto'
    echo.export CC=gcc
    echo.
    echo.CARCH="${MINGW_CHOST%%%%-*}"
    echo.CPATH="`cygpath -m $LOCALDESTDIR/include`;`cygpath -m $MINGW_PREFIX/include`"
    echo.LIBRARY_PATH="`cygpath -m $LOCALDESTDIR/lib`;`cygpath -m $MINGW_PREFIX/lib`"
    echo.export CPATH LIBRARY_PATH
    echo.
    echo.MANPATH="${LOCALDESTDIR}/share/man:${MINGW_PREFIX}/share/man:/usr/share/man"
    echo.INFOPATH="${LOCALDESTDIR}/share/info:${MINGW_PREFIX}/share/info:/usr/share/info"
    echo.
    echo.DXSDK_DIR="${MINGW_PREFIX}/${MINGW_CHOST}"
    echo.ACLOCAL_PATH="${LOCALDESTDIR}/share/aclocal:${MINGW_PREFIX}/share/aclocal:/usr/share/aclocal"
    echo.PKG_CONFIG="${MINGW_PREFIX}/bin/pkg-config --static"
    echo.PKG_CONFIG_PATH="${LOCALDESTDIR}/lib/pkgconfig:${MINGW_PREFIX}/lib/pkgconfig"
    echo.CPPFLAGS="-D_FORTIFY_SOURCE=2 -D__USE_MINGW_ANSI_STDIO=1"
    echo.CFLAGS="-mthreads -mtune=generic -O2 -pipe"
    echo.CXXFLAGS="${CFLAGS}"
    echo.LDFLAGS="-pipe -static-libgcc -static-libstdc++"
    echo.export DXSDK_DIR ACLOCAL_PATH PKG_CONFIG PKG_CONFIG_PATH CPPFLAGS CFLAGS CXXFLAGS LDFLAGS MSYSTEM
    echo.
    echo.export CARGO_HOME="/opt/cargo" RUSTUP_HOME="/opt/cargo"
    echo.
    echo.export PYTHONPATH=
    echo.
    echo.LANG=en_US.UTF-8
    echo.PATH="${LOCALDESTDIR}/bin:${MINGW_PREFIX}/bin:${INFOPATH}:${MSYS2_PATH}:${ORIGINAL_PATH}"
    echo.PATH="${LOCALDESTDIR}/bin-audio:${LOCALDESTDIR}/bin-global:${LOCALDESTDIR}/bin-video:${PATH}"
    echo.PATH="/opt/cargo/bin:/opt/bin:${PATH}"
    echo.source '/etc/profile.d/perlbin.sh'
    echo.PS1='\[\033[32m\]\u@\h \[\e[33m\]\w\[\e[0m\]\n\$ '
    echo.HOME="/home/${USERNAME}"
    echo.GIT_GUI_LIB_DIR=`cygpath -w /usr/share/git-gui/lib`
    echo.export LANG PATH PS1 HOME GIT_GUI_LIB_DIR
    echo.stty susp undef
    echo.cd /trunk
    echo.test -f "$LOCALDESTDIR/etc/custom_profile" ^&^& source "$LOCALDESTDIR/etc/custom_profile"
    )>%instdir%\local%1\etc\profile2.local
%instdir%\%msys2%\usr\bin\dos2unix -q %instdir%\local%1\etc\profile2.local
goto :EOF

:writeOption
setlocal enabledelayedexpansion
for %%i in (%*) do (
    set _opt=%%~i
    if ["!_opt:~0,2!"]==["--"] (
            echo !_opt!
        ) else if ["!_opt:~0,3!"]==["#--"] (
            echo !_opt!
        ) else if ["!_opt:~0,1!"]==["#"] (
            echo #--enable-!_opt:~1!
        ) else (
            echo --enable-!_opt!
        )
    )
setlocal
goto :EOF
