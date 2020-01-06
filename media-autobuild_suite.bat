@echo off
rem -----------------------------------------------------------------------------
rem LICENSE --------------------------------------------------------------------
rem -----------------------------------------------------------------------------
rem  This Windows Batchscript is for setup a compiler environment for building
rem  ffmpeg and other media tools under Windows.
rem
rem    Copyright (C) 2013  jb_alvarado
rem
rem    This program is free software: you can redistribute it and/or modify
rem    it under the terms of the GNU General Public License as published by
rem    the Free Software Foundation, either version 3 of the License, or
rem    (at your option) any later version.
rem
rem    This program is distributed in the hope that it will be useful,
rem    but WITHOUT ANY WARRANTY; without even the implied warranty of
rem    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
rem    GNU General Public License for more details.
rem
rem    You should have received a copy of the GNU General Public License
rem    along with this program.  If not, see <https://www.gnu.org/licenses/>.
rem -----------------------------------------------------------------------------

color 70
title media-autobuild_suite

setlocal
chcp 65001 >nul 2>&1
cd /d "%~dp0"
set "TERM=xterm-256color"
setlocal
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
    echo. The total filepath to the suite seems too large (larger than 60 characters^):
    echo. %instdir%
    echo. Some packages might fail building because of it.
    echo. Please move the suite directory closer to the root of your drive and maybe
    echo. rename the suite directory to a smaller name. Examples:
    echo. Avoid:  C:\Users\Administrator\Desktop\testing\media-autobuild_suite-master
    echo. Prefer: C:\media-autobuild_suite
    echo. Prefer: C:\ab-suite
    pause
)

for /f "usebackq tokens=*" %%f in (`powershell -noprofile -command $PSVersionTable.PSVersion.Major`) ^
do if %%f lss 4 (
    echo ----------------------------------------------------------------------
    echo. You do not have a powershell version greater than 4.
    echo. This is not supported.
    echo. Please upgrade your powershell either through downloading and installing WMF 5.1
    echo. https://docs.microsoft.com/en-us/powershell/wmf/5.1/install-configure
    echo. or by upgrading your OS.
    echo. This is not Powershell Core. That is separate.
    pause
    exit
)

(
    where lib.exe || ^
    where cl.exe || ^
    if DEFINED VSINSTALLDIR cd .
) >nul 2>&1 && (
    rem MSVCINSTALLED
    echo ----------------------------------------------------------------------
    echo. You are running in a MSVC environment (cl.exe or lib.exe detected^)
    echo. This is not supported.
    echo. Please run the script through a normal cmd.exe some other way.
    echo.
    echo. Detected Paths:
    where lib.exe 2>nul
    where cl.exe 2>nul
    echo %VSINSTALLDIR%
    pause
    exit
)

set build=%instdir%\build
if not exist %build% mkdir %build%

set msyspackages=asciidoc autoconf automake-wrapper autogen bison diffstat dos2unix help2man ^
intltool libtool patch python xmlto make zip unzip git subversion wget p7zip mercurial man-db ^
gperf winpty texinfo gyp-git doxygen autoconf-archive itstool ruby mintty flex

set mingwpackages=cmake dlfcn libpng gcc nasm pcre tools-git yasm ninja pkg-config meson ccache jq

:: built-ins
set ffmpeg_options_builtin=--disable-autodetect amf bzlib cuda cuvid d3d11va dxva2 ^
iconv lzma nvenc schannel zlib sdl2 ffnvcodec nvdec cuda-llvm

:: common external libs
set ffmpeg_options_basic=gmp libmp3lame libopus libvorbis libvpx libx264 libx265 ^
libdav1d --disable-debug

:: options used in zeranoe builds and not present above
set ffmpeg_options_zeranoe=fontconfig gnutls libass libbluray libfreetype ^
libmfx libmysofa libopencore-amrnb libopencore-amrwb libopenjpeg libsnappy ^
libsoxr libspeex libtheora libtwolame libvidstab libvo-amrwbenc libwavpack ^
libwebp libxml2 libzimg libshine gpl openssl libtls avisynth mbedtls libxvid ^
libaom libopenmpt version3

:: options also available with the suite
set ffmpeg_options_full=chromaprint decklink frei0r libbs2b libcaca ^
libcdio libfdk-aac libflite libfribidi libgme libgsm libilbc libsvthevc libsvtav1 ^
libkvazaar libmodplug librtmp librubberband #libssh libtesseract libxavs libzmq ^
libzvbi openal libvmaf libcodec2 libsrt ladspa #librav1e #vapoursynth #liblensfun

:: options also available with the suite that add shared dependencies
set ffmpeg_options_full_shared=opencl opengl cuda-nvcc libnpp libopenh264

:: built-ins
set mpv_options_builtin=#cplayer #manpage-build #lua #javascript #libass ^
#libbluray #uchardet #rubberband #lcms2 #libarchive #libavdevice ^
#shaderc #spirv-cross #d3d11 #jpeg #vapoursynth #vulkan #libplacebo

:: overriden defaults
set mpv_options_basic=--disable-debug-build "--lua=luajit"

:: all supported options
set mpv_options_full=dvdnav cdda #egl-angle #html-build ^
#pdf-build libmpv-shared openal sdl2 #sdl2-gamepad #sdl2-audio #sdl2-video

set iniOptions=msys2Arch arch license2 vpx2 x2643 x2652 other265 flac fdkaac mediainfo ^
soxB ffmpegB2 ffmpegUpdate ffmpegChoice mp4box rtmpdump mplayer2 mpv cores deleteSource ^
strip pack logging bmx standalone updateSuite aom faac ffmbc curl cyanrip2 redshift rav1e ^
ripgrep dav1d vvc jq dssim avs2 timeStamp noMintty ccache svthevc svtav1 svtvp9 xvc jo

set deleteIni=0
set ini=%build%\media-autobuild_suite.ini

rem Set all INI options to 0
for %%a in (%iniOptions%) do set %%aINI=0

