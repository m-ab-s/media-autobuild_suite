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
::	This is version 2.52
::	Project stared at 2013-09-24. Last bigger modification was on 2014-05-27
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
::	2014-04-26 change many libs and tools to native mingw libs, fix new compiler options
::	2014-04-27 use more tools from the compiler, fix options. most work at the moment but no mediainfo and no ffmpeg
::	2014-04-28 all 32 bit tools runing now, 64 bit need to be tested, x265 doesn't work at the moment and also no mediainfo
::	2014-04-29 fix mp4box, test 64 builds, add ffmpeg extra flags to the configure file. mediainfo not work for now and x265 only works in 64 bit
::	2014-05-01 change compiler build and target infos to the profile
::	2014-05-05 fix mediainfo 32 bit, remove un-needed code, simplify code, update versions from mediainfo; freetype; freebidi; fontconfig, remove libthread. x265 32 bit works
::	2014-05-06 make vpxenc static again. Now all working normal as it was in msys1
::	2014-05-07 remove external python and use internal, add some variables to the profile: for info, man and new python, add kvazaar h265 encoder
::	2014-05-12 no need for fribidi patch and sed, change libass to git download
::	2014-05-13 fix fdkaac bin, new msys32 download link
::	2014-05-14 fix issues with windows xp and fix wget download
::	2014-05-15 change cc and python alias, add mediainfo 64 bit, remove pdflatex
::	2014-05-17 change git download depth to 1, add sed for kvazaar
::	2014-05-18 simplify git clone/updates, merge audio tools and video tools to local tools.
::	2014-05-20 copy openjpeg.h to include folder, fix git download for vpx, remove external mercurial and using internal, remove opt folder and using p7zip internal
::	2014-05-21 add hg.bat, change opus version and add ffmpeg shared
::	2014-05-23 add update function to ffmpeg when a lib get a new update
::	2014-05-27 merge global and local tools and sort bin folders
::	2014-05-28 add mpg123, change wget.zip
::	2014-05-30 change libdvdcss and libdvdread to git, update libcrypt: gnutls; libcaca; libmodplug
::	2014-06-01 add openAL and exiv2
::	2014-06-12 fix kvazaar and vpxenc.exe 32 bit
::
::-------------------------------------------------------------------------------------

@echo off
color 80
title media-autobuild_suite

set instdir=%CD%
set "ini=media-autobuild_suite.ini"

:selectmsys2Arch
if exist %ini% GOTO msysset
	echo -------------------------------------------------------------------------------
	echo -------------------------------------------------------------------------------
	echo.
	echo. Select the msys2 system:
	echo. 1 = 32 bit msys2
	echo. 2 = 64 bit msys2 [recommended]
	echo.
	echo -------------------------------------------------------------------------------
	echo -------------------------------------------------------------------------------
	set /P msys2Arch="msys2 system:"
	if %msys2Arch% GTR 2 GOTO selectmsys2Arch
	
	echo.[compiler list]>>%ini%
	echo.msys2Arch=^%msys2Arch%>>%ini%
	echo.arch=^0>>%ini%
	echo.free=^0>>%ini%
	echo.ffmpegB=^0>>%ini%
	echo.ffmpegUpdate=^0>>%ini%
	echo.mp4box=^0>>%ini%
	echo.mplayer=^0>>%ini%
	echo.cores=^0>>%ini%
	echo.deleteSource=^0>>%ini%
	echo.strip=^0>>%ini%

:msysset	
for /F "tokens=2 delims==" %%a in ('findstr /i msys2Arch %ini%') do set msys2ArchINI=%%a
for /F "tokens=2 delims==" %%j in ('findstr /i arch %ini%') do set archINI=%%j
for /F "tokens=2 delims==" %%b in ('findstr /i free %ini%') do set freeINI=%%b
for /F "tokens=2 delims==" %%f in ('findstr /i ffmpegB %ini%') do set ffmpegINI=%%f
for /F "tokens=2 delims==" %%c in ('findstr /i ffmpegUpdate %ini%') do set ffmpegUpdateINI=%%c
for /F "tokens=2 delims==" %%d in ('findstr /i mp4box %ini%') do set mp4boxINI=%%d
for /F "tokens=2 delims==" %%e in ('findstr /i mplayer %ini%') do set mplayerINI=%%e
for /F "tokens=2 delims==" %%h in ('findstr /i cores %ini%') do set coresINI=%%h
for /F "tokens=2 delims==" %%i in ('findstr /i deleteSource %ini%') do set deleteSourceINI=%%i
for /F "tokens=2 delims==" %%k in ('findstr /i strip %ini%') do set stripINI=%%k

set msys2Arch=%msys2ArchINI%
if %msys2Arch%==1 (
	set "msys2=msys32"
	)
