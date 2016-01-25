#!/bin/bash

cpuCount=1
compile="false"
buildFFmpeg="false"
newFfmpeg="no"
FFMPEG_BASE_OPTS=("--enable-avisynth" "--pkg-config-flags=--static")
alloptions="$*"
echo -e "\nBuild start: $(date +"%F %T %z")" >> "$LOCALBUILDDIR"/newchangelog
echo -ne "\e]0;media-autobuild_suite\007"

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
--fdkaac=* ) fdkaac="${1#*=}"; shift ;;
--mediainfo=* ) mediainfo="${1#*=}"; shift ;;
--sox=* ) sox="${1#*=}"; shift ;;
--ffmpeg=* ) ffmpeg="${1#*=}"; shift ;;
--ffmpegUpdate=* ) ffmpegUpdate="${1#*=}"; shift ;;
--ffmpegChoice=* ) ffmpegChoice="${1#*=}"; shift ;;
--mplayer=* ) mplayer="${1#*=}"; shift ;;
--mpv=* ) mpv="${1#*=}"; shift ;;
--deleteSource=* ) deleteSource="${1#*=}"; shift ;;
--license=* ) license="${1#*=}"; shift ;;
--standalone=* ) standalone="${1#*=}"; shift ;;
--stripping* ) stripping="${1#*=}"; shift ;;
--packing* ) packing="${1#*=}"; shift ;;
--xpcomp=* ) xpcomp="${1#*=}"; shift ;;
--logging=* ) logging="${1#*=}"; shift ;;
--bmx=* ) bmx="${1#*=}"; shift ;;
    -- ) shift; break ;;
    -* ) echo "Error, unknown option: '$1'."; exit 1 ;;
    * ) break ;;
  esac
done

[[ -f "$LOCALBUILDDIR"/media-suite_helper.sh ]] &&
    source "$LOCALBUILDDIR"/media-suite_helper.sh

buildProcess() {
echo -e "\n\t${orange_color}Starting $bits compilation of all tools${reset_color}"
[[ -f "$HOME"/custom_build_options ]] &&
    echo "Imported custom build options (unsupported)" &&
    source "$HOME"/custom_build_options

cd_safe "$LOCALBUILDDIR"

do_getFFmpegConfig $license
do_getMpvConfig
if [[ -n "$alloptions" ]]; then
    thisrun="$(printf '%s\n' '#!/bin/bash' "FFMPEG_DEFAULT_OPTS=\"${FFMPEG_DEFAULT_OPTS[*]}\"" \
            "MPV_OPTS=\"${MPV_OPTS[*]}\"" \
            "bash $LOCALBUILDDIR/media-suite_compile.sh $alloptions")"
    [[ -f "$LOCALBUILDDIR/last_run_successful" ]] &&
        { diff -q <(echo "$thisrun") "$LOCALBUILDDIR/last_run_successful" >/dev/null 2>&1 ||
            buildFFmpeg="true"; }
    echo "$thisrun" > "$LOCALBUILDDIR/last_run"
    unset alloptions thisrun
fi

echo -e "\n\t${orange_color}Starting $bits compilation of global tools${reset_color}"
if [[ $ffmpeg != "n" ]] && do_checkForOptions --enable-libopenjpeg; then
    do_pacman_remove "openjpeg2"
    _check=(j{config,error,morecfg,peglib}.h libjpeg.a)
    do_vcs "https://github.com/libjpeg-turbo/libjpeg-turbo.git" libjpegturbo "${_check[@]}"
    if [[ $compile = "true" ]]; then
        do_uninstall "${_check[@]}"
        do_patch "libjpegturbo-0001-Fix-header-conflicts-with-MinGW.patch" am
        do_patch "libjpegturbo-0002-Only-compile-libraries.patch" am
        do_cmakeinstall -DWITH_TURBOJPEG=off -DWITH_JPEG8=on -DENABLE_SHARED=off
        do_checkIfExist "${_check[@]}"
    fi

    do_vcs "https://github.com/uclouvain/openjpeg.git" libopenjp2
    if [[ $compile = "true" ]]; then
        _check=(libopenjp2.{a,pc})
        do_uninstall {include,lib}/openjpeg-2.1 libopen{jpwl,mj2}.{a,pc} "${_check[@]}"
        do_patch "openjpeg-0001-Only-compile-libraries.patch" am
        do_cmakeinstall
        do_checkIfExist "${_check[@]}"
    fi
fi

if [[ "$mplayer" = "y" ]] ||
    { [[ $ffmpeg != "n" ]] && do_checkForOptions --enable-libass --enable-libfreetype \
    "--enable-(lib)?fontconfig" --enable-libfribidi; } || ! mpv_disabled libass; then
    do_pacman_remove "freetype fontconfig harfbuzz fribidi"

    if do_pkgConfig "freetype2 = 18.2.12" "2.6.2"; then
        _check=(libfreetype.{l,}a freetype2.pc)
        do_wget "http://download.savannah.gnu.org/releases/freetype/freetype-2.6.2.tar.bz2"
        do_uninstall include/freetype2 bin-global/freetype-config "${_check[@]}"
        do_separate_confmakeinstall global --with-harfbuzz=no
        do_checkIfExist "${_check[@]}" 
        rebuildLibass="y"
    fi

    if do_checkForOptions "--enable-(lib)?fontconfig" && do_pkgConfig "fontconfig = 2.11.94"; then
        do_pacman_remove "python2-lxml"
        _check=(libfontconfig.{l,}a fontconfig.pc)
        [[ -d fontconfig-2.11.94 && ! -f fontconfig-2.11.94/fc-blanks/fcblanks.h ]] && rm -rf fontconfig-2.11.94
        do_wget "http://www.freedesktop.org/software/fontconfig/release/fontconfig-2.11.94.tar.gz"
        do_uninstall include/fontconfig "${_check[@]}"
        [[ $standalone = y ]] || sed -i Makefile.in -e 's/SUBDIRS = .*/SUBDIRS = fontconfig src/' \
            -e '/fc-cache fc-cat fc-list/,+1d' \
            -e 's/CROSS_COMPILING_TRUE/CROSS_COMPILING_FALSE/'
        do_separate_confmakeinstall global
        do_checkIfExist "${_check[@]}"
        rebuildLibass="y"
    fi

    [[ -z $harfbuzz_ver ]] &&
        harfbuzz_ver=$(curl -sl "http://www.freedesktop.org/software/harfbuzz/release/" |
            grep -Po '(?<=href=)"harfbuzz.*.tar.bz2"')
    [[ -n $harfbuzz_ver ]] &&
        harfbuzz_ver=$(get_last_version "$harfbuzz_ver" "" "1\.1\.\d+") || harfbuzz_ver="1.1.3"
    if do_pkgConfig "harfbuzz = ${harfbuzz_ver}" || [[ $rebuildLibass = y ]]; then
        do_pacman_install "ragel"
        _check=(libharfbuzz.{l,}a harfbuzz.pc)
        do_wget "http://www.freedesktop.org/software/harfbuzz/release/harfbuzz-${harfbuzz_ver}.tar.bz2"
        do_uninstall include/harfbuzz "${_check[@]}"
        do_separate_confmakeinstall --with-icu=no --with-glib=no --with-gobject=no
        do_checkIfExist "${_check[@]}"
        rebuildLibass=y
    fi

    if do_pkgConfig "fribidi = 0.19.7"; then
        _check=(libfribidi.{l,}a fribidi.pc)
        [[ $standalone = y ]] && _check+=(bin-global/fribidi.exe)
        do_wget "http://fribidi.org/download/fribidi-0.19.7.tar.bz2"
        do_uninstall include/fribidi bin-global/fribidi.exe "${_check[@]}"
        [[ $standalone = y ]] || sed -i 's|bin doc test||' Makefile.in
        do_separate_confmakeinstall global --disable-deprecated --with-glib=no --disable-debug
        do_checkIfExist "${_check[@]}"
    fi
fi

if { [[ $ffmpeg != "n" ]] && ! do_checkForOptions --disable-sdl --disable-ffplay; } &&
    do_pkgConfig "sdl = 1.2.15"; then
    do_pacman_remove "SDL"
    _check=(bin-global/sdl-config libSDL{,main}.{l,}a sdl.pc)
    do_wget "http://www.libsdl.org/release/SDL-1.2.15.tar.gz"
    do_uninstall include/SDL "${_check[@]}"
    CFLAGS="-DDECLSPEC=" do_separate_confmakeinstall global
    sed -i "s/-mwindows//" "$LOCALDESTDIR/bin-global/sdl-config"
    sed -i "s/-mwindows//" "$LOCALDESTDIR/lib/pkgconfig/sdl.pc"
    do_checkIfExist "${_check[@]}"
fi


if { { [[ "$ffmpeg" != "n" ]] && do_checkForOptions --enable-gnutls; } ||
    [[ "$rtmpdump" = "y" && "$license" != "nonfree" ]]; }; then
[[ -z "$gnutls_ver" ]] && gnutls_ver=$(curl -sl "ftp://ftp.gnutls.org/gcrypt/gnutls/v3.4/")
[[ -n "$gnutls_ver" ]] &&
    gnutls_ver=$(get_last_version "$gnutls_ver" "xz$" '3\.4\.\d+(\.\d+)?') || gnutls_ver="3.4.8"
if do_pkgConfig "gnutls = $gnutls_ver"; then
    do_pacman_install nettle &&
        do_uninstall include/nettle libnettle.a nettle.pc

    _check=(libgnutls.{,l}a gnutls.pc)
    do_wget "ftp://ftp.gnutls.org/gcrypt/gnutls/v3.4/gnutls-${gnutls_ver}.tar.xz"
    do_uninstall include/gnutls "${_check[@]}"
    do_separate_confmakeinstall \
        --disable-cxx --disable-doc --disable-tools --disable-tests --without-p11-kit --disable-rpath \
        --disable-libdane --without-idn --without-tpm --enable-local-libopts --disable-guile
    sed -i 's/-lgnutls *$/-lgnutls -lnettle -lhogweed -lcrypt32 -lws2_32 -lz -lgmp -lintl -liconv/' \
        "$LOCALDESTDIR/lib/pkgconfig/gnutls.pc"
    do_checkIfExist "${_check[@]}"
