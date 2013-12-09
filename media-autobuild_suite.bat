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
::	This is version 0.99
::	Project stared at 2013-09-24. Last bigger modification was on 2013-12-05
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
	echo.vlc=^0>>%ini%
	echo.image=^0>>%ini%
	echo.cores=^0>>%ini%
	)

for /F "tokens=2 delims==" %%a in ('findstr /i arch %ini%') do set archINI=%%a
for /F "tokens=2 delims==" %%b in ('findstr /i free %ini%') do set freeINI=%%b
for /F "tokens=2 delims==" %%c in ('findstr /i ffmpeg %ini%') do set ffmpegINI=%%c
for /F "tokens=2 delims==" %%d in ('findstr /i mp4box %ini%') do set mp4boxINI=%%d
for /F "tokens=2 delims==" %%e in ('findstr /i mplayer %ini%') do set mplayerINI=%%e
for /F "tokens=2 delims==" %%f in ('findstr /i vlc %ini%') do set vlcINI=%%f
for /F "tokens=2 delims==" %%g in ('findstr /i image %ini%') do set imageINI=%%g
for /F "tokens=2 delims==" %%h in ('findstr /i cores %ini%') do set coresINI=%%h

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
if %buildffmpeg% GTR 2 GOTO ffmpeg

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

:magick
if %imageINI%==0 (
	echo -------------------------------------------------------------------------------
	echo -------------------------------------------------------------------------------
	echo.
	echo. Build static image tools [openEXR, ImageMagick]:
	echo. 1 = yes
	echo. 2 = no
	echo.
	echo -------------------------------------------------------------------------------
	echo -------------------------------------------------------------------------------
	set /P buildmagick="build ImageMagick:"
	) else (
		set buildmagick=%imageINI%
	)
	
if %buildmagick%==1 (
	set "magick=y"
	)
if %buildmagick%==2 (
	set "magick=n"
	)
if %buildmagick% GTR 2 GOTO magick

:vlc
if %vlcINI%==0 (
	echo -------------------------------------------------------------------------------
	echo -------------------------------------------------------------------------------
	echo.
	echo. Build vlc player:
	echo. 1 = yes
	echo. 2 = no
	echo.
	echo -------------------------------------------------------------------------------
	echo -------------------------------------------------------------------------------
	set /P buildvlc="build vlc:"
	) else (
		set buildvlc=%vlcINI%
		)
	
if %buildvlc%==1 (
	set "vlc=y"
	set "qt4=y"
	)
if %buildvlc%==2 (
	set "vlc=n"
	set "qt4=n"
	)
if %buildvlc% GTR 2 GOTO vlc

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

::------------------------------------------------------------------
::download and install basic msys system:
::------------------------------------------------------------------

if exist "%instdir%\msys\1.0\msys.bat" GOTO 7za
	echo -------------------------------------------------------------------------------
	echo.
	echo.- Download and install msys basic system
	echo.
	echo -------------------------------------------------------------------------------
	
	echo.var wshell = new ActiveXObject("WScript.Shell");var htmldoc = new ActiveXObject("htmlfile");var xmlhttp = new ActiveXObject("MSXML2.ServerXMLHTTP");var adodb = new ActiveXObject("ADODB.Stream");var FSO = new ActiveXObject("Scripting.FileSystemObject");;function http_get(url, is_binary){ xmlhttp.open("GET", url); xmlhttp.send(); WScript.echo("retrieving " + url); while (xmlhttp.readyState != 4);  WScript.Sleep(100); if (xmlhttp.status != 200) { WScript.Echo("http get failed: " + xmlhttp.status);  WScript.Quit(2); }; return is_binary ? xmlhttp.responseBody : xmlhttp.responseText;}; function url_decompose_filename(url) { return url.split('/').pop().split('?').shift(); }; function save_binary(path, data) { adodb.type = 1; adodb.open(); adodb.write(data); adodb.saveToFile(path, 2);}; function pick_from_sf_file_list(html, cond) { htmldoc.open(); htmldoc.write(html); var tr = htmldoc.getElementById("files_list").getElementsByTagName("tr"); for (var i = 0; i ^< tr.length; ++i) {  title = tr[i].title;  if (cond(title)) return title; }; return null;}; function download_mingw_get() { var base_url = "http://sourceforge.net/projects/mingw/files/Installer/mingw-get/"; var html = http_get(base_url, false); var project_name = pick_from_sf_file_list(html, function(title) { return title.indexOf("mingw-get") ^>= 0; }); var project_url = base_url + project_name + "/"; html = http_get(project_url, false); var dlp_name = pick_from_sf_file_list(html, function(title) { return title.indexOf("bin.zip") ^>= 0; }); var dlp_url = project_url + dlp_name + "/download"; html = http_get(dlp_url, false); htmldoc.open(); htmldoc.write(html); var div = htmldoc.getElementById("downloading"); var url = div.getElementsByTagName("a")[1].href; var filename = url.split('/').pop().split('?').shift(); var installer_data = http_get(url, true); save_binary(filename, installer_data); return FSO.GetAbsolutePathName(filename) }; function extract_zip(zip_file, dstdir) { var shell = new ActiveXObject("shell.application"); var dst = shell.NameSpace(dstdir); var zipdir = shell.NameSpace(zip_file); dst.CopyHere(zipdir.items(), 0);}; function install_mingw(zip_file, packages) { var rootdir = wshell.CurrentDirectory; extract_zip(zip_file, rootdir); wshell.Run("bin\\mingw-get install " + packages, 10, true); var fstab = FSO.GetAbsolutePathName("msys\\1.0\\etc\\fstab"); var fp = FSO.CreateTextFile(fstab, true); fp.WriteLine(rootdir.replace(/\\/g,"/") + "\t/mingw"); fp.Close(); FSO.GetFile(zip_file).Delete();}; var packages = "msys-base msys-coreutils msys-wget msys-zip msys-unzip"; install_mingw(download_mingw_get(), packages)>>build_msys.js
	
	cscript build_msys.js
	del build_msys.js
	del mingw-get-0.6*

