# set CPU count global. This can be overwrite from the compiler script (media-autobuild_suite.bat)
cpuCount=1
compile="false"
buildFFmpeg="false"
x264Bin="no"
newFfmpeg="no"
while true; do
  case $1 in
--cpuCount=* ) cpuCount="${1#*=}"; shift ;;
--build32=* ) build32="${1#*=}"; shift ;;
--build64=* ) build64="${1#*=}"; shift ;;
--mp4box=* ) mp4box="${1#*=}"; shift ;;
--ffmbc=* ) ffmbc="${1#*=}"; shift ;;
--x264=* ) x264="${1#*=}"; shift ;;
--x265=* ) x265="${1#*=}"; shift ;;
--ffmpeg=* ) ffmpeg="${1#*=}"; shift ;;
--ffmpegUpdate=* ) ffmpegUpdate="${1#*=}"; shift ;;
--mplayer=* ) mplayer="${1#*=}"; shift ;;
--mpv=* ) mpv="${1#*=}"; shift ;;
--mkv=* ) mkv="${1#*=}"; shift ;;
--deleteSource=* ) deleteSource="${1#*=}"; shift ;;
--nonfree=* ) nonfree="${1#*=}"; shift ;;
--stripping* ) stripping="${1#*=}"; shift ;;
--packing* ) packing="${1#*=}"; shift ;;
    -- ) shift; break ;;
    -* ) echo "Error, unknown option: '$1'."; exit 1 ;;
    * ) break ;;
  esac
done

# get git clone, or update
do_git() {
local gitURL="$1"
local gitFolder="$2"
local gitDepth="$3"
echo -ne "\033]0;compile $gitFolder $bits\007"
if [ ! -d $gitFolder ]; then
	if [[ $gitDepth == "noDepth" ]]; then
		git clone $gitURL $gitFolder
	else
		git clone --depth 1 $gitURL $gitFolder
	fi
	compile="true"
	cd $gitFolder
else 	
	cd $gitFolder
	oldHead=`git rev-parse HEAD`
	git reset --hard @{u}
	git pull origin master
	newHead=`git rev-parse HEAD`
	
	if [[ "$oldHead" != "$newHead" ]]; then 
		compile="true"
	fi
fi
}

# get svn checkout, or update
do_svn() {
local svnURL="$1"
local svnFolder="$2"
echo -ne "\033]0;compile $svnFolder $bits\007"
if [ ! -d $svnFolder ]; then
	svn checkout $svnURL $svnFolder
	compile="true"
	cd $svnFolder
else 	
	cd $svnFolder
	oldRevision=`svnversion`
	svn update
	newRevision=`svnversion`
	
	if [[ "$oldRevision" != "$newRevision" ]]; then 
		compile="true"
	fi
fi
}

# get hg clone, or update
do_hg() {
local hgURL="$1"
local hgFolder="$2"
echo -ne "\033]0;compile $hgFolder $bits\007"
if [ ! -d $hgFolder ]; then
	hg clone $hgURL $hgFolder
	compile="true"
	cd $hgFolder
else 	
	cd $hgFolder
	oldHead=`hg id --id`
	hg pull
	hg update
	newHead=`hg id --id`
	
	if [[ "$oldHead" != "$newHead" ]]; then 
		compile="true"
	fi
fi
}
	
# check if compiled file exist
do_checkIfExist() {
	local packetName="$1"
	local fileName="$2"
	local fileExtension=${fileName##*.}
	if [[ "$fileExtension" = "exe" ]]; then
		if [ -f "$LOCALDESTDIR/$fileName" ]; then
			echo -
			echo -------------------------------------------------
			echo "build $packetName done..."
			echo -------------------------------------------------
			echo -
			if [[ $deleteSource = "y" ]]; then
				if [[ ! "${packetName: -4}" = "-git" ]]; then
					if [[ ! "${packetName: -3}" = "-hg" ]]; then
						if [[ ! "${packetName: -4}" = "-svn" ]]; then
							cd $LOCALBUILDDIR
							rm -rf $LOCALBUILDDIR/$packetName
						fi	
					fi
				fi
			fi
			else
				echo -------------------------------------------------
				echo "Build $packetName failed..."
				echo "Delete the source folder under '$LOCALBUILDDIR' and start again," 
				echo "or if you know there is no dependences hit enter for continue it."
				read -p ""
				sleep 5
		fi	
	elif [[ "$fileExtension" = "a" ]] || [[ "$fileExtension" = "dll" ]]; then
		if [ -f "$LOCALDESTDIR/lib/$fileName" ]; then
			echo -
			echo -------------------------------------------------
			echo "build $packetName done..."
			echo -------------------------------------------------
			echo -
			if [[ $deleteSource = "y" ]]; then
				if [[ ! "${packetName: -4}" = "-git" ]]; then
					if [[ ! "${packetName: -3}" = "-hg" ]]; then
						if [[ ! "${packetName: -4}" = "-svn" ]]; then
							cd $LOCALBUILDDIR
							rm -rf $LOCALBUILDDIR/$packetName
						fi	
					fi
				fi
			fi
			else
				echo -------------------------------------------------
				echo "build $packetName failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again," 
				echo "or if you know there is no dependences hit enter for continue it"
				read -p "first close the batch window, then the shell window"
				sleep 5
		fi	
	fi
}

buildProcess() {
cd $LOCALBUILDDIR
echo "-------------------------------------------------------------------------------"
echo
echo "compile global tools $bits"
echo
echo "-------------------------------------------------------------------------------"
	
if [ -f "$LOCALDESTDIR/lib/libopenjpeg.a" ]; then
	echo -------------------------------------------------
	echo "openjpeg-1.5.2 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile openjpeg $bits\007"
		rm -rf openjpeg-1.5.2
		wget --tries=20 --retry-connrefused --waitretry=2 -O openjpeg-1.5.2.tar.gz -c "http://sourceforge.net/projects/openjpeg.mirror/files/1.5.2/openjpeg-1.5.2.tar.gz/download"
		tar xf openjpeg-1.5.2.tar.gz
		rm openjpeg-1.5.2.tar.gz
		cd openjpeg-1.5.2
		
		cmake -G "MSYS Makefiles" -DBUILD_SHARED_LIBS:BOOL=off -DBUILD_MJ2:BOOL=on -DBUILD_JPWL:BOOL=on -DBUILD_JPIP:BOOL=on -DBUILD_THIRDPARTY:BOOL=on -DCMAKE_INSTALL_PREFIX=$LOCALDESTDIR -DOPENJPEG_INSTALL_BIN_DIR=$LOCALDESTDIR/bin-global -DCMAKE_C_FLAGS="-mms-bitfields -mthreads -mtune=generic -pipe -DOPJ_STATIC"
				
		make -j $cpuCount
		make install
		
		do_checkIfExist openjpeg-1.5.2 libopenjpeg.a
		cp $LOCALDESTDIR/include/openjpeg-1.5/openjpeg.h $LOCALDESTDIR/include
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libfreetype.a" ]; then
	echo -------------------------------------------------
	echo "freetype-2.5.4 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile freetype $bits\007"
		rm -rf freetype-2.5.4
		wget --tries=20 --retry-connrefused --waitretry=2 -c http://downloads.sourceforge.net/project/freetype/freetype2/2.5.4/freetype-2.5.4.tar.bz2
		tar xf freetype-2.5.4.tar.bz2
		rm freetype-2.5.4.tar.bz2
		cd freetype-2.5.4
		./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-global --disable-shared --with-harfbuzz=no
		make -j $cpuCount
		make install
		
		do_checkIfExist freetype-2.5.4 libfreetype.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libfontconfig.a" ]; then
	echo -------------------------------------------------
	echo "fontconfig-2.11.1 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile fontconfig $bits\007"
		rm -rf fontconfig-2.11.1
		wget --tries=20 --retry-connrefused --waitretry=2 -c http://www.freedesktop.org/software/fontconfig/release/fontconfig-2.11.1.tar.gz
		tar xf fontconfig-2.11.1.tar.gz
		rm fontconfig-2.11.1.tar.gz
		cd fontconfig-2.11.1
		./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-global --enable-shared=no
		sed -i 's/-L${libdir} -lfontconfig[^l]*$/-L${libdir} -lfontconfig -lfreetype -lexpat/' fontconfig.pc
		
		make -j $cpuCount
		make install
		
		do_checkIfExist fontconfig-2.11.1 libfontconfig.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libfribidi.a" ]; then
	echo -------------------------------------------------
	echo "fribidi-0.19.6 is already compiled"
	echo -------------------------------------------------
	else
		echo -ne "\033]0;compile fribidi $bits\007"
		rm -rf fribidi-0.19.6
		wget --tries=20 --retry-connrefused --waitretry=2 -c http://fribidi.org/download/fribidi-0.19.6.tar.bz2
		tar xf fribidi-0.19.6.tar.bz2
		rm fribidi-0.19.6.tar.bz2
		cd fribidi-0.19.6
		
		./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-global --enable-shared=no --with-glib=no
		make -j $cpuCount
		make install

if [ ! -f ${LOCALDESTDIR}/bin-global/fribidi-config ]; then
cat > ${LOCALDESTDIR}/bin-global/fribidi-config << "EOF"
#!/bin/sh
case $1 in
  --version)
    pkg-config --modversion fribidi
    ;;
  --cflags)
    pkg-config --cflags fribidi
    ;;
  --libs)
    pkg-config --libs fribidi
    ;;
  *)
    false
    ;;
esac
EOF
fi

	do_checkIfExist fribidi-0.19.6 libfribidi.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libSDL.a" ]; then
	echo -------------------------------------------------
	echo "SDL-1.2.15 is already compiled"
	echo -------------------------------------------------
	else
		echo -ne "\033]0;compile SDL $bits\007"
		rm -rf SDL-1.2.15
		wget --tries=20 --retry-connrefused --waitretry=2 -c http://www.libsdl.org/release/SDL-1.2.15.tar.gz
		tar xf SDL-1.2.15.tar.gz
		rm SDL-1.2.15.tar.gz
		cd SDL-1.2.15
		CFLAGS="-DDECLSPEC=" ./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-global --enable-shared=no
		make -j $cpuCount
		make install

		sed -i "s/-mwindows//" "$LOCALDESTDIR/bin-global/sdl-config"
		sed -i "s/-mwindows//" "$LOCALDESTDIR/lib/pkgconfig/sdl.pc"

		do_checkIfExist SDL-1.2.15 libSDL.a
fi

