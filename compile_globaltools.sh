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

if [ -f "$GLOBALDESTDIR/lib/libz.a" ]; then
	echo -------------------------------------------------
	echo "zlib-1.2.8 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile zlib $bits\007"
		if [ -d "zlib-1.2.8" ]; then rm -rf zlib-1.2.8; fi
		wget -c http://www.zlib.net/zlib-1.2.8.tar.gz
		tar xf zlib-1.2.8.tar.gz
		rm zlib-1.2.8.tar.gz
		cd zlib-1.2.8
		sed 's/-O3/-O3 -mms-bitfields -mthreads/' win32/Makefile.gcc >Makefile.gcc
		make IMPLIB='libz.dll.a' -fMakefile.gcc
		install libz.a $GLOBALDESTDIR/lib
		install zlib.h $GLOBALDESTDIR/include
		install zconf.h $GLOBALDESTDIR/include

		if [ ! -f $GLOBALDESTDIR/lib/pkgconfig/zlib.pc ]; then
			echo "prefix=$GLOBALDESTDIR" >> $GLOBALDESTDIR/lib/pkgconfig/zlib.pc
			echo "exec_prefix=$GLOBALDESTDIR" >> $GLOBALDESTDIR/lib/pkgconfig/zlib.pc
			echo "libdir=$GLOBALDESTDIR/lib" >> $GLOBALDESTDIR/lib/pkgconfig/zlib.pc
			echo "sharedlibdir=$GLOBALDESTDIR/lib" >> $GLOBALDESTDIR/lib/pkgconfig/zlib.pc
			echo "includedir=$GLOBALDESTDIR/include" >> $GLOBALDESTDIR/lib/pkgconfig/zlib.pc
			echo "" >> $GLOBALDESTDIR/lib/pkgconfig/zlib.pc
			echo "Name: zlib" >> $GLOBALDESTDIR/lib/pkgconfig/zlib.pc
			echo "Description: zlib compression library" >> $GLOBALDESTDIR/lib/pkgconfig/zlib.pc
			echo "Version: 1.2.8" >> $GLOBALDESTDIR/lib/pkgconfig/zlib.pc
			echo "" >> $GLOBALDESTDIR/lib/pkgconfig/zlib.pc
			echo "Requires:" >> $GLOBALDESTDIR/lib/pkgconfig/zlib.pc
			echo "Libs: -L\${libdir} -L\${sharedlibdir} -lz" >> $GLOBALDESTDIR/lib/pkgconfig/zlib.pc
			echo "Cflags: -I${includedir}" >> $GLOBALDESTDIR/lib/pkgconfig/zlib.pc
		fi

		do_checkIfExist zlib-1.2.8 libz.a
fi	

cd $LOCALBUILDDIR

if [ -f "$GLOBALDESTDIR/bin/bzip2.exe" ]; then
	echo -------------------------------------------------
	echo "bzip2-1.0.6 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile bzip2 $bits\007"
		if [ -d "bzip2-1.0.6" ]; then rm -rf bzip2-1.0.6; fi
		wget -c http://bzip.org/1.0.6/bzip2-1.0.6.tar.gz
		tar xf bzip2-1.0.6.tar.gz
		rm bzip2-1.0.6.tar.gz
		cd bzip2-1.0.6
		make
		cp bzip2.exe $GLOBALDESTDIR/bin/
		cp bzip2recover.exe $GLOBALDESTDIR/bin/
		cp bzlib.h $GLOBALDESTDIR/include/
		cp libbz2.a $GLOBALDESTDIR/lib
		
		do_checkIfExist bzip2-1.0.6 bzip2.exe
fi	

cd $LOCALBUILDDIR

if [ -f "$GLOBALDESTDIR/lib/libdl.a" ]; then
	echo -------------------------------------------------
	echo "dlfcn-win32-r19 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile dlfcn-win32 $bits\007"
		if [ -d "dlfcn-win32-r19" ]; then rm -rf dlfcn-win32-r19; fi
		wget -c http://dlfcn-win32.googlecode.com/files/dlfcn-win32-r19.tar.bz2
		tar xf dlfcn-win32-r19.tar.bz2
		rm dlfcn-win32-r19.tar.bz2
		cd dlfcn-win32-r19
		./configure --prefix=$GLOBALDESTDIR --libdir=$GLOBALDESTDIR/lib --incdir=$GLOBALDESTDIR/include --disable-shared --enable-static
		make
		make install
		
		do_checkIfExist dlfcn-win32-r19 libdl.a
