source /local32/etc/profile.local

cpuCount=6
while true; do
  case $1 in
--cpuCount=* ) cpuCount="${1#*=}"; shift ;;
--nonfree=* ) nonfree="${1#*=}"; shift ;;
    -- ) shift; break ;;
    -* ) echo "Error, unknown option: '$1'."; exit 1 ;;
    * ) break ;;
  esac
done

cd $LOCALBUILDDIR

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
fi

if [ -f "gmp-5.0.5/compile.done" ]; then
	echo -------------------------------------------------
	echo "gmp-5.0.5 is already compiled"
	echo -------------------------------------------------
	else 
		wget -c ftp://ftp.gnu.org/gnu/gmp/gmp-5.0.5.tar.bz2
		tar xf gmp-5.0.5.tar.bz2
		cd gmp-5.0.5
		./configure --prefix=$LOCALDESTDIR --enable-shared=no
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		cd $LOCALBUILDDIR
		rm gmp-5.0.5.tar.bz2
fi

if [ -f "nettle-2.7.1/compile.done" ]; then
	echo -------------------------------------------------
	echo "nettle-2.7.1 is already compiled"
	echo -------------------------------------------------
	else 
		wget -c http://www.lysator.liu.se/~nisse/archive/nettle-2.7.1.tar.gz
		tar xf nettle-2.7.1.tar.gz
		cd nettle-2.7.1
		./configure --prefix=$LOCALDESTDIR --enable-shared=no
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		cd $LOCALBUILDDIR
		rm nettle-2.7.1.tar.gz
fi

if [ -f "libtool-2.4.2/compile.done" ]; then
	echo -------------------------------------------------
	echo "libtool-2.4.2 is already compiled"
	echo -------------------------------------------------
	else 
		wget -c ftp://ftp.gnu.org/gnu/libtool/libtool-2.4.2.tar.gz
		tar xf libtool-2.4.2.tar.gz
		cd libtool-2.4.2
		./configure --prefix=$LOCALDESTDIR --enable-shared=no
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		cd $LOCALBUILDDIR
		rm libtool-2.4.2.tar.gz
fi

if [ -f "libunistring-0.9.3/compile.done" ]; then
	echo -------------------------------------------------
	echo "libunistring-0.9.3 is already compiled"
	echo -------------------------------------------------
	else 
		wget -c http://ftp.gnu.org/gnu/libunistring/libunistring-0.9.3.tar.gz
		tar xf libunistring-0.9.3.tar.gz
		cd libunistring-0.9.3
		./configure --prefix=$LOCALDESTDIR --enable-shared=no
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		cd $LOCALBUILDDIR
		rm libunistring-0.9.3.tar.gz
fi

if [ -f "libffi-3.0.13/compile.done" ]; then
	echo -------------------------------------------------
	echo "libffi-3.0.13 is already compiled"
	echo -------------------------------------------------
	else 
		wget -c ftp://sourceware.org/pub/libffi/libffi-3.0.13.tar.gz
		tar xf libffi-3.0.13.tar.gz
		cd libffi-3.0.13
		./configure --prefix=$LOCALDESTDIR --enable-shared=no
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		cd $LOCALBUILDDIR
		rm libffi-3.0.13.tar.gz
fi

if [ -f "gc-7.2/compile.done" ]; then
	echo -------------------------------------------------
	echo "gc-7.2 is already compiled"
	echo -------------------------------------------------
	else 
		wget -c http://www.hpl.hp.com/personal/Hans_Boehm/gc/gc_source/gc.tar.gz
		tar xf gc.tar.gz
		cd gc-7.2
		./configure --prefix=$LOCALDESTDIR --enable-shared=no
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		cd $LOCALBUILDDIR
		rm gc.tar.gz
fi

if [ -f "readline-6.2/compile.done" ]; then
	echo -------------------------------------------------
	echo "readline-6.2 is already compiled"
	echo -------------------------------------------------
	else 
		wget -c ftp://ftp.cwru.edu/pub/bash/readline-6.2.tar.gz
		tar xf readline-6.2.tar.gz
		cd readline-6.2
		./configure --prefix=$LOCALDESTDIR --enable-shared=no
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		cd $LOCALBUILDDIR
		rm readline-6.2.tar.gz
fi

if [ -f "guile-2.0.9/compile.done" ]; then
	echo -------------------------------------------------
	echo "guile-2.0.9 is already compiled"
	echo -------------------------------------------------
	else 
		wget -c ftp://ftp.gnu.org/pub/gnu/guile/guile-2.0.9.tar.gz
		tar xf guile-2.0.9.tar.gz
		cd guile-2.0.9
		./configure --prefix=$LOCALDESTDIR --enable-shared=no
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		cd $LOCALBUILDDIR
		rm guile-2.0.9.tar.gz
fi

if [ -f "gnutls-3.2.3/compile.done" ]; then
	echo -------------------------------------------------
	echo "gnutls-3.2.3 is already compiled"
	echo -------------------------------------------------
	else 
		wget -c ftp://ftp.gnutls.org/gcrypt/gnutls/v3.2/gnutls-3.2.3.tar.xz
		tar xf gnutls-3.2.3.tar.xz
		cd gnutls-3.2.3
		./configure --prefix=$LOCALDESTDIR --enable-shared=no --disable-cxx --disable-doc
		make -j $cpuCount
		make install
		sed -i 's/-lgnutls *$/-lgnutls -lnettle -lhogweed -lgmp -lcrypt32 -lws2_32 -liconv/' "$PKG_CONFIG_PATH/gnutls.pc"
		echo "finish" > compile.done
		cd $LOCALBUILDDIR
		rm gnutls-3.2.3.tar.xz
fi

sleep 150