#----------------------
# crypto engine
#----------------------
cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libgcrypt.a" ]; then
	echo -------------------------------------------------
	echo "libgcrypt-1.6.2 is already compiled"
	echo -------------------------------------------------
	else
		echo -ne "\033]0;compile libgcrypt $bits\007"
		rm -rf libgcrypt-1.6.2
		wget --tries=20 --retry-connrefused --waitretry=2 ftp://ftp.gnupg.org/gcrypt/libgcrypt/libgcrypt-1.6.2.tar.bz2
		tar xf libgcrypt-1.6.2.tar.bz2
		rm libgcrypt-1.6.2.tar.bz2
		cd libgcrypt-1.6.2
		
		if [[ "$bits" = "32bit" ]]; then
			./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-global --disable-shared --with-gpg-error-prefix=$MINGW_PREFIX
		else
			./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-global --disable-shared --with-gpg-error-prefix=$MINGW_PREFIX --disable-asm --disable-padlock-support		
		fi
		make -j $cpuCount
		make install

		do_checkIfExist libgcrypt-1.6.2 libgcrypt.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libgnutls.a" ]; then
	echo -------------------------------------------------
	echo "gnutls-3.3.11 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile gnutls $bits\007"
		rm -rf gnutls-3.3.11
		wget --tries=20 --retry-connrefused --waitretry=2 ftp://ftp.gnutls.org/gcrypt/gnutls/v3.3/gnutls-3.3.11.tar.xz
		tar xf gnutls-3.3.11.tar.xz
		rm gnutls-3.3.11.tar.xz
		cd gnutls-3.3.11
		
		./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-global --disable-guile --enable-cxx --disable-doc --disable-tests --disable-shared --with-zlib --without-p11-kit --disable-rpath --disable-gtk-doc --disable-libdane --enable-local-libopts
		
		make -j $cpuCount
		make install
		
		sed -i 's/-lgnutls *$/-lgnutls -lnettle -lhogweed -liconv -lcrypt32 -lws2_32 -lz -lgmp -lintl/' $LOCALDESTDIR/lib/pkgconfig/gnutls.pc
		
		do_checkIfExist gnutls-3.3.11 libgnutls.a
fi

cd $LOCALBUILDDIR

do_git "git://git.ffmpeg.org/rtmpdump" rtmpdump-git

if [[ $compile == "true" ]]; then
	if [ -f "$LOCALDESTDIR/lib/librtmp.a" ]; then
		rm -rf $LOCALDESTDIR/include/librtmp
		rm $LOCALDESTDIR/lib/librtmp.a
		rm $LOCALDESTDIR/lib/pkgconfig/librtmp.pc
		rm $LOCALDESTDIR/man/man3/librtmp.3
		rm $LOCALDESTDIR/bin-video/rtmpdump.exe $LOCALDESTDIR/bin-video/rtmpsuck.exe $LOCALDESTDIR/bin-video/rtmpsrv.exe $LOCALDESTDIR/bin-video/rtmpgw.exe
		rm $LOCALDESTDIR/man/man1/rtmpdump.1 
		rm $LOCALDESTDIR/man/man8/rtmpgw.8
		make clean
	fi
	
	make XCFLAGS=$MINGW_PREFIX/include LDFLAGS="$LDFLAGS" prefix=$LOCALDESTDIR bindir=$LOCALDESTDIR/bin-video sbindir=$LOCALDESTDIR/bin-video CRYPTO=GNUTLS SHARED= SYS=mingw install LIBS="$LIBS -liconv -lrtmp -lgnutls -lhogweed -lnettle -lgmp -liconv -ltasn1 -lws2_32 -lwinmm -lgdi32 -lcrypt32 -lintl -lz -liconv" LIB_GNUTLS="-lgnutls -lhogweed -lnettle -lgmp -liconv -ltasn1" LIBS_mingw="-lws2_32 -lwinmm -lgdi32 -lcrypt32 -lintl"

	sed -i 's/Libs:.*/Libs: -L${libdir} -lrtmp -lwinmm -lz -lgmp -lintl/' $LOCALDESTDIR/lib/pkgconfig/librtmp.pc
	
	do_checkIfExist rtmpdump librtmp.a
	compile="false"
else
	echo -------------------------------------------------
	echo "rtmpdump is already up to date"
	echo -------------------------------------------------
fi

cd $LOCALBUILDDIR

do_git "https://github.com/foo86/dcadec.git" libdcadec-git

if [[ $compile == "true" ]]; then

	if [[ -d $LOCALDESTDIR/include/gme ]]; then
		rm -rf $LOCALDESTDIR/include/libdcadec
		rm -f $LOCALDESTDIR/lib/libdcadec.a
		rm -f $LOCALDESTDIR/lib/pkgconfig/dcadec.pc
		rm -f $LOCALDESTDIR/bin-audio/dcadec.exe
		make clean
	fi

    make CONFIG_WINDOWS=1 LDFLAGS=-lm
    make PREFIX=$LOCALDESTDIR BINDIR=$LOCALDESTDIR/bin-audio PKG_CONFIG_PATH=$LOCALDESTDIR/lib/pkgconfig install

    do_checkIfExist libdcadec-git libdcadec.a

    compile="false"
else
    echo -------------------------------------------------
    echo "libdcadec is already up to date"
    echo -------------------------------------------------
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libxml2.a" ]; then
	echo -------------------------------------------------
	echo "libxml2-2.9.1 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile libxml2 $bits\007"
		rm -rf libxml2-2.9.1
		wget --tries=20 --retry-connrefused --waitretry=2 -c ftp://xmlsoft.org/libxml2/libxml2-2.9.1.tar.gz
		tar xf libxml2-2.9.1.tar.gz
		rm libxml2-2.9.1.tar.gz
		cd libxml2-2.9.1
		
		./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-global --disable-shared --enable-static
		
		make -j $cpuCount
		make install
		
		do_checkIfExist libxml2-2.9.1 libxml2.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libgnurx.a" ]; then
	echo -------------------------------------------------
	echo "libgnurx-2.5.1 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile libgnurx $bits\007"
		rm -rf mingw-libgnurx-2.5.1
		wget --tries=20 --retry-connrefused --waitretry=2 -c http://downloads.sourceforge.net/project/mingw/Other/UserContributed/regex/mingw-regex-2.5.1/mingw-libgnurx-2.5.1-src.tar.gz
		tar xf mingw-libgnurx-2.5.1-src.tar.gz
		rm mingw-libgnurx-2.5.1-src.tar.gz
		cd mingw-libgnurx-2.5.1
		
		rm -f configure.ac

		wget --tries=20 --retry-connrefused --waitretry=2 --no-check-certificate -c -O Makefile.am https://raw.githubusercontent.com/Alexpux/MINGW-packages/master/mingw-w64-libgnurx/mingw32-libgnurx-Makefile.am
		wget --tries=20 --retry-connrefused --waitretry=2 --no-check-certificate -c -O configure.ac https://raw.githubusercontent.com/Alexpux/MINGW-packages/master/mingw-w64-libgnurx/mingw32-libgnurx-configure.ac
		
		touch NEWS
		touch AUTHORS
		libtoolize --copy
		aclocal
		autoconf
		automake --add-missing
		
		./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --enable-static=yes --enable-shared=no

		make -j $cpuCount
		make install
		
		do_checkIfExist libgnurx-2.5.1 libgnurx.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libmagic.a" ]; then
	echo -------------------------------------------------
	echo "file-5.22[libmagic] is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile file $bits\007"
		rm -rf file-5.22
		wget --tries=20 --retry-connrefused --waitretry=2 -c ftp://ftp.astron.com/pub/file/file-5.22.tar.gz
		tar xf file-5.22.tar.gz
		rm file-5.22.tar.gz
		cd file-5.22
		
		./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-global --enable-static=yes --enable-shared=no CPPFLAGS='-DPCRE_STATIC' LIBS='-lpcre -lshlwapi -lz'

		make CPPFLAGS='-D_REGEX_RE_COMP' -j $cpuCount
		make install
		
		do_checkIfExist file-5.22 libmagic.a
fi

cd $LOCALBUILDDIR

do_git "https://github.com/TimothyGu/libilbc.git" libilbc-git

if [[ $compile == "true" ]]; then
	if [[ ! -f "configure" ]]; then
		autoreconf -fiv
	else
		make uninstall
		make clean
	fi
	
	./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-global --disable-shared
	
	make -j $cpuCount
	make install
	
	do_checkIfExist libilbc-git libilbc.a
	compile="false"
else
	echo -------------------------------------------------
	echo "libilbc-git is already up to date"
	echo -------------------------------------------------
fi

cd $LOCALBUILDDIR
	
#do_svn "svn://dev.exiv2.org/svn/trunk" exiv2-svn

if [[ $compile == "no" ]]; then	# is deactivated for the moment
	if [ -d "build" ]; then
		cd build
		make uninstall
		rm $LOCALDESTDIR/bin-global/metacopy.exe
		rm $LOCALDESTDIR/bin-global/path-test.exe
		rm $LOCALDESTDIR/bin-global/exiv2.exe
		rm -rf *
	else
		mkdir build
		cd build
	fi
	
	LDFLAGS="$LDFLAGS -static -static-libgcc -static-libstdc++" cmake .. -G "MSYS Makefiles" -DCMAKE_INSTALL_PREFIX=$LOCALDESTDIR -DEXIV2_ENABLE_SHARED:BOOL=off -DCMAKE_BUILD_TYPE=release -DEXIV2_ENABLE_CURL:BOOL=off -DEXIV2_ENABLE_SSH:BOOL=off -Wno-dev
	
	make -j $cpuCount
	make install
	
	mv $LOCALDESTDIR/bin/metacopy.exe $LOCALDESTDIR/bin-global
	mv $LOCALDESTDIR/bin/path-test.exe $LOCALDESTDIR/bin-global
	mv $LOCALDESTDIR/bin/exiv2.exe $LOCALDESTDIR/bin-global
	
	do_checkIfExist exiv2-svn bin-global/exiv2.exe
	compile="false"
#else
#	echo -------------------------------------------------
#	echo "exiv2 is already up to date"
#	echo -------------------------------------------------
fi