fi		

cd $LOCALBUILDDIR

if [ -f "$GLOBALDESTDIR/lib/libpthread.a" ]; then
	echo -------------------------------------------------
	echo "pthreads-w32-2-9-1-release is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile pthreads-w32 $bits\007"
		if [ -d "pthreads-w32-2-9-1-release" ]; then rm -rf pthreads-w32-2-9-1-release; fi
		wget -c ftp://sourceware.org/pub/pthreads-win32/pthreads-w32-2-9-1-release.tar.gz
		tar xf pthreads-w32-2-9-1-release.tar.gz
		rm pthreads-w32-2-9-1-release.tar.gz
		cd pthreads-w32-2-9-1-release
		make clean GC-static
		cp libpthreadGC2.a $GLOBALDESTDIR/lib/libpthreadGC2.a || exit 1
		cp libpthreadGC2.a $GLOBALDESTDIR/lib/libpthread.a || exit 1
		cp pthread.h sched.h semaphore.h $GLOBALDESTDIR/include || exit 1
		
		do_checkIfExist pthreads-w32-2-9-1-release libpthread.a
fi

cd $LOCALBUILDDIR

#maybe we don't need this...
#if [ -f "nasm-2.10.09/compile.done" ]; then
#	echo -------------------------------------------------
#	echo "nasm-2.10.09 is already compiled"
#	echo -------------------------------------------------
#	else 
#		wget -c http://www.nasm.us/pub/nasm/releasebuilds/2.10.09/nasm-2.10.09.tar.gz
#		tar xf nasm-2.10.09.tar.gz
#		cd nasm-2.10.09
#		./configure --prefix=/$GLOBALDESTDIR
#		if [[ $bits = "64bit" ]]; then
#			sed -i 's/ -mthreads//g' Makefile
#			sed -i 's/ -mthreads//g' rdoff/Makefile
#		fi
#		make -j $cpuCount
#		make install
#		echo "finish" > compile.done
#		cd $LOCALBUILDDIR
#		rm nasm-2.10.09.tar.gz
#fi	

if [ -f "$GLOBALDESTDIR/bin/pkg-config.exe" ]; then
	echo -------------------------------------------------
	echo "pkg-config-lite-0.28-1 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile pkg-config-lite $bits\007"
		if [ -d "pkg-config-lite-0.28-1" ]; then rm -rf pkg-config-lite-0.28-1; fi
		wget -c http://downloads.sourceforge.net/project/pkgconfiglite/0.28-1/pkg-config-lite-0.28-1.tar.gz
		tar xf pkg-config-lite-0.28-1.tar.gz
		rm pkg-config-lite-0.28-1.tar.gz
		cd pkg-config-lite-0.28-1
		./configure --host=$targetHost --prefix=$GLOBALDESTDIR --enable-shared=no --with-pc-path="/global32/lib/pkgconfig"
		make -j $cpuCount
		make install

if [ ! -f ${GLOBALDESTDIR}/bin/pkg-config.sh ]; then
cat >  ${GLOBALDESTDIR}/bin/pkg-config.sh << "EOF"
#!/bin/sh
if pkg-config "$@" > /dev/null 2>&1 ; then
res=true
else
res=false
fi
pkg-config "$@" | tr -d \\r && $res
EOF
fi

	chmod ugo+x ${GLOBALDESTDIR}/bin/pkg-config.sh
	echo "PKG_CONFIG=${GLOBALDESTDIR}/bin/pkg-config.sh" >> ${GLOBALDESTDIR}/etc/profile.local
	echo "export PKG_CONFIG" >> ${GLOBALDESTDIR}/etc/profile.local
	source ${GLOBALDESTDIR}/etc/profile.local

	do_checkIfExist pkg-config-lite-0.28-1 pkg-config.exe
fi

cd $LOCALBUILDDIR

