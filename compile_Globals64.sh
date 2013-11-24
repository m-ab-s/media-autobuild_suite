source /local64/etc/profile.local

# set CPU count global. This can be overwrite from the compiler script (media-autobuild_suite.bat)
cpuCount=1
while true; do
  case $1 in
--cpuCount=* ) cpuCount="${1#*=}"; shift ;;
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

#make mingw libs static
if [ -f "/mingw64/lib/libgfortran.dll.a" ]; then mv /mingw64/lib/libgfortran.dll.a /mingw64/lib/libgfortran.dll.a.old; fi
if [ -f "/mingw64/lib/libgomp.dll.a" ]; then mv /mingw64/lib/libgomp.dll.a /mingw64/lib/libgomp.dll.a.old; fi
if [ -f "/mingw64/lib/libquadmath.dll.a" ]; then mv /mingw64/lib/libquadmath.dll.a /mingw64/lib/libquadmath.dll.a.old; fi
if [ -f "/mingw64/lib/libssp.dll.a" ]; then mv /mingw64/lib/libssp.dll.a /mingw64/lib/libssp.dll.a.old; fi

cd $LOCALBUILDDIR
if [ -f "zlib-1.2.8/compile.done" ]; then
	echo -------------------------------------------------
	echo "zlib-1.2.8 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compiling zlib 64Bit\007"
		wget -c http://www.zlib.net/zlib-1.2.8.tar.gz
		tar xf zlib-1.2.8.tar.gz
		cd zlib-1.2.8
		sed 's/-O3/-O3 -mms-bitfields -mthreads/' win32/Makefile.gcc >Makefile.gcc
		make IMPLIB='libz.dll.a' -fMakefile.gcc
		#install zlib1.dll $LOCALDESTDIR/bin
		install libz.a $LOCALDESTDIR/lib
		install zlib.h $LOCALDESTDIR/include
		install zconf.h $LOCALDESTDIR/include
		echo "finish" > compile.done
		cd $LOCALBUILDDIR
		rm zlib-1.2.8.tar.gz

cat > /local64/lib/pkgconfig/zlib.pc << "EOF"
prefix=/local64
exec_prefix=/local64
libdir=/local64/lib
sharedlibdir=/local64/lib
includedir=/local64/include

Name: zlib
Description: zlib compression library
Version: 1.2.8

Requires:
Libs: -L${libdir} -L${sharedlibdir} -lz
Cflags: -I${includedir}
EOF
	if [ -f "$LOCALDESTDIR/lib/libz.a" ]; then
		echo -
		echo -------------------------------------------------
		echo "build zlib-1.2.8 done..."
		echo -------------------------------------------------
		echo -
		else
			echo -------------------------------------------------
			echo "build zlib-1.2.8 failed..."
			echo "delete the source folder under '$LOCALBUILDDIR' and start again"
			read -p "first close the batch window, then the shell window"
			sleep 15
	fi
fi	
	
if [ -f "bzip2-1.0.6/compile.done" ]; then
	echo -------------------------------------------------
	echo "bzip2-1.0.6 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compiling bzip2 64Bit\007"
		wget -c http://bzip.org/1.0.6/bzip2-1.0.6.tar.gz
		tar xf bzip2-1.0.6.tar.gz
		cd bzip2-1.0.6
		make
		cp bzip2.exe $LOCALDESTDIR/bin/
		cp bzip2recover.exe $LOCALDESTDIR/bin/
		cp bzlib.h $LOCALDESTDIR/include/
		cp libbz2.a $LOCALDESTDIR/lib
		echo "finish" > compile.done
		cd $LOCALBUILDDIR
		rm bzip2-1.0.6.tar.gz
		
		if [ -f "$LOCALDESTDIR/bin/bzip2.exe" ]; then
			echo -
			echo -------------------------------------------------
			echo "build bzip2-1.0.6 done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build bzip2-1.0.6 failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
fi	

if [ -f "dlfcn-win32-r19/compile.done" ]; then
	echo -------------------------------------------------
	echo "dlfcn-win32-r19 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compiling dlfcn-win32 64Bit\007"
		wget -c http://dlfcn-win32.googlecode.com/files/dlfcn-win32-r19.tar.bz2
		tar xf dlfcn-win32-r19.tar.bz2
		cd dlfcn-win32-r19
		./configure --prefix=$LOCALDESTDIR --libdir=$LOCALDESTDIR/lib --incdir=$LOCALDESTDIR/include --disable-shared --enable-static
		make
		make install
		echo "finish" > compile.done
		cd $LOCALBUILDDIR
		rm dlfcn-win32-r19.tar.bz2
		
		if [ -f "$LOCALDESTDIR/lib/libdl.a" ]; then
			echo -
			echo -------------------------------------------------
			echo "build dlfcn-win32-r19 done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build dlfcn-win32-r19 failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