:7za
if exist "%instdir%\opt\bin\7za.exe" GOTO mingw-dtk
	echo -------------------------------------------------------------------------------
	echo.
	echo.- Download and install 7za
	echo.
	echo -------------------------------------------------------------------------------
	%instdir%\msys\1.0\bin\wget.exe -c "http://downloads.sourceforge.net/sevenzip/7za920.zip"
	mkdir opt
	cd opt
	mkdir bin
	mkdir doc
	cd doc
	mkdir 7za920
	cd ..
	cd bin
	%instdir%\msys\1.0\bin\unzip %instdir%/7za920.zip
	%instdir%\msys\1.0\bin\mv license.txt readme.txt 7-zip.chm ../doc/7za920
	cd ..\..
	del 7za920.zip
	
:mingw-dtk
if exist "%instdir%\bin\msgmerge.exe" GOTO autoTools
	echo -------------------------------------------------------------------------------
	echo.
	echo.- Download and install ming-developer-toolkit
	echo.
	echo -------------------------------------------------------------------------------
	del /Q %instdir%\var\lib\mingw-get\data\mingw*
	%instdir%\msys\1.0\bin\wget.exe -c "http://blog.pixelcrusher.de/downloads/media-autobuild_suite/mingw-dtk_jb.zip"
	cd %instdir%\var\lib\mingw-get\data
	%instdir%\opt\bin\7za.exe x %instdir%\mingw-dtk_jb.zip
	cd %instdir%
	del mingw-dtk_jb.zip
	%instdir%\bin\mingw-get install mingw-developer-toolkit pkginfo
	%instdir%\bin\mingw-get upgrade msys-core-bin=1.0.17-1
	
