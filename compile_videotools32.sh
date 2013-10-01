source /local32/etc/profile.local

# set CPU count global. This can be overwrite from the compiler script (ffmpeg-autobuild.bat)
cpuCount=1
while true; do
  case $1 in
--cpuCount=* ) cpuCount="${1#*=}"; shift ;;
--mp4box=* ) mp4box="${1#*=}"; shift ;;
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

if [ -f "x264-git/compile8.done" ]; then
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
		echo "finish" > compile8.done
		make clean
fi

if [ -f "x264-git/compile10.done" ]; then
	echo ----------------------------------
	echo "x264-10bit is already compiled"
	echo ----------------------------------
	else 
	./configure --extra-cflags=-fno-aggressive-loop-optimizations --enable-static --prefix=$LOCALDESTDIR --extra-cflags='-DX264_VERSION=20100422' --enable-win32thread --bit-depth=10
	make -j $cpuCount
	mv x264.exe x264-10bit.exe
	cp x264-10bit.exe /local32/bin/x264-10bit.exe
	echo "finish" > compile10.done
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
		cd $LOCALBUILDDIR
		echo "finish" > xvidcore/compile.done
		rm xvidcore-1.3.2.tar.gz
		if [[ -f "/local32/lib/xvidcore.dll" ]]; then
			rm /local32/lib/xvidcore.dll || exit 1
			mv /local32/lib/xvidcore.a /local32/lib/libxvidcore.a || exit 1
		fi
fi

if [[ $mp4box = "y" ]]; then
	if [ -f "mp4box_gpac/compile.done" ]; then
		echo ----------------------------------
		echo "mp4box_gpac is already compiled"
		echo ----------------------------------
		else 
			svn co svn://svn.code.sf.net/p/gpac/code/trunk/gpac mp4box_gpac
			cd mp4box_gpac
			rm extra_lib/linclude/zlib/zconf.h
			rm extra_lib/linclude/zlib/zlib.h
			cp $LOCALDESTDIR/lib/libz.a extra_lib/lib/gcc
			cp $LOCALDESTDIR/include/zconf.h extra_lib/linclude/zlib
			cp $LOCALDESTDIR/include/zlib.h extra_lib/linclude/zlib
			./configure --static-mp4box --enable-static-bin --extra-libs=-lws2_32 -lwinmm --use-zlib=local --use-ffmpeg=no --use-png=no 
			cp config.h include/gpac/internal
			make -j $cpuCount
			cp bin/gcc/MP4Box.exe $LOCALDESTDIR/bin
			echo "finish" > compile.done
			cd $LOCALBUILDDIR
			echo "mp4box done..."
	fi
fi