# set CPU count global. This can be overwrite from the compiler script (media-autobuild_suite.bat)
cpuCount=1
while true; do
  case $1 in
--cpuCount=* ) cpuCount="${1#*=}"; shift ;;
--build32=* ) build32="${1#*=}"; shift ;;
--build64=* ) build64="${1#*=}"; shift ;;
--qt4=* ) qt4="${1#*=}"; shift ;;
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
		if [ -f "$LOCALDESTDIR/bin/$fileName" ]; then
			echo -
			echo -------------------------------------------------
			echo "build $packetName done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build $packetName failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi	
	elif [[ "$fileExtension" = "a" ]]; then
		if [ -f "$LOCALDESTDIR/lib/$fileName" ]; then
			echo -
			echo -------------------------------------------------
			echo "build $packetName done..."
			echo -------------------------------------------------
			echo -
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

if [ -f "$LOCALDESTDIR/lib/libz.a" ]; then
	echo -------------------------------------------------
	echo "zlib-1.2.8 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile zlib $bits\007"
		if [ -d "zlib-1.2.8" ]; then rm -r zlib-1.2.8; fi
		wget -c http://www.zlib.net/zlib-1.2.8.tar.gz
		tar xf zlib-1.2.8.tar.gz
		rm zlib-1.2.8.tar.gz
		cd zlib-1.2.8
		sed 's/-O3/-O3 -mms-bitfields -mthreads/' win32/Makefile.gcc >Makefile.gcc
		make IMPLIB='libz.dll.a' -fMakefile.gcc
		install libz.a $LOCALDESTDIR/lib
		install zlib.h $LOCALDESTDIR/include
		install zconf.h $LOCALDESTDIR/include

		if [ ! -f $LOCALDESTDIR/lib/pkgconfig/zlib.pc ]; then
			echo "prefix=$LOCALDESTDIR" >> $LOCALDESTDIR/lib/pkgconfig/zlib.pc
			echo "exec_prefix=$LOCALDESTDIR" >> $LOCALDESTDIR/lib/pkgconfig/zlib.pc
			echo "libdir=$LOCALDESTDIR/lib" >> $LOCALDESTDIR/lib/pkgconfig/zlib.pc
			echo "sharedlibdir=$LOCALDESTDIR/lib" >> $LOCALDESTDIR/lib/pkgconfig/zlib.pc
			echo "includedir=$LOCALDESTDIR/include" >> $LOCALDESTDIR/lib/pkgconfig/zlib.pc
			echo "" >> $LOCALDESTDIR/lib/pkgconfig/zlib.pc
			echo "Name: zlib" >> $LOCALDESTDIR/lib/pkgconfig/zlib.pc
			echo "Description: zlib compression library" >> $LOCALDESTDIR/lib/pkgconfig/zlib.pc
			echo "Version: 1.2.8" >> $LOCALDESTDIR/lib/pkgconfig/zlib.pc
			echo "" >> $LOCALDESTDIR/lib/pkgconfig/zlib.pc
			echo "Requires:" >> $LOCALDESTDIR/lib/pkgconfig/zlib.pc
			echo "Libs: -L\${libdir} -L\${sharedlibdir} -lz" >> $LOCALDESTDIR/lib/pkgconfig/zlib.pc
			echo "Cflags: -I${includedir}" >> $LOCALDESTDIR/lib/pkgconfig/zlib.pc
		fi

		do_checkIfExist zlib-1.2.8 libz.a
fi	

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/bin/bzip2.exe" ]; then
	echo -------------------------------------------------
	echo "bzip2-1.0.6 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile bzip2 $bits\007"
		if [ -d "bzip2-1.0.6" ]; then rm -r bzip2-1.0.6; fi
		wget -c http://bzip.org/1.0.6/bzip2-1.0.6.tar.gz
		tar xf bzip2-1.0.6.tar.gz
		rm bzip2-1.0.6.tar.gz
		cd bzip2-1.0.6
		make
		cp bzip2.exe $LOCALDESTDIR/bin/
		cp bzip2recover.exe $LOCALDESTDIR/bin/
		cp bzlib.h $LOCALDESTDIR/include/
		cp libbz2.a $LOCALDESTDIR/lib
		
		do_checkIfExist bzip2-1.0.6 bzip2.exe
fi	

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libdl.a" ]; then
	echo -------------------------------------------------
	echo "dlfcn-win32-r19 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile dlfcn-win32 $bits\007"
		if [ -d "dlfcn-win32-r19" ]; then rm -r dlfcn-win32-r19; fi
		wget -c http://dlfcn-win32.googlecode.com/files/dlfcn-win32-r19.tar.bz2
		tar xf dlfcn-win32-r19.tar.bz2
		rm dlfcn-win32-r19.tar.bz2
		cd dlfcn-win32-r19
		./configure --prefix=$LOCALDESTDIR --libdir=$LOCALDESTDIR/lib --incdir=$LOCALDESTDIR/include --disable-shared --enable-static
		make
		make install
		
		do_checkIfExist dlfcn-win32-r19 libdl.a
