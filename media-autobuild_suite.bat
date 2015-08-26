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
::-------------------------------------------------------------------------------------
::
::  This is version 3.3
::  See HISTORY file for more information
::
::-------------------------------------------------------------------------------------

@echo off
color 80
title media-autobuild_suite

set instdir=%CD%
set "ini=media-autobuild_suite.ini"

set msyspackages=asciidoc autoconf autoconf2.13 automake-wrapper automake1.10 automake1.11 automake1.12 automake1.13 ^
automake1.14 automake1.6 automake1.7 automake1.8 automake1.9 autogen bison diffstat diffutils dos2unix help2man ^
intltool libtool patch python scons xmlto make tar zip unzip git subversion wget p7zip mercurial ruby man-db ^
pkg-config gperf winpty-git

set mingwpackages=boost cmake crt-git dlfcn doxygen gcc gcc-ada gcc-fortran gcc-libgfortran gcc-libs gcc-objc ^
gettext glew gmp gsm headers-git jasper lame lcms2 libcddb libcdio libgpg-error libiconv libjpeg-turbo libmodplug ^
libpng libtiff mpc nasm pcre ragel schroedinger sqlite3 tools-git winpthreads-git xvidcore yasm python2-lxml ninja

set ffmpeg_options=--enable-librtmp --enable-gnutls --enable-frei0r --enable-libbluray --enable-libcaca ^
--enable-libopenjpeg --enable-libass --enable-libgsm --enable-libilbc --enable-libmodplug --enable-libmp3lame ^
--enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libvo-amrwbenc --enable-libschroedinger ^
--enable-libsoxr --enable-libtwolame --enable-libspeex --enable-libtheora --enable-libvorbis ^
--enable-libvo-aacenc --enable-libopus --enable-libvidstab --enable-libxavs --enable-libxvid ^
--enable-libzvbi --enable-libdcadec --enable-libbs2b --enable-libmfx --enable-libcdio --enable-libfreetype ^
--enable-fontconfig --enable-libfribidi --enable-opengl --enable-libvpx --enable-libx264 --enable-libx265 ^
--enable-libkvazaar ^
--enable-libwebp ^
--enable-decklink --enable-libutvideo --enable-libgme ^
--enable-nonfree --enable-nvenc --enable-libfdk-aac --enable-openssl

:selectmsys2Arch
if exist %ini% GOTO checkINI
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Select the msys2 system:
    echo. 1 = 32 bit msys2
    echo. 2 = 64 bit msys2 [recommended]
    echo.
    echo. Choose the same as your operating system.
    echo.
    echo. If you make a mistake, delete the media-autobuild_suite.ini file
    echo. and re-run this file.
    echo.
    echo. These questions should only be asked once.
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P msys2Arch="msys2 system: "
    if %msys2Arch% GTR 2 GOTO selectmsys2Arch

    echo.[compiler list]>%ini%
    echo.msys2Arch=^%msys2Arch%>>%ini%

    set msys2ArchINI=%msys2Arch%
    set archINI=0
    set freeINI=0
    set vpxINI=0
    set x264INI=0
    set x265INI=0
    set other265INI=0
    set flacINI=0
    set mediainfoINI=0
    set soxINI=0
    set ffmpegINI=0
    set ffmpegUpdateINI=0
    set ffmpegChoiceINI=0
    set mp4boxINI=0
    set mplayerINI=0
    set mpvINI=0
    set coresINI=0
    set deleteSourceINI=0
    set stripINI=0
    set packINI=0

    GOTO systemVars

:checkINI
findstr /i "msys2Arch" %ini% > nul
    if ERRORLEVEL 1 del %ini% && GOTO selectmsys2Arch
findstr /i "arch" %ini% > nul
    if ERRORLEVEL 1 del %ini% && GOTO selectmsys2Arch
findstr /i "free" %ini% > nul
    if ERRORLEVEL 1 del %ini% && GOTO selectmsys2Arch
findstr /i "vpx" %ini% > nul
    if ERRORLEVEL 1 del %ini% && GOTO selectmsys2Arch
findstr /i "x264" %ini% > nul
    if ERRORLEVEL 1 del %ini% && GOTO selectmsys2Arch
findstr /i "x265" %ini% > nul
    if ERRORLEVEL 1 del %ini% && GOTO selectmsys2Arch
findstr /i "other265" %ini% > nul
    if ERRORLEVEL 1 del %ini% && GOTO selectmsys2Arch
findstr /i "flac" %ini% > nul
    if ERRORLEVEL 1 del %ini% && GOTO selectmsys2Arch
findstr /i "mediainfo" %ini% > nul
    if ERRORLEVEL 1 del %ini% && GOTO selectmsys2Arch
findstr /i "soxB" %ini% > nul
    if ERRORLEVEL 1 del %ini% && GOTO selectmsys2Arch
findstr /i "ffmpegB" %ini% > nul
    if ERRORLEVEL 1 del %ini% && GOTO selectmsys2Arch
findstr /i "ffmpegUpdate" %ini% > nul
    if ERRORLEVEL 1 del %ini% && GOTO selectmsys2Arch
findstr /i "ffmpegChoice" %ini% > nul
    if ERRORLEVEL 1 del %ini% && GOTO selectmsys2Arch
findstr /i "mp4box" %ini% > nul
    if ERRORLEVEL 1 del %ini% && GOTO selectmsys2Arch
findstr /i "mplayer" %ini% > nul
    if ERRORLEVEL 1 del %ini% && GOTO selectmsys2Arch
findstr /i "mpv" %ini% > nul
    if ERRORLEVEL 1 del %ini% && GOTO selectmsys2Arch
findstr /i "cores" %ini% > nul
    if ERRORLEVEL 1 del %ini% && GOTO selectmsys2Arch