if exist %ini% (
    rem Set INI options to what's found in the inifile
    for %%a in (%iniOptions%) do for /F "tokens=2 delims==" %%b in ('findstr %%a %ini%') do set %%aINI=%%b
) else set deleteIni=1

setlocal EnableDelayedExpansion
rem Check if any of the *INI options are still unset (0)
for %%a in (%iniOptions%) do if [!%%aINI!]==[0] set deleteIni=1 && goto :endINIcheck
:endINIcheck
endlocal & set deleteIni=%deleteIni%

rem case msys2Arch in 1) msys32;; *) msys64;; esac
if %PROCESSOR_ARCHITECTURE%==x86 if NOT DEFINED PROCESSOR_ARCHITEW6432 set msys2Arch=1
if NOT DEFINED msys2Arch set msys2Arch=2
if %deleteINI%==1 (
    echo.[compiler list]
    echo.msys2Arch=%msys2Arch%
)>"%ini%"

:systemVars
if %msys2Arch%==1 ( set "msys2=msys32" ) else set "msys2=msys64"

:selectSystem
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

if "%buildEnv%"=="" GOTO selectSystem
if %buildEnv%==1 set "build32=yes" && set "build64=yes"
if %buildEnv%==2 set "build32=yes" && set "build64=no"
if %buildEnv%==3 set "build32=no" && set "build64=yes"
if %buildEnv% GTR 3 GOTO selectSystem
if %deleteINI%==1 echo.arch=^%buildEnv%>>%ini%

:ffmpeglicense
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

if "%ffmpegLicense%"=="" GOTO ffmpeglicense
if %ffmpegLicense%==1 set "license2=nonfree"
if %ffmpegLicense%==2 set "license2=gplv3"
if %ffmpegLicense%==3 set "license2=gpl"
if %ffmpegLicense%==4 set "license2=lgplv3"
if %ffmpegLicense%==5 set "license2=lgpl"
if %ffmpegLicense% GTR 5 GOTO ffmpeglicense
if %deleteINI%==1 echo.license2=^%ffmpegLicense%>>%ini%

:standalone
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

if "%buildstandalone%"=="" GOTO standalone
if %buildstandalone%==1 set "standalone=y"
if %buildstandalone%==2 set "standalone=n"
if %buildstandalone% GTR 2 GOTO standalone
if %deleteINI%==1 echo.standalone=^%buildstandalone%>>%ini%

:vpx
if %vpx2INI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build vpx [VP8/VP9 encoder]?
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo. Binaries being built depends on "standalone=y"
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildvpx="Build vpx: "
) else set buildvpx=%vpx2INI%

if "%buildvpx%"=="" GOTO vpx
if %buildvpx%==1 set "vpx2=y"
if %buildvpx%==2 set "vpx2=n"
if %buildvpx% GTR 2 GOTO vpx
if %deleteINI%==1 echo.vpx2=^%buildvpx%>>%ini%

:aom
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

if "%buildaom%"=="" GOTO aom
if %buildaom%==1 set "aom=y"
if %buildaom%==2 set "aom=n"
if %buildaom% GTR 2 GOTO aom
if %deleteINI%==1 echo.aom=^%buildaom%>>%ini%

:rav1e
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

if "%buildrav1e%"=="" GOTO rav1e
if %buildrav1e%==1 set "rav1e=y"
if %buildrav1e%==2 set "rav1e=n"
if %buildrav1e% GTR 2 GOTO rav1e
if %deleteINI%==1 echo.rav1e=^%buildrav1e%>>%ini%

:dav1d
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

if "%builddav1d%"=="" GOTO dav1d
if %builddav1d%==1 set "dav1d=y"
if %builddav1d%==2 set "dav1d=n"
if %builddav1d% GTR 2 GOTO dav1d
if %deleteINI%==1 echo.dav1d=^%builddav1d%>>%ini%

:x264
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
    echo. 6 = Same as 4 with video codecs only (can reduce size by ~3MB^)
    echo. 7 = Lib/binary with only 8-bit
    echo.
    echo. Binaries being built depends on "standalone=y" and are always static.
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildx264="Build x264: "
) else set buildx264=%x2643INI%

if "%buildx264%"=="" GOTO x264
if %buildx264%==1 set "x2643=yes"
if %buildx264%==2 set "x2643=no"
if %buildx264%==3 set "x2643=high"
if %buildx264%==4 set "x2643=full"
if %buildx264%==5 set "x2643=shared"
if %buildx264%==6 set "x2643=fullv"
if %buildx264%==7 set "x2643=o8"
if %buildx264% GTR 7 GOTO x264
if %deleteINI%==1 echo.x2643=^%buildx264%>>%ini%

:x265
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

if "%buildx265%"=="" GOTO x265
if %buildx265%==1 set "x2652=y"
if %buildx265%==2 set "x2652=n"
if %buildx265%==3 set "x2652=o10"
if %buildx265%==4 set "x2652=o8"
if %buildx265%==5 set "x2652=s"
if %buildx265%==6 set "x2652=d"
if %buildx265%==7 set "x2652=o12"
if %buildx265% GTR 7 GOTO x265
if %deleteINI%==1 echo.x2652=^%buildx265%>>%ini%

:other265
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

if "%buildother265%"=="" GOTO other265
if %buildother265%==1 set "other265=y"
if %buildother265%==2 set "other265=n"
if %buildother265% GTR 2 GOTO other265
if %deleteINI%==1 echo.other265=^%buildother265%>>%ini%

:svthevc
if %svthevcINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build SVT-HEVC? [H.265 encoder]
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildsvthevc="Build SVT-HEVC: "
) else set buildsvthevc=%svthevcINI%

if "%buildsvthevc%"=="" GOTO svthevc
if %buildsvthevc%==1 set "svthevc=y"
if %buildsvthevc%==2 set "svthevc=n"
if %buildsvthevc% GTR 2 GOTO svthevc
if %deleteINI%==1 echo.svthevc=^%buildsvthevc%>>%ini%