:autoTools
if exist "%instdir%\msys\1.0\share\aclocal\pkg.m4" GOTO mingw32
	echo -------------------------------------------------------------------------------
	echo.
	echo.- Download and install AutoTools, libcrypt, Glib and PKG-CONFIG
	echo.
	echo -------------------------------------------------------------------------------
	cd %instdir%\msys\1.0
	%instdir%\msys\1.0\bin\wget.exe -c http://sourceforge.net/projects/mingw/files/MSYS/msysdev/autoconf/autoconf-2.68-1/autoconf-2.68-1-msys-1.0.17-bin.tar.lzma/download
	%instdir%\msys\1.0\bin\wget.exe -c http://sourceforge.net/projects/mingw/files/MSYS/msysdev/automake/automake-1.11.1-1/automake-1.11.1-1-msys-1.0.13-bin.tar.lzma/download
	%instdir%\msys\1.0\bin\wget.exe -c http://sourceforge.net/projects/mingw/files/MSYS/msysdev/libtool/libtool-2.4-1/libtool-2.4-1-msys-1.0.15-bin.tar.lzma/download
	%instdir%\msys\1.0\bin\wget.exe -c http://prdownloads.sourceforge.net/mingw/libcrypt-1.1_1-2-msys-1.0.11-dll-0.tar.lzma
	%instdir%\msys\1.0\bin\wget.exe -c http://sourceforge.net/projects/mingw/files/MSYS/Extension/perl/perl-5.8.8-1/perl-5.8.8-1-msys-1.0.17-bin.tar.lzma/download
	%instdir%\msys\1.0\bin\wget.exe -c http://sourceforge.net/projects/mingw/files/MSYS/Extension/m4/m4-1.4.14-1/m4-1.4.14-1-msys-1.0.13-bin.tar.lzma/download
	%instdir%\msys\1.0\bin\wget.exe -c http://ftp.acc.umu.se/pub/GNOME/binaries/win32/glib/2.28/glib_2.28.8-1_win32.zip
	%instdir%\msys\1.0\bin\wget.exe -c ftp://ftp.gnome.org/pub/gnome/binaries/win32/dependencies/pkg-config_0.23-3_win32.zip
	%instdir%\msys\1.0\bin\wget.exe -c ftp://ftp.gnome.org/pub/gnome/binaries/win32/dependencies/pkg-config-dev_0.23-3_win32.zip
	%instdir%\msys\1.0\bin\wget.exe -c http://ftp.gnome.org/pub/gnome/binaries/win32/dependencies/gettext-runtime_0.18.1.1-2_win32.zip
	
	%instdir%\msys\1.0\bin\lzma -d autoconf-2.68-1-msys-1.0.17-bin.tar.lzma
	%instdir%\msys\1.0\bin\tar --keep-newer-files -xf autoconf-2.68-1-msys-1.0.17-bin.tar
	%instdir%\msys\1.0\bin\lzma -d automake-1.11.1-1-msys-1.0.13-bin.tar.lzma
	%instdir%\msys\1.0\bin\tar --keep-newer-files -xf automake-1.11.1-1-msys-1.0.13-bin.tar
	%instdir%\msys\1.0\bin\lzma -d libtool-2.4-1-msys-1.0.15-bin.tar.lzma
	%instdir%\msys\1.0\bin\tar --keep-newer-files -xf libtool-2.4-1-msys-1.0.15-bin.tar
	%instdir%\msys\1.0\bin\lzma -d libcrypt-1.1_1-2-msys-1.0.11-dll-0.tar.lzma
	%instdir%\msys\1.0\bin\tar --keep-newer-files -xf libcrypt-1.1_1-2-msys-1.0.11-dll-0.tar
	%instdir%\msys\1.0\bin\lzma -d perl-5.8.8-1-msys-1.0.17-bin.tar.lzma
	%instdir%\msys\1.0\bin\tar --keep-newer-files -xf perl-5.8.8-1-msys-1.0.17-bin.tar
	%instdir%\msys\1.0\bin\lzma -d m4-1.4.14-1-msys-1.0.13-bin.tar.lzma
	%instdir%\msys\1.0\bin\tar --keep-newer-files -xf m4-1.4.14-1-msys-1.0.13-bin.tar
	%instdir%\msys\1.0\bin\unzip -n glib_2.28.8-1_win32.zip
	%instdir%\msys\1.0\bin\unzip -n pkg-config_0.23-3_win32.zip
	%instdir%\msys\1.0\bin\unzip -n pkg-config-dev_0.23-3_win32.zip
	%instdir%\msys\1.0\bin\unzip -n gettext-runtime_0.18.1.1-2_win32.zip
	
	del autoconf-2.68-1-msys-1.0.17-bin.tar
	del automake-1.11.1-1-msys-1.0.13-bin.tar
	del libtool-2.4-1-msys-1.0.15-bin.tar
	del libcrypt-1.1_1-2-msys-1.0.11-dll-0.tar
	del perl-5.8.8-1-msys-1.0.17-bin.tar
	del m4-1.4.14-1-msys-1.0.13-bin.tar
	del glib_2.28.8-1_win32.zip
	del pkg-config_0.23-3_win32.zip
	del pkg-config-dev_0.23-3_win32.zip
	del gettext-runtime_0.18.1.1-2_win32.zip
	
	for /f %%a in ('dir %instdir%\msys\1.0\home /B') do set userName=%%a
	echo.echo '%userName%'>%instdir%\msys\1.0\bin\whoami
	
	cd %instdir%
	
::------------------------------------------------------------------
::download and install mingw compiler:
::------------------------------------------------------------------	
	