if %msys2Arch%==2 (
	set "msys2=msys64"
	)

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
	echo. Build ffmpeg binary:
	echo. 1 = yes [static]
	echo. 2 = no
	echo. 3 = shared
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
	set "ffmpeg=s"
	)
if %buildffmpeg% GTR 3 GOTO ffmpeg

:ffmpegUp
if %ffmpegUpdateINI%==0 (
	echo -------------------------------------------------------------------------------
	echo -------------------------------------------------------------------------------
	echo.
	echo. Build ffmpeg new when lib has updated:
	echo. 1 = yes
	echo. 2 = no
	echo.
	echo -------------------------------------------------------------------------------
	echo -------------------------------------------------------------------------------
	set /P buildffmpegUp="build ffmpeg if lib is new:"
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
if exist "%instdir%\%msys2%" GOTO getMintty
	echo -------------------------------------------------------------
	echo.
	echo - Download wget
	echo.
	echo -------------------------------------------------------------
	if exist "%instdir%\install-wget" del "%instdir%\install-wget.js"
	
	echo.var wshell = new ActiveXObject("WScript.Shell"); var xmlhttp = new ActiveXObject("MSXML2.ServerXMLHTTP"); var adodb = new ActiveXObject("ADODB.Stream"); var FSO = new ActiveXObject("Scripting.FileSystemObject"); function http_get(url, is_binary) {xmlhttp.open("GET", url); xmlhttp.send(); WScript.echo("retrieving " + url); while (xmlhttp.readyState != 4); WScript.Sleep(10); if (xmlhttp.status != 200) {WScript.Echo("http get failed: " + xmlhttp.status); WScript.Quit(2)}; return is_binary ? xmlhttp.responseBody : xmlhttp.responseText}; function save_binary(path, data) {adodb.type = 1; adodb.open(); adodb.write(data); adodb.saveToFile(path, 2)}; function download_wget() {var base_url = "http://blog.pixelcrusher.de/downloads/media-autobuild_suite/wget.zip"; var filename = "wget.zip"; var installer_data = http_get(base_url, true); save_binary(filename, installer_data); return FSO.GetAbsolutePathName(filename)}; function extract_zip(zip_file, dstdir) {var shell = new ActiveXObject("shell.application"); var dst = shell.NameSpace(dstdir); var zipdir = shell.NameSpace(zip_file); dst.CopyHere(zipdir.items(), 0)}; function install_wget(zip_file) {var rootdir = wshell.CurrentDirectory; extract_zip(zip_file, rootdir)}; install_wget(download_wget())>>"%instdir%\install-wget.js"

	cscript "%instdir%\install-wget.js"
	del "%instdir%\install-wget.js"
	del "%instdir%\wget.zip"
	del "%instdir%\wget_COPYING.txt"
	del "%instdir%\wget_README.txt"
	
:check7zip
if exist "%instdir%\opt\bin\7za.exe" GOTO checkmsys2
	echo -------------------------------------------------------------
	echo.
	echo - Download and install 7zip
	echo.
	echo.
	echo -------------------------------------------------------------
	if not exist "%instdir%\%msys2%\bin\wget.exe" GOTO get7zip
	"%instdir%\%msys2%\bin\wget.exe" --tries=20 --retry-connrefused --waitretry=2 -c -P "%instdir%" "http://blog.pixelcrusher.de/downloads/media_compressor/7za920.exe"
	GOTO install7zip
	
	:get7zip
	"%instdir%\wget" --tries=20 --retry-connrefused --waitretry=2 -c -P "%instdir%" "http://blog.pixelcrusher.de/downloads/media_compressor/7za920.exe"
	
	:install7zip
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
if %msys2%==msys32 (
if exist "%instdir%\%msys2%\msys2_shell.bat" GOTO getMintty
	echo -------------------------------------------------------------------------------
	echo.
	echo.- Download and install msys2 basic system
	echo.
	echo -------------------------------------------------------------------------------
	
	"%instdir%\wget" --tries=20 --retry-connrefused --waitretry=2 --no-check-certificate -c -P "%instdir%" -O msys2-base.tar.xz "https://downloads.sourceforge.net/project/msys2/Base/i686/msys2-base-i686-20140507.tar.xz"
	
	%instdir%\opt\bin\7za.exe x msys2-base.tar.xz
	%instdir%\opt\bin\7za.exe x msys2-base.tar
	del msys2-base.tar.xz
	del msys2-base.tar
	if not exist %instdir%\%msys2%\bin\msys-2.0.dll (
		echo -------------------------------------------------------------------------------
		echo.
		echo.- Download from msys2 32 bit basic system failed, 
		echo.- please download it manuel from:
		echo.- http://downloads.sourceforge.net/project/msys2
		echo.- and copy the uncompressed folder to:
		echo.- %instdir%
		echo.- and start the batch script again!
		echo.
		echo -------------------------------------------------------------------------------
		pause
		)
	del wget.exe
	)
	
if %msys2%==msys64 (
if exist "%instdir%\%msys2%\msys2_shell.bat" GOTO getMintty
	echo -------------------------------------------------------------------------------
	echo.
	echo.- Download and install msys2 basic system
	echo.
	echo -------------------------------------------------------------------------------
	
	"%instdir%\wget" --tries=20 --retry-connrefused --waitretry=2 -c -P "%instdir%" -O msys2-base.tar.xz "http://sourceforge.net/projects/msys2/files/latest/download?source=files"
	
	%instdir%\opt\bin\7za.exe x msys2-base.tar.xz
	%instdir%\opt\bin\7za.exe x msys2-base.tar
	del msys2-base.tar.xz
	del msys2-base.tar
	del wget.exe
	)
	
:getMintty
if exist %instdir%\mintty.lnk GOTO minttySettings
	echo -------------------------------------------------------------------------------
	echo.
	echo.- set mintty shell shortcut and make a first run
	echo.
	echo -------------------------------------------------------------------------------
	
	echo.Set Shell = CreateObject^("WScript.Shell"^)>>%instdir%\setlink.vbs
	echo.Set link = Shell.CreateShortcut^("%instdir%\mintty.lnk"^)>>%instdir%\setlink.vbs
	echo.link.Arguments = "/bin/sh -l" >>%instdir%\setlink.vbs
	echo.link.Description = "msys2 shell console">>%instdir%\setlink.vbs
	echo.link.TargetPath = "%instdir%\%msys2%\bin\mintty.exe">>%instdir%\setlink.vbs
	echo.link.WindowStyle = ^1>>%instdir%\setlink.vbs
	echo.link.WorkingDirectory = "%instdir%\%msys2%\bin">>%instdir%\setlink.vbs
	echo.link.Save>>%instdir%\setlink.vbs

	cscript /nologo %instdir%\setlink.vbs 
	del %instdir%\setlink.vbs 	

	echo.sleep ^5>>firstrun.sh
	echo.exit>>firstrun.sh
	%instdir%\%msys2%\bin\mintty.exe /bin/sh -l %instdir%\firstrun.sh
	del firstrun.sh
	
:minttySettings
for /f %%i in ('dir %instdir%\%msys2%\home /B') do set userFolder=%%i
if exist %instdir%\%msys2%\home\%userFolder%\.minttyrc GOTO hgsettings

	echo.BoldAsFont=no>>%instdir%\%msys2%\home\%userFolder%\.minttyrc
	echo.BackgroundColour=57,57,57>>%instdir%\%msys2%\home\%userFolder%\.minttyrc
	echo.ForegroundColour=221,221,221>>%instdir%\%msys2%\home\%userFolder%\.minttyrc
	echo.Transparency=medium>>%instdir%\%msys2%\home\%userFolder%\.minttyrc
	echo.FontHeight=^9>>%instdir%\%msys2%\home\%userFolder%\.minttyrc
	echo.FontSmoothing=full>>%instdir%\%msys2%\home\%userFolder%\.minttyrc
	echo.AllowBlinking=yes>>%instdir%\%msys2%\home\%userFolder%\.minttyrc
	echo.Font=DejaVu Sans Mono>>%instdir%\%msys2%\home\%userFolder%\.minttyrc
	echo.Columns=90>>%instdir%\%msys2%\home\%userFolder%\.minttyrc
	echo.Rows=30>>%instdir%\%msys2%\home\%userFolder%\.minttyrc
	echo.Term=xterm-256color>>%instdir%\%msys2%\home\%userFolder%\.minttyrc
	echo.CursorType=block>>%instdir%\%msys2%\home\%userFolder%\.minttyrc
	echo.Black=38,39,41>>%instdir%\%msys2%\home\%userFolder%\.minttyrc
	echo.Red=249,38,113>>%instdir%\%msys2%\home\%userFolder%\.minttyrc
	echo.Green=166,226,46>>%instdir%\%msys2%\home\%userFolder%\.minttyrc
	echo.Yellow=253,151,31>>%instdir%\%msys2%\home\%userFolder%\.minttyrc
	echo.Blue=102,217,239>>%instdir%\%msys2%\home\%userFolder%\.minttyrc
	echo.Magenta=158,111,254>>%instdir%\%msys2%\home\%userFolder%\.minttyrc
	echo.Cyan=94,113,117>>%instdir%\%msys2%\home\%userFolder%\.minttyrc
	echo.White=248,248,242>>%instdir%\%msys2%\home\%userFolder%\.minttyrc
	echo.BoldBlack=85,68,68>>%instdir%\%msys2%\home\%userFolder%\.minttyrc
	echo.BoldRed=249,38,113>>%instdir%\%msys2%\home\%userFolder%\.minttyrc
	echo.BoldGreen=166,226,46>>%instdir%\%msys2%\home\%userFolder%\.minttyrc
	echo.BoldYellow=253,151,31>>%instdir%\%msys2%\home\%userFolder%\.minttyrc
	echo.BoldBlue=102,217,239>>%instdir%\%msys2%\home\%userFolder%\.minttyrc
	echo.BoldMagenta=158,111,254>>%instdir%\%msys2%\home\%userFolder%\.minttyrc
	echo.BoldCyan=163,186,191>>%instdir%\%msys2%\home\%userFolder%\.minttyrc
	echo.BoldWhite=248,248,242>>%instdir%\%msys2%\home\%userFolder%\.minttyrc
	
:hgsettings
for /f %%i in ('dir %instdir%\%msys2%\home /B') do set userFolder=%%i
if exist %instdir%\%msys2%\home\%userFolder%\.hgrc GOTO updatebase
	echo.[ui]>>%instdir%\%msys2%\home\%userFolder%\.hgrc
	echo.username = %userFolder%>>%instdir%\%msys2%\home\%userFolder%\.hgrc
	echo.verbose = True>>%instdir%\%msys2%\home\%userFolder%\.hgrc
	echo.editor = vim>>%instdir%\%msys2%\home\%userFolder%\.hgrc
	echo.>>%instdir%\%msys2%\home\%userFolder%\.hgrc
	echo.[web]>>%instdir%\%msys2%\home\%userFolder%\.hgrc
	echo.cacerts=/usr/ssl/cert.pem>>%instdir%\%msys2%\home\%userFolder%\.hgrc
	echo.>>%instdir%\%msys2%\home\%userFolder%\.hgrc
	echo.[extensions]>>%instdir%\%msys2%\home\%userFolder%\.hgrc
	echo.color =>>%instdir%\%msys2%\home\%userFolder%\.hgrc
	echo.>>%instdir%\%msys2%\home\%userFolder%\.hgrc
	echo.[color]>>%instdir%\%msys2%\home\%userFolder%\.hgrc
	echo.status.modified = magenta bold>>%instdir%\%msys2%\home\%userFolder%\.hgrc
	echo.status.added = green bold>>%instdir%\%msys2%\home\%userFolder%\.hgrc
	echo.status.removed = red bold>>%instdir%\%msys2%\home\%userFolder%\.hgrc
	echo.status.deleted = cyan bold>>%instdir%\%msys2%\home\%userFolder%\.hgrc
	echo.status.unknown = blue bold>>%instdir%\%msys2%\home\%userFolder%\.hgrc
	echo.status.ignored = black bold>>%instdir%\%msys2%\home\%userFolder%\.hgrc

:updatebase
echo.-------------------------------------------------------------------------------
echo.updating msys2 system
echo.-------------------------------------------------------------------------------
if exist %instdir%\updateMSYS2.sh del %instdir%\updateMSYS2.sh
echo.echo -ne "\033]0;update msys2 system\007">>updateMSYS2.sh
echo.pacman --noconfirm -Sy>>updateMSYS2.sh
echo.pacman --noconfirm -Su>>updateMSYS2.sh
echo.echo "-------------------------------------------------------------------------------">>updateMSYS2.sh
echo.echo "updating msys2 done...">>updateMSYS2.sh
echo.echo "-------------------------------------------------------------------------------">>updateMSYS2.sh
echo.sleep ^3>>updateMSYS2.sh
echo.exit>>updateMSYS2.sh
%instdir%\%msys2%\bin\mintty.exe /bin/sh -l %instdir%\updateMSYS2.sh
del updateMSYS2.sh

:installbase
if exist %instdir%\%msys2%\bin\make.exe GOTO sethgBat
	echo.-------------------------------------------------------------------------------
	echo.install msys2 base system
	echo.-------------------------------------------------------------------------------
	if exist %instdir%\pacman.sh del %instdir%\pacman.sh
	echo.echo -ne "\033]0;install base system\007">>pacman.sh
	echo.pacman --noconfirm -S asciidoc autoconf autoconf2.13 automake-wrapper automake1.10 automake1.11 automake1.12 automake1.13 automake1.14 automake1.6 automake1.7 automake1.8 automake1.9 autogen bison diffstat diffutils dos2unix flex groff help2man intltool libtool m4 man patch pkg-config scons xmlto make tar zip unzip git subversion wget p7zip mercurial>>pacman.sh
	echo.sleep ^3>>pacman.sh
	echo.exit>>pacman.sh
	%instdir%\%msys2%\bin\mintty.exe /bin/sh -l %instdir%\pacman.sh
	del pacman.sh
	rd /s/q opt

:sethgBat
if exist %instdir%\%msys2%\bin\hg.bat GOTO getmingw32
echo.@echo off>>%instdir%\%msys2%\bin\hg.bat
echo.>>%instdir%\%msys2%\bin\hg.bat
echo.setlocal>>%instdir%\%msys2%\bin\hg.bat
echo.set HG=^%%~f0>>%instdir%\%msys2%\bin\hg.bat
echo.>>%instdir%\%msys2%\bin\hg.bat
echo.set PYTHONHOME=>>%instdir%\%msys2%\bin\hg.bat
echo.set in=^%%*>>%instdir%\%msys2%\bin\hg.bat
echo.set out=^%%in: ^{= ^"^{^%%>>%instdir%\%msys2%\bin\hg.bat
echo.set out=^%%out:^} =^}^" ^%%>>%instdir%\%msys2%\bin\hg.bat
echo.>>%instdir%\%msys2%\bin\hg.bat
echo.^%%~dp0python2 ^%%~dp0hg ^%%out^%%>>%instdir%\%msys2%\bin\hg.bat