if [ -f "$GLOBALDESTDIR/lib/libpng.a" ]; then
	echo -------------------------------------------------
	echo "libpng is already compiled"
	echo -------------------------------------------------
	else
		echo -ne "\033]0;compile libpng $bits\007"
		if [ -d libpng ]; then rm -rf libpng; fi
		wget -c -O libpng.tar.xz "ftp://ftp.simplesystems.org/pub/libpng/png/src/libpng16/*.tar.xz"
		tar xf libpng.tar.xz
		rm libpng.tar.xz
		mv libpng-* libpng
		cd libpng
		./configure --host=$targetHost --prefix=$GLOBALDESTDIR --disable-shared
		make -j $cpuCount
		make install
		
		do_checkIfExist libpng libpng.a
fi

cd $LOCALBUILDDIR

if [ -f "$GLOBALDESTDIR/lib/libjpeg.a" ]; then
	echo -------------------------------------------------
	echo "jpeg-9 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile jpeg-9 $bits\007"
		if [ -d "jpeg-9" ]; then rm -rf jpeg-9; fi
		wget -c http://www.ijg.org/files/jpegsrc.v9.tar.gz
		tar xf jpegsrc.v9.tar.gz
		rm jpegsrc.v9.tar.gz
		cd jpeg-9
		./configure --host=$targetHost --prefix=$GLOBALDESTDIR --disable-shared --enable-static
		make -j $cpuCount
		make install
		
		do_checkIfExist jpeg-9 libjpeg.a
fi

cd $LOCALBUILDDIR

if [ -f "$GLOBALDESTDIR/lib/libopenjpeg.a" ]; then
	echo -------------------------------------------------
	echo "openjpeg_v1_4_sources_r697 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile openjpeg $bits\007"
		if [ -d "openjpeg_v1_4_sources_r697" ]; then rm -rf openjpeg_v1_4_sources_r697; fi
		wget -c "http://openjpeg.googlecode.com/files/openjpeg_v1_4_sources_r697.tgz"
		tar xf openjpeg_v1_4_sources_r697.tgz
		rm openjpeg_v1_4_sources_r697.tgz
		cd openjpeg_v1_4_sources_r697
		./configure --host=$targetHost --prefix=$GLOBALDESTDIR --enable-shared=no
		
		if [[ $bits = "32bit" ]]; then
			sed -i "s/\/usr\/lib/\/global32\/lib/" Makefile
		else
			sed -i "s/\/usr\/lib/\/global64\/lib/" Makefile
		fi
		
		make
		make install
		cp libopenjpeg.pc $GLOBALDESTDIR/lib/pkgconfig
		
		do_checkIfExist openjpeg_v1_4_sources_r697 libopenjpeg.a
fi

cd $LOCALBUILDDIR

if [ -f "$GLOBALDESTDIR/lib/libturbojpeg.a" ]; then
	echo -------------------------------------------------
	echo "libjpeg-turbo-1.3.0 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile libjpeg-turbo $bits\007"
		if [ -d "libjpeg-turbo-1.3.0" ]; then rm -rf libjpeg-turbo-1.3.0; fi
		wget -c "http://sourceforge.net/projects/libjpeg-turbo/files/1.3.0/libjpeg-turbo-1.3.0.tar.gz/download"
		tar xf libjpeg-turbo-1.3.0.tar.gz
		rm libjpeg-turbo-1.3.0.tar.gz
		cd libjpeg-turbo-1.3.0
		./configure --host=$targetHost --prefix=$GLOBALDESTDIR --enable-shared=no
		make -j $cpuCount
		make install
		#sed -i 's/typedef int boolean;/\/\/typedef int boolean;/' "$GLOBALDESTDIR/include/jmorecfg.h"
		
		do_checkIfExist libjpeg-turbo-1.3.0 libturbojpeg.a
fi

cd $LOCALBUILDDIR