fi
fi

if [[ $sox = "y" ]]; then
    _ver="2.5.1"
    if [[ -f "$LOCALDESTDIR/lib/libgnurx.a" ]]; then
        do_print_status "libgnurx ${_ver}" "$green_color" "Up-to-date"
    else
        _check=(lib{gnurx,regex}.a regex.h)
        do_wget_sf "mingw/Other/UserContributed/regex/mingw-regex-${_ver}/mingw-libgnurx-${_ver}-src.tar.gz" \
            "mingw-libgnurx-${_ver}.tar.gz"
        do_uninstall "${_check[@]}"
        do_separate_conf
        do_patch "libgnurx-1-additional-makefile-rules.patch"
        do_make -f Makefile.mxe install-static
        do_checkIfExist "${_check[@]}"
    fi

    _check=(magic.h libmagic.{l,}a bin-global/file.exe)
    _ver="5.25"
    if files_exist "${_check[@]}" &&
        grep -q "$_ver" "$LOCALDESTDIR/lib/libmagic.a"; then
        do_print_status "file $_ver" "$green_color" "Up-to-date"
    else
        do_wget "https://fossies.org/linux/misc/file-${_ver}.tar.gz"
        do_uninstall "${_check[@]}"
        do_separate_confmakeinstall global CFLAGS=-DHAVE_PREAD
        do_checkIfExist "${_check[@]}"
    fi
fi

if do_checkForOptions --enable-libwebp; then
    do_pacman_install libtiff
    do_vcs "https://chromium.googlesource.com/webm/libwebp"
    if [[ $compile = "true" ]]; then
        do_autoreconf
        _check=(libwebp{,mux}.{{,l}a,pc})
        if [[ $standalone = y ]]; then
            extracommands=(--enable-libwebp{demux,decoder,extras}
                LIBS="$($PKG_CONFIG --libs libpng libtiff-4)" --enable-experimental
                LDFLAGS="$LDFLAGS -static-libgcc")
            _check+=(libwebp{,mux,demux,decoder,extras}.{{,l}a,pc}
                bin-global/{{c,d}webp,webpmux}.exe)
        else
            extracommands=()
            sed -i 's/ examples man//' Makefile.in
        fi
        do_uninstall include/webp bin-global/gif2webp.exe "${_check[@]}"
        do_separate_confmakeinstall global --enable-swap-16bit-csp \
            --enable-libwebpmux "${extracommands[@]}"
        do_checkIfExist "${_check[@]}"
    fi
fi

syspath=$(cygpath -S)
[[ $bits = "32bit" && -d "$syspath/../SysWOW64" ]] && syspath="$syspath/../SysWOW64"
if do_checkForOptions --enable-opencl && [[ -f "$syspath/OpenCL.dll" ]]; then
    echo -e "${orange_color}Tesseract, FFmpeg and related apps will depend on OpenCL.dll${reset_color}"
    if ! files_exist libOpenCL.a; then
        cd_safe "$LOCALBUILDDIR"
        do_pacman_install "opencl-headers"
        [[ -d opencl ]] && rm -rf opencl
        mkdir opencl && cd_safe opencl
        gendef "$syspath/OpenCL.dll" >/dev/null 2>&1
        [[ -f OpenCL.def ]] && dlltool -l libOpenCL.a -d OpenCL.def -k -A
        [[ -f libOpenCL.a ]] && mv -f libOpenCL.a "$LOCALDESTDIR"/lib/
        do_checkIfExist libOpenCL.a
    fi
else
    do_removeOption --enable-opencl
fi
unset syspath

if do_checkForOptions --enable-libtesseract; then
    do_pacman_remove "tesseract-ocr"
    do_pacman_install "libtiff"
    if do_pkgConfig "lept = 1.72"; then
        _check=(liblept.{,l}a lept.pc)
        do_wget "http://www.leptonica.com/source/leptonica-1.72.tar.gz"
        do_uninstall include/leptonica "${_check[@]}"
        do_separate_confmakeinstall --disable-programs --without-libopenjpeg --without-libwebp
        do_checkIfExist "${_check[@]}"
    fi

    do_vcs "https://github.com/tesseract-ocr/tesseract.git"
    if [[ $compile = "true" ]]; then
        do_autogen
        _check=(libtesseract.{,l}a tesseract.pc bin-global/tesseract.exe)
        do_uninstall include/tesseract "${_check[@]}"
        opencl=""
        do_checkForOptions --enable-opencl && opencl="-lOpenCL"
        sed -i "s|@OPENCL_LIB@|$opencl -lstdc++|" tesseract.pc.in
        do_separate_confmakeinstall global --disable-graphics --disable-tessdata-prefix \
            LIBLEPT_HEADERSDIR="$LOCALDESTDIR/include" LDFLAGS="$LDFLAGS -static -static-libgcc" \
            LIBS="$($PKG_CONFIG --libs lept libtiff-4)" --datadir="$LOCALDESTDIR/bin-global"
        if [[ ! -f $LOCALDESTDIR/bin-global/tessdata/eng.traineddata ]]; then
            mkdir -p "$LOCALDESTDIR"/bin-global/tessdata
            pushd "$LOCALDESTDIR"/bin-global/tessdata > /dev/null
            curl -OLs "https://github.com/tesseract-ocr/tessdata/raw/master/eng.traineddata"
            printf "%s\n" "You can get more language data here:"\
                   "https://github.com/tesseract-ocr/tessdata/blob/master/"\
                   "Just download <lang you want>.traineddata and copy it to this directory."\
                    > need_more_languages.txt
            popd > /dev/null
        fi
        do_checkIfExist "${_check[@]}"
        unset opencl
    fi
fi

if { { [[ $ffmpeg != "n" ]] && do_checkForOptions --enable-librubberband; } ||
    ! mpv_disabled rubberband; } && do_pkgConfig "rubberband = 1.8.1"; then
    _check=(librubberband.a rubberband.pc rubberband/{rubberband-c,RubberBandStretcher}.h)
    do_vcs https://github.com/lachs0r/rubberband.git
    do_uninstall "${_check[@]}"
    log "distclean" make distclean
    do_make PREFIX="$LOCALDESTDIR" install-static
    do_checkIfExist "${_check[@]}"
    _to_remove+=($(pwd))
fi

if { [[ $ffmpeg != "n" ]] && do_checkForOptions --enable-libzimg; } ||
    { ! pc_exists zimg && ! mpv_disabled vapoursynth; } then
    do_vcs "https://github.com/sekrit-twc/zimg.git"
    if [[ $compile = "true" ]]; then
        _check=(zimg{.h,++.hpp} libzimg.{,l}a zimg.pc)
        do_uninstall "${_check[@]}"
        grep -q "Libs.private" zimg.pc.in || sed -i "/Cflags:/ i\Libs.private: -lstdc++" zimg.pc.in
        do_autoreconf
        do_separate_confmakeinstall
        do_checkIfExist "${_check[@]}"
    fi
fi
echo -e "\n\t${orange_color}Starting $bits compilation of audio tools${reset_color}"
if [[ $ffmpeg != "n" ]] && do_checkForOptions --enable-libdcadec; then
    do_pacman_remove "dcadec-git"
    do_vcs "https://github.com/foo86/dcadec.git"
    if [[ $compile = "true" ]]; then
        _check=(libdcadec.a dcadec.pc)
        do_uninstall include/libdcadec "${_check[@]}"
        log "make" make clean
        do_make CONFIG_WINDOWS=1 SMALL=1 PREFIX="$LOCALDESTDIR" install-lib
        do_checkIfExist "${_check[@]}"
    fi
fi

if [[ $ffmpeg != "n" ]] && do_checkForOptions --enable-libilbc; then
    do_vcs "https://github.com/TimothyGu/libilbc.git"
    if [[ $compile = "true" ]]; then
        _check=(ilbc.h libilbc.{{l,}a,pc})
        do_autoreconf
        do_uninstall "${_check[@]}"
        do_separate_confmakeinstall
        do_checkIfExist "${_check[@]}"
    fi
fi

if [[ $flac = "y" || $sox = "y" ]] ||
    do_checkForOptions --enable-libtheora --enable-libvorbis --enable-libspeex; then
    do_pacman_install libogg &&
        do_uninstall include/ogg share/aclocal/ogg.m4 libogg.{l,}a ogg.pc
fi

if [[ $sox = "y" ]] || do_checkForOptions --enable-libvorbis --enable-libtheora; then
    do_pacman_install libvorbis &&
        do_uninstall include/vorbis share/aclocal/vorbis.m4 \
        libvorbis{,enc,file}.{l,}a vorbis{,enc,file}.pc
fi

if [[ $sox = "y" ]] || do_checkForOptions --enable-libopus; then
    if do_pkgConfig "opus = 1.1.2"; then
        _check=(libopus.{l,}a opus.pc)
        do_wget "http://downloads.xiph.org/releases/opus/opus-1.1.2.tar.gz"
        [[ -f ".libs/libopus.a" ]] && log "distclean" make distclean
        do_uninstall include/opus "${_check[@]}"

        # needed to allow building shared FFmpeg with libopus
        sed -i 's, __declspec(dllexport),,' include/opus_defines.h

        do_generic_confmakeinstall --disable-doc
        do_checkIfExist "${_check[@]}"
        buildOpusEnc="true"
    fi

    do_pacman_install opusfile &&
        do_uninstall opus/opusfile.h libopus{file,url}.{l,}a opus{file,url}.pc