:getmingw32
if %build32%==yes (
if exist %instdir%\%msys2%\mingw32\bin\gcc.exe GOTO getmingw64
	echo.-------------------------------------------------------------------------------
	echo.install 32 bit compiler
	echo.-------------------------------------------------------------------------------
	if exist %instdir%\mingw32.sh del %instdir%\mingw32.sh
	echo.echo -ne "\033]0;install 32 bit compiler\007">>mingw32.sh
	echo.pacman --noconfirm -S mingw-w64-i686-cloog mingw-w64-i686-cmake mingw-w64-i686-crt-git mingw-w64-i686-doxygen mingw-w64-i686-gcc mingw-w64-i686-gcc-ada mingw-w64-i686-gcc-fortran mingw-w64-i686-gcc-libgfortran mingw-w64-i686-gcc-libs mingw-w64-i686-gcc-objc mingw-w64-i686-gettext mingw-w64-i686-glew mingw-w64-i686-gmp mingw-w64-i686-headers-git mingw-w64-i686-libiconv mingw-w64-i686-mpc mingw-w64-i686-winpthreads-git mingw-w64-i686-yasm mingw-w64-i686-lcms2 mingw-w64-i686-libtiff mingw-w64-i686-libpng mingw-w64-i686-libjpeg mingw-w64-i686-gsm mingw-w64-i686-lame mingw-w64-i686-libogg mingw-w64-i686-libvorbis mingw-w64-i686-xvidcore mingw-w64-i686-sqlite3 mingw-w64-i686-dlfcn mingw-w64-i686-jasper>>mingw32.sh
	echo.sleep ^3>>mingw32.sh
	echo.exit>>mingw32.sh
	%instdir%\%msys2%\bin\mintty.exe /bin/sh -l %instdir%\mingw32.sh
	del mingw32.sh
	)

