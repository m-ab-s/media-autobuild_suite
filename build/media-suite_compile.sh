#!/bin/bash

cpuCount=1
compile="false"
buildFFmpeg="false"
newFfmpeg="no"
FFMPEG_BASE_OPTS="--disable-debug --enable-gpl --enable-avisynth --pkg-config-flags=--static"
FFMPEG_DEFAULT_OPTS="--enable-gnutls --enable-frei0r --enable-libbluray --enable-libcaca \
--enable-libass --enable-libgsm --enable-libilbc --enable-libmodplug --enable-libmp3lame \
--enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libvo-amrwbenc --enable-libschroedinger \
--enable-libsoxr --enable-libtwolame --enable-libspeex --enable-libtheora --enable-libvorbis \
--enable-libopus --enable-libvidstab --enable-libxavs --enable-libxvid --enable-libtesseract \
--enable-libzvbi --enable-libdcadec --enable-libbs2b --enable-libmfx --enable-libcdio --enable-libfreetype \
--enable-fontconfig --enable-libfribidi --enable-opengl --enable-libvpx --enable-libx264 --enable-libx265 \
--enable-libkvazaar --enable-libwebp --enable-decklink --enable-libgme --enable-librubberband \
--disable-w32threads \
--enable-nonfree --enable-nvenc --enable-libfdk-aac --enable-openssl"
[[ ! -f "$LOCALBUILDDIR/last_run" ]] \
    && printf "#!/bin/bash\nbash $LOCALBUILDDIR/media-suite_compile.sh $*" > "$LOCALBUILDDIR/last_run"
printf "\nBuild start: $(date +"%F %T %z")\n" >> $LOCALBUILDDIR/newchangelog

while true; do
  case $1 in
--cpuCount=* ) cpuCount="${1#*=}"; shift ;;
--build32=* ) build32="${1#*=}"; shift ;;
--build64=* ) build64="${1#*=}"; shift ;;
--mp4box=* ) mp4box="${1#*=}"; shift ;;
--rtmpdump=* ) rtmpdump="${1#*=}"; shift ;;
--vpx=* ) vpx="${1#*=}"; shift ;;
--x264=* ) x264="${1#*=}"; shift ;;
--x265=* ) x265="${1#*=}"; shift ;;
--other265=* ) other265="${1#*=}"; shift ;;
--flac=* ) flac="${1#*=}"; shift ;;
--mediainfo=* ) mediainfo="${1#*=}"; shift ;;
--sox=* ) sox="${1#*=}"; shift ;;
--ffmpeg=* ) ffmpeg="${1#*=}"; shift ;;
--ffmpegUpdate=* ) ffmpegUpdate="${1#*=}"; shift ;;
--ffmpegChoice=* ) ffmpegChoice="${1#*=}"; shift ;;
--mplayer=* ) mplayer="${1#*=}"; shift ;;
--mpv=* ) mpv="${1#*=}"; shift ;;
--deleteSource=* ) deleteSource="${1#*=}"; shift ;;
--nonfree=* ) nonfree="${1#*=}"; shift ;;
--stripping* ) stripping="${1#*=}"; shift ;;
--packing* ) packing="${1#*=}"; shift ;;
--xpcomp=* ) xpcomp="${1#*=}"; shift ;;
    -- ) shift; break ;;
    -* ) echo "Error, unknown option: '$1'."; exit 1 ;;
    * ) break ;;
  esac
done

[[ -f $LOCALBUILDDIR/media-suite_helper.sh ]] && source $LOCALBUILDDIR/media-suite_helper.sh