fi

if { [[ $sox = "y" ]] || do_checkForOptions --enable-libspeex; } &&
    do_pkgConfig "speex = 1.2rc2"; then
    _check=(bin-audio/speex{enc,dec}.exe libspeex.{l,}a speex.pc)
    do_wget "http://downloads.xiph.org/releases/speex/speex-1.2rc2.tar.gz"
    [[ -f "libspeex/.libs/libspeex.a" ]] && log "distclean" make distclean
    do_uninstall include/speex "${_check[@]}"
    do_patch speex-mingw-winmm.patch
    do_generic_confmakeinstall audio --enable-vorbis-psy --enable-binaries
    do_checkIfExist "${_check[@]}"
fi

if [[ $flac = "y" || $sox = "y" ]]; then
    _check=(libFLAC.{l,}a bin-audio/flac.exe flac{,++}.pc)
    if do_pkgConfig "flac = 1.3.1" || ! files_exist "${_check[@]}"; then
    do_wget "http://downloads.xiph.org/releases/flac/flac-1.3.1.tar.xz"
    [[ -f "src/libFLAC/.libs/libFLAC.a" ]] && log "distclean" make distclean
    do_uninstall include/FLAC{,++} bin-audio/metaflac.exe "${_check[@]}"
    do_generic_confmakeinstall audio --disable-xmms-plugin --disable-doxygen-docs
    do_checkIfExist "${_check[@]}" bin-audio/metaflac.exe
    fi
fi

_check=(libvo-aacenc.{l,}a vo-aacenc.pc)
files_exist "${_check[@]}" && do_uninstall include/vo-aacenc "${_check[@]}"

if [[ $ffmpeg != "n" ]] && do_checkForOptions "--enable-libopencore-amr(wb|nb)"; then
    do_pacman_install "opencore-amr" &&
        do_uninstall include/opencore-amr{nb,wb} libopencore-amr{nb,wb}.{l,}a opencore-amr{nb,wb}.pc
fi

if { [[ $ffmpeg != "n" ]] && do_checkForOptions --enable-libvo-amrwbenc; } &&
    do_pkgConfig "vo-amrwbenc = 0.1.2"; then
    do_wget_sf "opencore-amr/vo-amrwbenc/vo-amrwbenc-0.1.2.tar.gz"
    [[ -f ".libs/libvo-amrwbenc.a" ]] && log "distclean" make distclean
    _check=(libvo-amrwbenc.{l,}a vo-amrwbenc.pc)
    do_uninstall include/vo-amrwbenc "${_check[@]}"
    do_generic_confmakeinstall
    do_checkIfExist "${_check[@]}"
fi

if { [[ $ffmpeg != "n" ]] && do_checkForOptions --enable-libfdk-aac; } ||
    [[ $fdkaac = "y" ]]; then
    do_vcs "https://github.com/mstorsjo/fdk-aac"
    if [[ $compile = "true" ]]; then
        _check=(libfdk-aac.{l,}a fdk-aac.pc)
        do_autoreconf
        [[ -f Makefile ]] && log "distclean" make distclean
        do_uninstall include/fdk-aac "${_check[@]}"
        CXXFLAGS+=" -O2 -fno-exceptions -fno-rtti" do_generic_confmakeinstall
        do_checkIfExist "${_check[@]}"
        buildFDK="true"
    fi
fi

if [[ $fdkaac = y ]]; then
    _check=(bin-audio/fdkaac.exe)
    do_vcs "https://github.com/nu774/fdkaac" bin-fdk-aac "${_check[@]}"
    if [[ $compile = "true" || $buildFDK = "true" ]]; then
        do_autoreconf
        [[ -f Makefile ]] && log "distclean" make distclean
        do_uninstall "${_check[@]}"
        CXXFLAGS+=" -O2" do_generic_confmakeinstall audio
        do_checkIfExist "${_check[@]}"
        unset buildFDK
    fi
fi

if do_checkForOptions --enable-libfaac; then
    _check=(bin-audio/faac.exe libfaac.a faac{,cfg}.h)
    if files_exist "${_check[@]}" &&
        [[ $(faac.exe) = *"FAAC 1.28"* ]]; then
        do_print_status "faac 1.28" "$green_color" "Up-to-date"
    else
        do_wget_sf "faac/faac-src/faac-1.28/faac-1.28.tar.bz2"
        sh bootstrap
        [[ -f Makefile ]] && log "distclean" make distclean
        do_uninstall "${_check[@]}"
        do_generic_confmakeinstall audio --without-mp4v2
        do_checkIfExist "${_check[@]}"
    fi
fi

_check=(bin-audio/oggenc.exe)
if [[ $standalone = y ]] && do_checkForOptions --enable-libvorbis &&
    ! files_exist "${_check[@]}"; then
    do_vcs "https://git.xiph.org/vorbis-tools.git" vorbis-tools
    _check+=(bin-audio/oggdec.exe)
    do_autoreconf
    [[ -f Makefile ]] && log "distclean" make distclean
    do_uninstall "${_check[@]}"
    do_generic_confmakeinstall audio --disable-ogg123 --disable-vorbiscomment \
        --disable-vcut --disable-ogginfo \
        "$(do_checkForOptions --enable-libspeex || echo "--without-speex")" \
        "$([[ $flac = "y" ]] || echo "--without-flac")"
    do_checkIfExist "${_check[@]}"
    _to_remove+=($(pwd))
fi

_check=(bin-audio/opusenc.exe)
if [[ $standalone = y ]] && do_checkForOptions --enable-libopus &&
    { ! files_exist "${_check[@]}" || [[ $buildOpusEnc = "true" ]]; }; then
    _check+=(bin-audio/opus{dec,info}.exe)
    do_wget "http://downloads.xiph.org/releases/opus/opus-tools-0.1.9.tar.gz"
    [[ -f "opusenc.exe" ]] && log "distclean" make distclean
    do_uninstall "${_check[@]}"
    do_generic_confmakeinstall audio LDFLAGS="$LDFLAGS -static -static-libgcc -static-libstdc++" \
        "$([[ $flac = y ]] || echo "--without-flac")"
    do_checkIfExist "${_check[@]}"
    unset buildOpusEnc
fi

if { [[ $ffmpeg != "n" ]] && do_checkForOptions --enable-libsoxr; } && do_pkgConfig "soxr = 0.1.2"; then
    _check=(soxr.h libsoxr.a soxr.pc)
    do_wget_sf "soxr/soxr-0.1.2-Source.tar.xz"
    sed -i 's|NOT WIN32|UNIX|g' ./src/CMakeLists.txt
    do_uninstall "${_check[@]}"
    do_cmakeinstall -DWITH_OPENMP=off -DWITH_LSR_BINDINGS=off
    sed -i "/Name:.*/ i\prefix=$LOCALDESTDIR\n" "$LOCALDESTDIR"/lib/pkgconfig/soxr.pc
    do_checkIfExist "${_check[@]}"
fi

if do_checkForOptions --enable-libmp3lame; then
    _check=(libmp3lame.{l,}a)
    _ver="3.99.5"
    [[ $standalone = y ]] && _check+=(bin-audio/lame.exe)
    if files_exist "${_check[@]}" &&
        grep -q "$_ver" "$LOCALDESTDIR/lib/libmp3lame.a"; then
        do_print_status "lame $_ver" "$green_color" "Up-to-date"
    else
        do_wget_sf "lame/lame/3.99/lame-${_ver}.tar.gz"
        if grep -q "xmmintrin\.h" configure.in configure; then
            do_patch lame-fixes.patch
            touch recently_updated
            do_autoreconf
        fi
        [[ -f libmp3lame/.libs/libmp3lame.a ]] && log "distclean" make distclean
        do_uninstall include/lame "${_check[@]}"
        do_generic_confmakeinstall audio --disable-decoder \
            $([[ $standalone = y ]] || echo "--disable-frontend")
        do_checkIfExist "${_check[@]}"
    fi
fi

if [[ $ffmpeg != "n" ]] && do_checkForOptions --enable-libgme; then
    _check=(libgme.{a,pc})
    do_vcs "https://bitbucket.org/mpyne/game-music-emu.git" libgme
    if [[ $compile = "true" ]]; then
        do_uninstall include/gme "${_check[@]}"
        do_cmakeinstall
        do_checkIfExist "${_check[@]}"
    fi
fi

if [[ $ffmpeg != "n" ]] && do_checkForOptions --enable-libtwolame; then
    do_pacman_install twolame &&
        do_uninstall twolame.h bin-audio/twolame.exe libtwolame.{l,}a twolame.pc
    do_addOption "--extra-cflags=-DLIBTWOLAME_STATIC"
fi

if { [[ $ffmpeg != "n" ]] && do_checkForOptions --enable-libbs2b; } &&
    do_pkgConfig "libbs2b = 3.1.0"; then
    _check=(libbs2b.{{l,}a,pc} )
    do_wget_sf "bs2b/libbs2b/3.1.0/libbs2b-3.1.0.tar.bz2"
    [[ -f "src/.libs/libbs2b.a" ]] && log "distclean" make distclean
    do_uninstall include/bs2b "${_check[@]}"
    do_patch "libbs2b-disable-sndfile.patch"
    do_patch "libbs2b-libs-only.patch"
    do_generic_confmakeinstall
    do_checkIfExist "${_check[@]}"
fi

