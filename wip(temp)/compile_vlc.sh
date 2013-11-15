cd $LOCALBUILDDIR

if [ -f "qt-everywhere-opensource-src-4.8.5/compile.done" ]; then
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
		sed -i 's/SUBDIRS += examples/#SUBDIRS += examples/' "projects.pro"
		sed -i 's/SUBDIRS += demos/#SUBDIRS += demos/' "projects.pro"

		./configure.exe -prefix $LOCALDESTDIR/qt4 -static -release -opensource -confirm-license -platform win32-g++
		mingw32-make -j8
		mingw32-make install
		strip --strip-all $LOCALDESTDIR/qt4/bin/*.exe
		
		echo "finish" > compile.done
		if [ -f "$LOCALDESTDIR/qt4/bin/designer.exe" ]; then
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