::-------------------------------------------------------------------------------------
:: LICENSE -------------------------------------------------------------------------
::-------------------------------------------------------------------------------------
::  This Windows Batchscript is for setup a compiler environment for building ffmpeg and other media tools under Windows.
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
::    along with this program.  If not, see <http://www.gnu.org/licenses/>.
::-------------------------------------------------------------------------------------

@echo off
color 80
title media-autobuild_suite

setlocal
set instdir=%CD%
set "ini=build\media-autobuild_suite.ini"

if not exist %instdir% (
    echo -------------------------------------------------------------------------------
    echo. You have probably run the script in a path with spaces.
    echo. This is not supported.
    echo. Please move the script to use a path without spaces. Example:
    echo. Incorrect: C:\build suite\
    echo. Correct:   C:\build_suite\
    pause
    exit
    )

if not ["%CD:~60,1%"]==[""] (
    echo -------------------------------------------------------------------------------
    echo. The total filepath to the suite seems too large (larger than 67 characters^):
    echo. %CD%
    echo. Some packages will fail building because of it.
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
gperf winpty texinfo upx gyp-git

set mingwpackages=cmake dlfcn doxygen libpng gcc nasm pcre tools-git yasm ninja pkg-config lz4

set ffmpeg_options=--enable-avisynth --enable-gcrypt --enable-libmp3lame ^
--enable-libopus --enable-libvorbis --enable-libvpx --enable-libx264 --enable-libx265 ^
--enable-cuda --enable-cuvid --enable-schannel

set ffmpeg_options_zeranoe=--enable-decklink --enable-fontconfig ^
--enable-frei0r --enable-gnutls --enable-libass --enable-libbluray --enable-libbs2b ^
--enable-libcaca --enable-libfreetype --enable-libfribidi ^
--enable-libgme --enable-libgsm --enable-libilbc --enable-libmfx --enable-libmodplug ^
--enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libopenjpeg ^
--enable-librtmp --enable-libschroedinger --enable-libsoxr --enable-libspeex ^
--enable-libtheora --enable-libtwolame --enable-libvidstab --enable-libvo-amrwbenc ^
--enable-libwavpack --enable-libwebp --enable-libxavs --enable-libxvid --enable-libzimg ^
--enable-openssl --enable-libsnappy --enable-gpl

set ffmpeg_options_full=--enable-opencl --enable-opengl --enable-libcdio ^
--enable-libfdk-aac --enable-libkvazaar --enable-librubberband ^
--enable-libssh --enable-libtesseract --enable-libzvbi ^
--enable-chromaprint --enable-libopenh264 --enable-libopenmpt ^
--enable-netcdf --enable-libnpp --enable-sdl2

set mpv_options=--enable-dvdread --enable-dvdnav --enable-libbluray --enable-libass --enable-rubberband ^
--enable-lua --enable-uchardet --enable-libarchive --enable-lcms2 --disable-debug-build ^
--enable-vapoursynth --disable-libmpv-shared --enable-egl-angle-lib --enable-html-build ^
--enable-pdf-build --enable-manpage-build

set iniOptions=msys2Arch arch license2 vpx2 x2642 x2652 other265 flac fdkaac mediainfo soxB ffmpegB ffmpegUpdate ^
ffmpegChoice mp4box rtmpdump mplayer mpv cores deleteSource strip pack xpcomp logging bmx standalone updateSuite ^
aom daala faac

set previousOptions=0
set msys2ArchINI=0

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
    if errorlevel 1 set deleteIni=1 && set %%aINI=0
    if errorlevel 0 for /F "tokens=2 delims==" %%b in ('findstr %%a %ini%') do (
        set %%aINI=%%b
        if %%b==0 set deleteIni=1
        )
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
    echo. Build FFmpeg/rtmpdump with which license?
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
    echo. In the case of rtmpdump, since its binaries are GPL, it will be compiled
    echo. with GnuTLS if LGPL is chosen, but if Non-free will use OpenSSL.
    echo. If not building rtmpdump, but just librtmp ^(which is LGPL^) to use in FFmpeg,
    echo. OpenSSL can be used.
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

:xpcomp
set "writexpcomp=no"
if %xpcompINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build libraries/binaries compatible with Windows XP when possible?
    echo. 1 = Yes
    echo. 2 = No [recommended]
    echo.
    echo. Examples: x265, disabled QuickSync and mpv, etc.
    echo. This usually causes worse performance in all systems.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildxpcomp="Build with XP compatibility: "
    ) else set buildxpcomp=%xpcompINI%
if %deleteINI%==1 set "writexpcomp=yes"

if %buildxpcomp%==1 set "xpcomp=y"
if %buildxpcomp%==2 set "xpcomp=n"
if %buildxpcomp% GTR 2 GOTO xpcomp
if %writexpcomp%==yes echo.xpcomp=^%buildxpcomp%>>%ini%

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