if [[ $sox = "y" ]]; then
    do_vcs "https://github.com/erikd/libsndfile.git" sndfile
    if [[ $compile = "true" ]]; then
        _check=(libsndfile.{l,}a sndfile.{h,pc})
        do_autogen
        [[ -f Makefile ]] && log "distclean" make distclean
        do_uninstall include/sndfile.hh "${_check[@]}"
        do_generic_conf
        sed -i 's/ examples regtest tests programs//g' Makefile
        do_makeinstall
        do_checkIfExist "${_check[@]}"
    fi

    do_pacman_install "libmad"
    _check=(bin-audio/sox.exe)
    do_vcs "git://git.code.sf.net/p/sox/code" sox "${_check[@]}"
    if [[ $compile = "true" ]]; then
        sed -i 's|found_libgsm=yes|found_libgsm=no|g' configure.ac
        do_autoreconf
        [[ -f Makefile ]] && log "distclean" make distclean
        do_uninstall sox.{pc,h} bin-audio/{soxi,play,rec}.exe libsox.{l,}a "${_check[@]}"
        do_generic_confmake --disable-symlinks CPPFLAGS='-DPCRE_STATIC' \
            LIBS='-lpcre -lshlwapi -lz -lgnurx'
        install src/sox.exe "$LOCALDESTDIR"/bin-audio/
        do_checkIfExist "${_check[@]}"
    fi
fi

if [[ $ffmpeg != "n" ]] && do_checkForOptions --enable-libmodplug; then
    do_pacman_install "libmodplug"
    do_addOption "--extra-cflags=-DMODPLUG_STATIC"
fi

echo -e "\n\t${orange_color}Starting $bits compilation of video tools${reset_color}"

if [[ $rtmpdump = "y" || $mediainfo = "y" ]] ||
    { [[ $ffmpeg != "n" ]] && do_checkForOptions --enable-librtmp; }; then
    _check=(librtmp.{a,pc})
    [[ $rtmpdump = "y" ]] && _check+=(bin-video/rtmpdump.exe)
    do_vcs "git://repo.or.cz/rtmpdump.git" librtmp "${_check[@]}"
    req=""
    pc_exists librtmp && req="$(pkg-config --print-requires $LOCALDESTDIR/lib/pkgconfig/librtmp.pc)"
    if do_checkForOptions --enable-gnutls || [[ $rtmpdump = "y" && $license != "nonfree" ]]; then
        crypto=GNUTLS
        pc=gnutls
    else
        crypto=OPENSSL
        pc=libssl
    fi
    if [[ $compile = "true" ]] || [[ $req != *$pc* ]]; then
        do_uninstall include/librtmp bin-video/rtmp{dump,suck,srv,gw}.exe "${_check[@]}"
        [[ -f "librtmp/librtmp.a" ]] && log "clean" make clean
        do_makeinstall XCFLAGS="$CFLAGS -I$MINGW_PREFIX/include" XLDFLAGS="$LDFLAGS" SHARED= \
            SYS=mingw prefix="$LOCALDESTDIR" bindir="$LOCALDESTDIR"/bin-video \
            sbindir="$LOCALDESTDIR"/bin-video mandir="$LOCALDESTDIR"/share/man \
            CRYPTO=$crypto LIB_${crypto}="$(pkg-config --static --libs $pc) -lz"
        [[ $rtmpdump = y ]] && _check+=(bin-video/rtmp{suck,srv,gw}.exe)
        do_checkIfExist "${_check[@]}"
        unset crypto pc req
        buildMediaInfo="true"
    fi
fi

if [[ $ffmpeg != "n" ]] && do_checkForOptions --enable-libtheora; then
    do_pacman_install libtheora &&
        do_uninstall include/theora libtheora{,enc,dec}.{l,}a theora{,enc,dec}.pc
fi

if [[ ! $vpx = "n" ]]; then
    _check=(libvpx.a vpx.pc)
    [[ $vpx = "y" ]] && _check+=(bin-video/vpxenc.exe)
    do_vcs "https://github.com/webmproject/libvpx.git#commit=5232326716a" vpx "${_check[@]}"
    if [[ $compile = "true" ]]; then
        do_uninstall include/vpx bin-video/vpxdec.exe "${_check[@]}"
        [[ -f config.mk ]] && log "distclean" make distclean
        do_patch vpx-0001-Fix-compilation-with-mingw64.patch am
        [[ $bits = "32bit" ]] && target="x86-win32" || target="x86_64-win64"
        LDFLAGS+=" -static-libgcc -static" do_configure --target="${target}-gcc" \
            --disable-shared --enable-static --disable-unit-tests --disable-docs \
            --enable-postproc --enable-vp9-postproc --enable-runtime-cpu-detect \
            --enable-vp9-highbitdepth --prefix="$LOCALDESTDIR" \
            "$([[ $vpx = "l" ]] && echo "--disable-examples" || echo "--enable-vp10")"
        sed -i 's/HAVE_GNU_STRIP=yes/HAVE_GNU_STRIP=no/g' "libs-${target}-gcc.mk"
        do_makeinstall
        if [[ $vpx = "y" ]] && files_exist bin/vpx{enc,dec}.exe; then
            mv "$LOCALDESTDIR"/bin/vpx{enc,dec}.exe "$LOCALDESTDIR"/bin-video/
            _check+=(bin-video/vpxdec.exe)
        else
            rm -f "$LOCALDESTDIR"/bin/vpx{enc,dec}.exe
        fi
        do_checkIfExist "${_check[@]}"
        buildFFmpeg="true"
        unset target
    fi
else
    pc_exists vpx || do_removeOption "--enable-libvpx"
fi

if [[ $other265 = "y" ]] || { [[ $ffmpeg != "n" ]] && do_checkForOptions --enable-libkvazaar; }; then
    _check=(bin-video/kvazaar.exe libkvazaar.{,l}a kvazaar.pc kvazaar.h)
    do_vcs "https://github.com/ultravideo/kvazaar.git" kvazaar
    if [[ $compile = "true" ]]; then
        do_uninstall kvazaar_version.h "${_check[@]}"
        do_autogen
        [[ -f config.log ]] && log "distclean" make distclean
        do_generic_confmakeinstall video
        do_checkIfExist "${_check[@]}"
    fi
fi

if [[ $mplayer = "y" ]] || ! mpv_disabled_all dvdread dvdnav; then
    do_vcs "http://git.videolan.org/git/libdvdread.git" dvdread
    if [[ $compile = "true" ]]; then
        _check=(libdvdread.{l,}a dvdread.pc)
        do_autoreconf
        [[ -f Makefile ]] && log "distclean" make distclean
        do_uninstall include/dvdread "${_check[@]}"
        do_generic_confmakeinstall
        do_checkIfExist "${_check[@]}"
    fi
    grep -q 'ldl' "$LOCALDESTDIR"/lib/pkgconfig/dvdread.pc ||
        sed -i "/Libs:.*/ a\Libs.private: -ldl" "$LOCALDESTDIR"/lib/pkgconfig/dvdread.pc

    do_vcs "http://git.videolan.org/git/libdvdnav.git" dvdnav
    if [[ $compile = "true" ]]; then
        _check=(libdvdnav.{l,}a dvdnav.pc)
        do_autoreconf
        [[ -f Makefile ]] && log "distclean" make distclean
        do_uninstall include/dvdnav "${_check[@]}"
        do_generic_confmakeinstall
        do_checkIfExist "${_check[@]}"
    fi
fi

if { [[ $ffmpeg != "n" ]] && do_checkForOptions --enable-libbluray; } ||
    ! mpv_disabled libbluray; then
    do_vcs "http://git.videolan.org/git/libbluray.git"
    if [[ $compile = "true" ]]; then
        _check=(libbluray.{{l,}a,pc})
        do_autoreconf
        [[ -f Makefile ]] && log "distclean" make distclean
        do_uninstall include/bluray "${_check[@]}"
        do_generic_confmakeinstall --enable-static --disable-examples --disable-bdjava --disable-doxygen-doc \
        --disable-doxygen-dot --without-libxml2 --without-fontconfig --without-freetype --disable-udf
        do_checkIfExist "${_check[@]}"
    fi
fi

if [[ $ffmpeg != "n" ]] && do_checkForOptions --enable-libutvideo && do_pkgConfig "libutvideo = 15.1.0"; then
    do_vcs "https://github.com/qyot27/libutvideo.git#branch=15.1.0"
    if [[ $compile = "true" ]]; then
        _check=(libutvideo.{a,pc})
        do_uninstall include/utvideo "${_check[@]}"
        [[ -f config.log ]] && log "distclean" make distclean
        do_patch "libutvideo-0001-Avoid-_countof-and-DllMain-in-MinGW.patch" am
        do_configure --prefix="$LOCALDESTDIR"
        do_makeinstall
        do_checkIfExist "${_check[@]}"
    fi
fi

if [[ $mplayer = "y" ]] || ! mpv_disabled libass ||
    { [[ $ffmpeg != "n" ]] && do_checkForOptions --enable-libass; }; then
    do_vcs "https://github.com/libass/libass.git"
    if [[ $compile = "true" || $rebuildLibass = "y" ]]; then
        _check=(ass/ass{,_types}.h libass.{{,l}a,pc})
        do_autoreconf
        [[ -f Makefile ]] && log "distclean" make distclean
        do_uninstall "${_check[@]}"
        do_checkForOptions "--enable-(lib)?fontconfig" || disable_fc="--disable-fontconfig"
        do_generic_confmakeinstall $disable_fc
        do_checkIfExist "${_check[@]}"
        buildFFmpeg="true"
        unset rebuildLibass disable_fc
    fi
fi

if [[ $ffmpeg != "n" ]] && do_checkForOptions --enable-libxavs &&
    do_pkgConfig "xavs"; then
    do_vcs "https://github.com/Distrotech/xavs.git"
    _check=(libxavs.a xavs.{h,pc})
    [[ -f "libxavs.a" ]] && log "distclean" make distclean
    do_uninstall "${_check[@]}"
    sed -i 's,"NUL","/dev/null",g' configure
    do_configure --host="$MINGW_CHOST" --prefix="$LOCALDESTDIR"
    do_make libxavs.a
    cp -f xavs.h "$LOCALDESTDIR"/include
    cp -f libxavs.a "$LOCALDESTDIR"/lib
    cp -f xavs.pc "$LOCALDESTDIR"/lib/pkgconfig
    do_checkIfExist "${_check[@]}"
    _to_remove+=($(pwd))