findstr /i "deleteSource" %ini% > nul
    if ERRORLEVEL 1 del %ini% && GOTO selectmsys2Arch
findstr /i "strip" %ini% > nul
    if ERRORLEVEL 1 del %ini% && GOTO selectmsys2Arch
findstr /i "pack" %ini% > nul
    if ERRORLEVEL 1 del %ini% && GOTO selectmsys2Arch

:readINI
for /F "tokens=2 delims==" %%a in ('findstr /i "msys2Arch" %ini%') do set msys2ArchINI=%%a
for /F "tokens=2 delims==" %%j in ('findstr /i "arch" %ini%') do set archINI=%%j
for /F "tokens=2 delims==" %%b in ('findstr /i "free" %ini%') do set freeINI=%%b
for /F "tokens=2 delims==" %%f in ('findstr /i "vpx" %ini%') do set vpxINI=%%f
for /F "tokens=2 delims==" %%f in ('findstr /i "x264" %ini%') do set x264INI=%%f
for /F "tokens=2 delims==" %%f in ('findstr /i "x265" %ini%') do set x265INI=%%f
for /F "tokens=2 delims==" %%f in ('findstr /i "other265" %ini%') do set other265INI=%%f
for /F "tokens=2 delims==" %%f in ('findstr /i "flac" %ini%') do set flacINI=%%f
for /F "tokens=2 delims==" %%f in ('findstr /i "mediainfo" %ini%') do set mediainfoINI=%%f
for /F "tokens=2 delims==" %%f in ('findstr /i "soxB" %ini%') do set soxINI=%%f
for /F "tokens=2 delims==" %%f in ('findstr /i "ffmpegB" %ini%') do set ffmpegINI=%%f
for /F "tokens=2 delims==" %%c in ('findstr /i "ffmpegUpdate" %ini%') do set ffmpegUpdateINI=%%c
for /F "tokens=2 delims==" %%c in ('findstr /i "ffmpegChoice" %ini%') do set ffmpegChoiceINI=%%c
for /F "tokens=2 delims==" %%d in ('findstr /i "mp4box" %ini%') do set mp4boxINI=%%d
for /F "tokens=2 delims==" %%e in ('findstr /i "mplayer" %ini%') do set mplayerINI=%%e
for /F "tokens=2 delims==" %%l in ('findstr /i "mpv" %ini%') do set mpvINI=%%l
for /F "tokens=2 delims==" %%h in ('findstr /i "cores" %ini%') do set coresINI=%%h
for /F "tokens=2 delims==" %%i in ('findstr /i "deleteSource" %ini%') do set deleteSourceINI=%%i
for /F "tokens=2 delims==" %%k in ('findstr /i "strip" %ini%') do set stripINI=%%k
for /F "tokens=2 delims==" %%g in ('findstr /i "pack" %ini%') do set packINI=%%g

:systemVars
set msys2Arch=%msys2ArchINI%
if %msys2Arch%==1 (
    set "msys2=msys32"
    )
if %msys2Arch%==2 (
    set "msys2=msys64"
    )

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
    set "writeArch=yes"
    ) else (
        set buildEnv=%archINI%
        )

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

:selectNonFree
set "writeFree=no"
if %freeINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Include non-free libraries [like fdkaac and faac]?
    echo. 1 = Yes
    echo. 2 = No
    echo. [you will not be able to redistribute binaries including these]
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P nonfree="Non-free binaries: "
    set "writeFree=yes"
    ) else (
        set nonfree=%freeINI%
        )

if %nonfree%==1 (
    set "binary=y"
    )
if %nonfree%==2 (
    set "binary=n"
    )
if %nonfree% GTR 2 GOTO selectNonFree
if %writeFree%==yes echo.free=^%nonfree%>>%ini%

:vpx
set "writevpx=no"
if %vpxINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build vpx [VP8/VP9 encoder] binary?
    echo. 1 = Yes [static]
    echo. 2 = Build library only
    echo. 3 = No
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildvpx="Build vpx: "
    set "writevpx=yes"
    ) else (
        set buildvpx=%vpxINI%
        )

if %buildvpx%==1 (
    set "vpx=y"
    )
if %buildvpx%==2 (
    set "vpx=l"
    )
if %buildvpx%==3 (
    set "vpx=n"
    )
if %buildvpx% GTR 3 GOTO vpx
if %writevpx%==yes echo.vpx=^%buildvpx%>>%ini%

:x264
set "writex264=no"
if %x264INI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build x264 [H.264 encoder] binary?
    echo. 1 = Yes [static]
    echo. 2 = Build library only
    echo. 3 = No
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildx264="Build x264: "
    set "writex264=yes"
    ) else (
        set buildx264=%x264INI%
        )

if %buildx264%==1 (
    set "x264=y"
    )
if %buildx264%==2 (
    set "x264=l"
    )
if %buildx264%==3 (
    set "x264=n"
    )
if %buildx264% GTR 3 GOTO x264
if %writex264%==yes echo.x264=^%buildx264%>>%ini%

:x265
set "writex265=no"
if %x265INI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build x265 [H.265 encoder]?
    echo. 1 = Static x265.exe and library with Main, Main10 and Main12 included
    echo. 2 = Static library only with Main, Main10 and Main12 included
    echo. 3 = No
    echo. 4 = Static x265.exe [Main] and libx265_main10.dll
    echo. 5 = Same as 1 with XP compatibility
    echo. 6 = Same as 2 with XP compatibility
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildx265="Build x265: "
    set "writex265=yes"
    ) else (
        set buildx265=%x265INI%
        )

if %buildx265%==1 (
    set "x265=y"
    )
if %buildx265%==2 (
    set "x265=l"
    )
if %buildx265%==3 (
    set "x265=n"
    )
if %buildx265%==4 (
    set "x265=s"
    )
