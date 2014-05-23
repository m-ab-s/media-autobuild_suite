# set CPU count global. This can be overwrite from the compiler script (media-autobuild_suite.bat)
cpuCount=1
compile="false"
buildFFmpeg="false"
x264Bin="no"
newFfmpeg="no"
while true; do
  case $1 in
--cpuCount=* ) cpuCount="${1#*=}"; shift ;;
--build32=* ) build32="${1#*=}"; shift ;;
--build64=* ) build64="${1#*=}"; shift ;;
--mp4box=* ) mp4box="${1#*=}"; shift ;;
--ffmpeg=* ) ffmpeg="${1#*=}"; shift ;;
--ffmpegUpdate=* ) ffmpegUpdate="${1#*=}"; shift ;;
--mplayer=* ) mplayer="${1#*=}"; shift ;;
--deleteSource=* ) deleteSource="${1#*=}"; shift ;;
--nonfree=* ) nonfree="${1#*=}"; shift ;;
    -- ) shift; break ;;
    -* ) echo "Error, unknown option: '$1'."; exit 1 ;;
    * ) break ;;
  esac
done

# get git clone, or update
do_git() {
local gitURL="$1"
local gitFolder="$2"
echo -ne "\033]0;compile $gitFolder $bits\007"
if [ ! -d $gitFolder ]; then
	git clone --depth 1 $gitURL $gitFolder
	if [ ! -d $gitFolder ]; then
		git clone $gitURL $gitFolder
	fi
	compile="true"
	cd $gitFolder
else 	
	cd $gitFolder
	oldHead=`git rev-parse HEAD`
	git pull origin master
	newHead=`git rev-parse HEAD`
	
	if [[ "$oldHead" != "$newHead" ]]; then 
		compile="true"
	fi
fi
}

# get svn checkout, or update
do_svn() {
local svnURL="$1"
local svnFolder="$2"
echo -ne "\033]0;compile $svnFolder $bits\007"
if [ ! -d $svnFolder ]; then
	svn checkout $svnURL $svnFolder
	compile="true"
	cd $svnFolder
else 	
	cd $svnFolder
	oldRevision=`svnversion`
	svn update
	newRevision=`svnversion`
	
	if [[ "$oldRevision" != "$newRevision" ]]; then 
		compile="true"
	fi
fi
}

# get hg clone, or update
do_hg() {
local hgURL="$1"
local hgFolder="$2"
echo -ne "\033]0;compile $hgFolder $bits\007"
if [ ! -d $hgFolder ]; then
	hg clone $hgURL $hgFolder
	compile="true"
	cd $hgFolder
else 	
	cd $hgFolder
	oldHead=`hg id --id`
	hg pull
	hg update
	newHead=`hg id --id`
	
	if [[ "$oldHead" != "$newHead" ]]; then 
		compile="true"
	fi
fi
}
	
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
echo "-------------------------------------------------------------------------------"
echo
echo "compile audio tools $bits"
echo
echo "-------------------------------------------------------------------------------"

