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
	
cd $LOCALBUILDDIR

if [ -f "freetype-2.5.0.1/compile.done" ]; then
	echo ----------------------------------
	echo "freetype-2.5.0.1 is already compiled"
	echo ----------------------------------
	else 
		wget -c "http://downloads.sourceforge.net/project/freetype/freetype2/2.5.0/freetype-2.5.0.1.tar.gz"
		tar xf freetype-2.5.0.1.tar.gz
		cd freetype-2.5.0.1
		./configure --prefix=$LOCALDESTDIR --disable-shared
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		cd $LOCALBUILDDIR
		rm freetype-2.5.0.1.tar.gz
fi

if [ -f "dx7headers/compile.done" ]; then
	echo ----------------------------------
	echo "dx7headers is already compiled"
	echo ----------------------------------
	else 
		wget -c "http://www.mplayerhq.hu/MPlayer/contrib/win32/dx7headers.tgz"
		mkdir dx7headers
		cd dx7headers
		/opt/bin/7za x ../dx7headers.tgz
		/opt/bin/7za x dx7headers.tar
		cd $LOCALBUILDDIR
		cp dx7headers/* $LOCALDESTDIR/include
		echo "finish" > dx7headers/compile.done
		rm dx7headers.tgz
		rm dx7headers/dx7headers.tar
fi

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
