source /local64/etc/profile.local

# set CPU count global. This can be overwrite from the compiler script (media-autobuild_suite.bat)
cpuCount=1
while true; do
  case $1 in
--cpuCount=* ) cpuCount="${1#*=}"; shift ;;
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
			else
				echo -------------------------------------------------
				echo "build $packetName failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi	
	elif [[ "$fileExtension" = "a" ]]; then
		if [ -f "$LOCALDESTDIR/lib/$fileName" ]; then
			echo -
			echo -------------------------------------------------
			echo "build $packetName done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build $packetName failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi	
	fi
}

cd $LOCALBUILDDIR

echo "-------------------------------------------------------------------------------"
echo
echo "compile audio tools 64 bit"
echo
echo "-------------------------------------------------------------------------------"

if [ -f "$LOCALDESTDIR/lib/libgsm.a" ]; then
	echo -------------------------------------------------
	echo "gsm-1.0.13 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile gsm 64Bit\007"
		wget -c http://www.imagemagick.org/download/delegates/ffmpeg/gsm-1.0.13.tar.bz2
		tar xf gsm-1.0.13.tar.bz2
		rm gsm-1.0.13.tar.bz2
		cd gsm-1.0.13
		make -j $cpuCount
		mkdir $LOCALDESTDIR/include/gsm
		cp inc/gsm.h  $LOCALDESTDIR/include/gsm
		cp lib/libgsm.a $LOCALDESTDIR/lib
		
		do_checkIfExist gsm-1.0.13 libgsm.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libogg.a" ]; then
	echo -------------------------------------------------
	echo "libogg-1.3.1 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile libogg 64Bit\007"
		wget -c http://downloads.xiph.org/releases/ogg/libogg-1.3.1.tar.gz
		tar xf libogg-1.3.1.tar.gz
		rm libogg-1.3.1.tar.gz
		cd libogg-1.3.1
		./configure --prefix=$LOCALDESTDIR --enable-shared=no
		make -j $cpuCount
		make install
		
		do_checkIfExist libogg-1.3.1 libogg.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libvorbis.a" ]; then
	echo -------------------------------------------------
	echo "libvorbis-1.3.3 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile libvorbis 64Bit\007"
		wget -c http://downloads.xiph.org/releases/vorbis/libvorbis-1.3.3.tar.xz
		tar xf libvorbis-1.3.3.tar.xz
		rm libvorbis-1.3.3.tar.xz
		cd libvorbis-1.3.3
		./configure --prefix=$LOCALDESTDIR --enable-shared=no
		make -j $cpuCount
		make install
		
		do_checkIfExist libvorbis-1.3.3 libvorbis.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libtheora.a" ]; then
	echo -------------------------------------------------
	echo "libtheora-1.1.1 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile libtheora 64Bit\007"
		wget -c http://downloads.xiph.org/releases/theora/libtheora-1.1.1.tar.bz2
		tar xf libtheora-1.1.1.tar.bz2
		rm libtheora-1.1.1.tar.bz2
		cd libtheora-1.1.1
		./configure --prefix=$LOCALDESTDIR --enable-shared=no
		make -j $cpuCount
		make install
		
		do_checkIfExist libtheora-1.1.1 libtheora.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libspeex.a" ]; then
	echo -------------------------------------------------
	echo "speex-1.2rc1 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile speex 64Bit\007"
		wget -c http://downloads.xiph.org/releases/speex/speex-1.2rc1.tar.gz
		tar xf speex-1.2rc1.tar.gz
		rm speex-1.2rc1.tar.gz
		cd speex-1.2rc1
		./configure --prefix=$LOCALDESTDIR --enable-shared=no 
		make -j $cpuCount
		make install
		
		do_checkIfExist speex-1.2rc1 libspeex.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libFLAC.a" ]; then
	echo -------------------------------------------------
	echo "flac-1.3.0 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile flac 64Bit\007"
		wget -c http://downloads.xiph.org/releases/flac/flac-1.3.0.tar.xz
		tar xf flac-1.3.0.tar.xz
		rm flac-1.3.0.tar.xz
		cd flac-1.3.0
		./configure --build=x86_64-w64-mingw32 --prefix=$LOCALDESTDIR --disable-xmms-plugin --enable-shared=no --enable-static
		make -j $cpuCount
		make install
		
		do_checkIfExist flac-1.3.0 libFLAC.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/bin/lame.exe" ]; then
	echo -------------------------------------------------
	echo "lame-3.99.5 is already compiled"
	echo -------------------------------------------------
	else
		echo -ne "\033]0;compile lame 64Bit\007"
		wget -c -O lame-3.99.5.tar.gz http://sourceforge.net/projects/lame/files/lame/3.99/lame-3.99.5.tar.gz/download 
		tar xf lame-3.99.5.tar.gz
		rm lame-3.99.5.tar.gz
		cd lame-3.99.5
		./configure --host=x86_64-pc-mingw32 --prefix=$LOCALDESTDIR --enable-expopt=full --enable-shared=no
		make -j $cpuCount
		make install
		
		do_checkIfExist lame-3.99.5 lame.exe
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libvo-aacenc.a" ]; then
	echo -------------------------------------------------
	echo "vo-aacenc-0.1.3 is already compiled"
	echo -------------------------------------------------
	else
		echo -ne "\033]0;compile vo-aacenc 64Bit\007"
		wget -c http://downloads.sourceforge.net/project/opencore-amr/vo-aacenc/vo-aacenc-0.1.3.tar.gz
		tar xf vo-aacenc-0.1.3.tar.gz
		rm vo-aacenc-0.1.3.tar.gz
		cd vo-aacenc-0.1.3
		./configure --host=x86_64-pc-mingw32 --prefix=$LOCALDESTDIR --enable-shared=no
		make -j $cpuCount
		make install
		
		do_checkIfExist vo-aacenc-0.1.3 libvo-aacenc.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libopencore-amrnb.a" ]; then
	echo -------------------------------------------------
	echo "opencore-amr-0.1.3 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile opencore-amr 64Bit\007"
		wget -c http://downloads.sourceforge.net/project/opencore-amr/opencore-amr/opencore-amr-0.1.3.tar.gz
		tar xf opencore-amr-0.1.3.tar.gz
		rm opencore-amr-0.1.3.tar.gz
		cd opencore-amr-0.1.3
		./configure --host=x86_64-pc-mingw32 --prefix=$LOCALDESTDIR --enable-shared=no
		make -j $cpuCount
		make install
		
		do_checkIfExist opencore-amr-0.1.3 libopencore-amrnb.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libvo-amrwbenc.a" ]; then
	echo -------------------------------------------------
	echo "vo-amrwbenc-0.1.2 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile vo-amrwbenc 64Bit\007"
		wget -c http://downloads.sourceforge.net/project/opencore-amr/vo-amrwbenc/vo-amrwbenc-0.1.2.tar.gz
		tar xf vo-amrwbenc-0.1.2.tar.gz
		rm vo-amrwbenc-0.1.2.tar.gz
		cd vo-amrwbenc-0.1.2
		./configure --host=x86_64-pc-mingw32 --prefix=$LOCALDESTDIR --enable-shared=no
		make -j $cpuCount
		make install
		
		do_checkIfExist vo-amrwbenc-0.1.2 libvo-amrwbenc.a
