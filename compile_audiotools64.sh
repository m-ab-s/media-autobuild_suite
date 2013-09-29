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
echo "compile SDL 64 bit"
echo "-------------------------------------------------------------------------------"

cd $LOCALBUILDDIR

if [ -f "SDL-1.2.15/compile.done" ]; then
	echo ----------------------------------
	echo "SDL-1.2.15 is already compiled"
	echo ----------------------------------
	else 
		wget -c http://www.libsdl.org/release/SDL-1.2.15.tar.gz
		tar xf SDL-1.2.15.tar.gz
		cd SDL-1.2.15
		./configure --host=x86_64-pc-mingw32 --prefix=$LOCALDESTDIR --enable-shared=no
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		cd $LOCALBUILDDIR
		rm SDL-1.2.15.tar.gz
		sed -i "s/-mwindows//" "/local64/bin/sdl-config"
		sed -i "s/-mwindows//" "/local64/lib/pkgconfig/sdl.pc"
fi

echo "-------------------------------------------------------------------------------"
echo
echo "compile audio tools 64 bit"
echo
echo "-------------------------------------------------------------------------------"

if [ -f "gsm-1.0.13/compile.done" ]; then
	echo ----------------------------------
	echo "gsm-1.0.13 is already compiled"
	echo ----------------------------------
	else 
		wget -c http://www.imagemagick.org/download/delegates/ffmpeg/gsm-1.0.13.tar.bz2
		tar xf gsm-1.0.13.tar.bz2
		cd gsm-1.0.13
		make -j $cpuCount
		mkdir $LOCALDESTDIR/include/gsm
		cp inc/gsm.h  $LOCALDESTDIR/include/gsm
		cp lib/libgsm.a $LOCALDESTDIR/lib
		echo "finish" > compile.done
		cd $LOCALBUILDDIR
		rm gsm-1.0.13.tar.bz2
fi

if [ -f "libogg-1.3.1/compile.done" ]; then
	echo ----------------------------------
	echo "libogg-1.3.1 is already compiled"
	echo ----------------------------------
	else 
		wget -c http://downloads.xiph.org/releases/ogg/libogg-1.3.1.tar.gz
		tar xf libogg-1.3.1.tar.gz
		cd libogg-1.3.1
		./configure --prefix=$LOCALDESTDIR --enable-shared=no
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		cd $LOCALBUILDDIR
		rm libogg-1.3.1.tar.gz
fi

if [ -f "libvorbis-1.3.3/compile.done" ]; then
	echo ----------------------------------
	echo "libvorbis-1.3.3 is already compiled"
	echo ----------------------------------
	else 
		wget -c http://downloads.xiph.org/releases/vorbis/libvorbis-1.3.3.tar.xz
		tar xf libvorbis-1.3.3.tar.xz
		cd libvorbis-1.3.3
		./configure --prefix=$LOCALDESTDIR --enable-shared=no
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		cd $LOCALBUILDDIR
		rm libvorbis-1.3.3.tar.xz
fi

if [ -f "libtheora-1.1.1/compile.done" ]; then
	echo ----------------------------------
	echo "libtheora-1.1.1 is already compiled"
	echo ----------------------------------
	else 
		wget -c http://downloads.xiph.org/releases/theora/libtheora-1.1.1.tar.bz2
		tar xf libtheora-1.1.1.tar.bz2
		cd libtheora-1.1.1
		./configure --prefix=$LOCALDESTDIR --enable-shared=no
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		cd $LOCALBUILDDIR
		rm libtheora-1.1.1.tar.bz2
fi

if [ -f "speex-1.2rc1/compile.done" ]; then
	echo ----------------------------------
	echo "speex-1.2rc1 is already compiled"
	echo ----------------------------------
	else 
		wget -c http://downloads.xiph.org/releases/speex/speex-1.2rc1.tar.gz
		tar xf speex-1.2rc1.tar.gz
		cd speex-1.2rc1
		./configure --prefix=$LOCALDESTDIR --enable-shared=no 
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		cd $LOCALBUILDDIR
		rm speex-1.2rc1.tar.gz
fi