:mingw32
if %build32%==yes (
	if exist "%instdir%\mingw32\bin\gcc.exe" GOTO mingw64
		echo -------------------------------------------------------------------------------
		echo.
		echo.- Download and install mingw 32bit compiler to mingw32
		echo.
		echo -------------------------------------------------------------------------------
		if exist mingw32-gcc-4.8.0.7z GOTO instMingW32
		%instdir%\msys\1.0\bin\wget.exe -c --no-check-certificate -O mingw32-gcc-4.8.2.7z "https://downloads.sourceforge.net/project/mingw-w64/Toolchains targetting Win32/Personal Builds/mingw-builds/4.8.2/threads-win32/sjlj/i686-4.8.2-release-win32-sjlj-rt_v3-rev0.7z"

		:instMingW32
		%instdir%\opt\bin\7za.exe x mingw32-gcc-4.8.2.7z
		%instdir%\msys\1.0\bin\cp %instdir%\mingw32\bin\gcc.exe %instdir%\mingw32\bin\cc.exe
		del mingw32-gcc-4.8.2.7z
		
		FOR /R "%instdir%\mingw32" %%C IN (*.dll.a) DO (
			%instdir%\msys\1.0\bin\mv  %%C %%C.dyn
			)
		if not exist "%instdir%\mingw32\bin\cc.exe" (
			echo.
			echo.download from compiler mingw32 fail...
			echo.try again or fix download
			echo.
			GOTO mingw32
			)
	)
		
:mingw64
if %build64%==yes (
	if exist "%instdir%\mingw64\bin\gcc.exe" GOTO makeDIR
		echo -------------------------------------------------------------------------------
		echo.
		echo.- Download and install mingw 64bit compiler to mingw64
		echo.
		echo -------------------------------------------------------------------------------
		if exist mingw64-gcc-4.8.0.7z GOTO instMingW64
		%instdir%\msys\1.0\bin\wget.exe -c --no-check-certificate -O mingw64-gcc-4.8.2.7z "https://downloads.sourceforge.net/project/mingw-w64/Toolchains targetting Win64/Personal Builds/mingw-builds/4.8.2/threads-win32/sjlj/x86_64-4.8.2-release-win32-sjlj-rt_v3-rev0.7z"
		
		:instMingW64
		%instdir%\opt\bin\7za.exe x mingw64-gcc-4.8.2.7z
		%instdir%\msys\1.0\bin\cp %instdir%\mingw64\bin\gcc.exe %instdir%\mingw64\bin\cc.exe
		del mingw64-gcc-4.8.2.7z

		FOR /R "%instdir%\mingw64" %%C IN (*.dll.a) DO (
			%instdir%\msys\1.0\bin\mv  %%C %%C.dyn
			)
		if not exist "%instdir%\mingw64\bin\cc.exe" (
			echo.
			echo.download from compiler mingw64 fail...
			echo.try again or fix download
			echo.
			GOTO mingw64
			)	
	)

:makeDIR
if %build32%==yes (
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
if exist %instdir%\conf-env.sh GOTO runConfFile
if exist %instdir%\msys\1.0\etc\userconf.cfg GOTO writeProfile32
	echo mount '%instdir%\opt\' /opt>>%instdir%\conf-env.sh
	echo mount '%instdir%\local32\' /local32>>%instdir%\conf-env.sh
	echo mount '%instdir%\build32\' /build32>>%instdir%\conf-env.sh
	echo mount '%instdir%\mingw32\' /mingw32>>%instdir%\conf-env.sh
	echo mount '%instdir%\local64\' /local64>>%instdir%\conf-env.sh
	echo mount '%instdir%\build64\' /build64>>%instdir%\conf-env.sh
	echo mount '%instdir%\mingw64\' /mingw64>>%instdir%\conf-env.sh

:runConfFile
if exist %instdir%\msys\1.0\etc\userconf.cfg GOTO writeProfile32
	echo -------------------------------------------------------------------------------
	echo.
	echo.- mounting build folders
	echo.
	echo -------------------------------------------------------------------------------
	%instdir%\msys\1.0\bin\sh -l %instdir%\conf-env.sh
	echo new mount done. see in fstap>> %instdir%\msys\1.0\etc\userconf.cfg
	del %instdir%\conf-env.sh

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
		echo.#>>%instdir%\local32\etc\profile.local
		echo.# /local32/etc/profile.local>>%instdir%\local32\etc\profile.local
		echo.#>>%instdir%\local32\etc\profile.local
		echo.>>%instdir%\local32\etc\profile.local
		echo.alias dir='ls -la --color=auto'>>%instdir%\local32\etc\profile.local
		echo.alias ls='ls --color=auto'>>%instdir%\local32\etc\profile.local
		echo.>>%instdir%\local32\etc\profile.local
		echo.PKG_CONFIG_PATH="/local32/lib/pkgconfig">>%instdir%\local32\etc\profile.local
		echo.CPPFLAGS="-I/local32/include">>%instdir%\local32\etc\profile.local
		echo.CFLAGS="-I/local32/include -mms-bitfields -mthreads -mtune=pentium3">>%instdir%\local32\etc\profile.local
		echo.CXXFLAGS="-I/local32/include -mms-bitfields -mthreads -mtune=pentium3">>%instdir%\local32\etc\profile.local
		echo.LDFLAGS="-L/local32/lib -mthreads">>%instdir%\local32\etc\profile.local
		echo.export PKG_CONFIG_PATH CPPFLAGS CFLAGS CXXFLAGS LDFLAGS>>%instdir%\local32\etc\profile.local
		echo.>>%instdir%\local32\etc\profile.local
		echo.PATH=".:/local32/bin:/mingw32/bin:/mingw/bin:/bin:/opt/bin:/opt/TortoiseHg">>%instdir%\local32\etc\profile.local
		echo.PS1='\[\033[32m\]\u@\h \[\033[33m\w\033[0m\]$ '>>%instdir%\local32\etc\profile.local
		echo.export PATH PS1>>%instdir%\local32\etc\profile.local
		echo.>>%instdir%\local32\etc\profile.local
		echo.# package build directory>>%instdir%\local32\etc\profile.local
		echo.LOCALBUILDDIR=/build32>>%instdir%\local32\etc\profile.local
		echo.# package installation prefix>>%instdir%\local32\etc\profile.local
		echo.LOCALDESTDIR=/local32>>%instdir%\local32\etc\profile.local
		echo.export LOCALBUILDDIR LOCALDESTDIR>>%instdir%\local32\etc\profile.local
		)
		
