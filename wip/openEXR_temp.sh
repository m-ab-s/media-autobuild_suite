cd $LOCALBUILDDIR
wget -c http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.14.tar.gz
tar xzf libiconv-1.14.tar.gz
cd libiconv-1.14
./configure --prefix=$LOCALDESTDIR
make
make install

cd $LOCALBUILDDIR
wget -c http://ftp.gnu.org/pub/gnu/gettext/gettext-0.18.3.1.tar.gz
tar xzf gettext-0.18.3.1.tar.gz
mv gettext-0.18.3.1 gettext-0.18.3.1-runtime
cd gettext-0.18.3.1-runtime
cat gettext-tools/woe32dll/gettextlib-exports.c | grep -v rpl_opt > gettext-tools/woe32dll/gettextlib-exports.c.new
mv gettext-tools/woe32dll/gettextlib-exports.c.new gettext-tools/woe32dll/gettextlib-exports.c
CFLAGS="-mms-bitfields -mthreads -O2" ./configure --prefix=$LOCALDESTDIR --enable-threads=win32 --enable-relocatable
cd gettext-runtime
make
make install

cd $LOCALBUILDDIR
tar xzf gettext-0.18.3.1.tar.gz
mv gettext-0.18.3.1 gettext-0.18.3.1-static
cd gettext-0.18.3.1-static
CFLAGS="-mms-bitfields -mthreads -O2" ./configure --prefix=$LOCALDESTDIR --enable-threads=win32 --enable-relocatable --disable-shared
make
install gettext-tools/src/msgfmt.exe $LOCALDESTDIR/bin
install gettext-tools/src/msgmerge.exe $LOCALDESTDIR/bin
install gettext-tools/src/xgettext.exe $LOCALDESTDIR/bin

cd $LOCALBUILDDIR
cd libiconv-1.14
./configure --prefix=$LOCALDESTDIR
make clean
make
make install

cd $LOCALBUILDDIR
svn checkout svn://dev.exiv2.org/svn/trunk exiv2
cd exiv2
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX:PATH=$LOCALDESTDIR -G "MSYS Makefiles" ..
make
make install

cd $LOCALBUILDDIR
wget -c ftp://ftp.fftw.org/pub/fftw/fftw-3.2.2.tar.gz
cd fftw-3.2.2
#sed -i 's/.\/configure --disable-shared --enable-maintainer-mode --enable-threads $*/ /g' bootstrap.sh
#sed -i 's/configur*/ /g' bootstrap.sh
./configure --prefix=/local32 --with-our-malloc16 --with-windows-f77-mangling --enable-shared --enable-threads --with-combined-threads --enable-portable-binary --enable-float --enable-sse
make 
make install

cd $LOCALBUILDDIR
wget -c https://github.com/downloads/openexr/openexr/ilmbase-1.0.3.tar.gz
tar xf ilmbase-1.0.3.tar.gz
ch ilmbase-1.0.3
sed -i 's/#if !defined (_WIN32) &&!(_WIN64) && !(HAVE_PTHREAD)/#if true/g' IlmThread/IlmThread.cpp
sed -i 's/#if !defined (_WIN32) && !(_WIN64) && !(HAVE_PTHREAD)/#if true/g' IlmThread/IlmThreadMutex.cpp
sed -i 's/#if !defined (_WIN32) && !(_WIN64) && !(HAVE_PTHREAD)/#if true/g' IlmThread/IlmThreadSemaphore.cpp
./configure --disable-threading --disable-posix-sem --prefix=/local32
make
make install