:xvc
if %xvcINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build xvc? [HEVC and AV1 competitor]
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo. Any issues with this will be considered low-priority due to lack of
    echo. potential stability
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildxvc="Build xvc: "
) else set buildxvc=%xvcINI%

if "%buildxvc%"=="" GOTO xvc
if %buildxvc%==1 set "xvc=y"
if %buildxvc%==2 set "xvc=n"
if %buildxvc% GTR 2 GOTO xvc
if %deleteINI%==1 echo.xvc=^%buildxvc%>>%ini%

:vvc
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

if "%buildvvc%"=="" GOTO vvc
if %buildvvc%==1 set "vvc=y"
if %buildvvc%==2 set "vvc=n"
if %buildvvc% GTR 2 GOTO vvc
if %deleteINI%==1 echo.vvc=^%buildvvc%>>%ini%

:svtav1
if %svtav1INI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build SVT-AV1? [AV1 encoder]
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo. Look at the link for hardware requirements
    echo. https://github.com/OpenVisualCloud/SVT-AV1/blob/master/README.md#Hardware
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildsvtav1="Build SVT-AV1: "
) else set buildsvtav1=%svtav1INI%

if "%buildsvtav1%"=="" GOTO svtav1
if %buildsvtav1%==1 set "svtav1=y"
if %buildsvtav1%==2 set "svtav1=n"
if %buildsvtav1% GTR 2 GOTO svtav1
if %deleteINI%==1 echo.svtav1=^%buildsvtav1%>>%ini%

:svtvp9
if %svtvp9INI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build SVT-VP9? [VP9 encoder]
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo. Look at the link for hardware requirements
    echo. https://github.com/OpenVisualCloud/SVT-VP9#Hardware
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildsvtvp9="Build SVT-VP9: "
) else set buildsvtvp9=%svtvp9INI%

if "%buildsvtvp9%"=="" GOTO svtvp9
if %buildsvtvp9%==1 set "svtvp9=y"
if %buildsvtvp9%==2 set "svtvp9=n"
if %buildsvtvp9% GTR 2 GOTO svtvp9
if %deleteINI%==1 echo.svtvp9=^%buildsvtvp9%>>%ini%

:flac
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

if "%buildflac%"=="" GOTO flac
if %buildflac%==1 set "flac=y"
if %buildflac%==2 set "flac=n"
if %buildflac% GTR 2 GOTO flac
if %deleteINI%==1 echo.flac=^%buildflac%>>%ini%

:fdkaac
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

if "%buildfdkaac%"=="" GOTO fdkaac
if %buildfdkaac%==1 set "fdkaac=y"
if %buildfdkaac%==2 set "fdkaac=n"
if %buildfdkaac% GTR 2 GOTO fdkaac
if %deleteINI%==1 echo.fdkaac=^%buildfdkaac%>>%ini%

:faac
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

if "%buildfaac%"=="" GOTO faac
if %buildfaac%==1 set "faac=y"
if %buildfaac%==2 set "faac=n"
if %buildfaac% GTR 2 GOTO faac
if %deleteINI%==1 echo.faac=^%buildfaac%>>%ini%

:mediainfo
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

if "%buildmediainfo%"=="" GOTO mediainfo
if %buildmediainfo%==1 set "mediainfo=y"
if %buildmediainfo%==2 set "mediainfo=n"
if %buildmediainfo% GTR 2 GOTO mediainfo
if %deleteINI%==1 echo.mediainfo=^%buildmediainfo%>>%ini%

:sox
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

if "%buildsox%"=="" GOTO sox
if %buildsox%==1 set "sox=y"
if %buildsox%==2 set "sox=n"
if %buildsox% GTR 2 GOTO sox
if %deleteINI%==1 echo.soxB=^%buildsox%>>%ini%

:ffmpeg
if %ffmpegB2INI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build FFmpeg binaries and libraries:
    echo. 1 = Yes [static] [recommended]
    echo. 2 = No
    echo. 3 = Shared
    echo. 4 = Both static and shared [shared goes to an isolated directory]
    echo. 5 = Shared-only with some shared libs (libass, freetype and fribidi^)
    echo. 6 = Same as 4, but static compilation ignores shared dependencies
    echo.
    echo. Note: Option 5 differs from 3 in that libass, freetype and fribidi are
    echo. compiled shared so they take less space. This one isn't tested a lot and
    echo. will fail with fontconfig enabled.
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildffmpeg="Build FFmpeg: "
) else set buildffmpeg=%ffmpegB2INI%

if "%buildffmpeg%"=="" GOTO ffmpeg
if %buildffmpeg%==1 set "ffmpeg=static"
if %buildffmpeg%==2 set "ffmpeg=no"
if %buildffmpeg%==3 set "ffmpeg=shared"
if %buildffmpeg%==4 set "ffmpeg=both"
if %buildffmpeg%==5 set "ffmpeg=sharedlibs"
if %buildffmpeg%==6 set "ffmpeg=bothstatic"
if %buildffmpeg% GTR 6 GOTO ffmpeg
if %deleteINI%==1 echo.ffmpegB2=^%buildffmpeg%>>%ini%

:ffmpegUp
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

if "%buildffmpegUp%"=="" GOTO ffmpegUp
if %buildffmpegUp%==1 set "ffmpegUpdate=y"
if %buildffmpegUp%==2 set "ffmpegUpdate=n"
if %buildffmpegUp%==3 set "ffmpegUpdate=onlyFFmpeg"
if %buildffmpegUp% GTR 3 GOTO ffmpegUp
if %deleteINI%==1 echo.ffmpegUpdate=^%buildffmpegUp%>>%ini%

:ffmpegChoice
if %ffmpegChoiceINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Choose ffmpeg and mpv optional libraries?
    echo. 1 = Yes
    echo. 2 = No (Light build^)
    echo. 3 = No (Mimic Zeranoe^)
    echo. 4 = No (All available external libs^)
    echo.
    echo. Avoid the last two unless you really want useless libraries you'll never use.
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

