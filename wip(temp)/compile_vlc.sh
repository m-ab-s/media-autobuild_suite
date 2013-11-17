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

if [ -f "$LOCALDESTDIR/bin/designer.exe" ]; then
	echo -------------------------------------------------
	echo "qt-everywhere-opensource-src-4.8.5 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compiling qt4 32Bit\007"
		wget -c http://download.qt-project.org/official_releases/qt/4.8/4.8.5/qt-everywhere-opensource-src-4.8.5.zip
		unzip -o qt-everywhere-opensource-src-4.8.5.zip
		cd qt-everywhere-opensource-src-4.8.5
		
		sed -i 's/QMAKE_LFLAGS		=/QMAKE_LFLAGS		= -static -static-libgcc -static-libstdc++/' "mkspecs/win32-g++/qmake.conf"
		sed -i 's/LFLAGS      = -static-libgcc -s/LFLAGS      = -static -static-libgcc -static-libstdc++ -s/' "qmake/Makefile.win32-g++"
		sed -i 's/!contains(QT_CONFIG, no-jpeg):!contains(QT_CONFIG, jpeg):SUBDIRS += jpeg/!contains(QT_CONFIG, no-libjpeg):!contains(QT_CONFIG, libjpeg):SUBDIRS += jpeg/' "src/plugins/imageformats/imageformats.pro"
		sed -i 's/#if defined(Q_OS_WIN64) && !defined(Q_CC_GNU)/#if defined(Q_OS_WIN64)/' "src/corelib/tools/qsimd.cpp"
		sed -i 's/SUBDIRS += demos/#SUBDIRS += demos/' "projects.pro"
		./configure.exe -prefix $LOCALDESTDIR -platform win32-g++ -static -release -opensource -confirm-license -nomake examples -qt-libjpeg -sse
		mingw32-make -j $cpuCount
		mingw32-make install
		
		cp ./plugins/imageformats/*.a $LOCALDESTDIR/lib
		cp ./plugins/accessible/libqtaccessiblewidgets.a  $LOCALDESTDIR/lib
		sed -i 's/\.\.\\.\.\\lib\\pkgconfig\\//' lib/pkgconfig/*.pc
		sed -i 's/Libs: -L${libdir} -lQtGui/Libs: -L${libdir} -lcomctl32 -lqjpeg -lqtaccessiblewidgets -lQtGui/' "lib/pkgconfig/QtGui.pc"
		cp lib/pkgconfig/*.pc $PKG_CONFIG_PATH
		if [ -f "$LOCALDESTDIR/bin/designer.exe" ]; then
			echo -
			echo -------------------------------------------------
			echo "build qt-everywhere-opensource-src-4.8.5 done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build qt-everywhere-opensource-src-4.8.5 failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
fi

cd $LOCALBUILDDIR

if [ -f "vlc-git/bootstrap" ]; then
	echo -ne "\033]0;compiling vlc 32Bit\007"
	cd vlc-git
	oldHead=`git rev-parse HEAD`
	git pull origin master
	newHead=`git rev-parse HEAD`
	if [[ "$oldHead" != "$newHead" ]]; then
	make clean
	if [[ ! -f "configure" ]]; then
		./bootstrap
	fi 
	./configure --disable-libgcrypt --disable-a52 --host=i586-pc-mingw32msvc --disable-mad --enable-qt --disable-sdl LDFLAGS="-L$LOCALDESTDIR/lib -mthreads -static-libgcc -static-libstdc++"
	make -j $cpuCount
	
	sed -i "s/package-win-common: package-win-install build-npapi/package-win-common: package-win-install/" Makefile
	sed -i "s/.*cp .*builddir.*npapi-vlc.*//g" Makefile
	for file in ./*/vlc.exe; do
		rm $file # try to force a rebuild...
	done
	make package-win-common
	strip --strip-all ./vlc-2.2.0-git/*.dll
	strip --strip-all ./vlc-2.2.0-git/*.exe
	cp -rf ./vlc-2.2.0-git $LOCALDESTDIR/bin
	
	if [ -f "$LOCALDESTDIR/bin/vlc-2.2.0-git/vlc.exe" ]; then
			echo -
			echo -------------------------------------------------
			echo "build vlc done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build vlc failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
	else
		echo -------------------------------------------------
		echo "vlc is already up to date"
		echo -------------------------------------------------
	fi
	else
	echo -ne "\033]0;compiling vlc 32Bit\007"
		git clone https://github.com/videolan/vlc.git vlc-git
		cd vlc-git
		sed -i '/SYS=mingw32/ a\		CC="$CC -static-libgcc"' configure.ac
		sed -i '/		CC="$CC -static-libgcc"/ a\		CXX="$CXX -static-libgcc -static-libstdc++"' configure.ac
		sed -i 's/AC_DEFINE_UNQUOTED(VLC_COMPILE_HOST, "`hostname -f 2>\/dev\/null || hostname`", \[host which ran configure\])/AC_DEFINE_UNQUOTED(VLC_COMPILE_HOST, "`hostname`", \[host which ran configure\])/' configure.ac
		cp -v /usr/share/aclocal/* m4/
		if [[ ! -f "configure" ]]; then
			./bootstrap
		fi 
		./configure --disable-libgcrypt --disable-a52 --host=i586-pc-mingw32msvc --disable-mad --enable-qt --disable-sdl
		make -j $cpuCount
		
		sed -i "s/package-win-common: package-win-install build-npapi/package-win-common: package-win-install/" Makefile
		sed -i "s/.*cp .*builddir.*npapi-vlc.*//g" Makefile
		for file in ./*/vlc.exe; do
			rm $file # try to force a rebuild...
		done
		make package-win-common
		strip --strip-all ./vlc-2.2.0-git/*.dll
		strip --strip-all ./vlc-2.2.0-git/*.exe
		cp -rf ./vlc-2.2.0-git $LOCALDESTDIR/bin
		
		if [ -f "$LOCALDESTDIR/bin/vlc-2.2.0-git/vlc.exe" ]; then
				echo -
				echo -------------------------------------------------
				echo "build vlc done..."
				echo -------------------------------------------------
				echo -
				else
					echo -------------------------------------------------
					echo "build vlc failed..."
					echo "delete the source folder under '$LOCALBUILDDIR' and start again"
					read -p "first close the batch window, then the shell window"
					sleep 15
			fi
fi

sleep 5		