if %buildx265%==5 (
    set "x265=y"
    set "xpcomp=y"
    )
if %buildx265%==6 (
    set "x265=l"
    set "xpcomp=y"
    )
if %buildx265% GTR 6 GOTO x265
if %writex265%==yes echo.x265=^%buildx265%>>%ini%

:other265
set "writeother265=no"
if %other265INI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build H.265 encoders other than x265?
    echo. 1 = Yes [static]
    echo. 2 = No
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildother265="Build other265: "
    set "writeother265=yes"
    ) else (
        set buildother265=%other265INI%
        )

if %buildother265%==1 (
    set "other265=y"
    )
if %buildother265%==2 (
    set "other265=n"
    )
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
    set "writeflac=yes"
    ) else (
        set buildflac=%flacINI%
        )

if %buildflac%==1 (
    set "flac=y"
    )
if %buildflac%==2 (
    set "flac=n"
    )
if %buildflac% GTR 2 GOTO flac
if %writeflac%==yes echo.flac=^%buildflac%>>%ini%

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
    set "writemediainfo=yes"
    ) else (
        set buildmediainfo=%mediainfoINI%
        )

if %buildmediainfo%==1 (
    set "mediainfo=y"
    )
if %buildmediainfo%==2 (
    set "mediainfo=n"
    )
if %buildmediainfo% GTR 2 GOTO mediainfo
if %writemediainfo%==yes echo.mediainfo=^%buildmediainfo%>>%ini%

:sox
set "writesox=no"
if %soxINI%==0 (
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
    set "writesox=yes"
    ) else (
        set buildsox=%soxINI%
        )

if %buildsox%==1 (
    set "sox=y"
    )
if %buildsox%==2 (
    set "sox=n"
    )
if %buildsox% GTR 2 GOTO sox
if %writesox%==yes echo.soxB=^%buildsox%>>%ini%

:ffmpeg
set "writeFF=no"
if %ffmpegINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Build FFmpeg binary:
    echo. 1 = Yes [static] [recommended]
    echo. 2 = No
    echo. 3 = Shared
    echo. 4 = Both static and shared [shared goes to an isolated directory]
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildffmpeg="Build FFmpeg: "
    set "writeFF=yes"
    ) else (
        set buildffmpeg=%ffmpegINI%
        )

if %buildffmpeg%==1 (
    set "ffmpeg=y"
    )
if %buildffmpeg%==2 (
    set "ffmpeg=n"
    )
if %buildffmpeg%==3 (
    set "ffmpeg=s"
    )
if %buildffmpeg%==4 (
    set "ffmpeg=b"
    )
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
    echo.
    echo. FFmpeg is updated a lot so you only need to select this if you
    echo. absolutely need updated external libraries in FFmpeg.
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildffmpegUp="Build ffmpeg if lib is new: "
    set "writeFFU=yes"
    ) else (
        set buildffmpegUp=%ffmpegUpdateINI%
        )

if %buildffmpegUp%==1 (
    set "ffmpegUpdate=y"
    )
if %buildffmpegUp%==2 (
    set "ffmpegUpdate=n"
    )
if %buildffmpegUp% GTR 2 GOTO ffmpegUp
if %writeFFU%==yes echo.ffmpegUpdate=^%buildffmpegUp%>>%ini%

:ffmpegChoice
set "writeFFC=no"
if %ffmpegChoiceINI%==0 (
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    echo.
    echo. Choose ffmpeg optional libraries?
    echo. 1 = Yes
    echo. 2 = No
    echo.
    echo. If you select yes, we will create a file with the default options
    echo. we use with FFmpeg. You can remove any that you don't need.
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildffmpegChoice="Choose ffmpeg optional libs: "
    set "writeFFC=yes"
    ) else (
        set buildffmpegChoice=%ffmpegChoiceINI%
        )

if %buildffmpegChoice%==1 (
    set "ffmpegChoice=y"
    if not exist "%instdir%\build" ( mkdir "%instdir%/build" )
    if not exist "%instdir%\build\ffmpeg_options.txt" (
        for %%i in (%ffmpeg_options%) do echo.%%i>>"%instdir%\build\ffmpeg_options.txt"
        echo -------------------------------------------------------------------------------
        echo. File with default options has been created in
        echo. %instdir%\build\ffmpeg_options.txt
        echo.
        echo. Edit it now or leave it unedited to compile according to defaults.
        echo -------------------------------------------------------------------------------
        pause
        )
    )
if %buildffmpegChoice%==2 (
    set "ffmpegChoice=n"
    )
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
    set "writeMP4Box=yes"
    ) else (
        set buildMp4box=%mp4boxINI%
        )

if %buildMp4box%==1 (
    set "mp4box=y"
    )
if %buildMp4box%==2 (
    set "mp4box=n"
    )
if %buildMp4box% GTR 2 GOTO mp4boxStatic
if %writeMP4Box%==yes echo.mp4box=^%buildMp4box%>>%ini%

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
    set "writeMPlayer=yes"
    ) else (
        set buildmplayer=%mplayerINI%
        )

if %buildmplayer%==1 (
    set "mplayer=y"
    )
if %buildmplayer%==2 (
    set "mplayer=n"
    )
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
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P buildmpv="Build mpv: "
    set "writeMPV=yes"
    ) else (
        set buildmpv=%mpvINI%
        )

if %buildmpv%==1 (
    set "mpv=y"
    )
if %buildmpv%==2 (
    set "mpv=n"
    )
if %buildmpv% GTR 2 GOTO mpv
if %writeMPV%==yes echo.mpv=^%buildmpv%>>%ini%

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
    set "writeCores=yes"
    ) else (
        set cpuCores=%coresINI%
        )
    for /l %%a in (1,1,%cpuCores%) do (
        set cpuCount=%%a
        )