if [ -f "$LOCALDESTDIR/lib/libtheora.a" ]; then
	echo -------------------------------------------------
	echo "libtheora-1.1.1 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile libtheora $bits\007"
		if [ -d "libtheora-1.1.1" ]; then rm -rf libtheora-1.1.1; fi
		wget --tries=20 --retry-connrefused --waitretry=2 -c http://downloads.xiph.org/releases/theora/libtheora-1.1.1.tar.bz2
		tar xf libtheora-1.1.1.tar.bz2
		rm libtheora-1.1.1.tar.bz2
		cd libtheora-1.1.1
		./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --enable-shared=no
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
		echo -ne "\033]0;compile speex $bits\007"
		if [ -d "speex-1.2rc1" ]; then rm -rf speex-1.2rc1; fi
		wget --tries=20 --retry-connrefused --waitretry=2 -c http://downloads.xiph.org/releases/speex/speex-1.2rc1.tar.gz
		tar xf speex-1.2rc1.tar.gz
		rm speex-1.2rc1.tar.gz
		cd speex-1.2rc1
		./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --enable-shared=no 
		make -j $cpuCount
		make install
		
		do_checkIfExist speex-1.2rc1 libspeex.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/bin/flac.exe" ]; then
	echo -------------------------------------------------
	echo "flac-1.3.0 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile flac $bits\007"
		if [ -d "flac-1.3.0" ]; then rm -rf flac-1.3.0; fi
		wget --tries=20 --retry-connrefused --waitretry=2 -c http://downloads.xiph.org/releases/flac/flac-1.3.0.tar.xz
		tar xf flac-1.3.0.tar.xz
		rm flac-1.3.0.tar.xz
		cd flac-1.3.0
		./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --disable-xmms-plugin --disable-doxygen-docs --enable-shared=no --enable-static
		make -j $cpuCount
		make install
		
		do_checkIfExist flac-1.3.0 flac.exe
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libvo-aacenc.a" ]; then
	echo -------------------------------------------------
	echo "vo-aacenc-0.1.3 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile vo-aacenc $bits\007"
		if [ -d "vo-aacenc-0.1.3" ]; then rm -rf vo-aacenc-0.1.3; fi
		wget --tries=20 --retry-connrefused --waitretry=2 -c http://downloads.sourceforge.net/project/opencore-amr/vo-aacenc/vo-aacenc-0.1.3.tar.gz
		tar xf vo-aacenc-0.1.3.tar.gz
		rm vo-aacenc-0.1.3.tar.gz
		cd vo-aacenc-0.1.3
		./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --enable-shared=no
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
		echo -ne "\033]0;compile opencore-amr $bits\007"
		if [ -d "opencore-amr-0.1.3" ]; then rm -rf opencore-amr-0.1.3; fi
		wget --tries=20 --retry-connrefused --waitretry=2 -c http://downloads.sourceforge.net/project/opencore-amr/opencore-amr/opencore-amr-0.1.3.tar.gz
		tar xf opencore-amr-0.1.3.tar.gz
		rm opencore-amr-0.1.3.tar.gz
		cd opencore-amr-0.1.3
		./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --enable-shared=no
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
		echo -ne "\033]0;compile vo-amrwbenc $bits\007"
		if [ -d "vo-amrwbenc-0.1.2" ]; then rm -rf vo-amrwbenc-0.1.2; fi
		wget --tries=20 --retry-connrefused --waitretry=2 -c http://downloads.sourceforge.net/project/opencore-amr/vo-amrwbenc/vo-amrwbenc-0.1.2.tar.gz
		tar xf vo-amrwbenc-0.1.2.tar.gz
		rm vo-amrwbenc-0.1.2.tar.gz
		cd vo-amrwbenc-0.1.2
		./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --enable-shared=no
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
		echo -ne "\033]0;compile fdk-aac $bits\007"
		if [ -d "patch-fdk-aac" ]; then rm -rf patch-fdk-aac; fi
		if [ -d "lib-fdk-aac" ]; then rm -rf lib-fdk-aac; fi
		if [ -d "bin-fdk-aac" ]; then rm -rf bin-fdk-aac; fi
		wget --tries=20 --retry-connrefused --waitretry=2 --no-check-certificate -c https://github.com/nu774/fdkaac_autobuild/archive/master.zip -O patch-fdk-aac.zip
		unzip patch-fdk-aac.zip
		rm patch-fdk-aac.zip
		mv fdkaac_autobuild-master patch-fdk-aac
		
		wget --tries=20 --retry-connrefused --waitretry=2 --no-check-certificate -c https://github.com/mstorsjo/fdk-aac/archive/master.zip -O lib-fdk-aac.zip 
		unzip lib-fdk-aac.zip
		rm lib-fdk-aac.zip
		mv fdk-aac-master lib-fdk-aac
		cp patch-fdk-aac/files/LibMakefile lib-fdk-aac/Makefile
		cp patch-fdk-aac/files/libfdk-aac.version lib-fdk-aac/libfdk-aac.version
		
		if [[ $bits = "32bit" ]]; then
				sed -i 's/PREFIX=\/mingw/PREFIX=\/local32/g' lib-fdk-aac/Makefile
			else
				sed -i 's/PREFIX=\/mingw/PREFIX=\/local64/g' lib-fdk-aac/Makefile
			fi

		sed -i 's/cd stage && zip -r $(PREFIX)\/libfdk-aac-win32-bin.zip \* \& cd \.\.//g' lib-fdk-aac/Makefile
		sed -i 's/$(CC)/gcc/g' lib-fdk-aac/Makefile
		cd lib-fdk-aac
		make -j $cpuCount
		make install

		cp libfdk-aac.a $LOCALDESTDIR/lib/libfdk-aac.a

		cd $LOCALBUILDDIR
		wget --tries=20 --retry-connrefused --waitretry=2 --no-check-certificate -c https://github.com/nu774/fdkaac/archive/master.zip -O bin-fdk-aac.zip 
		unzip bin-fdk-aac.zip
		rm bin-fdk-aac.zip 
		mv fdkaac-master bin-fdk-aac
		cp patch-fdk-aac/files/AppMakefile bin-fdk-aac/Makefile
		cp patch-fdk-aac/files/config.h bin-fdk-aac/config.h
		cd bin-fdk-aac
		
		if [[ $bits = "32bit" ]]; then
			sed -i 's/PREFIX=\/mingw/PREFIX=\/local32/g' Makefile
			sed -i '/PREFIX=\/local32/ a\CC=gcc' Makefile
			sed -i 's/CPPFLAGS=-DHAVE_CONFIG_H -I./CPPFLAGS=-DHAVE_CONFIG_H -I. -I\/local32\/include/g' Makefile
			sed -i 's/$(CC) -o$@ $(OBJS) -static -lfdk-aac/$(CC) -o$@ $(OBJS) -static -L\/local32\/lib -lfdk-aac/g' Makefile
		else
			sed -i 's/PREFIX=\/mingw/PREFIX=\/local64/g' Makefile
			sed -i '/PREFIX=\/local64/ a\CC=gcc' Makefile
			sed -i 's/CPPFLAGS=-DHAVE_CONFIG_H -I./CPPFLAGS=-DHAVE_CONFIG_H -I. -I\/local64\/include/g' Makefile
			sed -i 's/$(CC) -o$@ $(OBJS) -static -lfdk-aac/$(CC) -o$@ $(OBJS) -static -L\/local64\/lib -lfdk-aac/g' Makefile
		fi
		
		make
		make install
		
		rm $LOCALDESTDIR/bin/libfdk-aac-0.dll
		rm $LOCALDESTDIR/lib/libfdk-aac.dll.a

		if [ ! -f $LOCALDESTDIR/lib/pkgconfig/fdk-aac.pc ]; then
			echo "prefix=$LOCALDESTDIR" >> $LOCALDESTDIR/lib/pkgconfig/fdk-aac.pc
			echo "exec_prefix=$LOCALDESTDIR" >> $LOCALDESTDIR/lib/pkgconfig/fdk-aac.pc
			echo "libdir=$LOCALDESTDIR/lib" >> $LOCALDESTDIR/lib/pkgconfig/fdk-aac.pc
			echo "includedir=$LOCALDESTDIR/include" >> $LOCALDESTDIR/lib/pkgconfig/fdk-aac.pc
			echo "" >> $LOCALDESTDIR/lib/pkgconfig/fdk-aac.pc
			echo "Name: Fraunhofer FDK AAC Codec Library" >> $LOCALDESTDIR/lib/pkgconfig/fdk-aac.pc
			echo "Description: AAC codec library" >> $LOCALDESTDIR/lib/pkgconfig/fdk-aac.pc
			echo "Version: 0.3.0" >> $LOCALDESTDIR/lib/pkgconfig/fdk-aac.pc
			echo "Libs: -L\${libdir} -lfdk-aac" >> $LOCALDESTDIR/lib/pkgconfig/fdk-aac.pc
			echo "Libs.private: -lm" >> $LOCALDESTDIR/lib/pkgconfig/fdk-aac.pc
			echo "Cflags: -I${includedir}" >> $LOCALDESTDIR/lib/pkgconfig/fdk-aac.pc
		fi

		do_checkIfExist bin-fdk-aac fdkaac.exe
		do_checkIfExist lib-fdk-aac fdkaac.exe
		do_checkIfExist patch-fdk-aac fdkaac.exe
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/bin/faac.exe" ]; then
	echo -------------------------------------------------
	echo "faac-1.28 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile faac $bits\007"
		if [ -d "faac-1.28" ]; then rm -rf faac-1.28; fi
		wget --tries=20 --retry-connrefused --waitretry=2 -c http://downloads.sourceforge.net/faac/faac-1.28.tar.gz
		tar xf faac-1.28.tar.gz
		rm faac-1.28.tar.gz
		cd faac-1.28
		sh bootstrap 
		./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --enable-shared=no --without-mp4v2
		make -j $cpuCount
		make install
		
		do_checkIfExist faac-1.28 faac.exe
