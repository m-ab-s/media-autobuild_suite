source /local64/etc/profile.local

# set CPU count global. This can be overwrite from the compiler script (ffmpeg-autobuild.bat)
cpuCount=1
while true; do
  case $1 in
--cpuCount=* ) cpuCount="${1#*=}"; shift ;;
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

cd $LOCALBUILDDIR
if [ -f "zlib-1.2.8/compile.done" ]; then
	echo -------------------------------------------------
	echo "zlib-1.2.8 is already compiled"
	echo -------------------------------------------------
	else 
		wget -c http://www.zlib.net/zlib-1.2.8.tar.gz
		tar xf zlib-1.2.8.tar.gz
		cd zlib-1.2.8
		sed 's/-O3/-O3 -mms-bitfields -mthreads/' win32/Makefile.gcc >Makefile.gcc
		make IMPLIB='libz.dll.a' -fMakefile.gcc
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

if [ -f "libpng-1.6.6/compile.done" ]; then
	echo -------------------------------------------------
	echo "libpng-1.6.6 is already compiled"
	echo -------------------------------------------------
	else 
		wget -c "http://downloads.sourceforge.net/project/libpng/libpng16/1.6.6/libpng-1.6.6.tar.gz"
		tar xf libpng-1.6.6.tar.gz
		cd libpng-1.6.6
		./configure --host=x86_64-pc-mingw32 --prefix=$LOCALDESTDIR --disable-shared
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		cd $LOCALBUILDDIR
		rm libpng-1.6.6.tar.gz
		
		if [ -f "$LOCALDESTDIR/lib/libpng.a" ]; then
			echo -
			echo -------------------------------------------------
			echo "build libpng-1.6.6 done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build libpng-1.6.6 failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
fi

if [ -f "freetype-2.4.10/compile.done" ]; then
	echo -------------------------------------------------
	echo "freetype-2.4.10 is already compiled"
	echo -------------------------------------------------
	else 
		#wget -c "http://downloads.sourceforge.net/project/freetype/freetype2/2.5.0/freetype-2.5.0.1.tar.gz"
		wget -c http://download.savannah.gnu.org/releases/freetype/freetype-2.4.10.tar.gz
		tar xf freetype-2.4.10.tar.gz
		cd freetype-2.4.10
		./configure --host=x86_64-pc-mingw32 --prefix=$LOCALDESTDIR --disable-shared
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		cd $LOCALBUILDDIR
		rm freetype-2.4.10.tar.gz
		
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

if [ -f "libiconv-1.14/compile.done" ]; then
	echo -------------------------------------------------
	echo "libiconv-1.14 is already compiled"
	echo -------------------------------------------------
	else 
		wget -c http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.14.tar.gz
		tar xf libiconv-1.14.tar.gz
		cd libiconv-1.14
		./configure --prefix=$LOCALDESTDIR --enable-shared=no --enable-static=yes
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		cd $LOCALBUILDDIR
		rm libiconv-1.14.tar.gz
		
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

if [ -f "expat-2.1.0/compile.done" ]; then
	echo -------------------------------------------------
	echo "expat-2.1.0 is already compiled"
	echo -------------------------------------------------
	else 
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

if [ -f "fontconfig-2.10.1/compile.done" ]; then
	echo -------------------------------------------------
	echo "fontconfig-2.10.1 is already compiled"
	echo -------------------------------------------------
	else 
		wget -c http://www.freedesktop.org/software/fontconfig/release/fontconfig-2.10.1.tar.gz
		tar xf fontconfig-2.10.1.tar.gz
		cd fontconfig-2.10.1
		./configure --host=x86_64-pc-mingw32 --prefix=$LOCALDESTDIR --enable-shared=no
		make -j $cpuCount
		make install
		sed -i 's/-L${libdir} -lfontconfig[^l]*$/-L${libdir} -lfontconfig -lfreetype -lexpat/' "$PKG_CONFIG_PATH/fontconfig.pc"
		echo "finish" > compile.done
		cd $LOCALBUILDDIR
		rm fontconfig-2.10.1.tar.gz
		
		if [ -f "$LOCALDESTDIR/lib/libfontconfig.a" ]; then
			echo -
			echo -------------------------------------------------
			echo "build fontconfig-2.10.1 done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build fontconfig-2.10.1 failed..."
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

sleep 3