if "%cpuCount%"=="" GOTO :numCores
if %writeCores%==yes echo.cores=^%cpuCount%>>%ini%

:delete
set "writeDel=no"
if %deleteSourceINI%==0 (
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
    set "writeDel=yes"
    ) else (
        set deleteS=%deleteSourceINI%
    )

if %deleteS%==1 (
    set "deleteSource=y"
    )
if %deleteS%==2 (
    set "deleteSource=n"
    )
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
    set "writeStrip=yes"
    ) else (
        set stripF=%stripINI%
    )

if %stripF%==1 (
    set "stripFile=y"
    )
if %stripF%==2 (
    set "stripFile=n"
    )

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
    echo. Makes binaries a lot smaller at a big time cost after compiling.
    echo.
    echo -------------------------------------------------------------------------------
    echo -------------------------------------------------------------------------------
    set /P packF="Pack files: "
    set "writePack=yes"
    ) else (
        set packF=%packINI%
    )

if %packF%==1 (
    set "packFile=y"
    )
if %packF%==2 (
    set "packFile=n"
    )
if %packF% GTR 2 GOTO packEXE
if %writePack%==yes echo.pack=^%packF%>>%ini%

::------------------------------------------------------------------
::download and install basic msys2 system:
::------------------------------------------------------------------
if exist "%instdir%\%msys2%\usr\bin\wget.exe" GOTO getMintty
    echo -------------------------------------------------------------
    echo.
    echo - Download wget
    echo.
    echo -------------------------------------------------------------
    if exist "%instdir%\build\install-wget.js" del "%instdir%\build\install-wget.js"
    if not exist build mkdir build
    cd build
    if exist "%instdir%\build\msys2-base.tar.xz" GOTO unpack
    
    echo.var wshell = new ActiveXObject("WScript.Shell"); var xmlhttp = new ActiveXObject("MSXML2.ServerXMLHTTP"); var adodb = new ActiveXObject("ADODB.Stream"); var FSO = new ActiveXObject("Scripting.FileSystemObject"); function http_get(url, is_binary) {xmlhttp.open("GET", url); xmlhttp.send(); WScript.echo("retrieving " + url); while (xmlhttp.readyState != 4); WScript.Sleep(10); if (xmlhttp.status != 200) {WScript.Echo("http get failed: " + xmlhttp.status); WScript.Quit(2)}; return is_binary ? xmlhttp.responseBody : xmlhttp.responseText}; function save_binary(path, data) {adodb.type = 1; adodb.open(); adodb.write(data); adodb.saveToFile(path, 2)}; function download_wget() {var base_url = "http://blog.pixelcrusher.de/downloads/media-autobuild_suite/wget.zip"; var filename = "wget.zip"; var installer_data = http_get(base_url, true); save_binary(filename, installer_data); return FSO.GetAbsolutePathName(filename)}; function extract_zip(zip_file, dstdir) {var shell = new ActiveXObject("shell.application"); var dst = shell.NameSpace(dstdir); var zipdir = shell.NameSpace(zip_file); dst.CopyHere(zipdir.items(), 0)}; function install_wget(zip_file) {var rootdir = wshell.CurrentDirectory; extract_zip(zip_file, rootdir)}; install_wget(download_wget())>>install-wget.js

    cscript install-wget.js
    del install-wget.js
    del wget.zip
    del 7zip-license.txt
    del COPYING.txt

:checkmsys2
if %msys2%==msys32 (
if exist "%instdir%\%msys2%\msys2_shell.bat" GOTO getMintty
    echo -------------------------------------------------------------------------------
    echo.
    echo.- Download and install msys2 basic system
    echo.
    echo -------------------------------------------------------------------------------

    for /F %%b in ( '%instdir%\build\wget -qO- http://sourceforge.net/projects/msys2/files/Base/i686/ ^| %instdir%\build\grep -o -P "(?<=tr title=).*(?<=class=)" ^| %instdir%\build\grep -m 1 -o "msys2-base-i686-*.*tar.xz"' ) do %instdir%\build\wget --tries=20 --retry-connrefused --waitretry=2 -c -O msys2-base.tar.xz http://sourceforge.net/projects/msys2/files/Base/i686/%%b/download
    )

if %msys2%==msys64 (
if exist "%instdir%\%msys2%\msys2_shell.bat" GOTO getMintty
    echo -------------------------------------------------------------------------------
    echo.
    echo.- Download and install msys2 basic system
    echo.
    echo -------------------------------------------------------------------------------

    for /F %%b in ( '%instdir%\build\wget -qO- http://sourceforge.net/projects/msys2/files/Base/x86_64/ ^| %instdir%\build\grep -o -P "(?<=tr title=).*(?<=class=)" ^| %instdir%\build\grep -m 1 -o "msys2-base-x86_64-*.*tar.xz"' ) do %instdir%\build\wget --tries=20 --retry-connrefused --waitretry=2 -c -O msys2-base.tar.xz http://sourceforge.net/projects/msys2/files/Base/x86_64/%%b/download
    )
    
:unpack
if exist "%instdir%\build\msys2-base.tar.xz" (
    %instdir%\build\7za.exe x msys2-base.tar.xz -so | %instdir%\build\7za.exe x -aoa -si -ttar -o..
    del %instdir%\build\msys2-base.tar.xz
    del %instdir%\build\grep.exe
    del %instdir%\build\wget.exe
    del %instdir%\build\7za.exe
    )
    
if not exist %instdir%\%msys2%\usr\bin\msys-2.0.dll (
    echo -------------------------------------------------------------------------------
    echo.
    echo.- Download msys2 basic system failed,
    echo.- please download it manuel from:
    echo.- http://downloads.sourceforge.net/project/msys2
    echo.- and copy the uncompressed folder to:
    echo.- %instdir%\build
    echo.- and start the batch script again!
    echo.
    echo -------------------------------------------------------------------------------
    pause
    GOTO unpack
    )