if [ -f "$GLOBALDESTDIR/lib/libjasper.a" ]; then
	echo -------------------------------------------------
	echo "jasper-1.900.1 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile jasper $bits\007"
		if [ -d "jasper-1.900.1" ]; then rm -rf jasper-1.900.1; fi
		wget -c http://www.ece.uvic.ca/~frodo/jasper/software/jasper-1.900.1.zip
		unzip jasper-1.900.1.zip
		rm jasper-1.900.1.zip
		cd jasper-1.900.1
		./configure --host=$targetHost --prefix=$GLOBALDESTDIR --enable-static=no
		make -j $cpuCount
		make install
		
		do_checkIfExist jasper-1.900.1 libjasper.a
fi

cd $LOCALBUILDDIR

if [ -f "$GLOBALDESTDIR/lib/libtiff.a" ]; then
	echo -------------------------------------------------
	echo "tiff-4.0.3 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile tiff $bits\007"
		if [ -d "tiff-4.0.3" ]; then rm -rf tiff-4.0.3; fi
		wget -c ftp://ftp.remotesensing.org/pub/libtiff/tiff-4.0.3.tar.gz
		tar xf tiff-4.0.3.tar.gz
		rm tiff-4.0.3.tar.gz
		cd tiff-4.0.3
		./configure --host=$targetHost --prefix=$GLOBALDESTDIR --disable-shared
		make -j $cpuCount
		make install
		
		do_checkIfExist tiff-4.0.3 libtiff.a
fi

cd $LOCALBUILDDIR