fi
fi # nonfree end

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libopus.a" ]; then
    echo -------------------------------------------------
    echo "opus-1.1 is already compiled"
    echo -------------------------------------------------
    else 
		echo -ne "\033]0;compile opus $bits\007"
		if [ -d "opus-1.1" ]; then rm -rf opus-1.1; fi
		wget --tries=20 --retry-connrefused --waitretry=2 -c http://downloads.xiph.org/releases/opus/opus-1.1.tar.gz
		tar xf opus-1.1.tar.gz
		rm opus-1.1.tar.gz
		cd opus-1.1
		wget --tries=20 --retry-connrefused --waitretry=2 --no-check-certificate -c https://raw.github.com/jb-alvarado/media-autobuild_suite/master/patches/opus11.patch
		patch -p0 < opus11.patch
        ./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --enable-shared=no --enable-static --disable-doc
        make -j $cpuCount
        make install
		
		do_checkIfExist opus-1.1 libopus.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/bin/opusenc.exe" ]; then
    echo -------------------------------------------------
    echo "opus-tools-0.1.8 is already compiled"
    echo -------------------------------------------------
    else 
		echo -ne "\033]0;compile opus-tools $bits\007"
		if [ -d "opus-tools-0.1.8" ]; then rm -rf opus-tools-0.1.8; fi
      wget --tries=20 --retry-connrefused --waitretry=2 -c http://downloads.xiph.org/releases/opus/opus-tools-0.1.8.tar.gz
		tar xf opus-tools-0.1.8.tar.gz
		rm opus-tools-0.1.8.tar.gz
		cd opus-tools-0.1.8
        ./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR LDFLAGS="$LDFLAGS -static -static-libgcc -static-libstdc++"
        make -j $cpuCount
        make install
        
		do_checkIfExist opus-tools-0.1.8 opusenc.exe
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/liba52.a" ]; then
	echo -------------------------------------------------
	echo "a52dec-0.7.4 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile a52dec $bits\007"
		if [ -d "a52dec-0.7.4" ]; then rm -rf a52dec-0.7.4; fi
		wget --tries=20 --retry-connrefused --waitretry=2 -c "http://liba52.sourceforge.net/files/a52dec-0.7.4.tar.gz"
		tar xf a52dec-0.7.4.tar.gz
		rm a52dec-0.7.4.tar.gz
		cd a52dec-0.7.4
		./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --disable-shared
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
		echo -ne "\033]0;compile libmad $bits\007"
		if [ -d "libmad-0.15.1b" ]; then rm -rf libmad-0.15.1b; fi
		wget --tries=20 --retry-connrefused --waitretry=2 -c "ftp://ftp.mars.org/pub/mpeg/libmad-0.15.1b.tar.gz"
		tar xf libmad-0.15.1b.tar.gz
		rm libmad-0.15.1b.tar.gz
		cd libmad-0.15.1b
		./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --disable-shared --enable-fpm=intel --disable-debugging
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
		echo -ne "\033]0;compile soxr-0.1.1 $bits\007"
		if [ -d "soxr-0.1.1-Source" ]; then rm -rf soxr-0.1.1-Source; fi
		wget --tries=20 --retry-connrefused --waitretry=2 -c "http://sourceforge.net/projects/soxr/files/soxr-0.1.1-Source.tar.xz"
		tar xf soxr-0.1.1-Source.tar.xz
		rm soxr-0.1.1-Source.tar.xz
		cd soxr-0.1.1-Source
		cmake -G "MSYS Makefiles" -DCMAKE_INSTALL_PREFIX=$LOCALDESTDIR -DHAVE_WORDS_BIGENDIAN_EXITCODE=0 -DBUILD_SHARED_LIBS:bool=off -DBUILD_TESTS:BOOL=OFF -DWITH_OPENMP:BOOL=OFF
		make -j $cpuCount
		make install
		
		do_checkIfExist soxr-0.1.1-Source libsoxr.a
fi

cd $LOCALBUILDDIR

do_git  git://github.com/dbry/WavPack.git WavPack-git

if [[ $compile == "true" ]]; then
	if [[ ! -f ./configure ]]; then
		./autogen.sh
	else 
		make uninstall
		make clean
	fi

	./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --enable-shared=no --enable-mmx
	
	make -j $cpuCount
	make install
	
	do_checkIfExist WavPack-git libwavpack.a
	compile="false"
	buildFFmpeg="true"
else
	echo -------------------------------------------------
	echo "WavPack is already up to date"
	echo -------------------------------------------------
fi
	
cd $LOCALBUILDDIR

do_git "git://github.com/erikd/libsndfile.git" libsndfile-git

if [[ $compile == "true" ]]; then
	if [[ ! -f ./configure ]]; then
		sed -i 's/(python --version)/(python2 --version)/g' autogen.sh
		./autogen.sh
	else 
		make uninstall
		make clean
	fi

	./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --enable-shared=no --disable-external-libs
	
	make -j $cpuCount
	make install
	
	do_checkIfExist libsndfile-git libsndfile.a
	compile="false"
else
	echo -------------------------------------------------
	echo "libsndfile is already up to date"
	echo -------------------------------------------------
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libtwolame.a" ]; then
	echo -------------------------------------------------
	echo "twolame-0.3.13 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile twolame $bits\007"
		if [ -d "twolame-0.3.13" ]; then rm -rf twolame-0.3.13; fi
		wget --tries=20 --retry-connrefused --waitretry=2 -c -O twolame-0.3.13.tar.gz http://sourceforge.net/projects/twolame/files/twolame/0.3.13/twolame-0.3.13.tar.gz/download
		tar xf twolame-0.3.13.tar.gz
		rm twolame-0.3.13.tar.gz
		cd twolame-0.3.13
		./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --disable-shared CPPFLAGS="$CPPFLAGS -DLIBTWOLAME_STATIC"
		make -j $cpuCount
		make install
		
		do_checkIfExist twolame-0.3.13 libtwolame.a
