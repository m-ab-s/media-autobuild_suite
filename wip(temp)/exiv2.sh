source /local32/etc/profile.local

# set CPU count global. This can be overwrite from the compiler script (ffmpeg-autobuild.bat)
cpuCount=6
while true; do
  case $1 in
--cpuCount=* ) cpuCount="${1#*=}"; shift ;;
    -- ) shift; break ;;
    -* ) echo "Error, unknown option: '$1'."; exit 1 ;;
    * ) break ;;
  esac
done

cd $LOCALBUILDDIR
if [ -f "exiv2-0.23/compile.done" ]; then
    echo -------------------------------------------------
    echo "exiv2-0.23 is already compiled"
    echo -------------------------------------------------
    else 
		#svn checkout svn://dev.exiv2.org/svn/trunk exiv2
		wget -c http://www.exiv2.org/exiv2-0.23.tar.gz
		tar xzf exiv2-0.23.tar.gz
		rm exiv2-0.23.tar.gz
		cd exiv2-0.23
		./configure --prefix=$LOCALDESTDIR --enable-shared=no --enable-static=yes LDFLAGS="-L$LOCALDESTDIR/lib -mthreads -static -static-libgcc -static-libstdc++" 
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		
		if [ -f "$LOCALDESTDIR/bin/exiv2.exe" ]; then
			echo -
			echo -------------------------------------------------
			echo "build exiv2-0.23 done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build exiv2-0.23 failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
fi