fi

cd $LOCALBUILDDIR

if [[ $nonfree = "y" ]]; then
if [ -f "$LOCALDESTDIR/bin/fdkaac.exe" ]; then
	echo -------------------------------------------------
	echo "bin-fdk-aac is already compiled"
	echo -------------------------------------------------
	else
		echo -ne "\033]0;compile fdk-aac 64Bit\007"
		wget --no-check-certificate -c https://github.com/nu774/fdkaac_autobuild/archive/master.zip -O patch-fdk-aac.zip
		unzip patch-fdk-aac.zip
		rm patch-fdk-aac.zip
		mv fdkaac_autobuild-master patch-fdk-aac
		
		wget --no-check-certificate -c https://github.com/mstorsjo/fdk-aac/archive/master.zip -O lib-fdk-aac.zip 
		unzip lib-fdk-aac.zip
		rm lib-fdk-aac.zip
		mv fdk-aac-master lib-fdk-aac
		cp patch-fdk-aac/files/LibMakefile lib-fdk-aac/Makefile
		cp patch-fdk-aac/files/libfdk-aac.version lib-fdk-aac/libfdk-aac.version
		sed -i 's/PREFIX=\/mingw/PREFIX=\/local64/g' lib-fdk-aac/Makefile
		sed -i 's/cd stage && zip -r $(PREFIX)\/libfdk-aac-win32-bin.zip \* \& cd \.\.//g' lib-fdk-aac/Makefile
		cd lib-fdk-aac
		make install

		cp lib-fdk-aac.a $LOCALDESTDIR/lib/lib-fdk-aac.a

		cd $LOCALBUILDDIR
		wget --no-check-certificate -c https://github.com/nu774/fdkaac/archive/master.zip -O bin-fdk-aac.zip 
		unzip bin-fdk-aac.zip
		rm bin-fdk-aac.zip 
		mv fdkaac-master bin-fdk-aac
		cp  patch-fdk-aac/files/AppMakefile bin-fdk-aac/Makefile
		cp  patch-fdk-aac/files/config.h bin-fdk-aac/config.h
		sed -i 's/PREFIX=\/mingw/PREFIX=\/local64/g' bin-fdk-aac/Makefile
		sed -i 's/-DHAVE_CONFIG_H -I\./-DHAVE_CONFIG_H -I\. -I$(PREFIX)\/include/g' bin-fdk-aac/Makefile
		sed -i 's/$(CC) -o$@ $(OBJS) -static -lfdk-aac/$(CC) -o$@ $(OBJS) -L$(PREFIX)\/lib -static -lfdk-aac/g' bin-fdk-aac/Makefile
		cd bin-fdk-aac
		make install
		rm $LOCALDESTDIR/bin/libfdk-aac-0.dll
		rm $LOCALDESTDIR/lib/libfdk-aac.dll.a
		
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

	do_checkIfExist fdk-aac fdkaac.exe
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/bin/faac.exe" ]; then
	echo -------------------------------------------------
	echo "faac-1.28 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile faac 64Bit\007"
		wget -c http://downloads.sourceforge.net/faac/faac-1.28.tar.gz
		tar xf faac-1.28.tar.gz
		rm faac-1.28.tar.gz
		cd faac-1.28
		sh bootstrap 
		./configure --host=x86_64-pc-mingw32 --prefix=$LOCALDESTDIR --enable-shared=no --without-mp4v2
		make -j $cpuCount
		make install
		
		rm faac-1.28.tar.gz