:getmingw64	
if %build64%==yes (
if exist %instdir%\%msys2%\mingw64\bin\gcc.exe GOTO checkdyn
	echo.-------------------------------------------------------------------------------
	echo.install 64 bit compiler
	echo.-------------------------------------------------------------------------------
	if exist %instdir%\mingw64.sh del %instdir%\mingw64.sh
	echo.echo -ne "\033]0;install 64 bit compiler\007">>mingw64.sh
	echo.pacman --noconfirm -S mingw-w64-x86_64-cloog mingw-w64-x86_64-cmake mingw-w64-x86_64-crt-git mingw-w64-x86_64-doxygen mingw-w64-x86_64-gcc mingw-w64-x86_64-gcc-ada mingw-w64-x86_64-gcc-fortran mingw-w64-x86_64-gcc-libgfortran mingw-w64-x86_64-gcc-libs mingw-w64-x86_64-gcc-objc mingw-w64-x86_64-gettext mingw-w64-x86_64-glew mingw-w64-x86_64-gmp mingw-w64-x86_64-headers-git mingw-w64-x86_64-libiconv mingw-w64-x86_64-mpc mingw-w64-x86_64-winpthreads-git mingw-w64-x86_64-yasm mingw-w64-x86_64-lcms2 mingw-w64-x86_64-libtiff mingw-w64-x86_64-libpng mingw-w64-x86_64-libjpeg mingw-w64-x86_64-gsm mingw-w64-x86_64-lame mingw-w64-x86_64-libogg mingw-w64-x86_64-libvorbis mingw-w64-x86_64-xvidcore mingw-w64-x86_64-sqlite3 mingw-w64-x86_64-dlfcn mingw-w64-x86_64-jasper>>mingw64.sh
	echo.sleep ^3>>mingw64.sh
	echo.exit>>mingw64.sh
	%instdir%\%msys2%\bin\mintty.exe /bin/sh -l %instdir%\mingw64.sh
	del mingw64.sh
	)