:writeProfile64
if %build64%==yes (
	if exist %instdir%\local64\etc\profile.local GOTO loginProfile
		echo -------------------------------------------------------------------------------
		echo.
		echo.- write profile for 64 bit compiling
		echo.
		echo -------------------------------------------------------------------------------
		echo.#>>%instdir%\local64\etc\profile.local
		echo.# /local64/etc/profile.local>>%instdir%\local64\etc\profile.local
		echo.#>>%instdir%\local64\etc\profile.local
		echo.>>%instdir%\local64\etc\profile.local
		echo.alias dir='ls -la --color=auto'>>%instdir%\local64\etc\profile.local
		echo.alias ls='ls --color=auto'>>%instdir%\local64\etc\profile.local
		echo.>>%instdir%\local64\etc\profile.local
		echo.PKG_CONFIG_PATH="/local64/lib/pkgconfig">>%instdir%\local64\etc\profile.local
		echo.CPPFLAGS="-I/local64/include">>%instdir%\local64\etc\profile.local
		echo.CFLAGS="-I/local64/include -mms-bitfields -mthreads">>%instdir%\local64\etc\profile.local
		echo.CXXFLAGS="-I/local64/include -mms-bitfields -mthreads">>%instdir%\local64\etc\profile.local
		echo.LDFLAGS="-L/local64/lib">>%instdir%\local64\etc\profile.local
		echo.export PKG_CONFIG_PATH CPPFLAGS CFLAGS CXXFLAGS LDFLAGS>>%instdir%\local64\etc\profile.local
		echo.>>%instdir%\local64\etc\profile.local
		echo.PATH=".:/local64/bin:/mingw64/bin:/mingw/bin:/bin:/opt/bin:/opt/TortoiseHg">>%instdir%\local64\etc\profile.local
		echo.PS1='\[\033[32m\]\u@\h \[\033[33m\w\033[0m\]$ '>>%instdir%\local64\etc\profile.local
		echo.export PATH PS1>>%instdir%\local64\etc\profile.local
		echo.>>%instdir%\local64\etc\profile.local
		echo.# package build directory>>%instdir%\local64\etc\profile.local
		echo.LOCALBUILDDIR=/build64>>%instdir%\local64\etc\profile.local
		echo.# package installation prefix>>%instdir%\local64\etc\profile.local
		echo.LOCALDESTDIR=/local64>>%instdir%\local64\etc\profile.local
		echo.export LOCALBUILDDIR LOCALDESTDIR>>%instdir%\local64\etc\profile.local
		)
	
:loginProfile
if exist %instdir%\msys\1.0\etc\userprofile.cfg GOTO extraPacks