if [[ $mpv == "y" && ! $ffmpeg == "s" ]]; then

	cd $LOCALBUILDDIR

	do_git "git://midipix.org/waio" waio-git

	if [[ $compile == "true" ]]; then
		if [[ $bits = "32bit" ]]; then
			if [[ -f lib32/libwaio.a ]]; then
				./build-mingw-nt32 clean
				rm -rf $LOCALDESTDIR/include/waio
				rm -f $LOCALDESTDIR/lib/libwaio.a
			fi

			build-mingw-nt32 AR=i686-w64-mingw32-gcc-ar LD=ld STRIP=strip lib-static

			cp -r include/waio  $LOCALDESTDIR/include/
			cp -r lib32/libwaio.a $LOCALDESTDIR/lib/
		else
			if [[ -f lib64/libwaio.a ]]; then
				./build-mingw-nt64 clean
				rm -rf $LOCALDESTDIR/include/waio
				rm -f $LOCALDESTDIR/lib/libwaio.a
			fi

			build-mingw-nt64 AR=x86_64-w64-mingw32-gcc-ar LD=ld STRIP=strip lib-static

			cp -r include/waio  $LOCALDESTDIR/include/
			cp -r lib64/libwaio.a $LOCALDESTDIR/lib/
		fi

		do_checkIfExist waio-git libwaio.a
		compile="false"
	fi
fi

cd $LOCALBUILDDIR

if [ -f $LOCALDESTDIR/lib/libwx_baseu-3.0.a ]; then
	echo -------------------------------------------------
	echo "wxWidgets is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile wxWidgets $bits\007"
		rm -rf wxWidgets-3.0.2
		wget --tries=20 --retry-connrefused --waitretry=2 -c -O wxWidgets-3.0.2.tar.bz2 https://sourceforge.net/projects/wxwindows/files/3.0.2/wxWidgets-3.0.2.tar.bz2
		tar xf wxWidgets-3.0.2.tar.bz2
		rm wxWidgets-3.0.2.tar.bz2
		cd wxWidgets-3.0.2
		
		CPPFLAGS+=" -fno-devirtualize" CFLAGS+=" -fno-devirtualize" configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-global --with-msw --disable-mslu --disable-shared --enable-static --enable-iniconf --enable-iff --enable-permissive --disable-monolithic --enable-unicode --enable-accessibility --disable-precomp-headers LDFLAGS="$LDFLAGS -static -static-libgcc -static-libstdc++"
		
		make -j $cpuCount
		make install
		
		do_checkIfExist wxWidgets-3.0.2 libwx_baseu-3.0.a
fi

echo "-------------------------------------------------------------------------------"
echo
echo "compile global tools $bits done..."
echo
echo "-------------------------------------------------------------------------------"
	
cd $LOCALBUILDDIR
echo "-------------------------------------------------------------------------------"
echo
echo "compile audio tools $bits"
echo
echo "-------------------------------------------------------------------------------"

if [ -f "$LOCALDESTDIR/lib/libtheora.a" ]; then
	echo -------------------------------------------------
	echo "libtheora-1.1.1 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile libtheora $bits\007"
		rm -rf libtheora-1.1.1
		wget --tries=20 --retry-connrefused --waitretry=2 -c http://downloads.xiph.org/releases/theora/libtheora-1.1.1.tar.bz2
		tar xf libtheora-1.1.1.tar.bz2
		rm libtheora-1.1.1.tar.bz2
		cd libtheora-1.1.1
		
		./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --enable-shared=no --disable-examples
		
		make -j $cpuCount
		make install

		do_checkIfExist libtheora-1.1.1 libtheora.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libspeex.a" ]; then
	echo -------------------------------------------------
	echo "speex-1.2rc1 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile speex $bits\007"
		rm -rf speex-1.2rc1
		wget --tries=20 --retry-connrefused --waitretry=2 -c http://downloads.xiph.org/releases/speex/speex-1.2rc1.tar.gz
		tar xf speex-1.2rc1.tar.gz
		rm speex-1.2rc1.tar.gz
		cd speex-1.2rc1
		
		./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-audio --enable-shared=no 
		
		make -j $cpuCount
		make install
		
		do_checkIfExist speex-1.2rc1 libspeex.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/bin-audio/flac.exe" ]; then
    echo -------------------------------------------------
    echo "flac-1.3.1 is already compiled"
    echo -------------------------------------------------
    else
        echo -ne "\033]0;compile flac $bits\007"
        rm -rf flac-1.3.1
        wget --tries=20 --retry-connrefused --waitretry=2 -c http://downloads.xiph.org/releases/flac/flac-1.3.1.tar.xz
        tar xf flac-1.3.1.tar.xz
        rm flac-1.3.1.tar.xz
        cd flac-1.3.1

        ./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-audio --disable-xmms-plugin --disable-doxygen-docs --enable-shared=no --enable-static

        make -j $cpuCount
        make install

        do_checkIfExist flac-1.3.1 bin-audio/flac.exe
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libvo-aacenc.a" ]; then
	echo -------------------------------------------------
	echo "vo-aacenc-0.1.3 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile vo-aacenc $bits\007"
		rm -rf vo-aacenc-0.1.3
		wget --tries=20 --retry-connrefused --waitretry=2 -c http://downloads.sourceforge.net/project/opencore-amr/vo-aacenc/vo-aacenc-0.1.3.tar.gz
		tar xf vo-aacenc-0.1.3.tar.gz
		rm vo-aacenc-0.1.3.tar.gz
		cd vo-aacenc-0.1.3
		
		./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --enable-shared=no
		
		make -j $cpuCount
		make install
		
		do_checkIfExist vo-aacenc-0.1.3 libvo-aacenc.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libopencore-amrnb.a" ]; then
	echo -------------------------------------------------
	echo "opencore-amr-0.1.3 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile opencore-amr $bits\007"
		rm -rf opencore-amr-0.1.3
		wget --tries=20 --retry-connrefused --waitretry=2 -c http://downloads.sourceforge.net/project/opencore-amr/opencore-amr/opencore-amr-0.1.3.tar.gz
		tar xf opencore-amr-0.1.3.tar.gz
		rm opencore-amr-0.1.3.tar.gz
		cd opencore-amr-0.1.3
		
		./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --enable-shared=no
		
		make -j $cpuCount
		make install
		
		do_checkIfExist opencore-amr-0.1.3 libopencore-amrnb.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libvo-amrwbenc.a" ]; then
	echo -------------------------------------------------
	echo "vo-amrwbenc-0.1.2 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile vo-amrwbenc $bits\007"
		rm -rf vo-amrwbenc-0.1.2
		wget --tries=20 --retry-connrefused --waitretry=2 -c http://downloads.sourceforge.net/project/opencore-amr/vo-amrwbenc/vo-amrwbenc-0.1.2.tar.gz
		tar xf vo-amrwbenc-0.1.2.tar.gz
		rm vo-amrwbenc-0.1.2.tar.gz
		cd vo-amrwbenc-0.1.2
		
		./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --enable-shared=no
		
		make -j $cpuCount
		make install
		
		do_checkIfExist vo-amrwbenc-0.1.2 libvo-amrwbenc.a
fi

cd $LOCALBUILDDIR

do_git "https://github.com/mstorsjo/fdk-aac" fdk-aac-git

if [[ $compile == "true" ]]; then
	if [[ ! -f ./configure ]]; then
		./autogen.sh
	else 
		make uninstall
		make clean
	fi

	./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --enable-shared=no
	
	make -j $cpuCount
	make install
	
	do_checkIfExist fdk-aac-git libfdk-aac.a
	compile="false"
else
	echo -------------------------------------------------
	echo "fdk-aac is already up to date"
	echo -------------------------------------------------
fi
	
cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/bin-audio/fdkaac.exe" ]; then
	echo -------------------------------------------------
	echo "bin-fdk-aac is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile fdk-aac $bits\007"
		rm -rf bin-fdk-aac

		wget --tries=20 --retry-connrefused --waitretry=2 --no-check-certificate -c https://github.com/nu774/fdkaac/archive/master.zip -O bin-fdk-aac.zip 
		unzip bin-fdk-aac.zip
		rm bin-fdk-aac.zip 
		mv fdkaac-master bin-fdk-aac
		cd bin-fdk-aac
		
		if [[ ! -f ./configure ]]; then
			autoreconf -i
		fi
	
		./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-audio
		
		make -j $cpuCount
		make install

		do_checkIfExist bin-fdk-aac bin-audio/fdkaac.exe
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libfaac.a" ]; then
	echo -------------------------------------------------
	echo "faac-1.28 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile faac $bits\007"
		rm -rf faac-1.28
		wget --tries=20 --retry-connrefused --waitretry=2 -c http://downloads.sourceforge.net/faac/faac-1.28.tar.gz
		tar xf faac-1.28.tar.gz
		rm faac-1.28.tar.gz
		cd faac-1.28
		
		sh bootstrap
		
		./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-audio --enable-shared=no --without-mp4v2
		
		make -j $cpuCount
		make install
		
		do_checkIfExist faac-1.28 libfaac.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libopus.a" ]; then
    echo -------------------------------------------------
    echo "opus-1.1 is already compiled"
    echo -------------------------------------------------
    else 
		echo -ne "\033]0;compile opus $bits\007"
		rm -rf opus-1.1
		wget --tries=20 --retry-connrefused --waitretry=2 -c http://downloads.xiph.org/releases/opus/opus-1.1.tar.gz
		tar xf opus-1.1.tar.gz
		rm opus-1.1.tar.gz
		cd opus-1.1
		
		wget --tries=20 --retry-connrefused --waitretry=2 --no-check-certificate -c https://raw.github.com/jb-alvarado/media-autobuild_suite/master/patches/opus11.patch
		patch -p0 < opus11.patch
		
        ./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --enable-shared=no --enable-static --disable-doc
		
        make -j $cpuCount
		make install
		
		do_checkIfExist opus-1.1 libopus.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/bin-audio/opusenc.exe" ]; then
    echo -------------------------------------------------
    echo "opus-tools-0.1.9 is already compiled"
    echo -------------------------------------------------
    else 
		echo -ne "\033]0;compile opus-tools $bits\007"
		rm -rf opus-tools-0.1.9
		wget --tries=20 --retry-connrefused --waitretry=2 -c http://downloads.xiph.org/releases/opus/opus-tools-0.1.9.tar.gz
		tar xf opus-tools-0.1.9.tar.gz
		rm opus-tools-0.1.9.tar.gz
		cd opus-tools-0.1.9
		
        ./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-audio LDFLAGS="$LDFLAGS -static -static-libgcc -static-libstdc++"
		
        make -j $cpuCount
		make install
        
		do_checkIfExist opus-tools-0.1.9 bin-audio/opusenc.exe
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/liba52.a" ]; then
	echo -------------------------------------------------
	echo "a52dec-0.7.4 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile a52dec $bits\007"
		rm -rf a52dec-0.7.4
		wget --tries=20 --retry-connrefused --waitretry=2 -c "http://liba52.sourceforge.net/files/a52dec-0.7.4.tar.gz"
		tar xf a52dec-0.7.4.tar.gz
		rm a52dec-0.7.4.tar.gz
		cd a52dec-0.7.4
		
		./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-audio --disable-shared
		
		make -j $cpuCount
		make install
		
		do_checkIfExist a52dec-0.7.4 liba52.a