fi		

if [ -f "pthreads-w32-2-9-1-release/compile.done" ]; then
	echo -------------------------------------------------
	echo "pthreads-w32-2-9-1-release is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compiling pthreads-w32 64Bit\007"
		wget -c ftp://sourceware.org/pub/pthreads-win32/pthreads-w32-2-9-1-release.tar.gz
		tar xf pthreads-w32-2-9-1-release.tar.gz
		cd pthreads-w32-2-9-1-release
		make clean GC-static
		cp libpthreadGC2.a $LOCALDESTDIR/lib/libpthread.a || exit 1
		cp pthread.h sched.h semaphore.h $LOCALDESTDIR/include || exit 1
		echo "finish" > compile.done
		cd $LOCALBUILDDIR
		rm pthreads-w32-2-9-1-release.tar.gz
		
		if [ -f "$LOCALDESTDIR/lib/libpthread.a" ]; then
			echo -
			echo -------------------------------------------------
			echo "build pthreads-w32-2-9-1-release done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build pthreads-w32-2-9-1-release failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
fi
	
#maybe we don't need this...
#if [ -f "nasm-2.10.09/compile.done" ]; then
#	echo -------------------------------------------------
#	echo "nasm-2.10.09 is already compiled"
#	echo -------------------------------------------------
#	else 
#		cd $LOCALBUILDDIR
#		wget -c http://www.nasm.us/pub/nasm/releasebuilds/2.10.09/nasm-2.10.09.tar.gz
#		tar xf nasm-2.10.09.tar.gz
#		cd nasm-2.10.09
#		./configure --prefix=/mingw64
#		sed -i 's/ -mthreads//g' Makefile
#		sed -i 's/ -mthreads//g' rdoff/Makefile
#		make -j $cpuCount
#		make install
#		echo "finish" > compile.done
#		cd $LOCALBUILDDIR
#		rm nasm-2.10.09.tar.gz
#fi		

if [ -f "pkg-config-lite-0.28-1/compile.done" ]; then
	echo -------------------------------------------------
	echo "pkg-config-lite-0.28-1 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compiling pkg-config-lite 64Bit\007"
		wget -c http://downloads.sourceforge.net/project/pkgconfiglite/0.28-1/pkg-config-lite-0.28-1.tar.gz
		tar xf pkg-config-lite-0.28-1.tar.gz
		cd pkg-config-lite-0.28-1
		./configure --host=x86_64-pc-mingw32 --prefix=$LOCALDESTDIR --enable-shared=no --with-pc-path="/local64/lib/pkgconfig"
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		cd $LOCALBUILDDIR
		rm pkg-config-lite-0.28-1.tar.gz

cat >  ${LOCALDESTDIR}/bin/pkg-config.sh << "EOF"
#!/bin/sh
if pkg-config "$@" > /dev/null 2>&1 ; then
res=true
else
res=false
fi
pkg-config "$@" | tr -d \\r && $res

EOF

chmod ugo+x ${LOCALDESTDIR}/bin/pkg-config.sh
echo "PKG_CONFIG=${LOCALDESTDIR}/bin/pkg-config.sh" >> ${LOCALDESTDIR}/etc/profile.local
echo "export PKG_CONFIG" >> ${LOCALDESTDIR}/etc/profile.local
source ${LOCALDESTDIR}/etc/profile.local

	if [ -f "$LOCALDESTDIR/bin/pkg-config.exe" ]; then
		echo -
		echo -------------------------------------------------
		echo "build pkg-config-lite-0.28-1 done..."
		echo -------------------------------------------------
		echo -
		else
			echo -------------------------------------------------
			echo "build pkg-config-lite-0.28-1 failed..."
			echo "delete the source folder under '$LOCALBUILDDIR' and start again"
			read -p "first close the batch window, then the shell window"
			sleep 15
	fi
fi	

#if [ -f "libtool-2.4.2/compile.done" ]; then
#	echo -------------------------------------------------
#	echo "libtool-2.4.2 is already compiled"
#	echo -------------------------------------------------
#	else 
#		wget -c ftp://ftp.gnu.org/gnu/libtool/libtool-2.4.2.tar.gz
#		tar xf libtool-2.4.2.tar.gz
#		cd libtool-2.4.2
#		CPPFLAGS=' -DFRIBIDI_ENTRY="" ' ./configure --host=x86_64-pc-mingw32 --prefix=$LOCALDESTDIR --enable-shared=no
#		make -j $cpuCount
#		make install
#		echo "finish" > compile.done
#		cd $LOCALBUILDDIR
#		rm libtool-2.4.2.tar.gz
#		
#		if [ -f "$LOCALDESTDIR/lib/libltdl.a" ]; then
#			echo -
#			echo -------------------------------------------------
#			echo "build libtool-2.4.2 done..."
#			echo -------------------------------------------------
#			echo -
#			else
#				echo -------------------------------------------------
#				echo "build libtool-2.4.2 failed..."
#				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
#				read -p "first close the batch window, then the shell window"
#				sleep 15
#		fi
#fi

