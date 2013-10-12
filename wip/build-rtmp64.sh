source /local64/etc/profile.local

cd $LOCALBUILDDIR

wget ftp://ftp.gnu.org/gnu/gmp/gmp-5.1.3.tar.bz2
tar xf gmp-5.1.3.tar.bz2
rm gmp-5.1.3.tar.bz2
cd gmp-5.1.3
./configure --prefix=$LOCALDESTDIR --host=x86_64-pc-mingw32 --build=x86_64-pc-mingw32 --enable-cxx --disable-shared --with-gnu-ld
make -j6
make install

cd $LOCALBUILDDIR

wget -c http://www.lysator.liu.se/~nisse/archive/nettle-2.7.1.tar.gz
tar xf nettle-2.7.1.tar.gz
rm nettle-2.7.1.tar.gz
cd nettle-2.7.1
./configure --prefix=$LOCALDESTDIR --host=x86_64-pc-mingw32 --build=x86_64-pc-mingw32 --disable-shared
make -j6
make install

cd $LOCALBUILDDIR

wget ftp://ftp.gnupg.org/gcrypt/libgpg-error/libgpg-error-1.12.tar.bz2
tar xf libgpg-error-1.12.tar.bz2
rm libgpg-error-1.12.tar.bz2
cd libgpg-error-1.12
./configure --prefix=$LOCALDESTDIR --host=x86_64-pc-mingw32 --build=x86_64-pc-mingw32 --disable-shared --with-gnu-ld
sed -i 's/iconv --silent/iconv -s/g' potomo
make -j6
make install

cd $LOCALBUILDDIR

wget ftp://ftp.gnupg.org/gcrypt/libgcrypt/libgcrypt-1.5.3.tar.bz2
tar xf libgcrypt-1.5.3.tar.bz2
rm libgcrypt-1.5.3.tar.bz2
cd libgcrypt-1.5.3
./configure --prefix=$LOCALDESTDIR --host=x86_64-pc-mingw32 --build=x86_64-pc-mingw32 --disable-shared --with-gnu-ld
make -j6
make install

cd $LOCALBUILDDIR

wget ftp://ftp.gnutls.org/gcrypt/gnutls/v3.2/gnutls-3.2.3.tar.xz
tar xf gnutls-3.2.3.tar.xz
rm gnutls-3.2.3.tar.xz
cd gnutls-3.2.3
./configure --prefix=$LOCALDESTDIR --host=x86_64-pc-mingw32 --build=x86_64-pc-mingw32 --enable-threads=win32 --disable-guile --disable-doc --disable-tests --disable-shared --with-gnu-ld
make -j6
make install
sed -i 's/-lgnutls *$/-lgnutls -lnettle -lhogweed -liconv -lcrypt32 -lws2_32 -lz -lgmp/' $PKG_CONFIG_PATH/gnutls.pc

cd $LOCALBUILDDIR

git clone git://git.ffmpeg.org/rtmpdump rtmpdump
cd rtmpdump
sed -i 's/LIB_GNUTLS=.*/LIB_GNUTLS=-lgnutls -lhogweed -lnettle -lgmp -liconv $(LIBZ)/' Makefile
sed -i 's/LIBS_mingw=.*/LIBS_mingw=-lws2_32 -lwinmm -lgdi32 -lcrypt32/' Makefile
make LDFLAGS="$LDFLAGS" prefix=$LOCALDESTDIR CRYPTO=GNUTLS SHARED= SYS=mingw install
sed -i 's/Libs:.*/Libs: -L${libdir} -lrtmp -lz -lws2_32 -lwinmm -lgdi32/' $PKG_CONFIG_PATH/librtmp.pc