fi
fi # nonfree end

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libopus.a" ]; then
    echo -------------------------------------------------
    echo "opus-1.0.3 is already compiled"
    echo -------------------------------------------------
    else 
		echo -ne "\033]0;compile opus 64Bit\007"
      wget -c http://downloads.xiph.org/releases/opus/opus-1.0.3.tar.gz
		tar xf opus-1.0.3.tar.gz
		rm opus-1.0.3.tar.gz
		cd opus-1.0.3
        ./configure --host=x86_64-pc-mingw32 --prefix=$LOCALDESTDIR --enable-shared=no --enable-static --disable-doc
        make -j $cpuCount
        make install

		do_checkIfExist opus-1.0.3 libopus.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/bin/opusenc.exe" ]; then
    echo -------------------------------------------------
    echo "opus-tools-0.1.7 is already compiled"
    echo -------------------------------------------------
    else 
		echo -ne "\033]0;compile opus-tools 64Bit\007"
		wget --no-check-certificate -c https://ftp.mozilla.org/pub/mozilla.org/opus/opus-tools-0.1.7.tar.gz
		tar xf opus-tools-0.1.7.tar.gz
		rm opus-tools-0.1.7.tar.gz
		cd opus-tools-0.1.7
        ./configure --host=x86_64-pc-mingw32 --prefix=$LOCALDESTDIR LDFLAGS="-L$LOCALDESTDIR/lib -static -static-libgcc -static-libstdc++"
        make -j $cpuCount
        make install
        
		do_checkIfExist opus-tools-0.1.7 opusenc.exe
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/liba52.a" ]; then
	echo -------------------------------------------------
	echo "a52dec-0.7.4 is already compiled"
	echo -------------------------------------------------
	else 
	echo -ne "\033]0;compile a52dec 64Bit\007"
		wget -c "http://liba52.sourceforge.net/files/a52dec-0.7.4.tar.gz"
		tar xf a52dec-0.7.4.tar.gz
		rm a52dec-0.7.4.tar.gz
		cd a52dec-0.7.4
		./configure --host=x86_64-pc-mingw32 --prefix=$LOCALDESTDIR --disable-shared
		make -j $cpuCount
		make install
		
		do_checkIfExist a52dec-0.7.4 liba52.a