if "%buildffmpegChoice%"=="" GOTO ffmpegChoice
if %buildffmpegChoice%==1 (
    set "ffmpegChoice=y"
    if not exist %build%\ffmpeg_options.txt (
        (
            echo.# Lines starting with this character are ignored
            echo.# To override some options specifically for the shared build, create a ffmpeg_options_shared.txt file.
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
            echo.
            echo.# Full plus options that add shared dependencies
            call :writeOption %ffmpeg_options_full_shared%
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
if %deleteINI%==1 echo.ffmpegChoice=^%buildffmpegChoice%>>%ini%

:mp4boxStatic
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

if "%buildMp4box%"=="" GOTO mp4boxStatic
if %buildMp4box%==1 set "mp4box=y"
if %buildMp4box%==2 set "mp4box=n"
if %buildMp4box% GTR 2 GOTO mp4boxStatic
if %deleteINI%==1 echo.mp4box=^%buildMp4box%>>%ini%

:rtmpdump
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

if "%buildrtmpdump%"=="" GOTO rtmpdump
if %buildrtmpdump%==1 set "rtmpdump=y"
if %buildrtmpdump%==2 set "rtmpdump=n"
if %buildrtmpdump% GTR 2 GOTO rtmpdump
if %deleteINI%==1 echo.rtmpdump=^%buildrtmpdump%>>%ini%

:mplayer
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

if "%buildmplayer%"=="" GOTO mplayer
if %buildmplayer%==1 set "mplayer=y"
if %buildmplayer%==2 set "mplayer=n"
if %buildmplayer% GTR 2 GOTO mplayer
if %deleteINI%==1 echo.mplayer2=^%buildmplayer%>>%ini%

:mpv
if %mpvINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build mpv?
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo. Note: when built with shared-only FFmpeg, mpv is also shared.
    echo. Note: the third option was removed since vapoursynth is now a delay-import
    echo. dependency that is only required if you try to use the corresponding filter.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildmpv="Build mpv: "
) else set buildmpv=%mpvINI%

if "%buildmpv%"=="" GOTO mpv
if %buildmpv%==1 set "mpv=y"
if %buildmpv%==2 set "mpv=n"
if %buildmpv% GTR 2 GOTO mpv
if %deleteINI%==1 echo.mpv=^%buildmpv%>>%ini%

:bmx
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

if "%buildbmx%"=="" GOTO bmx
if %buildbmx%==1 set "bmx=y"
if %buildbmx%==2 set "bmx=n"
if %buildbmx% GTR 2 GOTO bmx
if %deleteINI%==1 echo.bmx=^%buildbmx%>>%ini%

:curl
if %curlINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build static curl?
    echo. 1 = Yes (same backend as FFmpeg's^)
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

if "%buildcurl%"=="" GOTO curl
if %buildcurl%==1 set "curl=y"
if %buildcurl%==2 set "curl=n"
if %buildcurl%==3 set "curl=schannel"
if %buildcurl%==4 set "curl=gnutls"
if %buildcurl%==5 set "curl=openssl"
if %buildcurl%==6 set "curl=libressl"
if %buildcurl%==7 set "curl=mbedtls"
if %buildcurl% GTR 7 GOTO curl
if %deleteINI%==1 echo.curl=^%buildcurl%>>%ini%

:ffmbc
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

if "%buildffmbc%"=="" GOTO ffmbc
if %buildffmbc%==1 set "ffmbc=y"
if %buildffmbc%==2 set "ffmbc=n"
if %buildffmbc% GTR 2 GOTO ffmbc
if %deleteINI%==1 echo.ffmbc=^%buildffmbc%>>%ini%

:cyanrip
if %cyanrip2INI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build cyanrip (CLI CD ripper^)?
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildcyanrip="Build cyanrip: "
) else set buildcyanrip=%cyanrip2INI%

if "%buildcyanrip%"=="" GOTO cyanrip
if %buildcyanrip%==1 set "cyanrip=y"
if %buildcyanrip%==2 set "cyanrip=n"
if %buildcyanrip% GTR 2 GOTO cyanrip
if %deleteINI%==1 echo.cyanrip2=^%buildcyanrip%>>%ini%

:redshift
if %redshiftINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build redshift (f.lux FOSS clone^)?
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildredshift="Build redshift: "
) else set buildredshift=%redshiftINI%

if "%buildredshift%"=="" GOTO redshift
if %buildredshift%==1 set "redshift=y"
if %buildredshift%==2 set "redshift=n"
if %buildredshift% GTR 2 GOTO redshift
if %deleteINI%==1 echo.redshift=^%buildredshift%>>%ini%

:ripgrep
if %ripgrepINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build ripgrep (faster grep in Rust^)?
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildripgrep="Build ripgrep: "
) else set buildripgrep=%ripgrepINI%

if "%buildripgrep%"=="" GOTO ripgrep
if %buildripgrep%==1 set "ripgrep=y"
if %buildripgrep%==2 set "ripgrep=n"
if %buildripgrep% GTR 2 GOTO ripgrep
if %deleteINI%==1 echo.ripgrep=^%buildripgrep%>>%ini%

:jq
if %jqINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build jq (CLI JSON processor^)?
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildjq="Build jq: "
) else set buildjq=%jqINI%

if "%buildjq%"=="" GOTO jq
if %buildjq%==1 set "jq=y"
if %buildjq%==2 set "jq=n"
if %buildjq% GTR 2 GOTO jq
if %deleteINI%==1 echo.jq=^%buildjq%>>%ini%

:jo
if %joINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build jo (CLI JSON from shell^)?
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildjo="Build jo: "
) else set buildjo=%joINI%

