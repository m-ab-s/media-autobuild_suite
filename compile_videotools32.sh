source /local32/etc/profile.local

# set CPU count global. This can be overwrite from the compiler script (ffmpeg-autobuild.bat)
cpuCount=1
while true; do
  case $1 in
--cpuCount=* ) cpuCount="${1#*=}"; shift ;;
--mp4box=* ) mp4box="${1#*=}"; shift ;;
--mplayer=* ) mplayer="${1#*=}"; shift ;;
--nonfree=* ) nonfree="${1#*=}"; shift ;;
    -- ) shift; break ;;
    -* ) echo "Error, unknown option: '$1'."; exit 1 ;;
    * ) break ;;
  esac
done

if [[ $nonfree = "y" ]]; then
    faac=""
  else
    if  [[ $nonfree = "n" ]]; then
      faac="--disable-faac --disable-faac-lavc" 
	fi
fi	

echo "-------------------------------------------------------------------------------"
echo 
echo "compile video tools 32 bit"
echo 
echo "-------------------------------------------------------------------------------"

cd $LOCALBUILDDIR

if [ -f "x264-git/configure" ]; then
	echo -ne "\033]0;compiling x264 32Bit\007"
	cd x264-git
	oldHead=`git rev-parse HEAD`
	git pull origin master
	newHead=`git rev-parse HEAD`
	if [[ "$oldHead" != "$newHead" ]]; then
		rm $LOCALDESTDIR/bin/x264-10bit.exe
		make uninstall
		make clean
		./configure --prefix=$LOCALDESTDIR --extra-cflags=-fno-aggressive-loop-optimizations --enable-static --enable-win32thread
		make -j $cpuCount
		make install
		make clean

		./configure --prefix=$LOCALDESTDIR --extra-cflags=-fno-aggressive-loop-optimizations --enable-static --enable-win32thread --bit-depth=10
		make -j $cpuCount
		cp x264.exe $LOCALDESTDIR/bin/x264-10bit.exe
		
		if [ -f "$LOCALDESTDIR/bin/x264-10bit.exe" ]; then
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
	else
		echo -------------------------------------------------
		echo "x264 is already up to date"
		echo -------------------------------------------------
	fi
	else
	echo -ne "\033]0;compiling x264 32Bit\007"
		git clone http://repo.or.cz/r/x264.git x264-git
		cd x264-git
		./configure --extra-cflags=-fno-aggressive-loop-optimizations --enable-static --prefix=$LOCALDESTDIR --extra-cflags='-DX264_VERSION=20100422' --enable-win32thread
		make -j $cpuCount
		make install
		make clean

		./configure --extra-cflags=-fno-aggressive-loop-optimizations --enable-static --prefix=$LOCALDESTDIR --extra-cflags='-DX264_VERSION=20100422' --enable-win32thread --bit-depth=10
		make -j $cpuCount
		cp x264.exe $LOCALDESTDIR/bin/x264-10bit.exe
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
		echo -ne "\033]0;compiling xvidcore 32Bit\007"
		wget -c http://downloads.xvid.org/downloads/xvidcore-1.3.2.tar.gz
		tar xf xvidcore-1.3.2.tar.gz
		rm xvidcore-1.3.2.tar.gz
		cd xvidcore/build/generic
		./configure --prefix=$LOCALDESTDIR
		sed -i "s/-mno-cygwin//" platform.inc
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		
		if [[ -f "/local32/lib/xvidcore.dll" ]]; then
			rm /local32/lib/xvidcore.dll || exit 1
			mv /local32/lib/xvidcore.a /local32/lib/libxvidcore.a || exit 1
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

cd $LOCALBUILDDIR

if [ -f "libvpx-git/configure" ]; then
	echo -ne "\033]0;compiling libvpx 32Bit\007"
	cd libvpx-git
	oldHead=`git rev-parse HEAD`
	git pull origin master
	newHead=`git rev-parse HEAD`
	if [[ "$oldHead" != "$newHead" ]]; then
	if [ -d "$LOCALDESTDIR/include/vpx" ]; then rm -r $LOCALDESTDIR/include/vpx; fi
	if [ -f "$LOCALDESTDIR/lib/pkgconfig/vpx.pc" ]; then rm $LOCALDESTDIR/lib/pkgconfig/vpx.pc; fi
	if [ -f "$LOCALDESTDIR/lib/libvpx.a" ]; then rm $LOCALDESTDIR/lib/libvpx.a; fi
		make clean
		./configure --prefix=$LOCALDESTDIR --disable-shared --enable-static --disable-unit-tests --disable-docs
		sed -i 's/HAVE_GNU_STRIP=yes/HAVE_GNU_STRIP=no/g' libs-x86-win32-gcc.mk
        make -j $cpuCount
        make install
		cp vpxdec.exe $LOCALDESTDIR/bin/vpxdec.exe
		cp vpxenc.exe $LOCALDESTDIR/bin/vpxenc.exe
		
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
	else
		echo -------------------------------------------------
		echo "libvpx-git is already up to date"
		echo -------------------------------------------------
	fi
	else
		echo -ne "\033]0;compiling libvpx 32Bit\007"
		git clone http://git.chromium.org/webm/libvpx.git libvpx-git
		cd libvpx-git
		./configure --prefix=$LOCALDESTDIR --disable-shared --enable-static --disable-unit-tests --disable-docs
		sed -i 's/HAVE_GNU_STRIP=yes/HAVE_GNU_STRIP=no/g' libs-x86-win32-gcc.mk
		make -j $cpuCount
		make install
		cp vpxdec.exe $LOCALDESTDIR/bin/vpxdec.exe
		cp vpxenc.exe $LOCALDESTDIR/bin/vpxenc.exe
		
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