:daala
set "writedaala=no"
if %daalaINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build daala [Daala codec]?
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo. Binaries being built depends on "standalone=y"
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P builddaala="Build daala: "
    ) else set builddaala=%daalaINI%
if %deleteINI%==1 set "writedaala=yes"

if %builddaala%==1 set "daala=y"
if %builddaala%==2 set "daala=n"
if %builddaala% GTR 2 GOTO daala
if %writedaala%==yes echo.daala=^%builddaala%>>%ini%

:x264
set "writex264=no"
if %x2642INI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build x264 [H.264 encoder]?
    echo. 1 = 8-bit lib/binary and 10-bit binary
    echo. 2 = No
    echo. 3 = 10-bit lib/binary
    echo. 4 = 8-bit lib/binary and 10-bit binary with libavformat and ffms2
    echo.
    echo. Binaries being built depends on "standalone=y"
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildx264="Build x264: "
    ) else set buildx264=%x2642INI%
if %deleteINI%==1 set "writex264=yes"

if %buildx264%==1 set "x2642=y"
if %buildx264%==2 set "x2642=n"
if %buildx264%==3 set "x2642=h"
if %buildx264%==4 set "x2642=f"
if %buildx264% GTR 4 GOTO x264
if %writex264%==yes echo.x2642=^%buildx264%>>%ini%

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
    echo. 6 = Same as 1 with addition of non-XP compatible x265-numa.exe
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
    echo. Build Kvazaar?
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo. Binary being built depends on "standalone=y"
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildother265="Build kvazaar: "
    ) else set buildother265=%other265INI%
if %deleteINI%==1 set "writeother265=yes"

if %buildother265%==1 set "other265=y"
if %buildother265%==2 set "other265=n"
if %buildother265% GTR 2 GOTO other265
if %writeother265%==yes echo.other265=^%buildother265%>>%ini%

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
if %ffmpegBINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build FFmpeg binaries and libraries:
    echo. 1 = Yes [static] [recommended]
    echo. 2 = No
    echo. 3 = Shared
    echo. 4 = Both static and shared [shared goes to an isolated directory]
    echo.
    echo. Note: mpv needs FFmpeg static libraries.
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildffmpeg="Build FFmpeg: "
    ) else set buildffmpeg=%ffmpegBINI%
if %deleteINI%==1 set "writeFF=yes"

if %buildffmpeg%==1 set "ffmpeg=static"
if %buildffmpeg%==2 set "ffmpeg=no"
if %buildffmpeg%==3 set "ffmpeg=shared"
if %buildffmpeg%==4 set "ffmpeg=both"
if %buildffmpeg% GTR 4 GOTO ffmpeg
if %writeFF%==yes echo.ffmpegB=^%buildffmpeg%>>%ini%

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
            for %%i in (%ffmpeg_options%) do echo.%%i
            echo.# Zeranoe
            for %%i in (%ffmpeg_options_zeranoe%) do echo.#%%i
            echo.# Full
            for %%i in (%ffmpeg_options_full%) do echo.#%%i
            )>>%build%\ffmpeg_options.txt
        echo -------------------------------------------------------------------------------
        echo. File with default FFmpeg options has been created in
        echo. %build%\ffmpeg_options.txt
        echo.
        echo. Edit it now or leave it unedited to compile according to defaults.
        echo -------------------------------------------------------------------------------
        pause
        )
    if not exist %build%\mpv_options.txt (
        for %%i in (%mpv_options%) do echo.%%i>>%build%\mpv_options.txt
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
if %mplayerINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build static mplayer/mencoder binary?
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildmplayer="Build mplayer: "
    ) else set buildmplayer=%mplayerINI%
if %deleteINI%==1 set "writeMPlayer=yes"

if %buildmplayer%==1 set "mplayer=y"
if %buildmplayer%==2 set "mplayer=n"
if %buildmplayer% GTR 2 GOTO mplayer
if %writeMPlayer%==yes echo.mplayer=^%buildmplayer%>>%ini%

:mpv
set "writeMPV=no"
if %mpvINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build static mpv binary?
    echo. 1 = Yes
    echo. 2 = No
    echo. 3 = compile with Vapoursynth, if installed [see Warning]
    echo.
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

