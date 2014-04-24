::-------------------------------------------------------------------------------------
:: LICENSE -------------------------------------------------------------------------
::-------------------------------------------------------------------------------------
::	This Windows Batchscript is for setup a compiler environment for building ffmpeg and other media tools under Windows.
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

::-------------------------------------------------------------------------------------
:: History ---------------------------------------------------------------------------
::-------------------------------------------------------------------------------------
::
::	This is version 1.7
::	Project stared at 2013-09-24. Last bigger modification was on 2014-4-21
::	2013-09-29 add ffmpeg, rtmp and other tools
::	2013-09-30 reorder code and some small things
::	2013-10-01 change pkg-config, add mp4box, and reorder code
::	2013-10-03 add libs (faac, and some others) and change ffmpeg download to github
::	2013-10-06 build the environment new and remove openssl and rtmp
::	2013-10-08 add libopus and libvpx (thanks to hoary)
::	2013-10-10 add libass and add build check to the shell scripts
::	2013-10-13 add libbluray, openjpeg and finally librtmp to ffmpeg
::	2013-10-14 add utvideo to ffmpeg and change profile parameter to static
::	2013-10-19 add xavs and opus-tools, update svn and opus version
::	2013-10-22 some fixes and add mplayer (maybe not the best way)
::	2013-11-05 update libbluray, fontconfig, add libxml2 and add update function to ffmpeg
::	2013-11-06 add openexr, jpeg2000 and imagemagick
::	2013-11-11 add updater for ffmpeg, x264, vpx and libbluray
::	2013-11-12 add info to the window title, make all mingw libs static, add jpegturbo, openexr and imagemagick for 64 bit
::	2013-11-18 add gettext, dvdcss, dvdread, dvdnav, qt4, vlc and reorder code.
::	2013-11-19 add a52dec, libmad, and libmpeg2 and sdl_image
::	2013-11-24 change compiler version to 4.8.2 and start to simplify code
::	2013-11-26 add x265
::	2013-11-27 add function for write settings to ini-file, change downloads from extra packs, finish simplify scripts and mediainfo cli (only 32 bit)
::	2013-11-29 add vidstab, libtwolame, soxr, libilbc, schroedinger, orc
::	2013-11-30 add exiv2
::	2013-12-04 add libcaca
::	2013-12-05 simplify code - now we only need one *.sh file for 32bit and 64bit compiling. (More edit and add features friendly)
::	2013-12-08 little fixes, fix libjpeg and libjasper, patch imagemagick, fix libass for mplayer, patchfiles to local, add libmodplug and libzvbi
::	2013-12-09 add frei0r and some fixes 
::	2013-12-10 add sox
::	2013-12-14 change compiler to rev.1
::	2014-01-13 change compiler to rev.2 and fix check
::	2014-02-02 add global32 and global64 folders to the environment. Make it more easy to build some part of tools new
::	2014-02-18 remove vlc, qt4 and imagetools, change mplayer to svn with update function
::	2014-03-02 change libpng link, add x265 to ffmpeg, new mediainfo version and some fixes
::	2014-03-23 change compiler to rev.3
::	2014-03-25 add python to the opt tools, add wavpack, libsndfile and new sox with libsndfile included 
::	2014-04-02 fix x264 10bit exe and change shell to utf-8, update svn; cmake; git; doxygen and add pdflatex
::	2014-04-04 add strip files to main batch
::	2014-04-08 ask for x265 in ffmpeg
::	2014-04-21 start to changing msys1 to msys2
::	2014-04-22 lang. detect for mintty
::	2014-04-24 add tools, update mediainfo version, start to change the compilers to native msys2 mingw-w64
::
::-------------------------------------------------------------------------------------

@echo off
color 80
title media-autobuild_suite

set instdir=%CD%
set "ini=media-autobuild_suite.ini"

if not exist %ini% (
	echo.[compiler list]>>%ini%
	echo.arch=^0>>%ini%
	echo.free=^0>>%ini%
	echo.ffmpeg=^0>>%ini%
	echo.mp4box=^0>>%ini%
	echo.mplayer=^0>>%ini%
	echo.cores=^0>>%ini%
	echo.deleteSource=^0>>%ini%
	echo.strip=^0>>%ini%
	)

for /F "tokens=2 delims==" %%a in ('findstr /i arch %ini%') do set archINI=%%a
for /F "tokens=2 delims==" %%b in ('findstr /i free %ini%') do set freeINI=%%b
for /F "tokens=2 delims==" %%c in ('findstr /i ffmpeg %ini%') do set ffmpegINI=%%c
for /F "tokens=2 delims==" %%d in ('findstr /i mp4box %ini%') do set mp4boxINI=%%d
for /F "tokens=2 delims==" %%e in ('findstr /i mplayer %ini%') do set mplayerINI=%%e
for /F "tokens=2 delims==" %%h in ('findstr /i cores %ini%') do set coresINI=%%h
for /F "tokens=2 delims==" %%i in ('findstr /i deleteSource %ini%') do set deleteSourceINI=%%i
for /F "tokens=2 delims==" %%i in ('findstr /i strip %ini%') do set stripINI=%%i

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
	set /P buildEnv="Build System:"
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
if %buildEnv% GTR 3 GOTO :selectSystem

