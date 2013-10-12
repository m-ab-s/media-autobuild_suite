source /local64/etc/profile.local

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
echo "compile video tools 64 bit"
echo 
echo "-------------------------------------------------------------------------------"

cd $LOCALBUILDDIR

if [ -f "x264-git/compile8.done" ]; then
	echo -------------------------------------------------
	echo "x264 is already compiled"
	echo -------------------------------------------------
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
		echo "finish" > compile8.done
		make clean
		
		if [ -f "$LOCALDESTDIR/lib/libx264.a" ]; then
			echo -
			echo -------------------------------------------------
			echo "build x264 done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build x264 failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
fi

if [ -f "x264-git/compile10.done" ]; then
	echo -------------------------------------------------
	echo "x264-10bit is already compiled"
	echo -------------------------------------------------
	else 
		./configure --host=x86_64-pc-mingw32 --extra-cflags=-fno-aggressive-loop-optimizations --enable-static --prefix=$LOCALDESTDIR --extra-cflags='-DX264_VERSION=20100422' --enable-win32thread --bit-depth=10
		make -j $cpuCount
		mv x264.exe x264-10bit.exe
		cp x264-10bit.exe /local64/bin/x264-10bit.exe
		echo "finish" > compile10.done
		make clean
		
		if [ -f "$LOCALDESTDIR/bin/x264-10bit.exe" ]; then
			echo -
			echo -------------------------------------------------
			echo "build x264-10bit done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build x264-10bit failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
fi

cd $LOCALBUILDDIR

if [ -f "xvidcore/compile.done" ]; then
	echo -------------------------------------------------
	echo "xvidcore is already compiled"
	echo -------------------------------------------------
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
		echo "finish" > xvidcore/compile.done
		rm xvidcore-1.3.2.tar.gz
		if [[ -f "/local64/lib/xvidcore.dll" ]]; then
			rm /local64/lib/xvidcore.dll || exit 1
			mv /local64/lib/xvidcore.a /local64/lib/libxvidcore.a || exit 1
		fi
		
		if [ -f "$LOCALDESTDIR/lib/libxvidcore.a" ]; then
			echo -
			echo -------------------------------------------------
			echo "build xvidcore done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build xvidcore failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
fi

if [ -f "libvpx-git/compile.done" ]; then
    echo -------------------------------------------------
    echo "libvpx is already compiled"
    echo -------------------------------------------------
    else 
        if [ -f "libvpx-git/configure" ]; then
            cd libvpx-git
            echo " updating libvpx-git"
            git pull http://git.chromium.org/webm/libvpx.git || exit 1
        else 
            git clone http://git.chromium.org/webm/libvpx.git libvpx-git
            cd libvpx-git
        fi
        ./configure --target=x86_64-win64-gcc --prefix=$LOCALDESTDIR --disable-shared --enable-static --disable-examples --disable-unit-tests --disable-docs
		sed -i 's/HAVE_GNU_STRIP=yes/HAVE_GNU_STRIP=no/g' libs-x86_64-win64-gcc.mk
        make -j $cpuCount
        make install
        echo "finish" > compile.done
		cd $LOCALBUILDDIR
		
		if [ -f "$LOCALDESTDIR/lib/libvpx.a" ]; then
			echo -
			echo -------------------------------------------------
			echo "build libvpx done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build libvpx failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
fi

if [[ $mp4box = "y" ]]; then
	if [ -f "mp4box_gpac/compile.done" ]; then
		echo -------------------------------------------------
		echo "mp4box_gpac is already compiled"
		echo -------------------------------------------------
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
			
			if [ -f "$LOCALDESTDIR/bin/mp4box.exe" ]; then
				echo -
				echo -------------------------------------------------
				echo "build mp4box done..."
				echo -------------------------------------------------
				echo -
				else
					echo -------------------------------------------------
					echo "build mp4box failed..."
					echo "delete the source folder under '$LOCALBUILDDIR' and start again"
					read -p "first close the batch window, then the shell window"
					sleep 15
			fi
	fi
fi

if [ -f "libbluray-0.2.3/compile.done" ]; then
	echo -------------------------------------------------
	echo "libbluray-0.2.3 is already compiled"
	echo -------------------------------------------------
	else 
		wget -c ftp://ftp.videolan.org/pub/videolan/libbluray/0.2.3/libbluray-0.2.3.tar.bz2 
		tar xf libbluray-0.2.3.tar.bz2
		cd libbluray-0.2.3
		./configure --host=x86_64-pc-mingw32 --prefix=$LOCALDESTDIR --disable-shared --enable-static
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		cd $LOCALBUILDDIR
		rm libbluray-0.2.3.tar.bz2
		
		if [ -f "$LOCALDESTDIR/lib/libbluray.a" ]; then
			echo -
			echo -------------------------------------------------
			echo "build libbluray-0.2.3 done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build libbluray-0.2.3 failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
fi

sleep 3