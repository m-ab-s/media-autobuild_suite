source /local32/etc/profile.local

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
    extras="--enable-nonfree --enable-libfdk-aac"
  else
    if  [[ $nonfree = "n" ]]; then
      extras="" 
	fi
fi		

echo "-------------------------------------------------------------------------------"
echo 
echo "compile ffmpeg 32 bit"
echo 
echo "-------------------------------------------------------------------------------"
if [ -f "ffmpeg-2.0.1/compile.done" ]; then
	echo ----------------------------------
	echo "ffmpeg-2.0.1 is already compiled"
	echo ----------------------------------
	else 
		cd $LOCALBUILDDIR
#cd $LOCALBUILDDIR
#if [ -f "ffmpeg-git/configure" ]; then
#	cd ffmpeg-git
#    echo " updating ffmpeg"
#    git pull https://github.com/FFmpeg/FFmpeg.git || exit 1
#	else 
#		git clone https://github.com/FFmpeg/FFmpeg.git ffmpeg-git
#		cd ffmpeg-git
#  fi
		wget -c http://ffmpeg.org/releases/ffmpeg-2.0.1.tar.gz
		tar xf ffmpeg-2.0.1.tar.gz
		cd ffmpeg-2.0.1
		./configure --prefix=$LOCALDESTDIR --extra-cflags=-DPTW32_STATIC_LIB --enable-gpl --enable-version3 --enable-postproc --enable-w32threads --enable-runtime-cpudetect --enable-memalign-hack --enable-avfilter --enable-bzlib --enable-zlib --enable-avisynth --enable-libgsm --enable-libmp3lame --enable-libspeex --enable-libtheora --enable-libvorbis --enable-libx264 --enable-libxvid --disable-debug $extras
		make -j $cpuCount
		make install
				echo "finish" > compile.done
		cd $LOCALBUILDDIR
		rm ffmpeg-2.0.1.tar.gz
fi	