:checkdyn
echo.-------------------------------------------------------------------------------
echo.check for dynamic libs
echo.-------------------------------------------------------------------------------

Setlocal EnableDelayedExpansion

if %build32%==yes (
if exist %instdir%\%msys2%\mingw32\lib\xvidcore.dll.a (
	del %instdir%\%msys2%\mingw32\bin\xvidcore.dll
	%instdir%\%msys2%\bin\mv %instdir%\%msys2%\mingw32\lib\xvidcore.a %instdir%\%msys2%\mingw32\lib\libxvidcore.a
	%instdir%\%msys2%\bin\mv %instdir%\%msys2%\mingw32\lib\xvidcore.dll.a %instdir%\%msys2%\mingw32\lib\xvidcore.dll.a.dyn
	)

	FOR /R "%instdir%\%msys2%\mingw32" %%C IN (*.dll.a) DO (
		set file=%%C
		set name=!file:~0,-6!
		if exist %%C.dyn del %%C.dyn
		if exist !name!.a (
			%instdir%\%msys2%\bin\mv %%C %%C.dyn
			)
		)
	)

if %build64%==yes (
if exist %instdir%\%msys2%\mingw64\lib\xvidcore.dll.a (
	del %instdir%\%msys2%\mingw64\bin\xvidcore.dll
	%instdir%\%msys2%\bin\mv %instdir%\%msys2%\mingw64\lib\xvidcore.a %instdir%\%msys2%\mingw64\lib\libxvidcore.a
	%instdir%\%msys2%\bin\mv %instdir%\%msys2%\mingw64\lib\xvidcore.dll.a %instdir%\%msys2%\mingw64\lib\xvidcore.dll.a.dyn
	)

	FOR /R "%instdir%\%msys2%\mingw64" %%C IN (*.dll.a) DO (
		set file=%%C
		set name=!file:~0,-6!
		if exist %%C.dyn del %%C.dyn
		if exist !name!.a (
			%instdir%\%msys2%\bin\mv %%C %%C.dyn
			)
		)
	)
	