:getMintty
if not exist %instdir%\mintty.lnk (
    echo -------------------------------------------------------------------------------
    echo.
    echo.- make a first run
    echo.
    echo -------------------------------------------------------------------------------

    echo.sleep ^4>>firstrun.sh
    echo.exit>>firstrun.sh
    %instdir%\%msys2%\usr\bin\mintty.exe -i /msys2.ico /usr/bin/bash --login %instdir%\firstrun.sh
    del firstrun.sh

    echo.-------------------------------------------------------------------------------
    echo.first update
    echo.-------------------------------------------------------------------------------
    if exist %instdir%\firstUpdate.sh del %instdir%\firstUpdate.sh
    (
        echo.echo -ne "\033]0;first msys2 update\007"
        echo.pacman --noconfirm --force -Sy --asdeps pacman-mirrors
        echo.sleep ^4
        echo.exit
        )>>%instdir%\firstUpdate.sh
    %instdir%\%msys2%\usr\bin\mintty.exe -i /msys2.ico /usr/bin/bash --login %instdir%\firstUpdate.sh
    del %instdir%\firstUpdate.sh

    echo.-------------------------------------------------------------------------------
    echo.second update
    echo.-------------------------------------------------------------------------------
    if exist %instdir%\secondUpdate.sh del %instdir%\secondUpdate.sh
    (
        echo.echo -ne "\033]0;second msys2 update\007"
        echo.pacman --noconfirm -Syu --force --asdeps --ignoregroup base
        echo.pacman --noconfirm -Su --force --asdeps
        echo.exit
        )>>%instdir%\secondUpdate.sh
    %instdir%\%msys2%\usr\bin\mintty.exe -i /msys2.ico /usr/bin/bash --login %instdir%\secondUpdate.sh
    cls
    del %instdir%\secondUpdate.sh

    (
        echo.Set Shell = CreateObject^("WScript.Shell"^)
        echo.Set link = Shell.CreateShortcut^("%instdir%\mintty.lnk"^)
        echo.link.Arguments = "-i /msys2.ico /usr/bin/bash --login"
        echo.link.Description = "msys2 shell console"
        echo.link.TargetPath = "%instdir%\%msys2%\usr\bin\mintty.exe"
        echo.link.WindowStyle = ^1
        echo.link.IconLocation = "%instdir%\%msys2%\msys2.ico"
        echo.link.WorkingDirectory = "%instdir%\%msys2%\usr\bin"
        echo.link.Save
        )>>%instdir%\setlink.vbs
    cscript /nologo %instdir%\setlink.vbs
    del %instdir%\setlink.vbs
        )
    if exist %instdir%\%msys2%\home\%USERNAME%\.minttyrc GOTO hgsettings
    if not exist %instdir%\%msys2%\home\%USERNAME% mkdir %instdir%\%msys2%\home\%USERNAME%
        (
            echo.BoldAsFont=no
            echo.BackgroundColour=57,57,57
            echo.ForegroundColour=221,221,221
            echo.Transparency=medium
            echo.FontHeight=^9
            echo.FontSmoothing=full
            echo.AllowBlinking=yes
            echo.Font=DejaVu Sans Mono
            echo.Columns=120
            echo.Rows=30
            echo.Term=xterm-256color
            echo.CursorType=block
            echo.ClicksPlaceCursor=yes
            echo.Black=38,39,41
            echo.Red=249,38,113
            echo.Green=166,226,46
            echo.Yellow=253,151,31
            echo.Blue=102,217,239
            echo.Magenta=158,111,254
            echo.Cyan=94,113,117
            echo.White=248,248,242
            echo.BoldBlack=85,68,68
            echo.BoldRed=249,38,113
            echo.BoldGreen=166,226,46
            echo.BoldYellow=253,151,31
            echo.BoldBlue=102,217,239
            echo.BoldMagenta=158,111,254
            echo.BoldCyan=163,186,191
            echo.BoldWhite=248,248,242
            )>>%instdir%\%msys2%\home\%USERNAME%\.minttyrc

:hgsettings
if exist %instdir%\%msys2%\home\%USERNAME%\.hgrc GOTO gitsettings
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
        )>>%instdir%\%msys2%\home\%USERNAME%\.hgrc

:gitsettings
if exist %instdir%\%msys2%\home\%USERNAME%\.gitconfig GOTO rebase
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
        )>>%instdir%\%msys2%\home\%USERNAME%\.gitconfig

:rebase
if %msys2%==msys32 (
    echo.-------------------------------------------------------------------------------
    echo.rebase msys32 system
    echo.-------------------------------------------------------------------------------
    call %instdir%\msys32\autorebase.bat
    )

:installbase
if exist "%instdir%\%msys2%\etc\pac-base.pk" del "%instdir%\%msys2%\etc\pac-base.pk"
for %%i in (%msyspackages%) do echo.%%i>>%instdir%\%msys2%\etc\pac-base.pk