cd $LOCALBUILDDIR
		
if [ -f "libbluray-git/bootstrap" ]; then
	echo -ne "\033]0;compiling libbluray 32Bit\007"
	cd libbluray-git
	oldHead=`git rev-parse HEAD`
	git pull origin master
	newHead=`git rev-parse HEAD`
	if [[ "$oldHead" != "$newHead" ]]; then
		make uninstall
		make clean
		/bootstrap
		./configure --prefix=$LOCALDESTDIR --disable-shared --enable-static
		make -j $cpuCount
		make install
		
		if [ -f "$LOCALDESTDIR/lib/libbluray.a" ]; then
			echo -
			echo -------------------------------------------------
			echo "build libbluray-git done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build libbluray-git failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
	else
		echo -------------------------------------------------
		echo "libbluray is already up to date"
		echo -------------------------------------------------
	fi
	else
		echo -ne "\033]0;compiling libbluray 32Bit\007"
		git clone git://git.videolan.org/libbluray.git libbluray-git
		cd libbluray-git
		./bootstrap
		./configure --prefix=$LOCALDESTDIR --disable-shared --enable-static
		make -j $cpuCount
		make install

		if [ -f "$LOCALDESTDIR/lib/libbluray.a" ]; then
			echo -
			echo -------------------------------------------------
			echo "build libbluray-git done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build libbluray-git failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
fi

cd $LOCALBUILDDIR

if [ -f "libutvideo-git/compile.done" ]; then
	echo -------------------------------------------------
	echo "libutvideo is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compiling libutvideo 32Bit\007"
		git clone git://github.com/qyot27/libutvideo.git libutvideo-git
		cd libutvideo-git
		./configure --prefix=$LOCALDESTDIR
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		cd $LOCALBUILDDIR
		
		if [ -f "$LOCALDESTDIR/lib/libutvideo.a" ]; then
			echo -
			echo -------------------------------------------------
			echo "build libutvideo done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build libutvideo failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
fi

if [ -f "xavs/compile.done" ]; then
	echo -------------------------------------------------
	echo "xavs is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compiling xavs 32Bit\007"
		svn checkout --trust-server-cert https://svn.code.sf.net/p/xavs/code/trunk/ xavs
		cd xavs
		./configure --prefix=$LOCALDESTDIR
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		cd $LOCALBUILDDIR
		
		if [ -f "$LOCALDESTDIR/lib/libxavs.a" ]; then
			echo -
			echo -------------------------------------------------
			echo "build xavs done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build xavs failed..."
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
			echo -ne "\033]0;compiling mp4box_gpac 32Bit\007"
			svn co svn://svn.code.sf.net/p/gpac/code/trunk/gpac mp4box_gpac
			cd mp4box_gpac
			rm extra_lib/include/zlib/zconf.h
			rm extra_lib/include/zlib/zlib.h
			cp $LOCALDESTDIR/lib/libz.a extra_lib/lib/gcc
			cp $LOCALDESTDIR/include/zconf.h extra_lib/include/zlib
			cp $LOCALDESTDIR/include/zlib.h extra_lib/include/zlib
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

if [[ $mplayer = "y" ]]; then
	if [ -f mplayer-checkout*/compile.done ]; then
		echo -------------------------------------------------
		echo "mplayer is already compiled"
		echo -------------------------------------------------
		else 
			echo -ne "\033]0;compiling mplayer 32Bit\007"
			wget -c http://www.mplayerhq.hu/MPlayer/releases/mplayer-checkout-snapshot.tar.bz2
			tar xf mplayer-checkout-snapshot.tar.bz2
			cd mplayer-checkout*
			
			if ! test -e ffmpeg ; then
				if ! git clone --depth 1 git://source.ffmpeg.org/ffmpeg.git ffmpeg ; then
					rm -rf ffmpeg
					echo "Failed to get a FFmpeg checkout"
					echo "Please try again or put FFmpeg source code copy into ffmpeg/ manually."
					echo "Nightly snapshot: http://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2"
					echo "To use a github mirror via http (e.g. because a firewall blocks git):"
					echo "git clone --depth 1 https://github.com/FFmpeg/FFmpeg ffmpeg; touch ffmpeg/mp_auto_pull"
					exit 1
				fi
				touch ffmpeg/mp_auto_pull
			fi
			./configure --prefix=$LOCALDESTDIR --extra-cflags='-DPTW32_STATIC_LIB -O3' --enable-runtime-cpudetection --enable-static --disable-ass --enable-ass-internal $faac
			make
			make install
			echo "finish" > compile.done
			cd $LOCALBUILDDIR
			rm mplayer-checkout-snapshot.tar.bz2
			
			if [ -f "$LOCALDESTDIR/bin/mplayer.exe" ]; then
				echo -
				echo -------------------------------------------------
				echo "build mplayer done..."
				echo -------------------------------------------------
				echo -
				else
					echo -------------------------------------------------
					echo "build mplayer failed..."
					echo "delete the source folder under '$LOCALBUILDDIR' and start again"
					read -p "first close the batch window, then the shell window"
					sleep 15
			fi
	fi
fi

sleep 3