fi

cd $LOCALBUILDDIR
		
if [ -f "$LOCALDESTDIR/lib/libmad.a" ]; then
	echo -------------------------------------------------
	echo "libmad-0.15.1b is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile libmad 64Bit\007"
		wget -c "ftp://ftp.mars.org/pub/mpeg/libmad-0.15.1b.tar.gz"
		tar xf libmad-0.15.1b.tar.gz
		rm libmad-0.15.1b.tar.gz
		cd libmad-0.15.1b
		./configure --host=x86_64-pc-mingw32 --prefix=$LOCALDESTDIR --disable-shared --enable-fpm=intel --disable-debugging
		make -j $cpuCount
		make install
		
		do_checkIfExist libmad-0.15.1b libmad.a
fi

cd $LOCALBUILDDIR
		
if [ -f "$LOCALDESTDIR/lib/libsoxr.a" ]; then
	echo -------------------------------------------------
	echo "soxr-0.1.1 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile soxr-0.1.1 64Bit\007"
		if [ -d "soxr-0.1.1-Source" ]; then rm -r soxr-0.1.1-Source; fi
		wget -c "http://sourceforge.net/projects/soxr/files/soxr-0.1.1-Source.tar.xz"
		tar xf soxr-0.1.1-Source.tar.xz
		rm soxr-0.1.1-Source.tar.xz
		cd soxr-0.1.1-Source
		cmake -G "MSYS Makefiles" -DCMAKE_INSTALL_PREFIX=$LOCALDESTDIR -DHAVE_WORDS_BIGENDIAN_EXITCODE=0 -DBUILD_SHARED_LIBS:bool=off -DBUILD_TESTS:BOOL=OFF -DWITH_OPENMP:BOOL=OFF
		make -j $cpuCount
		make install
		
		do_checkIfExist soxr-0.1.1-Source libsoxr.a
fi

cd $LOCALBUILDDIR
		
if [ -f "$LOCALDESTDIR/lib/libtwolame.a" ]; then
	echo -------------------------------------------------
	echo "twolame-0.3.13 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile twolame 64Bit\007"
		if [ -d "twolame-0.3.13" ]; then rm -r twolame-0.3.13; fi
		wget -c http://sourceforge.net/projects/twolame/files/twolame/0.3.13/twolame-0.3.13.tar.gz/download
		tar xf twolame-0.3.13.tar.gz
		rm twolame-0.3.13.tar.gz
		cd twolame-0.3.13
		./configure --host=x86_64-pc-mingw32 --prefix=$LOCALDESTDIR --disable-shared CPPFLAGS="$CPPFLAGS -DLIBTWOLAME_STATIC"
		make -j $cpuCount
		make install
		
		do_checkIfExist twolame-0.3.13 libtwolame.a
fi

sleep 3