if [ -f "flac-1.3.0/compile.done" ]; then
	echo ----------------------------------
	echo "flac-1.3.0 is already compiled"
	echo ----------------------------------
	else 
		wget -c http://downloads.xiph.org/releases/flac/flac-1.3.0.tar.xz
		tar xf flac-1.3.0.tar.xz
		cd flac-1.3.0
		./configure --build=x86_64-w64-mingw32 --prefix=$LOCALDESTDIR --disable-xmms-plugin --enable-shared=no --enable-static
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		cd $LOCALBUILDDIR
		rm flac-1.3.0.tar.xz
fi

if [ -f "lame-3.99.5/compile.done" ]; then
	echo ----------------------------------
	echo "lame-3.99.5 is already compiled"
	echo ----------------------------------
	else 
		wget -c -O lame-3.99.5.tar.gz http://sourceforge.net/projects/lame/files/lame/3.99/lame-3.99.5.tar.gz/download 
		tar xf lame-3.99.5.tar.gz
		cd lame-3.99.5
		./configure --host=x86_64-pc-mingw32 --prefix=$LOCALDESTDIR --enable-expopt=full --enable-shared=no
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		cd $LOCALBUILDDIR
		rm lame-3.99.5.tar.gz
fi

if [ -f "bin-fdk-aac/compile.done" ]; then
	echo ----------------------------------
	echo "bin-fdk-aac is already compiled"
	echo ----------------------------------
	else 
		cd $LOCALBUILDDIR
		
		wget --no-check-certificate -c https://github.com/nu774/fdkaac_autobuild/archive/master.zip -O patch-fdk-aac.zip
		unzip patch-fdk-aac.zip
		mv fdkaac_autobuild-master patch-fdk-aac
		
		wget --no-check-certificate -c https://github.com/mstorsjo/fdk-aac/archive/master.zip -O lib-fdk-aac.zip 
		unzip lib-fdk-aac.zip
		mv fdk-aac-master lib-fdk-aac
		cp patch-fdk-aac/files/LibMakefile lib-fdk-aac/Makefile
		cp patch-fdk-aac/files/libfdk-aac.version lib-fdk-aac/libfdk-aac.version
		sed -i 's/PREFIX=\/mingw/PREFIX=\/local64/g' lib-fdk-aac/Makefile
		sed -i 's/cd stage && zip -r $(PREFIX)\/libfdk-aac-win32-bin.zip \* \& cd \.\.//g' lib-fdk-aac/Makefile
		cd lib-fdk-aac
		make install

		cp lib-fdk-aac.a $LOCALDESTDIR/lib/lib-fdk-aac.a
		cp lib-fdk-aac.dll.a $LOCALDESTDIR/lib/lib-fdk-aac.dll.a

		cd $LOCALBUILDDIR
		wget --no-check-certificate -c https://github.com/nu774/fdkaac/archive/master.zip -O bin-fdk-aac.zip 
		unzip bin-fdk-aac.zip
		mv fdkaac-master bin-fdk-aac
		cp  patch-fdk-aac/files/AppMakefile bin-fdk-aac/Makefile
		cp  patch-fdk-aac/files/config.h bin-fdk-aac/config.h
		sed -i 's/PREFIX=\/mingw/PREFIX=\/local64/g' bin-fdk-aac/Makefile
		sed -i 's/-DHAVE_CONFIG_H -I\./-DHAVE_CONFIG_H -I\. -I$(PREFIX)\/include/g' bin-fdk-aac/Makefile
		sed -i 's/$(CC) -o$@ $(OBJS) -static -lfdk-aac/$(CC) -o$@ $(OBJS) -L$(PREFIX)\/lib -static -lfdk-aac/g' bin-fdk-aac/Makefile
		cd bin-fdk-aac
		make install
		echo "finish" > compile.done
		cd $LOCALBUILDDIR
		rm patch-fdk-aac.zip
		rm lib-fdk-aac.zip
		rm bin-fdk-aac.zip 

		
cat > /local64/lib/pkgconfig/fdk-aac.pc << "EOF"
prefix=/local64
exec_prefix=/local64
libdir=/local64/lib
includedir=/local64/include

Name: Fraunhofer FDK AAC Codec Library
Description: AAC codec library
Version: 0.3.0
Libs: -L${libdir} -lfdk-aac
Libs.private: -lm
Cflags: -I${includedir}

EOF
fi