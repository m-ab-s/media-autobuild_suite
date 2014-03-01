# set CPU count global. This can be overwrite from the compiler script (media-autobuild_suite.bat)
cpuCount=1
while true; do
  case $1 in
--cpuCount=* ) cpuCount="${1#*=}"; shift ;;
--build32=* ) build32="${1#*=}"; shift ;;
--build64=* ) build64="${1#*=}"; shift ;;
--mp4box=* ) mp4box="${1#*=}"; shift ;;
--ffmpeg=* ) ffmpeg="${1#*=}"; shift ;;
--mplayer=* ) mplayer="${1#*=}"; shift ;;
--deleteSource=* ) deleteSource="${1#*=}"; shift ;;
--nonfree=* ) nonfree="${1#*=}"; shift ;;
    -- ) shift; break ;;
    -* ) echo "Error, unknown option: '$1'."; exit 1 ;;
    * ) break ;;
  esac
done

# check if compiled file exist
do_checkIfExist() {
	local packetName="$1"
	local fileName="$2"
	local fileExtension=${fileName##*.}
	if [[ "$fileExtension" = "exe" ]]; then
		if [ -f "$LOCALDESTDIR/bin/$fileName" ]; then
			echo -
			echo -------------------------------------------------
			echo "build $packetName done..."
			echo -------------------------------------------------
			echo -
			if [[ $deleteSource = "y" ]]; then
				if [[ ! "${packetName: -4}" = "-git" ]]; then
					if [[ ! "${packetName: -3}" = "-hg" ]]; then
						if [[ ! "${packetName: -4}" = "-svn" ]]; then
							cd $LOCALBUILDDIR
							rm -rf $LOCALBUILDDIR/$packetName
						fi	
					fi
				fi
			fi
			else
				echo -------------------------------------------------
				echo "build $packetName failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi	
	elif [[ "$fileExtension" = "a" ]] || [[ "$fileExtension" = "dll" ]]; then
		if [ -f "$LOCALDESTDIR/lib/$fileName" ]; then
			echo -
			echo -------------------------------------------------
			echo "build $packetName done..."
			echo -------------------------------------------------
			echo -
			if [[ $deleteSource = "y" ]]; then
				if [[ ! "${packetName: -4}" = "-git" ]]; then
					if [[ ! "${packetName: -3}" = "-hg" ]]; then
						if [[ ! "${packetName: -4}" = "-svn" ]]; then
							cd $LOCALBUILDDIR
							rm -rf $LOCALBUILDDIR/$packetName
						fi	
					fi
				fi
			fi
			else
				echo -------------------------------------------------
				echo "build $packetName failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi	
	fi
}

buildProcess() {
cd $LOCALBUILDDIR

if [ -f "x264-git/configure" ]; then
	echo -ne "\033]0;compile x264 $bits\007"
	cd x264-git
	oldHead=`git rev-parse HEAD`
	git pull origin master
	newHead=`git rev-parse HEAD`
	if [[ "$oldHead" != "$newHead" ]]; then
		rm $LOCALDESTDIR/bin/x264-10bit.exe
		make uninstall
		make clean
		
		./configure --host=$targetHost --prefix=$LOCALDESTDIR --extra-cflags=-fno-aggressive-loop-optimizations --enable-static --enable-win32thread --bit-depth=10
		make -j $cpuCount
		cp x264.exe $LOCALDESTDIR/bin/x264-10bit.exe
		
		make clean
		
		./configure --host=$targetHost --prefix=$LOCALDESTDIR --extra-cflags=-fno-aggressive-loop-optimizations --enable-static --enable-win32thread
		make -j $cpuCount
		make install
		
		do_checkIfExist x264-git x264.exe
	else
		echo -------------------------------------------------
		echo "x264 is already up to date"
		echo -------------------------------------------------
	fi
	else
	echo -ne "\033]0;compile x264 $bits\007"
		git clone http://repo.or.cz/r/x264.git x264-git
		cd x264-git
		./configure --host=$targetHost --prefix=$LOCALDESTDIR --extra-cflags=-fno-aggressive-loop-optimizations --enable-static --enable-win32thread --bit-depth=10
		make -j $cpuCount
		cp x264.exe $LOCALDESTDIR/bin/x264-10bit.exe
		
		make clean
		
		./configure --host=$targetHost --prefix=$LOCALDESTDIR --extra-cflags=-fno-aggressive-loop-optimizations --enable-static --enable-win32thread
		make -j $cpuCount
		make install
		
		do_checkIfExist x264-git x264.exe
fi

cd $LOCALBUILDDIR

if [ -f "x265-hg/toolchain.cmake" ]; then
	echo -ne "\033]0;compile x265 $bits\007"
	cd x265-hg
	oldHead=`hg id --id`
	hg pull
	hg update
	newHead=`hg id --id`
	if [[ "$oldHead" != "$newHead" ]]; then
	
if [ ! -f "toolchain.cmake" ]; then
cat > toolchain.cmake << "EOF"
SET(CMAKE_SYSTEM_NAME Windows)
SET(CMAKE_C_COMPILER gcc -static-libgcc)
SET(CMAKE_CXX_COMPILER g++ -static-libgcc)
SET(CMAKE_RC_COMPILER windres)
SET(CMAKE_ASM_YASM_COMPILER yasm)
EOF
fi
		cd build/msys
		make clean
		rm -rf *
		if [ -f "$LOCALDESTDIR/bin/x265-16bit.exe" ]; then rm $LOCALDESTDIR/bin/x265-16bit.exe; fi
		if [ -f "$LOCALDESTDIR/include/x265.h" ]; then rm $LOCALDESTDIR/include/x265.h; fi
		if [ -f "$LOCALDESTDIR/include/x265_config.h" ]; then rm $LOCALDESTDIR/include/x265_config.h; fi
		if [ -f "$LOCALDESTDIR/lib/libx265.a" ]; then rm $LOCALDESTDIR/lib/libx265.a; fi
		if [ -f "$LOCALDESTDIR/lib/libx265.dll.a" ]; then rm $LOCALDESTDIR/lib/libx265.dll.a; fi
		if [ -f "$LOCALDESTDIR/lib/pkgconfig/x265.pc" ]; then rm $LOCALDESTDIR/lib/pkgconfig/x265.pc; fi
		
		cmake -G "MSYS Makefiles" -DCMAKE_TOOLCHAIN_FILE=../../toolchain.cmake -DCMAKE_INSTALL_PREFIX:PATH=$LOCALDESTDIR ../../source 
		make -j $cpuCount
		make install
		make clean
		rm -rf *

		cmake -G "MSYS Makefiles" -DCMAKE_TOOLCHAIN_FILE=../../toolchain.cmake -DHIGH_BIT_DEPTH=1 ../../source
		make -j $cpuCount
		cp x265.exe $LOCALDESTDIR/bin/x265-16bit.exe
		
		do_checkIfExist x265-git x265-16bit.exe
	else
		echo -------------------------------------------------
		echo "x265 is already up to date"
		echo -------------------------------------------------
	fi
	else
	echo -ne "\033]0;compile x265 $bits\007"
		hg clone https://bitbucket.org/multicoreware/x265 x265-hg
		cd x265-hg
cat > toolchain.cmake << "EOF"
SET(CMAKE_SYSTEM_NAME Windows)
SET(CMAKE_C_COMPILER gcc -static-libgcc)
SET(CMAKE_CXX_COMPILER g++ -static-libgcc)
SET(CMAKE_RC_COMPILER windres)
SET(CMAKE_ASM_YASM_COMPILER yasm)
EOF

		cd build/msys
		
		if [ -f "$LOCALDESTDIR/bin/x265-16bit.exe" ]; then rm $LOCALDESTDIR/bin/x265-16bit.exe; fi
		if [ -f "$LOCALDESTDIR/include/x265.h" ]; then rm $LOCALDESTDIR/include/x265.h; fi
		if [ -f "$LOCALDESTDIR/include/x265_config.h" ]; then rm $LOCALDESTDIR/include/x265_config.h; fi
		if [ -f "$LOCALDESTDIR/lib/libx265.a" ]; then rm $LOCALDESTDIR/lib/libx265.a; fi
		if [ -f "$LOCALDESTDIR/lib/libx265.dll.a" ]; then rm $LOCALDESTDIR/lib/libx265.dll.a; fi
		if [ -f "$LOCALDESTDIR/lib/pkgconfig/x265.pc" ]; then rm $LOCALDESTDIR/lib/pkgconfig/x265.pc; fi
		
		cmake -G "MSYS Makefiles" -DCMAKE_TOOLCHAIN_FILE=../../toolchain.cmake -DCMAKE_INSTALL_PREFIX:PATH=$LOCALDESTDIR ../../source 
		make -j $cpuCount
		make install
		make clean
		rm -rf *

		cmake -G "MSYS Makefiles" -DCMAKE_TOOLCHAIN_FILE=../../toolchain.cmake -DHIGH_BIT_DEPTH=1 ../../source
		make -j $cpuCount
		cp x265.exe $LOCALDESTDIR/bin/x265-16bit.exe
		
		do_checkIfExist x265-git x265-16bit.exe
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libxvidcore.a" ]; then
	echo -------------------------------------------------
	echo "xvidcore is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile xvidcore $bits\007"
		if [ -d "xvidcore" ]; then rm -rf xvidcore; fi
		wget -c http://downloads.xvid.org/downloads/xvidcore-1.3.2.tar.gz
		tar xf xvidcore-1.3.2.tar.gz
		rm xvidcore-1.3.2.tar.gz
		cd xvidcore/build/generic
		if [[ $bits = "64bit" ]]; then
			extra='--build=x86_64-unknown-linux-gnu --disable-assembly'
		fi
		./configure --host=$targetHost --prefix=$LOCALDESTDIR $extra
		sed -i "s/-mno-cygwin//" platform.inc
		make -j $cpuCount
		make install

		if [[ -f "$LOCALDESTDIR/lib/xvidcore.dll" ]]; then
			rm $LOCALDESTDIR/lib/xvidcore.dll || exit 1
			mv $LOCALDESTDIR/lib/xvidcore.a $LOCALDESTDIR/lib/libxvidcore.a || exit 1
		fi
		
		do_checkIfExist xvidcore libxvidcore.a
fi

cd $LOCALBUILDDIR

if [ -f "libvpx-git/configure" ]; then
	echo -ne "\033]0;compile libvpx $bits\007"
	cd libvpx-git
	oldHead=`git rev-parse HEAD`
	git pull origin master
	newHead=`git rev-parse HEAD`
	if [[ "$oldHead" != "$newHead" ]]; then
	if [ -d "$LOCALDESTDIR/include/vpx" ]; then rm -rf $LOCALDESTDIR/include/vpx; fi
	if [ -f "$LOCALDESTDIR/lib/pkgconfig/vpx.pc" ]; then rm $LOCALDESTDIR/lib/pkgconfig/vpx.pc; fi
	if [ -f "$LOCALDESTDIR/lib/libvpx.a" ]; then rm $LOCALDESTDIR/lib/libvpx.a; fi
		make clean
		if [[ $bits = "64bit" ]]; then
			./configure --target=x86_64-win64-gcc --prefix=$LOCALDESTDIR --disable-shared --enable-static --disable-unit-tests --disable-docs
			sed -i 's/HAVE_GNU_STRIP=yes/HAVE_GNU_STRIP=no/g' libs-x86_64-win64-gcc.mk
		else
			./configure --prefix=$LOCALDESTDIR --disable-shared --enable-static --disable-unit-tests --disable-docs
			sed -i 's/HAVE_GNU_STRIP=yes/HAVE_GNU_STRIP=no/g' libs-x86-win32-gcc.mk
		fi 
		grep -q -e '#if defined(_WIN32) || defined(_WIN64)' vpx/src/svc_encodeframe.c || sed -i '/#include "vpx\/vpx_encoder.h"/ a\#if defined(_WIN32) || defined(_WIN64)\
		#define strtok_r strtok_s\
		#endif' vpx/src/svc_encodeframe.c
        make -j $cpuCount
        make install
		cp vpxdec.exe $LOCALDESTDIR/bin/vpxdec.exe
		cp vpxenc.exe $LOCALDESTDIR/bin/vpxenc.exe
		
		do_checkIfExist libvpx-git vpxenc.exe
	else
		echo -------------------------------------------------
		echo "libvpx-git is already up to date"
		echo -------------------------------------------------
	fi
	else
		echo -ne "\033]0;compile libvpx $bits\007"
		git clone http://git.chromium.org/webm/libvpx.git libvpx-git
		cd libvpx-git
		if [[ $bits = "64bit" ]]; then
			./configure --target=x86_64-win64-gcc --prefix=$LOCALDESTDIR --disable-shared --enable-static --disable-unit-tests --disable-docs
			sed -i 's/HAVE_GNU_STRIP=yes/HAVE_GNU_STRIP=no/g' libs-x86_64-win64-gcc.mk
		else
			./configure --prefix=$LOCALDESTDIR --disable-shared --enable-static --disable-unit-tests --disable-docs
			sed -i 's/HAVE_GNU_STRIP=yes/HAVE_GNU_STRIP=no/g' libs-x86-win32-gcc.mk
		fi 
		grep -q -e '#if defined(_WIN32) || defined(_WIN64)' vpx/src/svc_encodeframe.c || sed -i '/#include "vpx\/vpx_encoder.h"/ a\#if defined(_WIN32) || defined(_WIN64)\
		#define strtok_r strtok_s\
		#endif' vpx/src/svc_encodeframe.c
		make -j $cpuCount
		make install
		cp vpxdec.exe $LOCALDESTDIR/bin/vpxdec.exe
		cp vpxenc.exe $LOCALDESTDIR/bin/vpxenc.exe
		
		do_checkIfExist libvpx-git vpxenc.exe
fi

cd $LOCALBUILDDIR
		
if [ -f "libbluray-git/bootstrap" ]; then
	echo -ne "\033]0;compile libbluray $bits\007"
	cd libbluray-git
	oldHead=`git rev-parse HEAD`
	git pull origin master
	newHead=`git rev-parse HEAD`
	if [[ "$oldHead" != "$newHead" ]]; then
		make uninstall
		make clean
		if [[ ! -f "configure" ]]; then
			./bootstrap
		fi
		./configure --host=$targetHost --prefix=$LOCALDESTDIR --disable-shared --enable-static
		make -j $cpuCount
		make install
		
		do_checkIfExist libbluray-git libbluray.a
	else
		echo -------------------------------------------------
		echo "libbluray is already up to date"
		echo -------------------------------------------------
	fi
	else
		echo -ne "\033]0;compile libbluray $bits\007"
		git clone git://git.videolan.org/libbluray.git libbluray-git
		cd libbluray-git
		./bootstrap
		./configure --host=$targetHost --prefix=$LOCALDESTDIR --disable-shared --enable-static
		make -j $cpuCount
		make install

		do_checkIfExist libbluray-git libbluray.a
fi

cd $LOCALBUILDDIR

if [ -f "libutvideo-git/configure" ]; then
	echo -ne "\033]0;compile libutvideo $bits\007"
	cd libutvideo-git
	oldHead=`git rev-parse HEAD`
	git pull origin master
	newHead=`git rev-parse HEAD`
	if [[ "$oldHead" != "$newHead" ]]; then
		make uninstall
		make clean
		./configure --prefix=$LOCALDESTDIR
		make -j $cpuCount
		make install
		
		do_checkIfExist libutvideo-git libutvideo.a
	else
		echo -------------------------------------------------
		echo "libutvideo is already up to date"
		echo -------------------------------------------------
	fi
else
	echo -ne "\033]0;compile libutvideo $bits\007"
	git clone git://github.com/qyot27/libutvideo.git libutvideo-git
	cd libutvideo-git
	./configure --prefix=$LOCALDESTDIR
	make -j $cpuCount
	make install
	
	do_checkIfExist libutvideo-git libutvideo.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libass.a" ]; then
	echo -------------------------------------------------
	echo "libass-0.10.2 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile libass $bits\007"
		if [ -d "libass-0.10.2" ]; then rm -rf libass-0.10.2; fi
		wget -c http://libass.googlecode.com/files/libass-0.10.2.tar.gz
		tar xf libass-0.10.2.tar.gz
		rm libass-0.10.2.tar.gz
		cd libass-0.10.2
		CPPFLAGS=' -DFRIBIDI_ENTRY="" ' ./configure --host=$targetHost --prefix=$LOCALDESTDIR --enable-shared=no
		make -j $cpuCount
		make install
		sed -i 's/-lass -lm/-lass -lfribidi -lm/' "$LOCALDESTDIR/lib/pkgconfig/libass.pc"
		
		do_checkIfExist libass-0.10.2 libass.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libxavs.a" ]; then
	echo -------------------------------------------------
	echo "xavs is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile xavs $bits\007"
		if [ -d "xavs" ]; then rm -rf xavs; fi
		svn checkout --trust-server-cert https://svn.code.sf.net/p/xavs/code/trunk/ xavs
		cd xavs
		./configure --host=$targetHost --prefix=$LOCALDESTDIR
		make -j $cpuCount
		make install
		
		do_checkIfExist xavs libxavs.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libdvdcss.a" ]; then
	echo -------------------------------------------------
	echo "libdvdcss-1.2.13 is already compiled"
	echo -------------------------------------------------
	else 
			echo -ne "\033]0;compile libdvdcss $bits\007"
			if [ -d "libdvdcss-1.2.13" ]; then rm -rf libdvdcss-1.2.13; fi
			wget -c http://download.videolan.org/pub/videolan/libdvdcss/1.2.13/libdvdcss-1.2.13.tar.bz2
			tar xf libdvdcss-1.2.13.tar.bz2
			rm libdvdcss-1.2.13.tar.bz2
			cd libdvdcss-1.2.13
			./configure --host=$targetHost --prefix=$LOCALDESTDIR --disable-shared
			make -j $cpuCount
			make install
			
			do_checkIfExist libdvdcss-1.2.13 libdvdcss.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libdvdread.a" ]; then
	echo -------------------------------------------------
	echo "libdvdread-4.2.1 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile libdvdread $bits\007"
		if [ -d "libdvdread-4.2.1" ]; then rm -rf libdvdread-4.2.1; fi
		wget -c http://dvdnav.mplayerhq.hu/releases/libdvdread-4.2.1-rc1.tar.xz
		tar xf libdvdread-4.2.1-rc1.tar.xz
		rm libdvdread-4.2.1-rc1.tar.xz
		cd libdvdread-4.2.1
		if [[ ! -f ./configure ]]; then
			./autogen.sh
		fi	
		./configure --host=$targetHost --prefix=$LOCALDESTDIR --disable-shared CFLAGS="$CFLAGS -DHAVE_DVDCSS_DVDCSS_H" LDFLAGS="$LDFLAGS -ldvdcss"
		sed -i 's/#define ATTRIBUTE_PACKED __attribute__ ((packed))/#define ATTRIBUTE_PACKED __attribute__ ((packed,gcc_struct))/' src/dvdread/ifo_types.h
		make -j $cpuCount
		make install
		sed -i "s/-ldvdread.*/-ldvdread -ldvdcss -ldl/" $LOCALDESTDIR/bin/dvdread-config
		sed -i 's/-ldvdread.*/-ldvdread -ldvdcss -ldl/' "$LOCALDESTDIR/lib/pkgconfig/dvdread.pc"
		
		do_checkIfExist libdvdread-4.2.1 libdvdread.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libdvdnav.a" ]; then
	echo -------------------------------------------------
	echo "libdvdnav-4.2.1 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile libdvdnav $bits\007"
		if [ -d "libdvdnav-4.2.1" ]; then rm -rf libdvdnav-4.2.1; fi
		wget -c http://dvdnav.mplayerhq.hu/releases/libdvdnav-4.2.1-rc1.tar.xz
		tar xf libdvdnav-4.2.1-rc1.tar.xz
		rm libdvdnav-4.2.1-rc1.tar.xz
		cd libdvdnav-4.2.1
		#cp -v /usr/share/aclocal/* m4/
		if [[ ! -f ./configure ]]; then
			./autogen.sh
		fi
		./configure --host=$targetHost --prefix=$LOCALDESTDIR --disable-shared --with-dvdread-config=$LOCALDESTDIR/bin/dvdread-config
		make -j $cpuCount
		make install
		sed -i "s/echo -L${exec_prefix}\/lib -ldvdnav -ldvdread/echo -L${exec_prefix}\/lib -ldvdnav -ldvdread -ldl/" $LOCALDESTDIR/bin/dvdnav-config
		
		do_checkIfExist libdvdread-4.2.1 libdvdnav.a
fi

if [[ $bits = "32bit" ]]; then
	cd $LOCALBUILDDIR

	if [ -f "$LOCALDESTDIR/bin/mediainfo.exe" ]; then
		echo -------------------------------------------------
		echo "MediaInfo_CLI is already compiled"
		echo -------------------------------------------------
		else
			echo -ne "\033]0;compile MediaInfo_CLI $bits\007"
			if [ -d "MediaInfo_CLI_GNU_FromSource" ]; then rm -rf MediaInfo_CLI_GNU_FromSource; fi
			wget -c http://mediaarea.net/download/binary/mediainfo/0.7.65/MediaInfo_CLI_0.7.65_GNU_FromSource.tar.bz2
			tar xf MediaInfo_CLI_0.7.65_GNU_FromSource.tar.bz2
			rm MediaInfo_CLI_0.7.65_GNU_FromSource.tar.bz2
			cd MediaInfo_CLI_GNU_FromSource
			
			sed -i '/#include <windows.h>/ a\#include <time.h>' ZenLib/Source/ZenLib/Ztring.cpp
			sed -i 's/make -s -j$numprocs/make -s -j $cpuCount/' CLI_Compile.sh
			sed -i 's/.\/configure --enable-staticlibs $\*/.\/configure --enable-staticlibs $* --enable-shared=no LDFLAGS="$LDFLAGS -static-libgcc"/' CLI_Compile.sh
			
			source CLI_Compile.sh
			cp MediaInfo/Project/GNU/CLI/mediainfo.exe $LOCALDESTDIR/bin/mediainfo.exe
			
			do_checkIfExist MediaInfo_CLI mediainfo.exe
	fi
fi

cd $LOCALBUILDDIR

if [ -f "vidstab-git/Makefile" ]; then
	echo -ne "\033]0;compile vidstab $bits\007"
	cd vidstab-git
	oldHead=`git rev-parse HEAD`
	git pull origin master
	newHead=`git rev-parse HEAD`
	if [[ "$oldHead" != "$newHead" ]]; then
		make uninstall
		make clean
		cmake -G "MSYS Makefiles" -DCMAKE_INSTALL_PREFIX=$LOCALDESTDIR
		sed -i "s/SHARED/STATIC/" CMakeLists.txt
		make -j $cpuCount
		make install
		
		do_checkIfExist vidstab-git libvidstab.a
	else
		echo -------------------------------------------------
		echo "vidstab is already up to date"
		echo -------------------------------------------------
	fi
	else
	echo -ne "\033]0;compile vidstab $bits\007"
		git clone https://github.com/georgmartius/vid.stab.git vidstab-git
		cd vidstab-git
		cmake -G "MSYS Makefiles" -DCMAKE_INSTALL_PREFIX=$LOCALDESTDIR
		 sed -i "s/SHARED/STATIC/" CMakeLists.txt
		make -j $cpuCount
		make install
		
		do_checkIfExist vidstab-git libvidstab.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libcaca.a" ]; then
	echo -------------------------------------------------
	echo "libcaca-0.99.beta18 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile libcaca $bits\007"
		if [ -d "libcaca-0.99.beta18" ]; then rm -rf libcaca-0.99.beta18; fi
		wget -c http://caca.zoy.org/files/libcaca/libcaca-0.99.beta18.tar.gz
		tar xf libcaca-0.99.beta18.tar.gz
		rm libcaca-0.99.beta18.tar.gz
		cd libcaca-0.99.beta18
		cd caca
		sed -i "s/__declspec(dllexport)//g" *.h
		sed -i "s/__declspec(dllimport)//g" *.h 
		cd ..
		./configure --host=$targetHost --prefix=$LOCALDESTDIR --disable-shared --disable-cxx --disable-csharp --disable-java --disable-python --disable-ruby --disable-imlib2 --disable-doc
		sed -i 's/ln -sf/$(LN_S)/' "caca/Makefile" "cxx/Makefile" "doc/Makefile"
		make -j $cpuCount
		make install
		
		do_checkIfExist libcaca-0.99.beta18 libcaca.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libmodplug.a" ]; then
	echo -------------------------------------------------
	echo "libmodplug-0.8.8.4 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile libmodplug $bits\007"
		if [ -d "libmodplug-0.8.8.4" ]; then rm -rf libmodplug-0.8.8.4; fi
		wget -c http://sourceforge.net/projects/modplug-xmms/files/libmodplug/0.8.8.4/libmodplug-0.8.8.4.tar.gz/download
		tar xf libmodplug-0.8.8.4.tar.gz
		rm libmodplug-0.8.8.4.tar.gz
		cd libmodplug-0.8.8.4
		./configure --host=$targetHost --prefix=$LOCALDESTDIR --disable-shared
		sed -i 's/-lmodplug.*/-lmodplug -lstdc++/' $LOCALDESTDIR/lib/pkgconfig/libmodplug.pc
		make -j $cpuCount
		make install
		
		do_checkIfExist libmodplug-0.8.8.4 libmodplug.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/liborc-0.4.a" ]; then
	echo -------------------------------------------------
	echo "orc-0.4.18 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile orc $bits\007"
		if [ -d "orc-0.4.18" ]; then rm -rf orc-0.4.18; fi
		wget -c http://code.entropywave.com/download/orc/orc-0.4.18.tar.gz
		tar xf orc-0.4.18.tar.gz
		rm orc-0.4.18.tar.gz
		cd orc-0.4.18
		./configure --host=$targetHost --prefix=$LOCALDESTDIR --disable-shared
		make -j $cpuCount
		make install
		
		do_checkIfExist orc-0.4.18 liborc-0.4.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libschroedinger-1.0.a" ]; then
	echo -------------------------------------------------
	echo "schroedinger-1.0.11 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile schroedinger $bits\007"
		if [ -d "schroedinger-1.0.11" ]; then rm -rf schroedinger-1.0.11; fi
		wget -c http://diracvideo.org/download/schroedinger/schroedinger-1.0.11.tar.gz
		tar xf schroedinger-1.0.11.tar.gz
		rm schroedinger-1.0.11.tar.gz
		cd schroedinger-1.0.11
		./configure --host=$targetHost --prefix=$LOCALDESTDIR --disable-shared
		sed -i 's/testsuite//' Makefile
		make -j $cpuCount
		make install
		sed -i 's/-lschroedinger-1.0$/-lschroedinger-1.0 -lorc-0.4/' "$LOCALDESTDIR/lib/pkgconfig/schroedinger-1.0.pc"
		
		do_checkIfExist schroedinger-1.0.11 libschroedinger-1.0.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libzvbi.a" ]; then
	echo -------------------------------------------------
	echo "zvbi-0.2.35 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile libmodplug $bits\007"
		if [ -d "zvbi-0.2.35" ]; then rm -rf zvbi-0.2.35; fi
		wget -c http://sourceforge.net/projects/zapping/files/zvbi/0.2.35/zvbi-0.2.35.tar.bz2/download
		tar xf zvbi-0.2.35.tar.bz2
		rm zvbi-0.2.35.tar.bz2
		cd zvbi-0.2.35
		wget --no-check-certificate -c https://raw.github.com/jb-alvarado/media-autobuild_suite/master/patches/zvbi-win32.patch
		wget --no-check-certificate -c https://raw.github.com/jb-alvarado/media-autobuild_suite/master/patches/zvbi-ioctl.patch
		patch -p0 < zvbi-win32.patch
		patch -p0 < zvbi-ioctl.patch
		./configure --host=$targetHost --prefix=$LOCALDESTDIR --disable-shared --disable-dvb --disable-bktr --disable-nls --disable-proxy --without-doxygen CFLAGS="$CFLAGS -DPTW32_STATIC_LIB" LIBS="$LIBS -lpng"
		cd src
		make -j $cpuCount
		make install
		cp ../zvbi-0.2.pc $LOCALDESTDIR/lib/pkgconfig
		
		do_checkIfExist zvbi-0.2.35 libzvbi.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/include/frei0r.h" ]; then
	echo -------------------------------------------------
	echo "frei0r is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile frei0r $bits\007"
		if [ -d "libmodplug-0.8.8.4" ]; then rm -rf libmodplug-0.8.8.4; fi
		wget --no-check-certificate -c -O frei0r-plugins-1.4.tar.gz https://files.dyne.org/.xsend.php?file=frei0r/releases/frei0r-plugins-1.4.tar.gz
		tar xf frei0r-plugins-1.4.tar.gz
		rm frei0r-plugins-1.4.tar.gz
		cd frei0r-plugins-1.4
		mkdir build
		cd build 
		cmake -G "MSYS Makefiles" -DCMAKE_INSTALL_PREFIX=$LOCALDESTDIR ..
		make -j $cpuCount all install
		
		do_checkIfExist frei0r-plugins-1.4 frei0r-1/xfade0r.dll
fi

#------------------------------------------------
# final tools
#------------------------------------------------

cd $LOCALBUILDDIR

if [[ $mp4box = "y" ]]; then
	if [ -f "mp4box-svn/configure" ]; then
		echo -ne "\033]0;compile mp4box-svn $bits\007"
		cd mp4box-svn
		oldRevision=`svnversion`
		svn update
		newRevision=`svnversion`
		if [[ "$oldRevision" != "$newRevision"  ]]; then
			rm $LOCALDESTDIR/bin/MP4Box.exe
			make clean
			./configure --host=$targetHost --static-mp4box --enable-static-bin --extra-libs="-lws2_32 -lwinmm -lz -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64" --use-ffmpeg=no --use-png=no
				cp config.h include/gpac/internal
				cd src
				make -j $cpuCount
				cd ..
				cd applications/mp4box
				make -j $cpuCount
				cd ../..
				cp bin/gcc/MP4Box.exe $LOCALDESTDIR/bin
				
				do_checkIfExist mp4box-svn MP4Box.exe
		else
			echo -------------------------------------------------
			echo "MP4Box is already up to date"
			echo -------------------------------------------------
		fi
	else
		echo -ne "\033]0;compile mp4box-svn $bits\007"
		svn checkout svn://svn.code.sf.net/p/gpac/code/trunk/gpac mp4box-svn
		cd mp4box-svn
		./configure --host=$targetHost --static-mp4box --enable-static-bin --extra-libs="-lws2_32 -lwinmm -lz -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64" --use-ffmpeg=no --use-png=no
		cp config.h include/gpac/internal
		cd src
		make -j $cpuCount
		cd ..
		cd applications/mp4box
		make -j $cpuCount
		cd ../..
		cp bin/gcc/MP4Box.exe $LOCALDESTDIR/bin
		
		do_checkIfExist mp4box-svn MP4Box.exe
	fi
fi

cd $LOCALBUILDDIR

if [[ $ffmpeg = "y" ]]; then
	if [[ $nonfree = "y" ]]; then
		extras="--enable-nonfree --enable-libfaac --enable-libfdk-aac"
	  else
		if  [[ $nonfree = "n" ]]; then
		  extras="" 
		fi
	fi
	
	echo "-------------------------------------------------------------------------------"
	echo "compile ffmpeg $bits"
	echo "-------------------------------------------------------------------------------"

	if [ -f "ffmpeg-git/configure" ]; then
		echo -ne "\033]0;compile ffmpeg $bits\007"
		cd ffmpeg-git
		oldHead=`git rev-parse HEAD`
		git pull origin master
		newHead=`git rev-parse HEAD`
		if [[ "$oldHead" != "$newHead" ]]; then
			make uninstall
			make clean
			
			if [[ $bits = "32bit" ]]; then
				arch='x86'
			else
				arch='x86_64'
			fi	
			
			./configure --arch=$arch --prefix=$LOCALDESTDIR --extra-cflags='-DPTW32_STATIC_LIB -DLIBTWOLAME_STATIC' --extra-libs='-lxml2 -lz -liconv -lws2_32 -lstdc++ -lpng -lm -lpthread -lwsock32' --disable-debug --enable-gpl --enable-version3 --enable-postproc --enable-w32threads --enable-runtime-cpudetect --enable-memalign-hack --disable-shared --enable-static --enable-avfilter --enable-bzlib --enable-zlib --enable-librtmp --enable-gnutls --enable-avisynth --enable-frei0r --enable-filter=frei0r --enable-libbluray --enable-libcaca --enable-libopenjpeg --enable-fontconfig --enable-libfreetype --enable-libass --enable-libgsm --enable-libmodplug --enable-libmp3lame --enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libvo-amrwbenc --enable-libschroedinger --enable-libsoxr --enable-libtwolame --enable-libutvideo --enable-libspeex --enable-libtheora --enable-libvorbis --enable-libvo-aacenc --enable-libopus --enable-libvidstab --enable-libvpx --enable-libxavs --enable-libx264 --enable-libxvid --enable-libzvbi $extras
			make -j $cpuCount
			make install
			
			do_checkIfExist ffmpeg-git ffmpeg.exe
		else
			echo -------------------------------------------------
			echo "ffmpeg is already up to date"
			echo -------------------------------------------------
		fi
		else
			echo -ne "\033]0;compile ffmpeg $bits\007"
			cd $LOCALBUILDDIR
			if [ -d "$LOCALDESTDIR/include/libavutil" ]; then rm -rf $LOCALDESTDIR/include/libavutil; fi
			if [ -d "$LOCALDESTDIR/include/libavcodec" ]; then rm -rf $LOCALDESTDIR/include/libavcodec; fi
			if [ -d "$LOCALDESTDIR/include/libpostproc" ]; then rm -rf $LOCALDESTDIR/include/libpostproc; fi
			if [ -d "$LOCALDESTDIR/include/libswresample" ]; then rm -rf $LOCALDESTDIR/include/libswresample; fi
			if [ -d "$LOCALDESTDIR/include/libswscale" ]; then rm -rf $LOCALDESTDIR/include/libswscale; fi
			if [ -d "$LOCALDESTDIR/include/libavdevice" ]; then rm -rf $LOCALDESTDIR/include/libavdevice; fi
			if [ -d "$LOCALDESTDIR/include/libavfilter" ]; then rm -rf $LOCALDESTDIR/include/libavfilter; fi
			if [ -d "$LOCALDESTDIR/include/libavformat" ]; then rm -rf $LOCALDESTDIR/include/libavformat; fi
			if [ -f "$LOCALDESTDIR/lib/libavutil.a" ]; then rm -rf $LOCALDESTDIR/lib/libavutil.a; fi
			if [ -f "$LOCALDESTDIR/lib/libswresample.a" ]; then rm -rf $LOCALDESTDIR/lib/libswresample.a; fi
			if [ -f "$LOCALDESTDIR/lib/libswscale.a" ]; then rm -rf $LOCALDESTDIR/lib/libswscale.a; fi
			if [ -f "$LOCALDESTDIR/lib/libavcodec.a" ]; then rm -rf $LOCALDESTDIR/lib/libavcodec.a; fi
			if [ -f "$LOCALDESTDIR/lib/libavdevice.a" ]; then rm -rf $LOCALDESTDIR/lib/libavdevice.a; fi
			if [ -f "$LOCALDESTDIR/lib/libavfilter.a" ]; then rm -rf $LOCALDESTDIR/lib/libavfilter.a; fi
			if [ -f "$LOCALDESTDIR/lib/libavformat.a" ]; then rm -rf $LOCALDESTDIR/lib/libavformat.a; fi
			if [ -f "$LOCALDESTDIR/lib/libpostproc.a" ]; then rm -rf $LOCALDESTDIR/lib/libpostproc.a; fi
			if [ -f "$LOCALDESTDIR/lib/pkgconfig/libavcodec.pc" ]; then rm -rf $LOCALDESTDIR/lib/pkgconfig/libavcodec.pc; fi
			if [ -f "$LOCALDESTDIR/lib/pkgconfig/libavutil.pc" ]; then rm -rf $LOCALDESTDIR/lib/pkgconfig/libavutil.pc; fi
			if [ -f "$LOCALDESTDIR/lib/pkgconfig/libpostproc.pc" ]; then rm -rf $LOCALDESTDIR/lib/pkgconfig/libpostproc.pc; fi
			if [ -f "$LOCALDESTDIR/lib/pkgconfig/libswresample.pc" ]; then rm -rf $LOCALDESTDIR/lib/pkgconfig/libswresample.pc; fi
			if [ -f "$LOCALDESTDIR/lib/pkgconfig/libswscale.pc" ]; then rm -rf $LOCALDESTDIR/lib/pkgconfig/libswscale.pc; fi
			if [ -f "$LOCALDESTDIR/lib/pkgconfig/libavdevice.pc" ]; then rm -rf $LOCALDESTDIR/lib/pkgconfig/libavdevice.pc; fi
			if [ -f "$LOCALDESTDIR/lib/pkgconfig/libavfilter.pc" ]; then rm -rf $LOCALDESTDIR/lib/pkgconfig/libavfilter.pc; fi
			if [ -f "$LOCALDESTDIR/lib/pkgconfig/libavformat.pc" ]; then rm -rf $LOCALDESTDIR/lib/pkgconfig/libavformat.pc; fi

			git clone https://github.com/FFmpeg/FFmpeg.git ffmpeg-git
			cd ffmpeg-git
			
			if [[ $bits = "32bit" ]]; then
				arch='x86'
			else
				arch='x86_64'
			fi	
			
			./configure --arch=$arch --prefix=$LOCALDESTDIR --extra-cflags='-DPTW32_STATIC_LIB -DLIBTWOLAME_STATIC' --extra-libs='-lxml2 -lz -liconv -lws2_32 -lstdc++ -lpng -lm -lpthread -lwsock32' --disable-debug --enable-gpl --enable-version3 --enable-postproc --enable-w32threads --enable-runtime-cpudetect --enable-memalign-hack --disable-shared --enable-static --enable-avfilter --enable-bzlib --enable-zlib --enable-librtmp --enable-gnutls --enable-avisynth --enable-frei0r --enable-filter=frei0r --enable-libbluray --enable-libcaca --enable-libopenjpeg --enable-fontconfig --enable-libfreetype --enable-libass --enable-libgsm --enable-libmodplug --enable-libmp3lame --enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libvo-amrwbenc --enable-libschroedinger --enable-libsoxr --enable-libtwolame --enable-libutvideo --enable-libspeex --enable-libtheora --enable-libvorbis --enable-libvo-aacenc --enable-libopus --enable-libvidstab --enable-libvpx --enable-libxavs --enable-libx264 --enable-libxvid --enable-libzvbi $extras
			make -j $cpuCount
			make install
			
			do_checkIfExist ffmpeg-git ffmpeg.exe
	fi
fi

cd $LOCALBUILDDIR

if [[ $nonfree = "y" ]]; then
    faac=""
  elif [[ $nonfree = "n" ]]; then
      faac="--disable-faac --disable-faac-lavc" 
fi	

if [[ $mplayer = "y" ]]; then

if [ -f "mplayer-svn/configure" ]; then
		echo -ne "\033]0;compile mplayer $bits\007"
		cd mplayer-svn
		oldRevision=`svnversion`
		svn update
		newRevision=`svnversion`
		
		if [ -d "ffmpeg" ]; then 
			cd ffmpeg 
			oldHead=`git rev-parse HEAD`
			git pull origin master
			newHead=`git rev-parse HEAD`
			cd ..
		fi	
		
		if [[ "$oldRevision" != "$newRevision"  ]] || [[ "$oldHead" != "$newHead"  ]] || [ ! -d "ffmpeg" ]; then
			make uninstall
			make clean
			
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
			./configure --prefix=$LOCALDESTDIR --extra-cflags='-DPTW32_STATIC_LIB -O3 -std=gnu99' --extra-libs='-lxml2 -lfreetype -lz -liconv -lws2_32' --enable-static --enable-runtime-cpudetection --enable-ass-internal --enable-bluray --with-dvdnav-config=$LOCALDESTDIR/bin/dvdnav-config --with-dvdread-config=$LOCALDESTDIR/bin/dvdread-config --disable-dvdread-internal --disable-libdvdcss-internal $faac
			make
			make install

			do_checkIfExist mplayer-svn mplayer.exe
			
			else
			echo -------------------------------------------------
			echo "mplayer is already up to date"
			echo -------------------------------------------------
		fi
		else
			echo -ne "\033]0;compile mplayer $bits\007"
			
			svn checkout svn://svn.mplayerhq.hu/mplayer/trunk mplayer-svn
			cd mplayer-svn
			
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
			./configure --prefix=$LOCALDESTDIR --extra-cflags='-DPTW32_STATIC_LIB -O3 -std=gnu99' --extra-libs='-lxml2 -lfreetype -lz -liconv -lws2_32' --enable-static --enable-runtime-cpudetection --enable-ass-internal --enable-bluray --with-dvdnav-config=$LOCALDESTDIR/bin/dvdnav-config --with-dvdread-config=$LOCALDESTDIR/bin/dvdread-config --disable-dvdread-internal --disable-libdvdcss-internal $faac
			make
			make install

			do_checkIfExist mplayer-svn mplayer.exe
	fi
fi

}

if [[ $build32 = "yes" ]]; then
	echo "-------------------------------------------------------------------------------"
	echo
	echo "compile video tools 32 bit"
	echo
	echo "-------------------------------------------------------------------------------"
	source /global32/etc/profile.local
	bits='32bit'
	targetHost='i686-w64-mingw32'
	buildProcess
	echo "-------------------------------------------------------------------------------"
	echo "compile video tools 32 bit done..."
	echo "-------------------------------------------------------------------------------"
	sleep 3
fi

if [[ $build64 = "yes" ]]; then
	echo "-------------------------------------------------------------------------------"
	echo
	echo "compile video tools 64 bit"
	echo
	echo "-------------------------------------------------------------------------------"
	source /global64/etc/profile.local
	bits='64bit'
	targetHost='x86_64-pc-mingw32'
	buildProcess
	echo "-------------------------------------------------------------------------------"
	echo "compile video tools 64 bit done..."
	echo "-------------------------------------------------------------------------------"
	sleep 3
fi

sleep 5
