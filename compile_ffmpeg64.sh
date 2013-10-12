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
		git clone https://github.com/FFmpeg/FFmpeg.git ffmpeg-git
		cd ffmpeg-git
		./configure --arch=x86_64 --prefix=$LOCALDESTDIR --extra-cflags=-DPTW32_STATIC_LIB --disable-debug --enable-gpl --enable-version3 --enable-postproc --enable-w32threads --enable-runtime-cpudetect --enable-memalign-hack --disable-shared --enable-static --enable-avfilter --enable-bzlib --enable-zlib --enable-avisynth --enable-libbluray --enable-fontconfig --enable-libfreetype --enable-libass --enable-libgsm --enable-libmp3lame --enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libvo-amrwbenc --enable-libspeex --enable-libtheora --enable-libvorbis --enable-libvo-aacenc --enable-libvpx --enable-libopus --enable-libx264 --enable-libxvid $extras
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