buildProcess() {
[[ -f "$HOME"/custom_build_options ]] &&
    echo "importing custom build options (unsupported)" && source "$HOME"/custom_build_options

cd $LOCALBUILDDIR
echo "-------------------------------------------------------------------------------"
echo
echo "compile global tools $bits"
echo
echo "-------------------------------------------------------------------------------"

do_getFFmpegConfig

if do_checkForOptions "--enable-libopenjpeg"; then
    cd $LOCALBUILDDIR
    do_vcs "https://github.com/libjpeg-turbo/libjpeg-turbo.git" libjpegturbo lib/libjpeg.a
    if [[ $compile = "true" ]]; then
        if [[ -f $LOCALDESTDIR/lib/libjpeg.a ]]; then
            rm -f $LOCALDESTDIR/include/j{config,error,morecfg,peglib}.h
            rm -f $LOCALDESTDIR/lib/libjpeg.{l,}a $LOCALDESTDIR/bin-global/{c,d}jpeg.exe
            rm -f $LOCALDESTDIR/bin-global/jpegtran.exe $LOCALDESTDIR/bin-global/{rd,wr}jpgcom.exe
        fi
        do_patch "libjpegturbo-0001-Fix-header-conflicts-with-MinGW.patch" am
        do_patch "libjpegturbo-0002-Only-compile-libraries.patch" am
        do_cmakeinstall -DWITH_TURBOJPEG=off -DWITH_JPEG8=on -DENABLE_SHARED=off
        do_checkIfExist libjpegturbo-git libjpeg.a
    fi

    cd $LOCALBUILDDIR
    do_vcs "https://github.com/uclouvain/openjpeg.git" libopenjp2
    if [[ $compile = "true" ]]; then
        if [[ -f $LOCALDESTDIR/lib/libopenmj2.a ]]; then
            rm -rf $LOCALDESTDIR/include/openjpeg{-2.1,.h} $LOCALDESTDIR/lib/openjpeg-2.1
            rm -f $LOCALDESTDIR/lib/libopenjp{2,wl}.a $LOCALDESTDIR/lib/libopenmj2.a
            rm -f $LOCALDESTDIR/lib/pkgconfig/libopenjp{2,wl}.pc
            rm -f $LOCALDESTDIR/bin-global/opj_*.exe
        fi
        do_patch "openjpeg-0001-Only-compile-libraries.patch" am
        do_cmakeinstall -DBUILD_MJ2=on
        # ffmpeg needs this specific openjpeg.h
        cp ../src/lib/openmj2/openjpeg.h $LOCALDESTDIR/include/
        do_checkIfExist libopenjp2-git libopenmj2.a
    fi
fi

if do_checkForOptions "--enable-libass --enable-libfreetype --enable-fontconfig --enable-libfribidi" ||
    [[ "$mpv" = "y" || "$mplayer" = "y" ]]; then
    rm -rf $LOCALDESTDIR/include/freetype2 $LOCALDESTDIR/bin-global/freetype-config
    rm -rf $LOCALDESTDIR/lib/libfreetype.{l,}a $LOCALDESTDIR/lib/pkgconfig/freetype2.pc

    rm -rf $LOCALDESTDIR/include/fontconfig $LOCALDESTDIR/bin-global/fc-*
    rm -rf $LOCALDESTDIR/lib/libfontconfig.{l,}a $LOCALDESTDIR/lib/pkgconfig/fontconfig.pc

    rm -rf $LOCALDESTDIR/include/fribidi $LOCALDESTDIR/bin-global/fribidi.exe
    rm -rf $LOCALDESTDIR/lib/libfribidi.{l,}a $LOCALDESTDIR/lib/pkgconfig/fribidi.pc

    rm -rf $LOCALBUILDDIR/harfbuzz-git
    rm -rf $LOCALDESTDIR/include/harfbuzz
    rm -rf $LOCALDESTDIR/lib/{libharfbuzz.{l,}a,pkgconfig/harfbuzz.pc}
    do_pacman_install "freetype fontconfig fribidi harfbuzz python2-lxml"
    do_pacman_remove "ragel"

    # fix iconv problems with harfbuzz/libass due to missing lib in mingw's glib pkgconfig
    grep -q "liconv" "$MINGW_PREFIX"/lib/pkgconfig/glib-2.0.pc ||
        sed -i 's/-lintl/& -liconv/g' "$MINGW_PREFIX"/lib/pkgconfig/glib-2.0.pc
fi

if ! do_checkForOptions "--disable-sdl --disable-ffplay"; then
    rm -rf $LOCALDESTDIR/include/SDL $LOCALDESTDIR/bin-global/sdl-config
    rm -rf $LOCALDESTDIR/lib/libSDL{,main}.{l,}a $LOCALDESTDIR/lib/pkgconfig/sdl.pc
    do_pacman_install "SDL"
    sed -i "s/-mwindows//" "$MINGW_PREFIX/bin/sdl-config"
fi

#----------------------
# crypto engine
#----------------------

if do_checkForOptions "--enable-gnutls"; then
    rm -f $LOCALDESTDIR/include/libgcrypt.h
    rm -f $LOCALDESTDIR/bin-global/{dumpsexp,hmac256,mpicalc}.exe
    rm -f $LOCALDESTDIR/lib/libgcrypt.{l,}a $LOCALDESTDIR/bin-global/libgcrypt-config

    rm -rf $LOCALDESTDIR/include/nettle $LOCALDESTDIR/bin-global/{nettle-*,{sexp,pkcs1}-conv}.exe
    rm -rf $LOCALDESTDIR/lib/libnettle.a $LOCALDESTDIR/lib/pkgconfig/nettle.pc

    do_pacman_install "libgcrypt nettle"

    if do_pkgConfig "gnutls = 3.4.5"; then
        cd $LOCALBUILDDIR
        do_wget "ftp://ftp.gnutls.org/gcrypt/gnutls/v3.4/gnutls-3.4.5.tar.xz"
        [[ -d build ]] && rm -rf build
        mkdir build && cd build
        if [[ -f $LOCALDESTDIR/lib/libgnutls.a ]]; then
            rm -rf $LOCALDESTDIR/include/gnutls $LOCALDESTDIR/lib/libgnutls*
            rm -f $LOCALDESTDIR/lib/pkgconfig/gnutls.pc
            rm -f $LOCALDESTDIR/bin-global/{gnutls-*,{psk,cert,srp,ocsp}tool}.exe
        fi
        ../configure --prefix=$LOCALDESTDIR --disable-shared --build=$targetBuild --disable-cxx \
            --disable-doc --disable-tools --disable-tests --without-p11-kit --disable-rpath \
            --disable-libdane --without-idn --without-tpm --enable-local-libopts --disable-guile
        sed -i 's/-lgnutls *$/-lgnutls -lnettle -lhogweed -lcrypt32 -lws2_32 -lz -lgmp -lintl -liconv/' \
        lib/gnutls.pc
        do_makeinstall
        do_checkIfExist gnutls-3.4.5 libgnutls.a
    fi
fi

if [[ $rtmpdump = "y" ]] || do_checkForOptions "--enable-librtmp"; then
    cd $LOCALBUILDDIR
    do_vcs "git://repo.or.cz/rtmpdump.git" librtmp bin-video/rtmpdump.exe
    extracommands=""
    req=""
    [[ -f "$LOCALDESTDIR/lib/pkgconfig/librtmp.pc" ]] && req=$(pkg-config --print-requires librtmp)
    if do_checkForOptions "--enable-gnutls"; then
        crypto=GNUTLS
        pc=gnutls
    else
        crypto=OPENSSL
        pc=libssl
    fi
    if [[ $compile = "true" ]] || [[ $req != *$pc* ]]; then
        if [[ -f "$LOCALDESTDIR/lib/librtmp.a" ]]; then
            rm -rf $LOCALDESTDIR/include/librtmp
            rm -f $LOCALDESTDIR/lib/librtmp.a $LOCALDESTDIR/lib/pkgconfig/librtmp.pc
            rm -f $LOCALDESTDIR/bin-video/rtmp{dump,suck,srv,gw}.exe
        fi
        [[ -f "librtmp/librtmp.a" ]] && make clean
        make XCFLAGS="$CFLAGS -I$MINGW_PREFIX/include" XLDFLAGS="$LDFLAGS" SHARED= \
            SYS=mingw prefix=$LOCALDESTDIR bindir=$LOCALDESTDIR/bin-video \
            sbindir=$LOCALDESTDIR/bin-video mandir=$LOCALDESTDIR/share/man \
            CRYPTO=$crypto LIB_${crypto}="$(pkg-config --static --libs $pc) -lz" install
        do_checkIfExist librtmp-git librtmp.a
        unset crypto pc req
    fi
else
    [[ -f "$LOCALDESTDIR/lib/pkgconfig/librtmp.pc" ]] || do_removeOption "--enable-librtmp"
fi

if [[ $sox = "y" ]]; then
    if [[ -f "$LOCALDESTDIR/lib/libgnurx.a" ]]; then
        echo -------------------------------------------------
        echo "libgnurx-2.5.1 is already compiled"
        echo -------------------------------------------------
    else
        cd $LOCALBUILDDIR
        echo -ne "\033]0;compile libgnurx $bits\007"
        do_wget_sf "mingw/Other/UserContributed/regex/mingw-regex-2.5.1/mingw-libgnurx-2.5.1-src.tar.gz" \
            mingw-libgnurx-2.5.1.tar.gz
        [[ -f "libgnurx.a" ]] && make distclean
        [[ -f "$LOCALDESTDIR/lib/libgnurx.a" ]] &&
            rm -f $LOCALDESTDIR/lib/lib{gnurx,regex}.a $LOCALDESTDIR/include/regex.h
        do_patch "libgnurx-1-additional-makefile-rules.patch"
        ./configure --prefix=$LOCALDESTDIR --disable-shared
        do_makeinstall -f Makefile.mxe install-static
        do_checkIfExist mingw-libgnurx-2.5.1 libgnurx.a
    fi

    if [[ -f $LOCALDESTDIR/bin-global/file.exe ]] &&
        [[ $(file.exe --version) = *"file.exe-5.25"* ]]; then
        echo -------------------------------------------------
        echo "file-5.24[libmagic] is already compiled"
        echo -------------------------------------------------
    else
        cd $LOCALBUILDDIR
        echo -ne "\033]0;compile file $bits\007"
        do_wget "https://fossies.org/linux/misc/file-5.25.tar.gz"
        [[ -f "src/.libs/libmagic.a" ]] && make distclean
        if [[ -f "$LOCALDESTDIR/lib/libmagic.a" ]]; then
            rm -rf $LOCALDESTDIR/include/magic.h $LOCALDESTDIR/bin-global/file.exe
            rm -rf $LOCALDESTDIR/lib/libmagic.{l,}a
        fi
        do_patch "file-1-fixes.patch"
        do_generic_confmakeinstall global CFLAGS=-DHAVE_PREAD
        do_checkIfExist file-5.25 libmagic.a
    fi
fi

if do_checkForOptions "--enable-libwebp"; then
    cd $LOCALBUILDDIR
    do_vcs "https://chromium.googlesource.com/webm/libwebp" libwebp
    if [[ $compile = "true" ]]; then
        [[ -f configure ]] || ./autogen.sh
        [[ -f Makefile ]] && make distclean
        if [[ -f $LOCALDESTDIR/lib/libwebp.a ]]; then
            rm -rf $LOCALDESTDIR/include/webp
            rm -f $LOCALDESTDIR/lib/libwebp{,demux,mux,decoder}.{,l}a
            rm -f $LOCALDESTDIR/lib/pkgconfig/libwebp{,decoder,demux,mux}.pc
            rm -f $LOCALDESTDIR/bin-global/{{c,d}webp,gif2webp,webpmux}.exe
        fi
        do_generic_confmakeinstall global --enable-swap-16bit-csp --enable-experimental \
            --enable-libwebpmux --enable-libwebpdemux --enable-libwebpdecoder \
            LIBS="$(pkg-config --static --libs libtiff-4)" LIBPNG_CONFIG="pkg-config --static" \
            LDFLAGS="$LDFLAGS -static -static-libgcc"
        do_checkIfExist libwebp-git libwebp.a
    fi
fi

if do_checkForOptions "--enable-libtesseract"; then
    do_pacman_remove "tesseract-ocr"
    cd $LOCALBUILDDIR
    if do_pkgConfig "lept = 1.72"; then
        do_wget "http://www.leptonica.com/source/leptonica-1.72.tar.gz"
        [[ -f Makefile ]] && make distclean
        if [[ -f $LOCALDESTDIR/lib/liblept.a ]]; then
            rm -rf $LOCALDESTDIR/include/leptonica
            rm -f $LOCALDESTDIR/lib/liblept.{,l}a $LOCALDESTDIR/lib/pkgconfig/lept.pc
        fi
        do_generic_confmakeinstall --disable-programs --without-libopenjpeg --without-libwebp
        do_checkIfExist leptonica-1.72 liblept.a
    fi

    cd $LOCALBUILDDIR
    do_vcs "https://github.com/tesseract-ocr/tesseract.git" tesseract
    if [[ $compile = "true" ]]; then
        [[ -f configure ]] || ./autogen.sh
        [[ -f config.log ]] && make distclean
        if [[ -f $LOCALDESTDIR/lib/libtesseract.a ]]; then
            rm -rf $LOCALDESTDIR/include/tesseract
            rm -f $LOCALDESTDIR/lib/libtesseract.{,l}a $LOCALDESTDIR/lib/pkgconfig/tesseract.pc
            rm -f $LOCALDESTDIR/bin-global/tesseract.exe
        fi
        sed -i 's# @OPENCL_LIB@# -lstdc++#' tesseract.pc.in
        do_generic_confmakeinstall global --disable-graphics --disable-tessdata-prefix \
            LIBLEPT_HEADERSDIR=$LOCALDESTDIR/include LDFLAGS="$LDFLAGS -static -static-libgcc" \
            LIBS="$(pkg-config --static --libs lept)" --datadir=$LOCALDESTDIR/bin-global
        if [[ ! -f $LOCALDESTDIR/bin-global/tessdata/eng.traineddata ]]; then
            mkdir -p $LOCALDESTDIR/bin-global/tessdata
            pushd $LOCALDESTDIR/bin-global/tessdata > /dev/null
            do_wget "https://github.com/tesseract-ocr/tessdata/raw/master/eng.traineddata"
            printf "%s\n" "You can get more language data here:"\
                   "https://github.com/tesseract-ocr/tessdata/blob/master/"\
                   "Just download <lang you want>.traineddata and copy it to this directory."\
                    > need_more_languages.txt
            popd > /dev/null
        fi
        do_checkIfExist tesseract-git libtesseract.a
    fi
fi

if do_checkForOptions "--enable-librubberband" && do_pkgConfig "rubberband = 1.8.1"; then
    cd $LOCALBUILDDIR
    if [[ ! -d rubberband-master ]] || [[ -d rubberband-master ]] &&
    { [[ $build32 = "yes" && ! -f rubberband-master/build_successful32bit ]] ||
      [[ $build64 = "yes" && ! -f rubberband-master/build_successful64bit ]]; }; then
        rm -rf rubberband-master{,.zip} rubberband-git
        do_wget "https://github.com/lachs0r/rubberband/archive/master.zip" rubberband-master.zip
    fi
    cd rubberband-master
    [[ -f $LOCALDESTDIR/lib/librubberband.a ]] && make PREFIX=$LOCALDESTDIR uninstall
    [[ -f "lib/librubberband.a" ]] && make clean
    make PREFIX=$LOCALDESTDIR install-static
    do_checkIfExist rubberband-master librubberband.a
fi

echo "-------------------------------------------------------------------------------"
echo
echo "compile global tools $bits done..."
echo
echo "-------------------------------------------------------------------------------"

echo "-------------------------------------------------------------------------------"
echo
echo "compile audio tools $bits"
echo
echo "-------------------------------------------------------------------------------"

if do_checkForOptions "--enable-libdcadec"; then
    rm -rf $LOCALBUILDDIR/dcadec-git
    rm -rf $LOCALDESTDIR/include/libdcadec
    rm -f $LOCALDESTDIR/lib/libdcadec.a
    rm -f $LOCALDESTDIR/lib/pkgconfig/dcadec.pc
    rm -f $LOCALDESTDIR/bin-audio/dcadec.exe
    do_pacman_install "dcadec-git"
fi

if do_checkForOptions "--enable-libilbc"; then
    cd $LOCALBUILDDIR
    do_vcs "https://github.com/TimothyGu/libilbc.git" libilbc
    if [[ $compile = "true" ]]; then
        [[ -f configure ]] && make distclean || autoreconf -fiv
        if [[ -f $LOCALDESTDIR/lib/libilbc.a ]]; then
            rm -rf $LOCALDESTDIR/include/ilbc.h
            rm -rf $LOCALDESTDIR/lib/libilbc.{l,}a $LOCALDESTDIR/lib/pkgconfig/libilbc.pc
        fi
        do_generic_confmakeinstall
        do_checkIfExist libilbc-git libilbc.a
    fi
fi

if [[ $flac = "y" || $sox = "y" ]] ||
    do_checkForOptions "--enable-libtheora --enable-libvorbis --enable-libspeex"; then
    rm -rf $LOCALDESTDIR/include/ogg $LOCALDESTDIR/share/aclocal/ogg.m4
    rm -rf $LOCALDESTDIR/lib/libogg.{l,}a $LOCALDESTDIR/lib/pkgconfig/ogg.pc
    do_pacman_install "libogg"
fi

if [[ $sox = "y" ]] || do_checkForOptions "--enable-libvorbis --enable-libtheora"; then
    rm -rf $LOCALDESTDIR/include/vorbis $LOCALDESTDIR/share/aclocal/vorbis.m4
    rm -f $LOCALDESTDIR/lib/libvorbis{,enc,file}.{l,}a
    rm -f $LOCALDESTDIR/lib/pkgconfig/vorbis{,enc,file}.pc
    do_pacman_install "libvorbis"
fi

if [[ $sox = "y" ]] || do_checkForOptions "--enable-libopus"; then
    rm -rf $LOCALDESTDIR/include/opus
    rm -rf $LOCALDESTDIR/lib/libopus.{l,}a $LOCALDESTDIR/lib/pkgconfig/opus.pc

    rm -rf $LOCALDESTDIR/include/opus/opusfile.h $LOCALDESTDIR/lib/libopus{file,url}.{l,}a
    rm -rf $LOCALDESTDIR/lib/pkgconfig/opus{file,url}.pc
    do_pacman_install "opus opusfile"
fi

if { [[ $sox = "y" ]] || do_checkForOptions "--enable-libspeex"; } && do_pkgConfig "speex = 1.2rc2"; then
    cd $LOCALBUILDDIR
    do_wget "http://downloads.xiph.org/releases/speex/speex-1.2rc2.tar.gz"
    [[ -f "libspeex/.libs/libspeex.a" ]] && make distclean
    if [[ -f $LOCALDESTDIR/lib/libspeex.a ]]; then
        rm -rf $LOCALDESTDIR/include/speex $LOCALDESTDIR/bin-audio/speex{enc,dec}.exe
        rm -rf $LOCALDESTDIR/lib/libspeex.{l,}a $LOCALDESTDIR/lib/pkgconfig/speex.pc
    fi
    do_patch speex-mingw-winmm.patch
    do_generic_confmakeinstall audio --enable-vorbis-psy --enable-binaries
    do_checkIfExist speex-1.2rc2 libspeex.a
fi

if [[ $flac = "y" || $sox = "y" ]] &&
    { [[ ! -f $LOCALDESTDIR/bin-audio/flac.exe ]] || do_pkgConfig "flac = 1.3.1"; } then
    cd $LOCALBUILDDIR
    do_wget "http://downloads.xiph.org/releases/flac/flac-1.3.1.tar.xz"
    [[ -f "src/libFLAC/.libs/libFLAC.a" ]] && make distclean
    if [[ -f $LOCALDESTDIR/lib/libFLAC.a ]]; then
        rm -rf $LOCALDESTDIR/include/FLAC{,++} $LOCALDESTDIR/bin-audio/{meta,}flac.exe
        rm -rf $LOCALDESTDIR/lib/libFLAC.{l,}a $LOCALDESTDIR/lib/pkgconfig/flac{,++}.pc
    fi
    do_generic_confmakeinstall audio --disable-xmms-plugin --disable-doxygen-docs
    do_checkIfExist flac-1.3.1 libFLAC.a
fi

if do_checkForOptions "--enable-libvo-aacenc" && do_pkgConfig "vo-aacenc = 0.1.3"; then
    cd $LOCALBUILDDIR
    do_wget_sf "opencore-amr/vo-aacenc/vo-aacenc-0.1.3.tar.gz"
    [[ -f ".libs/libvo-aacenc.a" ]] && make distclean
    if [[ -f $LOCALDESTDIR/lib/libvo-aacenc.a ]]; then
        rm -rf $LOCALDESTDIR/include/vo-aacenc
        rm -rf $LOCALDESTDIR/lib/libvo-aacenc.{l,}a $LOCALDESTDIR/lib/pkgconfig/vo-aacenc.pc
    fi
    do_generic_confmakeinstall
    do_checkIfExist vo-aacenc-0.1.3 libvo-aacenc.a
fi

if do_checkForOptions "--enable-libopencore-amr(wb|nb)"; then
    rm -rf $LOCALDESTDIR/include/opencore-amr{nb,wb}
    rm -f $LOCALDESTDIR/lib/libopencore-amr{nb,wb}.{l,}a
    rm -f $LOCALDESTDIR/lib/pkgconfig/opencore-amr{nb,wb}.pc
    do_pacman_install "opencore-amr"
fi

if do_checkForOptions "--enable-libvo-amrwbenc" && do_pkgConfig "vo-amrwbenc = 0.1.2"; then
    cd $LOCALBUILDDIR
    do_wget_sf "opencore-amr/vo-amrwbenc/vo-amrwbenc-0.1.2.tar.gz"
    [[ -f ".libs/libvo-amrwbenc.a" ]] && make distclean
    if [[ -f $LOCALDESTDIR/lib/libvo-amrwbenc.a ]]; then
        rm -rf $LOCALDESTDIR/include/vo-amrwbenc
        rm -rf $LOCALDESTDIR/lib/libvo-amrwbenc.{l,}a $LOCALDESTDIR/lib/pkgconfig/vo-amrwbenc.pc
    fi
    do_generic_confmakeinstall
    do_checkIfExist vo-amrwbenc-0.1.2 libvo-amrwbenc.a
fi

if do_checkForOptions "--enable-libfdk-aac"; then
    cd $LOCALBUILDDIR
    do_vcs "https://github.com/mstorsjo/fdk-aac" fdk-aac
    if [[ $compile = "true" ]]; then
        [[ -f configure ]] && make distclean || ./autogen.sh
        if [[ -f $LOCALDESTDIR/lib/libfdk-aac.a ]]; then
            rm -rf $LOCALDESTDIR/include/fdk-aac
            rm -f $LOCALDESTDIR/lib/libfdk-aac.{l,}a $LOCALDESTDIR/lib/pkgconfig/fdk-aac.pc
        fi
        CXXFLAGS+=" -O2 -fno-exceptions -fno-rtti" do_generic_confmakeinstall
        do_checkIfExist fdk-aac-git libfdk-aac.a
    fi

    cd $LOCALBUILDDIR
    do_vcs "https://github.com/nu774/fdkaac" bin-fdk-aac bin-audio/fdkaac.exe
    if [[ $compile = "true" ]]; then
        [[ -f configure ]] && make distclean || autoreconf -fiv
        rm -f $LOCALDESTDIR/bin-audio/fdkaac.exe
        CXXFLAGS+=" -O2" do_generic_confmakeinstall audio
        do_checkIfExist bin-fdk-aac-git bin-audio/fdkaac.exe
    fi
fi

if do_checkForOptions "--enable-libfaac"; then
    if [[ -f $LOCALDESTDIR/bin-audio/faac.exe ]] &&
        [[ $(faac.exe) = *"FAAC 1.28"* ]]; then
        echo -------------------------------------------------
        echo "faac-1.28 is already compiled"
        echo -------------------------------------------------
    else
        cd $LOCALBUILDDIR
        echo -ne "\033]0;compile faac $bits\007"
        do_wget_sf "faac/faac-src/faac-1.28/faac-1.28.tar.bz2"
        [[ -f configure ]] && make distclean || sh bootstrap
        if [[ -f $LOCALDESTDIR/lib/libfaac.a ]]; then
            rm -f $LOCALDESTDIR/include/faac{,cfg}.h
            rm -f $LOCALDESTDIR/lib/libfaac.a $LOCALDESTDIR/bin-audio/faac.exe
        fi
        do_generic_confmakeinstall audio --without-mp4v2
        do_checkIfExist faac-1.28 libfaac.a
    fi
fi

if do_checkForOptions "--enable-libvorbis"; then
    if [[ -f $LOCALDESTDIR/bin-audio/oggenc.exe ]] &&
        [[ $(oggenc.exe --version) = *"vorbis-tools 1.4.0"* ]]; then
        echo -------------------------------------------------
        echo "vorbis-tools-1.4.0 is already compiled"
        echo -------------------------------------------------
    else
        cd $LOCALBUILDDIR
        echo -ne "\033]0;compile vorbis-tools $bits\007"
        do_wget "http://downloads.xiph.org/releases/vorbis/vorbis-tools-1.4.0.tar.gz"
        [[ -f "oggenc/oggenc.exe" ]] && make distclean
        [[ -f "$LOCALDESTDIR/bin-audio/oggenc.exe" ]] &&
            rm -f $LOCALDESTDIR/bin-audio/ogg{enc,dec}.exe
        do_generic_conf --disable-ogg123 --disable-vorbiscomment --disable-vcut --disable-ogginfo \
            $(do_checkForOptions "--enable-libspeex" || echo "--disable-speex") \
            $([[ $flac = "y" ]] || echo "--disable-flac")
        make -j $cpuCount
        [[ -f oggenc/oggenc.exe ]] && cp -f oggenc/oggenc.exe oggdec/oggdec.exe $LOCALDESTDIR/bin-audio/
        do_checkIfExist vorbis-tools-1.4.0 bin-audio/oggenc.exe
    fi
fi

if do_checkForOptions "--enable-libopus"; then
    if [[ -f $LOCALDESTDIR/bin-audio/opusenc.exe ]] &&
        [[ $(opusenc.exe --version) = *"opus-tools 0.1.9"* ]]; then
        echo -------------------------------------------------
        echo "opus-tools-0.1.9 is already compiled"
        echo -------------------------------------------------
    else
        cd $LOCALBUILDDIR
        echo -ne "\033]0;compile opus-tools $bits\007"
        do_wget "http://downloads.xiph.org/releases/opus/opus-tools-0.1.9.tar.gz"
        [[ -f "opusenc.exe" ]] && make distclean
        [[ -f "$LOCALDESTDIR/bin-audio/opusenc.exe" ]] &&
            rm -rf $LOCALDESTDIR/bin-audio/opus{dec,enc,info}.exe
        do_generic_confmakeinstall audio LDFLAGS="$LDFLAGS -static -static-libgcc -static-libstdc++" \
            $([[ $flac = "y" ]] || echo "--without-flac")
        do_checkIfExist opus-tools-0.1.9 bin-audio/opusenc.exe
    fi
fi

if do_checkForOptions "--enable-libsoxr" && do_pkgConfig "soxr = 0.1.2"; then
    cd $LOCALBUILDDIR
    do_wget_sf "soxr/soxr-0.1.2-Source.tar.xz"
    sed -i 's|NOT WIN32|UNIX|g' ./src/CMakeLists.txt
    if [[ -f $LOCALDESTDIR/lib/libsoxr.a ]]; then
        rm -rf $LOCALDESTDIR/include/soxr.h
        rm -f $LOCALDESTDIR/lib/libsoxr.a
        rm -f $LOCALDESTDIR/lib/pkgconfig/soxr.pc
    fi
    do_cmakeinstall -DWITH_OPENMP=off -DWITH_LSR_BINDINGS=off
    sed -i "/Name:.*/ i\prefix=$LOCALDESTDIR\n" $LOCALDESTDIR/lib/pkgconfig/soxr.pc
    do_checkIfExist soxr-0.1.2-Source libsoxr.a
fi

if do_checkForOptions "--enable-libmp3lame"; then
    if [[ -f $LOCALDESTDIR/bin-audio/lame.exe ]] &&
        [[ $(lame.exe 2>&1) = *"3.99.5"* ]]; then
        echo -------------------------------------------------
        echo "lame 3.99.5 is already compiled"
        echo -------------------------------------------------
    else
        cd $LOCALBUILDDIR
        echo -ne "\033]0;compiling lame $bits\007"
        do_wget_sf "lame/lame/3.99/lame-3.99.5.tar.gz"
        if grep "xmmintrin\.h" configure.in; then
            do_patch lame-fixes.patch
            autoreconf -fi
        fi
        [[ -f libmp3lame/.libs/libmp3lame.a ]] && make distclean
        if [[ -f $LOCALDESTDIR/lib/libmp3lame.a ]]; then
            rm -rf $LOCALDESTDIR/include/lame
            rm -f $LOCALDESTDIR/lib/libmp3lame.{l,}a $LOCALDESTDIR/bin-audio/lame.exe
        fi
        do_generic_confmakeinstall audio --disable-decoder
        do_checkIfExist lame-3.99.5 libmp3lame.a
    fi
fi

if do_checkForOptions "--enable-libgme"; then
    cd $LOCALBUILDDIR
    do_vcs "https://bitbucket.org/mpyne/game-music-emu.git" libgme
    if [[ $compile = "true" ]]; then
        if [[ -f $LOCALDESTDIR/lib/libgme.a ]]; then
            rm -rf $LOCALDESTDIR/include/gme
            rm -f $LOCALDESTDIR/lib/libgme.a
            rm -f $LOCALDESTDIR/lib/pkgconfig/libgme.pc
        fi
        do_cmakeinstall
        do_checkIfExist libgme-git libgme.a
    fi
fi

if do_checkForOptions "--enable-libtwolame"; then
    rm -rf $LOCALDESTDIR/include/twolame.h $LOCALDESTDIR/bin-audio/twolame.exe
    rm -rf $LOCALDESTDIR/lib/libtwolame.{l,}a $LOCALDESTDIR/lib/pkgconfig/twolame.pc
    do_pacman_install "twolame"
    do_addOption "--extra-cflags=-DLIBTWOLAME_STATIC"
fi

if do_checkForOptions "--enable-libbs2b" && do_pkgConfig "libbs2b = 3.1.0"; then
    cd $LOCALBUILDDIR
    do_wget_sf "bs2b/libbs2b/3.1.0/libbs2b-3.1.0.tar.bz2"
    [[ -f "src/.libs/libbs2b.a" ]] && make distclean
    if [[ -f "$LOCALDESTDIR/lib/libbs2b.a" ]]; then
        rm -rf $LOCALDESTDIR/include/bs2b $LOCALDESTDIR/bin-audio/bs2b*
        rm -rf $LOCALDESTDIR/lib/libbs2b.{l,}a $LOCALDESTDIR/lib/pkgconfig/libbs2b.pc
    fi
    do_patch "libbs2b-disable-sndfile.patch"
    do_patch "libbs2b-libs-only.patch"
    do_generic_confmakeinstall
    do_checkIfExist libbs2b-3.1.0 libbs2b.a
fi

if [[ $sox = "y" ]]; then
    cd $LOCALBUILDDIR
    do_vcs "https://github.com/erikd/libsndfile.git" sndfile
    if [[ $compile = "true" ]]; then
        [[ ! -f ./configure ]] && ./autogen.sh || make distclean
        if [[ -f $LOCALDESTDIR/lib/libsndfile.a ]]; then
            rm -f $LOCALDESTDIR/include/sndfile.{h,}h $LOCALDESTDIR/bin-audio/sndfile-*
            rm -f $LOCALDESTDIR/lib/libsndfile.{l,}a $LOCALDESTDIR/lib/pkgconfig/sndfile.pc
        fi
        do_generic_conf
        sed -i 's/ examples regtest tests programs//g' Makefile
        do_makeinstall
        do_checkIfExist sndfile-git libsndfile.a
    fi

    cd $LOCALBUILDDIR
    do_pacman_install "libmad"
    do_vcs "git://git.code.sf.net/p/sox/code" sox bin-audio/sox.exe
    if [[ $compile = "true" ]]; then
        sed -i 's|found_libgsm=yes|found_libgsm=no|g' configure.ac
        [[ -f configure ]] && make distclean || autoreconf -fiv
        if [[ -f $LOCALDESTDIR/bin-audio/sox.exe ]]; then
            rm -f $LOCALDESTDIR/include/sox.h $LOCALDESTDIR/bin-audio/sox.exe
            rm -f $LOCALDESTDIR/lib/libsox.{l,}a $LOCALDESTDIR/lib/pkgconfig/sox.pc
        fi
        do_generic_confmakeinstall audio CPPFLAGS='-DPCRE_STATIC' LIBS='-lpcre -lshlwapi -lz -lgnurx'
        do_checkIfExist sox-git bin-audio/sox.exe
    fi
fi

if do_checkForOptions "--enable-libmodplug"; then
    do_pacman_install "libmodplug"
    do_addOption "--extra-cflags=-DMODPLUG_STATIC"
fi

echo "-------------------------------------------------------------------------------"
echo
echo "compile audio tools $bits done..."
echo
echo "-------------------------------------------------------------------------------"

echo "-------------------------------------------------------------------------------"
echo
echo "compile video tools $bits"
echo
echo "-------------------------------------------------------------------------------"

if do_checkForOptions "--enable-libtheora"; then
    rm -rf $LOCALDESTDIR/include/theora $LOCALDESTDIR/lib/libtheora{,enc,dec}.{l,}a
    rm -rf $LOCALDESTDIR/lib/pkgconfig/theora{,enc,dec}.pc
    do_pacman_install "libtheora"
fi

if [[ ! $vpx = "n" ]]; then
    cd $LOCALBUILDDIR
    do_vcs "https://chromium.googlesource.com/webm/libvpx.git" vpx
    if [[ $compile = "true" ]] || [[ $vpx = "y" && ! -f "$LOCALDESTDIR/bin-video/vpxenc.exe" ]]; then
        if [[ -f $LOCALDESTDIR/lib/libvpx.a ]]; then
            rm -rf $LOCALDESTDIR/include/vpx $LOCALDESTDIR/bin-video/vpx{enc,dec}.exe
            rm -f $LOCALDESTDIR/lib/libvpx.a $LOCALDESTDIR/lib/pkgconfig/vpx.pc
        fi
        [[ -f libvpx.a ]] && make distclean
        [[ $bits = "32bit" ]] && target="x86-win32" || target="x86_64-win64"
        LDFLAGS+=" -static-libgcc -static" ./configure --target="${target}-gcc" \
            --disable-shared --enable-static --disable-unit-tests --disable-docs \
            --enable-postproc --enable-vp9-postproc --enable-runtime-cpu-detect \
            --enable-vp9-highbitdepth --prefix=$LOCALDESTDIR \
            $([[ $vpx = "l" ]] && echo "--disable-examples" || echo "--enable-vp10")
        sed -i 's/HAVE_GNU_STRIP=yes/HAVE_GNU_STRIP=no/g' "libs-${target}-gcc.mk"
        do_makeinstall
        [[ $vpx = "y"  && -f $LOCALDESTDIR/bin/vpxenc.exe ]] &&
            mv $LOCALDESTDIR/bin/vpx{enc,dec}.exe $LOCALDESTDIR/bin-video/ ||
            rm -f $LOCALDESTDIR/bin/vpx{enc,dec}.exe
        do_checkIfExist vpx-git libvpx.a
        buildFFmpeg="true"
        unset target
    fi
else
    pkg-config --exists vpx || do_removeOption "--enable-libvpx"
fi

if [[ $other265 = "y" ]] || do_checkForOptions "--enable-libkvazaar"; then
    cd $LOCALBUILDDIR
    do_vcs "https://github.com/ultravideo/kvazaar.git#commit=9051fbf" kvazaar bin-video/kvazaar.exe
    if [[ $compile = "true" ]]; then
        if [[ -f "$LOCALDESTDIR/lib/libkvazaar.a" ]]; then
            rm -f "$LOCALDESTDIR/include/kvazaar.h"
            rm -f "$LOCALDESTDIR/include/kvazaar_version.h"
            rm -f "$LOCALDESTDIR/lib/libkvazaar.a"
            rm -f "$LOCALDESTDIR/lib/pkgconfig/kvazaar.pc"
            rm -f "$LOCALDESTDIR/bin-video/kvazaar.exe"
        fi
        cd src
        if [[ -f intra.o ]]; then
            make clean
        fi
        if [[ "$bits" = "32bit" ]]; then
            make all lib-static ARCH=i686 -j $cpuCount
        else
            make all lib-static ARCH=x86_64 -j $cpuCount
        fi
        make install-{pc,prog,static} PREFIX=$LOCALDESTDIR BINDIR=$LOCALDESTDIR/bin-video
        do_checkIfExist kvazaar-git libkvazaar.a
    fi
else
    pkg-config --exists kvazaar || do_removeOption "--enable-libkvazaar"
fi

if [[ $mplayer = "y" ]] || [[ $mpv = "y" ]]; then
    cd $LOCALBUILDDIR
    do_vcs "git://git.videolan.org/libdvdread.git" dvdread
    if [[ $compile = "true" ]]; then
        [[ -f configure ]] && make distclean || autoreconf -fiv
        if [[ -f $LOCALDESTDIR/lib/libdvdread.a ]]; then
            rm -rf $LOCALDESTDIR/include/dvdread
            rm -rf $LOCALDESTDIR/lib/libdvdread.{l,}a $LOCALDESTDIR/lib/pkgconfig/dvdread.pc
        fi
        do_generic_confmakeinstall
        do_checkIfExist dvdread-git libdvdread.a
    fi
    grep -q 'ldl' $LOCALDESTDIR/lib/pkgconfig/dvdread.pc ||
        sed -i "/Libs:.*/ a\Libs.private: -ldl" $LOCALDESTDIR/lib/pkgconfig/dvdread.pc

    cd $LOCALBUILDDIR
    do_vcs "git://git.videolan.org/libdvdnav.git" dvdnav
    if [[ $compile = "true" ]]; then
        [[ -f configure ]] && make distclean || autoreconf -fiv
        if [[ -f $LOCALDESTDIR/lib/libdvdnav.a ]]; then
            rm -rf $LOCALDESTDIR/include/dvdnav
            rm -rf $LOCALDESTDIR/lib/libdvdnav.{l,}a $LOCALDESTDIR/lib/pkgconfig/dvdnav.pc
        fi
        do_generic_confmakeinstall
        do_checkIfExist dvdnav-git libdvdnav.a
    fi
fi

if do_checkForOptions "--enable-libbluray"; then
    cd $LOCALBUILDDIR
    do_vcs "git://git.videolan.org/libbluray.git" libbluray
    if [[ $compile = "true" ]]; then
        [[ -f configure ]] && make distclean || autoreconf -fiv
        if [[ -f $LOCALDESTDIR/lib/libbluray.a ]]; then
            rm -rf $LOCALDESTDIR/include/bluray
            rm -rf $LOCALDESTDIR/lib/libbluray.{l,}a $LOCALDESTDIR/lib/pkgconfig/libbluray.pc
        fi
        do_generic_confmakeinstall --enable-static --disable-examples --disable-bdjava --disable-doxygen-doc \
        --disable-doxygen-dot --without-libxml2 --without-fontconfig --without-freetype
        do_checkIfExist libbluray-git libbluray.a
    fi
fi

if do_checkForOptions "--enable-libutvideo"; then
    cd $LOCALBUILDDIR
    do_vcs "https://github.com/qyot27/libutvideo.git#branch=15.1.0" libutvideo
    if [[ $compile = "true" ]]; then
        if [[ -f utv_core/libutvideo.a ]]; then
            rm -rf $LOCALDESTDIR/include/utvideo
            rm -rf $LOCALDESTDIR/lib/libutvideo.a $LOCALDESTDIR/lib/pkgconfig/libutvideo.pc
            make distclean
        fi
        ./configure --cross-prefix=$cross --prefix=$LOCALDESTDIR
        make -j $cpuCount AR="${AR-ar}" RANLIB="${RANLIB-ranlib}"
        make install RANLIBX="${RANLIB-ranlib}"
        do_checkIfExist libutvideo-git libutvideo.a
    fi
fi

if do_checkForOptions "--enable-libass"; then
    cd $LOCALBUILDDIR
    do_vcs "https://github.com/libass/libass.git" libass
    if [[ $compile = "true" || $buildLibass = "y" ]]; then
        [[ -f configure ]] && make distclean || autoreconf -fiv
        if [[ -f $LOCALDESTDIR/lib/libass.a ]]; then
            rm -rf $LOCALDESTDIR/include/ass
            rm -f $LOCALDESTDIR/lib/libass.{,l}a $LOCALDESTDIR/lib/pkgconfig/libass.pc
        fi
        [[ $bits = "64bit" ]] && disable_fc="--disable-fontconfig"
        do_generic_confmakeinstall $disable_fc
        do_checkIfExist libass-git libass.a
        buildFFmpeg="true"
        unset disable_fc buildLibass
    fi
fi

if do_checkForOptions "--enable-libxavs"; then
    cd $LOCALBUILDDIR
    if [[ -f "$LOCALDESTDIR/lib/libxavs.a" ]]; then
        echo -------------------------------------------------
        echo "xavs is already compiled"
        echo -------------------------------------------------
    else
        echo -ne "\033]0;compile xavs $bits\007"
        if [[ ! -d xavs ]] || [[ -d xavs ]] &&
        { [[ $build32 = "yes" && ! -f xavs/build_successful32bit ]] ||
          [[ $build64 = "yes" && ! -f xavs/build_successful64bit ]]; }; then
            rm -rf distrotech-xavs.zip xavs-distrotech-xavs
            do_wget https://github.com/Distrotech/xavs/archive/distrotech-xavs.zip
        fi
        cd xavs-distrotech-xavs
        [[ -f "libxavs.a" ]] && make distclean
        if [[ -f $LOCALDESTDIR/lib/libxavs.a ]]; then
            rm -rf $LOCALDESTDIR/include/xavs.h
            rm -rf $LOCALDESTDIR/lib/libxavs.a $LOCALDESTDIR/lib/pkgconfig/xavs.pc
        fi
        sed -i 's,"NUL","/dev/null",g' configure
        ./configure --host=$targetHost --prefix=$LOCALDESTDIR
        make -j $cpuCount libxavs.a
        cp -f xavs.h $LOCALDESTDIR/include
        cp -f libxavs.a $LOCALDESTDIR/lib
        cp -f xavs.pc $LOCALDESTDIR/lib/pkgconfig
        do_checkIfExist xavs-distrotech-xavs libxavs.a
    fi
fi

if [[ $mediainfo = "y" ]]; then
    cd $LOCALBUILDDIR
    do_vcs "https://github.com/MediaArea/ZenLib" libzen
    if [[ $compile = "true" ]]; then
        cd Project/GNU/Library
        [[ ! -f "configure" ]] && ./autogen.sh || make distclean
        if [[ -f $LOCALDESTDIR/lib/libzen.a ]]; then
            rm -rf $LOCALDESTDIR/include/ZenLib $LOCALDESTDIR/bin-global/libzen-config
            rm -f $LOCALDESTDIR/lib/libzen.{l,}a $LOCALDESTDIR/lib/pkgconfig/libzen.pc
        fi
        do_generic_conf
        [[ $bits = "64bit" ]] && sed -i 's/ -DSIZE_T_IS_LONG//g' Makefile
        do_makeinstall
        [[ -f "$LOCALDESTDIR/bin/libzen-config" ]] && rm $LOCALDESTDIR/bin/libzen-config
        do_checkIfExist libzen-git libzen.a
        buildMediaInfo="true"
    fi

    cd $LOCALBUILDDIR
    do_vcs "https://github.com/MediaArea/MediaInfoLib" libmediainfo
    if [[ $compile = "true" || $buildMediaInfo = "true" ]]; then
        cd Project/GNU/Library
        [[ ! -f "configure" ]] && ./autogen.sh || make distclean
        if [[ -f $LOCALDESTDIR/lib/libmediainfo.a ]]; then
            rm -rf $LOCALDESTDIR/include/MediaInfo{,DLL}
            rm -f $LOCALDESTDIR/lib/libmediainfo.{l,}a $LOCALDESTDIR/lib/pkgconfig/libmediainfo.pc
            rm -f $LOCALDESTDIR/bin-global/libmediainfo-config
        fi
        do_generic_conf LDFLAGS="$LDFLAGS -static-libgcc"
        [[ $bits = "64bit" ]] && sed -i 's/ -DSIZE_T_IS_LONG//g' Makefile
        do_makeinstall
        cp libmediainfo.pc $LOCALDESTDIR/lib/pkgconfig/
        do_checkIfExist libmediainfo-git libmediainfo.a
        buildMediaInfo="true"
    fi

    cd $LOCALBUILDDIR
    do_vcs "https://github.com/MediaArea/MediaInfo" mediainfo bin-video/mediainfo.exe
    if [[ $compile = "true" || $buildMediaInfo = "true" ]]; then
        cd Project/GNU/CLI
        [[ ! -f "configure" ]] && ./autogen.sh || make distclean
        [[ -f $LOCALDESTDIR/bin-video/mediainfo.exe ]] && rm -rf $LOCALDESTDIR/bin-video/mediainfo.exe
        do_generic_conf video --enable-staticlibs LDFLAGS="$LDFLAGS -static-libgcc"
        [[ $bits = "64bit" ]] && sed -i 's/ -DSIZE_T_IS_LONG//g' Makefile
        do_makeinstall
        do_checkIfExist mediainfo-git bin-video/mediainfo.exe
    fi
fi

if do_checkForOptions "--enable-libvidstab"; then
    cd $LOCALBUILDDIR
    do_vcs "https://github.com/georgmartius/vid.stab.git" vidstab
    if [[ $compile = "true" ]]; then
        if [[ -f $LOCALDESTDIR/lib/libvidstab.a ]]; then
            rm -rf $LOCALDESTDIR/include/vid.stab $LOCALDESTDIR/lib/libvidstab.a
            rm -rf $LOCALDESTDIR/lib/pkgconfig/vidstab.pc
        fi
        do_cmakeinstall
        do_checkIfExist vidstab-git libvidstab.a
        buildFFmpeg="true"
    fi
fi

if do_checkForOptions "--enable-libcaca"; then
    rm -rf $LOCALDESTDIR/include/caca* $LOCALDESTDIR/bin-video/caca*
    rm -rf $LOCALDESTDIR/lib/libcaca.{l,}a $LOCALDESTDIR/lib/pkgconfig/caca.pc
    do_pacman_install "libcaca"
    do_addOption "--extra-cflags=-DCACA_STATIC"
fi

if do_checkForOptions "--enable-libzvbi" && do_pkgConfig "zvbi-0.2 = 0.2.35"; then
    cd $LOCALBUILDDIR
    do_wget_sf "zapping/zvbi/0.2.35/zvbi-0.2.35.tar.bz2"
    [[ -f "src/.libs/libzvbi.a" ]] && make distclean
    if [[ -f $LOCALDESTDIR/lib/libzvbi.a ]]; then
        rm -rf $LOCALDESTDIR/include/libzvbi.h
        rm -rf $LOCALDESTDIR/lib/libzvbi.{l,}a $LOCALDESTDIR/lib/pkgconfig/zvbi-0.2.pc
    fi
    do_patch "zvbi-win32.patch"
    do_patch "zvbi-ioctl.patch"
    do_generic_conf --disable-dvb --disable-bktr --disable-nls --disable-proxy --without-doxygen \
    CFLAGS="$CFLAGS -DPTW32_STATIC_LIB" LIBS="$LIBS -lpng"
    cd src
    do_makeinstall
    cp ../zvbi-0.2.pc $LOCALDESTDIR/lib/pkgconfig
    do_checkIfExist zvbi-0.2.35 libzvbi.a
fi

if do_checkForOptions "--enable-frei0r" && do_pkgConfig "frei0r = 1.3.0"; then
    cd $LOCALBUILDDIR
    do_wget "https://files.dyne.org/frei0r/releases/frei0r-plugins-1.4.tar.gz"
    sed -i 's/find_package (Cairo)//' "CMakeLists.txt"
    if [[ -f $LOCALDESTDIR/lib/frei0r-1/xfade0r.dll ]]; then
        rm -rf $LOCALDESTDIR/include/frei0r.h
        rm -rf $LOCALDESTDIR/lib/frei0r-1 $LOCALDESTDIR/lib/pkgconfig/frei0r.pc
    fi
    do_cmakeinstall -DCMAKE_BUILD_TYPE=Release
    do_checkIfExist frei0r-plugins-1.4 frei0r-1/xfade0r.dll
fi

if do_checkForOptions "--enable-decklink" && [[ $ffmpeg != "n" ]]; then
    cd $LOCALBUILDDIR
    missing="n"
    for file in DeckLinkAPI{{,Version}.h,_i.c}; do
        [[ ! -f "$LOCALDESTDIR/include/$file" ]] && missing="y"
    done
    if [[ "$missing" = "n" ]] &&
        grep -qE 'API_VERSION_STRING[[:space:]]+"10.5"' "$LOCALDESTDIR/include/DeckLinkAPIVersion.h"; then
        echo -------------------------------------------------
        echo "DeckLinkAPI is already installed"
        echo -------------------------------------------------
    else
        echo -ne "\033]0;installing DeckLinkAPI $bits\007"
        mkdir -p DeckLinkAPI && cd DeckLinkAPI
        [[ ! -f recently_updated ]] && rm -f DeckLinkAPI{{,Version}.h,_i.c}
        for file in DeckLinkAPI{{,Version}.h,_i.c}; do
            [[ ! -f "$file" ]] &&
                do_wget "https://github.com/jb-alvarado/media-autobuild_suite/raw/master/build/extras/$file" &&
                touch recently_updated
            cp -f "$file" "$LOCALDESTDIR/include/$file"
        done
        do_checkIfExist DeckLinkAPI "include/DeckLinkAPI.h"
    fi
    unset missing
fi

if do_checkForOptions "--enable-nvenc" && [[ $ffmpeg != "n" ]]; then
    cd $LOCALBUILDDIR
    if [[ -f $LOCALDESTDIR/include/nvEncodeAPI.h ]]; then
        echo -------------------------------------------------
        echo "nvenc is already installed"
        echo -------------------------------------------------
    else
        echo -ne "\033]0;install nvenc $bits\007"
        [[ ! -d nvenc_5.0.1_sdk ]] &&
            do_wget "http://developer.download.nvidia.com/compute/nvenc/v5.0/nvenc_5.0.1_sdk.zip"
        [[ ! -f "$LOCALDESTDIR/include/nvEncodeAPI.h" ]] &&
            cp nvenc_5.0.1_sdk/Samples/common/inc/* "$LOCALDESTDIR/include/"
        do_checkIfExist nvenc_5.0.1_sdk "include/nvEncodeAPI.h"
    fi
fi

if do_checkForOptions "--enable-libmfx" && [[ $ffmpeg != "n" ]]; then
    cd $LOCALBUILDDIR
    do_vcs "https://github.com/lu-zero/mfx_dispatch.git" libmfx
    if [[ $compile = "true" ]]; then
        [[ ! -f configure ]] && autoreconf -fiv || make distclean
        if [[ -f $LOCALDESTDIR/lib/libmfx.a ]]; then
            rm -rf $LOCALDESTDIR/include/mfx
            rm -f $LOCALDESTDIR/lib/libmfx.{l,}a $LOCALDESTDIR/lib/pkgconfig/libmfx.pc
        fi
        do_generic_confmakeinstall
        do_checkIfExist libmfx-git libmfx.a
    fi
fi

if do_checkForOptions "--enable-libcdio"; then
    rm -rf $LOCALBUILDDIR/libcdio_paranoia-git
    rm -rf $LOCALDESTDIR/include/cdio $LOCALDESTDIR/lib/libcdio_{cdda,paranoia}.{l,}a
    rm -f $LOCALDESTDIR/lib/pkgconfig/libcdio_{cdda,paranoia}.pc
    rm -f $LOCALDESTDIR/bin-audio/cd-paranoia.exe
    do_pacman_install "libcddb libcdio libcdio-paranoia"
fi

#------------------------------------------------
# final tools
#------------------------------------------------

if [[ $mp4box = "y" ]]; then
    cd $LOCALBUILDDIR
    do_vcs "https://github.com/gpac/gpac.git" gpac bin-video/MP4Box.exe
    if [[ $compile = "true" ]]; then
        if [ -f $LOCALDESTDIR/lib/libgpac_static.a ]; then
            rm -f $LOCALDESTDIR/bin-video/MP4Box.exe $LOCALDESTDIR/lib/libgpac*
            rm -rf $LOCALDESTDIR/include/gpac
        fi
        [[ -f config.mak ]] && make distclean
        ./configure --prefix=$LOCALDESTDIR --static-mp4box --extra-libs="-lz"
        make -j $cpuCount
        make install-lib
        cp bin/gcc/MP4Box.exe $LOCALDESTDIR/bin-video
        do_checkIfExist gpac-git bin-video/MP4Box.exe
    fi
fi

if [[ ! $x264 = "n" ]]; then
    cd $LOCALBUILDDIR
    do_vcs "git://git.videolan.org/x264.git" x264
    if [[ $compile = "true" ]] || [[ $x264 != "l" && ! -f "$LOCALDESTDIR/bin-video/x264.exe" ]]; then
        extracommands="--host=$targetHost --prefix=$LOCALDESTDIR --enable-static --enable-win32thread"
        if [[ $x264 = "f" ]]; then
            cd $LOCALBUILDDIR
            do_vcs "git://git.videolan.org/ffmpeg.git" ffmpeg lib/libavcodec.a
            rm -rf $LOCALDESTDIR/include/libav{codec,device,filter,format,util,resample}
            rm -rf $LOCALDESTDIR/include/{libsw{scale,resample},libpostproc}
            rm -f $LOCALDESTDIR/lib/libav{codec,device,filter,format,util,resample}.a
            rm -f $LOCALDESTDIR/lib/{libsw{scale,resample},libpostproc}.a
            rm -f $LOCALDESTDIR/lib/pkgconfig/libav{codec,device,filter,format,util,resample}.pc
            rm -f $LOCALDESTDIR/lib/pkgconfig/{libsw{scale,resample},libpostproc}.pc
            [[ -f "config.mak" ]] && make distclean
            ./configure $FFMPEG_BASE_OPTS --prefix=$LOCALDESTDIR --disable-shared --disable-programs \
            --disable-devices --disable-filters --disable-encoders --disable-muxers

            do_makeinstall
            do_checkIfExist ffmpeg-git libavcodec.a
        else
            extracommands+=" --disable-lavf --disable-swscale --disable-ffms"
        fi

        if [[ $x264 != "l" ]]; then
            cd $LOCALBUILDDIR
            do_vcs "https://github.com/l-smash/l-smash.git" lsmash
            if [[ $compile = "true" ]]; then
                [[ -f "config.mak" ]] && make distclean
                if [[ -f $LOCALDESTDIR/lib/liblsmash.a ]]; then
                    rm -f $LOCALDESTDIR/include/lsmash.h $LOCALDESTDIR/lib/liblsmash.a
                    rm -f $LOCALDESTDIR/lib/pkgconfig/liblsmash.pc
                fi
                ./configure --prefix=$LOCALDESTDIR
                make -j $cpuCount lib
                make install-lib
                do_checkIfExist lsmash-git liblsmash.a
            fi
            cd $LOCALBUILDDIR/x264-git
            # x264 prefers and only uses lsmash if available
            extracommands+=" --disable-gpac"
        else
            extracommands+=" --disable-lsmash"
        fi

        echo -ne "\033]0;compile x264-git $bits\007"
        if [ -f $LOCALDESTDIR/lib/libx264.a ]; then
            rm -f $LOCALDESTDIR/include/x264{,_config}.h $LOCALDESTDIR/bin/x264{,-10bit}.exe
            rm -f $LOCALDESTDIR/lib/libx264.a $LOCALDESTDIR/lib/pkgconfig/x264.pc
        fi
        [[ -f "libx264.a" ]] && make distclean
        do_patch "x264-0001-Fix-compilation-with-ffmpeg-git.patch" am
        if [[ $x264 != "l" ]]; then
            extracommands+=" --bindir=$LOCALDESTDIR/bin-video"
            CFLAGS="$(echo $CFLAGS | sed 's/ -O2 / /')" ./configure --bit-depth=10 $extracommands
            make -j $cpuCount
            cp x264.exe $LOCALDESTDIR/bin-video/x264-10bit.exe
            make clean
        else
            extracommands+=" --disable-interlaced --disable-gpac --disable-cli"
        fi
        CFLAGS="$(echo $CFLAGS | sed 's/ -O2 / /')" ./configure --bit-depth=8 $extracommands
        do_makeinstall
        do_checkIfExist x264-git libx264.a
        buildFFmpeg="true"
    fi
else
    pkg-config --exists x264 || do_removeOption "--enable-libx264"
fi

if [[ ! $x265 = "n" ]]; then
    cd $LOCALBUILDDIR
    do_vcs "hg::https://bitbucket.org/multicoreware/x265" x265
    if [[ $compile = "true" ]] || [[ $x265 != "l" && ! -f "$LOCALDESTDIR"/bin-video/x265.exe ]]; then
        cd build/msys
        rm -f $LOCALDESTDIR/include/x265{,_config}.h
        rm -f $LOCALDESTDIR/lib/libx265{,_main10,_main12}.a $LOCALDESTDIR/lib/pkgconfig/x265.pc
        rm -f $LOCALDESTDIR/bin-video/libx265*.dll $LOCALDESTDIR/bin-video/x265.exe
        [[ $bits = "32bit" ]] && assembly="-DENABLE_ASSEMBLY=OFF" || assembly="-DENABLE_ASSEMBLY=ON"
        [[ $xpcomp = "y" ]] && xpsupport="-DWINXP_SUPPORT=ON" || xpsupport="-DWINXP_SUPPORT=OFF"

        build_x265() {
        rm -rf $LOCALBUILDDIR/x265-hg/build/msys/{8,10,12}bit

        do_x265_cmake() {
            cmake ../../../source -G Ninja $xpsupport -DHG_EXECUTABLE=/usr/bin/hg.bat \
            -DCMAKE_CXX_FLAGS="$CXXFLAGS -static-libgcc -static-libstdc++" \
            -DCMAKE_C_FLAGS="$CFLAGS -static-libgcc -static-libstdc++" \
            -DCMAKE_INSTALL_PREFIX=$LOCALDESTDIR -DBIN_INSTALL_DIR=$LOCALDESTDIR/bin-video \
            -DENABLE_SHARED=OFF -DENABLE_CLI=OFF -DHIGH_BIT_DEPTH=ON -DEXPORT_C_API=ON "$@"
            ninja -j $cpuCount
        }
        mkdir -p {8,10,12}bit

        cd 12bit
        if [[ $x265 != "s" ]]; then
            # multilib
            do_x265_cmake $assembly -DEXPORT_C_API=OFF -DMAIN12=ON
            cp libx265.a ../8bit/libx265_main12.a
        fi

        cd ../10bit
        if [[ $x265 = "s" ]]; then
            # libx265_main10.dll
            do_x265_cmake $assembly -DENABLE_SHARED=ON
            cp libx265.dll $LOCALDESTDIR/bin-video/libx265_main10.dll
        else
            # multilib
            do_x265_cmake $assembly -DEXPORT_C_API=OFF
            cp libx265.a ../8bit/libx265_main10.a
        fi

        cd ../8bit
        if [[ $x265 = "s" ]]; then
            # 8-bit static x265.exe
            do_x265_cmake -DENABLE_CLI=ON -DHIGH_BIT_DEPTH=OFF
        else
            # multilib
            [[ $x265 != "l" ]] && cli="-DENABLE_CLI=ON"
            do_x265_cmake -DEXTRA_LIB="x265_main10.a;x265_main12.a" -DEXTRA_LINK_FLAGS=-L. $cli \
                -DHIGH_BIT_DEPTH=OFF -DLINKED_10BIT=ON -DLINKED_12BIT=ON
        fi
        if [[ $x265 != "s" ]]; then
            mv libx265.a libx265_main.a
            ar -M <<EOF
CREATE libx265.a
ADDLIB libx265_main.a
ADDLIB libx265_main10.a
ADDLIB libx265_main12.a
SAVE
END
EOF
        fi
        }
        build_x265
        ninja -j $cpuCount install
        if [[ $x265 = "d" ]]; then
            cd ..
            rm -f $LOCALDESTDIR/bin-video/x265-numa.exe
            xpsupport="-DWINXP_SUPPORT=OFF"
            build_x265
            cp -f x265.exe $LOCALDESTDIR/bin-video/x265-numa.exe
        fi
        do_checkIfExist x265-hg libx265.a
        buildFFmpeg="true"
        unset xpsupport assembly cli
    fi
else
    pkg-config --exists x265 || do_removeOption "--enable-libx265"
fi

do_checkForOptions "--enable-libschroedinger" && do_pacman_install "schroedinger"
do_checkForOptions "--enable-libgsm" && do_pacman_install "gsm"
do_checkForOptions "--enable-libwavpack" && do_pacman_install "wavpack"
do_checkForOptions "--enable-libsnappy" && do_pacman_install "snappy"
if do_checkForOptions "--enable-libxvid"; then
    do_pacman_install "xvidcore"
    [[ -f $MINGW_PREFIX/lib/xvidcore.a ]] && mv -f $MINGW_PREFIX/lib/{,lib}xvidcore.a
    [[ -f $MINGW_PREFIX/lib/xvidcore.dll.a ]] && mv -f $MINGW_PREFIX/lib/xvidcore.dll.a{,.dyn}
    [[ -f $MINGW_PREFIX/bin/xvidcore.dll ]] && mv -f $MINGW_PREFIX/bin/xvidcore.dll{,.disabled}
fi
do_hide_all_sharedlibs

if [[ $ffmpeg != "n" ]]; then
    cd $LOCALBUILDDIR
    do_changeFFmpegConfig
    if [[ $ffmpeg != "s" ]]; then
        do_vcs "git://git.videolan.org/ffmpeg.git" ffmpeg bin-video/ffmpeg.exe
    else
        do_vcs "git://git.videolan.org/ffmpeg.git" ffmpeg bin-video/ffmpegSHARED/ffmpeg.exe
    fi
    if [[ $compile = "true" ]] || [[ $buildFFmpeg = "true" && $ffmpegUpdate = "y" ]]; then
        do_patch "ffmpeg-0001-Use-pkg-config-for-more-external-libs.patch" am
        do_patch "ffmpeg-0002-add-openhevc-intrinsics.patch" am
        do_checkForOptions "--enable-openssl --enable-gnutls" ||
            do_patch "ffmpeg-0003-avformat-implement-SChannel.patch" am

        # shared
        if [[ $ffmpeg != "y" ]] && [[ ! -f build_successful${bits}_shared ]]; then
            echo -ne "\033]0;compiling shared FFmpeg $bits\007"
            [[ -f config.mak ]] && make distclean
            rm -rf $LOCALDESTDIR/bin-video/ffmpegSHARED
            ./configure --prefix=$LOCALDESTDIR/bin-video/ffmpegSHARED \
                --disable-static --enable-shared $FFMPEG_OPTS_SHARED \
                --extra-libs='-lpng -lpthread -lwsock32'
            # cosmetics
            sed -ri "s/ ?--(prefix|bindir|extra-(cflags|libs)|pkg-config-flags)=(\S+|'[^']+')//g" config.h
            do_makeinstall
            do_checkIfExist ffmpeg-git bin-video/ffmpegSHARED/bin/ffmpeg.exe
            [[ $ffmpeg = "b" ]] && [[ -f build_successful${bits} ]] &&
                mv build_successful${bits} build_successful${bits}_shared
        fi

        # static
        if [[ $ffmpeg != "s" ]]; then
            echo -ne "\033]0;compiling static FFmpeg $bits\007"
            rm -rf $LOCALDESTDIR/include/libav{codec,device,filter,format,util,resample}
            rm -rf $LOCALDESTDIR/include/{libsw{scale,resample},libpostproc}
            rm -f $LOCALDESTDIR/lib/libav{codec,device,filter,format,util,resample}.a
            rm -f $LOCALDESTDIR/lib/{libsw{scale,resample},libpostproc}.a
            rm -f $LOCALDESTDIR/lib/pkgconfig/libav{codec,device,filter,format,util,resample}.pc
            rm -f $LOCALDESTDIR/lib/pkgconfig/{libsw{scale,resample},libpostproc}.pc
            rm -f $LOCALDESTDIR/bin-video/ff{mpeg,play,probe}.exe
            [[ -f config.mak ]] && make distclean
            ./configure --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-video \
                --enable-static --disable-shared $FFMPEG_OPTS \
                --extra-libs='-lpng -lpthread -lwsock32'
            # cosmetics
            sed -ri "s/ ?--(prefix|bindir|extra-(cflags|libs))=(\S+|'[^']+')//g" config.h
            do_makeinstall
            do_checkIfExist ffmpeg-git libavcodec.a
            newFfmpeg="yes"
        fi
    fi
fi

if [[ $bits = "64bit" && $other265 = "y" ]]; then
if [[ ! -f $LOCALDESTDIR/bin-video/f265cli.exe ]]; then
    cd $LOCALBUILDDIR
    do_wget "http://f265.org/f265/static/bin/f265_development_snapshot.zip"
    rm -rf f265 && mv f265_development_snapshot f265 && cd f265
    if [ -d "build" ]; then
        rm -rf build .sconf_temp
        rm -f .sconsign.dblite config.log options.py
    fi
    scons libav=none
    [[ -f build/f265cli.exe ]] && cp build/f265cli.exe $LOCALDESTDIR/bin-video/f265cli.exe
    do_checkIfExist f265 bin-video/f265cli.exe
else
    echo -------------------------------------------------
    echo "f265 is already compiled"
    echo -------------------------------------------------
fi
fi

if [[ $mplayer = "y" ]]; then
    cd $LOCALBUILDDIR
    [[ $nonfree = "n" ]] && faac="--disable-faac --disable-faac-lavc"

    do_vcs "svn::svn://svn.mplayerhq.hu/mplayer/trunk" mplayer bin-video/mplayer.exe

    if [ -d "ffmpeg" ]; then
        cd ffmpeg
        git checkout -f --no-track -B master origin/HEAD
        git fetch
        oldHead=$(git rev-parse HEAD)
        git checkout -f --no-track -B master origin/HEAD
        newHead=$(git rev-parse HEAD)
        cd ..
    fi

    if [[ $compile == "true" ]] || [[ "$oldHead" != "$newHead"  ]] || [[ $buildFFmpeg == "true" ]]; then
        [[ -f $LOCALDESTDIR/bin-video/mplayer.exe ]] &&
            rm -f $LOCALDESTDIR/bin-video/{mplayer,mencoder}.exe
        [[ -f config.mak ]] && make distclean
        if ! test -e ffmpeg ; then
            if [ ! $ffmpeg = "n" ]; then
                git clone $LOCALBUILDDIR/ffmpeg-git ffmpeg
                git checkout -f --no-track -B master origin/HEAD
            elif ! git clone --depth 1 git://git.videolan.org/ffmpeg.git ffmpeg; then
                rm -rf ffmpeg
                echo "Failed to get a FFmpeg checkout"
                echo "Please try again or put FFmpeg source code copy into ffmpeg/ manually."
                echo "Nightly snapshot: http://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2"
                echo "To use a github mirror via http (e.g. because a firewall blocks git):"
                echo "git clone --depth 1 https://github.com/FFmpeg/FFmpeg ffmpeg"
                exit 1
            fi
        fi

        grep -q "windows" libmpcodecs/ad_spdif.c ||
            sed -i '/#include "mp_msg.h/ a\#include <windows.h>' libmpcodecs/ad_spdif.c

        ./configure --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-video --cc=gcc \
        --extra-cflags='-DPTW32_STATIC_LIB -O3 -std=gnu99 -DMODPLUG_STATIC' \
        --extra-libs='-llzma -lfreetype -lz -lbz2 -liconv -lws2_32 -lpthread -lwinpthread -lpng -lwinmm -ldl' \
        --extra-ldflags='-Wl,--allow-multiple-definition' --enable-static --enable-runtime-cpudetection \
        --disable-gif --disable-cddb $faac --with-dvdread-config="$PKG_CONFIG dvdread" \
        --with-freetype-config="$PKG_CONFIG freetype2" --with-dvdnav-config="$PKG_CONFIG dvdnav"\

        do_makeinstall
        do_checkIfExist mplayer-svn bin-video/mplayer.exe
    fi
fi

if [[ $mpv = "y" ]] && pkg-config --exists "libavcodec libavutil libavformat libswscale"; then
    cd $LOCALBUILDDIR
    do_vcs "git://midipix.org/waio" waio lib/libwaio.a
    if [[ $compile = "true" ]]; then
        [[ $bits = "32bit" ]] && _bits="32" || _bits="64"
        if [[ -f lib${_bits}/libwaio.a ]]; then
            ./build-mingw-nt${_bits} clean
            rm -rf $LOCALDESTDIR/include/waio
            rm -f $LOCALDESTDIR/lib/libwaio.a
        fi
        build-mingw-nt${_bits} AR=${targetBuild}-gcc-ar LD=ld STRIP=strip lib-static
        cp -r include/waio  $LOCALDESTDIR/include/
        cp -r lib${_bits}/libwaio.a $LOCALDESTDIR/lib/
        do_checkIfExist waio-git libwaio.a
        unset _bits
    fi

    cd $LOCALBUILDDIR
    do_vcs "http://luajit.org/git/luajit-2.0.git" luajit
    if [[ $compile = "true" ]]; then
        if [[ -f "$LOCALDESTDIR/lib/libluajit-5.1.a" ]]; then
            rm -rf $LOCALDESTDIR/include/luajit-2.0 $LOCALDESTDIR/bin-global/luajit*.exe $LOCALDESTDIR/lib/lua
            rm -rf $LOCALDESTDIR/lib/libluajit-5.1.a $LOCALDESTDIR/lib/pkgconfig/luajit.pc
        fi
        [[ -f "src/luajit.exe" ]] && make clean
        make BUILDMODE=static amalg
        make BUILDMODE=static PREFIX=$LOCALDESTDIR INSTALL_BIN=$LOCALDESTDIR/bin-global FILE_T=luajit.exe \
        INSTALL_TNAME='luajit-$(VERSION).exe' INSTALL_TSYMNAME=luajit.exe install
        # luajit comes with a broken .pc file
        sed -r -i "s/(Libs.private:).*/\1 -liconv/" $LOCALDESTDIR/lib/pkgconfig/luajit.pc
        do_checkIfExist luajit-git libluajit-5.1.a
    fi

    rm -f $LOCALDESTDIR/include/uchardet.h $LOCALDESTDIR/lib/libuchardet.a
    rm -f $LOCALDESTDIR/lib/pkgconfig/uchardet.pc $LOCALDESTDIR/bin/uchardet.exe
    do_pacman_install "uchardet-git"

    cd $LOCALBUILDDIR
    do_vcs "https://github.com/mpv-player/mpv.git" mpv bin-video/mpv.exe
    if [[ $compile = "true" ]] || [[ $newFfmpeg = "yes" ]]; then
        # mpv uses libs from pkg-config but randomly uses MinGW's librtmp.a which gets compiled
        # with GnuTLS. If we didn't compile ours with GnuTLS the build fails on linking.
        do_checkForOptions "--enable-librtmp" && [[ -f "$MINGW_PREFIX"/lib/librtmp.a ]] &&
            mv "$MINGW_PREFIX"/lib/librtmp.a{,.bak}

        [[ ! -f waf ]] && $python bootstrap.py
        if [[ -d build ]]; then
            $python waf distclean
            rm -f $LOCALDESTDIR/bin-video/mpv.{exe,com}
        fi

        # for purely cosmetic reasons, show the last release version when doing -V
        git describe --tags $(git rev-list --tags --max-count=1) | cut -c 2- > VERSION
        [[ $bits = "64bit" ]] && mpv_ldflags="-Wl,--image-base,0x140000000,--high-entropy-va" &&
            mpv_pthreads="--enable-win32-internal-pthreads"

        LDFLAGS="$LDFLAGS $mpv_ldflags" $python waf configure --prefix=$LOCALDESTDIR \
        --bindir=$LOCALDESTDIR/bin-video --disable-debug-build --enable-static-build \
        --lua=luajit $mpv_pthreads --disable-libguess --enable-libarchive

        # Windows(?) has a lower argument limit than *nix so
        # we replace tons of repeated -L flags with just two
        replace="LIBPATH_lib\1 = ['${LOCALDESTDIR}/lib','${MINGW_PREFIX}/lib']"
        sed -r -i "s:LIBPATH_lib(ass|av(|device|filter)) = .*:$replace:g" ./build/c4che/_cache.py

        $python waf install -j $cpuCount

        if [[ $bits = "32bit" ]] && [[ ! -d $LOCALDESTDIR/bin-video/fonts ]]; then
            do_wget "https://raw.githubusercontent.com/lachs0r/mingw-w64-cmake/master/packages/mpv/mpv/fonts.conf"
            mkdir -p $LOCALDESTDIR/bin-video/mpv
            mv -f fonts.conf $LOCALDESTDIR/bin-video/mpv/
            do_wget "http://srsfckn.biz/noto-mpv.7z" noto-mpv.7z fonts
            mv fonts $LOCALDESTDIR/bin-video/
        fi

        unset mpv_ldflags mpv_pthreads replace
        do_checkIfExist mpv-git bin-video/mpv.exe
        [[ -f "$MINGW_PREFIX"/lib/librtmp.a.bak ]] && mv "$MINGW_PREFIX"/lib/librtmp.a{.bak,}
    fi
fi

echo "-------------------------------------------------------------------------------"
echo
echo "compile video tools $bits done..."
echo
echo "-------------------------------------------------------------------------------"
}