if %build64%==yes (
	if %build32%==yes GOTO loginProfile32
	echo -------------------------------------------------------------------------------
	echo.
	echo.- write default profile (64 bit)
	echo.
	echo -------------------------------------------------------------------------------
	echo.cat ^>^> /etc/profile ^<^< "EOF">>%instdir%\profile.sh
	echo.if [ -f /local64/etc/profile.local ]; then>>%instdir%\profile.sh
	 echo.       source /local64/etc/profile.local>>%instdir%\profile.sh
	echo.fi>>%instdir%\profile.sh
	echo.>>%instdir%\profile.sh
	echo.EOF>>%instdir%\profile.sh

	%instdir%\msys\1.0\bin\sh -l %instdir%\profile.sh
	echo 64 bit build system add to profile. see profile>>%instdir%\msys\1.0\etc\userprofile.cfg
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
	echo.if [ -f /local32/etc/profile.local ]; then>>%instdir%\profile.sh
	 echo.       source /local32/etc/profile.local>>%instdir%\profile.sh
	echo.fi>>%instdir%\profile.sh
	echo.>>%instdir%\profile.sh
	echo.EOF>>%instdir%\profile.sh

	%instdir%\msys\1.0\bin\sh -l %instdir%\profile.sh
	echo 32 bit build system add to profile. see profile>>%instdir%\msys\1.0\etc\userprofile.cfg
	del %instdir%\profile.sh

:extraPacks
::------------------------------------------------------------------
:: get extra packs and compile global tools:
::------------------------------------------------------------------

if not exist "%instdir%\opt\bin\git.exe" (
	echo.-------------------------------------------------------------------------------
	echo.download and install PortableGit
	echo.-------------------------------------------------------------------------------
	cd %instdir%\opt
	%instdir%\msys\1.0\bin\wget -c "http://msysgit.googlecode.com/files/PortableGit-1.8.3-preview20130601.7z"
	%instdir%\opt\bin\7za x PortableGit-1.8.3-preview20130601.7z -aoa
	%instdir%\msys\1.0\bin\rm git-bash.bat git-cmd.bat "Git Bash.vbs"
	%instdir%\msys\1.0\bin\mv ReleaseNotes.rtf README.portable doc\git
	%instdir%\msys\1.0\bin\rm PortableGit-1.8.3-preview20130601.7z
	cd ..
	)

if not exist "%instdir%\opt\bin\svn.exe" (
	echo.-------------------------------------------------------------------------------
	echo.download and install svn
	echo.-------------------------------------------------------------------------------
	cd %instdir%\opt
	%instdir%\msys\1.0\bin\wget -c "http://downloads.sourceforge.net/project/win32svn/1.8.3/apache22/svn-win32-1.8.3.zip"
	%instdir%\msys\1.0\bin\unzip svn-win32-1.8.3.zip
	%instdir%\msys\1.0\bin\cp -va svn-win32-1.8.3/* .
	%instdir%\msys\1.0\bin\mkdir -p doc\svn-win32-1.8.3
	%instdir%\msys\1.0\bin\mv README.txt doc\svn-win32-1.8.3
	%instdir%\msys\1.0\bin\rm svn-win32-1.8.3.zip
	%instdir%\msys\1.0\bin\rm -r svn-win32-1.8.3
	cd ..
	)

if not exist "%instdir%\opt\bin\cmake.exe" (
	echo.-------------------------------------------------------------------------------
	echo.download and install cmake
	echo.-------------------------------------------------------------------------------
	cd %instdir%\opt
	%instdir%\msys\1.0\bin\wget -c "http://www.cmake.org/files/v2.8/cmake-2.8.11.1-win32-x86.zip"
	%instdir%\msys\1.0\bin\unzip cmake-2.8.11.1-win32-x86.zip
	%instdir%\msys\1.0\bin\cp -va cmake-2.8.11.1-win32-x86/* .
	%instdir%\msys\1.0\bin\rm cmake-2.8.11.1-win32-x86.zip
	%instdir%\msys\1.0\bin\rm -r cmake-2.8.11.1-win32-x86
	cd ..
	)
	
if not exist "%instdir%\opt\TortoiseHg\hg.exe" (
	echo.-------------------------------------------------------------------------------
	echo.download and install TortoiseHg
	echo.-------------------------------------------------------------------------------
	cd %instdir%\opt
	%instdir%\msys\1.0\bin\wget --no-check-certificate -c "https://bitbucket.org/tortoisehg/thg/downloads/tortoisehg-2.4.1-hg-2.2.2-x86.msi"
	msiexec /a tortoisehg-2.4.1-hg-2.2.2-x86.msi /qb TARGETDIR=%instdir%\opt\hg-temp
	%instdir%\msys\1.0\bin\cp -va %instdir%\opt\hg-temp\PFiles\TortoiseHg %instdir%\opt
	%instdir%\msys\1.0\bin\rm tortoisehg-2.4.1-hg-2.2.2-x86.msi
	%instdir%\msys\1.0\bin\rm -r -f %instdir%\opt\hg-temp
	cd ..
	)		

cd %instdir%

:checkDoxygen32	
if %build32%==yes (
	if exist %instdir%\mingw32\bin\doxygen.exe GOTO checkDoxygen64
	cd %instdir%\build32
	%instdir%\msys\1.0\bin\wget -c "http://ftp.stack.nl/pub/users/dimitri/doxygen-1.8.5.windows.bin.zip"
	cd %instdir%\mingw32\bin
	%instdir%\opt\bin\7za x %instdir%\build32\doxygen-1.8.5.windows.bin.zip
	del %instdir%\build32\doxygen-1.8.5.windows.bin.zip
	)
	
:checkDoxygen64
if %build64%==yes (
	if exist %instdir%\mingw64\bin\doxygen.exe GOTO checkYasm32
	cd %instdir%\build64
	%instdir%\msys\1.0\bin\wget -c "http://ftp.stack.nl/pub/users/dimitri/doxygen-1.8.5.windows.x64.bin.zip"
	cd %instdir%\mingw64\bin
	%instdir%\opt\bin\7za x %instdir%\build64\doxygen-1.8.5.windows.x64.bin.zip
	del %instdir%\build64\doxygen-1.8.5.windows.x64.bin.zip
	)
	
:checkYasm32	
if %build32%==yes (
	if exist %instdir%\mingw32\bin\yasm.exe GOTO checkYasm64
	cd %instdir%\build32
	%instdir%\msys\1.0\bin\wget -c "http://www.tortall.net/projects/yasm/releases/yasm-1.2.0-win32.exe"
	ren yasm-1.2.0-win32.exe yasm.exe
	copy yasm.exe %instdir%\mingw32\bin
	del yasm.exe
	)	
	
:checkYasm64	
if %build64%==yes (
	if exist %instdir%\mingw64\bin\yasm.exe GOTO getMintty
	cd %instdir%\build64
	%instdir%\msys\1.0\bin\wget -c "http://www.tortall.net/projects/yasm/releases/yasm-1.2.0-win64.exe"
	ren yasm-1.2.0-win64.exe yasm.exe
	copy yasm.exe %instdir%\mingw64\bin
	del yasm.exe
	)	
cd %instdir%

:getMintty
if exist %instdir%\msys\1.0\bin\mintty.exe GOTO minttySettings
	echo -------------------------------------------------------------------------------
	echo.
	echo.- download and install mintty (a nice shell console tool):
	echo. (it is recommended to don't use the windows cmd, it is not stable)
	echo.
	echo -------------------------------------------------------------------------------
	%instdir%\msys\1.0\bin\wget -c http://blog.pixelcrusher.de/downloads/media-autobuild_suite/mintty-1.1.3-msys.zip
	%instdir%\opt\bin\7za.exe e -r -y %instdir%\mintty-1.1.3-msys.zip -o%instdir%\msys\1.0\bin mintty.exe
	%instdir%\opt\bin\7za.exe e -r -y %instdir%\mintty-1.1.3-msys.zip -o%instdir%\msys\1.0\share\doc readme-msys.html
	
	for /f %%i in ('dir %instdir%\msys\1.0\home /B') do set userFolder=%%i
	
	echo.Set Shell = CreateObject^("WScript.Shell"^)>>%instdir%\setlink.vbs
	echo.Set link = Shell.CreateShortcut^("%instdir%\mintty.lnk"^)>>%instdir%\setlink.vbs
	echo.link.Arguments = "/bin/sh -l" >>%instdir%\setlink.vbs
	echo.link.Description = "msys shell console">>%instdir%\setlink.vbs
	echo.link.TargetPath = "%instdir%\msys\1.0\bin\mintty.exe">>%instdir%\setlink.vbs
	echo.link.WindowStyle = ^1>>%instdir%\setlink.vbs
	echo.link.WorkingDirectory = "%instdir%\msys\1.0\bin">>%instdir%\setlink.vbs
	echo.link.Save>>%instdir%\setlink.vbs

	cscript /nologo %instdir%\setlink.vbs 
	del %instdir%\mintty-1.1.3-msys.zip 
	del %instdir%\setlink.vbs 
	
::mintty seetings, color, transparency, etc.
:minttySettings
if exist %instdir%\msys\1.0\home\%userFolder%\.minttyrc GOTO compileGlobals
	echo.BoldAsFont=no>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.BackgroundColour=57,57,57>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.ForegroundColour=221,221,221>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.Transparency=medium>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.FontHeight=^9>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.FontSmoothing=full>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.AllowBlinking=yes>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.Font=DejaVu Sans Mono>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.Columns=90>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.Rows=30>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.Locale=de_DE>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.Charset=ISO-8859-1>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.Term=xterm-256color>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.CursorType=block>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.Black=38,39,41>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.Red=249,38,113>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.Green=166,226,46>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.Yellow=253,151,31>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.Blue=102,217,239>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.Magenta=158,111,254>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.Cyan=94,113,117>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.White=248,248,242>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.BoldBlack=85,68,68>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.BoldRed=249,38,113>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.BoldGreen=166,226,46>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.BoldYellow=253,151,31>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.BoldBlue=102,217,239>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.BoldMagenta=158,111,254>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.BoldCyan=163,186,191>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc
	echo.BoldWhite=248,248,242>>%instdir%\msys\1.0\home\%userFolder%\.minttyrc

:compileGlobals
if exist %instdir%\compile_globaltools.sh GOTO compileGobal
	echo -------------------------------------------------------------------------------
	echo.
	echo.- get script for global tools:
	echo.
	echo -------------------------------------------------------------------------------
	if exist %instdir%\media-autobuild_suite.zip GOTO unpackglobal
		%instdir%\msys\1.0\bin\wget --no-check-certificate -c -O media-autobuild_suite.zip https://github.com/jb-alvarado/media-autobuild_suite/archive/master.zip
		
		:unpackglobal
		%instdir%\opt\bin\7za.exe e -r -y %instdir%\media-autobuild_suite.zip -o%instdir% compile_globaltools.sh

:compileGobal
echo -------------------------------------------------------------------------------
echo.
echo.- compile global tools:
echo.
echo -------------------------------------------------------------------------------
%instdir%\mintty.lnk %instdir%\compile_globaltools.sh --cpuCount=%cpuCount% --build32=%build32% --build64=%build64% --qt4=%qt4%
echo. compile global tools done...

:: audio tools
if exist %instdir%\compile_audiotools.sh GOTO compileAudio
	echo -------------------------------------------------------------------------------
	echo.
	echo.- get script for audio tools:
	echo.
	echo -------------------------------------------------------------------------------
	if exist %instdir%\media-autobuild_suite.zip GOTO unpackAudio
		%instdir%\msys\1.0\bin\wget --no-check-certificate -c -O media-autobuild_suite.zip https://github.com/jb-alvarado/media-autobuild_suite/archive/master.zip
	
		:unpackAudio
		%instdir%\opt\bin\7za.exe e -r -y %instdir%\media-autobuild_suite.zip -o%instdir% compile_audiotools.sh

:compileAudio
echo -------------------------------------------------------------------------------
echo.
echo.- compile audio tools:
echo.
echo -------------------------------------------------------------------------------
%instdir%\mintty.lnk %instdir%\compile_audiotools.sh --cpuCount=%cpuCount% --build32=%build32% --build64=%build64% --nonfree=%binary%
echo. compile audio tools done...

:: video tools
if not exist %instdir%\compile_videotools.sh (
	echo -------------------------------------------------------------------------------
	echo.
	echo.- get script for video tools:
	echo.
	echo -------------------------------------------------------------------------------
	if not exist %instdir%\media-autobuild_suite.zip (
		%instdir%\msys\1.0\bin\wget --no-check-certificate -c -O media-autobuild_suite.zip https://github.com/jb-alvarado/media-autobuild_suite/archive/master.zip
		)
		%instdir%\opt\bin\7za.exe e -r -y %instdir%\media-autobuild_suite.zip -o%instdir% compile_videotools.sh
	)

echo -------------------------------------------------------------------------------
echo.
echo.- compile video tools:
echo.
echo -------------------------------------------------------------------------------
%instdir%\mintty.lnk %instdir%\compile_videotools.sh --cpuCount=%cpuCount% --build32=%build32% --build64=%build64% --mp4box=%mp4box% --ffmpeg=%ffmpeg% --mplayer=%mplayer% --vlc=%vlc% --nonfree=%binary%
echo. compile video tools done...
	
::imagemagick	
if %magick%==y (
		if not exist %instdir%\compile_imagetools.sh (
			echo -------------------------------------------------------------------------------
			echo.
			echo.- get script for image tools:
			echo.
			echo -------------------------------------------------------------------------------
			if not exist %instdir%\media-autobuild_suite.zip (
				%instdir%\msys\1.0\bin\wget --no-check-certificate -c -O media-autobuild_suite.zip https://github.com/jb-alvarado/media-autobuild_suite/archive/master.zip
				)
				%instdir%\opt\bin\7za.exe e -r -y %instdir%\media-autobuild_suite.zip -o%instdir% compile_imagetools.sh
			)

		echo -------------------------------------------------------------------------------
		echo.
		echo.- compile image tools:
		echo.
		echo -------------------------------------------------------------------------------
		%instdir%\mintty.lnk %instdir%\compile_imagetools.sh --cpuCount=%cpuCount% --build32=%build32% --build64=%build64%
		echo. compile image tools done...
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