::------------------------------------------------------------------
::download and install basic msys2 system:
::------------------------------------------------------------------
if exist "%instdir%\%msys2%\usr\bin\wget.exe" GOTO getMintty
echo -------------------------------------------------------------
echo.
echo - Download wget
echo.
echo -------------------------------------------------------------
if exist %build%\install-wget.js del %build%\install-wget.js
cd build
if exist %build%\msys2-base.tar.xz GOTO unpack
if exist %build%\wget.exe if exist %build%\7za.exe if exist %build%\grep.exe GOTO checkmsys2
if not exist %build%\wget.exe (
    if exist wget-pack.exe del wget-pack.exe
    (
        echo./*from http://superuser.com/a/536400*/
        echo.var r=new ActiveXObject("WinHttp.WinHttpRequest.5.1"^);
        echo.r.Open("GET",WScript.Arguments(0^),false^);r.Send(^);
        echo.b=new ActiveXObject("ADODB.Stream"^);
        echo.b.Type=1;b.Open(^);b.Write(r.ResponseBody^);
        echo.b.SaveToFile(WScript.Arguments(1^)^);
        )>wget.js

    cscript /nologo wget.js https://i.fsbn.eu/pub/wget-pack.exe wget-pack.exe
    %build%\wget-pack.exe x
    )
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
    del wget.js wget-pack.exe 2>nul
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
        echo.pacman --noconfirm -Sy --force --asdeps pacman-mirrors
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
    %instdir%\%msys2%\usr\bin\sh.exe -l -c "pacman -S --needed --noconfirm --asdeps bash pacman msys2-runtime"

    echo.-------------------------------------------------------------------------------
    echo.second update
    echo.-------------------------------------------------------------------------------
    (
        echo.echo -ne "\033]0;second msys2 update\007"
        echo.pacman --noconfirm -Syu --force --asdeps
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

    if exist "%instdir%\%msys2%\home\%USERNAME%\.minttyrc" GOTO hgsettings
    if not exist "%instdir%\%msys2%\home\%USERNAME%" mkdir "%instdir%\%msys2%\home\%USERNAME%"
        (
            echo.BoldAsFont=yes
            echo.BackgroundColour=39,40,34
            echo.ForegroundColour=248,248,242
            echo.Transparency=off
            echo.FontHeight=^9
            echo.FontSmoothing=default
            echo.AllowBlinking=yes
            echo.Font=Consolas
            echo.Columns=120
            echo.Rows=30
            echo.Term=xterm-256color
            echo.CursorType=block
            echo.ClicksPlaceCursor=yes
            echo.Locale=en_US
            echo.Charset=UTF-8
            echo.Black=39,40,34
            echo.Red=249,38,114
            echo.Green=166,226,46
            echo.Yellow=244,191,117
            echo.Blue=102,217,239
            echo.Magenta=174,129,255
            echo.Cyan=161,239,228
            echo.White=248,248,242
            echo.BoldBlack=117,113,94
            echo.BoldRed=204,6,78
            echo.BoldGreen=122,172,24
            echo.BoldYellow=240,169,69
            echo.BoldBlue=33,199,233
            echo.BoldMagenta=126,51,255
            echo.BoldCyan=95,227,210
            echo.BoldWhite=249,248,245
            )>>"%instdir%\%msys2%\home\%USERNAME%\.minttyrc"

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
    echo.echo $msysbasesystem ^| xargs $nargs pacman -Sw --noconfirm --needed
    echo.echo $msysbasesystem ^| xargs $nargs pacman -S --noconfirm --needed
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
        echo.echo $mingw32compiler ^| xargs $nargs pacman -Sw --noconfirm --needed --force
        echo.echo $mingw32compiler ^| xargs $nargs pacman -S --noconfirm --needed --force
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

        if %packF%==y (
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
        echo.echo $mingw64compiler ^| xargs $nargs pacman -Sw --noconfirm --needed --force
        echo.echo $mingw64compiler ^| xargs $nargs pacman -S --noconfirm --needed --force
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

        if %packF%==y (
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
if not exist %build%\last_run if exist %build%\update.log del %build%\update.log
%mintty% -t "update autobuild suite" %instdir%\%msys2%\usr\bin\script.exe -a -q -f %build%\update.log ^
-c '/usr/bin/bash --login /build/media-suite_update.sh --build32=%build32% --build64=%build64%'

if exist "%build%\update_core" (
    echo.-------------------------------------------------------------------------------
    echo.critical updates
    echo.-------------------------------------------------------------------------------
    %instdir%\%msys2%\usr\bin\sh.exe -l -c "pacman -S --needed --noconfirm --asdeps bash pacman msys2-runtime"
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

:writeProfile32
if %build32%==yes (
    if exist %instdir%\local32\etc\profile2.local GOTO writeProfile64
        echo -------------------------------------------------------------------------------
        echo.
        echo.- write profile for 32 bit compiling
        echo.
        echo -------------------------------------------------------------------------------
        (
            echo.# /local32/etc/profile2.local
            echo.#
            echo.
            echo.MSYSTEM=MINGW32
            echo.
            echo.# package build directory
            echo.LOCALBUILDDIR=/build
            echo.# package installation prefix
            echo.LOCALDESTDIR=/local32
            echo.export LOCALBUILDDIR LOCALDESTDIR
            echo.
            echo.bits='32bit'
            echo.arch="x86"
            echo.CARCH="i686"
            )>>%instdir%\local32\etc\profile2.local
        call :writeCommonProfile 32
        )

:writeProfile64
if %build64%==yes (
    if exist %instdir%\local64\etc\profile2.local GOTO loginProfile
        echo -------------------------------------------------------------------------------
        echo.
        echo.- write profile for 64 bit compiling
        echo.
        echo -------------------------------------------------------------------------------
        (
            echo.# /local64/etc/profile2.local
            echo.#
            echo.
            echo.MSYSTEM=MINGW64
            echo.
            echo.# package build directory
            echo.LOCALBUILDDIR=/build
            echo.# package installation prefix
            echo.LOCALDESTDIR=/local64
            echo.export LOCALBUILDDIR LOCALDESTDIR
            echo.
            echo.bits='64bit'
            echo.arch="x86_64"
            echo.CARCH="x86_64"
            )>>%instdir%\local64\etc\profile2.local
        call :writeCommonProfile 64
        )

:loginProfile
if exist %instdir%\%msys2%\etc\profile.pacnew ^
move /y %instdir%\%msys2%\etc\profile.pacnew %instdir%\%msys2%\etc\profile
%instdir%\%msys2%\usr\bin\grep -q -e 'profile2.local' %instdir%\%msys2%\etc\profile || (
    echo -------------------------------------------------------------------------------
    echo.writing default profile
    echo -------------------------------------------------------------------------------
    (
        echo.if [[ -z "$MSYSTEM" ^|^| "$MSYSTEM" = MINGW64 ]]; then
        echo.   source /local64/etc/profile2.local
        echo.elif [[ -z "$MSYSTEM" ^|^| "$MSYSTEM" = MINGW32 ]]; then
        echo.   source /local32/etc/profile2.local
        echo.fi
        )>%instdir%\%msys2%\etc\profile.d\Zab-suite.sh
    )

:compileLocals
cd %instdir%

if [%build64%]==[yes] (
    set MSYSTEM=MINGW64
    ) else set MSYSTEM=MINGW32

if not exist %build%\last_run if exist %build%\compile.log del %build%\compile.log
start /I %instdir%\%msys2%\usr\bin\mintty.exe -i /msys2.ico -t "media-autobuild_suite" ^
%instdir%\%msys2%\usr\bin\script.exe -a -q -f %build%\compile.log -c '^
MSYS2_PATH_TYPE=inherit MSYSTEM=%MSYSTEM% /usr/bin/bash --login ^
/build/media-suite_compile.sh --cpuCount=%cpuCount% --build32=%build32% --build64=%build64% --deleteSource=%deleteSource% ^
--mp4box=%mp4box% --vpx=%vpx2% --x264=%x2642% --x265=%x2652% --other265=%other265% --flac=%flac% --fdkaac=%fdkaac% ^
--mediainfo=%mediainfo% --sox=%sox% --ffmpeg=%ffmpeg% --ffmpegUpdate=%ffmpegUpdate% --ffmpegChoice=%ffmpegChoice% ^
--mplayer=%mplayer% --mpv=%mpv% --license=%license2%  --stripping=%stripFile% --packing=%packFile% --xpcomp=%xpcomp% ^
--rtmpdump=%rtmpdump% --logging=%logging% --bmx=%bmx% --standalone=%standalone% --aom=%aom% ^
--daala=%daala% --faac=%faac%'

endlocal
goto :EOF

:createBaseFolders
if not exist %instdir%\%1\share (
    echo.-------------------------------------------------------------------------------
    echo.create %1 folders
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

:writeCommonProfile
(
    echo.
    echo.# common in both profiles
    echo.alias dir='ls -la --color=auto'
    echo.alias ls='ls --color=auto'
    echo.export CC=gcc
    echo.source '/etc/msystem'
    echo.
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
    echo.LANG=en_US.UTF-8
    echo.PATH="${LOCALDESTDIR}/bin:${MINGW_PREFIX}/bin:${INFOPATH}:${PATH}"
    echo.PATH="${LOCALDESTDIR}/bin-audio:${LOCALDESTDIR}/bin-global:${LOCALDESTDIR}/bin-video:${PATH}"
    echo.PS1='\[\033[32m\]\u@\h \[\e[33m\]\w\[\e[0m\]\n\$ '
    echo.HOME="/home/${USERNAME}"
    echo.GIT_GUI_LIB_DIR=`cygpath -w /usr/share/git-gui/lib`
    echo.export LANG PATH PS1 HOME GIT_GUI_LIB_DIR
    echo.stty susp undef
    echo.cd /trunk
    )>>%instdir%\local%1\etc\profile2.local
goto :EOF