fi
	
cd $LOCALBUILDDIR
	
do_git "git://git.code.sf.net/p/sox/code" sox-git

if [[ $compile == "true" ]]; then
	if [[ $bits = "32bit" ]]; then
		mv /mingw32/lib/libgsm.a /mingw32/lib/tmp_libgsm.a
	else
		mv /mingw64/lib/libgsm.a /mingw64/lib/tmp_libgsm.a
	fi
	
	if [[ ! -f ./configure ]]; then
		autoreconf -i
	else
		make uninstall
		make clean
	fi
	
	./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --enable-shared=no
	
	make -j $cpuCount
	make install
	if [[ $bits = "32bit" ]]; then
		mv /mingw32/lib/tmp_libgsm.a /mingw32/lib/libgsm.a
	else
		mv /mingw64/lib/tmp_libgsm.a /mingw64/lib/libgsm.a
	fi
	
	do_checkIfExist sox-git sox.exe
	compile="false"
else
	echo -------------------------------------------------
	echo "sox is already up to date"
	echo -------------------------------------------------
fi

echo "-------------------------------------------------------------------------------"
echo
echo "compile audio tools $bits done..."
echo
echo "-------------------------------------------------------------------------------"
	
cd $LOCALBUILDDIR
sleep 3
echo "-------------------------------------------------------------------------------"
echo
echo "compile video tools $bits"
echo
echo "-------------------------------------------------------------------------------"

do_git "http://repo.or.cz/r/x264.git" x264-git

if [[ $compile == "true" ]]; then
	if [ -f "$LOCALDESTDIR/lib/libx264.a" ]; then
		rm -f $LOCALDESTDIR/include/x264.h $LOCALDESTDIR/include/x264_config.h $LOCALDESTDIR/lib/libx264.a
		rm -f $LOCALDESTDIR/bin/x264.exe $LOCALDESTDIR/bin/x264-10bit.exe $LOCALDESTDIR/lib/pkgconfig/x264.pc
	fi
	if [ -f "libx264.a" ]; then
		make clean
	fi
	
	./configure --host=$targetHost --prefix=$LOCALDESTDIR --extra-cflags=-fno-aggressive-loop-optimizations --enable-static --enable-win32thread --disable-cli
	make -j $cpuCount
	make install
	
	do_checkIfExist x264-git libx264.a
	compile="false"
	buildFFmpeg="true"
	x264Bin="yes"
else
	echo -------------------------------------------------
	echo "x264 is already up to date"
	echo -------------------------------------------------
fi

cd $LOCALBUILDDIR

do_hg "https://bitbucket.org/multicoreware/x265" x265-hg

if [[ $compile == "true" ]]; then
	cd build/msys
	make clean
	rm -rf *
	if [ -f "$LOCALDESTDIR/bin/x265-16bit.exe" ]; then rm $LOCALDESTDIR/bin/x265-16bit.exe; fi
	if [ -f "$LOCALDESTDIR/include/x265.h" ]; then rm $LOCALDESTDIR/include/x265.h; fi
	if [ -f "$LOCALDESTDIR/include/x265_config.h" ]; then rm $LOCALDESTDIR/include/x265_config.h; fi
	if [ -f "$LOCALDESTDIR/lib/libx265.a" ]; then rm $LOCALDESTDIR/lib/libx265.a; fi
	if [ -f "$LOCALDESTDIR/lib/pkgconfig/x265.pc" ]; then rm $LOCALDESTDIR/lib/pkgconfig/x265.pc; fi

	cmake -G "MSYS Makefiles" -DHIGH_BIT_DEPTH=1 ../../source -DENABLE_SHARED:BOOLEAN=OFF -DCMAKE_CXX_FLAGS="$CXXFLAGS -static-libgcc -static-libstdc++" -DCMAKE_C_FLAGS="$CFLAGS -static-libgcc -static-libstdc++"
	make -j $cpuCount
	cp x265.exe $LOCALDESTDIR/bin/x265-16bit.exe

	make clean
	rm -rf *

	cmake -G "MSYS Makefiles" -DCMAKE_INSTALL_PREFIX:PATH=$LOCALDESTDIR ../../source -DENABLE_SHARED:BOOLEAN=OFF -DCMAKE_CXX_FLAGS="$CXXFLAGS -static-libgcc -static-libstdc++" -DCMAKE_C_FLAGS="$CFLAGS -static-libgcc -static-libstdc++"
	make -j $cpuCount
	make install

	do_checkIfExist x265-git x265.exe
	compile="false"
	buildFFmpeg="true"
else
	echo -------------------------------------------------
	echo "x265 is already up to date"
	echo -------------------------------------------------
fi

cd $LOCALBUILDDIR

do_git "http://git.chromium.org/webm/libvpx.git" libvpx-git

if [[ $compile == "true" ]]; then
	if [ -d "$LOCALDESTDIR/include/vpx" ]; then rm -rf $LOCALDESTDIR/include/vpx; fi
	if [ -f "$LOCALDESTDIR/lib/pkgconfig/vpx.pc" ]; then rm $LOCALDESTDIR/lib/pkgconfig/vpx.pc; fi
	if [ -f "$LOCALDESTDIR/lib/libvpx.a" ]; then rm $LOCALDESTDIR/lib/libvpx.a; fi
	make clean
	if [[ $bits = "64bit" ]]; then
		LDFLAGS="$LDFLAGS -static-libgcc -static" ./configure --prefix=$LOCALDESTDIR --target=x86_64-win64-gcc --disable-shared --enable-static --disable-unit-tests --disable-docs --enable-postproc --enable-vp9-postproc --enable-runtime-cpu-detect
		sed -i 's/HAVE_GNU_STRIP=yes/HAVE_GNU_STRIP=no/g' libs-x86_64-win64-gcc.mk
	else
		LDFLAGS="$LDFLAGS -static-libgcc -static" ./configure --prefix=$LOCALDESTDIR --target=x86-win32-gcc --disable-shared --enable-static --disable-unit-tests --disable-docs --enable-postproc --enable-vp9-postproc --enable-runtime-cpu-detect
		sed -i 's/HAVE_GNU_STRIP=yes/HAVE_GNU_STRIP=no/g' libs-x86-win32-gcc.mk
	fi 

	make -j $cpuCount
	make install
	
	do_checkIfExist libvpx-git libvpx.a
	compile="false"
	buildFFmpeg="true"
