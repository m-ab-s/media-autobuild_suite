# set CPU count global. This can be overwrite from the compiler script (media-autobuild_suite.bat)
cpuCount=1
while true; do
  case $1 in
--cpuCount=* ) cpuCount="${1#*=}"; shift ;;
--build32=* ) build32="${1#*=}"; shift ;;
--build64=* ) build64="${1#*=}"; shift ;;
--deleteSource=* ) deleteSource="${1#*=}"; shift ;;
    -- ) shift; break ;;
    -* ) echo "Error, unknown option: '$1'."; exit 1 ;;
    * ) break ;;
  esac
done

cd $pwd
if [ ! -f ".gitconfig" ]; then
echo -------------------------------------------------
echo "build git config..."
echo -------------------------------------------------
cat > .gitconfig << "EOF"
[core]
	autocrlf = false
EOF
fi

# check if compiled file exist
do_checkIfExist() {
	local packetName="$1"
	local fileName="$2"
	local fileExtension=${fileName##*.}
	if [[ "$fileExtension" = "exe" ]]; then
		if [ -f "$GLOBALDESTDIR/bin/$fileName" ]; then
			echo -
			echo -------------------------------------------------
			echo "build $packetName done..."
			echo -------------------------------------------------
			echo -
			if [[ $deleteSource = "y" ]]; then
				if [[ ! "${packetName: -4}" = "-git" ]]; then
					if [[ ! "${packetName: -3}" = "-hg" ]]; then
						cd $LOCALBUILDDIR
						rm -rf $LOCALBUILDDIR/$packetName
					fi
				fi
			fi
			else
				echo -------------------------------------------------
				echo "build $packetName failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi	
	elif [[ "$fileExtension" = "a" ]]; then
		if [ -f "$GLOBALDESTDIR/lib/$fileName" ]; then
			echo -
			echo -------------------------------------------------
			echo "build $packetName done..."
			echo -------------------------------------------------
			echo -
			if [[ $deleteSource = "y" ]]; then
				if [[ ! "${packetName: -4}" = "-git" ]]; then
					if [[ ! "${packetName: -3}" = "-hg" ]]; then
						cd $LOCALBUILDDIR
						rm -rf $LOCALBUILDDIR/$packetName
					fi
				fi
			fi
			else
				echo -------------------------------------------------
				echo "build $packetName failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi	
	fi
}

buildProcess() {
cd $LOCALBUILDDIR

if [ -f "$GLOBALDESTDIR/lib/libdl.a" ]; then
	echo -------------------------------------------------
	echo "dlfcn-win32-r19 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile dlfcn-win32 $bits\007"
		if [ -d "dlfcn-win32-r19" ]; then rm -rf dlfcn-win32-r19; fi
		wget --tries=20 --retry-connrefused --waitretry=2 -c http://dlfcn-win32.googlecode.com/files/dlfcn-win32-r19.tar.bz2
		tar xf dlfcn-win32-r19.tar.bz2
		rm dlfcn-win32-r19.tar.bz2
		cd dlfcn-win32-r19
		./configure --prefix=$GLOBALDESTDIR --libdir=$GLOBALDESTDIR/lib --incdir=$GLOBALDESTDIR/include --disable-shared --enable-static
		make
		make install
		
		do_checkIfExist dlfcn-win32-r19 libdl.a
fi		

#cd $LOCALBUILDDIR

#if [ -f "$GLOBALDESTDIR/lib/libpthread.a" ]; then
#	echo -------------------------------------------------
#	echo "pthreads-w32-2-9-1-release is already compiled"
#	echo -------------------------------------------------
#	else 
#		echo -ne "\033]0;compile pthreads-w32 $bits\007"
#		if [ -d "pthreads-w32-2-9-1-release" ]; then rm -rf pthreads-w32-2-9-1-release; fi
#		wget --tries=20 --retry-connrefused --waitretry=2 -c ftp://sourceware.org/pub/pthreads-win32/pthreads-w32-2-9-1-release.tar.gz
#		tar xf pthreads-w32-2-9-1-release.tar.gz
#		rm pthreads-w32-2-9-1-release.tar.gz
#		cd pthreads-w32-2-9-1-release
#		make clean GC-static
#		cp libpthreadGC2.a $GLOBALDESTDIR/lib/libpthreadGC2.a || exit 1
#		cp libpthreadGC2.a $GLOBALDESTDIR/lib/libpthread.a || exit 1
#		cp pthread.h sched.h semaphore.h $GLOBALDESTDIR/include || exit 1
		
#		do_checkIfExist pthreads-w32-2-9-1-release libpthread.a
#fi

cd $LOCALBUILDDIR

if [ -f "$GLOBALDESTDIR/lib/libopenjpeg.a" ]; then
	echo -------------------------------------------------
	echo "openjpeg-1.5.1 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile openjpeg $bits\007"
		if [ -d "openjpeg-1.5.1" ]; then rm -rf openjpeg-1.5.1; fi
		wget --tries=20 --retry-connrefused --waitretry=2 -c "http://openjpeg.googlecode.com/files/openjpeg-1.5.1.tar.gz"
		tar xf openjpeg-1.5.1.tar.gz
		rm openjpeg-1.5.1.tar.gz
		cd openjpeg-1.5.1
		./configure --build=$targetBuild --host=$targetHost --prefix=$GLOBALDESTDIR --enable-shared=no LIBS="$LIBS -lpng -ljpeg -lz" CFLAGS="$CFLAGS -DOPJ_STATIC"
				
		make
		make install
		cp libopenjpeg.pc $GLOBALDESTDIR/lib/pkgconfig
		
		do_checkIfExist openjpeg-1.5.1 libopenjpeg.a
fi

cd $LOCALBUILDDIR

if [ -f "$GLOBALDESTDIR/lib/libjasper.a" ]; then
	echo -------------------------------------------------
	echo "jasper-1.900.1 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile jasper $bits\007"
		if [ -d "jasper-1.900.1" ]; then rm -rf jasper-1.900.1; fi
		wget --tries=20 --retry-connrefused --waitretry=2 -c http://www.ece.uvic.ca/~frodo/jasper/software/jasper-1.900.1.zip
		unzip jasper-1.900.1.zip
		rm jasper-1.900.1.zip
		cd jasper-1.900.1
		./configure --build=$targetBuild --host=$targetHost --prefix=$GLOBALDESTDIR --enable-static=no
		make -j $cpuCount
		make install
		
		do_checkIfExist jasper-1.900.1 libjasper.a
fi

cd $LOCALBUILDDIR

if [ -f "$GLOBALDESTDIR/lib/libfreetype.a" ]; then
	echo -------------------------------------------------
	echo "freetype-2.4.10 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile freetype $bits\007"
		if [ -d "freetype-2.4.10" ]; then rm -rf freetype-2.4.10; fi
		#wget --tries=20 --retry-connrefused --waitretry=2 -c "http://downloads.sourceforge.net/project/freetype/freetype2/2.5.0/freetype-2.5.0.1.tar.gz"
		wget --tries=20 --retry-connrefused --waitretry=2 -c http://download.savannah.gnu.org/releases/freetype/freetype-2.4.10.tar.gz
		tar xf freetype-2.4.10.tar.gz
		rm freetype-2.4.10.tar.gz
		cd freetype-2.4.10
		./configure --build=$targetBuild --host=$targetHost --prefix=$GLOBALDESTDIR --disable-shared
		make -j $cpuCount
		make install
		
		do_checkIfExist freetype-2.4.10 libfreetype.a
fi

cd $LOCALBUILDDIR

if [ -f "$GLOBALDESTDIR/lib/libfontconfig.a" ]; then
	echo -------------------------------------------------
	echo "fontconfig-2.10.2 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile fontconfig $bits\007"
		if [ -d "fontconfig-2.10.2" ]; then rm -rf fontconfig-2.10.2; fi
		wget --tries=20 --retry-connrefused --waitretry=2 -c http://www.freedesktop.org/software/fontconfig/release/fontconfig-2.10.2.tar.gz
		tar xf fontconfig-2.10.2.tar.gz
		rm fontconfig-2.10.2.tar.gz
		cd fontconfig-2.10.2
		./configure --build=$targetBuild --host=$targetHost --prefix=$GLOBALDESTDIR --enable-shared=no
		make -j $cpuCount
		make install
		sed -i 's/-L${libdir} -lfontconfig[^l]*$/-L${libdir} -lfontconfig -lfreetype -lexpat/' "$GLOBALDESTDIR/lib/pkgconfig/fontconfig.pc"
		
		do_checkIfExist fontconfig-2.10.2 libfontconfig.a
fi

cd $LOCALBUILDDIR

if [ -f "$GLOBALDESTDIR/lib/libfribidi.a" ]; then
	echo -------------------------------------------------
	echo "fribidi-0.19.4 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile fribidi $bits\007"
		if [ -d "fribidi-0.19.4" ]; then rm -rf fribidi-0.19.4; fi
		wget --tries=20 --retry-connrefused --waitretry=2 -c http://fribidi.org/download/fribidi-0.19.4.tar.bz2
		tar xf fribidi-0.19.4.tar.bz2
		rm fribidi-0.19.4.tar.bz2
		cd fribidi-0.19.4
		wget --tries=20 --retry-connrefused --waitretry=2 --no-check-certificate -c https://raw.github.com/jb-alvarado/media-autobuild_suite/master/patches/fribidi.diff
		patch -p0 < fribidi.diff
		./configure --build=$targetBuild --host=$targetHost --prefix=$GLOBALDESTDIR --enable-shared=no
		sed -i 's/-export-symbols-regex "^fribidi_.*" $(am__append_1)/-export-symbols-regex "^fribidi_.*" # $(am__append_1)/g' "lib/Makefile"
		make -j $cpuCount
		make install		

if [ ! -f ${GLOBALDESTDIR}/bin/fribidi-config ]; then
cat > ${GLOBALDESTDIR}/bin/fribidi-config << "EOF"
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

		do_checkIfExist fribidi-0.19.4 libfribidi.a
fi

cd $LOCALBUILDDIR

if [ -f "$GLOBALDESTDIR/lib/libSDL.a" ]; then
	echo -------------------------------------------------
	echo "SDL-1.2.15 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile SDL $bits\007"
		if [ -d "SDL-1.2.15" ]; then rm -rf SDL-1.2.15; fi
		wget --tries=20 --retry-connrefused --waitretry=2 -c http://www.libsdl.org/release/SDL-1.2.15.tar.gz
		tar xf SDL-1.2.15.tar.gz
		rm SDL-1.2.15.tar.gz
		cd SDL-1.2.15
		./configure --build=$targetBuild --host=$targetHost --prefix=$GLOBALDESTDIR --enable-shared=no
		make -j $cpuCount
		make install
		
		if [[ $bits = "32bit" ]]; then
			sed -i "s/-mwindows//" "/global32/bin/sdl-config"
			sed -i "s/-mwindows//" "/global32/lib/pkgconfig/sdl.pc"
		else
			sed -i "s/-mwindows//" "/global64/bin/sdl-config"
			sed -i "s/-mwindows//" "/global64/lib/pkgconfig/sdl.pc"
		fi
		
		do_checkIfExist SDL-1.2.15 libSDL.a
fi

cd $LOCALBUILDDIR

if [ -f "$GLOBALDESTDIR/lib/libSDL_image.a" ]; then
	echo -------------------------------------------------
	echo "SDL_image-1.2.12 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile SDL_imagae $bits\007"
		if [ -d "SDL_image-1.2.12" ]; then rm -rf SDL_image-1.2.12; fi
		wget --tries=20 --retry-connrefused --waitretry=2 -c http://www.libsdl.org/projects/SDL_image/release/SDL_image-1.2.12.tar.gz
		tar xf SDL_image-1.2.12.tar.gz
		rm SDL_image-1.2.12.tar.gz
		cd SDL_image-1.2.12
		./configure --build=$targetBuild --host=$targetHost --prefix=$GLOBALDESTDIR --enable-shared=no
		make -j $cpuCount
		make install
		
		do_checkIfExist SDL_image-1.2.12 libSDL_image.a
fi

#----------------------
# crypto engine
#----------------------

cd $LOCALBUILDDIR

if [ -f "$GLOBALDESTDIR/lib/libgcrypt.a" ]; then
	echo -------------------------------------------------
	echo "libgcrypt-1.5.3 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile libgcrypt $bits\007"
		if [ -d "libgcrypt-1.5.3" ]; then rm -rf libgcrypt-1.5.3; fi
		wget --tries=20 --retry-connrefused --waitretry=2 ftp://ftp.gnupg.org/gcrypt/libgcrypt/libgcrypt-1.5.3.tar.bz2
		tar xf libgcrypt-1.5.3.tar.bz2
		rm libgcrypt-1.5.3.tar.bz2
		cd libgcrypt-1.5.3
		./configure --build=$targetBuild --host=$targetHost --prefix=$GLOBALDESTDIR --disable-shared --with-gnu-ld
		make -j $cpuCount
		make install
		
		do_checkIfExist libgcrypt-1.5.3 libgcrypt.a
fi

cd $LOCALBUILDDIR

if [ -f "$GLOBALDESTDIR/lib/libgnutls.a" ]; then
	echo -------------------------------------------------
	echo "gnutls-3.2.3 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile gnutls $bits\007"
		if [ -d "gnutls-3.2.3" ]; then rm -rf gnutls-3.2.3; fi
		wget --tries=20 --retry-connrefused --waitretry=2 ftp://ftp.gnutls.org/gcrypt/gnutls/v3.2/gnutls-3.2.3.tar.xz
		tar xf gnutls-3.2.3.tar.xz
		rm gnutls-3.2.3.tar.xz
		cd gnutls-3.2.3
		./configure --build=$targetBuild --host=$targetHost --prefix=$GLOBALDESTDIR --enable-threads=win32 --disable-guile --disable-doc --disable-tests --disable-shared --with-gnu-ld --without-p11-kit
		make -j $cpuCount
		make install
		sed -i 's/-lgnutls *$/-lgnutls -lnettle -lhogweed -liconv -lcrypt32 -lws2_32 -lz -lgmp -lintl/' $GLOBALDESTDIR/lib/pkgconfig/gnutls.pc
		
		if [[ $bits = "32bit" ]]; then
			sed -i 's/-L\/global32\/lib .*/-L\/global32\/lib/' $GLOBALDESTDIR/lib/pkgconfig/gnutls.pc
		else
			sed -i 's/-L\/global64\/lib .*/-L\/global64\/lib/' $GLOBALDESTDIR/lib/pkgconfig/gnutls.pc
		fi
		
		do_checkIfExist gnutls-3.2.3 libgnutls.a
fi

cd $LOCALBUILDDIR

if [ -f "$GLOBALDESTDIR/bin/rtmpdump.exe" ]; then
	echo -------------------------------------------------
	echo "rtmpdump is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile rtmpdump $bits\007"
		if [ -d "rtmpdump" ]; then rm -rf rtmpdump; fi
		git clone git://git.ffmpeg.org/rtmpdump rtmpdump
		cd rtmpdump
		sed -i 's/LIB_GNUTLS=.*/LIB_GNUTLS=-lgnutls -lhogweed -lnettle -lgmp -liconv -ltasn1 $(LIBZ)/' Makefile
		sed -i 's/LIBS_mingw=.*/LIBS_mingw=-lws2_32 -lwinmm -lgdi32 -lcrypt32 -lintl/' Makefile
		make LDFLAGS="$LDFLAGS" prefix=$GLOBALDESTDIR CRYPTO=GNUTLS SHARED= SYS=mingw install LIBS="$LIBS -liconv -lrtmp -lgnutls -lhogweed -lnettle -lgmp -liconv -ltasn1 -lws2_32 -lwinmm -lgdi32 -lcrypt32 -lintl -lz -liconv"
		sed -i 's/Libs:.*/Libs: -L${libdir} -lrtmp -lwinmm -lz -lgmp -lintl/' $GLOBALDESTDIR/lib/pkgconfig/librtmp.pc
		
		do_checkIfExist rtmpdump rtmpdump.exe
fi

cd $LOCALBUILDDIR

if [ -f "$GLOBALDESTDIR/lib/libdca.a" ]; then
	echo -------------------------------------------------
	echo "libdca is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile libdca $bits\007"
		if [ -d "libdca" ]; then rm -rf libdca; fi
		svn co svn://svn.videolan.org/libdca/trunk libdca
		cd libdca
		./bootstrap
		./configure --build=$targetBuild --host=$targetHost --prefix=$GLOBALDESTDIR --disable-shared
		make -j $cpuCount
		make install
		
		do_checkIfExist libdca libdca.a
fi

cd $LOCALBUILDDIR

if [ -f "$GLOBALDESTDIR/lib/libxml2.a" ]; then
	echo -------------------------------------------------
	echo "libxml2-2.9.1 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile libxml2 $bits\007"
		if [ -d "libxml2-2.9.1" ]; then rm -rf libxml2-2.9.1; fi
		wget --tries=20 --retry-connrefused --waitretry=2 -c ftp://xmlsoft.org/libxml2/libxml2-2.9.1.tar.gz
		tar xf libxml2-2.9.1.tar.gz
		rm libxml2-2.9.1.tar.gz
		cd libxml2-2.9.1
		./configure --build=$targetBuild --host=$targetHost --prefix=$GLOBALDESTDIR --disable-shared --enable-static
		make -j $cpuCount
		make install
		cp $GLOBALDESTDIR/lib/xml2.a $GLOBALDESTDIR/lib/libxml2.a
		cp $GLOBALDESTDIR/lib/xml2.la $GLOBALDESTDIR/lib/libxml2.la
		
		do_checkIfExist libxml2-2.9.1 libxml2.a
fi

cd $LOCALBUILDDIR

if [ -f "$GLOBALDESTDIR/lib/libilbc.a" ]; then
	echo -------------------------------------------------
	echo "libilbc is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile libilbc $bits\007"
		if [ -d "libilbc" ]; then rm -rf libilbc; fi
		git clone https://github.com/dekkers/libilbc.git libilbc
		cd libilbc
		if [[ ! -f "configure" ]]; then
			autoreconf -fiv
		fi
		./configure --build=$targetBuild --host=$targetHost --prefix=$GLOBALDESTDIR --disable-shared
		make -j $cpuCount
		make install
		
		do_checkIfExist libilbc libilbc.a
fi
}

if [[ $build32 = "yes" ]]; then
	echo "-------------------------------------------------------------------------------"
	echo
	echo "compile global tools 32 bit"
	echo
	echo "-------------------------------------------------------------------------------"
	source /global32/etc/profile.local
	buildProcess
	echo "-------------------------------------------------------------------------------"
	echo "compile global tools 32 bit done..."
	echo "-------------------------------------------------------------------------------"
	sleep 3
fi

if [[ $build64 = "yes" ]]; then
	echo "-------------------------------------------------------------------------------"
	echo
	echo "compile global tools 64 bit"
	echo
	echo "-------------------------------------------------------------------------------"
	source /global64/etc/profile.local
	buildProcess
	echo "-------------------------------------------------------------------------------"
	echo "compile global tools 64 bit done..."
	echo "-------------------------------------------------------------------------------"
	sleep 3
fi

sleep 3