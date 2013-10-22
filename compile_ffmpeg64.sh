source /local64/etc/profile.local

# set CPU count global. This can be overwrite from the compiler script (ffmpeg-autobuild.bat)
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

if [[ $nonfree = "y" ]]; then
    extras="--enable-nonfree --enable-libfaac --enable-libfdk-aac"
  else
    if  [[ $nonfree = "n" ]]; then
      extras="" 
	fi
fi		

echo "-------------------------------------------------------------------------------"
echo 
echo "compile ffmpeg 64 bit"
echo 
echo "-------------------------------------------------------------------------------"

cd $LOCALBUILDDIR

if [ -f "ffmpeg-git/compile.done" ]; then
	echo -------------------------------------------------
	echo "ffmpeg-git is already compiled"
	echo -------------------------------------------------
	else
		if [ -d "$LOCALDESTDIR/include/libavutil" ]; then rm -r $LOCALDESTDIR/include/libavutil; fi
		if [ -d "$LOCALDESTDIR/include/libavcodec" ]; then rm -r $LOCALDESTDIR/include/libavcodec; fi
		if [ -d "$LOCALDESTDIR/include/libpostproc" ]; then rm -r $LOCALDESTDIR/include/libpostproc; fi
		if [ -d "$LOCALDESTDIR/include/libswresample" ]; then rm -r $LOCALDESTDIR/include/libswresample; fi
		if [ -d "$LOCALDESTDIR/include/libswscale" ]; then rm -r $LOCALDESTDIR/include/libswscale; fi
		if [ -d "$LOCALDESTDIR/include/libavdevice" ]; then rm -r $LOCALDESTDIR/include/libavdevice; fi
		if [ -d "$LOCALDESTDIR/include/libavfilter" ]; then rm -r $LOCALDESTDIR/include/libavfilter; fi
		if [ -d "$LOCALDESTDIR/include/libavformat" ]; then rm -r $LOCALDESTDIR/include/libavformat; fi
		if [ -f "$LOCALDESTDIR/lib/libavutil.a" ]; then rm -r $LOCALDESTDIR/lib/libavutil.a; fi
		if [ -f "$LOCALDESTDIR/lib/libswresample.a" ]; then rm -r $LOCALDESTDIR/lib/libswresample.a; fi
		if [ -f "$LOCALDESTDIR/lib/libswscale.a" ]; then rm -r $LOCALDESTDIR/lib/libswscale.a; fi
		if [ -f "$LOCALDESTDIR/lib/libavcodec.a" ]; then rm -r $LOCALDESTDIR/lib/libavcodec.a; fi
		if [ -f "$LOCALDESTDIR/lib/libavdevice.a" ]; then rm -r $LOCALDESTDIR/lib/libavdevice.a; fi
		if [ -f "$LOCALDESTDIR/lib/libavfilter.a" ]; then rm -r $LOCALDESTDIR/lib/libavfilter.a; fi
		if [ -f "$LOCALDESTDIR/lib/libavformat.a" ]; then rm -r $LOCALDESTDIR/lib/libavformat.a; fi
		if [ -f "$LOCALDESTDIR/lib/libpostproc.a" ]; then rm -r $LOCALDESTDIR/lib/libpostproc.a; fi
		if [ -f "$LOCALDESTDIR/lib/pkgconfig/libavcodec.pc" ]; then rm -r $LOCALDESTDIR/lib/pkgconfig/libavcodec.pc; fi
		if [ -f "$LOCALDESTDIR/lib/pkgconfig/libavutil.pc" ]; then rm -r $LOCALDESTDIR/lib/pkgconfig/libavutil.pc; fi
		if [ -f "$LOCALDESTDIR/lib/pkgconfig/libpostproc.pc" ]; then rm -r $LOCALDESTDIR/lib/pkgconfig/libpostproc.pc; fi
		if [ -f "$LOCALDESTDIR/lib/pkgconfig/libswresample.pc" ]; then rm -r $LOCALDESTDIR/lib/pkgconfig/libswresample.pc; fi
		if [ -f "$LOCALDESTDIR/lib/pkgconfig/libswscale.pc" ]; then rm -r $LOCALDESTDIR/lib/pkgconfig/libswscale.pc; fi
		if [ -f "$LOCALDESTDIR/lib/pkgconfig/libavdevice.pc" ]; then rm -r $LOCALDESTDIR/lib/pkgconfig/libavdevice.pc; fi
		if [ -f "$LOCALDESTDIR/lib/pkgconfig/libavfilter.pc" ]; then rm -r $LOCALDESTDIR/lib/pkgconfig/libavfilter.pc; fi
		if [ -f "$LOCALDESTDIR/lib/pkgconfig/libavformat.pc" ]; then rm -r $LOCALDESTDIR/lib/pkgconfig/libavformat.pc; fi
		
		git clone https://github.com/FFmpeg/FFmpeg.git ffmpeg-git
		cd ffmpeg-git
		./configure --arch=x86_64 --prefix=$LOCALDESTDIR --extra-cflags=-DPTW32_STATIC_LIB --disable-debug --enable-gpl --enable-version3 --enable-postproc --enable-w32threads --enable-runtime-cpudetect --enable-memalign-hack --disable-shared --enable-static --enable-avfilter --enable-bzlib --enable-zlib --enable-librtmp --enable-gnutls --enable-avisynth --enable-libbluray --enable-libopenjpeg --enable-fontconfig --enable-libfreetype --enable-libass --enable-libgsm --enable-libmp3lame --enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libvo-amrwbenc --enable-libutvideo --enable-libspeex --enable-libtheora --enable-libvorbis --enable-libvo-aacenc --enable-libopus --enable-libvpx --enable-libxavs --enable-libx264 --enable-libxvid $extras
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		
		if [ -f "$LOCALDESTDIR/bin/ffmpeg.exe" ]; then
			echo -
			echo -------------------------------------------------
			echo "build ffmpeg done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build ffmpeg failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
fi		

sleep 5