fi		

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libpthread.a" ]; then
	echo -------------------------------------------------
	echo "pthreads-w32-2-9-1-release is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile pthreads-w32 $bits\007"
		if [ -d "pthreads-w32-2-9-1-release" ]; then rm -r pthreads-w32-2-9-1-release; fi
		wget -c ftp://sourceware.org/pub/pthreads-win32/pthreads-w32-2-9-1-release.tar.gz
		tar xf pthreads-w32-2-9-1-release.tar.gz
		rm pthreads-w32-2-9-1-release.tar.gz
		cd pthreads-w32-2-9-1-release
		make clean GC-static
		cp libpthreadGC2.a $LOCALDESTDIR/lib/libpthread.a || exit 1
		cp pthread.h sched.h semaphore.h $LOCALDESTDIR/include || exit 1
		
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
#		./configure --prefix=/$LOCALDESTDIR
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

if [ -f "$LOCALDESTDIR/bin/pkg-config.exe" ]; then
	echo -------------------------------------------------
	echo "pkg-config-lite-0.28-1 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile pkg-config-lite $bits\007"
		if [ -d "pkg-config-lite-0.28-1" ]; then rm -r pkg-config-lite-0.28-1; fi
		wget -c http://downloads.sourceforge.net/project/pkgconfiglite/0.28-1/pkg-config-lite-0.28-1.tar.gz
		tar xf pkg-config-lite-0.28-1.tar.gz
		rm pkg-config-lite-0.28-1.tar.gz
		cd pkg-config-lite-0.28-1
		./configure --host=$targetHost --prefix=$LOCALDESTDIR --enable-shared=no --with-pc-path="/local32/lib/pkgconfig"
		make -j $cpuCount
		make install

if [ ! -f ${LOCALDESTDIR}/bin/pkg-config.sh ]; then
cat >  ${LOCALDESTDIR}/bin/pkg-config.sh << "EOF"
#!/bin/sh
if pkg-config "$@" > /dev/null 2>&1 ; then
res=true
else
res=false
fi
pkg-config "$@" | tr -d \\r && $res
EOF
fi

	chmod ugo+x ${LOCALDESTDIR}/bin/pkg-config.sh
	echo "PKG_CONFIG=${LOCALDESTDIR}/bin/pkg-config.sh" >> ${LOCALDESTDIR}/etc/profile.local
	echo "export PKG_CONFIG" >> ${LOCALDESTDIR}/etc/profile.local
	source ${LOCALDESTDIR}/etc/profile.local

	do_checkIfExist pkg-config-lite-0.28-1 pkg-config.exe
fi

cd $LOCALBUILDDIR

#if [ -f "libtool-2.4.2/compile.done" ]; then
#	echo -------------------------------------------------
#	echo "libtool-2.4.2 is already compiled"
#	echo -------------------------------------------------
#	else 
#		wget -c ftp://ftp.gnu.org/gnu/libtool/libtool-2.4.2.tar.gz
#		tar xf libtool-2.4.2.tar.gz
#		cd libtool-2.4.2
#		CPPFLAGS=' -DFRIBIDI_ENTRY="" ' ./configure --host=$targetHost --prefix=$LOCALDESTDIR --enable-shared=no
#		make -j $cpuCount
#		make install
#		echo "finish" > compile.done
#		cd $LOCALBUILDDIR
#		rm libtool-2.4.2.tar.gz
#fi