if "%buildjo%"=="" GOTO jo
if %buildjo%==1 set "jo=y"
if %buildjo%==2 set "jo=n"
if %buildjo% GTR 2 GOTO jo
if %deleteINI%==1 echo.jo=^%buildjo%>>%ini%

:dssim
if %dssimINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build dssim (multiscale SSIM in Rust^)?
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P builddssim="Build dssim: "
) else set builddssim=%dssimINI%

if "%builddssim%"=="" GOTO dssim
if %builddssim%==1 set "dssim=y"
if %builddssim%==2 set "dssim=n"
if %builddssim% GTR 2 GOTO dssim
if %deleteINI%==1 echo.dssim=^%builddssim%>>%ini%

:avs2
if %avs2INI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build avs2 (Audio Video Coding Standard Gen2 encoder/decoder^)?
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo. Binaries being built depends on "standalone=y" and are always static.
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildavs2="Build avs2: "
) else set buildavs2=%avs2INI%

if "%buildavs2%"=="" GOTO avs2
if %buildavs2%==1 set "avs2=y"
if %buildavs2%==2 set "avs2=n"
if %buildavs2% GTR 2 GOTO avs2
if %deleteINI%==1 echo.avs2=^%buildavs2%>>%ini%

:numCores
if %NUMBER_OF_PROCESSORS% EQU 1 ( set coreHalf=1 ) else set /a coreHalf=%NUMBER_OF_PROCESSORS%/2
if %coresINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Number of CPU Cores/Threads for compiling:
    echo. [it is non-recommended to use all cores/threads!]
    echo.
    echo. Recommended: %coreHalf%
    echo.
    echo. If you have Windows Defender Real-time protection on, most of your processing
    echo. power will go to it. It is recommended to whitelist this directory from
    echo. scanning due to the amount of new files and copying/moving done by the suite.
    echo. If you do not know how to do this, google it. If you don't care, ignore this.
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P cpuCores="Core/Thread Count: "
) else set cpuCores=%coresINI%
for /l %%a in (1,1,%cpuCores%) do set cpuCount=%%a

if "%cpuCount%"=="" GOTO numCores
if %deleteINI%==1 echo.cores=^%cpuCount%>>%ini%

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

if "%deleteS%"=="" GOTO delete
if %deleteS%==1 set "deleteSource=y"
if %deleteS%==2 set "deleteSource=n"
if %deleteS% GTR 2 GOTO delete
if %deleteINI%==1 echo.deleteSource=^%deleteS%>>%ini%

:stripEXE
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

if "%stripF%"=="" GOTO stripEXE
if %stripF%==1 set "stripFile=y"
if %stripF%==2 set "stripFile=n"
if %stripF% GTR 2 GOTO stripEXE
if %deleteINI%==1 echo.strip=^%stripF%>>%ini%

:packEXE
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

if "%packF%"=="" GOTO packEXE
if %packF%==1 set "packFile=y"
if %packF%==2 set "packFile=n"
if %packF% GTR 2 GOTO packEXE
if %deleteINI%==1 echo.pack=^%packF%>>%ini%

:logging
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

if "%loggingF%"=="" GOTO logging
if %loggingF%==1 set "logging=y"
if %loggingF%==2 set "logging=n"
if %loggingF% GTR 2 GOTO logging
if %deleteINI%==1 echo.logging=^%loggingF%>>%ini%

:updateSuite
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

if "%updateSuiteF%"=="" GOTO updateSuite
if %updateSuiteF%==1 set "updateSuite=y"
if %updateSuiteF%==2 set "updateSuite=n"
if %updateSuiteF% GTR 2 GOTO updateSuite
if %deleteINI%==1 echo.updateSuite=^%updateSuiteF%>>%ini%

:timeStamp
if %timeStampINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Show timestamps of commands during compilation?
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo This will show the start times of commands during compilation.
    echo Don't turn this on unless you really want to see the timestamps.
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P timeStampF="Show Timestamps: "
) else set timeStampF=%timeStampINI%

if "%timeStampF%"=="" GOTO timestamp
if %timeStampF%==1 set "timeStamp=y"
if %timeStampF%==2 set "timeStamp=n"
if %timeStampF% GTR 2 GOTO timeStamp
if %deleteINI%==1 echo.timeStamp=^%timeStampF%>>%ini%

:ccache
if %ccacheINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Use ccache when compiling?
    echo. Experimental.
    echo. Speeds up rebuilds and recompilations, but requires the files to be
    echo. compiled at least once before any effect is seen
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildwithccache="Use ccache: "
) else set buildwithccache=%ccacheINI%

if "%buildwithccache%"=="" GOTO ccache
if %buildwithccache%==1 set "ccache=y"
if %buildwithccache%==2 set "ccache=n"
if %buildwithccache% GTR 2 GOTO ccache
if %deleteINI%==1 echo.ccache=^%buildwithccache%>>%ini%

:noMintty
if %noMinttyINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Are you running this script through ssh or similar?
    echo. (Can't open another window outside of this terminal^)
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo This will disable the use of mintty and print the output to this console.
    echo There is no guarantee that this will work properly.
    echo You must make sure that you have ssh keep-alive enabled or something similar
    echo to screen that will allow you to run this script in the background.
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P noMinttyF="SSH: "
) else set noMinttyF=%noMinttyINI%

if "%noMinttyF%"=="" GOTO noMintty
if %noMinttyF%==1 (
    set "noMintty=y"
    color
)
if %noMinttyF%==2 set "noMintty=n"
if %noMinttyF% GTR 2 GOTO noMintty
if %deleteINI%==1 echo.noMintty=^%noMinttyF%>>%ini%

rem ------------------------------------------------------------------
rem download and install basic msys2 system:
rem ------------------------------------------------------------------
cd %build%
set scripts=media-suite_compile.sh media-suite_helper.sh media-suite_update.sh bash.ps1
for %%s in (%scripts%) do (
    if not exist "%build%\%%s" (
        powershell -Command (New-Object System.Net.WebClient^).DownloadFile('"https://github.com/m-ab-s/media-autobuild_suite/raw/master/build/%%s"', '"%%s"' ^)
    )
)

