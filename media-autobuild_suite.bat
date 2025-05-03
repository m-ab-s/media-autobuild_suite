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

if %PROCESSOR_ARCHITECTURE%==x86 if NOT DEFINED PROCESSOR_ARCHITEW6432 (
    echo ----------------------------------------------------------------------
    echo. 32-bit host machine and OS are no longer supported by the suite
    echo. nor upstream for building.
    echo. Please consider either moving to a 64-bit machine and OS or use
    echo. a 64-bit machine to compile the binaries you need.
    pause
    exit
)

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

if not ["%instdir:~32,1%"]==[""] (
    echo -------------------------------------------------------------------------------
    echo. The total filepath to the suite seems too large (larger than 32 characters^):
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

set msyspackages=autoconf-archive autoconf-wrapper autogen automake-wrapper base dos2unix ^
filesystem git libtool make msys2-runtime patch pacutils p7zip subversion unzip winpty

set mingwpackages=ccache cmake dlfcn gettext-tools meson nasm ninja pkgconf

:: built-ins
set ffmpeg_options_builtin=--disable-autodetect amf bzlib cuda cuvid d3d12va d3d11va dxva2 ^
iconv lzma nvenc schannel zlib sdl2 ffnvcodec nvdec cuda-llvm

:: common external libs
set ffmpeg_options_basic=gmp libmp3lame libopus libvorbis libvpx libx264 libx265 ^
libdav1d libaom --disable-debug libfdk-aac

:: options used in zeranoe builds and not present above
set ffmpeg_options_zeranoe=fontconfig gnutls libass libbluray libfreetype ^
libharfbuzz libvpl libmysofa libopencore-amrnb libopencore-amrwb libopenjpeg libsnappy ^
libsoxr libspeex libtheora libtwolame libvidstab libvo-amrwbenc ^
libwebp libxml2 libzimg libshine gpl openssl libtls avisynth #mbedtls libxvid ^
libopenmpt version3 librav1e libsrt libgsm libvmaf libsvtav1

:: options also available with the suite
set ffmpeg_options_full=chromaprint decklink frei0r libaribb24 libbs2b libcaca ^
libcdio libflite libfribidi libgme libilbc libsvthevc ^
libsvtvp9 libkvazaar libmodplug librist librtmp librubberband #libssh ^
libtesseract libxavs libzmq libzvbi openal libcodec2 ladspa #vapoursynth #liblensfun ^
libglslang vulkan libdavs2 libxavs2 libuavs3d libplacebo libjxl libvvenc libvvdec liblc3

:: options also available with the suite that add shared dependencies
set ffmpeg_options_full_shared=opencl opengl cuda-nvcc libnpp libopenh264

:: built-ins
set mpv_options_builtin=#-Dcplayer=true #manpage-build #lua #javascript ^
#libbluray #uchardet #rubberband #lcms2 #libarchive #libavdevice ^
#shaderc #spirv-cross #d3d11 #jpeg #vapoursynth #vulkan

:: overriden defaults
set mpv_options_basic=-Dlua=luajit

:: all supported options
set mpv_options_full=dvdnav cdda #egl-angle #html-build ^
#pdf-build openal sdl2 #sdl2-gamepad #sdl2-audio #sdl2-video

set iniOptions=arch license2 vpx2 x2643 x2652 other265 flac fdkaac mediainfo ^
soxB ffmpegB2 ffmpegUpdate ffmpegChoice mp4box rtmpdump mplayer2 mpv cores deleteSource ^
strip pack logging bmx standalone updateSuite av1an aom faac exhale ffmbc curl cyanrip2 ^
rav1e ripgrep dav1d libavif libheif vvc uvg266 jq dssim gifski avs2 dovitool hdr10plustool timeStamp ^
noMintty ccache svthevc svtav1 svtvp9 xvc jo vlc CC jpegxl vvenc vvdec zlib ffmpegPath pkgUpdateTime
@rem re-add autouploadlogs if we find some way to upload to github directly instead

set deleteIni=0
set ini=%build%\media-autobuild_suite.ini

rem Set all INI options to 0
for %%a in (%iniOptions%) do set %%aINI=0

if exist %ini% (
    rem Set INI options to what's found in the inifile
    echo.foreach ($option in $env:iniOptions.split(" "^)^) { ^
        $m = Select-String -Path $env:ini -CaseSensitive -SimpleMatch -Pattern $option; ^
        if ($null -ne $m^) { ^
            Write-Output "set `"${option}INI^=$($m.Line.Split("="^, 2^)[1]^)`"" ^
        } else { ^
            Write-Output "set `"${option}INI^=0^`"" ^
        } ^
    } | powershell -NoProfile -Command - > %build%\options.bat
    call %build%\options.bat
    del %build%\options.bat
) else set deleteIni=1

setlocal EnableDelayedExpansion
rem Check if any of the *INI options are still unset (0)
for %%a in (%iniOptions%) do if [0]==[!%%aINI!] set deleteIni=1 && goto :endINIcheck
:endINIcheck
endlocal & set deleteIni=%deleteIni%

if %deleteINI%==1 echo.[compiler list] >"%ini%"

:selectSystem
if [0]==[%archINI%] (
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
if [0]==[%license2INI%] (
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
if [0]==[%standaloneINI%] (
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

:av1an
if [0]==[%av1anINI%] (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build Av1an [Scalable video encoding framework]?
    echo. 1 = Yes [link with static FFmpeg]
    echo. 2 = Yes [link with shared FFmpeg]
    echo. 3 = No
    echo.
    echo. Av1an requires local installed copies of Python and Vapoursynth,
    echo. an executable of FFmpeg and one of these encoders to function:
    echo. aom, SVT-AV1, rav1e, vpx, x264, or x265
    echo. If FFmpeg is built shared, then the Av1an executable will be in a subfolder.
    echo. (Note: Not available for 32-bit due to Vapoursynth being broken in 32-bit!^)
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildav1an="Build av1an: "
) else set buildav1an=%av1anINI%

if "%buildav1an%"=="" GOTO av1an
if %buildav1an%==1 set "av1an=y"
if %buildav1an%==2 set "av1an=shared"
if %buildav1an%==3 set "av1an=n"
if %buildav1an% GTR 3 GOTO av1an
if %deleteINI%==1 echo.av1an=^%buildav1an%>>%ini%

:vpx
if [0]==[%vpx2INI%] (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build vpx [VP8/VP9 encoder]?
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo. Binaries being built depends on "standalone/av1an=y" and are always static.
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
if [0]==[%aomINI%] (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build aom [Alliance for Open Media codec]?
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo. Binaries being built depends on "standalone/av1an=y" and are always static.
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
if [0]==[%rav1eINI%] (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build rav1e [Alternative, faster AV1 standalone encoder]?
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo. Binaries being built depends on "standalone/av1an=y" and are always static.
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
if [0]==[%dav1dINI%] (
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

:libavif
if [0]==[%libavifINI%] (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build libavif [AV1 image format encoder and decoder]?
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo. Binaries being built depends on "standalone=y" and are always static.
    echo. Will build aom, dav1d, and rav1e if not already previously enabled
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildlibavif="Build libavif: "
) else set buildlibavif=%libavifINI%

if "%buildlibavif%"=="" GOTO libavif
if %buildlibavif%==1 set "libavif=y"
if %buildlibavif%==2 set "libavif=n"
if %buildlibavif% GTR 2 GOTO libavif
if %deleteINI%==1 echo.libavif=^%buildlibavif%>>%ini%

:libheif
if [0]==[%libheifINI%] (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build libheif [High Efficiency Image File Format encoder and decoder]?
    echo. 1 = Yes
    echo. 2 = No
    echo. 3 = Shared (a single libheif.dll with multiple executables^)
    echo.
    echo. Will use available encoders and decoders supported by libheif.
    echo. If not found, built libheif will lack the corresponding encode/decode ability.
    echo. Additionally libde265 will be built.
    echo. dec265 of libde265 being built depends on "standalone=y" and is always static.
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildlibheif="Build libheif: "
) else set buildlibheif=%libheifINI%

if "%buildlibheif%"=="" GOTO libheif
if %buildlibheif%==1 set "libheif=y"
if %buildlibheif%==2 set "libheif=n"
if %buildlibheif%==3 set "libheif=shared"
if %buildlibheif% GTR 3 GOTO libheif
if %deleteINI%==1 echo.libheif=^%buildlibheif%>>%ini%

:jpegxl
if [0]==[%jpegxlINI%] (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build jpeg-xl tools [JPEG XL image format encoder and decoder]?
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildjpegxl="Build jpegxl: "
) else set buildjpegxl=%jpegxlINI%

if "%buildjpegxl%"=="" GOTO jpegxl
if %buildjpegxl%==1 set "jpegxl=y"
if %buildjpegxl%==2 set "jpegxl=n"
if %buildjpegxl% GTR 2 GOTO jpegxl
if %deleteINI%==1 echo.jpegxl=^%buildjpegxl%>>%ini%

:x264
if [0]==[%x2643INI%] (
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
    echo. Binaries being built depends on "standalone/av1an=y" and are always static.
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
if [0]==[%x2652INI%] (
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
    echo. Binaries being built depends on "standalone/av1an=y" and are always static.
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
if [0]==[%other265INI%] (
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
if [0]==[%svthevcINI%] (
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
if [0]==[%xvcINI%] (
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
if [0]==[%vvcINI%] (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build VVC Reference Software? [H.265 successor enc/decoder]
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

:uvg266
if [0]==[%uvg266INI%] (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build uvg266? [H.266 encoder by ultravideo, the Kvazaar team]
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P builduvg266="Build uvg266: "
) else set builduvg266=%uvg266INI%

if "%builduvg266%"=="" GOTO uvg266
if %builduvg266%==1 set "uvg266=y"
if %builduvg266%==2 set "uvg266=n"
if %builduvg266% GTR 2 GOTO uvg266
if %deleteINI%==1 echo.uvg266=^%builduvg266%>>%ini%

:vvenc
if [0]==[%vvencINI%] (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build vvenc? [Fraunhofer HHI Versatile Video Encoder]
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildvvenc="Build vvenc: "
) else set buildvvenc=%vvencINI%

if "%buildvvenc%"=="" GOTO vvenc
if %buildvvenc%==1 set "vvenc=y"
if %buildvvenc%==2 set "vvenc=n"
if %buildvvenc% GTR 2 GOTO vvenc
if %deleteINI%==1 echo.vvenc=^%buildvvenc%>>%ini%

:vvdec
if [0]==[%vvdecINI%] (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build vvdec? [Fraunhofer HHI Versatile Video Decoder]
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildvvdec="Build vvdec: "
) else set buildvvdec=%vvdecINI%

if "%buildvvdec%"=="" GOTO vvdec
if %buildvvdec%==1 set "vvdec=y"
if %buildvvdec%==2 set "vvdec=n"
if %buildvvdec% GTR 2 GOTO vvdec
if %deleteINI%==1 echo.vvdec=^%buildvvdec%>>%ini%

:svtav1
if [0]==[%svtav1INI%] (
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
if [0]==[%svtvp9INI%] (
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
if [0]==[%flacINI%] (
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
if [0]==[%fdkaacINI%] (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build FDK-AAC library and binary? [AAC-LC/HE/HEv2 codec]
    echo. 1 = Yes
    echo. 2 = No
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
if [0]==[%faacINI%] (
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

:exhale
if [0]==[%exhaleINI%] (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build exhale binary? [open-source ISO/IEC 23003-3 USAC, xHE-AAC encoder]
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo. Binaries being built do not depend on "standalone=y"
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildexhale="Build exhale: "
) else set buildexhale=%exhaleINI%

if "%buildexhale%"=="" GOTO exhale
if %buildexhale%==1 set "exhale=y"
if %buildexhale%==2 set "exhale=n"
if %buildexhale% GTR 2 GOTO exhale
if %deleteINI%==1 echo.exhale=^%buildexhale%>>%ini%

:mediainfo
if [0]==[%mediainfoINI%] (
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
if [0]==[%soxBINI%] (
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
if [0]==[%ffmpegB2INI%] (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build FFmpeg binaries and libraries:
    echo. 1 = Yes [static] [recommended]
    echo. 2 = No
    echo. 3 = Shared
    echo. 4 = Both static and shared [shared goes to an isolated directory]
    echo. 5 = Shared-only with some shared dependencies (libass, freetype and fribidi^)
    echo. 6 = Same as 4, but static compilation ignores shared dependencies
    echo.
    echo. Note: Option 5 differs from 3 in that libass, freetype and fribidi are
    echo. compiled shared so they take less space. Currently broken if libass or libass
    echo. dependees are enabled.
    echo. Option 6 produces static and shared ffmpeg and ffmpeg libs where the static
    echo. one includes only strictly static dependencies (opencl, opengl, cuda-nvcc,
    echo. libnpp, libopenh264 are hard disabled.^)
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

set defaultFFmpegPath=https://git.ffmpeg.org/ffmpeg.git

:ffmpegPath
if [0]==[%ffmpegPathINI%] (
    set ffmpegPath=%defaultFFmpegPath%
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Using default ffmpeg source path: https://git.ffmpeg.org/ffmpeg.git
    echo.
    echo. If you want to use a custom source repository, add a line like this 
    echo. to media-autobuild_suite.ini:
    echo.
    echo.     ffmpegPath=https://github.com/username/FFmpeg.git#branch=branchname
    echo. 
    echo. or for a local repository like:
    echo.
    echo.     ffmpegPath=../myrepos/ffmpeg
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
) else set ffmpegPath=%ffmpegPathINI%

if %deleteINI%==1 echo.ffmpegPath=%ffmpegPath%>>%ini%

rem Handle relative paths and convert to absolute path
rem after sanitizing: back- to forward-slashes, remove colon after drive letter
call :resolvePath %ffmpegPath%
setlocal EnableDelayedExpansion
if exist %resolvePath% (
    set nixdir=!resolvePath:\=/!
    set "ffmpegPath=/!nixdir::=!"
)
endlocal & set "ffmpegPath=%ffmpegPath%"

if not [%defaultFFmpegPath%]==[%ffmpegPath%] (
    echo -------------------------------------------------------------------------------
    echo.
    echo. Using ffmpeg path: %ffmpegPath%
    echo.
    echo -------------------------------------------------------------------------------
)

:ffmpegUp
if [0]==[%ffmpegUpdateINI%] (
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
if [0]==[%ffmpegChoiceINI%] (
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
            call :writeFFmpegOption %ffmpeg_options_builtin%
            echo.
            echo.# Common options
            call :writeFFmpegOption %ffmpeg_options_basic%
            echo.
            echo.# Zeranoe
            call :writeFFmpegOption %ffmpeg_options_zeranoe%
            echo.
            echo.# Full
            call :writeFFmpegOption %ffmpeg_options_full%
            echo.
            echo.# Full plus options that add shared dependencies
            call :writeFFmpegOption %ffmpeg_options_full_shared%
            )>%build%\ffmpeg_options.txt
        echo -------------------------------------------------------------------------------
        echo. File with default FFmpeg options has been created in
        echo. %build%\ffmpeg_options.txt
        echo.
        echo. Edit it now or leave it unedited to compile according to defaults.
        echo -------------------------------------------------------------------------------
        pause
        )
    findstr /C:--enable-cplayer %build%\mpv_options.txt >nul 2>&1 && for /f %%i in ('powershell -c "Get-Date -format yyyy-MM-dd--HH-mm-ss"') do (
        rename %build%\mpv_options.txt %%i-mpv_options.txt >nul 2>&1
        echo -------------------------------------------------------------------------------
        echo. Old mpv_options.txt was detected.
        echo. It has been renamed to %%i-mpv_options.txt.
        echo. You can delete it if you don't need it.
        echo -------------------------------------------------------------------------------
        echo.
    )
    if not exist %build%\mpv_options.txt (
        (
            echo.# Lines starting with this character are ignored
            echo.
            echo.# Built-in options, use =disabled to disable them
            call :writempvOption %mpv_options_builtin%
            echo.
            echo.# Common options or overriden defaults
            call :writempvOption %mpv_options_basic%
            echo.
            echo.# Full
            call :writempvOption %mpv_options_full%
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
if [0]==[%mp4boxINI%] (
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
if [0]==[%rtmpdumpINI%] (
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
if [0]==[%mplayer2INI%] (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. #################### UNSUPPORTED, IF IT BREAKS, IT BREAKS ####################
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
if [0]==[%mpvINI%] (
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

:vlc
if [0]==[%vlcINI%] (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build VLC media player?
    echo. Takes a long time because of qt5 and wouldn't recommend it if you
    echo. don't have ccache enabled.
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo. Note: compilation of VLC is currently broken, do not enable unless you know
    echo. what you are doing.
    echo. 
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildvlc="Build vlc: "
) else set buildvlc=%vlcINI%

if "%buildvlc%"=="" GOTO vlc
if %buildvlc%==1 set "vlc=y"
if %buildvlc%==2 set "vlc=n"
if %buildvlc% GTR 2 GOTO vlc
if %deleteINI%==1 echo.vlc=^%buildvlc%>>%ini%

:bmx
if [0]==[%bmxINI%] (
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
if [0]==[%curlINI%] (
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
if [0]==[%ffmbcINI%] (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. #################### UNSUPPORTED, IF IT BREAKS, IT BREAKS ####################
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
if [0]==[%cyanrip2INI%] (
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

:ripgrep
if [0]==[%ripgrepINI%] (
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
if [0]==[%jqINI%] (
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
if [0]==[%joINI%] (
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
if [0]==[%dssimINI%] (
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

:gifski
if [0]==[%gifskiINI%] (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build gifski (high quality GIF encoder in Rust^)?
    echo. 1 = Yes
    echo. 2 = With built-in video support
    echo. 3 = No
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildgifski="Build gifski: "
) else set buildgifski=%gifskiINI%

if "%buildgifski%"=="" GOTO gifski
if %buildgifski%==1 set "gifski=y"
if %buildgifski%==2 set "gifski=video"
if %buildgifski%==3 set "gifski=n"
if %buildgifski% GTR 3 GOTO gifski
if %deleteINI%==1 echo.gifski=^%buildgifski%>>%ini%

:avs2
if [0]==[%avs2INI%] (
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

:dovitool
if [0]==[%dovitoolINI%] (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build dovi_tool (CLI tool for working with Dolby Vision^)?
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P builddovitool="Build dovi_tool: "
) else set builddovitool=%dovitoolINI%

if "%builddovitool%"=="" GOTO dovitool
if %builddovitool%==1 set "dovitool=y"
if %builddovitool%==2 set "dovitool=n"
if %builddovitool% GTR 2 GOTO dovitool
if %deleteINI%==1 echo.dovitool=^%builddovitool%>>%ini%

:hdr10plustool
if [0]==[%hdr10plustoolINI%] (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build hdr10plus_tool (CLI utility to work with HDR10+ in HEVC files^)?
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildhdr10plustool="Build hdr10plus_tool: "
) else set buildhdr10plustool=%hdr10plustoolINI%

if "%buildhdr10plustool%"=="" GOTO hdr10plustool
if %buildhdr10plustool%==1 set "hdr10plustool=y"
if %buildhdr10plustool%==2 set "hdr10plustool=n"
if %buildhdr10plustool% GTR 2 GOTO hdr10plustool
if %deleteINI%==1 echo.hdr10plustool=^%buildhdr10plustool%>>%ini%

:zlib
if [0]==[%zlibINI%] (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build zlib?
    echo. 1 = Yes, build zlib
    echo. 2 = Yes, build zlib (Chromium fork^)
    echo. 3 = Yes, build zlib (Cloudflare fork^)
    echo. 4 = Yes, build zlib-ng
    echo. 5 = Yes, build zlib-rs
    echo. 6 = No, use msys2 package when needed [Recommended]
    echo.
    echo. If "standalone=y", then minizip will be built alongside zlib.
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildzlib="Build zlib: "
) else set buildzlib=%zlibINI%

if "%buildzlib%"=="" GOTO zlib
if %buildzlib%==1 set "zlib=y"
if %buildzlib%==2 set "zlib=chromium"
if %buildzlib%==3 set "zlib=cloudflare"
if %buildzlib%==4 set "zlib=ng"
if %buildzlib%==5 set "zlib=rs"
if %buildzlib%==6 set "zlib=n"
if %buildzlib% GTR 6 GOTO zlib
if %deleteINI%==1 echo.zlib=^%buildzlib%>>%ini%

:CC
if [0]==[%CCINI%] (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Use clang instead of gcc (C compiler^)?
    echo. Experimental and possibly broken due to gcc assumptions
    echo. 1 = Yes
    echo. 2 = No [Recommended]
    echo.
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildCC="Build using clang: "
) else set buildCC=%CCINI%

if "%buildCC%"=="" GOTO CC
if %buildCC%==1 set "CC=clang"
if %buildCC%==2 set "CC=gcc"
if %buildCC% GTR 2 GOTO CC
if %deleteINI%==1 echo.CC=^%buildCC%>>%ini%

:numCores
if %NUMBER_OF_PROCESSORS% EQU 1 ( set coreHalf=1 ) else set /a coreHalf=%NUMBER_OF_PROCESSORS%/2
if [0]==[%coresINI%] (
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

if [0]==[%deleteSourceINI%] (
:delete
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Delete versioned source folders after compile is done?
    echo. 1 = Yes [recommended]
    echo. 2 = No
    echo.
    echo. This will save a bit of space for libraries not compiled from git.
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
if [0]==[%stripINI%] (
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
if [0]==[%packINI%] (
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
if [0]==[%loggingINI%] (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Write logs of compilation commands?
    echo. 1 = Yes [recommended]
    echo. 2 = No
    echo.
    echo. Note: Setting this to yes will also hide output from these commands.
    echo. On successful compilation, these logs are deleted since they aren't needed.
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

@REM :autouploadlogs
@REM if [0]==[%autouploadlogsINI%] (
@REM     echo -------------------------------------------------------------------------------
@REM     echo -------------------------------------------------------------------------------
@REM     echo.
@REM     echo. Automatically upload error logs to 0x0.st?
@REM     echo. 1 = Yes [recommended]
@REM     echo. 2 = No
@REM     echo.
@REM     echo. This will upload logs.zip to 0x0.st for easy copy and pasting into github
@REM     echo. issues. If you choose no, then uploading logs will be your responsibility and
@REM     echo. no guarantees will be made for issues lacking logs.
@REM     echo.
@REM     echo -------------------------------------------------------------------------------
@REM     echo -------------------------------------------------------------------------------
@REM     set /P autouploadlogsF="Upload logs: "
@REM ) else set autouploadlogsF=%autouploadlogsINI%

@REM if "%autouploadlogsF%"=="" GOTO autouploadlogs
@REM if %autouploadlogsF%==1 set "autouploadlogs=y"
@REM if %autouploadlogsF%==2 set "autouploadlogs=n"
@REM if %autouploadlogsF% GTR 2 GOTO autouploadlogs
@REM if %deleteINI%==1 echo.autouploadlogs=^%autouploadlogsF%>>%ini%

:updateSuite
if [0]==[%updateSuiteINI%] (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Create script to update suite files automatically?
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo. If you have made changes to the scripts, they will be reset but saved to a
    echo. .diff text file inside %build%
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
if [0]==[%timeStampINI%] (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Show timestamps of commands during compilation?
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo. This will show the start times of commands during compilation.
    echo. Don't turn this on unless you really want to see the timestamps.
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P timeStampF="Show timestamps: "
) else set timeStampF=%timeStampINI%

if "%timeStampF%"=="" GOTO timestamp
if %timeStampF%==1 set "timeStamp=y"
if %timeStampF%==2 set "timeStamp=n"
if %timeStampF% GTR 2 GOTO timeStamp
if %deleteINI%==1 echo.timeStamp=^%timeStampF%>>%ini%

:ccache
if [0]==[%ccacheINI%] (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Use ccache when compiling?
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo. Speeds up rebuilds and recompilations, but requires the files
    echo. to be compiled at least once before any effect is seen
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
if [0]==[%noMinttyINI%] (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Are you running this script through ssh or similar?
    echo. (Can't open another window outside of this terminal^)
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo. This will disable the use of mintty and print the output to this console.
    echo. There is no guarantee that this will work properly.
    echo. You must make sure that you have ssh keep-alive enabled or something similar
    echo. to screen that will allow you to run this script in the background.
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

rem pkgUpdateTime
if [0]==[%pkgUpdateTimeINI%] (
    set pkgUpdateTime=86400
) else set pkgUpdateTime=%pkgUpdateTimeINI%
if %deleteINI%==1 echo.pkgUpdateTime=^%pkgUpdateTime%>>%ini%

if %build32%==yes (
    if %CC%==clang (
        echo ----------------------------------------------------------------------
        echo. As of December 18th 2024, msys2 no longer supports the
        echo. CLANG32 environment. To continue running the suite, either
        echo. switch to 64-bit (arch=3^), or
        echo. switch to using gcc as the compiler (CC=2^).
        echo. This can be done through editing build\media-autobuild_suite.ini.
        pause
        exit
    )
)

rem ------------------------------------------------------------------
rem download and install basic msys2 system:
rem ------------------------------------------------------------------
cd %build%
set scripts=media-suite_compile.sh media-suite_deps.sh media-suite_helper.sh media-suite_update.sh
for %%s in (%scripts%) do (
    if not exist "%build%\%%s" (
        powershell -Command (New-Object System.Net.WebClient^).DownloadFile('"https://github.com/m-ab-s/media-autobuild_suite/raw/master/build/%%s"', '"%%s"' ^)
    )
)

rem checkmsys2
if not exist "%instdir%\msys64\msys2_shell.cmd" (
    echo -------------------------------------------------------------------------------
    echo.
    echo.- Download and install msys2 basic system
    echo.
    echo -------------------------------------------------------------------------------
    echo [System.Net.ServicePointManager]::SecurityProtocol = 'Tls12'; ^
        (New-Object System.Net.WebClient^).DownloadFile(^
        'https://github.com/msys2/msys2-installer/releases/download/nightly-x86_64/msys2-base-x86_64-latest.sfx.exe', ^
        "$PWD\msys2-base.sfx.exe"^) | powershell -NoProfile -Command - || goto :errorMsys
    :unpack
    if exist %build%\msys2-base.sfx.exe (
        echo -------------------------------------------------------------------------------
        echo.
        echo.- unpacking msys2 basic system
        echo.
        echo -------------------------------------------------------------------------------
        .\msys2-base.sfx.exe x -y -o".."
        if exist msys2-base.sfx.exe del msys2-base.sfx.exe
    )

    if not exist %instdir%\msys64\usr\bin\msys-2.0.dll (
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
set "bash=%instdir%\msys64\usr\bin\bash.exe"
set "PATH=%instdir%\msys64\opt\bin;%instdir%\msys64\usr\bin;%PATH%"
if not exist %instdir%\mintty.lnk (
    echo -------------------------------------------------------------------------------
    echo.- make a first run
    echo -------------------------------------------------------------------------------
    call :runBash firstrun.log exit

    sed -i "s/#Color/Color/;s/^^IgnorePkg.*/#&/" %instdir%\msys64\etc\pacman.conf

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
        if %CC%==clang (
            echo.link.Arguments = "-full-path -clang64 -where .."
        ) else (
            echo.link.Arguments = "-full-path -mingw -where .."
        )
        echo.link.Description = "msys2 shell console"
        echo.link.TargetPath = "%instdir%\msys64\msys2_shell.cmd"
        echo.link.WindowStyle = 1
        echo.link.IconLocation = "%instdir%\msys64\msys2.ico"
        echo.link.WorkingDirectory = "%instdir%\msys64"
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
set "fstab=%instdir%\msys64\etc\fstab"
if exist %fstab%. (
    findstr trunk %fstab% >nul 2>&1 || set "removefstab=yes"
    for /f "tokens=1 delims= " %%a in ('findstr trunk %fstab%') do if not [%%a]==[%instdir%\] set "removefstab=yes"
    findstr local32 %fstab% >nul 2>&1 && ( if [%build32%]==[no] set "removefstab=yes" ) || if [%build32%]==[yes] set "removefstab=yes"
    findstr local64 %fstab% >nul 2>&1 && ( if [%build64%]==[no] set "removefstab=yes" ) || if [%build64%]==[yes] set "removefstab=yes"
    findstr clang32 %fstab% >nul 2>&1 && set "removefstab=yes"
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
        echo.%instdir%\ /trunk ntfs binary,posix=0,noacl,user 0 0
        echo.%instdir%\build\ /build ntfs binary,posix=0,noacl,user 0 0
        echo.%instdir%\msys64\mingw32\ /mingw32 ntfs binary,posix=0,noacl,user 0 0
        echo.%instdir%\msys64\mingw64\ /mingw64 ntfs binary,posix=0,noacl,user 0 0
        echo.%instdir%\msys64\clang64\ /clang64 ntfs binary,posix=0,noacl,user 0 0
        if "%build32%"=="yes" echo.%instdir%\local32\ /local32 ntfs binary,posix=0,noacl,user 0 0
        if "%build64%"=="yes" echo.%instdir%\local64\ /local64 ntfs binary,posix=0,noacl,user 0 0
    )>"%instdir%\msys64\etc\fstab."
)

if not exist "%instdir%\msys64\home\%USERNAME%" mkdir "%instdir%\msys64\home\%USERNAME%"
set "TERM="
type nul >>"%instdir%\msys64\home\%USERNAME%\.minttyrc"
for /F "tokens=2 delims==" %%b in ('findstr /i TERM "%instdir%\msys64\home\%USERNAME%\.minttyrc"') do set TERM=%%b
if not defined TERM (
    printf %%s\n Locale=en_US Charset=UTF-8 Font=Consolas Columns=120 Rows=30 TERM=xterm-256color ^
    > "%instdir%\msys64\home\%USERNAME%\.minttyrc"
    set "TERM=xterm-256color"
)

rem gitsettings
if not exist "%instdir%\msys64\home\%USERNAME%\.gitconfig" (
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
)>"%instdir%\msys64\home\%USERNAME%\.gitconfig"

rem installbase
if exist "%instdir%\msys64\etc\pac-base.pk" del "%instdir%\msys64\etc\pac-base.pk"
for %%i in (%msyspackages%) do echo.%%i>>%instdir%\msys64\etc\pac-base.pk

if not exist %instdir%\msys64\usr\bin\make.exe (
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

for %%i in (%instdir%\msys64\usr\ssl\cert.pem) do if %%~zi==0 call :runBash cert.log update-ca-trust

rem installmingw
rem extra package for clang
if %CC%==clang (
    set "mingwpackages=%mingwpackages% clang gcc-compat lld"
) else (
    set "mingwpackages=%mingwpackages% binutils gcc"
)
if exist "%instdir%\msys64\etc\pac-mingw.pk" del "%instdir%\msys64\etc\pac-mingw.pk"
for %%i in (%mingwpackages%) do echo.%%i>>%instdir%\msys64\etc\pac-mingw.pk
if %build32%==yes call :getmingw 32
if %build64%==yes call :getmingw 64
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
        %instdir%\msys64\usr\bin\sed -n '/start suite update/,/end suite update/p' ^
            %build%/media-suite_update.sh
    )>%instdir%\update_suite.sh
)

rem ------------------------------------------------------------------
rem write config profiles:
rem ------------------------------------------------------------------

if %build32%==yes call :writeProfile 32
if %build64%==yes call :writeProfile 64

rem update
if exist "%instdir%\build\updated.log" (
    powershell -noprofile -command "exit ([datetimeoffset]::now.tounixtimeseconds() - (get-content %instdir%\build\updated.log) -gt %pkgUpdateTime%)" || set needsupdate=yes
) else (
    set needsupdate=yes
)
if defined needsupdate (
    call :runBash update.log /build/media-suite_update.sh --build32=%build32% --build64=%build64% --CC="%CC%"
    powershell -noprofile -command "[datetimeoffset]::now.tounixtimeseconds()" > %instdir%\build\updated.log
)

if exist "%build%\update_core" (
    echo.-------------------------------------------------------------------------------
    echo.critical updates
    echo.-------------------------------------------------------------------------------
    pacman -S --needed --noconfirm --ask=20 --asdeps bash pacman msys2-runtime
    del "%build%\update_core"
)

mkdir "%instdir%\msys64\home\%USERNAME%\.gnupg" > nul 2>&1
findstr hkps://keys.openpgp.org "%instdir%\msys64\home\%USERNAME%\.gnupg\gpg.conf" >nul 2>&1 || echo keyserver hkps://keys.openpgp.org >> "%instdir%\msys64\home\%USERNAME%\.gnupg\gpg.conf"

rem loginProfile
if exist %instdir%\msys64\etc\profile.pacnew ^
    move /y %instdir%\msys64\etc\profile.pacnew %instdir%\msys64\etc\profile
(
    echo.case "$MSYSTEM" in
    echo.*32^) source /local32/etc/profile2.local ;;
    echo.*64^) source /local64/etc/profile2.local ;;
    echo.esac
    echo.case $- in
    echo.*i*^) ;;
    echo.*^) export LANG=en_US.UTF-8 ;;
    echo.esac
)>%instdir%\msys64\etc\profile.d\Zab-suite.sh

rem compileLocals
cd %instdir%

title MABSbat

if exist %build%\compilation_failed del %build%\compilation_failed
if exist %build%\fail_comp del %build%\compilation_failed

endlocal & (
set compileArgs=--cpuCount=%cpuCount% --build32=%build32% --build64=%build64% ^
--deleteSource=%deleteSource% --mp4box=%mp4box% --vpx=%vpx2% --x264=%x2643% --x265=%x2652% ^
--other265=%other265% --flac=%flac% --fdkaac=%fdkaac% --mediainfo=%mediainfo% --sox=%sox% ^
--ffmpeg=%ffmpeg% --ffmpegUpdate=%ffmpegUpdate% --ffmpegChoice=%ffmpegChoice% --mplayer=%mplayer% ^
--mpv=%mpv% --license=%license2%  --stripping=%stripFile% --packing=%packFile% --rtmpdump=%rtmpdump% ^
--logging=%logging% --bmx=%bmx% --standalone=%standalone% --aom=%aom% --faac=%faac% --exhale=%exhale% ^
--ffmbc=%ffmbc% --curl=%curl% --cyanrip=%cyanrip% --rav1e=%rav1e% --ripgrep=%ripgrep% --dav1d=%dav1d% ^
--vvc=%vvc% --uvg266=%uvg266% --vvenc=%vvenc% --vvdec=%vvdec% --jq=%jq% --jo=%jo% --dssim=%dssim% ^
--gifski=%gifski% --avs2=%avs2% --dovitool=%dovitool% --hdr10plustool=%hdr10plustool% --timeStamp=%timeStamp% ^
--noMintty=%noMintty% --ccache=%ccache% --svthevc=%svthevc% --svtav1=%svtav1% --svtvp9=%svtvp9% ^
--xvc=%xvc% --vlc=%vlc% --libavif=%libavif% --libheif=%libheif% --jpegxl=%jpegxl% --av1an=%av1an% --zlib=%zlib% ^
--ffmpegPath=%ffmpegPath% --exitearly=%MABS_EXIT_EARLY%
    @REM --autouploadlogs=%autouploadlogs%
    set "noMintty=%noMintty%"
    if %build64%==yes (
        if %CC%==clang ( set "MSYSTEM=CLANG64" ) else set "MSYSTEM=MINGW64"
    ) else (
        set "MSYSTEM=MINGW32"
    )
    set "MSYS2_PATH_TYPE=inherit"
    if %noMintty%==y set "PATH=%PATH%"
    set "build=%build%"
    set "instdir=%instdir%"
)
if %noMintty%==y (
    call :runBash compile.log /build/media-suite_compile.sh %compileArgs%
) else (
    if exist %build%\compile.log del %build%\compile.log
    start "compile" /I /LOW %CD%\msys64\usr\bin\mintty.exe -i /msys2.ico -t "media-autobuild_suite" ^
    --log 2>&1 %build%\compile.log /bin/env MSYSTEM=%MSYSTEM% MSYS2_PATH_TYPE=inherit ^
    /usr/bin/bash ^
    --login /build/media-suite_compile.sh %compileArgs%
)
color
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
    echo.#!/usr/bin/bash
    if %CC%==clang (
        echo.MSYSTEM=CLANG%1
    ) else (
        echo.MSYSTEM=MINGW%1
    )
    echo.source /etc/msystem
    echo.
    echo.# package build directory
    echo.export LOCALBUILDDIR='/build'
    echo.# package installation prefix
    echo.export LOCALDESTDIR='/local%1'
    echo.
    echo.bits='%1bit'
    echo.
    echo.export CONFIG_SITE=/etc/config.site
    echo.alias dir='ls -la --color=auto'
    echo.alias ls='ls --color=auto'
    if %CC%==clang (
        echo.export CC="ccache clang"
        echo.export CXX="ccache clang++"
    ) else (
        echo.export CC="ccache gcc"
        echo.export CXX="ccache g++"
    )
    echo.
    echo.CARCH="${MINGW_CHOST%%%%-*}"
    echo.C_INCLUDE_PATH="$(cygpath -pm $LOCALDESTDIR/include:$MINGW_PREFIX/include)"
    echo.CPLUS_INCLUDE_PATH="$(cygpath -pm $LOCALDESTDIR/include)"
    echo.export C_INCLUDE_PATH CPLUS_INCLUDE_PATH
    echo.
    echo.MANPATH="${LOCALDESTDIR}/share/man:${MINGW_PREFIX}/share/man:/usr/share/man"
    echo.INFOPATH="${LOCALDESTDIR}/share/info:${MINGW_PREFIX}/share/info:/usr/share/info"
    echo.
    echo.DXSDK_DIR="${MINGW_PREFIX}/${MINGW_CHOST}"
    echo.ACLOCAL_PATH="${LOCALDESTDIR}/share/aclocal:${MINGW_PREFIX}/share/aclocal:/usr/share/aclocal"
    echo.PKG_CONFIG="${MINGW_PREFIX}/bin/pkgconf --keep-system-cflags --static"
    echo.PKG_CONFIG_PATH="${LOCALDESTDIR}/lib/pkgconfig:${MINGW_PREFIX}/lib/pkgconfig"
    echo.
    echo.CFLAGS="-D_FORTIFY_SOURCE=2 -fstack-protector-strong" # security related flags
    echo.CFLAGS+=" -mtune=generic -O2 -pipe" # performance related flags
    echo.CFLAGS+=" -D__USE_MINGW_ANSI_STDIO=1" # mingw-w64 specific flags for c99 printf
    echo.CXXFLAGS="${CFLAGS}" # copy CFLAGS to CXXFLAGS
    echo.LDFLAGS="${CFLAGS} -static-libgcc" # copy CFLAGS to LDFLAGS
    echo.case "$CC" in
    echo.*clang^)
    echo.    # clang complains about using static-libstdc++ with C files.
    echo.    LDFLAGS+=" --start-no-unused-arguments -static-libstdc++ --end-no-unused-arguments"
    echo.    CFLAGS+=" --start-no-unused-arguments -mthreads --end-no-unused-arguments" # mingw-w64 specific flags for windows threads.
    echo.    CFLAGS+=" -Qunused-arguments" # clang 17.0.1 complains about -mwindows being present during compilation
    echo.;;
    echo.*gcc^)
    echo.    # while gcc doesn't.
    echo.    LDFLAGS+=" -static-libstdc++"
    echo.    CFLAGS+=" -mthreads" # mingw-w64 specific flags for windows threads.
    echo.;;
    echo.esac
    echo.# CPPFLAGS used to be here, but cmake ignores it, so it's not as useful.
    echo.export DXSDK_DIR ACLOCAL_PATH PKG_CONFIG PKG_CONFIG_PATH CFLAGS CXXFLAGS LDFLAGS
    echo.
    echo.export CARGO_HOME="/opt/cargo"
    echo.if [[ -z "$CCACHE_DIR" ]]; then
    echo.    export CCACHE_DIR="${LOCALBUILDDIR}/cache"
    echo.fi
    echo.
    echo.export PYTHONPATH=
    echo.
    echo.LANG=en_US.UTF-8
    echo.PATH="${MINGW_PREFIX}/bin:${INFOPATH}:${MSYS2_PATH}:${ORIGINAL_PATH}"
    echo.PATH="${LOCALDESTDIR}/bin-audio:${LOCALDESTDIR}/bin-global:${LOCALDESTDIR}/bin-video:${LOCALDESTDIR}/bin:${PATH}"
    echo.PATH="/opt/bin:${PATH}"
    echo.source '/etc/profile.d/perlbin.sh'
    echo.PS1='\[\033[32m\]\u@\h \[\e[33m\]\w\[\e[0m\]\n\$ '
    echo.HOME="/home/${USERNAME}"
    echo.GIT_GUI_LIB_DIR=`cygpath -w /usr/share/git-gui/lib`
    echo.export LANG PATH PS1 HOME GIT_GUI_LIB_DIR
    echo.stty susp undef
    echo.test -f "$LOCALDESTDIR/etc/custom_profile" ^&^& source "$LOCALDESTDIR/etc/custom_profile"
)>%instdir%\local%1\etc\profile2.local
%instdir%\msys64\usr\bin\dos2unix -q %instdir%\local%1\etc\profile2.local
goto :EOF

:writeFFmpegOption
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

:writempvOption
setlocal enabledelayedexpansion
for %%i in (%*) do (
    set _opt=%%~i
    if ["!_opt:~0,1!"]==["-"] (
        echo !_opt!
    ) else if ["!_opt:~0,2!"]==["#-"] (
        echo !_opt!
    ) else if ["!_opt:~0,1!"]==["#"] (
        echo #-D!_opt:~1!=enabled
    ) else (
        echo -D!_opt!=enabled
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
    start "bash" /B /LOW /WAIT bash %build%\bash.sh "%build%\%log%" "%command%" "%arg%"
) else (
    if exist %build%\%log% del %build%\%log%
    start /I /LOW /WAIT %instdir%\msys64\usr\bin\mintty.exe -d -i /msys2.ico ^
    -t "media-autobuild_suite" --log 2>&1 %build%\%log% /usr/bin/bash -lc ^
    "%command% %arg%"
)
endlocal
goto :EOF

:getmingw
setlocal
set found=0
if %CC%==clang (
    set "compiler=%instdir%\msys64\clang%1\bin\clang.exe"
) else set "compiler=%instdir%\msys64\mingw%1\bin\gcc.exe"
if exist %compiler% set found=1
if %found%==1 GOTO :EOF
echo.-------------------------------------------------------------------------------
echo.install %1 bit compiler
echo.-------------------------------------------------------------------------------
if %CC%==clang (
    set prefix=mingw-w64-clang-x86_64-
) else (
    if "%1"=="32" (
        set prefix=mingw-w64-i686-
    ) else set prefix=mingw-w64-x86_64-
)
(
    echo.printf '\033]0;install %1 bit compiler\007'
    echo.[[ "$(uname)" = *6.1* ]] ^&^& nargs="-n 4"
    echo.sed 's/^^/%prefix%/g' /etc/pac-mingw.pk ^| xargs $nargs pacman -Sw --noconfirm --ask=20 --needed
    echo.sed 's/^^/%prefix%/g' /etc/pac-mingw.pk ^| xargs $nargs pacman -S --noconfirm --ask=20 --needed
    echo.sleep 3
    echo.exit
)>%build%\mingw.sh
call :runBash mingw%1.log /build/mingw.sh

if exist %compiler% set found=1
if %found%==0 (
    echo -------------------------------------------------------------------------------
    echo.
    echo.MinGW%1 compiler isn't installed; maybe the download didn't work
    echo.Do you want to try it again?
    echo.
    echo -------------------------------------------------------------------------------
    set /P try="try again [y/n]: "

    if [%try%]==[y] GOTO getmingw %1
    exit
)
endlocal
goto :EOF

:resolvePath
set "resolvePath=%~dpnx1"
goto :EOF
