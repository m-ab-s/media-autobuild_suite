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

if [ -f "jpeg-9/compile.done" ]; then
	echo ----------------------------------
	echo "jpeg-9 is already compiled"
	echo ----------------------------------
	else 
		wget -c "http://www.ijg.org/files/jpegsrc.v9.tar.gz"
		tar xf jpegsrc.v9.tar.gz
		cd jpeg-9
		./configure --prefix=$LOCALDESTDIR --enable-static
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		cd $LOCALBUILDDIR
		rm jpegsrc.v9.tar.gz
fi

if [ -f "libpng-1.6.6/compile.done" ]; then
	echo ----------------------------------
	echo "libpng-1.6.6 is already compiled"
	echo ----------------------------------
	else 
		wget -c "http://downloads.sourceforge.net/project/libpng/libpng16/1.6.6/libpng-1.6.6.tar.gz"
		tar xf libpng-1.6.6.tar.gz
		cd libpng-1.6.6
		./configure --prefix=$LOCALDESTDIR --disable-shared
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		cd $LOCALBUILDDIR
		rm libpng-1.6.6.tar.gz
fi

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

if [ -f "a52dec-0.7.4/compile.done" ]; then
	echo ----------------------------------
	echo "a52dec-0.7.4 is already compiled"
	echo ----------------------------------
	else 
		wget -c "http://liba52.sourceforge.net/files/a52dec-0.7.4.tar.gz"
		tar xf a52dec-0.7.4.tar.gz
		cd a52dec-0.7.4
		./configure --prefix=$LOCALDESTDIR
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		cd $LOCALBUILDDIR
		rm a52dec-0.7.4.tar.gz
fi

if [ -f "libmad-0.15.1b/compile.done" ]; then
	echo ----------------------------------
	echo "libmad-0.15.1b is already compiled"
	echo ----------------------------------
	else 
		wget -c "ftp://ftp.mars.org/pub/mpeg/libmad-0.15.1b.tar.gz"
		tar xf libmad-0.15.1b.tar.gz
		cd libmad-0.15.1b
		./configure --prefix=$LOCALDESTDIR --disable-shared --enable-fpm=intel --disable-debugging
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		cd $LOCALBUILDDIR
		rm libmad-0.15.1b.tar.gz
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
		#svn co svn://svn.code.sf.net/p/gpac/code/trunk/gpac mp4box_gpac
		#cd mp4box_gpac
		#./configure --prefix=$LOCALDESTDIR --cpu=i586 --strip --use-png=no --use-ffmpeg=no --static-mp4box --enable-static-bin
		#cp config.h include/gpac/internal
		#make -j $cpuCount
		#make install
		#echo "finish" > compile.done
		#cd $LOCALBUILDDIR
		#rm libpng-1.6.6.tar.gz
fi
