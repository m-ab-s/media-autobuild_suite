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