Setlocal DisableDelayedExpansion

if %build32%==yes (
	if not exist %instdir%\build32 mkdir %instdir%\build32
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
		mkdir %instdir%\local32\uninstall
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
		mkdir %instdir%\local64\bin-audio
		mkdir %instdir%\local64\bin-global
		mkdir %instdir%\local64\bin-video
		mkdir %instdir%\local64\etc
		mkdir %instdir%\local64\include
		mkdir %instdir%\local64\lib
		mkdir %instdir%\local64\lib\pkgconfig
		mkdir %instdir%\local64\share
		mkdir %instdir%\local64\uninstall
		)
	)
	
:writeConfFile
if exist %instdir%\%msys2%\etc\fstabconf.cfg GOTO writeProfile32
	echo.>>%instdir%\%msys2%\etc\fstab.
	echo.%instdir%\opt\ /opt>>%instdir%\%msys2%\etc\fstab.
	echo.%instdir%\local32\ /local32>>%instdir%\%msys2%\etc\fstab.
	echo.%instdir%\build32\ /build32>>%instdir%\%msys2%\etc\fstab.
	echo.%instdir%\%msys2%\mingw32\ /mingw32>>%instdir%\%msys2%\etc\fstab.
	echo.%instdir%\local64\ /local64>>%instdir%\%msys2%\etc\fstab.
	echo.%instdir%\build64\ /build64>>%instdir%\%msys2%\etc\fstab.
	echo.%instdir%\%msys2%\mingw64\ /mingw64>>%instdir%\%msys2%\etc\fstab.
	echo.new mount done. see in fstab>> %instdir%\%msys2%\etc\fstabconf.cfg

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
		echo.alias CC='/mingw32/bin/gcc.exe'>>%instdir%\local32\etc\profile.local
		echo.alias python='/usr/bin/python2.exe'>>%instdir%\local32\etc\profile.local
		echo.>>%instdir%\local32\etc\profile.local
		echo.MSYS2_PATH="/usr/local/bin:/usr/bin">>%instdir%\local32\etc\profile.local
		echo.MANPATH="/usr/share/man:/mingw32/share/man:/local32/man:/local32/share/man">>%instdir%\local32\etc\profile.local
		echo.INFOPATH="/usr/local/info:/usr/share/info:/usr/info:/mingw32/share/info">>%instdir%\local32\etc\profile.local
		echo.>>%instdir%\local32\etc\profile.local
		echo.MSYSTEM=MINGW32>>%instdir%\local32\etc\profile.local
		echo.>>%instdir%\local32\etc\profile.local
		echo.PKG_CONFIG_PATH="/mingw32/lib/pkgconfig:/local32/lib/pkgconfig">>%instdir%\local32\etc\profile.local
		echo.CPPFLAGS="-I/local32/include">>%instdir%\local32\etc\profile.local
		echo.CFLAGS="-I/local32/include -mms-bitfields -mthreads -mtune=pentium3">>%instdir%\local32\etc\profile.local
		echo.CXXFLAGS="-I/local32/include -mms-bitfields -mthreads -mtune=pentium3">>%instdir%\local32\etc\profile.local
		echo.LDFLAGS="-L/local32/lib -mthreads">>%instdir%\local32\etc\profile.local
		echo.export PKG_CONFIG_PATH CPPFLAGS CFLAGS CXXFLAGS LDFLAGS MSYSTEM>>%instdir%\local32\etc\profile.local
		echo.>>%instdir%\local32\etc\profile.local
		echo.PYTHONHOME=/usr>>%instdir%\local32\etc\profile.local
		echo.PYTHONPATH="/usr/lib/python2.7:/usr/lib/python2.7/Tools/Scripts">>%instdir%\local32\etc\profile.local
		echo.>>%instdir%\local32\etc\profile.local
		echo.PATH=".:/local32/bin-audio:/local32/bin-global:/local32/bin-video:/local32/bin:/mingw32/bin:${MSYS2_PATH}:${INFOPATH}:${PYTHONHOME}:${PYTHONPATH}">>%instdir%\local32\etc\profile.local
		echo.PS1='\[\033[32m\]\u@\h \[\033[33m\w\033[0m\]$ '>>%instdir%\local32\etc\profile.local
		echo.export PATH PS1>>%instdir%\local32\etc\profile.local
		echo.>>%instdir%\local32\etc\profile.local
		echo.# package build directory>>%instdir%\local32\etc\profile.local
		echo.LOCALBUILDDIR=/build32>>%instdir%\local32\etc\profile.local
		echo.# package installation prefix>>%instdir%\local32\etc\profile.local
		echo.LOCALDESTDIR=/local32>>%instdir%\local32\etc\profile.local
		echo.export LOCALBUILDDIR LOCALDESTDIR>>%instdir%\local32\etc\profile.local
		echo.>>%instdir%\local32\etc\profile.local
		echo.bits='32bit'>>%instdir%\local32\etc\profile.local
		echo.targetBuild='i686-w64-mingw32'>>%instdir%\local32\etc\profile.local
		echo.targetHost='i686-w64-mingw32'>>%instdir%\local32\etc\profile.local
		echo.cross='i686-w64-mingw32-'>>%instdir%\local32\etc\profile.local
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
		echo.alias CC='/mingw64/bin/gcc.exe'>>%instdir%\local64\etc\profile.local
		echo.alias python='/usr/bin/python2.exe'>>%instdir%\local64\etc\profile.local
		echo.>>%instdir%\local64\etc\profile.local
		echo.MSYS2_PATH="/usr/local/bin:/usr/bin">>%instdir%\local64\etc\profile.local
		echo.MANPATH="/usr/share/man:/mingw64/share/man:/local64/man:/local64/share/man">>%instdir%\local64\etc\profile.local
		echo.INFOPATH="/usr/local/info:/usr/share/info:/usr/info:/mingw64/share/info">>%instdir%\local64\etc\profile.local
		echo.>>%instdir%\local64\etc\profile.local
		echo.MSYSTEM=MINGW32>>%instdir%\local64\etc\profile.local
		echo.>>%instdir%\local64\etc\profile.local
		echo.PKG_CONFIG_PATH="/mingw64/lib/pkgconfig:/local64/lib/pkgconfig">>%instdir%\local64\etc\profile.local
		echo.CPPFLAGS="-I/local64/include">>%instdir%\local64\etc\profile.local
		echo.CFLAGS="-I/local64/include -mms-bitfields -mthreads">>%instdir%\local64\etc\profile.local
		echo.CXXFLAGS="-I/local64/include -mms-bitfields -mthreads">>%instdir%\local64\etc\profile.local
		echo.LDFLAGS="-L/local64/lib">>%instdir%\local64\etc\profile.local
		echo.export PKG_CONFIG_PATH CPPFLAGS CFLAGS CXXFLAGS LDFLAGS MSYSTEM>>%instdir%\local64\etc\profile.local
		echo.>>%instdir%\local64\etc\profile.local
		echo.PYTHONHOME=/usr>>%instdir%\local64\etc\profile.local
		echo.PYTHONPATH="/usr/lib/python2.7:/usr/lib/python2.7/Tools/Scripts">>%instdir%\local64\etc\profile.local
		echo.>>%instdir%\local64\etc\profile.local
		echo.PATH=".:/local64/bin-audio:/local64/bin-global:/local64/bin-video:/local64/bin:/mingw64/bin:${MSYS2_PATH}:${INFOPATH}:${PYTHONHOME}:${PYTHONPATH}">>%instdir%\local64\etc\profile.local
		echo.PS1='\[\033[32m\]\u@\h \[\033[33m\w\033[0m\]$ '>>%instdir%\local64\etc\profile.local
		echo.export PATH PS1>>%instdir%\local64\etc\profile.local
		echo.>>%instdir%\local64\etc\profile.local
		echo.# package build directory>>%instdir%\local64\etc\profile.local
		echo.LOCALBUILDDIR=/build64>>%instdir%\local64\etc\profile.local
		echo.# package installation prefix>>%instdir%\local64\etc\profile.local
		echo.LOCALDESTDIR=/local64>>%instdir%\local64\etc\profile.local
		echo.export LOCALBUILDDIR LOCALDESTDIR>>%instdir%\local64\etc\profile.local
		echo.>>%instdir%\local64\etc\profile.local
		echo.bits='64bit'>>%instdir%\local64\etc\profile.local
		echo.targetBuild='x86_64-pc-mingw32'>>%instdir%\local64\etc\profile.local
		echo.targetHost='x86_64-pc-mingw32'>>%instdir%\local64\etc\profile.local
		echo.cross='x86_64-w64-mingw32-'>>%instdir%\local64\etc\profile.local
		)
	
