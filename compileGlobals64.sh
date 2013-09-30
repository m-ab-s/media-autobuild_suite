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

cd $LOCALBUILDDIR
if [ -f "zlib-1.2.8/compile.done" ]; then
	echo ----------------------------------
	echo "zlib-1.2.8 is already compiled"
	echo ----------------------------------
	else 
		wget -c http://www.zlib.net/zlib-1.2.8.tar.gz
		tar xzf zlib-1.2.8.tar.gz
		cd zlib-1.2.8
		sed 's/-O3/-O3 -mms-bitfields -mthreads/' win32/Makefile.gcc ^>Makefile.gcc
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
fi	
	
if [ -f "bzip2-1.0.6/compile.done" ]; then
	echo ----------------------------------
	echo "bzip2-1.0.6 is already compiled"
	echo ----------------------------------
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
fi	

if [ -f "dlfcn-win32-r19/compile.done" ]; then
	echo ----------------------------------
	echo "dlfcn-win32-r19 is already compiled"
	echo ----------------------------------
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
fi		

	
#maybe we don't need this...
if [ -f "nasm-2.10.09/compile.done" ]; then
	echo ----------------------------------
	echo "nasm-2.10.09 is already compiled"
	echo ----------------------------------
	else 
		cd $LOCALBUILDDIR
		wget -c http://www.nasm.us/pub/nasm/releasebuilds/2.10.09/nasm-2.10.09.tar.gz
		tar xf nasm-2.10.09.tar.gz
		cd nasm-2.10.09
		./configure --prefix=/mingw64
		sed -i 's/ -mthreads//g' Makefile
		sed -i 's/ -mthreads//g' rdoff/Makefile
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		cd $LOCALBUILDDIR
		rm nasm-2.10.09.tar.gz
fi		

if [ -f "pkg-config-lite-0.28-1/compile.done" ]; then
	echo ----------------------------------
	echo "pkg-config-lite-0.28-1 is already compiled"
	echo ----------------------------------
	else 
		wget -c http://downloads.sourceforge.net/project/pkgconfiglite/0.28-1/pkg-config-lite-0.28-1.tar.gz
		tar xf pkg-config-lite-0.28-1.tar.gz
		cd pkg-config-lite-0.28-1
		./configure --host=x86_64-pc-mingw32 --prefix=/mingw64 --enable-shared=no --with-pc-path="/local64/lib/pkgconfig"
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		cd $LOCALBUILDDIR
		rm pkg-config-lite-0.28-1.tar.gz
fi	

if [ -f "libiconv-1.14/compile.done" ]; then
	echo ----------------------------------
	echo "libiconv-1.14 is already compiled"
	echo ----------------------------------
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
fi

if [ -f "pcre-8.33/compile.done" ]; then
	echo ----------------------------------
	echo "pcre-8.33 is already compiled"
	echo ----------------------------------
	else 
		wget -c ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.33.tar.gz
		tar xf pcre-8.33.tar.gz
		cd pcre-8.33
		./configure --build=x86_64-w64-mingw32 --prefix=$LOCALDESTDIR --enable-pcre16 --enable-pcre32 --enable-unicode-properties --enable-newline-is-any --enable-shared=no --enable-static=yes
		make -j $cpuCount
		make install
		echo 'finish' > compile.done
		cd $LOCALDESTDIR/include
		cp pcreposix.h regex.h
		cd $LOCALDESTDIR/lib
		cp libpcreposix.a libregex.a
		cp libpcreposix.a libgnurx.a
		cd $LOCALBUILDDIR
		rm pcre-8.33.tar.gz
fi

if [ -f "openssl-1.0.1e/compile.done" ]; then
	echo ----------------------------------
	echo "openssl-1.0.1e is already compiled"
	echo ----------------------------------
	else 
		wget -c http://www.openssl.org/source/openssl-1.0.1e.tar.gz
		tar xf openssl-1.0.1e.tar.gz
		cd openssl-1.0.1e
		./Configure --prefix=$LOCALDESTDIR -DHAVE_STRUCT_TIMESPEC -L/local64/lib -lz -lws2_32 no-shared zlib mingw64
		make -j $cpuCount
		make test
		make install
		echo 'finish' > compile.done
		cd $LOCALBUILDDIR
		rm openssl-1.0.1e.tar.gz
fi

if [ -f "rtmpdump-2.3/compile.done" ]; then
	echo ----------------------------------
	echo "rtmpdump-2.3 is already compiled"
	echo ----------------------------------
	else 
	wget --no-check-certificate -c https://github.com/snpn/rtmpdump/archive/master.zip -O rtmpdump-master.zip
	unzip rtmpdump-master.zip
	cd rtmpdump-master
	sed -i 's/LIB_OPENSSL=-lssl -lcrypto $(LIBZ)/LIB_OPENSSL=-lssl -lcrypto $(LIBZ) -L\/local64\/lib/g' Makefile
	sed -i 's/LIB_OPENSSL=-lssl -lcrypto $(LIBZ)/LIB_OPENSSL=-lssl -lcrypto $(LIBZ) -L\/local64\/lib/g' librtmp/Makefile
	make SYS=mingw SHARED=no
	cp -iv *.exe $LOCALDESTDIR/bin
	mkdir $LOCALDESTDIR/include/librtmp
	cd librtmp
	cp -iv amf.h http.h log.h rtmp.h $LOCALDESTDIR/include/librtmp
	cp -iv librtmp*.a $LOCALDESTDIR/lib

if [ -n "/local64/lib/pkgconfig/librtmp.pc" ]; then
cat > /local64/lib/pkgconfig/librtmp.pc << "EOF"
prefix=/local64
exec_prefix=${prefix}
libdir=${exec_prefix}/lib
incdir=${prefix}/include/librtmp

Name: librtmp
Description: RTMP implementation
Version: 2.4
Requires: openssl libcrypto

Libs: -L${libdir} -lrtmp -lwinmm -lz
Libs.private: -lws2_32 -lgdi32 -lssl -lcrypto
Cflags: -I${incdir}
EOF
fi

cd $LOCALBUILDDIR
rm rtmpdump-master.zip
fi