else
	echo -------------------------------------------------
	echo "libvpx-git is already up to date"
	echo -------------------------------------------------
fi

cd $LOCALBUILDDIR

do_git "https://github.com/ultravideo/kvazaar.git" kvazaar-git

if [[ $compile == "true" ]]; then
	if [ -d "scons_build_x86" ]; then 
		rm -rf scons_build_x86
	fi
	if [ -d "scons_build_x64" ]; then
		rm -rf scons_build_x64
	fi
	
	sed -i "s/'Windows'/'MINGW32_NT-6.1'/g" SConstruct
	sed -i 's/LD = gcc -pthread -lrt/LD = gcc -pthread/g' src/Makefile
		
	if [[ $bits = "64bit" ]]; then
		scons x64
		cp scons_build_x64/kvazaar.exe $LOCALDESTDIR/bin
	else
		scons x86
		cp scons_build_x86/kvazaar.exe $LOCALDESTDIR/bin
	fi 

	do_checkIfExist kvazaar-git kvazaar.exe
	compile="false"
else
	echo -------------------------------------------------
	echo "kvazaar-git is already up to date"
	echo -------------------------------------------------
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libdvdcss.a" ]; then
echo -------------------------------------------------
echo "libdvdcss-1.2.13 is already compiled"
echo -------------------------------------------------
else
echo -ne "\033]0;compile libdvdcss $bits\007"
if [ -d "libdvdcss-1.2.13" ]; then rm -rf libdvdcss-1.2.13; fi
wget --tries=20 --retry-connrefused --waitretry=2 -c http://download.videolan.org/pub/videolan/libdvdcss/1.2.13/libdvdcss-1.2.13.tar.bz2
tar xf libdvdcss-1.2.13.tar.bz2
rm libdvdcss-1.2.13.tar.bz2
cd libdvdcss-1.2.13
./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --disable-shared --disable-apidoc
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
wget --tries=20 --retry-connrefused --waitretry=2 -c http://dvdnav.mplayerhq.hu/releases/libdvdread-4.2.1.tar.xz
tar xf libdvdread-4.2.1.tar.xz
rm libdvdread-4.2.1.tar.xz
cd libdvdread-4.2.1
if [[ ! -f ./configure ]]; then
./autogen.sh
fi	
./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --disable-shared CFLAGS="$CFLAGS -DHAVE_DVDCSS_DVDCSS_H" LDFLAGS="$LDFLAGS -ldvdcss"
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
wget --tries=20 --retry-connrefused --waitretry=2 -c http://dvdnav.mplayerhq.hu/releases/libdvdnav-4.2.1.tar.xz
tar xf libdvdnav-4.2.1.tar.xz
rm libdvdnav-4.2.1.tar.xz
cd libdvdnav-4.2.1
if [[ ! -f ./configure ]]; then
./autogen.sh
fi
./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --disable-shared --with-dvdread-config=$LOCALDESTDIR/bin/dvdread-config
make -j $cpuCount
make install
sed -i "s/echo -L${exec_prefix}\/lib -ldvdnav -ldvdread/echo -L${exec_prefix}\/lib -ldvdnav -ldvdread -ldl/" $LOCALDESTDIR/bin/dvdnav-config

do_checkIfExist libdvdnav-4.2.1 libdvdnav.a
fi

cd $LOCALBUILDDIR

do_git "git://git.videolan.org/libbluray.git" libbluray-git

if [[ $compile == "true" ]]; then
	if [ -f $LOCALDESTDIR/lib/libbluray.a ]; then
		make uninstall
		make clean
	fi
	
	if [[ ! -f "configure" ]]; then
		./bootstrap
	fi
	./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --disable-shared --enable-static
	make -j $cpuCount
	make install
	
	do_checkIfExist libbluray-git libbluray.a
	compile="false"
	buildFFmpeg="true"
else
	echo -------------------------------------------------
	echo "libbluray is already up to date"
	echo -------------------------------------------------
fi

cd $LOCALBUILDDIR

do_git "git://github.com/qyot27/libutvideo.git" libutvideo-git

if [[ $compile == "true" ]]; then
	if [ -f $LOCALDESTDIR/lib/libutvideo.a ]; then
		make uninstall
		make clean
	fi
	
	sed -i 's/AR="${AR-${cross_prefix}ar}"/AR="${AR-ar}"/g' configure
	sed -i 's/RANLIB="${RANLIB-${cross_prefix}ranlib}"/RANLIB="${RANLIB-ranlib}"/g' configure
	#grep -q -e '#include <windows.h>' utv_core/Codec.h || sed -i '/#define CBGROSSWIDTH_WINDOWS ((size_t)-1)/ a\#include <windows.h>\
	#define DLLEXPORT' utv_core/Codec.h	
	./configure --cross-prefix=$cross --prefix=$LOCALDESTDIR
	make -j $cpuCount
	make install
	
	do_checkIfExist libutvideo-git libutvideo.a
	compile="false"
	buildFFmpeg="true"
else
	echo -------------------------------------------------
	echo "libutvideo is already up to date"
	echo -------------------------------------------------
fi

cd $LOCALBUILDDIR

do_git "https://github.com/libass/libass.git" libass-git

if [[ $compile == "true" ]]; then
	if [ -f $LOCALDESTDIR/lib/libass.a ]; then
		make uninstall
		make clean
	fi
	
	if [[ ! -f "configure" ]]; then
		./autogen.sh
	fi
	CPPFLAGS=' -DFRIBIDI_ENTRY="" ' ./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --enable-shared=no
	make -j $cpuCount
	make install
	
	sed -i 's/-lass -lm/-lass -lfribidi -lm/' "$LOCALDESTDIR/lib/pkgconfig/libass.pc"
	
	do_checkIfExist libass-git libass.a
	compile="false"
	buildFFmpeg="true"