if [ -f "$LOCALDESTDIR/lib/libpng.a" ]; then
	echo -------------------------------------------------
	echo "libpng-1.6.7 is already compiled"
	echo -------------------------------------------------
	else
		echo -ne "\033]0;compile libpng $bits\007"
		if [ -d "libpng-1.6.7" ]; then rm -r libpng-1.6.7; fi
		wget -c "http://downloads.sourceforge.net/project/libpng/libpng16/1.6.7/libpng-1.6.7.tar.gz"
		tar xf libpng-1.6.7.tar.gz
		rm libpng-1.6.7.tar.gz
		cd libpng-1.6.7
		./configure --host=$targetHost --prefix=$LOCALDESTDIR --disable-shared
		make -j $cpuCount
		make install
		
		do_checkIfExist libpng-1.6.7 libpng.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libopenjpeg.a" ]; then
	echo -------------------------------------------------
	echo "openjpeg_v1_4_sources_r697 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile openjpeg $bits\007"
		if [ -d "openjpeg_v1_4_sources_r697" ]; then rm -r openjpeg_v1_4_sources_r697; fi
		wget -c "http://openjpeg.googlecode.com/files/openjpeg_v1_4_sources_r697.tgz"
		tar xf openjpeg_v1_4_sources_r697.tgz
		rm openjpeg_v1_4_sources_r697.tgz
		cd openjpeg_v1_4_sources_r697
		./configure --host=$targetHost --prefix=$LOCALDESTDIR --enable-shared=no
		
		if [[ $bits = "32bit" ]]; then
			sed -i "s/\/usr\/lib/\/local32\/lib/" Makefile
		else
			sed -i "s/\/usr\/lib/\/local64\/lib/" Makefile
		fi
		
		make
		make install
		cp libopenjpeg.pc $PKG_CONFIG_PATH
		
		do_checkIfExist openjpeg_v1_4_sources_r697 libopenjpeg.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libturbojpeg.a" ]; then
	echo -------------------------------------------------
	echo "libjpeg-turbo-1.3.0 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile libjpeg-turbo $bits\007"
		if [ -d "libjpeg-turbo-1.3.0" ]; then rm -r libjpeg-turbo-1.3.0; fi
		wget -c "http://sourceforge.net/projects/libjpeg-turbo/files/1.3.0/libjpeg-turbo-1.3.0.tar.gz/download"
		tar xf libjpeg-turbo-1.3.0.tar.gz
		rm libjpeg-turbo-1.3.0.tar.gz
		cd libjpeg-turbo-1.3.0
		./configure --host=$targetHost --prefix=$LOCALDESTDIR --enable-shared=no
		make -j $cpuCount
		make install
		sed -i 's/typedef int boolean;/\/\/typedef int boolean;/' "$LOCALDESTDIR/include/jmorecfg.h"
		
		do_checkIfExist libjpeg-turbo-1.3.0 libturbojpeg.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libjpeg.a" ]; then
	echo -------------------------------------------------
	echo "jpeg-9 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile jpeg-9 $bits\007"
		if [ -d "jpeg-9" ]; then rm -r jpeg-9; fi
		wget -c http://www.ijg.org/files/jpegsrc.v9.tar.gz
		tar xf jpegsrc.v9.tar.gz
		rm jpegsrc.v9.tar.gz
		cd jpeg-9
		./configure --host=$targetHost --prefix=$LOCALDESTDIR --disable-shared --enable-static
		make -j $cpuCount
		make install
		
		do_checkIfExist jpeg-9 libjpeg.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libjasper.a" ]; then
	echo -------------------------------------------------
	echo "jasper-1.900.1 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile jasper $bits\007"
		if [ -d "jasper-1.900.1" ]; then rm -r jasper-1.900.1; fi
		wget -c http://www.ece.uvic.ca/~frodo/jasper/software/jasper-1.900.1.zip
		unzip jasper-1.900.1.zip
		rm jasper-1.900.1.zip
		cd jasper-1.900.1
		./configure --host=$targetHost --prefix=$LOCALDESTDIR --enable-static=no --disable-libjpeg
		make -j $cpuCount
		make install
		
		do_checkIfExist jasper-1.900.1 libjasper.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libtiff.a" ]; then
	echo -------------------------------------------------
	echo "tiff-4.0.3 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile tiff $bits\007"
		if [ -d "tiff-4.0.3" ]; then rm -r tiff-4.0.3; fi
		wget -c ftp://ftp.remotesensing.org/pub/libtiff/tiff-4.0.3.tar.gz
		tar xf tiff-4.0.3.tar.gz
		rm tiff-4.0.3.tar.gz
		cd tiff-4.0.3
		./configure --host=$targetHost --prefix=$LOCALDESTDIR --disable-shared
		make -j $cpuCount
		make install
		
		do_checkIfExist tiff-4.0.3 libtiff.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/include/d3dx.h" ]; then
	echo -------------------------------------------------
	echo "dx7headers is already compiled"
	echo -------------------------------------------------
	else 
		if [ -d "dx7headers" ]; then rm -r dx7headers; fi
		wget -c "http://www.mplayerhq.hu/MPlayer/contrib/win32/dx7headers.tgz"
		mkdir dx7headers
		cd dx7headers
		/opt/bin/7za x ../dx7headers.tgz
		/opt/bin/7za x dx7headers.tar
		rm dx7headers.tar
		cd $LOCALBUILDDIR
		cp dx7headers/* $LOCALDESTDIR/include
		rm dx7headers.tgz
		
		if [ -f "$LOCALDESTDIR/include/d3dx.h" ]; then
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

if [ -f "$LOCALDESTDIR/lib/libiconv.a" ]; then
	echo -------------------------------------------------
	echo "libiconv-1.14 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile libiconv $bits\007"
		if [ -d "libiconv-1.14" ]; then rm -r libiconv-1.14; fi
		wget -c http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.14.tar.gz
		tar xf libiconv-1.14.tar.gz
		rm libiconv-1.14.tar.gz
		cd libiconv-1.14
		./configure --prefix=$LOCALDESTDIR --enable-shared=no --enable-static=yes LDFLAGS="-L$LOCALDESTDIR/lib -mthreads -static -static-libgcc -static-libstdc++ -DPTW32_STATIC_LIB"
		make -j $cpuCount
		make install

		do_checkIfExist libiconv-1.14 libiconv.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libasprintf.a" ]; then
    echo -------------------------------------------------
    echo "gettext-0.18.3.1-runtime is already compiled"
    echo -------------------------------------------------
    else 
		echo -ne "\033]0;compile gettext-runtime $bits\007"
		if [ -d "gettext-0.18.3.1-runtime" ]; then rm -r gettext-0.18.3.1-runtime; fi
		wget -c http://ftp.gnu.org/pub/gnu/gettext/gettext-0.18.3.1.tar.gz
		tar xzf gettext-0.18.3.1.tar.gz
		mv gettext-0.18.3.1 gettext-0.18.3.1-runtime
		cd gettext-0.18.3.1-runtime
		cat gettext-tools/woe32dll/gettextlib-exports.c | grep -v rpl_opt > gettext-tools/woe32dll/gettextlib-exports.c.new
		mv gettext-tools/woe32dll/gettextlib-exports.c.new gettext-tools/woe32dll/gettextlib-exports.c
		CFLAGS="$CFLAGS -O2" ./configure --host=$targetHost --prefix=$LOCALDESTDIR --enable-threads=win32 --enable-relocatable LDFLAGS="$LDFLAGS -static -static-libgcc -DPTW32_STATIC_LIB" 
		cd gettext-runtime
		make -j $cpuCount
		make install
		
		do_checkIfExist gettext-0.18.3.1-runtime libasprintf.a
fi
		
cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/bin/msgmerge.exe" ]; then
    echo -------------------------------------------------
    echo "gettext-0.18.3.1-static is already compiled"
    echo -------------------------------------------------
    else 
		echo -ne "\033]0;compile gettext-static $bits\007"
		if [ -d "gettext-0.18.3.1-static" ]; then rm -r gettext-0.18.3.1-static; fi
		tar xzf gettext-0.18.3.1.tar.gz
		rm gettext-0.18.3.1.tar.gz
		mv gettext-0.18.3.1 gettext-0.18.3.1-static
		cd gettext-0.18.3.1-static
		CFLAGS="$CFLAGS -O2" ./configure --host=$targetHost --prefix=$LOCALDESTDIR --enable-threads=win32 --enable-relocatable --disable-shared LDFLAGS="$LDFLAGS -static -static-libgcc -static-libstdc++ -DPTW32_STATIC_LIB" 
		make -j $cpuCount
		install gettext-tools/src/*.exe $LOCALDESTDIR/bin
		install gettext-tools/misc/autopoint $LOCALDESTDIR/bin
		
		do_checkIfExist gettext-0.18.3.1-static msgmerge.exe
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/bin/iconv.exe" ]; then
    echo -------------------------------------------------
    echo "libiconv-1.14 is already compiled"
    echo -------------------------------------------------
    else 
		echo -ne "\033]0;compile libiconv $bits\007"
		if [ -d "libiconv-1.14" ]; then rm -r libiconv-1.14; fi
		wget -c http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.14.tar.gz
		tar xzf libiconv-1.14.tar.gz
		rm libiconv-1.14.tar.gz
		cd libiconv-1.14
		./configure --host=$targetHost --prefix=$LOCALDESTDIR --enable-shared=no --enable-static=yes LDFLAGS="$LDFLAGS -static -static-libgcc -static-libstdc++ -DPTW32_STATIC_LIB" 
		make clean
		make -j $cpuCount
		make install
		
		do_checkIfExist libiconv-1.14 iconv.exe
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libfreetype.a" ]; then
	echo -------------------------------------------------
	echo "freetype-2.4.10 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile freetype $bits\007"
		if [ -d "freetype-2.4.10" ]; then rm -r freetype-2.4.10; fi
		#wget -c "http://downloads.sourceforge.net/project/freetype/freetype2/2.5.0/freetype-2.5.0.1.tar.gz"
		wget -c http://download.savannah.gnu.org/releases/freetype/freetype-2.4.10.tar.gz
		tar xf freetype-2.4.10.tar.gz
		rm freetype-2.4.10.tar.gz
		cd freetype-2.4.10
		./configure --host=$targetHost --prefix=$LOCALDESTDIR --disable-shared
		make -j $cpuCount
		make install
		
		do_checkIfExist freetype-2.4.10 libfreetype.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libexpat.a" ]; then
	echo -------------------------------------------------
	echo "expat-2.1.0 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile expat $bits\007"
		if [ -d "expat-2.1.0" ]; then rm -r expat-2.1.0; fi
		wget -c http://sourceforge.net/projects/expat/files/expat/2.1.0/expat-2.1.0.tar.gz/download
		tar xf expat-2.1.0.tar.gz
		rm expat-2.1.0.tar.gz
		cd expat-2.1.0
		./configure --host=$targetHost --prefix=$LOCALDESTDIR --enable-shared=no
		make -j $cpuCount
		make install
		
		do_checkIfExist expat-2.1.0 libexpat.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libfontconfig.a" ]; then
	echo -------------------------------------------------
	echo "fontconfig-2.10.2 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile fontconfig $bits\007"
		if [ -d "fontconfig-2.10.2" ]; then rm -r fontconfig-2.10.2; fi
		wget -c http://www.freedesktop.org/software/fontconfig/release/fontconfig-2.10.2.tar.gz
		tar xf fontconfig-2.10.2.tar.gz
		rm fontconfig-2.10.2.tar.gz
		cd fontconfig-2.10.2
		./configure --host=$targetHost --prefix=$LOCALDESTDIR --enable-shared=no
		make -j $cpuCount
		make install
		sed -i 's/-L${libdir} -lfontconfig[^l]*$/-L${libdir} -lfontconfig -lfreetype -lexpat/' "$PKG_CONFIG_PATH/fontconfig.pc"
		
		do_checkIfExist fontconfig-2.10.2 libfontconfig.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libfribidi.a" ]; then
	echo -------------------------------------------------
	echo "fribidi-0.19.4 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile fribidi $bits\007"
		if [ -d "fribidi-0.19.4" ]; then rm -r fribidi-0.19.4; fi
		wget -c http://fribidi.org/download/fribidi-0.19.4.tar.bz2
		tar xf fribidi-0.19.4.tar.bz2
		rm fribidi-0.19.4.tar.bz2
		cd fribidi-0.19.4
		wget --no-check-certificate -c https://raw.github.com/rdp/ffmpeg-windows-build-helpers/master/patches/fribidi.diff
		patch -p0 < fribidi.diff
		./configure --host=$targetHost --prefix=$LOCALDESTDIR --enable-shared=no
		sed -i 's/-export-symbols-regex "^fribidi_.*" $(am__append_1)/-export-symbols-regex "^fribidi_.*" # $(am__append_1)/g' "lib/Makefile"
		make -j $cpuCount
		make install		

if [ ! -f ${LOCALDESTDIR}/bin/fribidi-config ]; then
cat > ${LOCALDESTDIR}/bin/fribidi-config << "EOF"
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

if [ -f "$LOCALDESTDIR/lib/libass.a" ]; then
	echo -------------------------------------------------
	echo "libass-0.10.1 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile libass $bits\007"
		if [ -d "libass-0.10.1" ]; then rm -r libass-0.10.1; fi
		wget -c http://libass.googlecode.com/files/libass-0.10.1.tar.gz
		tar xf libass-0.10.1.tar.gz
		rm libass-0.10.1.tar.gz
		cd libass-0.10.1
		CPPFLAGS=' -DFRIBIDI_ENTRY="" ' ./configure --host=$targetHost --prefix=$LOCALDESTDIR --enable-shared=no
		make -j $cpuCount
		make install
		sed -i 's/-lass -lm/-lass -lfribidi -lm/' "$PKG_CONFIG_PATH/libass.pc"
		
		do_checkIfExist libass-0.10.1 libass.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libSDL.a" ]; then
	echo -------------------------------------------------
	echo "SDL-1.2.15 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile SDL $bits\007"
		if [ -d "SDL-1.2.15" ]; then rm -r SDL-1.2.15; fi
		wget -c http://www.libsdl.org/release/SDL-1.2.15.tar.gz
		tar xf SDL-1.2.15.tar.gz
		rm SDL-1.2.15.tar.gz
		cd SDL-1.2.15
		./configure --host=$targetHost --prefix=$LOCALDESTDIR --enable-shared=no
		make -j $cpuCount
		make install
		
		if [[ $bits = "32bit" ]]; then
			sed -i "s/-mwindows//" "/local32/bin/sdl-config"
			sed -i "s/-mwindows//" "/local32/lib/pkgconfig/sdl.pc"
		else
			sed -i "s/-mwindows//" "/local64/bin/sdl-config"
			sed -i "s/-mwindows//" "/local64/lib/pkgconfig/sdl.pc"
		fi
		
		do_checkIfExist SDL-1.2.15 libSDL.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libSDL_image.a" ]; then
	echo -------------------------------------------------
	echo "SDL_image-1.2.12 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile SDL_imagae $bits\007"
		if [ -d "SDL_image-1.2.12" ]; then rm -r SDL_image-1.2.12; fi
		wget -c http://www.libsdl.org/projects/SDL_image/release/SDL_image-1.2.12.tar.gz
		tar xf SDL_image-1.2.12.tar.gz
		rm SDL_image-1.2.12.tar.gz
		cd SDL_image-1.2.12
		./configure --host=$targetHost --prefix=$LOCALDESTDIR --enable-shared=no
		make -j $cpuCount
		make install
		
		do_checkIfExist SDL_image-1.2.12 libSDL_image.a
fi

#----------------------
# crypto engine
#----------------------

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libgmp.a" ]; then
	echo -------------------------------------------------
	echo "gmp-5.1.3 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile gmp $bits\007"
		if [ -d "gmp-5.1.3" ]; then rm -r gmp-5.1.3; fi
		wget ftp://ftp.gnu.org/gnu/gmp/gmp-5.1.3.tar.bz2
		tar xf gmp-5.1.3.tar.bz2
		rm gmp-5.1.3.tar.bz2
		cd gmp-5.1.3
		./configure --host=$targetHost --prefix=$LOCALDESTDIR --enable-cxx --disable-shared --with-gnu-ld
		make -j $cpuCount
		make install
		
		do_checkIfExist gmp-5.1.3 libgmp.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libnettle.a" ]; then
	echo -------------------------------------------------
	echo "nettle-2.7.1 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile nettle $bits\007"
		if [ -d "nettle-2.7.1" ]; then rm -r nettle-2.7.1; fi
		wget -c http://ftp.gnu.org/gnu/nettle/nettle-2.7.1.tar.gz
		tar xf nettle-2.7.1.tar.gz
		rm nettle-2.7.1.tar.gz
		cd nettle-2.7.1
		./configure --host=$targetHost --prefix=$LOCALDESTDIR --disable-shared
		make -j $cpuCount
		make install
		
		do_checkIfExist nettle-2.7.1 libnettle.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libgpg-error.a" ]; then
	echo -------------------------------------------------
	echo "libgpg-error-1.12 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile libgpg-error $bits\007"
		if [ -d "libgpg-error-1.12" ]; then rm -r libgpg-error-1.12; fi
		wget ftp://ftp.gnupg.org/gcrypt/libgpg-error/libgpg-error-1.12.tar.bz2
		tar xf libgpg-error-1.12.tar.bz2
		rm libgpg-error-1.12.tar.bz2
		cd libgpg-error-1.12
		./configure --host=$targetHost --prefix=$LOCALDESTDIR --disable-shared --with-gnu-ld
		sed -i 's/iconv --silent/iconv -s/g' potomo
		make -j $cpuCount
		make install
		
		do_checkIfExist libgpg-error-1.12 libgpg-error.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libgcrypt.a" ]; then
	echo -------------------------------------------------
	echo "libgcrypt-1.5.3 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile libgcrypt $bits\007"
		if [ -d "libgcrypt-1.5.3" ]; then rm -r libgcrypt-1.5.3; fi
		wget ftp://ftp.gnupg.org/gcrypt/libgcrypt/libgcrypt-1.5.3.tar.bz2
		tar xf libgcrypt-1.5.3.tar.bz2
		rm libgcrypt-1.5.3.tar.bz2
		cd libgcrypt-1.5.3
		./configure --host=$targetHost --prefix=$LOCALDESTDIR --disable-shared --with-gnu-ld
		make -j $cpuCount
		make install
		
		do_checkIfExist libgcrypt-1.5.3 libgcrypt.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libgnutls.a" ]; then
	echo -------------------------------------------------
	echo "gnutls-3.2.3 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile gnutls $bits\007"
		if [ -d "gnutls-3.2.3" ]; then rm -r gnutls-3.2.3; fi
		wget ftp://ftp.gnutls.org/gcrypt/gnutls/v3.2/gnutls-3.2.3.tar.xz
		tar xf gnutls-3.2.3.tar.xz
		rm gnutls-3.2.3.tar.xz
		cd gnutls-3.2.3
		./configure --host=$targetHost --prefix=$LOCALDESTDIR --enable-threads=win32 --disable-guile --disable-doc --disable-tests --disable-shared --with-gnu-ld
		make -j $cpuCount
		make install
		sed -i 's/-lgnutls *$/-lgnutls -lnettle -lhogweed -liconv -lcrypt32 -lws2_32 -lz -lgmp -lintl/' $PKG_CONFIG_PATH/gnutls.pc
		
		if [[ $bits = "32bit" ]]; then
			sed -i 's/-L\/local32\/lib .*/-L\/local32\/lib/' $PKG_CONFIG_PATH/gnutls.pc
		else
			sed -i 's/-L\/local64\/lib .*/-L\/local64\/lib/' $PKG_CONFIG_PATH/gnutls.pc
		fi
		
		do_checkIfExist gnutls-3.2.3 libgnutls.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/bin/rtmpdump.exe" ]; then
	echo -------------------------------------------------
	echo "rtmpdump is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile rtmpdump $bits\007"
		if [ -d "rtmpdump" ]; then rm -r rtmpdump; fi
		git clone git://git.ffmpeg.org/rtmpdump rtmpdump
		cd rtmpdump
		sed -i 's/LIB_GNUTLS=.*/LIB_GNUTLS=-lgnutls -lhogweed -lnettle -lgmp -liconv $(LIBZ)/' Makefile
		sed -i 's/LIBS_mingw=.*/LIBS_mingw=-lws2_32 -lwinmm -lgdi32 -lcrypt32 -lintl/' Makefile
		make LDFLAGS="$LDFLAGS" prefix=$LOCALDESTDIR CRYPTO=GNUTLS SHARED= SYS=mingw install
		sed -i 's/Libs:.*/Libs: -L${libdir} -lrtmp -lwinmm -lz -lgmp -lintl/' $PKG_CONFIG_PATH/librtmp.pc
		
		do_checkIfExist rtmpdump rtmpdump.exe
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/liblzo2.a" ]; then
	echo -------------------------------------------------
	echo "lzo-2.06 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile lzo $bits\007"
		if [ -d "lzo-2.06" ]; then rm -r lzo-2.06; fi
		wget -c http://www.oberhumer.com/opensource/lzo/download/lzo-2.06.tar.gz
		tar xf lzo-2.06.tar.gz
		rm lzo-2.06.tar.gz
		cd lzo-2.06
		./configure --host=$targetHost --prefix=$LOCALDESTDIR --disable-shared
		make -j $cpuCount
		make install
		
		do_checkIfExist lzo-2.06 liblzo2.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libdca.a" ]; then
	echo -------------------------------------------------
	echo "libdca is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile libdca $bits\007"
		if [ -d "libdca" ]; then rm -r libdca; fi
		svn co svn://svn.videolan.org/libdca/trunk libdca
		cd libdca
		./bootstrap
		./configure --host=$targetHost --prefix=$LOCALDESTDIR --disable-shared
		make -j $cpuCount
		make install
		
		do_checkIfExist libdca libdca.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libxml2.a" ]; then
	echo -------------------------------------------------
	echo "libxml2-2.9.1 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile libxml2 $bits\007"
		if [ -d "libxml2-2.9.1" ]; then rm -r libxml2-2.9.1; fi
		wget -c ftp://xmlsoft.org/libxml2/libxml2-2.9.1.tar.gz
		tar xf libxml2-2.9.1.tar.gz
		rm libxml2-2.9.1.tar.gz
		cd libxml2-2.9.1
		./configure --host=$targetHost --prefix=$LOCALDESTDIR --disable-shared --enable-static
		make -j $cpuCount
		make install
		cp $LOCALDESTDIR/lib/xml2.a $LOCALDESTDIR/lib/libxml2.a
		cp $LOCALDESTDIR/lib/xml2.la $LOCALDESTDIR/lib/libxml2.la
		
		do_checkIfExist libxml2-2.9.1 libxml2.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/liblua.a" ]; then
	echo -------------------------------------------------
	echo "lua-5.1.4 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile lua $bits\007"
		if [ -d "lua-5.1.4" ]; then rm -r lua-5.1.4; fi
		wget -c http://www.lua.org/ftp/lua-5.1.4.tar.gz
		tar xf lua-5.1.4.tar.gz
		rm lua-5.1.4.tar.gz
		cd lua-5.1.4
		
		if [[ $bits = "32bit" ]]; then
			sed -i "s/INSTALL_TOP= \/usr\/local/INSTALL_TOP= \/local32/" Makefile
		else
			sed -i "s/INSTALL_TOP= \/usr\/local/INSTALL_TOP= \/local64/" Makefile
		fi
			
		sed -i "s/CC= gcc/local/CC= gcc -static-libgcc/" src/Makefile
		make mingw
		make install
		cp src/lua51.dll $LOCALDESTDIR/bin
		
		do_checkIfExist lua-5.1.4 liblua.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/liborc-0.4.a" ]; then
	echo -------------------------------------------------
	echo "orc-0.4.18 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile orc $bits\007"
		if [ -d "orc-0.4.18" ]; then rm -r orc-0.4.18; fi
		wget -c http://code.entropywave.com/download/orc/orc-0.4.18.tar.gz
		tar xf orc-0.4.18.tar.gz
		rm orc-0.4.18.tar.gz
		cd orc-0.4.18
		./configure --host=$targetHost --prefix=$LOCALDESTDIR --disable-shared
		make -j $cpuCount
		make install
		
		do_checkIfExist orc-0.4.18 liborc-0.4.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libschroedinger-1.0.a" ]; then
	echo -------------------------------------------------
	echo "schroedinger-1.0.11 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile schroedinger $bits\007"
		if [ -d "schroedinger-1.0.11" ]; then rm -r schroedinger-1.0.11; fi
		wget -c http://diracvideo.org/download/schroedinger/schroedinger-1.0.11.tar.gz
		tar xf schroedinger-1.0.11.tar.gz
		rm schroedinger-1.0.11.tar.gz
		cd schroedinger-1.0.11
		./configure --host=$targetHost --prefix=$LOCALDESTDIR --disable-shared
		sed -i 's/testsuite//' Makefile
		make -j $cpuCount
		make install
		sed -i 's/-lschroedinger-1.0$/-lschroedinger-1.0 -lorc-0.4/' "$PKG_CONFIG_PATH/schroedinger-1.0.pc"
		
		do_checkIfExist schroedinger-1.0.11 libschroedinger-1.0.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libilbc.a" ]; then
	echo -------------------------------------------------
	echo "libilbc is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile libilbc $bits\007"
		if [ -d "libilbc" ]; then rm -r libilbc; fi
		git clone https://github.com/dekkers/libilbc.git libilbc
		cd libilbc
		if [[ ! -f "configure" ]]; then
			autoreconf -fiv
		fi
		./configure --host=$targetHost --prefix=$LOCALDESTDIR --disable-shared
		make -j $cpuCount
		make install
		
		do_checkIfExist libilbc libilbc.a