if [ -f "libpng-1.6.7/compile.done" ]; then
	echo -------------------------------------------------
	echo "libpng-1.6.7 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compiling libpng 64Bit\007"
		wget -c "http://downloads.sourceforge.net/project/libpng/libpng16/1.6.7/libpng-1.6.7.tar.gz"
		tar xf libpng-1.6.7.tar.gz
		cd libpng-1.6.7
		./configure --host=x86_64-pc-mingw32 --prefix=$LOCALDESTDIR --disable-shared
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		cd $LOCALBUILDDIR
		rm libpng-1.6.7.tar.gz
		
		if [ -f "$LOCALDESTDIR/lib/libpng.a" ]; then
			echo -
			echo -------------------------------------------------
			echo "build libpng-1.6.7 done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build libpng-1.6.7 failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
fi

if [ -f "openjpeg_v1_4_sources_r697/compile.done" ]; then
	echo -------------------------------------------------
	echo "openjpeg_v1_4_sources_r697 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compiling openjpeg 64Bit\007"
		wget -c "http://openjpeg.googlecode.com/files/openjpeg_v1_4_sources_r697.tgz"
		tar xf openjpeg_v1_4_sources_r697.tgz
		cd openjpeg_v1_4_sources_r697
		./configure --host=x86_64-pc-mingw32 --prefix=$LOCALDESTDIR --enable-shared=no
		sed -i "s/\/usr\/lib/\/local64\/lib/" Makefile
		make
		make install
		echo "finish" > compile.done
		cp libopenjpeg.pc $PKG_CONFIG_PATH
		cd $LOCALBUILDDIR
		rm openjpeg_v1_4_sources_r697.tgz
		
		if [ -f "$LOCALDESTDIR/lib/libopenjpeg.a" ]; then
			echo -
			echo -------------------------------------------------
			echo "build openjpeg_v1_4_sources_r697 done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build openjpeg_v1_4_sources_r697 failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
fi

if [ -f "libjpeg-turbo-1.3.0/compile.done" ]; then
	echo -------------------------------------------------
	echo "libjpeg-turbo-1.3.0 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compiling libjpeg-turbo 64Bit\007"
		wget -c "http://sourceforge.net/projects/libjpeg-turbo/files/1.3.0/libjpeg-turbo-1.3.0.tar.gz/download"
		tar xf libjpeg-turbo-1.3.0.tar.gz
		rm libjpeg-turbo-1.3.0.tar.gz
		cd libjpeg-turbo-1.3.0
		./configure --host=x86_64-pc-mingw32 --prefix=$LOCALDESTDIR --enable-shared=no
		make -j $cpuCount
		make install
		sed -i 's/typedef int boolean;/\/\/typedef int boolean;/' "$LOCALDESTDIR/include/jmorecfg.h"
		echo "finish" > compile.done
		
		if [ -f "$LOCALDESTDIR/lib/libturbojpeg.a" ]; then
			echo -
			echo -------------------------------------------------
			echo "build libjpeg-turbo-1.3.0 done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build libjpeg-turbo-1.3.0 failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
fi

cd $LOCALBUILDDIR

if [ -f "jpeg-9/compile.done" ]; then
	echo -------------------------------------------------
	echo "jpeg-9 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compiling jpeg-9 64Bit\007"
		wget -c http://www.ijg.org/files/jpegsrc.v9.tar.gz
		tar xf jpegsrc.v9.tar.gz
		rm jpegsrc.v9.tar.gz
		cd jpeg-9
		./configure --host=x86_64-pc-mingw32 --prefix=$LOCALDESTDIR --disable-shared --enable-static
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		cd $LOCALBUILDDIR
		
		if [ -f "$LOCALDESTDIR/lib/libjpeg.a" ]; then
			echo -
			echo -------------------------------------------------
			echo "build jpeg-9 done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build jpeg-9 failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
fi

if [ -f "jasper-1.900.1/compile.done" ]; then
	echo -------------------------------------------------
	echo "jasper-1.900.1 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compiling jasper 64Bit\007"
		wget -c http://www.ece.uvic.ca/~frodo/jasper/software/jasper-1.900.1.zip
		unzip jasper-1.900.1.zip
		rm jasper-1.900.1.zip
		cd jasper-1.900.1
		./configure --host=x86_64-pc-mingw32 --prefix=$LOCALDESTDIR --enable-static=no
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		cd $LOCALBUILDDIR
		
		if [ -f "$LOCALDESTDIR/lib/libjasper.a" ]; then
			echo -
			echo -------------------------------------------------
			echo "build jasper-1.900.1 done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build jasper-1.900.1 failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