else
	echo -------------------------------------------------
	echo "libass is already up to date"
	echo -------------------------------------------------
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libxavs.a" ]; then
	echo -------------------------------------------------
	echo "xavs is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile xavs $bits\007"
		if [ -d "xavs" ]; then rm -rf xavs; fi
		svn checkout --trust-server-cert --non-interactive https://svn.code.sf.net/p/xavs/code/trunk/ xavs
		cd xavs
		./configure --host=$targetHost --prefix=$LOCALDESTDIR
		make -j $cpuCount
		make install
		
		do_checkIfExist xavs libxavs.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/bin/mediainfo.exe" ]; then
	echo -------------------------------------------------
	echo "MediaInfo_CLI is already compiled"
	echo -------------------------------------------------
	else
		echo -ne "\033]0;compile MediaInfo_CLI $bits\007"
		if [ -d "mediainfo" ]; then rm -rf mediainfo; fi
		wget --tries=20 --retry-connrefused --waitretry=2 -c http://downloads.sourceforge.net/project/mediainfo/source/mediainfo/0.7.69/mediainfo_0.7.69_AllInclusive.7z
		mkdir mediainfo
		cd mediainfo
		7za x ../mediainfo_0.7.69_AllInclusive.7z
		rm ../mediainfo_0.7.69_AllInclusive.7z
		
		sed -i '/#include <windows.h>/ a\#include <time.h>' ZenLib/Source/ZenLib/Ztring.cpp
		cd ZenLib/Project/GNU/Library
		
		./autogen
		./configure --build=$targetBuild --host=$targetHost
		
		if [[ $bits = "64bit" ]]; then
			sed -i 's/ -DSIZE_T_IS_LONG//g' Makefile
		fi
		make -j $cpuCount
		
		cd ../../../../MediaInfoLib/Project/GNU/Library
		./autogen
		./configure --build=$targetBuild --host=$targetHost LDFLAGS="$LDFLAGS -static-libgcc"
		
		if [[ $bits = "64bit" ]]; then
			sed -i 's/ -DSIZE_T_IS_LONG//g' Makefile
		fi
		
		make -j $cpuCount
		
		cd ../../../../MediaInfo/Project/GNU/CLI
		./autogen
		./configure --build=$targetBuild --host=$targetHost --enable-staticlibs --enable-shared=no LDFLAGS="$LDFLAGS -static-libgcc"
		
		if [[ $bits = "64bit" ]]; then
			sed -i 's/ -DSIZE_T_IS_LONG//g' Makefile
		fi
		
		make -j $cpuCount
		
		cp mediainfo.exe $LOCALDESTDIR/bin/mediainfo.exe

		do_checkIfExist mediainfo mediainfo.exe
fi

cd $LOCALBUILDDIR

do_git "https://github.com/georgmartius/vid.stab.git" vidstab-git

if [[ $compile == "true" ]]; then
	make uninstall
	make clean
	cmake -G "MSYS Makefiles" -DCMAKE_INSTALL_PREFIX=$LOCALDESTDIR
	sed -i "s/SHARED/STATIC/" CMakeLists.txt
	make -j $cpuCount
	make install
	
	do_checkIfExist vidstab-git libvidstab.a
	compile="false"
	buildFFmpeg="true"
else
	echo -------------------------------------------------
	echo "vidstab is already up to date"
	echo -------------------------------------------------
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libcaca.a" ]; then
	echo -------------------------------------------------
	echo "libcaca-0.99.beta18 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile libcaca $bits\007"
		if [ -d "libcaca-0.99.beta18" ]; then rm -rf libcaca-0.99.beta18; fi
		wget --tries=20 --retry-connrefused --waitretry=2 -c http://caca.zoy.org/files/libcaca/libcaca-0.99.beta18.tar.gz
		tar xf libcaca-0.99.beta18.tar.gz
		rm libcaca-0.99.beta18.tar.gz
		cd libcaca-0.99.beta18
		cd caca
		sed -i "s/#if defined _WIN32 && defined __GNUC__ && __GNUC__ >= 3/#if defined __MINGW__/g" string.c
		sed -i "s/#if defined _WIN32 && defined __GNUC__ && __GNUC__ >= 3/#if defined __MINGW__/g" figfont.c
		sed -i "s/__declspec(dllexport)//g" *.h
		sed -i "s/__declspec(dllimport)//g" *.h 
		cd ..
		./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --disable-shared --disable-cxx --disable-csharp --disable-ncurses --disable-java --disable-python --disable-ruby --disable-imlib2 --disable-doc
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
		wget --tries=20 --retry-connrefused --waitretry=2 -c -O libmodplug-0.8.8.4.tar.gz http://sourceforge.net/projects/modplug-xmms/files/libmodplug/0.8.8.4/libmodplug-0.8.8.4.tar.gz/download
		tar xf libmodplug-0.8.8.4.tar.gz
		rm libmodplug-0.8.8.4.tar.gz
		cd libmodplug-0.8.8.4
		./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --disable-shared
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
		if [ -d "orc-0.4.19" ]; then rm -rf orc-0.4.19; fi
		wget --tries=20 --retry-connrefused --waitretry=2 -c http://gstreamer.freedesktop.org/src/orc/orc-0.4.19.tar.gz
		tar xf orc-0.4.19.tar.gz
		rm orc-0.4.19.tar.gz
		cd orc-0.4.19
		./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --disable-shared LDFLAGS="$LDFLAGS -static -static-libgcc -static-libstdc++"
		make -j $cpuCount
		make install
		
		do_checkIfExist orc-0.4.19 liborc-0.4.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libschroedinger-1.0.a" ]; then
	echo -------------------------------------------------
	echo "schroedinger-1.0.11 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile schroedinger $bits\007"
		if [ -d "schroedinger-1.0.11" ]; then rm -rf schroedinger-1.0.11; fi
		wget --tries=20 --retry-connrefused --waitretry=2 -c http://download.videolan.org/contrib/schroedinger-1.0.11.tar.gz
		tar xf schroedinger-1.0.11.tar.gz
		rm schroedinger-1.0.11.tar.gz
		cd schroedinger-1.0.11
		./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --disable-shared LDFLAGS="$LDFLAGS -static -static-libgcc -static-libstdc++"
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
		wget --tries=20 --retry-connrefused --waitretry=2 -c -O zvbi-0.2.35.tar.bz2 http://sourceforge.net/projects/zapping/files/zvbi/0.2.35/zvbi-0.2.35.tar.bz2/download
		tar xf zvbi-0.2.35.tar.bz2
		rm zvbi-0.2.35.tar.bz2
		cd zvbi-0.2.35
		wget --tries=20 --retry-connrefused --waitretry=2 --no-check-certificate -c https://raw.github.com/jb-alvarado/media-autobuild_suite/master/patches/zvbi-win32.patch
		wget --tries=20 --retry-connrefused --waitretry=2 --no-check-certificate -c https://raw.github.com/jb-alvarado/media-autobuild_suite/master/patches/zvbi-ioctl.patch
		patch -p0 < zvbi-win32.patch
		patch -p0 < zvbi-ioctl.patch
		./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --disable-shared --disable-dvb --disable-bktr --disable-nls --disable-proxy --without-doxygen CFLAGS="$CFLAGS -DPTW32_STATIC_LIB" LIBS="$LIBS -lpng"
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
		wget --tries=20 --retry-connrefused --waitretry=2 --no-check-certificate -c -O frei0r-plugins-1.4.tar.gz https://files.dyne.org/.xsend.php?file=frei0r/releases/frei0r-plugins-1.4.tar.gz
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
	do_svn "http://svn.code.sf.net/p/gpac/code/trunk/gpac" mp4box-svn

	if [[ $compile == "true" ]]; then
		if [ -f $LOCALDESTDIR/bin/MP4Box.exe ]; then
			rm $LOCALDESTDIR/bin/MP4Box.exe
			make clean
		fi
		
		./configure --build=$targetBuild --host=$targetHost --static-mp4box --enable-static-bin --extra-libs="-lws2_32 -lwinmm -lz -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64" --use-ffmpeg=no --use-png=no --disable-ssl
		cp config.h include/gpac/internal
		cd src
		make -j $cpuCount
		
		cd ../applications/mp4box
		make -j $cpuCount
		cd ../..
		cp bin/gcc/MP4Box.exe $LOCALDESTDIR/bin
		
		do_checkIfExist mp4box-svn MP4Box.exe
		compile="false"
	else
		echo -------------------------------------------------
		echo "MP4Box is already up to date"
		echo -------------------------------------------------
	fi