fi

cd $LOCALBUILDDIR
		
if [ -f "$LOCALDESTDIR/lib/libmad.a" ]; then
	echo -------------------------------------------------
	echo "libmad-0.15.1b is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile libmad $bits\007"
		rm -rf libmad-0.15.1b
		wget --tries=20 --retry-connrefused --waitretry=2 -c "ftp://ftp.mars.org/pub/mpeg/libmad-0.15.1b.tar.gz"
		tar xf libmad-0.15.1b.tar.gz
		rm libmad-0.15.1b.tar.gz
		cd libmad-0.15.1b
		
		./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --disable-shared --enable-fpm=intel --disable-debugging
		
		make -j $cpuCount
		make install
		
		do_checkIfExist libmad-0.15.1b libmad.a
fi

cd $LOCALBUILDDIR
		
if [ -f "$LOCALDESTDIR/lib/libsoxr.a" ]; then
	echo -------------------------------------------------
	echo "soxr-0.1.1 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile soxr-0.1.1 $bits\007"
		rm -rf soxr-0.1.1-Source
		wget --tries=20 --retry-connrefused --waitretry=2 -c "http://sourceforge.net/projects/soxr/files/soxr-0.1.1-Source.tar.xz"
		tar xf soxr-0.1.1-Source.tar.xz
		rm soxr-0.1.1-Source.tar.xz
		cd soxr-0.1.1-Source
		
		sed -i 's|NOT WIN32|UNIX|g' ./src/CMakeLists.txt
		
		mkdir build 
		cd build
		
		cmake .. -G "MSYS Makefiles" -DCMAKE_INSTALL_PREFIX=$LOCALDESTDIR -DHAVE_WORDS_BIGENDIAN_EXITCODE=0 -DBUILD_SHARED_LIBS:bool=off -DBUILD_TESTS:BOOL=OFF -DWITH_OPENMP:BOOL=OFF -DUNIX:BOOL=on -Wno-dev
		
		make -j $cpuCount
		make install
		
		do_checkIfExist soxr-0.1.1-Source libsoxr.a
fi

cd $LOCALBUILDDIR
	
do_git "git://git.code.sf.net/p/sox/code" sox-git

if [[ $compile == "true" ]]; then
	sed -i 's|found_libgsm=yes|found_libgsm=no|g' configure.ac
	
	if [[ ! -f ./configure ]]; then
		autoreconf -i
	else
		make uninstall
		make clean
	fi
	
	./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-audio --enable-shared=no CPPFLAGS='-DPCRE_STATIC' LIBS='-lpcre -lshlwapi -lz -lgnurx' SNDFILE_LIBS="-lsndfile -lFLAC -lvorbis -lvorbisenc -logg"
	
	make -j $cpuCount
	make install

	do_checkIfExist sox-git bin-audio/sox.exe
		
	compile="false"
else
	echo -------------------------------------------------
	echo "sox is already up to date"
	echo -------------------------------------------------
fi

cd $LOCALBUILDDIR

do_git "https://bitbucket.org/mpyne/game-music-emu.git" gme-git

if [[ $compile == "true" ]]; then

	if [[ -d $LOCALDESTDIR/include/gme ]]; then
		rm -rf $LOCALDESTDIR/include/gme
		rm -f $LOCALDESTDIR/lib/libgme.a
		rm -f $LOCALDESTDIR/lib/pkgconfig/libgme.pc
		make clean
	fi

    cmake -G "MSYS Makefiles" -DCMAKE_INSTALL_PREFIX=$LOCALDESTDIR -DBUILD_SHARED_LIBS=OFF

    make -j $cpuCount
    make install

    do_checkIfExist gme-git libgme.a

    compile="false"
else
    echo -------------------------------------------------
    echo "gme is already up to date"
    echo -------------------------------------------------
fi

echo "-------------------------------------------------------------------------------"
echo
echo "compile audio tools $bits done..."
echo
echo "-------------------------------------------------------------------------------"
	
cd $LOCALBUILDDIR
sleep 3
echo "-------------------------------------------------------------------------------"
echo
echo "compile video tools $bits"
echo
echo "-------------------------------------------------------------------------------"

do_git "https://git.chromium.org/git/webm/libvpx.git" libvpx-git noDepth

if [[ $compile == "true" ]]; then
	if [ -d $LOCALDESTDIR/include/vpx ]; then
		rm -rf $LOCALDESTDIR/include/vpx
		rm -f $LOCALDESTDIR/lib/pkgconfig/vpx.pc
		rm -f $LOCALDESTDIR/lib/libvpx.a
		make clean
	fi
	
	if [[ $bits = "64bit" ]]; then
		LDFLAGS="$LDFLAGS -static-libgcc -static" ./configure --prefix=$LOCALDESTDIR --target=x86_64-win64-gcc --disable-shared --enable-static --disable-unit-tests --disable-docs --enable-postproc --enable-vp9-postproc --enable-runtime-cpu-detect
		sed -i 's/HAVE_GNU_STRIP=yes/HAVE_GNU_STRIP=no/g' libs-x86_64-win64-gcc.mk
	else
		LDFLAGS="$LDFLAGS -static-libgcc -static" ./configure --prefix=$LOCALDESTDIR --target=x86-win32-gcc --disable-shared --enable-static --disable-unit-tests --disable-docs --enable-postproc --enable-vp9-postproc --enable-runtime-cpu-detect
		sed -i 's/HAVE_GNU_STRIP=yes/HAVE_GNU_STRIP=no/g' libs-x86-win32-gcc.mk
	fi 

	make -j $cpuCount
	make install
	
	mv $LOCALDESTDIR/bin/vpxdec.exe $LOCALDESTDIR/bin-video
	mv $LOCALDESTDIR/bin/vpxenc.exe $LOCALDESTDIR/bin-video
	
	do_checkIfExist libvpx-git libvpx.a
	compile="false"
	buildFFmpeg="true"
else
	echo -------------------------------------------------
	echo "libvpx-git is already up to date"
	echo -------------------------------------------------
fi

cd $LOCALBUILDDIR

do_git "https://github.com/ultravideo/kvazaar.git" kvazaar-git

if [[ $compile == "true" ]]; then
	cd src
	if [[ -f intra.o ]]; then
		make clean
	fi
	
	if [[ "$bits" = "32bit" ]]; then
		make ARCH=i686 -j $cpuCount
	else
		make ARCH=x86_64 -j $cpuCount
	fi 

	cp kvazaar.exe $LOCALDESTDIR/bin-video
	do_checkIfExist kvazaar-git bin-video/kvazaar.exe
	compile="false"
else
	echo -------------------------------------------------
	echo "kvazaar-git is already up to date"
	echo -------------------------------------------------
fi

cd $LOCALBUILDDIR

do_git "git://git.videolan.org/libdvdread.git" libdvdread-git

if [[ $compile == "true" ]]; then

	if [[ ! -f "configure" ]]; then
		autoreconf -fiv
	else 
		make uninstall
		make clean
	fi
	
	./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-video --disable-shared --disable-apidoc
	
	make -j $cpuCount
	make install

	do_checkIfExist libdvdread-git libdvdread.a
	compile="false"
else
	echo -------------------------------------------------
	echo "libdvdread-git is already up to date"
	echo -------------------------------------------------
fi

cd $LOCALBUILDDIR

do_git "git://git.videolan.org/libdvdnav.git" libdvdnav-git

if [[ $compile == "true" ]]; then

	if [[ ! -f "configure" ]]; then
		autoreconf -fiv
	else 
		make uninstall
		make clean
	fi
		
		./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-video --disable-shared
		
		make -j $cpuCount
		make install

		do_checkIfExist libdvdnav-git libdvdnav.a
		compile="false"
else
	echo -------------------------------------------------
	echo "libdvdnav-git is already up to date"
	echo -------------------------------------------------
fi

cd $LOCALBUILDDIR

do_git "git://git.videolan.org/libbluray.git" libbluray-git

if [[ $compile == "true" ]]; then

if [[ ! -f "configure" ]]; then
		autoreconf -fiv
	else 
		make uninstall
		make clean
	fi

	./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-video --disable-shared --enable-static --disable-examples --disable-bdjava --disable-doxygen-doc --disable-doxygen-dot LIBXML2_LIBS="-L$LOCALDESTDIR/lib -lxml2" LIBXML2_CFLAGS="-I$LOCALDESTDIR/include/libxml2 -DLIBXML_STATIC"

	make -j $cpuCount
	make install
	
	do_checkIfExist libbluray-git libbluray.a
	compile="false"
else
	echo -------------------------------------------------
	echo "libbluray-git is already up to date"
	echo -------------------------------------------------
fi

cd $LOCALBUILDDIR

echo -ne "\033]0;compile libutvideo-git $bits\007"
if [ ! -d libutvideo-git ]; then
	git clone "https://github.com/qyot27/libutvideo.git" libutvideo-git
	compile="true"
	cd libutvideo-git
else
	cd libutvideo-git
	oldHead=`git rev-parse HEAD`
	git pull origin buildsystem
	newHead=`git rev-parse HEAD`

	if [[ "$oldHead" != "$newHead" ]]; then
		compile="true"
	fi
fi

if [[ $compile == "true" ]]; then
	if [ -f $LOCALDESTDIR/lib/libutvideo.a ]; then
		make uninstall
		make clean
	fi

	./configure --cross-prefix=$cross --prefix=$LOCALDESTDIR

	make -j $cpuCount AR="${AR-ar}" RANLIB="${RANLIB-ranlib}"
	make install RANLIBX="${RANLIB-ranlib}"

	do_checkIfExist libutvideo-git libutvideo.a
	compile="false"
	buildFFmpeg="true"
else
	echo -------------------------------------------------
	echo "libutvideo is already up to date"
	echo -------------------------------------------------
fi

cd $LOCALBUILDDIR

do_git "https://github.com/libass/libass.git" libass-git

