source /local32/etc/profile.local

# set CPU count global. This can be overwrite from the compiler script (ffmpeg-autobuild.bat)
cpuCount=6
while true; do
  case $1 in
--cpuCount=* ) cpuCount="${1#*=}"; shift ;;
    -- ) shift; break ;;
    -* ) echo "Error, unknown option: '$1'."; exit 1 ;;
    * ) break ;;
  esac
done

cd $LOCALBUILDDIR
wget -c http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.14.tar.gz
tar xzf libiconv-1.14.tar.gz
rm libiconv-1.14.tar.gz
cd libiconv-1.14
./configure --prefix=$LOCALDESTDIR
make -j $cpuCount
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
make -j $cpuCount
make install

cd $LOCALBUILDDIR
tar xzf gettext-0.18.3.1.tar.gz
rm gettext-0.18.3.1.tar.gz
mv gettext-0.18.3.1 gettext-0.18.3.1-static
cd gettext-0.18.3.1-static
CFLAGS="-mms-bitfields -mthreads -O2" ./configure --prefix=$LOCALDESTDIR --enable-threads=win32 --enable-relocatable --disable-shared
make -j $cpuCount
install gettext-tools/src/*.exe $LOCALDESTDIR/bin
install gettext-tools/misc/autopoint $LOCALDESTDIR/bin

cd $LOCALBUILDDIR
cd libiconv-1.14
./configure --prefix=$LOCALDESTDIR
make clean
make -j $cpuCount
make install

cd $LOCALBUILDDIR
svn checkout svn://dev.exiv2.org/svn/trunk exiv2
cd exiv2
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX:PATH=$LOCALDESTDIR -G "MSYS Makefiles" ..
make -j $cpuCount
make install

cd $LOCALBUILDDIR
wget -c ftp://ftp.fftw.org/pub/fftw/fftw-3.2.2.tar.gz
tar xf fftw-3.2.2.tar.gz
rm fftw-3.2.2.tar.gz
cd fftw-3.2.2
#sed -i 's/.\/configure --disable-shared --enable-maintainer-mode --enable-threads $*/ /g' bootstrap.sh
#sed -i 's/configur*/ /g' bootstrap.sh
./configure --prefix=/local32 --with-our-malloc16 --with-windows-f77-mangling --enable-shared --enable-threads --with-combined-threads --enable-portable-binary --enable-float --enable-sse
make -j $cpuCount
make install

cd $LOCALBUILDDIR
wget --no-check-certificate -c https://github.com/downloads/openexr/openexr/ilmbase-1.0.3.tar.gz
tar xf ilmbase-1.0.3.tar.gz
rm ilmbase-1.0.3.tar.gz
cd ilmbase-1.0.3
sed -i 's/#if !defined (_WIN32) &&!(_WIN64) && !(HAVE_PTHREAD)/#if true/g' IlmThread/IlmThread.cpp
sed -i 's/#if !defined (_WIN32) && !(_WIN64) && !(HAVE_PTHREAD)/#if true/g' IlmThread/IlmThreadMutex.cpp
sed -i 's/#if !defined (_WIN32) && !(_WIN64) && !(HAVE_PTHREAD)/#if true/g' IlmThread/IlmThreadSemaphore.cpp
./configure --disable-threading --disable-posix-sem --prefix=/local32
make -j $cpuCount
make install