if [ -f "$GLOBALDESTDIR/include/d3dx.h" ]; then
	echo -------------------------------------------------
	echo "dx7headers is already compiled"
	echo -------------------------------------------------
	else 
		if [ -d "dx7headers" ]; then rm -rf dx7headers; fi
		wget -c "http://www.mplayerhq.hu/MPlayer/contrib/win32/dx7headers.tgz"
		mkdir dx7headers
		cd dx7headers
		/opt/bin/7za x ../dx7headers.tgz
		/opt/bin/7za x dx7headers.tar
		rm dx7headers.tar
		cd $LOCALBUILDDIR
		cp dx7headers/* $GLOBALDESTDIR/include
		rm dx7headers.tgz
		
		if [ -f "$GLOBALDESTDIR/include/d3dx.h" ]; then
			if [[ $deleteSource = "y" ]]; then
				rm -rf dx7headers
			fi 
			echo -
			echo -------------------------------------------------
			echo "build dx7headers done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build dx7headers failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
fi

cd $LOCALBUILDDIR

if [ -f "$GLOBALDESTDIR/lib/libiconv.a" ]; then
	echo -------------------------------------------------
	echo "libiconv-1.14 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile libiconv $bits\007"
		if [ -d "libiconv-1.14" ]; then rm -rf libiconv-1.14; fi
		wget -c http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.14.tar.gz
		tar xf libiconv-1.14.tar.gz
		rm libiconv-1.14.tar.gz
		cd libiconv-1.14
		./configure --prefix=$GLOBALDESTDIR --enable-shared=no --enable-static=yes LDFLAGS="-L$GLOBALDESTDIR/lib -mthreads -static -static-libgcc -static-libstdc++ -DPTW32_STATIC_LIB"
		make -j $cpuCount
		make install

		do_checkIfExist libiconv-1.14 libiconv.a
fi

cd $LOCALBUILDDIR

if [ -f "$GLOBALDESTDIR/lib/libasprintf.a" ]; then
    echo -------------------------------------------------
    echo "gettext-0.18.3.1-runtime is already compiled"
    echo -------------------------------------------------
    else 
		echo -ne "\033]0;compile gettext-runtime $bits\007"
		if [ -d "gettext-0.18.3.1-runtime" ]; then rm -rf gettext-0.18.3.1-runtime; fi
		wget -c http://ftp.gnu.org/pub/gnu/gettext/gettext-0.18.3.1.tar.gz
		tar xzf gettext-0.18.3.1.tar.gz
		mv gettext-0.18.3.1 gettext-0.18.3.1-runtime
		cd gettext-0.18.3.1-runtime
		cat gettext-tools/woe32dll/gettextlib-exports.c | grep -v rpl_opt > gettext-tools/woe32dll/gettextlib-exports.c.new
		mv gettext-tools/woe32dll/gettextlib-exports.c.new gettext-tools/woe32dll/gettextlib-exports.c
		CFLAGS="$CFLAGS -O2" ./configure --host=$targetHost --prefix=$GLOBALDESTDIR --enable-threads=win32 --enable-relocatable LDFLAGS="$LDFLAGS -static -static-libgcc -DPTW32_STATIC_LIB" 
		cd gettext-runtime
		make -j $cpuCount
		make install
		
		do_checkIfExist gettext-0.18.3.1-runtime libasprintf.a
fi
		
cd $LOCALBUILDDIR

if [ -f "$GLOBALDESTDIR/bin/msgmerge.exe" ]; then
    echo -------------------------------------------------
    echo "gettext-0.18.3.1-static is already compiled"
    echo -------------------------------------------------
    else 
		echo -ne "\033]0;compile gettext-static $bits\007"
		if [ -d "gettext-0.18.3.1-static" ]; then rm -rf gettext-0.18.3.1-static; fi
		tar xzf gettext-0.18.3.1.tar.gz
		rm gettext-0.18.3.1.tar.gz
		mv gettext-0.18.3.1 gettext-0.18.3.1-static
		cd gettext-0.18.3.1-static
		CFLAGS="$CFLAGS -O2" ./configure --host=$targetHost --prefix=$GLOBALDESTDIR --enable-threads=win32 --enable-relocatable --disable-shared LDFLAGS="$LDFLAGS -static -static-libgcc -static-libstdc++ -DPTW32_STATIC_LIB" 
		make -j $cpuCount
		install gettext-tools/src/*.exe $GLOBALDESTDIR/bin
		install gettext-tools/misc/autopoint $GLOBALDESTDIR/bin
		
		do_checkIfExist gettext-0.18.3.1-static msgmerge.exe
fi

cd $LOCALBUILDDIR

if [ -f "$GLOBALDESTDIR/bin/iconv.exe" ]; then
    echo -------------------------------------------------
    echo "libiconv-1.14 is already compiled"
    echo -------------------------------------------------
    else 
		echo -ne "\033]0;compile libiconv $bits\007"
		if [ -d "libiconv-1.14" ]; then rm -rf libiconv-1.14; fi
		wget -c http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.14.tar.gz
		tar xzf libiconv-1.14.tar.gz
		rm libiconv-1.14.tar.gz
		cd libiconv-1.14
		./configure --host=$targetHost --prefix=$GLOBALDESTDIR --enable-shared=no --enable-static=yes LDFLAGS="$LDFLAGS -static -static-libgcc -static-libstdc++ -DPTW32_STATIC_LIB" 
		make clean
		make -j $cpuCount
		make install
		
		do_checkIfExist libiconv-1.14 iconv.exe
fi

cd $LOCALBUILDDIR

if [ -f "$GLOBALDESTDIR/lib/libfreetype.a" ]; then
	echo -------------------------------------------------
	echo "freetype-2.4.10 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile freetype $bits\007"
		if [ -d "freetype-2.4.10" ]; then rm -rf freetype-2.4.10; fi
		#wget -c "http://downloads.sourceforge.net/project/freetype/freetype2/2.5.0/freetype-2.5.0.1.tar.gz"
		wget -c http://download.savannah.gnu.org/releases/freetype/freetype-2.4.10.tar.gz
		tar xf freetype-2.4.10.tar.gz
		rm freetype-2.4.10.tar.gz
		cd freetype-2.4.10
		./configure --host=$targetHost --prefix=$GLOBALDESTDIR --disable-shared
		make -j $cpuCount
		make install
		
		do_checkIfExist freetype-2.4.10 libfreetype.a
fi

cd $LOCALBUILDDIR

if [ -f "$GLOBALDESTDIR/lib/libexpat.a" ]; then
	echo -------------------------------------------------
	echo "expat-2.1.0 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile expat $bits\007"
		if [ -d "expat-2.1.0" ]; then rm -rf expat-2.1.0; fi
		wget -c http://sourceforge.net/projects/expat/files/expat/2.1.0/expat-2.1.0.tar.gz/download
		tar xf expat-2.1.0.tar.gz
		rm expat-2.1.0.tar.gz
		cd expat-2.1.0
		./configure --host=$targetHost --prefix=$GLOBALDESTDIR --enable-shared=no
		make -j $cpuCount
		make install
		
		do_checkIfExist expat-2.1.0 libexpat.a
fi

cd $LOCALBUILDDIR

if [ -f "$GLOBALDESTDIR/lib/libfontconfig.a" ]; then
	echo -------------------------------------------------
	echo "fontconfig-2.10.2 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile fontconfig $bits\007"
		if [ -d "fontconfig-2.10.2" ]; then rm -rf fontconfig-2.10.2; fi
		wget -c http://www.freedesktop.org/software/fontconfig/release/fontconfig-2.10.2.tar.gz
		tar xf fontconfig-2.10.2.tar.gz
		rm fontconfig-2.10.2.tar.gz
		cd fontconfig-2.10.2
		./configure --host=$targetHost --prefix=$GLOBALDESTDIR --enable-shared=no
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
		wget -c http://fribidi.org/download/fribidi-0.19.4.tar.bz2
		tar xf fribidi-0.19.4.tar.bz2
		rm fribidi-0.19.4.tar.bz2
		cd fribidi-0.19.4
		wget --no-check-certificate -c https://raw.github.com/jb-alvarado/media-autobuild_suite/master/patches/fribidi.diff
		patch -p0 < fribidi.diff
		./configure --host=$targetHost --prefix=$GLOBALDESTDIR --enable-shared=no
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
		wget -c http://www.libsdl.org/release/SDL-1.2.15.tar.gz
		tar xf SDL-1.2.15.tar.gz
		rm SDL-1.2.15.tar.gz
		cd SDL-1.2.15
		./configure --host=$targetHost --prefix=$GLOBALDESTDIR --enable-shared=no
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
		wget -c http://www.libsdl.org/projects/SDL_image/release/SDL_image-1.2.12.tar.gz
		tar xf SDL_image-1.2.12.tar.gz
		rm SDL_image-1.2.12.tar.gz
		cd SDL_image-1.2.12
		./configure --host=$targetHost --prefix=$GLOBALDESTDIR --enable-shared=no
		make -j $cpuCount
		make install
		
		do_checkIfExist SDL_image-1.2.12 libSDL_image.a
fi

#----------------------
# crypto engine
#----------------------

cd $LOCALBUILDDIR

if [ -f "$GLOBALDESTDIR/lib/libgmp.a" ]; then
	echo -------------------------------------------------
	echo "gmp-5.1.3 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile gmp $bits\007"
		if [ -d "gmp-5.1.3" ]; then rm -rf gmp-5.1.3; fi
		wget ftp://ftp.gnu.org/gnu/gmp/gmp-5.1.3.tar.bz2
		tar xf gmp-5.1.3.tar.bz2
		rm gmp-5.1.3.tar.bz2
		cd gmp-5.1.3
		./configure --host=$targetHost --prefix=$GLOBALDESTDIR --enable-cxx --disable-shared --with-gnu-ld
		make -j $cpuCount
		make install
		
		do_checkIfExist gmp-5.1.3 libgmp.a
fi

cd $LOCALBUILDDIR

if [ -f "$GLOBALDESTDIR/lib/libnettle.a" ]; then
	echo -------------------------------------------------
	echo "nettle-2.7.1 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile nettle $bits\007"
		if [ -d "nettle-2.7.1" ]; then rm -rf nettle-2.7.1; fi
		wget -c http://ftp.gnu.org/gnu/nettle/nettle-2.7.1.tar.gz
		tar xf nettle-2.7.1.tar.gz
		rm nettle-2.7.1.tar.gz
		cd nettle-2.7.1
		./configure --host=$targetHost --prefix=$GLOBALDESTDIR --disable-shared
		make -j $cpuCount
		make install
		
		do_checkIfExist nettle-2.7.1 libnettle.a
fi

cd $LOCALBUILDDIR

if [ -f "$GLOBALDESTDIR/lib/libgpg-error.a" ]; then
	echo -------------------------------------------------
	echo "libgpg-error-1.12 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile libgpg-error $bits\007"
		if [ -d "libgpg-error-1.12" ]; then rm -rf libgpg-error-1.12; fi
		wget ftp://ftp.gnupg.org/gcrypt/libgpg-error/libgpg-error-1.12.tar.bz2
		tar xf libgpg-error-1.12.tar.bz2
		rm libgpg-error-1.12.tar.bz2
		cd libgpg-error-1.12
		./configure --host=$targetHost --prefix=$GLOBALDESTDIR --disable-shared --with-gnu-ld
		sed -i 's/iconv --silent/iconv -s/g' potomo
		make -j $cpuCount
		make install
		
		do_checkIfExist libgpg-error-1.12 libgpg-error.a
fi

cd $LOCALBUILDDIR

if [ -f "$GLOBALDESTDIR/lib/libgcrypt.a" ]; then
	echo -------------------------------------------------
	echo "libgcrypt-1.5.3 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile libgcrypt $bits\007"
		if [ -d "libgcrypt-1.5.3" ]; then rm -rf libgcrypt-1.5.3; fi
		wget ftp://ftp.gnupg.org/gcrypt/libgcrypt/libgcrypt-1.5.3.tar.bz2
		tar xf libgcrypt-1.5.3.tar.bz2
		rm libgcrypt-1.5.3.tar.bz2
		cd libgcrypt-1.5.3
		./configure --host=$targetHost --prefix=$GLOBALDESTDIR --disable-shared --with-gnu-ld
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
		wget ftp://ftp.gnutls.org/gcrypt/gnutls/v3.2/gnutls-3.2.3.tar.xz
		tar xf gnutls-3.2.3.tar.xz
		rm gnutls-3.2.3.tar.xz
		cd gnutls-3.2.3
		./configure --host=$targetHost --prefix=$GLOBALDESTDIR --enable-threads=win32 --disable-guile --disable-doc --disable-tests --disable-shared --with-gnu-ld
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
		sed -i 's/LIB_GNUTLS=.*/LIB_GNUTLS=-lgnutls -lhogweed -lnettle -lgmp -liconv $(LIBZ)/' Makefile
		sed -i 's/LIBS_mingw=.*/LIBS_mingw=-lws2_32 -lwinmm -lgdi32 -lcrypt32 -lintl/' Makefile
		make LDFLAGS="$LDFLAGS" prefix=$GLOBALDESTDIR CRYPTO=GNUTLS SHARED= SYS=mingw install
		sed -i 's/Libs:.*/Libs: -L${libdir} -lrtmp -lwinmm -lz -lgmp -lintl/' $GLOBALDESTDIR/lib/pkgconfig/librtmp.pc
		
		do_checkIfExist rtmpdump rtmpdump.exe