fi

cd $LOCALBUILDDIR

if [[ $ffmpeg = "y" ]] || [[ $ffmpeg = "s" ]]; then
	if [[ $nonfree = "y" ]]; then
		extras="--enable-nonfree --enable-libfaac --enable-libfdk-aac"
	  else
		extras="" 
	fi
	
	echo "-------------------------------------------------------------------------------"
	echo "compile ffmpeg $bits"
	echo "-------------------------------------------------------------------------------"

	do_git "https://github.com/FFmpeg/FFmpeg.git" ffmpeg-git

	if [[ $compile == "true" ]] || [[ $buildFFmpeg == "true" ]]; then
		if [ -d "$LOCALDESTDIR/include/libavutil" ]; then 
			rm -rf $LOCALDESTDIR/include/libavutil
			rm -rf $LOCALDESTDIR/include/libavcodec
			rm -rf $LOCALDESTDIR/include/libpostproc
			rm -rf $LOCALDESTDIR/include/libswresample
			rm -rf $LOCALDESTDIR/include/libswscale
			rm -rf $LOCALDESTDIR/include/libavdevice
			rm -rf $LOCALDESTDIR/include/libavfilter
			rm -rf $LOCALDESTDIR/include/libavformat
			rm -rf $LOCALDESTDIR/lib/libavutil.a
			rm -rf $LOCALDESTDIR/lib/libswresample.a
			rm -rf $LOCALDESTDIR/lib/libswscale.a
			rm -rf $LOCALDESTDIR/lib/libavcodec.a
			rm -rf $LOCALDESTDIR/lib/libavdevice.a
			rm -rf $LOCALDESTDIR/lib/libavfilter.a
			rm -rf $LOCALDESTDIR/lib/libavformat.a
			rm -rf $LOCALDESTDIR/lib/libpostproc.a
			rm -rf $LOCALDESTDIR/lib/pkgconfig/libavcodec.pc
			rm -rf $LOCALDESTDIR/lib/pkgconfig/libavutil.pc
			rm -rf $LOCALDESTDIR/lib/pkgconfig/libpostproc.pc
			rm -rf $LOCALDESTDIR/lib/pkgconfig/libswresample.pc
			rm -rf $LOCALDESTDIR/lib/pkgconfig/libswscale.pc
			rm -rf $LOCALDESTDIR/lib/pkgconfig/libavdevice.pc
			rm -rf $LOCALDESTDIR/lib/pkgconfig/libavfilter.pc
			rm -rf $LOCALDESTDIR/lib/pkgconfig/libavformat.pc
			make clean
		fi
			
			if [[ $bits = "32bit" ]]; then
				arch='x86'
			else
				arch='x86_64'
			fi
			if [[ $ffmpeg = "s" ]]; then
				if [ -d "$LOCALDESTDIR/bin/ffmpegSHARED/bin/ffmpeg.exe" ]; then 
					rm -rf $LOCALDESTDIR/bin/ffmpegSHARED
					make clean
				fi
				LDFLAGS="$LDFLAGS -static-libgcc" ./configure --arch=$arch --target-os=mingw32 --prefix=$LOCALDESTDIR/bin/ffmpegSHARED --disable-debug --disable-static --enable-shared --enable-gpl --enable-version3 --enable-runtime-cpudetect --enable-avfilter --enable-bzlib --enable-zlib --enable-librtmp --enable-gnutls --enable-avisynth --enable-frei0r --enable-filter=frei0r --enable-libbluray --enable-libcaca --enable-libopenjpeg --enable-fontconfig --enable-libfreetype --enable-libass --enable-libgsm --enable-libmodplug --enable-libmp3lame --enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libvo-amrwbenc --enable-libschroedinger --enable-libsoxr --enable-libtwolame --enable-libspeex --enable-libtheora --enable-libvorbis --enable-libvo-aacenc --enable-libopus --enable-libvidstab --enable-libvpx --enable-libwavpack --enable-libxavs --enable-libx264 --enable-libx265 --enable-libxvid --enable-libzvbi $extras --extra-cflags='-DPTW32_STATIC_LIB -DLIBTWOLAME_STATIC' --extra-libs='-lxml2 -llzma -lstdc++ -lpng -lm -lpthread -lwsock32 -lhogweed -lnettle -lgmp -ltasn1 -lws2_32 -lwinmm -lgdi32 -lcrypt32 -lintl -lz -liconv'
			else
				./configure --arch=$arch --target-os=mingw32 --prefix=$LOCALDESTDIR --disable-debug --disable-shared --enable-gpl --enable-version3 --enable-runtime-cpudetect --enable-avfilter --enable-bzlib --enable-zlib --enable-librtmp --enable-gnutls --enable-avisynth --enable-frei0r --enable-filter=frei0r --enable-libbluray --enable-libcaca --enable-libopenjpeg --enable-fontconfig --enable-libfreetype --enable-libass --enable-libgsm --enable-libmodplug --enable-libmp3lame --enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libvo-amrwbenc --enable-libschroedinger --enable-libsoxr --enable-libtwolame --enable-libutvideo --enable-libspeex --enable-libtheora --enable-libvorbis --enable-libvo-aacenc --enable-libopus --enable-libvidstab --enable-libvpx --enable-libwavpack --enable-libxavs --enable-libx264 --enable-libx265 --enable-libxvid --enable-libzvbi $extras --extra-cflags='-DPTW32_STATIC_LIB -DLIBTWOLAME_STATIC' --extra-libs='-lxml2 -llzma -lstdc++ -lpng -lm -lpthread -lwsock32 -lhogweed -lnettle -lgmp -ltasn1 -lws2_32 -lwinmm -lgdi32 -lcrypt32 -lintl -lz -liconv'
				
				newFfmpeg="yes"
			fi
			
			if [[ $bits = "32bit" ]]; then
				sed -i "s/--target-os=mingw32 --prefix=\/local32 //g" config.h
			else
				sed -i "s/--target-os=mingw32 --prefix=\/local64 //g" config.h
			fi
			
			sed -i "s/ --extra-cflags='-DPTW32_STATIC_LIB -DLIBTWOLAME_STATIC' --extra-libs='-lxml2 -llzma -lstdc++ -lpng -lm -lpthread -lwsock32 -lhogweed -lnettle -lgmp -ltasn1 -lws2_32 -lwinmm -lgdi32 -lcrypt32 -lintl -lz -liconv'//g" config.h
			
			make -j $cpuCount
			make install
			
			do_checkIfExist ffmpeg-git ffmpeg.exe
			compile="false"
		else
			echo -------------------------------------------------
			echo "ffmpeg is already up to date"
			echo -------------------------------------------------
		fi