:loginProfile
if exist %instdir%\%msys2%\etc\userprofile.cfg GOTO compileLocals

if %build32%==no GOTO loginProfile64
	echo -------------------------------------------------------------------------------
	echo.
	echo.- write default profile [32 bit]
	echo.
	echo -------------------------------------------------------------------------------
	echo.cat ^>^> /etc/profile ^<^< "EOF">>%instdir%\profile.sh
	echo.if [ -f /local32/etc/profile.local ]; then>>%instdir%\profile.sh
	 echo.       source /local32/etc/profile.local>>%instdir%\profile.sh
	echo.fi>>%instdir%\profile.sh
	echo.>>%instdir%\profile.sh
	echo.EOF>>%instdir%\profile.sh

	%instdir%\%msys2%\bin\sh -l %instdir%\profile.sh
	echo 32 bit build system add to profile. see profile>>%instdir%\%msys2%\etc\userprofile.cfg
	del %instdir%\profile.sh
	GOTO compileLocals
	
:loginProfile64
	echo -------------------------------------------------------------------------------
	echo.
	echo.- write default profile [64 bit]
	echo.
	echo -------------------------------------------------------------------------------
	echo.cat ^>^> /etc/profile ^<^< "EOF">>%instdir%\profile.sh
	echo.if [ -f /local64/etc/profile.local ]; then>>%instdir%\profile.sh
	 echo.       source /local64/etc/profile.local>>%instdir%\profile.sh
	echo.fi>>%instdir%\profile.sh
	echo.>>%instdir%\profile.sh
	echo.EOF>>%instdir%\profile.sh

	%instdir%\%msys2%\bin\sh -l %instdir%\profile.sh
	echo 64 bit build system add to profile. see profile>>%instdir%\%msys2%\etc\userprofile.cfg
	del %instdir%\profile.sh