rem checkmsys2
if %msys2%==msys32 ( set "msysprefix=i686" ) else set "msysprefix=x86_64"
if not exist "%instdir%\%msys2%\msys2_shell.cmd" (
    echo -------------------------------------------------------------------------------
    echo.
    echo.- Download and install msys2 basic system
    echo.
    echo -------------------------------------------------------------------------------
    echo [System.Net.ServicePointManager]::SecurityProtocol = 'Tls12'; ^
        $wc = New-Object System.Net.WebClient; ^
        while ((Get-Item $PWD\msys2-base.tar.xz -ErrorAction Ignore^).Length -ne ^
        (Invoke-WebRequest -Uri "http://repo.msys2.org/distrib/msys2-%msysprefix%-latest.tar.xz" ^
        -UseBasicParsing -Method Head^).headers.'Content-Length'^) {if ($i -le 5^) {try ^
        {$wc.DownloadFile('http://repo.msys2.org/distrib/msys2-%msysprefix%-latest.tar.xz', ^
        "$PWD\msys2-base.tar.xz"^)} catch {$i++}}} | powershell -NoProfile -Command - || goto :errorMsys

    :unpack
    if exist %build%\msys2-base.tar.xz (
        echo -------------------------------------------------------------------------------
        echo.
        echo.- Downloading and unpacking msys2 basic system
        echo.
        echo -------------------------------------------------------------------------------
        7z >nul 2>&1 || 7za >nul 2>&1 || powershell -NoProfile -NonInteractive -Command (New-Object System.Net.WebClient^).DownloadFile('https://github.com/chocolatey/chocolatey.org/raw/master/chocolatey/Website/7za.exe', '7za.exe'^)
        7z >nul 2>&1 && 7z x msys2-base.tar.xz -so | 7z x -aoa -si -ttar -o.. || 7za x msys2-base.tar.xz -so | 7za x -aoa -si -ttar -o..
        if exist 7za.exe del 7za.exe
    )

    if not exist %instdir%\%msys2%\usr\bin\msys-2.0.dll (
        :errorMsys
        echo -------------------------------------------------------------------------------
        echo.
        echo.- Download msys2 basic system failed,
        echo.- please download it manually from:
        echo.- http://repo.msys2.org/distrib/
        echo.- extract and put the msys2 folder into
        echo.- the root media-autobuid_suite folder
        echo.- and start the batch script again!
        echo.
        echo -------------------------------------------------------------------------------
        pause
        GOTO :unpack
    )
)

rem getMintty
set "bash=%instdir%\%msys2%\usr\bin\bash.exe"
set "PATH=%instdir%\%msys2%\opt\bin;%instdir%\%msys2%\usr\bin;%PATH%"
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
    call :runBash firstrun.log exit

    sed -i "s/#Color/Color/;s/^^IgnorePkg.*/#&/" %instdir%\%msys2%\etc\pacman.conf

    echo.-------------------------------------------------------------------------------
    echo.first update
    echo.-------------------------------------------------------------------------------
    title first msys2 update
    call :runBash firstUpdate.log pacman --noconfirm -Sy --asdeps pacman-mirrors

    echo.-------------------------------------------------------------------------------
    echo.critical updates
    echo.-------------------------------------------------------------------------------
    pacman -S --needed --ask=20 --noconfirm --asdeps bash pacman msys2-runtime

    echo.-------------------------------------------------------------------------------
    echo.second update
    echo.-------------------------------------------------------------------------------
    title second msys2 update
    call :runBash secondUpdate.log pacman --noconfirm -Syu --asdeps

    (
        echo.Set Shell = CreateObject("WScript.Shell"^)
        echo.Set link = Shell.CreateShortcut("%instdir%\mintty.lnk"^)
        echo.link.Arguments = "-full-path -mingw"
        echo.link.Description = "msys2 shell console"
        echo.link.TargetPath = "%instdir%\%msys2%\msys2_shell.cmd"
        echo.link.WindowStyle = 1
        echo.link.IconLocation = "%instdir%\%msys2%\msys2.ico"
        echo.link.WorkingDirectory = "%instdir%\%msys2%"
        echo.link.Save
    )>%build%\setlink.vbs
    cscript /B /Nologo %build%\setlink.vbs
    del %build%\setlink.vbs
)

rem createFolders
if %build32%==yes call :createBaseFolders local32
if %build64%==yes call :createBaseFolders local64

rem checkFstab
set "removefstab=no"
set "fstab=%instdir%\%msys2%\etc\fstab"
if exist %fstab%. (
    findstr build32 %fstab% >nul 2>&1 && set "removefstab=yes"
    findstr trunk %fstab% >nul 2>&1 || set "removefstab=yes"
    for /f "tokens=1 delims= " %%a in ('findstr trunk %fstab%') do if not [%%a]==[%instdir%\] set "removefstab=yes"
    findstr local32 %fstab% >nul 2>&1 && ( if [%build32%]==[no] set "removefstab=yes" ) || if [%build32%]==[yes] set "removefstab=yes"
    findstr local64 %fstab% >nul 2>&1 && ( if [%build64%]==[no] set "removefstab=yes" ) || if [%build64%]==[yes] set "removefstab=yes"
) else set removefstab=yes

if not [%removefstab%]==[no] (
    rem writeFstab
    echo -------------------------------------------------------------------------------
    echo.
    echo.- write fstab mount file
    echo.
    echo -------------------------------------------------------------------------------
    (
        echo.none / cygdrive binary,posix=0,noacl,user 0 0
        echo.
        echo.%instdir%\ /trunk
        echo.%instdir%\build\ /build
        echo.%instdir%\%msys2%\mingw32\ /mingw32
        echo.%instdir%\%msys2%\mingw64\ /mingw64
        if "%build32%"=="yes" echo.%instdir%\local32\ /local32
        if "%build64%"=="yes" echo.%instdir%\local64\ /local64
    )>"%instdir%\%msys2%\etc\fstab."
)

