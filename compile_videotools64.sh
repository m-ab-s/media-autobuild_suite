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

echo "-------------------------------------------------------------------------------"
echo 
echo "compile video tools 64 bit"
echo 
echo "-------------------------------------------------------------------------------"

cd $LOCALBUILDDIR

if [ -f "x264-git/x264.exe" ]; then
	echo ----------------------------------
	echo "x264 is already compiled"
	echo ----------------------------------
	else 
		if [ -f "x264-git/configure" ]; then
			cd x264-git
			echo " updating x264-git"
			git pull http://repo.or.cz/r/x264.git || exit 1
			else 
				git clone http://repo.or.cz/r/x264.git x264-git
				cd x264-git
		  fi
		./configure --host=x86_64-pc-mingw32 --extra-cflags=-fno-aggressive-loop-optimizations --enable-static --prefix=$LOCALDESTDIR --extra-cflags='-DX264_VERSION=20100422' --enable-win32thread
		make -j $cpuCount
		make install
		make clean
fi

if [ -f "x264-git/x264-10bit.exe" ]; then
	echo ----------------------------------
	echo "x264-10bit is already compiled"
	echo ----------------------------------
	else 
	./configure --host=x86_64-pc-mingw32 --extra-cflags=-fno-aggressive-loop-optimizations --enable-static --prefix=$LOCALDESTDIR --extra-cflags='-DX264_VERSION=20100422' --enable-win32thread --bit-depth=10
	make -j $cpuCount
	mv x264.exe x264-10bit.exe
	cp x264-10bit.exe /local64/bin/x264-10bit.exe
fi

cd $LOCALBUILDDIR

if [ -f "xvidcore/compile.done" ]; then
	echo ----------------------------------
	echo "xvidcore is already compiled"
	echo ----------------------------------
	else 
		wget -c http://downloads.xvid.org/downloads/xvidcore-1.3.2.tar.gz
		tar xf xvidcore-1.3.2.tar.gz
		cd xvidcore/build/generic
		./configure --host=x86_64-pc-mingw32 --build=x86_64-unknown-linux-gnu --disable-assembly --prefix=$LOCALDESTDIR
		sed -i "s/-mno-cygwin//" platform.inc
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		cd $LOCALBUILDDIR
		rm xvidcore-1.3.2.tar.gz
		if [[ -f "/local64/lib/xvidcore.dll" ]]; then
			rm /local64/lib/xvidcore.dll || exit 1
			mv /local64/lib/xvidcore.a /local64/lib/libxvidcore.a || exit 1
		fi
fi