run_builds() {
    new_updates="no"
    new_updates_packages=""
    if [[ $build32 = "yes" ]]; then
        source /local32/etc/profile.local
        buildProcess
        echo "-------------------------------------------------------------------------------"
        echo "compile all tools 32bit done..."
        echo "-------------------------------------------------------------------------------"
    fi

    if [[ $build64 = "yes" ]]; then
        source /local64/etc/profile.local
        buildProcess
        echo "-------------------------------------------------------------------------------"
        echo "compile all tools 64bit done..."
        echo "-------------------------------------------------------------------------------"
    fi
}

cd $LOCALBUILDDIR
if [[ "$(pwd)" = "$LOCALBUILDDIR" ]]; then
    run_builds
else
    read -p "Something serious has failed. Let us know before running this script again."
    exit 1
fi

while [[ $new_updates = "yes" ]]; do
    ret="no"
    echo "-------------------------------------------------------------------------------"
    echo "There were new updates while compiling."
    echo "Updated:$new_updates_packages"
    echo "Would you like to run compilation again to get those updates? Default: no"
    do_prompt "y/[n] "
    echo "-------------------------------------------------------------------------------"
    [[ $ret = "y" || $ret = "Y" || $ret = "yes" ]] && run_builds || break
done

if [[ $stripping = "y" ]]; then
    echo -ne "\033]0;Stripping $bits binaries\007"
    echo
    echo "-------------------------------------------------------------------------------"
    echo
    printf "Stripping binaries and libs... "
    find /local*/{bin-*,lib} -regex ".*\.\(exe\|dll\)" -not -name x265.exe -newer $LOCALBUILDDIR/last_run | \
        xargs -r strip --strip-all
    find /local*/bin-video -name x265.exe -newer $LOCALBUILDDIR/last_run | xargs -r strip --strip-unneeded
    printf "done!\n"
