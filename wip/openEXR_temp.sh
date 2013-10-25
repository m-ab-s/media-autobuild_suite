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
		./configure --prefix=$LOCALDESTDIR --enable-shared=no --enable-static=yes LDFLAGS="-L$LOCALDESTDIR/lib -mthreads -static -static-libgcc -static-libstdc++ -DPTW32_STATIC_LIB" 
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

cd $LOCALBUILDDIR
if [ -f "fftw-3.2.2/compile.done" ]; then
    echo -------------------------------------------------
    echo "fftw-3.2.2 is already compiled"
    echo -------------------------------------------------
    else 
		wget -c ftp://ftp.fftw.org/pub/fftw/fftw-3.2.2.tar.gz
		tar xf fftw-3.2.2.tar.gz
		rm fftw-3.2.2.tar.gz
		cd fftw-3.2.2
		#sed -i 's/.\/configure --disable-shared --enable-maintainer-mode --enable-threads $*/ /g' bootstrap.sh
		#sed -i 's/configur*/ /g' bootstrap.sh
		./configure --prefix=/local32 --with-our-malloc16 --with-windows-f77-mangling --enable-shared --enable-threads --with-combined-threads --enable-portable-binary --enable-float --enable-sse LDFLAGS="-L$LOCALDESTDIR/lib -mthreads -static -static-libgcc -static-libstdc++ -DPTW32_STATIC_LIB" 
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		
		if [ -f "$LOCALDESTDIR/bin/fftwf-wisdom.exe" ]; then
			echo -
			echo -------------------------------------------------
			echo "build fftw-3.2.2 done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build fftw-3.2.2 failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
fi

cd $LOCALBUILDDIR
if [ -f "fltk-1.3.2/compile.done" ]; then
    echo -------------------------------------------------
    echo "fltk-1.3.2 is already compiled"
    echo -------------------------------------------------
    else 
		wget -c http://fltk.org/pub/fltk/1.3.2/fltk-1.3.2-source.tar.gz
		tar xzf fltk-1.3.2-source.tar.gz
		rm fltk-1.3.2-source.tar.gz
		cd fltk-1.3.2
		./configure --prefix=$LOCALDESTDIR LDFLAGS="-L$LOCALDESTDIR/lib -mthreads -static -static-libgcc -static-libstdc++ -DPTW32_STATIC_LIB" 
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		
		if [ -f "$LOCALDESTDIR/bin/fluid.exe" ]; then
			echo -
			echo -------------------------------------------------
			echo "build fltk-1.3.2 done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build fltk-1.3.2 failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
fi

cd $LOCALBUILDDIR
if [ -f "OpenEXR-Master/compile.done" ]; then
    echo -------------------------------------------------
    echo "OpenEXR is already compiled"
    echo -------------------------------------------------
    else 
		git clone https://github.com/openexr/openexr.git OpenEXR-Master
		cd OpenEXR-Master
		cd IlmBase
		./bootstrap
		sed -i 's/#if !defined (_WIN32) &&!(_WIN64) && !(HAVE_PTHREAD)/#if true/g' IlmThread/IlmThread.cpp
		sed -i 's/#if !defined (_WIN32) && !(_WIN64) && !(HAVE_PTHREAD)/#if true/g' IlmThread/IlmThreadMutex.cpp
		sed -i 's/#if !defined (_WIN32) && !(_WIN64) && !(HAVE_PTHREAD)/#if true/g' IlmThread/IlmThreadSemaphore.cpp
		./configure --prefix=$LOCALDESTDIR --disable-threading --disable-posix-sem LDFLAGS="-L$LOCALDESTDIR/lib -mthreads -static -static-libgcc -static-libstdc++ -DPTW32_STATIC_LIB" 
		make -j $cpuCount
		make install
		cd ..

		cd OpenEXR
		./bootstrap
		sed -i 's/#define ZLIB_WINAPI/\/\/#define ZLIB_WINAPI/g' IlmImf/ImfZipCompressor.cpp
		sed -i 's/#define ZLIB_WINAPI/\/\/#define ZLIB_WINAPI/g' IlmImf/ImfPxr24Compressor.cpp
		./configure --prefix=$LOCALDESTDIR --disable-threading --disable-posix-sem --disable-ilmbasetest LDFLAGS="-L$LOCALDESTDIR/lib -mthreads -static -static-libgcc -static-libstdc++ -DPTW32_STATIC_LIB" 
		cd IlmImf
		g++ -I/local32/include -I/local32/include/OpenEXR -mms-bitfields -mthreads -mtune=pentium3 -static -static-libgcc -static-libstdc++ -I/local32/include -L/local32/lib -mthreads  b44ExpLogTable.cpp -lHalf -o b44ExpLogTable
		cd ..
		make -j $cpuCount
		make install
		cd ..
		echo "finish" > compile.done
		
		if [ -f "$LOCALDESTDIR/bin/exrmakepreview.exe" ]; then
			echo -
			echo -------------------------------------------------
			echo "build OpenEXR done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build OpenEXR failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
fi

#cd $LOCALBUILDDIR
#if [ -f "aces_container/compile.done" ]; then
#    echo -------------------------------------------------
#    echo "aces_container is already compiled"
#    echo -------------------------------------------------
#    else 
#		git clone https://github.com/ampas/aces_container.git aces_container
#		cd aces_container
#		mkdir build
#		cd build
#		cmake -DCMAKE_INSTALL_PREFIX:PATH=$LOCALDESTDIR -G "MSYS Makefiles" ..
#		make -j $cpuCount
#		make install
#		echo "finish" > compile.done
#		
#		if [ -f "$LOCALDESTDIR/bin/aces_container.exe" ]; then
#			echo -
#			echo -------------------------------------------------
#			echo "build aces_container done..."
#			echo -------------------------------------------------
#			echo -
#			else
#				echo -------------------------------------------------
#				echo "build aces_container failed..."
#				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
#				read -p "first close the batch window, then the shell window"
#				sleep 15
#		fi
#fi
#
#cd $LOCALBUILDDIR
#if [ -f "CTL/compile.done" ]; then
#    echo -------------------------------------------------
#    echo "CTL is already compiled"
#    echo -------------------------------------------------
#    else 
#		git clone https://github.com/ampas/CTL.git CTL
#		cd CTL
#		mkdir build
#		cd build
#		cmake -DCMAKE_INSTALL_PREFIX:PATH=$LOCALDESTDIR -G "MSYS Makefiles" ..
#		make -j $cpuCount
#		make install
#		echo "finish" > compile.done
#		
#		if [ -f "$LOCALDESTDIR/bin/CTL.exe" ]; then
#			echo -
#			echo -------------------------------------------------
#			echo "build CTL done..."
#			echo -------------------------------------------------
#			echo -
#			else
#				echo -------------------------------------------------
#				echo "build CTL failed..."
#				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
#				read -p "first close the batch window, then the shell window"
#				sleep 15
#		fi
#fi

#cd $LOCALBUILDDIR
cd OpenEXR_Viewers
./bootstrap 
./configure --prefix=$LOCALDESTDIR --enable-shared=no --enable-static=yes --disable-threading --disable-posix-sem LDFLAGS="-L$LOCALDESTDIR/lib -mthreads -static -static-libgcc -static-libstdc++ -DPTW32_STATIC_LIB" 
make -j $cpuCount
make install