fi

cd $LOCALBUILDDIR

if [ -f "$GLOBALDESTDIR/lib/liblzo2.a" ]; then
	echo -------------------------------------------------
	echo "lzo-2.06 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile lzo $bits\007"
		if [ -d "lzo-2.06" ]; then rm -rf lzo-2.06; fi
		wget -c http://www.oberhumer.com/opensource/lzo/download/lzo-2.06.tar.gz
		tar xf lzo-2.06.tar.gz
		rm lzo-2.06.tar.gz
		cd lzo-2.06
		./configure --host=$targetHost --prefix=$GLOBALDESTDIR --disable-shared
		make -j $cpuCount
		make install
		
		do_checkIfExist lzo-2.06 liblzo2.a
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
		./configure --host=$targetHost --prefix=$GLOBALDESTDIR --disable-shared
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
		wget -c ftp://xmlsoft.org/libxml2/libxml2-2.9.1.tar.gz
		tar xf libxml2-2.9.1.tar.gz
		rm libxml2-2.9.1.tar.gz
		cd libxml2-2.9.1
		./configure --host=$targetHost --prefix=$GLOBALDESTDIR --disable-shared --enable-static
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
		./configure --host=$targetHost --prefix=$GLOBALDESTDIR --disable-shared
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
	bits='32bit'
	targetHost='i686-w64-mingw32'
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
	bits='64bit'
	targetHost='x86_64-pc-mingw32'
	buildProcess
	echo "-------------------------------------------------------------------------------"
	echo "compile global tools 64 bit done..."
	echo "-------------------------------------------------------------------------------"
	sleep 3
fi

sleep 3