fi

if [ -f "tiff-4.0.3/compile.done" ]; then
	echo -------------------------------------------------
	echo "tiff-4.0.3 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compiling tiff 64Bit\007"
		wget -c ftp://ftp.remotesensing.org/pub/libtiff/tiff-4.0.3.tar.gz
		tar xf tiff-4.0.3.tar.gz
		rm tiff-4.0.3.tar.gz
		cd tiff-4.0.3
		./configure --host=x86_64-pc-mingw32 --prefix=$LOCALDESTDIR --disable-shared
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		cd $LOCALBUILDDIR
		
		if [ -f "$LOCALDESTDIR/lib/libtiff.a" ]; then
			echo -
			echo -------------------------------------------------
			echo "build tiff-4.0.3 done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build tiff-4.0.3 failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
fi

if [ -f "dx7headers/compile.done" ]; then
	echo -------------------------------------------------
	echo "dx7headers is already compiled"
	echo -------------------------------------------------
	else 
		wget -c "http://www.mplayerhq.hu/MPlayer/contrib/win32/dx7headers.tgz"
		mkdir dx7headers
		cd dx7headers
		/opt/bin/7za x ../dx7headers.tgz
		/opt/bin/7za x dx7headers.tar
		rm dx7headers.tar
		cd $LOCALBUILDDIR
		cp dx7headers/* $LOCALDESTDIR/include
		echo "finish" > dx7headers/compile.done
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

if [ -f "libiconv-1.14/compile1.done" ]; then
	echo -------------------------------------------------
	echo "libiconv-1.14 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compiling libiconv 64Bit\007"
		wget -c http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.14.tar.gz
		tar xf libiconv-1.14.tar.gz
		rm libiconv-1.14.tar.gz
		cd libiconv-1.14
		./configure --prefix=$LOCALDESTDIR --enable-shared=no --enable-static=yes LDFLAGS="-L$LOCALDESTDIR/lib -mthreads -static -static-libgcc -static-libstdc++ -DPTW32_STATIC_LIB"
		make -j $cpuCount
		make install
		echo "finish" > compile1.done

		if [ -f "$LOCALDESTDIR/lib/libiconv.a" ]; then
			echo -
			echo -------------------------------------------------
			echo "build libiconv-1.14 done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build libiconv-1.14 failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
fi

cd $LOCALBUILDDIR

if [ -f "gettext-0.18.3.1-runtime/compile.done" ]; then
    echo -------------------------------------------------
    echo "gettext-0.18.3.1-runtime is already compiled"
    echo -------------------------------------------------
    else 
		echo -ne "\033]0;compiling gettext-runtime 64Bit\007"
		wget -c http://ftp.gnu.org/pub/gnu/gettext/gettext-0.18.3.1.tar.gz
		tar xzf gettext-0.18.3.1.tar.gz
		mv gettext-0.18.3.1 gettext-0.18.3.1-runtime
		cd gettext-0.18.3.1-runtime
		cat gettext-tools/woe32dll/gettextlib-exports.c | grep -v rpl_opt > gettext-tools/woe32dll/gettextlib-exports.c.new
		mv gettext-tools/woe32dll/gettextlib-exports.c.new gettext-tools/woe32dll/gettextlib-exports.c
		CFLAGS="-mms-bitfields -mthreads -O2" ./configure --host=x86_64-pc-mingw32 --prefix=$LOCALDESTDIR --enable-threads=win32 --enable-relocatable LDFLAGS="-L$LOCALDESTDIR/lib -static -static-libgcc -DPTW32_STATIC_LIB" 
		cd gettext-runtime
		make -j $cpuCount
		make install
		cd ..
		echo "finish" > compile.done
		
		if [ -f "$LOCALDESTDIR/lib/libasprintf.a" ]; then
			echo -
			echo -------------------------------------------------
			echo "build gettext-0.18.3.1-runtime done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build gettext-0.18.3.1-runtime failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
fi
		
cd $LOCALBUILDDIR

if [ -f "gettext-0.18.3.1-static/compile.done" ]; then
    echo -------------------------------------------------
    echo "gettext-0.18.3.1-static is already compiled"
    echo -------------------------------------------------
    else 
		echo -ne "\033]0;compiling gettext-static 64Bit\007"
		tar xzf gettext-0.18.3.1.tar.gz
		rm gettext-0.18.3.1.tar.gz
		mv gettext-0.18.3.1 gettext-0.18.3.1-static
		cd gettext-0.18.3.1-static
		CFLAGS="-mms-bitfields -mthreads -O2" ./configure --host=x86_64-pc-mingw32 --prefix=$LOCALDESTDIR --enable-threads=win32 --enable-relocatable --disable-shared LDFLAGS="-L$LOCALDESTDIR/lib -static -static-libgcc -static-libstdc++ -DPTW32_STATIC_LIB" 
		make -j $cpuCount
		install gettext-tools/src/*.exe $LOCALDESTDIR/bin
		install gettext-tools/misc/autopoint $LOCALDESTDIR/bin
		echo "finish" > compile.done
		
		if [ -f "$LOCALDESTDIR/bin/msgmerge.exe" ]; then
			echo -
			echo -------------------------------------------------
			echo "build gettext-0.18.3.1-static done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build gettext-0.18.3.1-static failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
fi

cd $LOCALBUILDDIR

if [ -f "libiconv-1.14/compile2.done" ]; then
    echo -------------------------------------------------
    echo "libiconv-1.14 is already compiled"
    echo -------------------------------------------------
    else 
		echo -ne "\033]0;compiling libiconv 64Bit\007"
		wget -c http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.14.tar.gz
		tar xzf libiconv-1.14.tar.gz
		rm libiconv-1.14.tar.gz
		cd libiconv-1.14
		./configure --host=x86_64-pc-mingw32 --prefix=$LOCALDESTDIR --enable-shared=no --enable-static=yes LDFLAGS="-L$LOCALDESTDIR/lib -static -static-libgcc -static-libstdc++ -DPTW32_STATIC_LIB" 
		make clean
		make -j $cpuCount
		make install
		echo "finish" > compile2.done
		
		if [ -f "$LOCALDESTDIR/lib/libiconv.a" ]; then
			echo -
			echo -------------------------------------------------
			echo "build libiconv-1.14 done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build libiconv-1.14 failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
fi

cd $LOCALBUILDDIR

if [ -f "freetype-2.4.10/compile.done" ]; then
	echo -------------------------------------------------
	echo "freetype-2.4.10 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compiling freetype 64Bit\007"
		#wget -c "http://downloads.sourceforge.net/project/freetype/freetype2/2.5.0/freetype-2.5.0.1.tar.gz"
		wget -c http://download.savannah.gnu.org/releases/freetype/freetype-2.4.10.tar.gz
		tar xf freetype-2.4.10.tar.gz
		rm freetype-2.4.10.tar.gz
		cd freetype-2.4.10
		./configure --host=x86_64-pc-mingw32 --prefix=$LOCALDESTDIR --disable-shared
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		
		if [ -f "$LOCALDESTDIR/lib/libfreetype.a" ]; then
			echo -
			echo -------------------------------------------------
			echo "build freetype-2.4.10 done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build freetype-2.4.10 failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
fi

cd $LOCALBUILDDIR

if [ -f "expat-2.1.0/compile.done" ]; then
	echo -------------------------------------------------
	echo "expat-2.1.0 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compiling expat 64Bit\007"
		wget -c http://sourceforge.net/projects/expat/files/expat/2.1.0/expat-2.1.0.tar.gz/download
		tar xf expat-2.1.0.tar.gz
		cd expat-2.1.0
		./configure --host=x86_64-pc-mingw32 --prefix=$LOCALDESTDIR --enable-shared=no
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		cd $LOCALBUILDDIR
		rm expat-2.1.0.tar.gz
		
		if [ -f "$LOCALDESTDIR/lib/libexpat.a" ]; then
			echo -
			echo -------------------------------------------------
			echo "build expat-2.1.0 done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build expat-2.1.0 failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
fi

if [ -f "fontconfig-2.10.2/compile.done" ]; then
	echo -------------------------------------------------
	echo "fontconfig-2.10.2 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compiling fontconfig 64Bit\007"
		wget -c http://www.freedesktop.org/software/fontconfig/release/fontconfig-2.10.2.tar.gz
		tar xf fontconfig-2.10.2.tar.gz
		cd fontconfig-2.10.2
		./configure --host=x86_64-pc-mingw32 --prefix=$LOCALDESTDIR --enable-shared=no
		make -j $cpuCount
		make install
		sed -i 's/-L${libdir} -lfontconfig[^l]*$/-L${libdir} -lfontconfig -lfreetype -lexpat/' "$PKG_CONFIG_PATH/fontconfig.pc"
		echo "finish" > compile.done
		cd $LOCALBUILDDIR
		rm fontconfig-2.10.2.tar.gz
		
		if [ -f "$LOCALDESTDIR/lib/libfontconfig.a" ]; then
			echo -
			echo -------------------------------------------------
			echo "build fontconfig-2.10.2 done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build fontconfig-2.10.2 failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
fi

if [ -f "fribidi-0.19.4/compile.done" ]; then
	echo -------------------------------------------------
	echo "fribidi-0.19.4 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compiling fribidi 64Bit\007"
		wget -c http://fribidi.org/download/fribidi-0.19.4.tar.bz2
		tar xf fribidi-0.19.4.tar.bz2
		cd fribidi-0.19.4
		wget --no-check-certificate -c https://raw.github.com/rdp/ffmpeg-windows-build-helpers/master/patches/fribidi.diff
		patch -p0 < fribidi.diff
		./configure --host=x86_64-pc-mingw32 --prefix=$LOCALDESTDIR --enable-shared=no
		sed -i 's/-export-symbols-regex "^fribidi_.*" $(am__append_1)/-export-symbols-regex "^fribidi_.*" # $(am__append_1)/g' "lib/Makefile"
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		cd $LOCALBUILDDIR
		rm fribidi-0.19.4.tar.bz2

cat > /local64/bin/fribidi-config << "EOF"
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

		if [ -f "$LOCALDESTDIR/lib/libfribidi.a" ]; then
			echo -
			echo -------------------------------------------------
			echo "build fribidi-0.19.4 done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build fribidi-0.19.4 failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
fi

if [ -f "libass-0.10.1/compile.done" ]; then
	echo -------------------------------------------------
	echo "libass-0.10.1 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compiling libass 64Bit\007"
		wget -c http://libass.googlecode.com/files/libass-0.10.1.tar.gz
		tar xf libass-0.10.1.tar.gz
		cd libass-0.10.1
		CPPFLAGS=' -DFRIBIDI_ENTRY="" ' ./configure --host=x86_64-pc-mingw32 --prefix=$LOCALDESTDIR --enable-shared=no
		make -j $cpuCount
		make install
		sed -i 's/-lass -lm/-lass -lfribidi -lm/' "$PKG_CONFIG_PATH/libass.pc"
		echo "finish" > compile.done
		cd $LOCALBUILDDIR
		rm libass-0.10.1.tar.gz
		
		if [ -f "$LOCALDESTDIR/lib/libass.a" ]; then
			echo -
			echo -------------------------------------------------
			echo "build libass-0.10.1 done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build libass-0.10.1 failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
fi

if [ -f "SDL-1.2.15/compile.done" ]; then
	echo -------------------------------------------------
	echo "SDL-1.2.15 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compiling SDL 64Bit\007"
		wget -c http://www.libsdl.org/release/SDL-1.2.15.tar.gz
		tar xf SDL-1.2.15.tar.gz
		cd SDL-1.2.15
		./configure --host=x86_64-pc-mingw32 --prefix=$LOCALDESTDIR --enable-shared=no
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		cd $LOCALBUILDDIR
		rm SDL-1.2.15.tar.gz
		sed -i "s/-mwindows//" "/local64/bin/sdl-config"
		sed -i "s/-mwindows//" "/local64/lib/pkgconfig/sdl.pc"
		
		if [ -f "$LOCALDESTDIR/lib/libSDL.a" ]; then
			echo -
			echo -------------------------------------------------
			echo "build SDL-1.2.15 done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build SDL-1.2.15 failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
fi

if [ -f "SDL_image-1.2.12/compile.done" ]; then
	echo -------------------------------------------------
	echo "SDL_image-1.2.12 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compiling SDL_imagae 32Bit\007"
		wget -c http://www.libsdl.org/projects/SDL_image/release/SDL_image-1.2.12.tar.gz
		tar xf SDL_image-1.2.12.tar.gz
		rm SDL_image-1.2.12.tar.gz
		cd SDL_image-1.2.12
		./configure --host=x86_64-pc-mingw32 --prefix=$LOCALDESTDIR --enable-shared=no
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		
		if [ -f "$LOCALDESTDIR/lib/libSDL_image.a" ]; then
			echo -
			echo -------------------------------------------------
			echo "build SDL_image-1.2.12 done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build SDL_image-1.2.12 failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
fi

#----------------------
# crypto engine
#----------------------

cd $LOCALBUILDDIR

if [ -f "gmp-5.1.3/compile.done" ]; then
	echo -------------------------------------------------
	echo "gmp-5.1.3 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compiling gmp 64Bit\007"
		wget ftp://ftp.gnu.org/gnu/gmp/gmp-5.1.3.tar.bz2
		tar xf gmp-5.1.3.tar.bz2
		rm gmp-5.1.3.tar.bz2
		cd gmp-5.1.3
		./configure --prefix=$LOCALDESTDIR --host=x86_64-pc-mingw32 --build=x86_64-pc-mingw32 --enable-cxx --disable-shared --with-gnu-ld
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		if [ -f "$LOCALDESTDIR/lib/libgmp.a" ]; then
			echo -
			echo -------------------------------------------------
			echo "build gmp-5.1.3 done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build gmp-5.1.3 failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
fi

cd $LOCALBUILDDIR

if [ -f "nettle-2.7.1/compile.done" ]; then
	echo -------------------------------------------------
	echo "nettle-2.7.1 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compiling nettle 64Bit\007"
		wget -c http://www.lysator.liu.se/~nisse/archive/nettle-2.7.1.tar.gz
		tar xf nettle-2.7.1.tar.gz
		rm nettle-2.7.1.tar.gz
		cd nettle-2.7.1
		./configure --prefix=$LOCALDESTDIR --host=x86_64-pc-mingw32 --build=x86_64-pc-mingw32 --disable-shared
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		if [ -f "$LOCALDESTDIR/lib/libnettle.a" ]; then
			echo -
			echo -------------------------------------------------
			echo "build nettle-2.7.1 done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build nettle-2.7.1 failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
fi

cd $LOCALBUILDDIR

if [ -f "libgpg-error-1.12/compile.done" ]; then
	echo -------------------------------------------------
	echo "libgpg-error-1.12 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compiling libgpg-error 64Bit\007"
		wget ftp://ftp.gnupg.org/gcrypt/libgpg-error/libgpg-error-1.12.tar.bz2
		tar xf libgpg-error-1.12.tar.bz2
		rm libgpg-error-1.12.tar.bz2
		cd libgpg-error-1.12
		./configure --prefix=$LOCALDESTDIR --host=x86_64-pc-mingw32 --build=x86_64-pc-mingw32 --disable-shared --with-gnu-ld
		sed -i 's/iconv --silent/iconv -s/g' potomo
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		if [ -f "$LOCALDESTDIR/lib/libgpg-error.a" ]; then
			echo -
			echo -------------------------------------------------
			echo "build libgpg-error-1.12 done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build libgpg-error-1.12 failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
fi

cd $LOCALBUILDDIR

if [ -f "libgcrypt-1.5.3/compile.done" ]; then
	echo -------------------------------------------------
	echo "libgcrypt-1.5.3 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compiling libgcrypt 64Bit\007"
		wget ftp://ftp.gnupg.org/gcrypt/libgcrypt/libgcrypt-1.5.3.tar.bz2
		tar xf libgcrypt-1.5.3.tar.bz2
		rm libgcrypt-1.5.3.tar.bz2
		cd libgcrypt-1.5.3
		./configure --prefix=$LOCALDESTDIR --host=x86_64-pc-mingw32 --build=x86_64-pc-mingw32 --disable-shared --with-gnu-ld
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		if [ -f "$LOCALDESTDIR/lib/libgcrypt.a" ]; then
			echo -
			echo -------------------------------------------------
			echo "build libgcrypt-1.5.3 done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build libgcrypt-1.5.3 failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libgnutls.a" ]; then
	echo -------------------------------------------------
	echo "gnutls-3.2.3 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compiling gnutls 64Bit\007"
		wget ftp://ftp.gnutls.org/gcrypt/gnutls/v3.2/gnutls-3.2.3.tar.xz
		tar xf gnutls-3.2.3.tar.xz
		rm gnutls-3.2.3.tar.xz
		cd gnutls-3.2.3
		./configure --prefix=$LOCALDESTDIR --host=x86_64-pc-mingw32 --build=x86_64-pc-mingw32 --enable-threads=win32 --disable-guile --disable-doc --disable-tests --disable-shared --with-gnu-ld
		make -j $cpuCount
		make install
		sed -i 's/-lgnutls *$/-lgnutls -lnettle -lhogweed -liconv -lcrypt32 -lws2_32 -lz -lgmp -lintl/' $PKG_CONFIG_PATH/gnutls.pc
		sed -i 's/-L\/local64\/lib .*/-L\/local64\/lib/' $PKG_CONFIG_PATH/gnutls.pc
		echo "finish" > compile.done
		if [ -f "$LOCALDESTDIR/lib/libgnutls.a" ]; then
			echo -
			echo -------------------------------------------------
			echo "build gnutls-3.2.3 done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build gnutls-3.2.3 failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