fi

if [[ $mediainfo = "y" ]]; then
    do_vcs "https://github.com/MediaArea/ZenLib" libzen
    if [[ $compile = "true" || $buildMediaInfo = "true" ]]; then
        _check=(libzen.{{l,}a,pc})
        cd_safe Project/GNU/Library
        do_autoreconf
        [[ -f "Makefile" ]] && log "distclean" make distclean --ignore-errors
        do_uninstall include/ZenLib bin-global/libzen-config "${_check[@]}"
        do_generic_conf
        [[ $bits = "64bit" ]] && sed -i 's/ -DSIZE_T_IS_LONG//g' Makefile libzen.pc
        do_makeinstall
        rm -f "$LOCALDESTDIR"/bin/libzen-config
        do_checkIfExist "${_check[@]}"
        buildMediaInfo="true"
    fi

    # MinGW's libcurl.pc is missing libs
    sed -i 's/-lidn -lrtmp/-lidn -lintl -liconv -lrtmp/' "$MINGW_PREFIX"/lib/pkgconfig/libcurl.pc

    do_vcs "https://github.com/MediaArea/MediaInfoLib" libmediainfo
    if [[ $compile = "true" || $buildMediaInfo = "true" ]]; then
        _check=(libmediainfo.{{l,}a,pc})
        cd_safe Project/GNU/Library
        do_autoreconf
        [[ -f "Makefile" ]] && log "distclean" make distclean --ignore-errors
        do_uninstall include/MediaInfo{,DLL} bin-global/libmediainfo-config "${_check[@]}"
        LDFLAGS+=" -static" do_generic_conf --enable-staticlibs --with-libcurl
        do_makeinstall
        sed -i "s,libmediainfo\.a.*,libmediainfo.a $(pkg-config --static --libs libcurl librtmp libzen)," \
            libmediainfo.pc
        cp libmediainfo.pc "$LOCALDESTDIR"/lib/pkgconfig/
        do_checkIfExist "${_check[@]}"
        buildMediaInfo="true"
    fi

    _check=(bin-video/mediainfo.exe)
    do_vcs "https://github.com/MediaArea/MediaInfo" mediainfo "${_check[@]}"
    if [[ $compile = "true" || $buildMediaInfo = "true" ]]; then
        cd_safe Project/GNU/CLI
        do_autoreconf
        [[ -f "Makefile" ]] && log "distclean" make distclean --ignore-errors
        do_uninstall "${_check[@]}"
        LDFLAGS+=" -static-libgcc -static-libstdc++" do_generic_conf video --enable-staticlibs
        do_makeinstall
        do_checkIfExist "${_check[@]}"
    fi
fi

if [[ $ffmpeg != "n" ]] && do_checkForOptions --enable-libvidstab; then
    do_vcs "https://github.com/georgmartius/vid.stab.git" vidstab
    if [[ $compile = "true" ]]; then
        _check=(libvidstab.a vidstab.pc)
        do_uninstall include/vid.stab "${_check[@]}"
        do_cmakeinstall
        do_checkIfExist "${_check[@]}"
    fi
fi

if [[ $ffmpeg != "n" ]] && do_checkForOptions --enable-libcaca; then
    do_pacman_install "libcaca" &&
        do_uninstall libcaca.{l,}a caca.pc
    do_addOption "--extra-cflags=-DCACA_STATIC"
fi

if { [[ $ffmpeg != "n" ]] && do_checkForOptions --enable-libzvbi; } && do_pkgConfig "zvbi-0.2 = 0.2.35"; then
    _check=(libzvbi.{h,{l,}a} zvbi-0.2.pc)
    do_wget_sf "zapping/zvbi/0.2.35/zvbi-0.2.35.tar.bz2"
    [[ -f "src/.libs/libzvbi.a" ]] && log "distclean" make distclean
    do_uninstall "${_check[@]}"
    do_patch "zvbi-win32.patch"
    do_patch "zvbi-ioctl.patch"
    do_generic_conf --disable-dvb --disable-bktr --disable-nls --disable-proxy --without-doxygen \
    CFLAGS="$CFLAGS -DPTW32_STATIC_LIB" LIBS="$LIBS -lpng"
    cd_safe src
    do_makeinstall
    cp ../zvbi-0.2.pc "$LOCALDESTDIR"/lib/pkgconfig
    do_checkIfExist "${_check[@]}"
fi

if { [[ $ffmpeg != "n" ]] && do_checkForOptions --enable-frei0r; } && do_pkgConfig "frei0r = 1.3.0"; then
    _check=(frei0r.{h,pc})
    do_wget "https://files.dyne.org/frei0r/releases/frei0r-plugins-1.4.tar.gz"
    sed -i 's/find_package (Cairo)//' "CMakeLists.txt"
    do_uninstall lib/frei0r-1 "${_check[@]}"
    do_cmakeinstall -DCMAKE_BUILD_TYPE=Release
    pushd "$LOCALDESTDIR" >/dev/null
    _check+=($(find lib/frei0r-1 -name "*.dll"))
    popd >/dev/null
    do_checkIfExist "${_check[@]}"
fi

if [[ $ffmpeg != "n" ]] && do_checkForOptions --enable-decklink; then
    cd_safe "$LOCALBUILDDIR"
    _check=(DeckLinkAPI{,Version}.h include/DeckLinkAPI_i.c)
    _ver="10.5.4"
    if files_exist "${_check[@]}" &&
        [[ $_ver = $(get_api_version "$LOCALDESTDIR/include/DeckLinkAPIVersion.h" VERSION_STRING) ]]; then
        do_print_status "DeckLinkAPI $_ver" "$green_color" "Up-to-date"
    else
        mkdir -p DeckLinkAPI && cd_safe DeckLinkAPI
        [[ ! -f recently_updated ]] && rm -f DeckLinkAPI{{,Version}.h,_i.c}
        for file in DeckLinkAPI{{,Version}.h,_i.c}; do
            [[ ! -f "$file" ]] &&
                curl -OLs "https://github.com/jb-alvarado/media-autobuild_suite/raw/master/build/extras/$file" &&
                touch recently_updated
            cp -f "$file" "$LOCALDESTDIR"/include/
        done
        do_checkIfExist "${_check[@]}"
    fi
fi

if [[ $ffmpeg != "n" ]] && do_checkForOptions --enable-nvenc; then
    cd_safe "$LOCALBUILDDIR"
    _ver="6"
    _check=(nvEncodeAPI.h)
    if files_exist "${_check[@]}" &&
        [[ "$_ver" = $(get_api_version "$LOCALDESTDIR"/include/nvEncodeAPI.h MAJOR | head -n1) ]]; then
        do_print_status "nvEncodeAPI ${_ver}.0.1" "$green_color" "Up-to-date"
    else
        do_uninstall {cudaModuleMgr,drvapi_error_string,exception}.h \
            helper_{cuda{,_drvapi},functions,string,timer}.h \
            {nv{CPUOPSys,FileIO,Utils},NvHWEncoder}.h "${_check[@]}"
        mkdir -p NvEncAPI && cd_safe NvEncAPI
        [[ -f recently_updated ]] || rm -f "$_check"
        [[ ! -f "$_check" ]] &&
            curl -OLs \
            "https://github.com/jb-alvarado/media-autobuild_suite/raw/master/build/extras/$_check" &&
            touch recently_updated
        cp -f "$_check" "$LOCALDESTDIR"/include/
        do_checkIfExist "${_check[@]}"
    fi
fi

if [[ $ffmpeg != "n" ]] && do_checkForOptions --enable-libmfx; then
    do_vcs "https://github.com/lu-zero/mfx_dispatch.git" libmfx
    if [[ $compile = "true" ]]; then
        _check=(libmfx.{{l,}a,pc})
        do_autoreconf
        [[ -f Makefile ]] && log "distclean" make distclean
        do_uninstall include/mfx "${_check[@]}"
        do_generic_confmakeinstall
        do_checkIfExist "${_check[@]}"
    fi
fi

if [[ $ffmpeg != "n" ]] && do_checkForOptions --enable-libcdio; then
    [[ -d "$LOCALBUILDDIR/libcdio_paranoia-git" ]] &&
        _to_remove+=("$LOCALBUILDDIR/libcdio_paranoia-git") &&
        do_uninstall include/cdio libcdio_{cdda,paranoia}.{{l,}a,pc} bin-audio/cd-paranoia.exe
    do_pacman_install "libcddb libcdio libcdio-paranoia"
fi

if [[ $mp4box = "y" ]]; then
    _check=(bin-video/MP4Box.exe libgpac_static.a)
    do_vcs "https://github.com/gpac/gpac.git" gpac "${_check[@]}"
    if [[ $compile = "true" ]]; then
        do_uninstall include/gpac "${_check[@]}"
        [[ -f config.mak ]] && log "distclean" make distclean
        do_configure --prefix="$LOCALDESTDIR" --static-mp4box
        do_make
        log "install" make install-lib
        cp bin/gcc/MP4Box.exe "$LOCALDESTDIR"/bin-video
        do_checkIfExist "${_check[@]}"
    fi
fi