:compileLocals
cd %instdir%
echo -------------------------------------------------------------------------------
echo.
echo.- compile local tools:
echo.
echo -------------------------------------------------------------------------------
%instdir%\%msys2%\bin\mintty.exe /bin/sh -l %instdir%\compile_localtools.sh --cpuCount=%cpuCount% --build32=%build32% --build64=%build64% --deleteSource=%deleteSource% --mp4box=%mp4box% --ffmpeg=%ffmpeg% --ffmpegUpdate=%ffmpegUpdate% --mplayer=%mplayer% --nonfree=%binary%
echo. compile video tools done...	
	
:: strip compiled files
if %stripFile%==y (
echo -------------------------------------------------------------------------------
echo.
echo.- stripping bins:
echo.
echo -------------------------------------------------------------------------------

if %build32%==yes (
	FOR /R "%instdir%\local32" %%C IN (*.exe) DO (
		FOR /F "tokens=1 delims= " %%A IN ( "%%~tC" ) DO (
			IF %%A==%date% (
				%instdir%\%msys2%\mingw32\bin\strip %%C
				%instdir%\%msys2%\mingw32\bin\strip --strip-all %%C
				echo.strip %%~nC%%~xC 32Bit done...
				)
			)
		)
	)	
)
if %stripFile%==y (	
if %build64%==yes (
	FOR /R "%instdir%\local64" %%C IN (*.exe) DO (
		FOR /F "tokens=1 delims= " %%A IN ( "%%~tC" ) DO (
			IF %%A==%date% (
				%instdir%\%msys2%\mingw64\bin\strip %%C
				%instdir%\%msys2%\mingw64\bin\strip --strip-all %%C
				echo.strip %%~nC%%~xC 64Bit done...
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