if exist %instdir%\%msys2%\usr\bin\make.exe GOTO sethgBat
    echo.-------------------------------------------------------------------------------
    echo.install msys2 base system
    echo.-------------------------------------------------------------------------------
    if exist %instdir%\pacman.sh del %instdir%\pacman.sh
    (
    echo.echo -ne "\033]0;install base system\007"
    echo.pacman --noconfirm -S $(cat /etc/pac-base.pk ^| sed -e 's#\\##'^)
    echo.sleep ^3
    echo.exit
        )>>%instdir%\pacman.sh
    %instdir%\%msys2%\usr\bin\mintty.exe -i /msys2.ico /usr/bin/bash --login %instdir%\pacman.sh
    del %instdir%\pacman.sh

    for %%i in (%instdir%\%msys2%\usr\ssl\cert.pem) do (
        if %%~zi==0 (
            echo.update-ca-trust>>cert.sh
            echo.sleep ^3>>cert.sh
            echo.exit>>cert.sh
            %instdir%\%msys2%\usr\bin\mintty.exe -i /msys2.ico /usr/bin/bash --login %instdir%\cert.sh
            del cert.sh
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
if %build32%==yes (
if exist "%instdir%\%msys2%\etc\pac-mingw32.pk" del "%instdir%\%msys2%\etc\pac-mingw32.pk"
for %%i in (%mingwpackages%) do echo.mingw-w64-i686-%%i>>%instdir%\%msys2%\etc\pac-mingw32.pk

:tryagain32
if exist %instdir%\%msys2%\mingw32\bin\gcc.exe GOTO getmingw64
    echo.-------------------------------------------------------------------------------
    echo.install 32 bit compiler
    echo.-------------------------------------------------------------------------------
    if exist %instdir%\mingw32.sh del %instdir%\mingw32.sh
    (
        echo.echo -ne "\033]0;install 32 bit compiler\007"
        echo.pacman --noconfirm -S $(cat /etc/pac-mingw32.pk ^| sed -e 's#\\##'^)
        echo.sleep ^3
        echo.exit
        )>>%instdir%\mingw32.sh
    %instdir%\%msys2%\usr\bin\mintty.exe -i /msys2.ico /usr/bin/bash --login %instdir%\mingw32.sh
    del %instdir%\mingw32.sh
    )
    
if not exist %instdir%\%msys2%\mingw32\bin\gcc.exe (
    echo -------------------------------------------------------------------------------
    echo.
    echo.mingw32 where not install, maybe the download has not work
    echo.do you want to try it again?
    echo.
    echo -------------------------------------------------------------------------------
    set /P try32="try again [y/n]: "

    if %packF%==y (
        GOTO tryagain32
        ) else exit
    )
    
:getmingw64
if %build64%==yes (
if exist "%instdir%\%msys2%\etc\pac-mingw64.pk" del "%instdir%\%msys2%\etc\pac-mingw64.pk"
for %%i in (%mingwpackages%) do echo.mingw-w64-x86_64-%%i>>%instdir%\%msys2%\etc\pac-mingw64.pk

:tryagain64
if exist %instdir%\%msys2%\mingw64\bin\gcc.exe GOTO updatebase
    echo.-------------------------------------------------------------------------------
    echo.install 64 bit compiler
    echo.-------------------------------------------------------------------------------
    if exist %instdir%\mingw64.sh del %instdir%\mingw64.sh
        (
        echo.echo -ne "\033]0;install 64 bit compiler\007"
        echo.pacman --noconfirm -S $(cat /etc/pac-mingw64.pk ^| sed -e 's#\\##'^)
        echo.sleep ^3
        echo.exit
        )>>%instdir%\mingw64.sh
    %instdir%\%msys2%\usr\bin\mintty.exe -i /msys2.ico /usr/bin/bash --login %instdir%\mingw64.sh
    del %instdir%\mingw64.sh
    )

if not exist %instdir%\%msys2%\mingw64\bin\gcc.exe (
    echo -------------------------------------------------------------------------------
    echo.
    echo.mingw64 where not install, maybe the download has not work
    echo.do you want to try it again?
    echo.
    echo -------------------------------------------------------------------------------
    set /P try64="try again [y/n]: "

    if %packF%==y (
        GOTO tryagain64
        ) else exit
    )
    
:updatebase
echo.-------------------------------------------------------------------------------
echo.update autobuild suite
echo.-------------------------------------------------------------------------------

%instdir%\%msys2%\usr\bin\mintty.exe -i /msys2.ico /usr/bin/bash --login %instdir%\media-suite_update.sh ^
--build32=%build32% --build64=%build64% --remove=%deleteSource%
cls

:rebase2
if %msys2%==msys32 (
    echo.-------------------------------------------------------------------------------
    echo.second rebase msys32 system
    echo.-------------------------------------------------------------------------------
    call %instdir%\msys32\autorebase.bat
    )

:checkdyn
echo.-------------------------------------------------------------------------------
echo.check for dynamic libs
echo.-------------------------------------------------------------------------------

Setlocal EnableDelayedExpansion

if %build32%==yes (
if exist %instdir%\%msys2%\mingw32\lib\xvidcore.dll.a (
    del %instdir%\%msys2%\mingw32\bin\xvidcore.dll
    %instdir%\%msys2%\usr\bin\mv %instdir%\%msys2%\mingw32\lib\xvidcore.a %instdir%\%msys2%\mingw32\lib\libxvidcore.a
    %instdir%\%msys2%\usr\bin\mv %instdir%\%msys2%\mingw32\lib\xvidcore.dll.a %instdir%\%msys2%\mingw32\lib\xvidcore.dll.a.dyn
    )

    FOR /R "%instdir%\%msys2%\mingw32" %%C IN (*.dll.a) DO (
        set file=%%C
        set name=!file:~0,-6!
        if exist %%C.dyn del %%C.dyn
        if exist !name!.a (
            %instdir%\%msys2%\usr\bin\mv %%C %%C.dyn
            )
        )
    )

if %build64%==yes (
if exist %instdir%\%msys2%\mingw64\lib\xvidcore.dll.a (
    del %instdir%\%msys2%\mingw64\bin\xvidcore.dll
    %instdir%\%msys2%\usr\bin\mv %instdir%\%msys2%\mingw64\lib\xvidcore.a %instdir%\%msys2%\mingw64\lib\libxvidcore.a
    %instdir%\%msys2%\usr\bin\mv %instdir%\%msys2%\mingw64\lib\xvidcore.dll.a %instdir%\%msys2%\mingw64\lib\xvidcore.dll.a.dyn
    )

    FOR /R "%instdir%\%msys2%\mingw64" %%C IN (*.dll.a) DO (
        set file=%%C
        set name=!file:~0,-6!
        if exist %%C.dyn del %%C.dyn
        if exist !name!.a (
            %instdir%\%msys2%\usr\bin\mv %%C %%C.dyn
            )
        )
    )

Setlocal DisableDelayedExpansion

if %build32%==yes (
    if not exist %instdir%\build mkdir %instdir%\build
    if not exist %instdir%\local32\share (
        echo.-------------------------------------------------------------------------------
        echo.create local32 folders
        echo.-------------------------------------------------------------------------------
        mkdir %instdir%\local32
        mkdir %instdir%\local32\bin
        mkdir %instdir%\local32\bin-audio
        mkdir %instdir%\local32\bin-global
        mkdir %instdir%\local32\bin-video
        mkdir %instdir%\local32\etc
        mkdir %instdir%\local32\include
        mkdir %instdir%\local32\lib
        mkdir %instdir%\local32\lib\pkgconfig
        mkdir %instdir%\local32\share
        )
    )

if %build64%==yes (
    if not exist %instdir%\build mkdir %instdir%\build
    if not exist %instdir%\local64\share (
        echo.-------------------------------------------------------------------------------
        echo.create local64 folders
        echo.-------------------------------------------------------------------------------
        mkdir %instdir%\local64
        mkdir %instdir%\local64\bin
        mkdir %instdir%\local64\bin-audio
        mkdir %instdir%\local64\bin-global
        mkdir %instdir%\local64\bin-video
        mkdir %instdir%\local64\etc
        mkdir %instdir%\local64\include
        mkdir %instdir%\local64\lib
        mkdir %instdir%\local64\lib\pkgconfig
        mkdir %instdir%\local64\share
        )
    )

if %build32%==yes (
    set searchStr=local32
    ) else (
        set searchStr=local64
        )

if not exist %instdir%\%msys2%\etc\fstab. GOTO writeFstab

for /f "tokens=2 delims=/" %%b in ('findstr /i build32 %instdir%\%msys2%\etc\fstab.') do set searchRes=oldbuild

if "%searchRes%"=="oldbuild" (
    del %instdir%\%msys2%\etc\fstab.
    GOTO writeFstab
    )

for /f "tokens=2 delims=/" %%a in ('findstr /i %searchStr% %instdir%\%msys2%\etc\fstab.') do set searchRes=%%a

if "%searchRes%"=="local32" GOTO writeProfile32
if "%searchRes%"=="local64" GOTO writeProfile32

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
        echo.%instdir%\local32\ /local32
        echo.%instdir%\build\ /build
        echo.%instdir%\%msys2%\mingw32\ /mingw32
        echo.%instdir%\local64\ /local64
        echo.%instdir%\%msys2%\mingw64\ /mingw64
        )>>%instdir%\%msys2%\etc\fstab.

::------------------------------------------------------------------
:: write config profiles:
::------------------------------------------------------------------

:writeProfile32
if %build32%==yes (
    if exist %instdir%\local32\etc\profile.local GOTO writeProfile64
        echo -------------------------------------------------------------------------------
        echo.
        echo.- write profile for 32 bit compiling
        echo.
        echo -------------------------------------------------------------------------------
        (
            echo.#
            echo.# /local32/etc/profile.local
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
            echo.MINGW_PREFIX="/mingw32"
            echo.MINGW_CHOST="i686-w64-mingw32"
            echo.
            echo.# rest is the same in both profiles
            echo.targetBuild="${MINGW_CHOST}"
            echo.targetHost="${MINGW_CHOST}"
            echo.cross="${MINGW_CHOST}-"
            echo.alias dir='ls -la --color=auto'
            echo.alias ls='ls --color=auto'
            echo.export CC=gcc
            echo.export python=/usr/bin/python
            echo.
            echo.MSYS2_PATH="/usr/local/bin:/usr/bin"
            echo.MANPATH="/usr/share/man:${MINGW_PREFIX}/share/man:${LOCALDESTDIR}/man:${LOCALDESTDIR}/share/man"
            echo.INFOPATH="/usr/local/info:/usr/share/info:/usr/info:${MINGW_PREFIX}/share/info"
            echo.
            echo.DXSDK_DIR="${MINGW_PREFIX}/${MINGW_CHOST}"
            echo.ACLOCAL_PATH="${MINGW_PREFIX}/share/aclocal:/usr/share/aclocal"
            echo.PKG_CONFIG_PATH="${LOCALDESTDIR}/lib/pkgconfig:${MINGW_PREFIX}/lib/pkgconfig"
            echo.CPPFLAGS="-I${LOCALDESTDIR}/include -D_FORTIFY_SOURCE=2 -D__USE_MINGW_ANSI_STDIO=1"
            echo.CFLAGS="-I${LOCALDESTDIR}/include -mthreads -mtune=generic -O2 -pipe"
            echo.CXXFLAGS="${CFLAGS}"
            echo.LDFLAGS="-L${LOCALDESTDIR}/lib -pipe"
            echo.export DXSDK_DIR ACLOCAL_PATH PKG_CONFIG_PATH CPPFLAGS CFLAGS CXXFLAGS LDFLAGS MSYSTEM
            echo.
            echo.PYTHONHOME=/usr
            echo.PYTHONPATH="/usr/lib/python2.7:/usr/lib/python2.7/Tools/Scripts"
            echo.
            echo.PATH=".:${LOCALDESTDIR}/bin-audio:${LOCALDESTDIR}/bin-global:${LOCALDESTDIR}/bin-video:${LOCALDESTDIR}/bin:${MINGW_PREFIX}/bin:${MSYS2_PATH}:${INFOPATH}:${PYTHONHOME}:${PYTHONPATH}:${PATH}"
            echo.PS1='\[\033[32m\]\u@\h \[\e[33m\]\w\[\e[0m\]\n\$ '
            echo.HOME="/home/${USERNAME}"
            echo.GIT_GUI_LIB_DIR=`cygpath -w /usr/share/git-gui/lib`
            echo.export PATH PS1 HOME GIT_GUI_LIB_DIR
            )>>%instdir%\local32\etc\profile.local
        )

:writeProfile64
if %build64%==yes (
    if exist %instdir%\local64\etc\profile.local GOTO loginProfile
        echo -------------------------------------------------------------------------------
        echo.
        echo.- write profile for 64 bit compiling
        echo.
        echo -------------------------------------------------------------------------------
        (
            echo.#
            echo.# /local64/etc/profile.local
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
            echo.MINGW_PREFIX="/mingw64"
            echo.MINGW_CHOST="x86_64-w64-mingw32"
            echo.
            echo.# rest is the same in both profiles
            echo.targetBuild="${MINGW_CHOST}"
            echo.targetHost="${MINGW_CHOST}"
            echo.cross="${MINGW_CHOST}-"
            echo.alias dir='ls -la --color=auto'
            echo.alias ls='ls --color=auto'
            echo.export CC=gcc
            echo.export python=/usr/bin/python
            echo.
            echo.MSYS2_PATH="/usr/local/bin:/usr/bin"
            echo.MANPATH="/usr/share/man:${MINGW_PREFIX}/share/man:${LOCALDESTDIR}/man:${LOCALDESTDIR}/share/man"
            echo.INFOPATH="/usr/local/info:/usr/share/info:/usr/info:${MINGW_PREFIX}/share/info"
            echo.
            echo.DXSDK_DIR="${MINGW_PREFIX}/${MINGW_CHOST}"
            echo.ACLOCAL_PATH="${MINGW_PREFIX}/share/aclocal:/usr/share/aclocal"
            echo.PKG_CONFIG_PATH="${LOCALDESTDIR}/lib/pkgconfig:${MINGW_PREFIX}/lib/pkgconfig"
            echo.CPPFLAGS="-I${LOCALDESTDIR}/include -D_FORTIFY_SOURCE=2 -D__USE_MINGW_ANSI_STDIO=1"
            echo.CFLAGS="-I${LOCALDESTDIR}/include -mthreads -mtune=generic -O2 -pipe"
            echo.CXXFLAGS="${CFLAGS}"
            echo.LDFLAGS="-L${LOCALDESTDIR}/lib -pipe"
            echo.export DXSDK_DIR ACLOCAL_PATH PKG_CONFIG_PATH CPPFLAGS CFLAGS CXXFLAGS LDFLAGS MSYSTEM
            echo.
            echo.PYTHONHOME=/usr
            echo.PYTHONPATH="/usr/lib/python2.7:/usr/lib/python2.7/Tools/Scripts"
            echo.
            echo.PATH=".:${LOCALDESTDIR}/bin-audio:${LOCALDESTDIR}/bin-global:${LOCALDESTDIR}/bin-video:${LOCALDESTDIR}/bin:${MINGW_PREFIX}/bin:${MSYS2_PATH}:${INFOPATH}:${PYTHONHOME}:${PYTHONPATH}:${PATH}"
            echo.PS1='\[\033[32m\]\u@\h \[\e[33m\]\w\[\e[0m\]\n\$ '
            echo.HOME="/home/${USERNAME}"
            echo.GIT_GUI_LIB_DIR=`cygpath -w /usr/share/git-gui/lib`
            echo.export PATH PS1 HOME GIT_GUI_LIB_DIR
            )>>%instdir%\local64\etc\profile.local
        )

:loginProfile
if %build32%==no GOTO loginProfile64
    %instdir%\%msys2%\usr\bin\grep -q -e 'profile.local' %instdir%\%msys2%\etc\profile || (
        echo -------------------------------------------------------------------------------
        echo.
        echo.- write default profile [32 bit]
        echo.
        echo -------------------------------------------------------------------------------
        (
            echo.
            echo.if [[ -z "$MSYSTEM" ^&^& -f /local32/etc/profile.local ]]; then
            echo.       source /local32/etc/profile.local
            echo.fi
            )>>%instdir%\%msys2%\etc\profile.
    )

    GOTO compileLocals

:loginProfile64
    %instdir%\%msys2%\usr\bin\grep -q -e 'profile.local' %instdir%\%msys2%\etc\profile || (
        echo -------------------------------------------------------------------------------
        echo.
        echo.- write default profile [64 bit]
        echo.
        echo -------------------------------------------------------------------------------
        (
            echo.
            echo.if [[ -z "$MSYSTEM" ^&^& -f /local64/etc/profile.local ]]; then
            echo.       source /local64/etc/profile.local
            echo.fi
            )>>%instdir%\%msys2%\etc\profile.
    )

:compileLocals
cd %instdir%
IF ERRORLEVEL == 1 (
    ECHO Something goes wrong...
    pause
  )

start %instdir%\%msys2%\usr\bin\mintty.exe -i /msys2.ico /usr/bin/bash --login %instdir%\media-suite_compile.sh ^
--cpuCount=%cpuCount% --build32=%build32% --build64=%build64% --deleteSource=%deleteSource% --mp4box=%mp4box% ^
--vpx=%vpx% --x264=%x264% --x265=%x265% --other265=%other265% --flac=%flac% --mediainfo=%mediainfo% ^
--sox=%sox% --ffmpeg=%ffmpeg% --ffmpegUpdate=%ffmpegUpdate% --ffmpegChoice=%ffmpegChoice% --mplayer=%mplayer% ^
--mpv=%mpv% --nonfree=%binary%  --stripping=%stripFile% --packing=%packFile% --xpcomp=%xpcomp%

exit