if [[ $compile == "true" ]]; then
	if [ -f $LOCALDESTDIR/lib/libass.a ]; then
		make uninstall
		make clean
	fi

	if [[ ! -f "configure" ]]; then
		./autogen.sh
	fi

	CPPFLAGS=' -DFRIBIDI_ENTRY="" ' ./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --enable-shared=no --disable-harfbuzz

	make -j $cpuCount
	make install

	sed -i 's/-lass -lm/-lass -lfribidi -lm/' "$LOCALDESTDIR/lib/pkgconfig/libass.pc"

	do_checkIfExist libass-git libass.a
	compile="false"
	buildFFmpeg="true"
else
	echo -------------------------------------------------
	echo "libass is already up to date"
	echo -------------------------------------------------
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libxavs.a" ]; then
	echo -------------------------------------------------
	echo "xavs is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile xavs $bits\007"
		rm -rf xavs
		
		svn checkout --trust-server-cert --non-interactive https://svn.code.sf.net/p/xavs/code/trunk/ xavs
		cd xavs
		
		./configure --host=$targetHost --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-video
		
		make -j $cpuCount
		make install
		
		do_checkIfExist xavs libxavs.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/bin-video/mediainfo.exe" ]; then
	echo -------------------------------------------------
	echo "MediaInfo_CLI is already compiled"
	echo -------------------------------------------------
	else
		echo -ne "\033]0;compile MediaInfo_CLI $bits\007"
		rm -rf mediainfo
		
		a=`wget -qO- "http://sourceforge.net/projects/mediainfo/files/source/mediainfo/" | sed "s/<tbody>/\n<tbody>\n/g;s/<\/tbody>/\n<\/tbody>\n/g" | awk "/<tbody>/,/<\/tbody>/" | grep "tr.*title.*class.*folder" | sed "s/<tr.\.*title=\d034//g;s/\d034 class.*$//g" | sed "q1" | sed "s/%%20//g" | sed "s/ //g"`

		b=`wget -qO- "http://sourceforge.net/projects/mediainfo/files/source/mediainfo/$a/" | sed "s/<tbody>/\n<tbody>\n/g;s/<\/tbody>/\n<\/tbody>\n/g" | awk "/<tbody>/,/<\/tbody>/" | grep "tr.*title.*class.*file" | sed "s/<tr.\.*title=\d034//g;s/\d034 class.*$//g" | grep "7z" | sed "s/ //g"`

		wget --tries=20 --retry-connrefused --waitretry=2 -c -O mediainfo.7z "http://sourceforge.net/projects/mediainfo/files/source/mediainfo/$a/$b/download"
		
		mkdir mediainfo
		cd mediainfo
		7za x ../mediainfo.7z
		rm ../mediainfo.7z
		
		sed -i '/#include <windows.h>/ a\#include <time.h>' ZenLib/Source/ZenLib/Ztring.cpp
		cd ZenLib/Project/GNU/Library
		
		./autogen
		./configure --build=$targetBuild --host=$targetHost
		
		if [[ $bits = "64bit" ]]; then
			sed -i 's/ -DSIZE_T_IS_LONG//g' Makefile
		fi
		make -j $cpuCount
		
		cd ../../../../MediaInfoLib/Project/GNU/Library
		
		./autogen
		
		./configure --build=$targetBuild --host=$targetHost LDFLAGS="$LDFLAGS -static-libgcc"
		
		if [[ $bits = "64bit" ]]; then
			sed -i 's/ -DSIZE_T_IS_LONG//g' Makefile
		fi
		
		make -j $cpuCount
		
		cd ../../../../MediaInfo/Project/GNU/CLI
		./autogen
		./configure --build=$targetBuild --host=$targetHost --enable-staticlibs --enable-shared=no LDFLAGS="$LDFLAGS -static-libgcc"
		
		if [[ $bits = "64bit" ]]; then
			sed -i 's/ -DSIZE_T_IS_LONG//g' Makefile
		fi
		
		make -j $cpuCount
		
		cp mediainfo.exe $LOCALDESTDIR/bin-video/mediainfo.exe

		do_checkIfExist mediainfo bin-video/mediainfo.exe
fi

cd $LOCALBUILDDIR

do_git "https://github.com/georgmartius/vid.stab.git" vidstab-git

if [[ $compile == "true" ]]; then
	if [ -d "build" ]; then
		cd build
		rm -rf $LOCALDESTDIR/include/vid.stab
		make clean
		rm -rf *
	else
		mkdir build
		cd build
	fi

	cmake .. -G "MSYS Makefiles" -DCMAKE_INSTALL_PREFIX=$LOCALDESTDIR -DBUILD_SHARED_LIBS:BOOL=off
	
	make -j $cpuCount
	make install
	
	do_checkIfExist vidstab-git libvidstab.a
	compile="false"
	buildFFmpeg="true"
else
	echo -------------------------------------------------
	echo "vidstab is already up to date"
	echo -------------------------------------------------
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libcaca.a" ]; then
	echo -------------------------------------------------
	echo "libcaca-0.99.beta19 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile libcaca $bits\007"
		rm -rf libcaca-0.99.beta19
		wget --tries=20 --retry-connrefused --waitretry=2 --no-check-certificate -c https://fossies.org/linux/privat/libcaca-0.99.beta19.tar.gz
		tar xf libcaca-0.99.beta19.tar.gz
		rm libcaca-0.99.beta19.tar.gz
		cd libcaca-0.99.beta19
		cd caca
		
		sed -i "s/#if defined _WIN32 && defined __GNUC__ && __GNUC__ >= 3/#if defined __MINGW__/g" string.c
		sed -i "s/#if defined(HAVE_VSNPRINTF_S)//g" string.c
		sed -i "s/vsnprintf_s(buf, bufsize, _TRUNCATE, format, args);//g" string.c
		sed -i "s/#elif defined(HAVE_VSNPRINTF)/#if defined(HAVE_VSNPRINTF)/g" string.c
		sed -i "s/#define HAVE_VSNPRINTF_S 1/#define HAVE_VSNPRINTF 1/g" ../win32/config.h
		sed -i "s/#if defined _WIN32 && defined __GNUC__ && __GNUC__ >= 3/#if defined __MINGW__/g" figfont.c
		sed -i "s/__declspec(dllexport)//g" *.h
		sed -i "s/__declspec(dllimport)//g" *.h 
		cd ..
		
		./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-video --disable-shared --disable-cxx --disable-csharp --disable-ncurses --disable-java --disable-python --disable-ruby --disable-imlib2 --disable-doc
		
		sed -i 's/ln -sf/$(LN_S)/' "caca/Makefile" "cxx/Makefile" "doc/Makefile"
		
		make -j $cpuCount
		make install
		
		do_checkIfExist libcaca-0.99.beta19 libcaca.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libzvbi.a" ]; then
	echo -------------------------------------------------
	echo "zvbi-0.2.35 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile libzvbi $bits\007"
		rm -rf zvbi-0.2.35
		wget --tries=20 --retry-connrefused --waitretry=2 -c -O zvbi-0.2.35.tar.bz2 http://sourceforge.net/projects/zapping/files/zvbi/0.2.35/zvbi-0.2.35.tar.bz2/download
		tar xf zvbi-0.2.35.tar.bz2
		rm zvbi-0.2.35.tar.bz2
		cd zvbi-0.2.35
		
		wget --tries=20 --retry-connrefused --waitretry=2 --no-check-certificate -c https://raw.github.com/jb-alvarado/media-autobuild_suite/master/patches/zvbi-win32.patch
		wget --tries=20 --retry-connrefused --waitretry=2 --no-check-certificate -c https://raw.github.com/jb-alvarado/media-autobuild_suite/master/patches/zvbi-ioctl.patch
		patch -p0 < zvbi-win32.patch
		patch -p0 < zvbi-ioctl.patch
		
		./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --disable-shared --disable-dvb --disable-bktr --disable-nls --disable-proxy --without-doxygen CFLAGS="$CFLAGS -DPTW32_STATIC_LIB" LIBS="$LIBS -lpng"
		
		cd src
		
		make -j $cpuCount
		make install
		
		cp ../zvbi-0.2.pc $LOCALDESTDIR/lib/pkgconfig
		
		do_checkIfExist zvbi-0.2.35 libzvbi.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/include/DeckLinkAPI.h" ]; then
	echo -------------------------------------------------
	echo "DeckLinkAPI is already downloaded"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;download DeckLinkAPI $bits\007"
		cd $LOCALDESTDIR/include
		wget --tries=20 --retry-connrefused --waitretry=2 --no-check-certificate -c https://raw.githubusercontent.com/jb-alvarado/media-autobuild_suite/master/includes/DeckLinkAPI.h
		wget --tries=20 --retry-connrefused --waitretry=2 --no-check-certificate -c https://raw.githubusercontent.com/jb-alvarado/media-autobuild_suite/master/includes/DeckLinkAPI_i.c
		
		if [ ! -f "$LOCALDESTDIR/include/DeckLinkAPI.h" ]; then
			echo -------------------------------------------------
			echo "DeckLinkAPI.h download failed..."
			echo "if you know there is no dependences hit enter for continue it," 
			echo "or run script again"
			read -p ""
			sleep 5
		else
			echo -
			echo -------------------------------------------------
			echo "download DeckLinkAPI done..."
			echo -------------------------------------------------
			echo -
		fi
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/include/frei0r.h" ]; then
	echo -------------------------------------------------
	echo "frei0r is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile frei0r $bits\007"
		rm -rf frei0r-plugins-1.4
		wget --tries=20 --retry-connrefused --waitretry=2 --no-check-certificate -c -O frei0r-plugins-1.4.tar.gz https://files.dyne.org/frei0r/releases/frei0r-plugins-1.4.tar.gz
		tar xf frei0r-plugins-1.4.tar.gz
		rm frei0r-plugins-1.4.tar.gz
		cd frei0r-plugins-1.4
		
		sed -i 's/find_package (Cairo)//' "CMakeLists.txt"
		
		mkdir build
		cd build 
		
		cmake -G "MSYS Makefiles" -DCMAKE_INSTALL_PREFIX=$LOCALDESTDIR ..
		
		make -j $cpuCount 
		make all install
		
		do_checkIfExist frei0r-plugins-1.4 frei0r-1/xfade0r.dll
fi

#------------------------------------------------
# final tools
#------------------------------------------------

cd $LOCALBUILDDIR