if [[ $x264 != "n" ]]; then
    do_vcs "http://git.videolan.org/git/x264.git"
    if [[ $compile = "true" ]] || { [[ $x264 != "l" ]] && ! files_exist bin-video/x264.exe; }; then
        extracommands=("--host=$MINGW_CHOST" "--prefix=$LOCALDESTDIR" --enable-static --enable-win32thread)
        if [[ $x264 = "f" ]]; then
            _check=(libav{codec,format}.{a,pc})
            do_vcs "http://source.ffmpeg.org/git/ffmpeg.git" ffmpeg "${_check[@]}"
            do_uninstall include/lib{av{codec,device,filter,format,util,resample},{sw{scale,resample},postproc}} \
                lib{av{device,filter,util,resample},sw{scale,resample},postproc}.{a,pc} "${_check[@]}"
            [[ -f "config.mak" ]] && log "distclean" make distclean
            do_configure "${FFMPEG_BASE_OPTS[@]}" --prefix="$LOCALDESTDIR" --disable-programs \
            --disable-devices --disable-filters --disable-encoders --disable-muxers
            do_makeinstall
            do_checkIfExist "${_check[@]}"
            cd_safe "$LOCALBUILDDIR"/x264-git
        else
            extracommands+=(--disable-lavf --disable-swscale --disable-ffms)
        fi

        if [[ $x264 != "l" ]]; then
            do_vcs "https://github.com/l-smash/l-smash.git" liblsmash
            if [[ $compile = "true" ]]; then
                _check=(lsmash.h liblsmash.{a,pc})
                [[ -f "config.mak" ]] && log "distclean" make distclean
                do_uninstall "${_check[@]}"
                do_configure --prefix="$LOCALDESTDIR"
                do_make install-lib
                do_checkIfExist "${_check[@]}"
            fi
            cd_safe "$LOCALBUILDDIR"/x264-git
            # x264 prefers and only uses lsmash if available
            extracommands+=(--disable-gpac)
        else
            extracommands+=(--disable-lsmash)
        fi

        _check=(x264{,_config}.h libx264.a x264.pc)
        [[ -f "libx264.a" ]] && log "distclean" make distclean
        if [[ $x264 != "l" ]]; then
            _check+=(bin-video/x264{,-10bit}.exe)
            do_uninstall "${_check[@]}"
            extracommands+=("--bindir=$LOCALDESTDIR/bin-video")
            CFLAGS="${CFLAGS// -O2 / }" do_configure --bit-depth=10 "${extracommands[@]}"
            do_make
            cp x264.exe "$LOCALDESTDIR"/bin-video/x264-10bit.exe
            log "clean" make clean
        else
            do_uninstall "${_check[@]}"
            extracommands+=(--disable-interlaced --disable-gpac --disable-cli)
        fi
        CFLAGS="${CFLAGS// -O2 / }" do_configure --bit-depth=8 "${extracommands[@]}"
        do_makeinstall
        do_checkIfExist "${_check[@]}"
        buildFFmpeg="true"
        unset extracommands
    fi
else
    pc_exists x264 || do_removeOption "--enable-libx264"
fi