if not exist "%instdir%\%msys2%\home\%USERNAME%" mkdir "%instdir%\%msys2%\home\%USERNAME%"
set "TERM="
type nul >>"%instdir%\%msys2%\home\%USERNAME%\.minttyrc"
for /F "tokens=2 delims==" %%b in ('findstr /i TERM "%instdir%\%msys2%\home\%USERNAME%\.minttyrc"') do set TERM=%%b
if not defined TERM (
    printf %%s\n Locale=en_US Charset=UTF-8 Font=Consolas Columns=120 Rows=30 TERM=xterm-256color ^
    > "%instdir%\%msys2%\home\%USERNAME%\.minttyrc"
    set "TERM=xterm-256color"
)

rem hgsettings
if not exist "%instdir%\%msys2%\home\%USERNAME%\.hgrc" (
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
)>"%instdir%\%msys2%\home\%USERNAME%\.hgrc"

rem gitsettings
if not exist "%instdir%\%msys2%\home\%USERNAME%\.gitconfig" (
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
)>"%instdir%\%msys2%\home\%USERNAME%\.gitconfig"

rem installbase
if exist "%instdir%\%msys2%\etc\pac-base.pk" del "%instdir%\%msys2%\etc\pac-base.pk"
for %%i in (%msyspackages%) do echo.%%i>>%instdir%\%msys2%\etc\pac-base.pk

if not exist %instdir%\%msys2%\usr\bin\make.exe (
    echo.-------------------------------------------------------------------------------
    echo.install msys2 base system
    echo.-------------------------------------------------------------------------------
    if exist %build%\install_base_failed del %build%\install_base_failed
    title install base system
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
    call :runBash pacman.log /build/pacman.sh
    del %build%\pacman.sh
)

for %%i in (%instdir%\%msys2%\usr\ssl\cert.pem) do if %%~zi==0 call :runBash cert.log update-ca-trust

rem sethgBat
if not exist %instdir%\%msys2%\usr\bin\hg.bat (
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
)>%instdir%\%msys2%\usr\bin\hg.bat

rem installmingw
if exist "%instdir%\%msys2%\etc\pac-mingw.pk" del "%instdir%\%msys2%\etc\pac-mingw.pk"
for %%i in (%mingwpackages%) do echo.%%i>>%instdir%\%msys2%\etc\pac-mingw.pk
if %build32%==yes call :getmingw 32 i
if %build64%==yes call :getmingw 64 x
if exist "%build%\mingw.sh" del %build%\mingw.sh

rem updatebase
echo.-------------------------------------------------------------------------------
echo.update autobuild suite
echo.-------------------------------------------------------------------------------

cd %build%
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

rem update
call :runBash update.log /build/media-suite_update.sh --build32=%build32% --build64=%build64%

if exist "%build%\update_core" (
    echo.-------------------------------------------------------------------------------
    echo.critical updates
    echo.-------------------------------------------------------------------------------
    pacman -S --needed --noconfirm --ask=20 --asdeps bash pacman msys2-runtime
    del "%build%\update_core"
)

if %msys2%==msys32 (
    echo.-------------------------------------------------------------------------------
    echo.second rebase %msys2% system
    echo.-------------------------------------------------------------------------------
    call %instdir%\%msys2%\autorebase.bat
)
del "%build%\msys2-base.tar.xz" 2>nul

rem ------------------------------------------------------------------
rem write config profiles:
rem ------------------------------------------------------------------

if %build32%==yes call :writeProfile 32
if %build64%==yes call :writeProfile 64

findstr hkps://keys.openpgp.org "%instdir%\%msys2%\home\%USERNAME%\.gnupg\gpg.conf" >nul 2>&1 || echo keyserver hkps://keys.openpgp.org >> "%instdir%\%msys2%\home\%USERNAME%\.gnupg\gpg.conf"

rem loginProfile
if exist %instdir%\%msys2%\etc\profile.pacnew ^
    move /y %instdir%\%msys2%\etc\profile.pacnew %instdir%\%msys2%\etc\profile
findstr /C:"profile2.local" %instdir%\%msys2%\etc\profile.d\Zab-suite.sh >nul 2>&1 || (
    echo.if [[ -z "$MSYSTEM" ^|^| "$MSYSTEM" = MINGW64 ]]; then
    echo.   source /local64/etc/profile2.local
    echo.elif [[ -z "$MSYSTEM" ^|^| "$MSYSTEM" = MINGW32 ]]; then
    echo.   source /local32/etc/profile2.local
    echo.fi
)>%instdir%\%msys2%\etc\profile.d\Zab-suite.sh

rem compileLocals
cd %instdir%

title MABSbat

if exist %build%\compilation_failed del %build%\compilation_failed
if exist %build%\fail_comp del %build%\compilation_failed

REM Test mklink availability
set "MSYS="
mkdir testmklink 2>nul
mklink /d linkedtestmklink testmklink >nul 2>&1 && (
    set MSYS="winsymlinks:nativestrict"
    rmdir /q linkedtestmklink
)
rmdir /q testmklink

