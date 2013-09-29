source /local32/etc/profile.local

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
echo "compile video tools 32 bit"
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
		./configure --extra-cflags=-fno-aggressive-loop-optimizations --enable-static --prefix=$LOCALDESTDIR --extra-cflags='-DX264_VERSION=20100422' --enable-win32thread
		make -j $cpuCount
		make install
		make clean
fi

if [ -f "x264-git/x264-10bit.exe" ]; then
	echo ----------------------------------
	echo "x264-10bit is already compiled"
	echo ----------------------------------
	else 
	./configure --extra-cflags=-fno-aggressive-loop-optimizations --enable-static --prefix=$LOCALDESTDIR --extra-cflags='-DX264_VERSION=20100422' --enable-win32thread --bit-depth=10
	make -j $cpuCount
	mv x264.exe x264-10bit.exe
	cp x264-10bit.exe /local32/bin/x264-10bit.exe
	make clean
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
		./configure --prefix=$LOCALDESTDIR
		sed -i "s/-mno-cygwin//" platform.inc
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		cd $LOCALBUILDDIR
		rm xvidcore-1.3.2.tar.gz
		if [[ -f "/local32/lib/xvidcore.dll" ]]; then
			rm /local32/lib/xvidcore.dll || exit 1
			mv /local32/lib/xvidcore.a /local32/lib/libxvidcore.a || exit 1
		fi
fi