fi

cd $LOCALBUILDDIR

if [ -f "rtmpdump/compile.done" ]; then
	echo -------------------------------------------------
	echo "rtmpdump is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compiling rtmpdump 64Bit\007"
		git clone git://git.ffmpeg.org/rtmpdump rtmpdump
		cd rtmpdump
		sed -i 's/LIB_GNUTLS=.*/LIB_GNUTLS=-lgnutls -lhogweed -lnettle -lgmp -liconv $(LIBZ)/' Makefile
		sed -i 's/LIBS_mingw=.*/LIBS_mingw=-lws2_32 -lwinmm -lgdi32 -lcrypt32 -lintl/' Makefile
		make LDFLAGS="$LDFLAGS" prefix=$LOCALDESTDIR CRYPTO=GNUTLS SHARED= SYS=mingw install
		sed -i 's/Libs:.*/Libs: -L${libdir} -lrtmp -lwinmm -lz -lgmp -lintl/' $PKG_CONFIG_PATH/librtmp.pc
		echo "finish" > compile.done
		if [ -f "$LOCALDESTDIR/lib/librtmp.a" ]; then
			echo -
			echo -------------------------------------------------
			echo "build rtmpdump done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build rtmpdump failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
fi

cd $LOCALBUILDDIR

if [ -f "lzo-2.06/compile.done" ]; then
	echo -------------------------------------------------
	echo "lzo-2.06 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compiling lzo 64Bit\007"
		wget -c http://www.oberhumer.com/opensource/lzo/download/lzo-2.06.tar.gz
		tar xf lzo-2.06.tar.gz
		rm lzo-2.06.tar.gz
		cd lzo-2.06
		./configure --host=x86_64-pc-mingw32 --prefix=$LOCALDESTDIR --disable-shared
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		if [ -f "$LOCALDESTDIR/lib/liblzo2.a" ]; then
			echo -
			echo -------------------------------------------------
			echo "build lzo-2.06 done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build lzo-2.06 failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