fi

if [[ $packing = "y" ]]; then
    if [ ! -f "$LOCALBUILDDIR/upx391w/upx.exe" ]; then
        echo -ne "\033]0;Installing UPX\007"
        cd $LOCALBUILDDIR
        rm -rf upx391w
        do_wget_sf "upx/upx/3.91/upx391w.zip"
    fi
    echo -ne "\033]0;Packing $bits binaries\007"
    echo
    echo "-------------------------------------------------------------------------------"
    echo
    echo "Packing binaries and shared libs... "
    packcmd="$LOCALBUILDDIR/upx391w/upx.exe -9 -qq"
    [[ $stripping = "y" ]] && packcmd="$packcmd --strip-relocs=0"
    find /local*/bin-* -regex ".*\.\(exe\|dll\)" -newer $LOCALBUILDDIR/last_run | xargs -r $packcmd
fi

echo
echo "-------------------------------------------------------------------------------"
echo
echo "deleting status files..."
cd $LOCALBUILDDIR
find . -maxdepth 2 -name recently_updated | xargs rm -f
find . -maxdepth 2 -regex ".*build_successful\(32\|64\)bit\(_shared\)?\$" | xargs rm -f
[[ -f last_run ]] && mv last_run last_successful_run
[[ -f CHANGELOG.txt ]] && cat CHANGELOG.txt >> newchangelog
unix2dos -n newchangelog CHANGELOG.txt 2> /dev/null && rm -f newchangelog
rm -f {firstrun,firstUpdate,secondUpdate,pacman,mingw32,mingw64}.log

if [[ $deleteSource = "y" ]]; then
    echo -ne "\033]0;deleting source folders\007"
    echo
    echo "deleting source folders..."
    echo
    find $LOCALBUILDDIR -mindepth 1 -maxdepth 1 -type d \
        ! -regex ".*\(-\(git\|hg\|svn\)\|upx.*\|extras\|patches\)\$" | xargs rm -rf
fi

echo -ne "\033]0;compiling done...\007"
echo
echo "Compilation successful."
echo "This window will close automatically in 5 seconds."
sleep 5