:selectNonFree
if %freeINI%==0 (
	echo -------------------------------------------------------------------------------
	echo -------------------------------------------------------------------------------
	echo.
	echo. Build nonfree binaries [like fdkaac], is not allow to distribute them:
	echo. 1 = nonfree binaries
	echo. 2 = free binaries
	echo.
	echo -------------------------------------------------------------------------------
	echo -------------------------------------------------------------------------------
	set /P nonfree="Binaries:"
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

:ffmpeg
if %ffmpegINI%==0 (
	echo -------------------------------------------------------------------------------
	echo -------------------------------------------------------------------------------
	echo.
	echo. Build static ffmpeg binary:
	echo. 1 = yes
	echo. 2 = no
	echo. 3 = with x265 [experimental]
	echo.
	echo -------------------------------------------------------------------------------
	echo -------------------------------------------------------------------------------
	set /P buildffmpeg="build ffmpeg:"
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
	set "ffmpeg=w"
	)
if %buildffmpeg% GTR 3 GOTO ffmpeg

:mp4boxStatic
if %mp4boxINI%==0 (
	echo -------------------------------------------------------------------------------
	echo -------------------------------------------------------------------------------
	echo.
	echo. Build static mp4box binary:
	echo. 1 = yes
	echo. 2 = no
	echo.
	echo -------------------------------------------------------------------------------
	echo -------------------------------------------------------------------------------
	set /P buildMp4box="build mp4box:"
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

:mplayer
if %mplayerINI%==0 (
	echo -------------------------------------------------------------------------------
	echo -------------------------------------------------------------------------------
	echo.
	echo. Build static mplayer/mencoder binary:
	echo. 1 = yes
	echo. 2 = no
	echo.
	echo -------------------------------------------------------------------------------
	echo -------------------------------------------------------------------------------
	set /P buildmplayer="build mplayer:"
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

:numCores
if %coresINI%==0 (
	echo -------------------------------------------------------------------------------
	echo -------------------------------------------------------------------------------
	echo.
	echo. Number of CPU Cores/Threads for compiling:
	echo. [it is non-recommended to use all cores/threads!]
	echo.
	echo -------------------------------------------------------------------------------
	echo -------------------------------------------------------------------------------
	set /P cpuCores="Core/Thread Count:"
	echo -------------------------------------------------------------------------------
	) else ( 
		set cpuCores=%coresINI%
		)
	for /l %%a in (1,1,%cpuCores%) do (
		set cpuCount=%%a
		)
if "%cpuCount%"=="" GOTO :numCores

:delete
if %deleteSourceINI%==0 (
	echo -------------------------------------------------------------------------------
	echo -------------------------------------------------------------------------------
	echo.
	echo. delete source folders, after compile is done:
	echo. 1 = yes
	echo. 2 = no
	echo.
	echo -------------------------------------------------------------------------------
	echo -------------------------------------------------------------------------------
	set /P deleteS="delete source:"
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

:stripEXE
if %stripINI%==0 (
	echo -------------------------------------------------------------------------------
	echo -------------------------------------------------------------------------------
	echo.
	echo. strip compiled files:
	echo. 1 = yes
	echo. 2 = no
	echo.
	echo -------------------------------------------------------------------------------
	echo -------------------------------------------------------------------------------
	set /P stripF="strip files:"
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

::------------------------------------------------------------------
::download and install basic msys system:
::------------------------------------------------------------------

if exist "%instdir%\opt" GOTO check7zip
	echo -------------------------------------------------------------
	echo.
	echo - Download wget
	echo.
	echo -------------------------------------------------------------
	if exist "%instdir%\install-wget" del "%instdir%\install-wget.js"
	
	echo.var wshell = new ActiveXObject("WScript.Shell"); var htmldoc = new ActiveXObject("htmlfile"); var xmlhttp = new ActiveXObject("MSXML2.ServerXMLHTTP"); var adodb = new ActiveXObject("ADODB.Stream"); var FSO = new ActiveXObject("Scripting.FileSystemObject"); function http_get(url, is_binary) {xmlhttp.open("GET", url); xmlhttp.send(); WScript.echo("retrieving " + url); while (xmlhttp.readyState != 4); WScript.Sleep(100); if (xmlhttp.status != 200) {WScript.Echo("http get failed: " + xmlhttp.status); WScript.Quit(2)}; return is_binary ? xmlhttp.responseBody : xmlhttp.responseText}; function save_binary(path, data) {adodb.type = 1; adodb.open(); adodb.write(data); adodb.saveToFile(path, 2)}; function download_wget() {var base_url = "http://blog.pixelcrusher.de/downloads/media_compressor/wget.zip"; html = http_get(base_url, false); htmldoc.open(); htmldoc.write(html); var div = htmldoc.getElementById("downloading"); var filename = "wget.zip"; var installer_data = http_get(base_url, true); save_binary(filename, installer_data); return FSO.GetAbsolutePathName(filename)}; function extract_zip(zip_file, dstdir) {var shell = new ActiveXObject("shell.application"); var dst = shell.NameSpace(dstdir); var zipdir = shell.NameSpace(zip_file); dst.CopyHere(zipdir.items(), 0)}; function install_wget(zip_file) {var rootdir = wshell.CurrentDirectory; extract_zip(zip_file, rootdir)}; install_wget(download_wget())>>"%instdir%\install-wget.js"

	cscript "%instdir%\install-wget.js"
	del "%instdir%\install-wget.js"
	del "%instdir%\wget.zip"
	rmdir /s /q help
	rmdir /s /q license
	rmdir /s /q readme
	
:check7zip
if exist "%instdir%\opt\bin\7za.exe" GOTO checkmsys2
	echo -------------------------------------------------------------
	echo.
	echo - Download and install 7zip
	echo.
	echo.
	echo -------------------------------------------------------------
	"%instdir%\wget" -P "%instdir%" "http://blog.pixelcrusher.de/downloads/media_compressor/7za920.exe"
	
	7za920.exe
	
	del "%instdir%\7za920.exe"
	mkdir opt
	cd opt
	mkdir bin
	mkdir doc
	cd doc
	mkdir 7za920
	cd %instdir%
	
	move 7zip-license.txt opt\doc\7za920
	move 7zip-readme.txt opt\doc\7za920
	move 7-zip.chm opt\doc\7za920
	move 7za.exe opt\bin
	
:checkmsys2
if exist "%instdir%\msys64\msys2_shell.bat" GOTO getMintty
	echo -------------------------------------------------------------------------------
	echo.
	echo.- Download and install msys2 basic system
	echo.
	echo -------------------------------------------------------------------------------
	
	"%instdir%\wget" -P "%instdir%" -O msys2-base.tar.xz "http://sourceforge.net/projects/msys2/files/latest/download?source=files"
	
	%instdir%\opt\bin\7za.exe x msys2-base.tar.xz
	%instdir%\opt\bin\7za.exe x msys2-base.tar
	del msys2-base.tar.xz
	del msys2-base.tar
	del wget.exe
	
:getMintty
if exist %instdir%\mintty.lnk GOTO updatebase
	echo -------------------------------------------------------------------------------
	echo.
	echo.- set mintty shell shortcut and make a first run
	echo.
	echo -------------------------------------------------------------------------------
	
	echo.Set Shell = CreateObject^("WScript.Shell"^)>>%instdir%\setlink.vbs
	echo.Set link = Shell.CreateShortcut^("%instdir%\mintty.lnk"^)>>%instdir%\setlink.vbs
	echo.link.Arguments = "/bin/sh -l" >>%instdir%\setlink.vbs
	echo.link.Description = "msys2 shell console">>%instdir%\setlink.vbs
	echo.link.TargetPath = "%instdir%\msys64\bin\mintty.exe">>%instdir%\setlink.vbs
	echo.link.WindowStyle = ^1>>%instdir%\setlink.vbs
	echo.link.WorkingDirectory = "%instdir%\msys64\bin">>%instdir%\setlink.vbs
	echo.link.Save>>%instdir%\setlink.vbs

	cscript /nologo %instdir%\setlink.vbs 
	del %instdir%\setlink.vbs 	

	echo.sleep ^5>firstrun.sh
	echo.exit>firstrun.sh
	%instdir%\mintty.lnk %instdir%\firstrun.sh
	del firstrun.sh
	
	for /f %%i in ('dir %instdir%\msys64\home /B') do set userFolder=%%i
	
	Setlocal EnableDelayedExpansion 

	for /F "tokens=3 delims= " %%g in ('reg query "hklm\system\controlset001\control\nls\language" /v Installlanguage') do (
	if [%%g] EQU [0407] (
		set lang=de_DE
		) else (
			set land=C
			)
	)
	set lng=!lang!
	Setlocal DisableDelayedExpansion 
	
	echo.BoldAsFont=no>>%instdir%\msys64\home\%userFolder%\.minttyrc
	echo.BackgroundColour=57,57,57>>%instdir%\msys64\home\%userFolder%\.minttyrc
	echo.ForegroundColour=221,221,221>>%instdir%\msys64\home\%userFolder%\.minttyrc
	echo.Transparency=medium>>%instdir%\msys64\home\%userFolder%\.minttyrc
	echo.FontHeight=^9>>%instdir%\msys64\home\%userFolder%\.minttyrc
	echo.FontSmoothing=full>>%instdir%\msys64\home\%userFolder%\.minttyrc
	echo.AllowBlinking=yes>>%instdir%\msys64\home\%userFolder%\.minttyrc
	echo.Font=DejaVu Sans Mono>>%instdir%\msys64\home\%userFolder%\.minttyrc
	echo.Columns=90>>%instdir%\msys64\home\%userFolder%\.minttyrc
	echo.Rows=30>>%instdir%\msys64\home\%userFolder%\.minttyrc
	echo.Locale=%lng%>>%instdir%\msys64\home\%userFolder%\.minttyrc
	echo.Charset=UTF-8>>%instdir%\msys64\home\%userFolder%\.minttyrc
	echo.Term=xterm-256color>>%instdir%\msys64\home\%userFolder%\.minttyrc
	echo.CursorType=block>>%instdir%\msys64\home\%userFolder%\.minttyrc
	echo.Black=38,39,41>>%instdir%\msys64\home\%userFolder%\.minttyrc
	echo.Red=249,38,113>>%instdir%\msys64\home\%userFolder%\.minttyrc
	echo.Green=166,226,46>>%instdir%\msys64\home\%userFolder%\.minttyrc
	echo.Yellow=253,151,31>>%instdir%\msys64\home\%userFolder%\.minttyrc
	echo.Blue=102,217,239>>%instdir%\msys64\home\%userFolder%\.minttyrc
	echo.Magenta=158,111,254>>%instdir%\msys64\home\%userFolder%\.minttyrc
	echo.Cyan=94,113,117>>%instdir%\msys64\home\%userFolder%\.minttyrc
	echo.White=248,248,242>>%instdir%\msys64\home\%userFolder%\.minttyrc
	echo.BoldBlack=85,68,68>>%instdir%\msys64\home\%userFolder%\.minttyrc
	echo.BoldRed=249,38,113>>%instdir%\msys64\home\%userFolder%\.minttyrc
	echo.BoldGreen=166,226,46>>%instdir%\msys64\home\%userFolder%\.minttyrc
	echo.BoldYellow=253,151,31>>%instdir%\msys64\home\%userFolder%\.minttyrc
	echo.BoldBlue=102,217,239>>%instdir%\msys64\home\%userFolder%\.minttyrc
	echo.BoldMagenta=158,111,254>>%instdir%\msys64\home\%userFolder%\.minttyrc
	echo.BoldCyan=163,186,191>>%instdir%\msys64\home\%userFolder%\.minttyrc
	echo.BoldWhite=248,248,242>>%instdir%\msys64\home\%userFolder%\.minttyrc
	
:updatebase
echo.-------------------------------------------------------------------------------
echo.updating msys2 system
echo.-------------------------------------------------------------------------------
echo.pacman --noconfirm -Sy>>updateMSYS2.sh
echo.pacman --noconfirm -Su>>updateMSYS2.sh
echo.echo "-------------------------------------------------------------------------------">>updateMSYS2.sh
echo.echo "updating msys2 done...">>updateMSYS2.sh
echo.echo "-------------------------------------------------------------------------------">>updateMSYS2.sh
echo.sleep ^5>>updateMSYS2.sh
echo.exit>>updateMSYS2.sh
%instdir%\mintty.lnk %instdir%\updateMSYS2.sh
del updateMSYS2.sh

:installbase
if exist %instdir%\msys64\bin\make.exe GOTO makeDIR
	echo.-------------------------------------------------------------------------------
	echo.install msys2 base system
	echo.-------------------------------------------------------------------------------
	echo.pacman --noconfirm -S asciidoc autoconf autoconf2.13 automake-wrapper automake1.10 automake1.11 automake1.12 automake1.13 automake1.14 automake1.6 automake1.7 automake1.8 automake1.9 bison diffstat diffutils dos2unix flex gdb gperf groff help2man intltool libtool m4 man patch pkg-config scons swig xmlto make tar zip unzip git subversion wget>>pacman.sh
	echo.exit>>pacman.sh

if %build32%==yes (
	echo.pacman --noconfirm -S mingw-w64-i686-cloog mingw-w64-i686-cmake mingw-w64-i686-crt-svn mingw-w64-i686-doxygen mingw-w64-i686-gcc mingw-w64-i686-gcc-ada mingw-w64-i686-gcc-fortran mingw-w64-i686-gcc-libgfortran mingw-w64-i686-gcc-libs mingw-w64-i686-gcc-objc mingw-w64-i686-gettext mingw-w64-i686-glew mingw-w64-i686-gmp mingw-w64-i686-headers-svn mingw-w64-i686-libiconv mingw-w64-i686-mpc mingw-w64-i686-winpthreads-svn mingw-w64-i686-sqlite3 mingw-w64-i686-yasm>>pacman.sh
	)	
	
if %build64%==yes (
	echo.pacman --noconfirm -S mingw-w64-x86_64-cloog mingw-w64-x86_64-cmake mingw-w64-x86_64-crt-svn mingw-w64-x86_64-doxygen mingw-w64-x86_64-gcc mingw-w64-x86_64-gcc-ada mingw-w64-x86_64-gcc-fortran mingw-w64-x86_64-gcc-libgfortran mingw-w64-x86_64-gcc-libs mingw-w64-x86_64-gcc-objc mingw-w64-x86_64-gettext mingw-w64-x86_64-glew mingw-w64-x86_64-gmp mingw-w64-x86_64-headers-svn mingw-w64-x86_64-libiconv mingw-w64-x86_64-mpc mingw-w64-x86_64-winpthreads-svn mingw-w64-x86_64-sqlite3 mingw-w64-x86_64-yasm>>pacman.sh
	)
	
	%instdir%\mintty.lnk %instdir%\pacman.sh
	del pacman.sh
	
:makeDIR
if %build32%==yes (
	if not exist %instdir%\global32 (
		echo.-------------------------------------------------------------------------------
		echo.create global32 folders
		echo.-------------------------------------------------------------------------------
		mkdir %instdir%\global32
		mkdir %instdir%\global32\bin
		mkdir %instdir%\global32\etc
		mkdir %instdir%\global32\include
		mkdir %instdir%\global32\lib
		mkdir %instdir%\global32\lib\pkgconfig
		mkdir %instdir%\global32\share
		)
	if not exist %instdir%\build32 mkdir %instdir%\build32
	if not exist %instdir%\local32\share (
		echo.-------------------------------------------------------------------------------
		echo.create local32 folders
		echo.-------------------------------------------------------------------------------
		mkdir %instdir%\local32
		mkdir %instdir%\local32\bin
		mkdir %instdir%\local32\etc
		mkdir %instdir%\local32\include
		mkdir %instdir%\local32\lib
		mkdir %instdir%\local32\lib\pkgconfig
		mkdir %instdir%\local32\share
		)	
	)
	
if %build64%==yes (
	if not exist %instdir%\global64 (
		echo.-------------------------------------------------------------------------------
		echo.create global64 folders
		echo.-------------------------------------------------------------------------------
		mkdir %instdir%\global64
		mkdir %instdir%\global64\bin
		mkdir %instdir%\global64\etc
		mkdir %instdir%\global64\include
		mkdir %instdir%\global64\lib
		mkdir %instdir%\global64\lib\pkgconfig
		mkdir %instdir%\global64\share
		)
	if not exist %instdir%\build64 mkdir %instdir%\build64
	if not exist %instdir%\local64\share (
		echo.-------------------------------------------------------------------------------
		echo.create local64 folders
		echo.-------------------------------------------------------------------------------
		mkdir %instdir%\local64
		mkdir %instdir%\local64\bin
		mkdir %instdir%\local64\etc
		mkdir %instdir%\local64\include
		mkdir %instdir%\local64\lib
		mkdir %instdir%\local64\lib\pkgconfig
		mkdir %instdir%\local64\share
		)
	)
	
:writeConfFile
if exist %instdir%\msys64\etc\fstabconf.cfg GOTO writeProfile32
	echo.>>%instdir%\msys64\etc\fstab.
	echo.%instdir%\opt\ /opt>>%instdir%\msys64\etc\fstab.
	echo.%instdir%\global32\ /global32>>%instdir%\msys64\etc\fstab.
	echo.%instdir%\local32\ /local32>>%instdir%\msys64\etc\fstab.
	echo.%instdir%\build32\ /build32>>%instdir%\msys64\etc\fstab.
	echo.%instdir%\msys64\mingw32\ /mingw32>>%instdir%\msys64\etc\fstab.
	echo.%instdir%\global64\ /global64>>%instdir%\msys64\etc\fstab.
	echo.%instdir%\local64\ /local64>>%instdir%\msys64\etc\fstab.
	echo.%instdir%\build64\ /build64>>%instdir%\msys64\etc\fstab.
	echo.%instdir%\msys64\mingw64\ /mingw64>>%instdir%\msys64\etc\fstab.
	echo.new mount done. see in fstab>> %instdir%\msys64\etc\fstabconf.cfg

::------------------------------------------------------------------
:: write config profiles:
::------------------------------------------------------------------	

:writeProfile32
if %build32%==yes (
	if exist %instdir%\global32\etc\profile.local GOTO writeProfile64
		echo -------------------------------------------------------------------------------
		echo.
		echo.- write profile for 32 bit compiling
		echo.
		echo -------------------------------------------------------------------------------
		echo.#>>%instdir%\global32\etc\profile.local
		echo.# /global32/etc/profile.local>>%instdir%\global32\etc\profile.local
		echo.#>>%instdir%\global32\etc\profile.local
		echo.>>%instdir%\global32\etc\profile.local
		echo.alias dir='ls -la --color=auto'>>%instdir%\global32\etc\profile.local
		echo.alias ls='ls --color=auto'>>%instdir%\global32\etc\profile.local
		echo.>>%instdir%\global32\etc\profile.local
		echo.PKG_CONFIG_PATH="/local32/lib/pkgconfig">>%instdir%\global32\etc\profile.local
		echo.CPPFLAGS="-I/global32/include -I/local32/include">>%instdir%\global32\etc\profile.local
		echo.CFLAGS="-I/global32/include -I/local32/include -mms-bitfields -mthreads -mtune=pentium3">>%instdir%\global32\etc\profile.local
		echo.CXXFLAGS="-I/global32/include -I/local32/include -mms-bitfields -mthreads -mtune=pentium3">>%instdir%\global32\etc\profile.local
		echo.LDFLAGS="-L/global32/lib -L/local32/lib -mthreads">>%instdir%\global32\etc\profile.local
		echo.export PKG_CONFIG_PATH CPPFLAGS CFLAGS CXXFLAGS LDFLAGS>>%instdir%\global32\etc\profile.local
		echo.>>%instdir%\global32\etc\profile.local
		echo.PATH=".:/global32/bin:/local32/bin:/mingw32/bin:/mingw/bin:/bin:/opt/bin:/opt/TortoiseHg:/opt/Python27:/opt/Python27/Tools/Scripts">>%instdir%\global32\etc\profile.local
		echo.PS1='\[\033[32m\]\u@\h \[\033[33m\w\033[0m\]$ '>>%instdir%\global32\etc\profile.local
		echo.export PATH PS1>>%instdir%\global32\etc\profile.local
		echo.>>%instdir%\global32\etc\profile.local
		echo.# package build directory>>%instdir%\global32\etc\profile.local
		echo.LOCALBUILDDIR=/build32>>%instdir%\global32\etc\profile.local
		echo.# package installation prefix>>%instdir%\global32\etc\profile.local
		echo.GLOBALDESTDIR=/global32>>%instdir%\global32\etc\profile.local
		echo.LOCALDESTDIR=/local32>>%instdir%\global32\etc\profile.local
		echo.export LOCALBUILDDIR GLOBALDESTDIR LOCALDESTDIR>>%instdir%\global32\etc\profile.local
		)
		
:writeProfile64
if %build64%==yes (
	if exist %instdir%\global64\etc\profile.local GOTO loginProfile
		echo -------------------------------------------------------------------------------
		echo.
		echo.- write profile for 64 bit compiling
		echo.
		echo -------------------------------------------------------------------------------
		echo.#>>%instdir%\global64\etc\profile.local
		echo.# /global64/etc/profile.local>>%instdir%\global64\etc\profile.local
		echo.#>>%instdir%\global64\etc\profile.local
		echo.>>%instdir%\global64\etc\profile.local
		echo.alias dir='ls -la --color=auto'>>%instdir%\global64\etc\profile.local
		echo.alias ls='ls --color=auto'>>%instdir%\global64\etc\profile.local
		echo.>>%instdir%\global64\etc\profile.local
		echo.PKG_CONFIG_PATH="/local64/lib/pkgconfig">>%instdir%\global64\etc\profile.local
		echo.CPPFLAGS="-I/global64/include -I/local64/include">>%instdir%\global64\etc\profile.local
		echo.CFLAGS="-I/global64/include -I/local64/include -mms-bitfields -mthreads">>%instdir%\global64\etc\profile.local
		echo.CXXFLAGS="-I/global64/include -I/local64/include -mms-bitfields -mthreads">>%instdir%\global64\etc\profile.local
		echo.LDFLAGS="-L/global64/lib -L/local64/lib">>%instdir%\global64\etc\profile.local
		echo.export PKG_CONFIG_PATH CPPFLAGS CFLAGS CXXFLAGS LDFLAGS>>%instdir%\global64\etc\profile.local
		echo.>>%instdir%\global64\etc\profile.local
		echo.PATH=".:/global64/bin:/local64/bin:/mingw64/bin:/mingw/bin:/bin:/opt/bin:/opt/TortoiseHg:/opt/Python27:/opt/Python27/Tools/Scripts">>%instdir%\global64\etc\profile.local
		echo.PS1='\[\033[32m\]\u@\h \[\033[33m\w\033[0m\]$ '>>%instdir%\global64\etc\profile.local
		echo.export PATH PS1>>%instdir%\global64\etc\profile.local
		echo.>>%instdir%\global64\etc\profile.local
		echo.# package build directory>>%instdir%\global64\etc\profile.local
		echo.LOCALBUILDDIR=/build64>>%instdir%\global64\etc\profile.local
		echo.# package installation prefix>>%instdir%\global64\etc\profile.local
		echo.GLOBALDESTDIR=/global64>>%instdir%\global64\etc\profile.local
		echo.LOCALDESTDIR=/local64>>%instdir%\global64\etc\profile.local
		echo.export LOCALBUILDDIR GLOBALDESTDIR LOCALDESTDIR>>%instdir%\global64\etc\profile.local
		)
	
:loginProfile
if exist %instdir%\msys64\etc\userprofile.cfg GOTO extraPacks

if %build64%==yes (
	if %build32%==yes GOTO loginProfile32
	echo -------------------------------------------------------------------------------
	echo.
	echo.- write default profile (64 bit)
	echo.
	echo -------------------------------------------------------------------------------
	echo.cat ^>^> /etc/profile ^<^< "EOF">>%instdir%\profile.sh
	echo.if [ -f /global64/etc/profile.local ]; then>>%instdir%\profile.sh
	 echo.       source /global64/etc/profile.local>>%instdir%\profile.sh
	echo.fi>>%instdir%\profile.sh
	echo.>>%instdir%\profile.sh
	echo.EOF>>%instdir%\profile.sh

	%instdir%\msys64\bin\sh -l %instdir%\profile.sh
	echo 64 bit build system add to profile. see profile>>%instdir%\msys64\etc\userprofile.cfg
	del %instdir%\profile.sh
	GOTO extraPacks
	)
	
:loginProfile32
	echo -------------------------------------------------------------------------------
	echo.
	echo.- write default profile (32 bit)
	echo.
	echo -------------------------------------------------------------------------------
	echo.cat ^>^> /etc/profile ^<^< "EOF">>%instdir%\profile.sh
	echo.if [ -f /global32/etc/profile.local ]; then>>%instdir%\profile.sh
	 echo.       source /global32/etc/profile.local>>%instdir%\profile.sh
	echo.fi>>%instdir%\profile.sh
	echo.>>%instdir%\profile.sh
	echo.EOF>>%instdir%\profile.sh

	%instdir%\msys64\bin\sh -l %instdir%\profile.sh
	echo 32 bit build system add to profile. see profile>>%instdir%\msys64\etc\userprofile.cfg
	del %instdir%\profile.sh
	
:extraPacks
::------------------------------------------------------------------
:: get extra packs and compile global tools:
::------------------------------------------------------------------

if not exist "%instdir%\opt\bin\pdflatex.exe" (
	echo.-------------------------------------------------------------------------------
	echo.download and install pdftex-w32
	echo.-------------------------------------------------------------------------------
	cd %instdir%\opt
	%instdir%\msys64\bin\wget.exe --tries=20 --retry-connrefused --waitretry=2 -c "http://ctan.ijs.si/mirror/w32tex/current/pdftex-w32.tar.xz"
	%instdir%\msys64\bin\wget.exe --tries=20 --retry-connrefused --waitretry=2 -c "http://ctan.ijs.si/mirror/w32tex/current/makeindex-w32.tar.xz"
	%instdir%\msys64\bin\wget.exe --tries=20 --retry-connrefused --waitretry=2 -c "http://ctan.ijs.si/mirror/w32tex/current/dvipsk-w32.tar.xz"
	%instdir%\msys64\bin\xz -d pdftex-w32.tar.xz
	%instdir%\msys64\bin\tar -xf pdftex-w32.tar
	%instdir%\msys64\bin\xz -d makeindex-w32.tar.xz
	%instdir%\msys64\bin\tar -xf makeindex-w32.tar
	%instdir%\msys64\bin\xz -d dvipsk-w32.tar.xz
	%instdir%\msys64\bin\tar -xf dvipsk-w32.tar
	%instdir%\msys64\bin\rm pdftex-w32.tar
	%instdir%\msys64\bin\rm makeindex-w32.tar
	%instdir%\msys64\bin\rm dvipsk-w32.tar
	cd ..
	)		

if not exist "%instdir%\opt\python27\python.exe" (
	cd %instdir%\opt
	mkdir python27
	%instdir%\msys64\bin\wget.exe --tries=20 --retry-connrefused --waitretry=2 -c --no-check-certificate https://www.python.org/ftp/python/2.7.2/python-2.7.2.msi
	msiexec /a %instdir%\opt\python-2.7.2.msi /qb TARGETDIR=%instdir%\opt\python27
	del python-2.7.2.msi
	cd ..
)

if not exist "%instdir%\opt\TortoiseHg\hg.exe" (
	echo.-------------------------------------------------------------------------------
	echo.download and install TortoiseHg
	echo.-------------------------------------------------------------------------------
	cd %instdir%\opt
	%instdir%\msys64\bin\wget.exe --tries=20 --retry-connrefused --waitretry=2 --no-check-certificate -c "http://bitbucket.org/tortoisehg/files/downloads/tortoisehg-2.11.2-hg-2.9.2-x86.msi"
	msiexec /a tortoisehg-2.11.2-hg-2.9.2-x86.msi /qb TARGETDIR=%instdir%\opt\hg-temp
	%instdir%\msys64\bin\cp -va %instdir%\opt\hg-temp\PFiles\TortoiseHg %instdir%\opt
	%instdir%\msys64\bin\rm tortoisehg-2.11.2-hg-2.9.2-x86.msi
	%instdir%\msys64\bin\rm -r -f %instdir%\opt\hg-temp
	cd ..
	)

cd %instdir%

:compileGlobals
if exist %instdir%\compile_globaltools.sh GOTO compileGobal
	echo -------------------------------------------------------------------------------
	echo.
	echo.- get script for global tools:
	echo.
	echo -------------------------------------------------------------------------------
	if exist %instdir%\media-autobuild_suite.zip GOTO unpackglobal
		%instdir%\msys64\bin\wget.exe --tries=20 --retry-connrefused --waitretry=2 --no-check-certificate -c -O media-autobuild_suite.zip https://github.com/jb-alvarado/media-autobuild_suite/archive/master.zip
		
		:unpackglobal
		%instdir%\opt\bin\7za.exe e -r -y %instdir%\media-autobuild_suite.zip -o%instdir% compile_globaltools.sh

:compileGobal
echo -------------------------------------------------------------------------------
echo.
echo.- compile global tools:
echo.
echo -------------------------------------------------------------------------------
%instdir%\mintty.lnk %instdir%\compile_globaltools.sh --cpuCount=%cpuCount% --build32=%build32% --build64=%build64% --deleteSource=%deleteSource%
echo. compile global tools done...

:: audio tools
if exist %instdir%\compile_audiotools.sh GOTO compileAudio
	echo -------------------------------------------------------------------------------
	echo.
	echo.- get script for audio tools:
	echo.
	echo -------------------------------------------------------------------------------
	if exist %instdir%\media-autobuild_suite.zip GOTO unpackAudio
		%instdir%\msys64\bin\wget.exe --tries=20 --retry-connrefused --waitretry=2 --no-check-certificate -c -O media-autobuild_suite.zip https://github.com/jb-alvarado/media-autobuild_suite/archive/master.zip
	
		:unpackAudio
		%instdir%\opt\bin\7za.exe e -r -y %instdir%\media-autobuild_suite.zip -o%instdir% compile_audiotools.sh

:compileAudio
echo -------------------------------------------------------------------------------
echo.
echo.- compile audio tools:
echo.
echo -------------------------------------------------------------------------------
%instdir%\mintty.lnk %instdir%\compile_audiotools.sh --cpuCount=%cpuCount% --build32=%build32% --build64=%build64% --deleteSource=%deleteSource% --nonfree=%binary%
echo. compile audio tools done...

:: video tools
if not exist %instdir%\compile_videotools.sh (
	echo -------------------------------------------------------------------------------
	echo.
	echo.- get script for video tools:
	echo.
	echo -------------------------------------------------------------------------------
	if not exist %instdir%\media-autobuild_suite.zip (
		%instdir%\msys64\bin\wget.exe --tries=20 --retry-connrefused --waitretry=2 --no-check-certificate -c -O media-autobuild_suite.zip https://github.com/jb-alvarado/media-autobuild_suite/archive/master.zip
		)
		%instdir%\opt\bin\7za.exe e -r -y %instdir%\media-autobuild_suite.zip -o%instdir% compile_videotools.sh
	)

echo -------------------------------------------------------------------------------
echo.
echo.- compile video tools:
echo.
echo -------------------------------------------------------------------------------
%instdir%\mintty.lnk %instdir%\compile_videotools.sh --cpuCount=%cpuCount% --build32=%build32% --build64=%build64% --deleteSource=%deleteSource% --mp4box=%mp4box% --ffmpeg=%ffmpeg% --mplayer=%mplayer% --nonfree=%binary%
echo. compile video tools done...	
	
:: strip compiled files
if %stripFile%==y (
echo -------------------------------------------------------------------------------
echo.
echo.- stripping bins:
echo.
echo -------------------------------------------------------------------------------

if %build32%==yes (
	FOR /R "%instdir%\local32\bin" %%C IN (*.exe) DO (
		FOR /F "tokens=1 delims= " %%A IN ( "%%~tC" ) DO (
			IF %%A == %date% (
				%instdir%\msys64\mingw32\bin\strip --strip-all %%C
				echo.strip %%~nC%%~xC 32Bit done...
				)
			)
		)
		
	FOR /R "%instdir%\local32\bin" %%D IN (*.dll) DO (
		FOR /F "tokens=1 delims= " %%A IN ( "%%~tD" ) DO (
			IF %%A == %date% (
				%instdir%\msys64\mingw32\bin\strip --strip-all %%D
				echo.strip %%~nD%%~xD 32Bit done...
				)
			)
		)
	)	
	
if %build64%==yes (
	FOR /R "%instdir%\local64\bin" %%C IN (*.exe) DO (
		FOR /F "tokens=1 delims= " %%A IN ( "%%~tC" ) DO (
			IF %%A == %date% (
				%instdir%\msys64\mingw32\bin\strip --strip-all %%C
				echo.strip %%~nC%%~xC 64Bit done...
				)
			)
		)
		
	FOR /R "%instdir%\local64\bin" %%D IN (*.dll) DO (
		FOR /F "tokens=1 delims= " %%A IN ( "%%~tD" ) DO (
			IF %%A == %date% (
				%instdir%\msys64\mingw32\bin\strip --strip-all %%D
				echo.strip %%~nD%%~xD 64Bit done...
				)
			)
		)
	)
)

echo -------------------------------------------------------------------------------
echo.
echo. compiling done...
echo.
echo -------------------------------------------------------------------------------

ping 127.0.0.0 -n 3 >nul
echo.
echo Window close in 15
echo.
ping 127.0.0.0 -n 5 >nul
echo.
echo Window close in 10
echo.
ping 127.0.0.0 -n 5 >nul
echo.
echo Window close in 5
echo.
ping 127.0.0.0 -n 5 >nul
echo.