if [[ $mp4box = "y" ]]; then
	do_svn "http://svn.code.sf.net/p/gpac/code/trunk/gpac" gpac-svn

	if [[ $compile == "true" ]]; then
		if [ -f $LOCALDESTDIR/bin-video/MP4Box.exe ]; then
			rm $LOCALDESTDIR/bin-video/MP4Box.exe
			make uninstall
			make clean
		fi
		
		./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --static-mp4box --enable-static-bin --extra-libs="-lws2_32 -lwinmm -lz -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64" --use-ffmpeg=no --use-png=no --disable-ssl
		
		if [[ $bits = "64bit" ]]; then
			sed -i 's/ -fPIC//g' config.mak
		fi
		
		cd src
		make -j $cpuCount
		
		cd ../applications/mp4box
		make -j $cpuCount
		
		cd ../..
		make install-lib
		rm -f $LOCALDESTDIR/bin/libgpac.dll
		rm -f $LOCALDESTDIR/lib/libgpac.dll.a

		cp ./bin/gcc/MP4Box.exe $LOCALDESTDIR/bin-video
		
		do_checkIfExist gpac-svn bin-video/MP4Box.exe
		compile="false"
	else
		echo -------------------------------------------------
		echo "gpac-svn is already up to date"
		echo -------------------------------------------------
	fi
fi

cd $LOCALBUILDDIR

do_git "git://git.videolan.org/x264.git" x264-git noDepth

if [[ $compile == "true" ]]; then
	if [[ $x264 == "y" ]]; then
		cd $LOCALBUILDDIR

		do_git "https://github.com/FFmpeg/FFmpeg.git" ffmpeg-git

		echo "-------------------------------------------------------------------------------"
		echo "compile ffmpeg $bits libs"
		echo "-------------------------------------------------------------------------------"

		if [ -f "$LOCALDESTDIR/lib/libavcodec.a" ]; then 
			rm -rf $LOCALDESTDIR/include/libavutil
			rm -rf $LOCALDESTDIR/include/libavcodec
			rm -rf $LOCALDESTDIR/include/libpostproc
			rm -rf $LOCALDESTDIR/include/libswresample
			rm -rf $LOCALDESTDIR/include/libswscale
			rm -rf $LOCALDESTDIR/include/libavdevice
			rm -rf $LOCALDESTDIR/include/libavfilter
			rm -rf $LOCALDESTDIR/include/libavformat
			rm -f $LOCALDESTDIR/lib/libavutil.a
			rm -f $LOCALDESTDIR/lib/libswresample.a
			rm -f $LOCALDESTDIR/lib/libswscale.a
			rm -f $LOCALDESTDIR/lib/libavcodec.a
			rm -f $LOCALDESTDIR/lib/libavdevice.a
			rm -f $LOCALDESTDIR/lib/libavfilter.a
			rm -f $LOCALDESTDIR/lib/libavformat.a
			rm -f $LOCALDESTDIR/lib/libpostproc.a
			rm -f $LOCALDESTDIR/lib/pkgconfig/libavcodec.pc
			rm -f $LOCALDESTDIR/lib/pkgconfig/libavutil.pc
			rm -f $LOCALDESTDIR/lib/pkgconfig/libpostproc.pc
			rm -f $LOCALDESTDIR/lib/pkgconfig/libswresample.pc
			rm -f $LOCALDESTDIR/lib/pkgconfig/libswscale.pc
			rm -f $LOCALDESTDIR/lib/pkgconfig/libavdevice.pc
			rm -f $LOCALDESTDIR/lib/pkgconfig/libavfilter.pc
			rm -f $LOCALDESTDIR/lib/pkgconfig/libavformat.pc
		fi
		
		if [ -f "config.mak" ]; then
			make distclean
		fi
			
		if [[ $bits = "32bit" ]]; then
			arch='x86'
		else
			arch='x86_64'
		fi

		./configure --arch=$arch --target-os=mingw32 --prefix=$LOCALDESTDIR --disable-debug --disable-shared --disable-doc --enable-runtime-cpudetect --disable-programs --disable-devices --disable-filters --disable-encoders --disable-muxers

		make -j $cpuCount
		make install
		
		sed -i "s/ -lp11-kit//g" $LOCALDESTDIR/lib/pkgconfig/libavcodec.pc
		sed -i "s/ -lp11-kit//g" $LOCALDESTDIR/lib/pkgconfig/libavdevice.pc
		sed -i "s/ -lp11-kit//g" $LOCALDESTDIR/lib/pkgconfig/libavfilter.pc
		sed -i "s/ -lp11-kit//g" $LOCALDESTDIR/lib/pkgconfig/libavformat.pc
			
		do_checkIfExist ffmpeg-lib libavcodec.a

		cd $LOCALBUILDDIR/x264-git
		
		echo -ne "\033]0;compile x264-git $bits\007"
		
		if [ -f "$LOCALDESTDIR/lib/libx264.a" ]; then
			rm -f $LOCALDESTDIR/include/x264.h $LOCALDESTDIR/include/x264_config.h $LOCALDESTDIR/lib/libx264.a
			rm -f $LOCALDESTDIR/bin/x264.exe $LOCALDESTDIR/bin/x264-10bit.exe $LOCALDESTDIR/lib/pkgconfig/x264.pc
		fi
		
		if [ -f "libx264.a" ]; then
			make distclean
		fi
		
		./configure --host=$targetHost --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-video --enable-static --bit-depth=10 --enable-win32thread
		make -j $cpuCount
		
		cp x264.exe $LOCALDESTDIR/bin-video/x264-10bit.exe
		make clean

		./configure --host=$targetHost --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-video --enable-static --enable-win32thread

		make -j $cpuCount
		make install
		
		do_checkIfExist x264-git libx264.a
		compile="false"
		buildFFmpeg="true"
	else
		echo -ne "\033]0;compile libx264-git $bits\007"

		if [ -f "$LOCALDESTDIR/lib/libx264.a" ]; then
			rm -f $LOCALDESTDIR/include/x264.h $LOCALDESTDIR/include/x264_config.h $LOCALDESTDIR/lib/libx264.a
			rm -f $LOCALDESTDIR/lib/pkgconfig/x264.pc
		fi

		if [ -f "libx264.a" ]; then
			make distclean
		fi

		./configure --host=$targetHost --prefix=$LOCALDESTDIR --enable-static --enable-win32thread --disable-interlaced --disable-swscale --disable-lavf --disable-ffms --disable-gpac --disable-lsmash --bit-depth=8 --disable-cli

		make -j $cpuCount
		make install

		do_checkIfExist x264-git libx264.a
		compile="false"
		buildFFmpeg="true"
	fi
else
	echo -------------------------------------------------
	echo "x264 is already up to date"
	echo -------------------------------------------------
fi

cd $LOCALBUILDDIR

do_hg "https://bitbucket.org/multicoreware/x265" x265-hg

if [[ $compile == "true" ]]; then
	cd build/msys
	rm -rf *
	rm -f $LOCALDESTDIR/include/x265.h
	rm -f $LOCALDESTDIR/include/x265_config.h
	rm -f $LOCALDESTDIR/lib/libx265.a
	rm -f $LOCALDESTDIR/lib/pkgconfig/x265.pc

	if [[ $x265 == "y" ]]; then

		rm -f $LOCALDESTDIR/bin-video/x265-16bit.exe
		rm -f $LOCALDESTDIR/bin-video/x265.exe

		if [[ $bits = "32bit" ]]; then
			cmake -G "MSYS Makefiles" -DHIGH_BIT_DEPTH=1 -DENABLE_ASSEMBLY=OFF ../../source -DENABLE_SHARED:BOOLEAN=OFF -DHG_EXECUTABLE=/usr/bin/hg.bat -DCMAKE_CXX_FLAGS_RELEASE:STRING="-O3 -DNDEBUG $CXXFLAGS" -DCMAKE_EXE_LINKER_FLAGS_RELEASE:STRING="$LDFLAGS -static"
		else
			cmake -G "MSYS Makefiles" -DHIGH_BIT_DEPTH=1 ../../source -DENABLE_SHARED:BOOLEAN=OFF -DHG_EXECUTABLE=/usr/bin/hg.bat -DCMAKE_CXX_FLAGS_RELEASE:STRING="-O3 -DNDEBUG $CXXFLAGS" -DCMAKE_EXE_LINKER_FLAGS_RELEASE:STRING="$LDFLAGS -static"
		fi
		
		make -j $cpuCount
		cp x265.exe $LOCALDESTDIR/bin-video/x265-16bit.exe

		make clean
		rm -rf *

		cmake -G "MSYS Makefiles" -DCMAKE_INSTALL_PREFIX:PATH=$LOCALDESTDIR -DBIN_INSTALL_DIR=$LOCALDESTDIR/bin-video ../../source -DENABLE_SHARED:BOOLEAN=OFF -DHG_EXECUTABLE=/usr/bin/hg.bat -DCMAKE_CXX_FLAGS_RELEASE:STRING="-O3 -DNDEBUG $CXXFLAGS" -DCMAKE_EXE_LINKER_FLAGS_RELEASE:STRING="$LDFLAGS -static"
	else
		cmake -G "MSYS Makefiles" -DCMAKE_INSTALL_PREFIX:PATH=$LOCALDESTDIR -DENABLE_CLI:BOOLEAN=OFF ../../source -DENABLE_SHARED:BOOLEAN=OFF -DHG_EXECUTABLE=/usr/bin/hg.bat -DCMAKE_CXX_FLAGS="-static-libgcc -static-libstdc++" -DCMAKE_C_FLAGS="-static-libgcc -static-libstdc++"
	fi
	
	make -j $cpuCount
	make install

	do_checkIfExist x265-git libx265.a
	compile="false"
	buildFFmpeg="true"
else
	echo -------------------------------------------------
	echo "x265 is already up to date"
	echo -------------------------------------------------
fi

cd $LOCALBUILDDIR

