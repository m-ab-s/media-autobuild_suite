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