fi

cd $LOCALBUILDDIR

if [[ $qt4 = "y" ]]; then
	if [ -f "$LOCALDESTDIR/bin/designer.exe" ]; then
		echo -------------------------------------------------
		echo "qt-4.8.5 is already compiled"
		echo -------------------------------------------------
		else 
			echo -ne "\033]0;compile qt4 $bits\007"
			if [ -d "qt-everywhere-opensource-src-4.8.5" ]; then rm -r qt-everywhere-opensource-src-4.8.5; fi
			wget -c http://download.qt-project.org/official_releases/qt/4.8/4.8.5/qt-everywhere-opensource-src-4.8.5.zip
			unzip -o qt-everywhere-opensource-src-4.8.5.zip
			rm qt-everywhere-opensource-src-4.8.5.zip
			cd qt-everywhere-opensource-src-4.8.5
			
			sed -i 's/QMAKE_LFLAGS		=/QMAKE_LFLAGS		= -static -static-libgcc -static-libstdc++/' "mkspecs/win32-g++/qmake.conf"
			sed -i 's/LFLAGS      = -static-libgcc -s/LFLAGS      = -static -static-libgcc -static-libstdc++ -s/' "qmake/Makefile.win32-g++"
			sed -i 's/!contains(QT_CONFIG, no-jpeg):!contains(QT_CONFIG, jpeg):SUBDIRS += jpeg/!contains(QT_CONFIG, no-libjpeg):!contains(QT_CONFIG, libjpeg):SUBDIRS += jpeg/' "src/plugins/imageformats/imageformats.pro"
			sed -i 's/#if defined(Q_OS_WIN64) && !defined(Q_CC_GNU)/#if defined(Q_OS_WIN64)/' "src/corelib/tools/qsimd.cpp"
			sed -i 's/SUBDIRS += demos/#SUBDIRS += demos/' "projects.pro"
			./configure.exe -prefix $LOCALDESTDIR -platform win32-g++ -static -release -opensource -confirm-license -nomake examples -qt-libjpeg -sse
			mingw32-make -j $cpuCount
			mingw32-make install
			
			cp ./plugins/imageformats/*.a $LOCALDESTDIR/lib
			cp ./plugins/accessible/libqtaccessiblewidgets.a  $LOCALDESTDIR/lib
			sed -i 's/\.\.\\.\.\\lib\\pkgconfig\\//' lib/pkgconfig/*.pc
			sed -i 's/Libs: -L${libdir} -lQtGui/Libs: -L${libdir} -lcomctl32 -lqjpeg -lqtaccessiblewidgets -lQtGui/' "lib/pkgconfig/QtGui.pc"
			cp lib/pkgconfig/*.pc $PKG_CONFIG_PATH
			
			do_checkIfExist qt-everywhere-opensource-src-4.8.5 designer.exe
	fi
fi
}

if [[ $build32 = "yes" ]]; then
	echo "-------------------------------------------------------------------------------"
	echo
	echo "compile global tools 32 bit"
	echo
	echo "-------------------------------------------------------------------------------"
	source /local32/etc/profile.local
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
	source /local64/etc/profile.local
	bits='64bit'
	targetHost='x86_64-pc-mingw32'
	buildProcess
	echo "-------------------------------------------------------------------------------"
	echo "compile global tools 64 bit done..."
	echo "-------------------------------------------------------------------------------"
	sleep 3
fi

sleep 3