if [[ ! $x265 = "n" ]]; then
    do_vcs "hg::https://bitbucket.org/multicoreware/x265"
    _check=(x265{,_config}.h libx265.a x265.pc)
    [[ $x265 != "l"* ]] && _check+=(bin-video/x265.exe)
    if [[ $compile = "true" ]] || ! files_exist "${_check[@]}"; then
        do_patch "x265-revid.patch"
        cd_safe build/msys
        do_uninstall libx265{_main10,_main12}.a bin-video/libx265_main{10,12}.dll "${_check[@]}"
        [[ $bits = "32bit" ]] && assembly="-DENABLE_ASSEMBLY=OFF" || assembly="-DENABLE_ASSEMBLY=ON"
        [[ $xpcomp = "y" ]] && xpsupport="-DWINXP_SUPPORT=ON" || xpsupport="-DWINXP_SUPPORT=OFF"

        build_x265() {
        rm -rf "$LOCALBUILDDIR"/x265-hg/build/msys/{8,10,12}bit

        do_x265_cmake() {
            CFLAGS+=" -static-libgcc -static-libstdc++" \
            CXXFLAGS+=" -static-libgcc -static-libstdc++" \
            log "cmake" cmake ../../../source -G Ninja $xpsupport -DHG_EXECUTABLE=/usr/bin/hg.bat \
            -DCMAKE_INSTALL_PREFIX="$LOCALDESTDIR" -DBIN_INSTALL_DIR="$LOCALDESTDIR"/bin-video \
            -DENABLE_SHARED=OFF -DENABLE_CLI=OFF -DHIGH_BIT_DEPTH=ON -DEXPORT_C_API=ON "$@"
            log "ninja" ninja -j "${cpuCount:=1}"
        }
        mkdir -p {8,10,12}bit

        if [[ $x265 != *8 ]]; then
            cd_safe 12bit
            if [[ $x265 = "s" ]]; then
                # libx265_main12.dll
                do_x265_cmake $assembly -DENABLE_SHARED=ON -DMAIN12=ON
                cp libx265.dll "$LOCALDESTDIR"/bin-video/libx265_main12.dll
            else
                # multilib
                do_x265_cmake $assembly -DEXPORT_C_API=OFF -DMAIN12=ON
                cp libx265.a ../8bit/libx265_main12.a
            fi

            cd_safe ../10bit
            if [[ $x265 = "s" ]]; then
                # libx265_main10.dll
                do_x265_cmake $assembly -DENABLE_SHARED=ON
                cp libx265.dll "$LOCALDESTDIR"/bin-video/libx265_main10.dll
            else
                # multilib
                do_x265_cmake $assembly -DEXPORT_C_API=OFF
                cp libx265.a ../8bit/libx265_main10.a
            fi
            cd_safe ..
        fi

        cd_safe 8bit
        if [[ $x265 = "s" || $x265 = *8 ]]; then
            # 8-bit static x265.exe/library
            [[ $x265 != "l8" ]] && cli="-DENABLE_CLI=ON"
            do_x265_cmake $cli -DHIGH_BIT_DEPTH=OFF
        else
            # multilib
            [[ $x265 != "l" ]] && cli="-DENABLE_CLI=ON"
            do_x265_cmake -DEXTRA_LIB="x265_main10.a;x265_main12.a" -DEXTRA_LINK_FLAGS=-L. $cli \
                -DHIGH_BIT_DEPTH=OFF -DLINKED_10BIT=ON -DLINKED_12BIT=ON
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
        log "install" ninja -j "${cpuCount:=1}" install
        if [[ $x265 = "d" ]]; then
            cd_safe ..
            do_uninstall bin-video/x265-numa.exe
            xpsupport="-DWINXP_SUPPORT=OFF"
            build_x265
            cp -f x265.exe "$LOCALDESTDIR"/bin-video/x265-numa.exe
            _check+=(bin-video/x265-numa.exe)
        fi
        do_checkIfExist "${_check[@]}"
        buildFFmpeg="true"
        unset xpsupport assembly cli
    fi
else
    pc_exists x265 || do_removeOption "--enable-libx265"
fi

if [[ $ffmpeg != "n" ]]; then
    do_checkForOptions --enable-gcrypt && do_pacman_install libgcrypt
    do_checkForOptions --enable-libschroedinger && do_pacman_install schroedinger
    do_checkForOptions --enable-libgsm && do_pacman_install gsm
    do_checkForOptions --enable-libwavpack && do_pacman_install wavpack
    do_checkForOptions --enable-libsnappy && do_pacman_install snappy
    if do_checkForOptions --enable-libxvid; then
        do_pacman_install xvidcore
        [[ -f $MINGW_PREFIX/lib/xvidcore.a ]] && mv -f "$MINGW_PREFIX"/lib/{,lib}xvidcore.a
        [[ -f $MINGW_PREFIX/lib/xvidcore.dll.a ]] && mv -f "$MINGW_PREFIX"/lib/xvidcore.dll.a{,.dyn}
        [[ -f $MINGW_PREFIX/bin/xvidcore.dll ]] && mv -f "$MINGW_PREFIX"/bin/xvidcore.dll{,.disabled}
    fi
    if do_checkForOptions --enable-libssh; then
        do_pacman_install libssh
        do_addOption "--extra-cflags=-DLIBSSH_STATIC"
        do_addOption "--extra-ldflags=-Wl,--allow-multiple-definition"
        grep -q "Requires.private" "$MINGW_PREFIX"/lib/pkgconfig/libssh.pc ||
            sed -i "/Libs:/ i\Requires.private: libssl" "$MINGW_PREFIX"/lib/pkgconfig/libssh.pc
    fi
    do_hide_all_sharedlibs

    if [[ $ffmpeg = "s" ]]; then
        _check=(bin-video/ffmpegSHARED/ffmpeg.exe)
    else
        _check=(bin-video/ffmpeg.exe libavcodec.{a,pc})
    fi
    do_vcs "http://source.ffmpeg.org/git/ffmpeg.git" ffmpeg "${_check[@]}"
    if [[ $compile = "true" ]] || [[ $buildFFmpeg = "true" && $ffmpegUpdate = "y" ]]; then
        do_changeFFmpegConfig $license
        do_checkForOptions --enable-libgme "--enable-libopencore-amr(nb|wb)" --enable-libtheora \
            --enable-libtwolame --enable-libvorbis --enable-openssl --enable-libcdio &&
            do_patch "ffmpeg-0001-configure-Try-pkg-config-first-with-a-few-libs.patch" am
        do_patch "ffmpeg-0002-add-openhevc-intrinsics.patch" am

        _uninstall=(include/lib{av{codec,device,filter,format,util,resample},{sw{scale,resample},postproc}}
            lib{av{codec,device,filter,format,util,resample},sw{scale,resample},postproc}.{a,pc})
        sedflags="prefix|bindir|extra-(cflags|libs|ldflags)|pkg-config-flags"

        # shared
        if [[ $ffmpeg != "y" ]] && [[ ! -f build_successful${bits}_shared ]]; then
            do_print_progress "Compiling ${bold_color}shared${reset_color} FFmpeg"
            [[ -f config.mak ]] && log "distclean" make distclean
            do_uninstall bin-video/ffmpegSHARED "${_uninstall[@]}"
            do_configure --prefix="$LOCALDESTDIR/bin-video/ffmpegSHARED" \
                --disable-static --enable-shared "${FFMPEG_OPTS_SHARED[@]}"
            # cosmetics
            sed -ri "s/ ?--($sedflags)=(\S+[^\" ]|'[^']+')//g" config.h
            do_makeinstall
            do_checkIfExist bin-video/ffmpegSHARED/bin/ffmpeg.exe
            [[ $ffmpeg = "b" ]] && [[ -f build_successful${bits} ]] &&
                mv build_successful"${bits}"{,_shared} && mv ab-suite.{,shared.}configure.log &&
                mv ab-suite.{,shared.}configure.error.log && mv ab-suite.{,shared.}install.log &&
                mv ab-suite.{,shared.}install.error.log
            do_checkForOptions --enable-debug &&
                create_debug_link "$LOCALDESTDIR"/ffmpegSHARED/bin/ff{mpeg,probe,play}.exe
        fi

        # static
        if [[ $ffmpeg != "s" ]]; then
            do_print_progress "Compiling ${bold_color}static${reset_color} FFmpeg"
            [[ -f config.mak ]] && log "distclean" make distclean
            do_uninstall bin-video/ff{mpeg,play,probe}.exe{,.debug} "${_uninstall[@]}"
            do_configure --prefix="$LOCALDESTDIR" --bindir="$LOCALDESTDIR"/bin-video "${FFMPEG_OPTS[@]}"
            # cosmetics
            sed -ri "s/ ?--($sedflags)=(\S+[^\" ]|'[^']+')//g" config.h
            do_makeinstall
            do_checkIfExist "${_check[@]}"
            newFfmpeg="yes"
            do_checkForOptions --enable-debug &&
                create_debug_link "$LOCALDESTDIR"/bin-video/ff{mpeg,probe,play}.exe
        fi
    fi
fi

if [[ $bits = "64bit" && $other265 = "y" ]]; then
    _check=(bin-video/f265cli.exe)
if files_exist "${_check[@]}"; then
    do_print_status "f265 snapshot" "$green_color" "Up-to-date"
else
    do_wget "http://f265.org/f265/static/bin/f265_development_snapshot.zip"
    rm -rf f265 && mv f265_development_snapshot f265 && cd_safe f265
    if [ -d "build" ]; then
        rm -rf build .sconf_temp
        rm -f .sconsign.dblite config.log options.py
    fi
    log "scons" scons libav=none
    [[ -f build/f265cli.exe ]] && cp build/f265cli.exe "$LOCALDESTDIR"/bin-video/f265cli.exe
    do_checkIfExist "${_check[@]}"
fi
fi

if [[ $mplayer = "y" ]]; then
    [[ $license != "nonfree" ]] && faac=(--disable-faac --disable-faac-lavc)
    _check=(bin-video/m{player,encoder}.exe)
    do_vcs "svn::svn://svn.mplayerhq.hu/mplayer/trunk" mplayer "${_check[@]}"

    if [[ $compile == "true" ]] || [[ $buildFFmpeg == "true" ]]; then
        do_uninstall "${_check[@]}"
        [[ -f config.mak ]] && log "distclean" make distclean
        if [[ ! -d ffmpeg ]]; then
            if [[ "$ffmpeg" != "n" ]] &&
                git clone -q "$LOCALBUILDDIR"/ffmpeg-git ffmpeg; then
                pushd ffmpeg >/dev/null
                git checkout -qf --no-track -B master origin/HEAD
                popd >/dev/null
            elif ! git clone http://source.ffmpeg.org/git/ffmpeg.git ffmpeg; then
                rm -rf ffmpeg
                echo "Failed to get a FFmpeg checkout"
                echo "Please try again or put FFmpeg source code copy into ffmpeg/ manually."
                echo "Nightly snapshot: http://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2"
                echo "Either re-run the script or extract above to inside /build/mplayer-svn."
                do_prompt "<Enter> to continue or <Ctrl+c> to exit the script"
            fi
        fi
        if [[ -d ffmpeg ]]; then
            cd_safe ffmpeg
            git fetch -q origin
            git checkout -qf --no-track -B master origin/HEAD
            cd_safe ..
        else
            compilation_fail "Finding valid ffmpeg dir"
        fi

        grep -q "windows" libmpcodecs/ad_spdif.c ||
            sed -i '/#include "mp_msg.h/ a\#include <windows.h>' libmpcodecs/ad_spdif.c

        _notrequired="true"
        do_configure --prefix="$LOCALDESTDIR" --bindir="$LOCALDESTDIR"/bin-video --cc=gcc \
        --extra-cflags='-DPTW32_STATIC_LIB -O3 -std=gnu99 -DMODPLUG_STATIC' \
        --extra-libs='-llzma -lfreetype -lz -lbz2 -liconv -lws2_32 -lpthread -lwinpthread -lpng -lwinmm -ldl' \
        --extra-ldflags='-Wl,--allow-multiple-definition' --enable-static --enable-runtime-cpudetection \
        --disable-gif --disable-cddb "${faac[@]}" --with-dvdread-config="$PKG_CONFIG dvdread" \
        --with-freetype-config="$PKG_CONFIG freetype2" --with-dvdnav-config="$PKG_CONFIG dvdnav" &&
        do_makeinstall &&
        do_checkIfExist "${_check[@]}"
        unset _notrequired
    fi
fi

if [[ $xpcomp = "n" && $mpv != "n" ]] && pc_exists libavcodec libavformat libswscale; then
    [[ -d $LOCALBUILDDIR/waio-git ]] && do_uninstall include/waio libwaio.a &&
        _to_remove+=("$LOCALBUILDDIR/waio-git")

    if ! mpv_disabled lua && [[ ${MPV_OPTS[@]} != ${MPV_OPTS[@]#--lua=lua51} ]]; then
        do_pacman_install lua51
    elif ! mpv_disabled lua; then
        do_pacman_remove lua51
    if do_pkgConfig luajit; then
        _check=(libluajit-5.1.a luajit.pc luajit-2.0/luajit.h)
        do_vcs "http://luajit.org/git/luajit-2.0.git" luajit
        do_uninstall include/luajit-2.0 lib/lua "${_check[@]}"
        rm -rf ./temp
        [[ -f "src/luajit.exe" ]] && log "clean" make clean
        do_make BUILDMODE=static amalg
        do_makeinstall BUILDMODE=static PREFIX="$LOCALDESTDIR" DESTDIR="$(pwd)/temp"
        cp -rf temp/"$LOCALDESTDIR"/{lib,include} "$LOCALDESTDIR"/
        # luajit comes with a broken .pc file
        sed -r -i "s/(Libs.private:).*/\1 -liconv/" "$LOCALDESTDIR"/lib/pkgconfig/luajit.pc
        do_checkIfExist "${_check[@]}"
        _to_remove+=($(pwd))
    fi
    fi

    do_pacman_remove "uchardet-git"
    if ! mpv_disabled uchardet; then
        do_vcs "https://github.com/BYVoid/uchardet.git"
        if [[ $compile = "true" ]]; then
            _check=(uchardet/uchardet.h uchardet.pc libuchardet.a bin-global/uchardet.exe)
            do_uninstall "${_check[@]}"
            do_patch "uchardet-0001-CMake-allow-static-only-builds.patch" am
            grep -q "Libs.private" uchardet.pc.in ||
                sed -i "/Cflags:/ i\Libs.private: -lstdc++" uchardet.pc.in
            LDFLAGS+=" -static" do_cmakeinstall -DCMAKE_INSTALL_BINDIR="$LOCALDESTDIR"/bin-global
            do_checkIfExist "${_check[@]}"
        fi
    fi

    mpv_enabled libarchive && do_pacman_install libarchive
    ! mpv_disabled lcms2 && do_pacman_install lcms2

    if ! mpv_disabled egl-angle; then
    _check=(libEGL.{a,pc} libGLESv2.a)
    do_vcs "https://github.com/wiiaboo/angleproject.git" angleproject "${_check[@]}"
    if [[ $compile = "true" ]]; then
        log "uninstall" make PREFIX="$LOCALDESTDIR" uninstall
        [[ -f libEGL.a ]] && log "clean" make clean
        do_makeinstall PREFIX="$LOCALDESTDIR"
        do_checkIfExist "${_check[@]}"
    fi
    fi

    vsprefix=$(get_vs_prefix)
    if ! mpv_disabled vapoursynth && [[ -n $vsprefix ]]; then
        cd_safe "$LOCALBUILDDIR"
        vsversion=$("$vsprefix"/vspipe -v | grep -Po "(?<=Core R)\d+")
        if [[ $vsversion -ge 24 ]]; then
            echo -e "${orange_color}Compiling mpv with Vapoursynth R${vsversion}${reset_color}"
        else
            vsprefix=""
            echo -e "${red_color}Update to at least Vapoursynth R24 to use with mpv${reset_color}"
        fi
        _check=(lib{vapoursynth,vsscript}.a vapoursynth{,-script}.pc
            vapoursynth/{VS{Helper,Script},VapourSynth}.h)
        if [[ x"$vsprefix" != x ]] &&
            { ! pc_exists "vapoursynth = $vsversion" || ! files_exist "${_check[@]}"; }; then
            do_uninstall {vapoursynth,vsscript}.lib "${_check[@]}"
            baseurl="https://github.com/vapoursynth/vapoursynth/raw/master"
            # headers
            mkdir -p "$LOCALDESTDIR"/include/vapoursynth &&
                cd_safe "$LOCALDESTDIR"/include/vapoursynth
            for _file in {VS{Helper,Script},VapourSynth}.h; do
                curl -sLO "${baseurl}/include/${_file}"
            done

            # import libs
            cd_safe "$LOCALDESTDIR"/lib
            for _file in vapoursynth vsscript; do
                gendef - "$vsprefix/${_file}.dll" 2>/dev/null |
                    sed -r -e 's|^_||' -e 's|@[1-9]+$||' > "${_file}.def"
                dlltool -l "lib${_file}.a" -d "${_file}.def" 2>/dev/null
                rm -f "${_file}.def"
            done

            curl -sL "$baseurl/pc/vapoursynth.pc.in" |
            sed -e "s;@prefix@;$LOCALDESTDIR;" \
                -e 's;@exec_prefix@;${prefix};' \
                -e 's;@libdir@;${prefix}/lib;' \
                -e 's;@includedir@;${prefix}/include;' \
                -e "s;@VERSION@;$vsversion;" \
                -e '/Libs.private/ d' \
                > pkgconfig/vapoursynth.pc
            curl -sL "$baseurl/pc/vapoursynth-script.pc.in" |
            sed -e "s;@prefix@;$LOCALDESTDIR;" \
                -e 's;@exec_prefix@;${prefix};' \
                -e 's;@libdir@;${prefix}/lib;' \
                -e 's;@includedir@;${prefix}/include;' \
                -e "s;@VERSION@;$vsversion;" \
                -e '/Requires.private/ d' \
                -e 's;lvapoursynth-script;lvsscript;' \
                -e '/Libs.private/ d' \
                > pkgconfig/vapoursynth-script.pc

            do_checkIfExist "${_check[@]}"
            newFfmpeg="yes"
        elif [[ -z "$vsprefix" ]]; then
            mpv_disable vapoursynth
        fi
        unset vsprefix vsversion _file baseurl
    elif ! mpv_disabled vapoursynth; then
        mpv_disable vapoursynth
    fi

    _check=(bin-video/mpv.{exe,com})
    do_vcs "https://github.com/mpv-player/mpv.git" mpv "${_check[@]}"
    if [[ $compile = "true" ]] || [[ $newFfmpeg = "yes" ]]; then
        # mpv uses libs from pkg-config but randomly uses MinGW's librtmp.a which gets compiled
        # with GnuTLS. If we didn't compile ours with GnuTLS the build fails on linking.
        hide_files "$MINGW_PREFIX"/lib/lib{rtmp,harfbuzz}.a

        [[ ! -f waf ]] && /usr/bin/python bootstrap.py >/dev/null 2>&1
        if [[ -d build ]]; then
            /usr/bin/python waf distclean >/dev/null 2>&1
            do_uninstall bin-video/mpv.exe.debug "${_check[@]}"
        fi

        # for purely cosmetic reasons, show the last release version when doing -V
        git describe --tags "$(git rev-list --tags --max-count=1)" | cut -c 2- > VERSION
        mpv_ldflags=()
        [[ $bits = "64bit" ]] && mpv_ldflags+=("-Wl,--image-base,0x140000000,--high-entropy-va")
        do_checkForOptions --enable-libssh && mpv_ldflags+=("-Wl,--allow-multiple-definition")
        ! mpv_disabled egl-angle && do_patch "mpv-0001-waf-Use-pkgconfig-with-ANGLE.patch" am
        [[ $license = *v3 || $license = nonfree ]] && MPV_OPTS+=("--enable-gpl3")

        LDFLAGS+=" ${mpv_ldflags[*]}" log configure /usr/bin/python waf configure \
            "--prefix=$LOCALDESTDIR" "--bindir=$LOCALDESTDIR/bin-video" --enable-static-build \
            --disable-libguess --disable-vapoursynth-lazy "${MPV_OPTS[@]}"

        # Windows(?) has a lower argument limit than *nix so
        # we replace tons of repeated -L flags with just two
        replace="LIBPATH_lib\1 = ['${LOCALDESTDIR}/lib','${MINGW_PREFIX}/lib']"
        sed -r -i "s:LIBPATH_lib(ass|av(|device|filter)) = .*:$replace:g" ./build/c4che/_cache.py

        log "install" /usr/bin/python waf install -j "${cpuCount:=1}"

        unset mpv_ldflags replace withvs
        unhide_files "$MINGW_PREFIX"/lib/lib{rtmp,harfbuzz}.a
        ! mpv_disabled debug-build &&
            create_debug_link "$LOCALDESTDIR"/bin-video/mpv.exe
        do_checkIfExist "${_check[@]}"
    fi
fi

if [[ $bmx = "y" ]]; then
    _ver="0.8.2"
    if do_pkgConfig "liburiparser = $_ver"; then
        _check=(liburiparser.{{,l}a,pc})
        do_wget_sf "uriparser/Sources/${_ver}/uriparser-${_ver}.tar.bz2"
        do_uninstall include/uriparser "${_check[@]}"
        [[ -f Makefile ]] && log distclean make distclean
        sed -i '/bin_PROGRAMS/ d' Makefile.am
        do_generic_confmakeinstall --disable-test --disable-doc
        do_checkIfExist "${_check[@]}"
        buildBmx="true"
    fi

    do_vcs git://git.code.sf.net/p/bmxlib/libmxf libMXF-1.0
    if [[ $compile = "true" || $buildBmx = "true" ]]; then
        _check=(bin-video/MXFDump.exe libMXF-1.0.{{,l}a,pc})
        sed -i 's| mxf_win32_mmap.c||' mxf/Makefile.am
        do_autogen
        do_uninstall include/libMXF-1.0 "${_check[@]}"
        [[ -f Makefile ]] && log distclean make distclean
        LDFLAGS+=" -static-libgcc" do_generic_confmakeinstall video \
            --disable-examples
        do_checkIfExist "${_check[@]}"
        buildBmx="true"
    fi

    do_vcs git://git.code.sf.net/p/bmxlib/libmxfpp libMXF++-1.0
    if [[ $compile = "true" || $buildBmx = "true" ]]; then
        _check=(libMXF++-1.0.{{,l}a,pc})
        do_autogen
        do_uninstall include/libMXF++-1.0 "${_check[@]}"
        [[ -f Makefile ]] && log distclean make distclean
        do_generic_confmakeinstall video --disable-examples
        do_checkIfExist "${_check[@]}"
        buildBmx="true"
    fi

    _check=(bin-video/{bmxtranswrap,{h264,mov}dump,mxf2raw,raw2bmx}.exe)
    do_vcs git://git.code.sf.net/p/bmxlib/bmx bmx "${_check[@]}"
    if [[ $compile = "true" || $buildBmx = "true" ]]; then
        do_patch bmx-0001-configure-no-libcurl.patch am
        do_patch bmx-0002-avoid-mmap-in-MinGW.patch am
        do_autogen
        do_uninstall libbmx-0.1.{{,l}a,pc} bin-video/bmxparse.exe \
            include/bmx-0.1 "${_check[@]}"
        LDFLAGS+=" -static -static-libgcc -static-libstdc++" \
            do_separate_confmakeinstall video
        do_checkIfExist "${_check[@]}"
    fi
fi

echo -e "\n\t${orange_color}Finished $bits compilation of all tools${reset_color}"
}

run_builds() {
    new_updates="no"
    new_updates_packages=""
    if [[ $build32 = "yes" ]]; then
        source /local32/etc/profile.local
        buildProcess
    fi

    if [[ $build64 = "yes" ]]; then
        source /local64/etc/profile.local
        buildProcess
    fi
}

cd_safe "$LOCALBUILDDIR"
unset _to_remove
run_builds

while [[ $new_updates = "yes" ]]; do
    ret="no"
    echo "-------------------------------------------------------------------------------"
    echo "There were new updates while compiling."
    echo "Updated:$new_updates_packages"
    echo "Would you like to run compilation again to get those updates? Default: no"
    do_prompt "y/[n] "
    echo "-------------------------------------------------------------------------------"
    if [[ $ret = "y" || $ret = "Y" || $ret = "yes" ]]; then
        run_builds
    else
        break
    fi
done

if [[ $packing = "y" ]]; then
    if [ ! -f "$LOCALBUILDDIR/upx391w/upx.exe" ]; then
        rm -rf upx391w
        do_wget_sf "upx/upx/3.91/upx391w.zip"
    fi
    echo -e "\n\t${orange_color}Packing binaries and shared libs...${reset_color}"
    packcmd=("$LOCALBUILDDIR/upx391w/upx.exe" "-9" "-qq")
    [[ $stripping = "y" ]] && packcmd+=("--strip-relocs=0")
    find /local*/bin-* -regex ".*\.\(exe\|dll\)" -newer "$LOCALBUILDDIR"/last_run -print0 |
        xargs -0 -r "${packcmd[@]}"
fi

echo -e "\n\t${orange_color}Deleting status files...${reset_color}"
cd_safe "$LOCALBUILDDIR"
find . -maxdepth 2 -name recently_updated -print0 | xargs -0 rm -f
find . -maxdepth 2 -regex ".*build_successful\(32\|64\)bit\(_shared\)?\$" -print0 |
    xargs -0 rm -f
find . -maxdepth 5 -name "ab-suite.*.log" -print0 | xargs -0 rm -f
[[ -f last_run ]] && mv last_run last_successful_run
[[ -f CHANGELOG.txt ]] && cat CHANGELOG.txt >> newchangelog
unix2dos -n newchangelog CHANGELOG.txt 2> /dev/null && rm -f newchangelog
rm -f {firstrun,firstUpdate,secondUpdate,pacman,mingw32,mingw64}.log

if [[ $deleteSource = "y" ]]; then
    echo -e "\n\t${orange_color}Deleting source folders...${reset_color}"
    find "$LOCALBUILDDIR" -mindepth 1 -maxdepth 1 -type d \
        ! -regex ".*\(-\(git\|hg\|svn\)\|upx.*\|extras\|patches\)\$" -print0 |
        xargs -0 rm -rf
    echo "${_to_remove[@]}" | xargs -r rm -rf
    unset _to_remove
fi

echo -e "\n\t${green_color}Compilation successful.${reset_color}"
echo -e "\t${green_color}This window will close automatically in 5 seconds.${reset_color}"
sleep 5