fi

cd $LOCALBUILDDIR

if [ -f "libdca/compile.done" ]; then
	echo -------------------------------------------------
	echo "libdca is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compiling libdca 64Bit\007"
		svn co svn://svn.videolan.org/libdca/trunk libdca
		cd libdca
		./bootstrap
		./configure --host=x86_64-pc-mingw32 --prefix=$LOCALDESTDIR --disable-shared
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		if [ -f "$LOCALDESTDIR/lib/libdca.a" ]; then
			echo -
			echo -------------------------------------------------
			echo "build libdca done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build libdca failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
fi

cd $LOCALBUILDDIR

if [ -f "libxml2-2.9.1/compile.done" ]; then
	echo -------------------------------------------------
	echo "libxml2-2.9.1 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compiling libxml2 64Bit\007"
		wget -c ftp://xmlsoft.org/libxml2/libxml2-2.9.1.tar.gz
		tar xf libxml2-2.9.1.tar.gz
		rm libxml2-2.9.1.tar.gz
		cd libxml2-2.9.1
		./configure --host=x86_64-pc-mingw32 --prefix=$LOCALDESTDIR --disable-shared --enable-static
		make -j $cpuCount
		make install
		cp $LOCALDESTDIR/lib/xml2.a $LOCALDESTDIR/lib/libxml2.a
		cp $LOCALDESTDIR/lib/xml2.la $LOCALDESTDIR/lib/libxml2.la
		echo "finish" > compile.done
		if [ -f "$LOCALDESTDIR/lib/libxml2.a" ]; then
			echo -
			echo -------------------------------------------------
			echo "build libxml2-2.9.1 done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build libxml2-2.9.1 failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