if [[ $ffmbc = "y" ]]; then
	if [ -f "$LOCALDESTDIR/bin-video/ffmbc.exe" ]; then
		echo -------------------------------------------------
		echo "ffmbc-0.7.2 is already compiled"
		echo -------------------------------------------------
		else 
			echo -ne "\033]0;compile ffmbc $bits\007"
			
			if [[ $nonfree = "y" ]]; then
				extras="--enable-nonfree --enable-libfaac"
			else
				extras="" 
			fi
	
			rm -rf FFmbc-0.7.2
			wget --tries=20 --retry-connrefused --waitretry=2 --no-check-certificate -c -O FFmbc-0.7.2.tar.bz2 "https://drive.google.com/uc?id=0B0jxxycBojSwTEgtbjRZMXBJREU&export=download"
			tar xf FFmbc-0.7.2.tar.bz2 
			rm FFmbc-0.7.2.tar.bz2 
			cd FFmbc-0.7.2

			if [[ $bits = "32bit" ]]; then
				arch='x86'
			else
				arch='x86_64'
			fi
			
			./configure --arch=$arch --target-os=mingw32 --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-video --disable-debug --disable-shared --disable-doc --disable-avdevice --disable-dxva2 --disable-ffprobe --disable-w32threads --enable-gpl --enable-runtime-cpudetect --enable-bzlib --enable-zlib --enable-librtmp --enable-avisynth --enable-frei0r --enable-libopenjpeg --enable-libass --enable-libmp3lame --enable-libschroedinger --enable-libspeex --enable-libtheora --enable-libvorbis --enable-libvpx --enable-libxavs --enable-libx264 --enable-libxvid $extras --extra-cflags='-DPTW32_STATIC_LIB' --extra-libs='-ldl'
			
			make SRC_DIR=. -j $cpuCount 
			make SRC_DIR=. install-progs
			
			do_checkIfExist FFmbc-0.7.2 bin-video/ffmbc.exe
	fi
fi

cd $LOCALBUILDDIR

if [[ $ffmpeg = "y" ]] || [[ $ffmpeg = "s" ]]; then
	if [[ $nonfree = "y" ]]; then
		extras="--enable-nonfree --enable-libfaac --enable-libfdk-aac"
	  else
		extras="" 
	fi
	
	echo "-------------------------------------------------------------------------------"
	echo "compile ffmpeg $bits"
	echo "-------------------------------------------------------------------------------"

	do_git "https://github.com/FFmpeg/FFmpeg.git" ffmpeg-git

	if [[ $compile == "true" ]] || [[ $buildFFmpeg == "true" ]]; then
		if [ -f "$LOCALDESTDIR/lib/libavcodec.a" ]; then 
			rm -rf $LOCALDESTDIR/include/libavutil
			rm -rf $LOCALDESTDIR/include/libavcodec
			rm -rf $LOCALDESTDIR/include/libpostproc
			rm -rf $LOCALDESTDIR/include/libswresample
			rm -rf $LOCALDESTDIR/include/libswscale
			rm -rf $LOCALDESTDIR/include/libavdevice
			rm -rf $LOCALDESTDIR/include/libavfilter
			rm -rf $LOCALDESTDIR/include/libavformat
			rm -f $LOCALDESTDIR/lib/libavutil.a
			rm -f $LOCALDESTDIR/lib/libswresample.a
			rm -f $LOCALDESTDIR/lib/libswscale.a
			rm -f $LOCALDESTDIR/lib/libavcodec.a
			rm -f $LOCALDESTDIR/lib/libavdevice.a
			rm -f $LOCALDESTDIR/lib/libavfilter.a
			rm -f $LOCALDESTDIR/lib/libavformat.a
			rm -f $LOCALDESTDIR/lib/libpostproc.a
			rm -f $LOCALDESTDIR/lib/pkgconfig/libavcodec.pc
			rm -f $LOCALDESTDIR/lib/pkgconfig/libavutil.pc
			rm -f $LOCALDESTDIR/lib/pkgconfig/libpostproc.pc
			rm -f $LOCALDESTDIR/lib/pkgconfig/libswresample.pc
			rm -f $LOCALDESTDIR/lib/pkgconfig/libswscale.pc
			rm -f $LOCALDESTDIR/lib/pkgconfig/libavdevice.pc
			rm -f $LOCALDESTDIR/lib/pkgconfig/libavfilter.pc
			rm -f $LOCALDESTDIR/lib/pkgconfig/libavformat.pc
		fi
		
		if [ -f "config.mak" ]; then
			make distclean
		fi
			
		if [[ $bits = "32bit" ]]; then
			arch='x86'
		else
			arch='x86_64'
		fi
			
		if [[ $ffmpeg = "s" ]]; then
			if [ -f "$LOCALDESTDIR/bin-video/ffmpegSHARED/bin/ffmpeg.exe" ]; then 
				rm -rf $LOCALDESTDIR/bin-video/ffmpegSHARED
				make distclean
			fi
			CPPFLAGS='-DFRIBIDI_ENTRY=""' LDFLAGS="$LDFLAGS -static-libgcc" ./configure \
			--arch=$arch --target-os=mingw32 --prefix=$LOCALDESTDIR/bin-video/ffmpegSHARED \
			--disable-debug --disable-static --disable-doc --disable-w32threads --enable-shared \
			--enable-gpl --enable-version3 --enable-runtime-cpudetect --enable-avfilter --enable-bzlib \
			--enable-zlib --enable-librtmp --enable-gnutls --enable-avisynth --enable-frei0r --enable-filter=frei0r \
			--enable-libbluray --enable-libcaca --enable-libopenjpeg --enable-fontconfig --enable-libfreetype \
			--enable-libass --enable-libgsm --enable-libilbc --enable-libmodplug --enable-libmp3lame \
			--enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libvo-amrwbenc --enable-libschroedinger \
			--enable-libsoxr --enable-libtwolame --enable-libspeex --enable-libtheora --enable-libvorbis \
			--enable-libvo-aacenc --enable-libopus --enable-libvidstab --enable-libvpx --enable-libwavpack \
			--enable-libxavs --enable-libx264 --enable-libx265 --enable-libxvid --enable-libzvbi \
			--enable-libgme --enable-libdcadec $extras \
			--extra-cflags='-DPTW32_STATIC_LIB -DLIBTWOLAME_STATIC -DCACA_STATIC -DMODPLUG_STATIC' \
			--extra-libs='-lxml2 -llzma -lstdc++ -lpng -lm -lpthread -lwsock32 -lhogweed -lnettle -lgmp -ltasn1 -lws2_32 -lwinmm -lgdi32 -lcrypt32 -lintl -lz -liconv -lole32 -loleaut32' --extra-ldflags='-mconsole -Wl,--allow-multiple-definition'
		else
			if [ -f "$LOCALDESTDIR/bin-video/ffmpegSHARED/bin/ffmpeg.exe" ]; then
				make distclean
			fi
			CPPFLAGS='-DFRIBIDI_ENTRY=""' ./configure \
			--arch=$arch --target-os=mingw32 --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-video \
			--disable-debug --disable-shared --disable-doc --disable-w32threads --enable-gpl \
			--enable-version3 --enable-runtime-cpudetect --enable-avfilter --enable-bzlib --enable-zlib \
			--enable-decklink --enable-librtmp --enable-gnutls --enable-avisynth --enable-frei0r \
			--enable-filter=frei0r --enable-libbluray --enable-libcaca --enable-libopenjpeg \
			--enable-fontconfig --enable-libfreetype --enable-libass --enable-libgsm --enable-libilbc \
			--enable-libmodplug --enable-libmp3lame --enable-libopencore-amrnb --enable-libopencore-amrwb \
			--enable-libvo-amrwbenc --enable-libschroedinger --enable-libsoxr --enable-libtwolame \
			--enable-libspeex --enable-libtheora --enable-libutvideo --enable-libvorbis --enable-libvo-aacenc \
			--enable-libopus --enable-libvidstab --enable-libvpx --enable-libwavpack --enable-libxavs \
			--enable-libx264 --enable-libx265 --enable-libxvid --enable-libzvbi \
			--enable-libgme --enable-libdcadec $extras \
			--extra-cflags='-DPTW32_STATIC_LIB -DLIBTWOLAME_STATIC -DCACA_STATIC -DMODPLUG_STATIC' \
			--extra-libs='-lxml2 -llzma -lstdc++ -lpng -lm -lpthread -lwsock32 -lhogweed -lnettle -lgmp -ltasn1 -lws2_32 -lwinmm -lgdi32 -lcrypt32 -lintl -lz -liconv -lole32 -loleaut32' --extra-ldflags='-mconsole -Wl,--allow-multiple-definition'
			
			newFfmpeg="yes"
		fi

		sed -i "s|--target-os=mingw32 --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-video ||g" config.h
		
		sed -i "s/ --extra-cflags='-DPTW32_STATIC_LIB -DLIBTWOLAME_STATIC -DCACA_STATIC -DMODPLUG_STATIC' --extra-libs='-lxml2 -llzma -lstdc++ -lpng -lm -lpthread -lwsock32 -lhogweed -lnettle -lgmp -ltasn1 -lws2_32 -lwinmm -lgdi32 -lcrypt32 -lintl -lz -liconv -lole32 -loleaut32' --extra-ldflags='-mconsole -Wl,--allow-multiple-definition'//g" config.h
		
		make -j $cpuCount
		make install
		
		if [[ ! $ffmpeg = "s" ]]; then
			sed -i "s/ -lp11-kit//g" $LOCALDESTDIR/lib/pkgconfig/libavcodec.pc
			sed -i "s/ -lp11-kit//g" $LOCALDESTDIR/lib/pkgconfig/libavdevice.pc
			sed -i "s/ -lp11-kit//g" $LOCALDESTDIR/lib/pkgconfig/libavfilter.pc
			sed -i "s/ -lp11-kit//g" $LOCALDESTDIR/lib/pkgconfig/libavformat.pc
			sed -i "s/Libs: -L\${libdir}  -lswresample -lm/Libs: -L\${libdir}  -lswresample -lm -lsoxr/g" $LOCALDESTDIR/lib/pkgconfig/libswresample.pc
			
			do_checkIfExist ffmpeg-git libavcodec.a
		else 
			do_checkIfExist ffmpeg-git bin-video/ffmpegSHARED/bin/ffmpeg.exe
		fi
			
		compile="false"
	else
		echo -------------------------------------------------
		echo "ffmpeg is already up to date"
		echo -------------------------------------------------
	fi
fi

if [[ $bits = "64bit" ]]; then
	cd $LOCALBUILDDIR

	do_git "http://f265.org/repos/f265/" f265-git noDepth

	if [[ $compile == "true" ]] && [[ ! $ffmpeg == "s" ]] || [[ $newFfmpeg == "yes" ]]; then
		if [ -d "build" ]; then
			rm -rf build
			rm -rf .sconf_temp
			rm -f .sconsign.dblite
			rm -f config.log
			rm -f options.py
		fi
		
		scons

		if [ -f build/f265cli.exe ]; then
			rm -f $LOCALDESTDIR/bin-video/f265cli.exe
			cp build/f265cli.exe $LOCALDESTDIR/bin-video/f265cli.exe
		fi
		
		do_checkIfExist f265-git bin-video/f265cli.exe
		compile="false"
	else
		echo -------------------------------------------------
		echo "f265 is already up to date"
		echo -------------------------------------------------
	fi