fi

cd $LOCALBUILDDIR

echo -ne "\033]0;compile x264 bins $bits\007"
if [[ $x264Bin == "yes" ]] || [[ $newFfmpeg == "yes" ]]; then
	cd x264-git
	make uninstall
	make clean
	
	./configure --host=$targetHost --prefix=$LOCALDESTDIR --extra-cflags=-fno-aggressive-loop-optimizations --enable-static --enable-win32thread --disable-cli --bit-depth=10 --extra-ldflags='-lsoxr'
	make -j $cpuCount
	
	./configure --host=$targetHost --prefix=$LOCALDESTDIR --extra-cflags=-fno-aggressive-loop-optimizations --enable-static --enable-win32thread --bit-depth=10 --extra-ldflags='-lsoxr'
	make -j $cpuCount
	
	cp x264.exe $LOCALDESTDIR/bin/x264-10bit.exe
	make clean
	
	./configure --host=$targetHost --prefix=$LOCALDESTDIR --extra-cflags=-fno-aggressive-loop-optimizations --enable-static --enable-win32thread --disable-cli --extra-ldflags='-lsoxr'
	make -j $cpuCount
	
	./configure --host=$targetHost --prefix=$LOCALDESTDIR --extra-cflags=-fno-aggressive-loop-optimizations --enable-static --enable-win32thread --extra-ldflags='-lsoxr'
	make -j $cpuCount
	make install
fi

cd $LOCALBUILDDIR

if [[ $nonfree = "y" ]]; then
    faac=""
  elif [[ $nonfree = "n" ]]; then
      faac="--disable-faac --disable-faac-lavc" 
fi	

if [[ $mplayer = "y" ]]; then
	do_svn "svn://svn.mplayerhq.hu/mplayer/trunk" mplayer-svn
	
	if [ -d "ffmpeg" ]; then
		cd ffmpeg
		oldHead=`git rev-parse HEAD`
		git pull origin master
		newHead=`git rev-parse HEAD`
		cd ..
	fi 

	if [[ $compile == "true" ]] || [[ "$oldHead" != "$newHead"  ]] || [ ! -d "ffmpeg" ]; then
		if [ -f $LOCALDESTDIR/bin/mplayer.exe ]; then
			make uninstall
			make clean
		fi
		
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
		./configure --prefix=$LOCALDESTDIR --cc=gcc --extra-cflags='-DPTW32_STATIC_LIB -O3 -std=gnu99' --extra-libs='-lxml2 -llzma -lfreetype -lz -liconv -lws2_32 -lpthread -lwinpthread -lpng' --enable-static --enable-runtime-cpudetection --enable-ass-internal --enable-bluray --with-dvdnav-config=$LOCALDESTDIR/bin/dvdnav-config --with-dvdread-config=$LOCALDESTDIR/bin/dvdread-config --disable-dvdread-internal --disable-libdvdcss-internal $faac
		make -j $cpuCount
		make install

		do_checkIfExist mplayer-svn mplayer.exe
		compile="false"
		else
		echo -------------------------------------------------
		echo "mplayer is already up to date"
		echo -------------------------------------------------
	fi
fi

echo "-------------------------------------------------------------------------------"
echo
echo "compile video tools $bits done..."
echo
echo "-------------------------------------------------------------------------------"
	
}

if [[ $build32 = "yes" ]]; then
	echo "-------------------------------------------------------------------------------"
	echo
	echo "compile local tools 32bit"
	echo
	echo "-------------------------------------------------------------------------------"
	source /global32/etc/profile.local
	buildProcess
	echo "-------------------------------------------------------------------------------"
	echo "compile local tools 32bit done..."
	echo "-------------------------------------------------------------------------------"
	sleep 3
fi

if [[ $build64 = "yes" ]]; then
	echo "-------------------------------------------------------------------------------"
	echo
	echo "compile local tools 64bit"
	echo
	echo "-------------------------------------------------------------------------------"
	source /global64/etc/profile.local
	buildProcess
	echo "-------------------------------------------------------------------------------"
	echo "compile local tools 64bit done..."
	echo "-------------------------------------------------------------------------------"
	sleep 3
fi

sleep 5