fi

cd $LOCALBUILDDIR

if [ -f "lua-5.1.4/compile.done" ]; then
	echo -------------------------------------------------
	echo "lua-5.1.4 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compiling lua 32Bit\007"
		wget -c http://www.lua.org/ftp/lua-5.1.4.tar.gz
		tar xf lua-5.1.4.tar.gz
		rm lua-5.1.4.tar.gz
		cd lua-5.1.4
		sed -i "s/INSTALL_TOP= \/usr\/local/INSTALL_TOP= \/local64/" Makefile
		sed -i "s/CC= gcc/local/CC= gcc -static-libgcc/" src/Makefile
		make mingw
		make install
		cp src/lua51.dll $LOCALDESTDIR/bin
		echo "finish" > compile.done
		if [ -f "$LOCALDESTDIR/lib/liblua.a" ]; then
			echo -
			echo -------------------------------------------------
			echo "build lua-5.1.4 done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build lua-5.1.4 failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
fi

cd $LOCALBUILDDIR

if [[ $qt4 = "y" ]]; then
	if [ -f "$LOCALDESTDIR/bin/designer.exe" ]; then
		echo -------------------------------------------------
		echo "qt-everywhere-opensource-src-4.8.5 is already compiled"
		echo -------------------------------------------------
		else 
			echo -ne "\033]0;compiling qt4 64Bit\007"
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
			if [ -f "$LOCALDESTDIR/bin/designer.exe" ]; then
				echo -
				echo -------------------------------------------------
				echo "build qt-everywhere-opensource-src-4.8.5 done..."
				echo -------------------------------------------------
				echo -
				else
					echo -------------------------------------------------
					echo "build qt-everywhere-opensource-src-4.8.5 failed..."
					echo "delete the source folder under '$LOCALBUILDDIR' and start again"
					read -p "first close the batch window, then the shell window"
					sleep 15
			fi
	fi
fi

sleep 3