endlocal & (
set compileArgs=--cpuCount=%cpuCount% --build32=%build32% --build64=%build64% ^
--deleteSource=%deleteSource% --mp4box=%mp4box% --vpx=%vpx2% --x264=%x2643% --x265=%x2652% ^
--other265=%other265% --flac=%flac% --fdkaac=%fdkaac% --mediainfo=%mediainfo% --sox=%sox% ^
--ffmpeg=%ffmpeg% --ffmpegUpdate=%ffmpegUpdate% --ffmpegChoice=%ffmpegChoice% --mplayer=%mplayer% ^
--mpv=%mpv% --license=%license2%  --stripping=%stripFile% --packing=%packFile% --rtmpdump=%rtmpdump% ^
--logging=%logging% --bmx=%bmx% --standalone=%standalone% --aom=%aom% --faac=%faac% --ffmbc=%ffmbc% ^
--curl=%curl% --cyanrip=%cyanrip% --redshift=%redshift% --rav1e=%rav1e% --ripgrep=%ripgrep% ^
--dav1d=%dav1d% --vvc=%vvc% --jq=%jq% --jo=%jo% --dssim=%dssim% --avs2=%avs2% --timeStamp=%timeStamp% ^
--noMintty=%noMintty% --ccache=%ccache% --svthevc=%svthevc% --svtav1=%svtav1% --svtvp9=%svtvp9% --xvc=%xvc%
    set "msys2=%msys2%"
    set "noMintty=%noMintty%"
    if %build64%==yes ( set "MSYSTEM=MINGW64" ) else set "MSYSTEM=MINGW32"
    set "MSYS2_PATH_TYPE=inherit"
    set "MSYS=%MSYS%"
    if %noMintty%==y set "PATH=%PATH%"
    set "build=%build%"
    set "instdir=%instdir%"
)
if %noMintty%==y (
    call :runBash compile.log /build/media-suite_compile.sh %compileArgs%
) else (
    if exist %build%\compile.log del %build%\compile.log
    start /I %CD%\%msys2%\usr\bin\mintty.exe -i /msys2.ico -t "media-autobuild_suite" ^
    --log 2>&1 %build%\compile.log /bin/env MSYSTEM=%MSYSTEM% MSYS2_PATH_TYPE=inherit ^
    MSYS=%MSYS% /usr/bin/bash ^
    --login /build/media-suite_compile.sh %compileArgs%
)
exit /B %ERRORLEVEL%
endlocal
goto :EOF

:createBaseFolders
if not exist %instdir%\%1\share (
    echo.-------------------------------------------------------------------------------
    echo.creating %1-bit install folders
    echo.-------------------------------------------------------------------------------
    mkdir %instdir%\%1 2>NUL
    mkdir %instdir%\%1\bin 2>NUL
    mkdir %instdir%\%1\bin-audio 2>NUL
    mkdir %instdir%\%1\bin-global 2>NUL
    mkdir %instdir%\%1\bin-video 2>NUL
    mkdir %instdir%\%1\etc 2>NUL
    mkdir %instdir%\%1\include 2>NUL
    mkdir %instdir%\%1\lib 2>NUL
    mkdir %instdir%\%1\lib\pkgconfig 2>NUL
    mkdir %instdir%\%1\share 2>NUL
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
    echo.export CC="ccache gcc"
    echo.export CXX="ccache g++"
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
    echo.CPPFLAGS="-D_FORTIFY_SOURCE=0 -D__USE_MINGW_ANSI_STDIO=1"
    echo.CFLAGS="-mthreads -mtune=generic -O2 -pipe"
    echo.CXXFLAGS="${CFLAGS}"
    echo.LDFLAGS="-pipe -static-libgcc -static-libstdc++"
    echo.export DXSDK_DIR ACLOCAL_PATH PKG_CONFIG PKG_CONFIG_PATH CPPFLAGS CFLAGS CXXFLAGS LDFLAGS MSYSTEM
    echo.
    echo.export CARGO_HOME="/opt/cargo" RUSTUP_HOME="/opt/cargo"
    echo.export SCCACHE_DIR="$HOME/.sccache"
    echo.export CCACHE_DIR="$HOME/.ccache"
    echo.
    echo.export PYTHONPATH=
    echo.
    echo.LANG=en_US.UTF-8
    echo.PATH="${MINGW_PREFIX}/bin:${INFOPATH}:${MSYS2_PATH}:${ORIGINAL_PATH}"
    echo.PATH="${LOCALDESTDIR}/bin-audio:${LOCALDESTDIR}/bin-global:${LOCALDESTDIR}/bin-video:${LOCALDESTDIR}/bin:${PATH}"
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
endlocal
goto :EOF

:runBash
setlocal enabledelayedexpansion
set "log=%1"
shift
set "command=%1"
shift
set args=%*
set arg=!args:%log% %command%=!
if %noMintty%==y (
    script -e -q --command "exec /usr/bin/bash -lc '%command% $@' -- %arg%" /dev/null | tee "%build%\%log%"
) else (
    if exist %build%\%log% del %build%\%log%
    start /I /WAIT %instdir%\%msys2%\usr\bin\mintty.exe -d -i /msys2.ico ^
    -t "media-autobuild_suite" --log 2>&1 %build%\%log% /usr/bin/bash -lc ^
    "%command% %arg%"
)
endlocal
goto :EOF

:getmingw
setlocal
if exist %instdir%\%msys2%\mingw%1\bin\gcc.exe GOTO :EOF
echo.-------------------------------------------------------------------------------
echo.install %1 bit compiler
echo.-------------------------------------------------------------------------------
(
    echo.echo -ne "\033]0;install %1 bit compiler\007"
    echo.mingwcompiler="$(cat /etc/pac-mingw.pk | sed 's;.*;&:%2;g' | tr '\n\r' '  ')"
    echo.[[ "$(uname)" = *6.1* ]] ^&^& nargs="-n 4"
    echo.echo $mingwcompiler ^| xargs $nargs pacboy -Sw --noconfirm --ask=20 --needed
    echo.echo $mingwcompiler ^| xargs $nargs pacboy -S --noconfirm --ask=20 --needed
    echo.sleep ^3
    echo.exit
)>%build%\mingw.sh
call :runBash mingw%1.log /build/mingw.sh

if not exist %instdir%\%msys2%\mingw%1\bin\gcc.exe (
    echo -------------------------------------------------------------------------------
    echo.
    echo.MinGW%1 GCC compiler isn't installed; maybe the download didn't work
    echo.Do you want to try it again?
    echo.
    echo -------------------------------------------------------------------------------
    set /P try="try again [y/n]: "

    if [%try%]==[y] (
        GOTO getmingw %1 %2
    ) else exit
)
endlocal
goto :EOF