fi

cd $LOCALBUILDDIR

if [[ $nonfree = "y" ]]; then
    faac=""
  elif [[ $nonfree = "n" ]]; then
      faac="--disable-faac --disable-faac-lavc" 
fi	

if [[ $mplayer = "y" ]]; then
	do_svn "svn://svn.mplayerhq.hu/mplayer/trunk" mplayer-svn
	
	if [ -d "ffmpeg" ]; then
		cd ffmpeg
		oldHead=`git rev-parse HEAD`
		git pull origin master
		newHead=`git rev-parse HEAD`
		cd ..
	fi 

	if [[ $compile == "true" ]] || [[ "$oldHead" != "$newHead"  ]] || [[ $buildFFmpeg == "true" ]]; then
		if [ -f $LOCALDESTDIR/bin-video/mplayer.exe ]; then
			make uninstall
			make distclean
		fi
		
		if ! test -e ffmpeg ; then
			if ! git clone --depth 1 git://source.ffmpeg.org/ffmpeg.git ffmpeg ; then
				rm -rf ffmpeg
				echo "Failed to get a FFmpeg checkout"
				echo "Please try again or put FFmpeg source code copy into ffmpeg/ manually."
				echo "Nightly snapshot: http://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2"
				echo "To use a github mirror via http (e.g. because a firewall blocks git):"
				echo "git clone --depth 1 https://github.com/FFmpeg/FFmpeg ffmpeg; touch ffmpeg/mp_auto_pull"
				exit 1
			fi
			touch ffmpeg/mp_auto_pull
		fi
		
		sed -i '/#include "mp_msg.h/ a\#include <windows.h>' libmpcodecs/ad_spdif.c
		 
		CPPFLAGS='-DFRIBIDI_ENTRY=""' ./configure --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-video --cc=gcc --extra-cflags='-DPTW32_STATIC_LIB -O3 -std=gnu99 -DLIBTWOLAME_STATIC -DMODPLUG_STATIC' --extra-libs='-lxml2 -llzma -lfreetype -lz -lbz2 -liconv -lws2_32 -lpthread -lwinpthread -lpng -lwinmm' --extra-ldflags='-Wl,--allow-multiple-definition' --enable-static --enable-runtime-cpudetection --enable-ass-internal --enable-bluray --disable-gif --enable-freetype $faac
		
		make -j $cpuCount
		make install

		do_checkIfExist mplayer-svn bin-video/mplayer.exe
		compile="false"
		else
		echo -------------------------------------------------
		echo "mplayer is already up to date"
		echo -------------------------------------------------
	fi
fi

cd $LOCALBUILDDIR

if [[ $mpv = "y" ]]; then

	do_git "https://github.com/lachs0r/rubberband.git" rubberband-git

	if [[ $compile == "true" ]]; then

		if [[ ! -f "$LOCALDESTDIR/lib/librubberband.a" ]]; then
			make PREFIX=$LOCALDESTDIR uninstall
			make clean
		fi

		make PREFIX=$LOCALDESTDIR install-static

		do_checkIfExist rubberband-git librubberband.a
		compile="false"
	else
		echo -------------------------------------------------
		echo "rubberband is already up to date"
		echo -------------------------------------------------
	fi

	cd $LOCALBUILDDIR

	do_git "https://github.com/mpv-player/mpv.git" mpv-git
	
	if [[ $compile == "true" ]] && [[ ! $ffmpeg == "s" ]] || [[ $newFfmpeg == "yes" ]]; then
		if [ ! -f waf ]; then
			python2 ./bootstrap.py
		else
			python2 ./waf distclean
			rm waf
			rm -rf .waf-*
			rm -rf $LOCALDESTDIR/bin-video/mpv
			python2 ./bootstrap.py
		fi
		
		CFLAGS="$CFLAGS -DCACA_STATIC" LDFLAGS="$LDFLAGS -Wl,--allow-multiple-definition" python2 ./waf configure --prefix=$LOCALDESTDIR/bin-video/mpv --disable-debug-build --enable-static-build --enable-sdl2 --disable-manpage-build --disable-pdf-build

		if [[ $bits = "32bit" ]]; then
			sed -i "s/LIBPATH_libav = .*/LIBPATH_libav = ['\/local32\/lib', '\/mingw32\/lib']/g" ./build/c4che/_cache.py
			sed -i "s/LIBPATH_libavdevice = .*/LIBPATH_libavdevice = ['\/local32\/lib', '\/mingw32\/lib']/g" ./build/c4che/_cache.py
			sed -i "s/LIBPATH_libavfilter = .*/LIBPATH_libavfilter = ['\/local32\/lib', '\/mingw32\/lib']/g" ./build/c4che/_cache.py
		else
			sed -i "s/LIBPATH_libav = .*/LIBPATH_libav = ['\/local64\/lib', '\/mingw64\/lib']/g" ./build/c4che/_cache.py
			sed -i "s/LIBPATH_libavdevice = .*/LIBPATH_libavdevice = ['\/local64\/lib', '\/mingw64\/lib']/g" ./build/c4che/_cache.py
			sed -i "s/LIBPATH_libavfilter = .*/LIBPATH_libavfilter = ['\/local64\/lib', '\/mingw64\/lib']/g" ./build/c4che/_cache.py
		fi
		
		python2 ./waf build -j $cpuCount
		python2 ./waf install
		
		if [ ! -d "$LOCALDESTDIR/bin-video/mpv/lua" ]; then
			mkdir $LOCALDESTDIR/bin-video/mpv/lua
			cp player/lua/*.lua $LOCALDESTDIR/bin-video/mpv/lua
		fi
		
		do_checkIfExist mpv-git bin-video/mpv/bin/mpv.exe
		compile="false"
	fi
fi

cd $LOCALBUILDDIR

if [[ $mkv = "y" ]]; then
	do_git "https://github.com/mbunkus/mkvtoolnix.git" mkvtoolnix-git
	
	if [[ $compile == "true" ]]; then
		if [[ ! -f ./configure ]]; then
			./autogen.sh
			git submodule init
			git submodule update
		else
			rake clean
			rm -rf $LOCALDESTDIR/bin-video/mkvtoolnix
		fi
		
		if [[ ! -f ./mkvinfo.patch ]]; then
			wget --tries=20 --retry-connrefused --waitretry=2 --no-check-certificate -c https://raw.github.com/jb-alvarado/media-autobuild_suite/master/patches/mkvinfo.patch
		fi
		
		patch -N -p0 < mkvinfo.patch
		
		./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR/bin-video/mkvtoolnix --without-curl --with-boost-libdir=$MINGW_PREFIX/lib
		
		sed -i "s/EXTRA_CFLAGS = *$/EXTRA_CFLAGS = -static-libgcc -static-libstdc++ -static/g" build-config
		sed -i "s/EXTRA_LDFLAGS = *$/EXTRA_LDFLAGS = -static-libgcc -static-libstdc++ -static/g" build-config
		sed -i "s/LIBINTL_LIBS = -lintl*$/LIBINTL_LIBS = -lintl -liconv/g" build-config
		
		export DRAKETHREADS=$cpuCount
		
		drake
		rake install
		
		mkdir -p $LOCALDESTDIR/bin-video/mkvtoolnix/bin/doc
		mv $LOCALDESTDIR/bin-video/mkvtoolnix/share/locale $LOCALDESTDIR/bin-video/mkvtoolnix/bin/locale
		mv $LOCALDESTDIR/bin-video/mkvtoolnix/share/doc/mkvtoolnix/guide $LOCALDESTDIR/bin-video/mkvtoolnix/bin/doc/guide
		cp -r examples $LOCALDESTDIR/bin-video/mkvtoolnix/bin/examples
		unset DRAKETHREADS

		do_checkIfExist mkvtoolnix-git bin-video/mkvtoolnix/bin/mkvmerge.exe

		compile="false"
	fi
fi
	
if [[ $stripping = "y" ]]; then
	cd $LOCALDESTDIR
	
	echo -ne "\033]0;strip $bits binaries\007"
	echo
	echo "-------------------------------------------------------------------------------"
	echo
	FILES=`find ./bin* ./lib -regex ".*\.\(exe\|dll\)" -mmin -600`
	
	for f in $FILES; do 
		strip --strip-all $f
		echo "strip $f done..."
	done
	
fi

if [[ $packing = "y" ]]; then
	if [ ! -f "$LOCALBUILDDIR/upx391w/upx.exe" ]; then
		echo -ne "\033]0;Download UPX\007"
		cd $LOCALBUILDDIR
		rm -rf upx391w
		wget --tries=20 --retry-connrefused --waitretry=2 -c http://upx.sourceforge.net/download/upx391w.zip
		unzip upx391w.zip
		rm upx391w.zip
	fi
	echo -ne "\033]0;pack $bits binaries\007"
	echo
	echo "-------------------------------------------------------------------------------"
	echo
	cd $LOCALDESTDIR
	FILES=`find ./bin-*  -regex ".*\.\(exe\|dll\)" -mmin -600`
	
	for f in $FILES; do
		if [[ $stripping = "y" ]]; then
			$LOCALBUILDDIR/upx391w/upx.exe -9 -q $f
		else
			$LOCALBUILDDIR/upx391w/upx.exe -9 -q --strip-relocs=0 $f
		fi
		echo "pack $f done..."
	done
fi


echo "-------------------------------------------------------------------------------"
echo
echo "compile video tools $bits done..."
echo
echo "-------------------------------------------------------------------------------"
}

if [[ $build32 = "yes" ]]; then
	source /local32/etc/profile.local
	buildProcess
	echo "-------------------------------------------------------------------------------"
	echo "compile all tools 32bit done..."
	echo "-------------------------------------------------------------------------------"
	sleep 3
fi

if [[ $build64 = "yes" ]]; then
	source /local64/etc/profile.local
	buildProcess
	echo "-------------------------------------------------------------------------------"
	echo "compile all tools 64bit done..."
	echo "-------------------------------------------------------------------------------"
	sleep 3
fi

echo -ne "\033]0;compiling done...\007"
echo
echo "Window close in 15"
echo 
sleep 5
echo 
echo "Window close in 10"
echo
sleep 5
echo
echo "Window close in 5"
sleep 5

