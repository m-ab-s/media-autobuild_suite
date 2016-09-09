#!/bin/bash
shopt -s extglob

FFMPEG_BASE_OPTS=(--pkg-config-flags=--static)
alloptions="$*"
if [[ x"$LOCALBUILDDIR" = "x" ]]; then
    echo "Something went wrong."
    echo "MSYSTEM: $MSYSTEM"
    echo "pwd: $(cygpath -w "$(pwd)")"
    echo "fstab: "
    cat /etc/fstab
    echo "Create a new issue and upload all logs you can find, especially compile.log"
    read -r -p "Enter to continue" ret
    exit 1
fi
echo -e "\nBuild start: $(date +"%F %T %z")" >> "$LOCALBUILDDIR"/newchangelog

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
--angle=* ) angle="${1#*=}"; shift ;;
--aom=* ) aom="${1#*=}"; shift ;;
--daala=* ) daala="${1#*=}"; shift ;;
--faac=* ) faac="${1#*=}"; shift ;;
    -- ) shift; break ;;
    -* ) echo "Error, unknown option: '$1'."; exit 1 ;;
    * ) break ;;
  esac
done

source "$LOCALBUILDDIR"/media-suite_helper.sh

buildProcess() {
set_title
echo -e "\n\t${orange}Starting $bits compilation of all tools${reset}"
[[ -f "$HOME"/custom_build_options ]] &&
    echo "Imported custom build options (unsupported)" &&
    source "$HOME"/custom_build_options

cd_safe "$LOCALBUILDDIR"

do_getFFmpegConfig "$license"
do_getMpvConfig

if [[ $bits = 64bit && "$(pacman -Qe "$MINGW_PACKAGE_PREFIX-gcc")" = *"6.1.0-1" &&
    -f "$MINGW_PREFIX/lib/gcc/$MINGW_CHOST"/6.1.0/libgcc_s.a ]]; then
    do_unhide_all_sharedlibs
    "${curl_opts[@]}" -O "https://i.fsbn.eu/mingw-w64-x86_64-gcc-6.1.0-1-any.pkg.tar.xz"
    pacman -U --noconfirm "mingw-w64-x86_64-gcc-6.1.0-1-any.pkg.tar.xz"
    add_to_remove "mingw-w64-x86_64-gcc-6.1.0-1-any.pkg.tar.xz"
    do_hide_all_sharedlibs
fi

# in case the root was moved, this fixes windows abspaths
screwed_prefixes=($(grep -E -l "(prefix|libdir|includedir)=[^/$].*" "$LOCALDESTDIR"/lib/pkgconfig/*.pc))
[[ -n "${screwed_prefixes[@]}" ]] && screwed_prefixes=($(grep -qL "$(cygpath -m "$LOCALDESTDIR")" "${screwed_prefixes[@]}"))
[[ -n "${screwed_prefixes[@]}" ]] && sed -ri \
    "s;(prefix|libdir|includedir)=.*${LOCALDESTDIR};\1=$(cygpath -m /trunk)${LOCALDESTDIR};g" \
    "${screwed_prefixes[@]}"

do_uninstall q j{config,error,morecfg,peglib}.h \
    lib{jpeg,nettle,ogg,vorbis{,enc,file},opus{,file,url},vo-aacenc,gnurx,regex}.{,l}a \
    lib{opencore-amr{nb,wb},twolame,theora{,enc,dec},caca,dcadec,waio,magic,EGL,GLESv2}.{l,}a \
    include/{nettle,ogg,vo-aacenc,opencore-amr{nb,wb},theora,cdio,libdcadec,waio} \
    opus/opus{,file}.h regex.h magic.h \
    {nettle,ogg,vorbis{,enc,file},opus{,file,url},vo-aacenc}.pc \
    {opencore-amr{nb,wb},twolame,theora{,enc,dec},caca,dcadec,libEGL}.pc \
    libcdio_{cdda,paranoia}.{{l,}a,pc} \
    share/aclocal/{ogg,vorbis}.m4 \
    twolame.h bin-audio/{twolame,cd-paranoia}.exe bin-global/file.exe \
    {cudaModuleMgr,drvapi_error_string,exception}.h \
    helper_{cuda{,_drvapi},functions,string,timer}.h \
    {nv{CPUOPSys,FileIO,Utils},NvHWEncoder}.h

if [[ -n "$alloptions" ]]; then
    {
        echo '#!/bin/bash'
        echo 'FFMPEG_DEFAULT_OPTS=('
        printf '\t"%s"\n' "${FFMPEG_DEFAULT_OPTS[@]}"
        echo ')'
        echo "bash $LOCALBUILDDIR/media-suite_compile.sh $alloptions"
    } > "$LOCALBUILDDIR/last_run"
    unset alloptions
fi

set_title "compiling global tools"
echo -e "\n\t${orange}Starting $bits compilation of global tools${reset}"

_check=(libopenjp2.{a,pc})
if [[ $ffmpeg != "n" ]] && enabled libopenjpeg &&
    do_vcs "https://github.com/uclouvain/openjpeg.git" libopenjp2; then
    do_pacman_remove openjpeg2

    do_uninstall {include,lib}/openjpeg-2.1 libopen{jpwl,mj2}.{a,pc} "${_check[@]}"
    do_cmakeinstall -DBUILD_CODEC=off
    do_checkIfExist
fi

if [[ "$mplayer" = "y" ]] || ! mpv_disabled libass ||
    { [[ $ffmpeg != "n" ]] && enabled_any libass libfreetype {lib,}fontconfig libfribidi; }; then
    do_pacman_remove freetype fontconfig harfbuzz fribidi

    _check=(libfreetype.{l,}a freetype2.pc)
    if do_pkgConfig "freetype2 = 18.5.12" "2.6.5"; then
        do_wget -h 6a386964e18ba28cb93370e57a19031b \
            "http://download.savannah.gnu.org/releases/freetype/freetype-2.6.5.tar.bz2"
        do_uninstall include/freetype2 bin-global/freetype-config "${_check[@]}"
        do_separate_confmakeinstall global --with-harfbuzz=no
        do_checkIfExist
    fi

    _deps=(libfreetype.a)
    _check=(libfontconfig.{,l}a fontconfig.pc)
    if enabled_any {lib,}fontconfig && do_pkgConfig "fontconfig = 2.12.0"; then
        do_pacman_remove python2-lxml
        do_wget -h f0313daaec6dce8471a2e57ac08c9fda \
            "https://www.freedesktop.org/software/fontconfig/release/fontconfig-2.12.0.tar.bz2"
        do_uninstall include/fontconfig "${_check[@]}"
        [[ $standalone = y ]] || sed -i Makefile.in \
            -e '/^SUBDIRS/,+2{s/fontconfig.*/fontconfig src/;/fc-/d}' \
            -e 's/CROSS_COMPILING_TRUE/CROSS_COMPILING_FALSE/'
        do_separate_confmakeinstall global
        do_checkIfExist
    fi

    [[ ! $harfbuzz_ver ]] &&
        harfbuzz_ver="$(clean_html_index "https://www.freedesktop.org/software/harfbuzz/release/")" &&
        harfbuzz_ver="$(get_last_version "$harfbuzz_ver" "harfbuzz" "1\.\d+\.\d+")"
    harfbuzz_ver="${harfbuzz_ver:-1.3.0}"
    _deps=(lib{freetype,fontconfig}.a)
    _check=(libharfbuzz.{,l}a harfbuzz.pc)
    if do_pkgConfig "harfbuzz = ${harfbuzz_ver}"; then
        do_pacman_install ragel
        do_wget "https://www.freedesktop.org/software/harfbuzz/release/harfbuzz-${harfbuzz_ver}.tar.bz2"
        do_uninstall include/harfbuzz "${_check[@]}"
        do_separate_confmakeinstall --with-{icu,glib,gobject}=no
        do_checkIfExist
    fi

    _check=(libfribidi.{l,}a fribidi.pc)
    [[ $standalone = y ]] && _check+=(bin-global/fribidi.exe)
    if do_pkgConfig "fribidi = 0.19.7"; then
        do_wget -h 6c7e7cfdd39c908f7ac619351c1c5c23 \
            "http://fribidi.org/download/fribidi-0.19.7.tar.bz2"
        do_uninstall include/fribidi "${_check[@]}"
        [[ $standalone = y ]] || sed -i 's|bin doc test||' Makefile.in
        do_separate_confmakeinstall global --disable-{deprecated,debug} --with-glib=no
        do_checkIfExist
    fi
fi

_check=(bin-global/sdl-config libSDL{,main}.{l,}a sdl.pc)
if { [[ $ffmpeg != "n" ]] && ! disabled_any sdl ffplay; } &&
    do_pkgConfig "sdl = 1.2.15"; then
    do_pacman_remove SDL
    do_wget -h 9d96df8417572a2afb781a7c4c811a85 \
        "https://www.libsdl.org/release/SDL-1.2.15.tar.gz"
    do_uninstall include/SDL "${_check[@]}"
    CFLAGS="-DDECLSPEC=" do_separate_confmakeinstall global
    sed -i "s/-mwindows//" "$LOCALDESTDIR/bin-global/sdl-config"
    sed -i "s/-mwindows//" "$LOCALDESTDIR/lib/pkgconfig/sdl.pc"
    do_checkIfExist
fi

if { { [[ $ffmpeg != n ]] && enabled gnutls; } ||
    [[ $rtmpdump = y && $license != nonfree ]]; }; then
    [[ -z "$gnutls_ver" ]] &&
        gnutls_ver="$("${curl_opts[@]}" -l "ftp://ftp.gnutls.org/gcrypt/gnutls/v3.5/")" &&
        gnutls_ver="$(get_last_version "$gnutls_ver" "xz$" '3\.5\.\d+(\.\d+)?')"
    gnutls_ver="${gnutls_ver:-3.5.2}"
    _check=(libgnutls.{,l}a gnutls.pc)
    if do_pkgConfig "gnutls = $gnutls_ver"; then
        do_pacman_install nettle
        do_wget "ftp://ftp.gnutls.org/gcrypt/gnutls/v3.5/gnutls-${gnutls_ver}.tar.xz"
        do_uninstall include/gnutls "${_check[@]}"
        /usr/bin/grep -q "crypt32" lib/gnutls.pc.in ||
            sed -i 's/Libs.private.*/& -lcrypt32/' lib/gnutls.pc.in
        do_separate_confmakeinstall \
            --disable-{cxx,doc,tools,tests,rpath,libdane,guile} \
            --without-{p11-kit,idn,tpm} --enable-local-libopts \
            LDFLAGS="$LDFLAGS -L${LOCALDESTDIR}/lib -L${MINGW_PREFIX}/lib"
        do_checkIfExist
    fi
    grep -q "lib.*\.a" "$(file_installed gnutls.pc)" &&
        sed -ri "s;($LOCALDESTDIR|$MINGW_PREFIX)/lib/lib(\w+).a;-l\2;g" "$(file_installed gnutls.pc)"
fi

if { { [[ $ffmpeg != n ]] && enabled openssl; } ||
    [[ $rtmpdump = y && $license = nonfree ]]; }; then
    [[ ! "$libressl_ver" ]] &&
        libressl_ver="$(clean_html_index "http://ftp.openbsd.org/pub/OpenBSD/LibreSSL/")" &&
        libressl_ver="$(get_last_version "$libressl_ver" "" '2\.\d+\.\d+')"
    libressl_ver="${libressl_ver:-2.4.1}"
    _check=(tls.h lib{crypto,ssl,tls}.{pc,{,l}a} openssl.pc)
    [[ $standalone = y ]] && _check+=("bin-global/openssl.exe")
    if do_pkgConfig "libssl = $libressl_ver"; then
        do_wget "http://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-${libressl_ver}.tar.gz"
        do_uninstall etc/ssl include/openssl "${_check[@]}"
        _sed="man"
        [[ $standalone = y ]] || _sed="apps tests $_sed"
        sed -ri "s;(^SUBDIRS .*) $_sed;\1;" Makefile.in
        sed -i 's;DESTDIR)/\$;DESTDIR)$;g' apps/openssl/Makefile.in
        do_separate_confmakeinstall global
        do_checkIfExist
        unset _sed
    fi
fi

[[ ! "$curl_ver" ]] &&
    curl_ver="$(clean_html_index https://curl.haxx.se/download/)" &&
    curl_ver="$(get_last_version "$curl_ver" bz2 "7\.\d+\.\d")"
curl_ver="${curl_ver:-7.50.1}"
_check=(curl/curl.h libcurl.{{,l}a,pc})
[[ $standalone = y ]] && _check+=(bin-global/curl.exe)
if [[ $mediainfo = y || $bmx = y ]] && do_pkgConfig "libcurl = $curl_ver"; then
    do_pacman_install nghttp2
    do_wget "https://curl.haxx.se/download/curl-${curl_ver}.tar.bz2"
    do_uninstall include/curl bin-global/{curl-config,curl-ca-bundle.crt} "${_check[@]}"
    [[ $standalone = y ]] || sed -ri "s;(^SUBDIRS = lib) src (include) scripts;\1 \2;" Makefile.in
    extra_opts=()
    if enabled openssl; then
        extra_opts+=(--with-{ssl,nghttp2} --without-gnutls)
    elif enabled gnutls; then
        extra_opts+=(--with-gnutls --without-{ssl,nghttp2})
    else
        extra_opts+=(--with-{winssl,winidn,nghttp2} --without-{ssl,gnutls,libidn})
    fi
    /usr/bin/grep -q "NGHTTP2_STATICLIB" libcurl.pc.in ||
        { sed -i 's;Cflags.*;& -DNGHTTP2_STATICLIB;' libcurl.pc.in &&
          sed -i 's;-DCURL_STATICLIB ;&-DNGHTTP2_STATICLIB ;' curl-config.in; }
    hide_conflicting_libs
    CPPFLAGS+=" -DNGHTTP2_STATICLIB" CFLAGS="${CFLAGS#-I${LOCALDESTDIR}/include }" \
        do_separate_confmakeinstall global "${extra_opts[@]}" \
        --without-{libssh2,random,ca-bundle,ca-path} --enable-sspi --disable-{debug,manual}
    hide_conflicting_libs -R
    log ca-bundle make ca-bundle
    enabled_any openssl gnutls && [[ -f lib/ca-bundle.crt ]] &&
        cp -f lib/ca-bundle.crt "$LOCALDESTDIR"/bin-global/curl-ca-bundle.crt
    do_checkIfExist
fi

_check=(libwebp{,mux}.{{,l}a,pc})
[[ $standalone = y ]] && _check+=(libwebp{demux,decoder}.{{,l}a,pc}
    bin-global/{{c,d}webp,webpmux}.exe)
if [[ $ffmpeg != n || $standalone = y ]] && enabled libwebp &&
    do_vcs "https://chromium.googlesource.com/webm/libwebp"; then
    do_pacman_install libtiff
    do_autoreconf
    if [[ $standalone = y ]]; then
        extracommands=(--enable-libwebp{demux,decoder,extras}
            LIBS="$($PKG_CONFIG --libs libpng libtiff-4)" --enable-experimental)
    else
        extracommands=()
        sed -i 's/ examples man//' Makefile.in
    fi
    do_uninstall include/webp bin-global/gif2webp.exe "${_check[@]}"
    do_separate_confmakeinstall global --enable-{swap-16bit-csp,libwebpmux} \
        "${extracommands[@]}"
    do_checkIfExist
fi

syspath=$(cygpath -S)
[[ $bits = "32bit" && -d "$syspath/../SysWOW64" ]] && syspath="$syspath/../SysWOW64"
if [[ $ffmpeg != n ]] && enabled opencl && [[ -f "$syspath/OpenCL.dll" ]]; then
    echo -e "${orange}FFmpeg and related apps will depend on OpenCL.dll${reset}"
    _check=(libOpenCL.a)
    if ! files_exist "${_check[@]}"; then
        cd_safe "$LOCALBUILDDIR"
        [[ -d opencl ]] && rm -rf opencl
        mkdir -p opencl && cd_safe opencl
        do_pacman_install opencl-headers
        create_build_dir
        gendef "$syspath/OpenCL.dll" >/dev/null 2>&1
        [[ -f OpenCL.def ]] && dlltool -l libOpenCL.a -d OpenCL.def -k -A
        [[ -f libOpenCL.a ]] && do_install libOpenCL.a
        do_checkIfExist
    fi
else
    do_removeOption --enable-opencl
fi
unset syspath

if [[ $ffmpeg != n || $standalone = y ]] && enabled libtesseract; then
    do_pacman_remove tesseract-ocr
    do_pacman_install libtiff
    _check=(liblept.{,l}a lept.pc)
    if do_pkgConfig "lept = 1.73"; then
        do_wget -h 092cea2e568cada79fff178820397922 \
            "http://www.leptonica.com/source/leptonica-1.73.tar.gz"
        do_uninstall include/leptonica "${_check[@]}"
        do_separate_confmakeinstall --disable-programs --without-lib{openjpeg,webp}
        do_checkIfExist
    fi

    _check=(libtesseract.{,l}a tesseract.pc)
    if do_vcs "https://github.com/tesseract-ocr/tesseract.git"; then
        do_autogen
        _check+=(bin-global/tesseract.exe)
        do_uninstall include/tesseract "${_check[@]}"
        sed -i "s|Libs.private.*|& -lstdc++|" tesseract.pc.in
        do_separate_confmakeinstall global --disable-{graphics,tessdata-prefix} \
            LIBLEPT_HEADERSDIR="$LOCALDESTDIR/include" \
            LIBS="$($PKG_CONFIG --libs lept libtiff-4)" --datadir="$LOCALDESTDIR/bin-global"
        if [[ ! -f $LOCALDESTDIR/bin-global/tessdata/eng.traineddata ]]; then
            do_pacman_install tesseract-data-eng
            mkdir -p "$LOCALDESTDIR"/bin-global/tessdata
            do_install "$MINGW_PREFIX/share/tessdata/eng.traineddata" bin-global/tessdata/
            printf "%s\n" "You can get more language data here:"\
                   "https://github.com/tesseract-ocr/tessdata/blob/master/"\
                   "Just download <lang you want>.traineddata and copy it to this directory."\
                    > "$LOCALDESTDIR"/bin-global/tessdata/need_more_languages.txt
        fi
        do_checkIfExist
    fi
fi

_check=(librubberband.a rubberband.pc rubberband/{rubberband-c,RubberBandStretcher}.h)
if { { [[ $ffmpeg != "n" ]] && enabled librubberband; } ||
    ! mpv_disabled rubberband; } && { do_pkgConfig "rubberband = 1.8.1" ||
    { test_newer installed "$(find "$MINGW_PREFIX/lib/" -name libstdc++.a)" rubberband.pc &&
    do_uninstall rubberband.pc; }; } &&
    do_vcs https://github.com/lachs0r/rubberband.git; then
    do_uninstall "${_check[@]}"
    log "distclean" make distclean
    do_make PREFIX="$LOCALDESTDIR" install-static
    do_checkIfExist
    add_to_remove
fi

if { [[ $ffmpeg != "n" ]] && enabled libzimg; } ||
    { ! pc_exists zimg && ! mpv_disabled vapoursynth; } then
    _check=(zimg{.h,++.hpp} libzimg.{,l}a zimg.pc)
    if do_vcs "https://github.com/sekrit-twc/zimg.git"; then
        do_uninstall "${_check[@]}"
        do_autoreconf
        do_separate_confmakeinstall
        do_checkIfExist
    fi
fi

if [[ $ffmpeg != n ]] && enabled chromaprint; then
    do_pacman_install fftw
    _check=(libchromaprint.{a,pc} chromaprint.h)
    if do_vcs "https://bitbucket.org/acoustid/chromaprint.git" libchromaprint; then
        do_uninstall "${_check[@]}"
        do_cmakeinstall -DWITH_FFTW3=on
        do_checkIfExist
    fi
    do_addOption --extra-libs=-lfftw3 --extra-libs=-lstdc++ --extra-cflags=-DCHROMAPRINT_NODLL
fi

set_title "compiling audio tools"
echo -e "\n\t${orange}Starting $bits compilation of audio tools${reset}"

if [[ $ffmpeg != "n" || $sox = y ]]; then
    enabled libwavpack && do_pacman_install wavpack
    enabled_any libopencore-amr{wb,nb} && do_pacman_install opencore-amr
    if enabled libtwolame; then
        do_pacman_install twolame
        do_addOption --extra-cflags=-DLIBTWOLAME_STATIC
    fi
    enabled libmp3lame && do_pacman_install lame
fi

_check=(ilbc.h libilbc.{{l,}a,pc})
if [[ $ffmpeg != "n" ]] && enabled libilbc && do_pkgConfig "libilbc = 2.0.3-dev" &&
    do_vcs "https://github.com/TimothyGu/libilbc.git"; then
    do_autoreconf
    do_uninstall "${_check[@]}"
    do_separate_confmakeinstall
    do_checkIfExist
    add_to_remove
fi

enabled libvorbis && do_pacman_install libvorbis
enabled libopus && do_pacman_install opus
enabled libspeex && do_pacman_install speex

_check=(bin-audio/speex{enc,dec}.exe)
if [[ $standalone = y ]] && enabled libspeex && ! { files_exist "${_check[@]}" &&
    grep -q '1.2rc2' "$LOCALDESTDIR/bin-audio/speexenc.exe"; } &&
    do_vcs "https://git.xiph.org/speex.git"; then
    do_uninstall include/speex libspeex.{l,}a speex.pc "${_check[@]}"
    do_autoreconf
    do_separate_conf --enable-vorbis-psy --enable-binaries
    do_make
    do_install src/speex{enc,dec}.exe bin-audio/
    do_checkIfExist
    add_to_remove
fi

_check=(libFLAC{,++}.{,l}a flac{,++}.pc)
[[ $standalone = y ]] && _check+=(bin-audio/flac.exe)
if [[ $flac = y ]] && do_vcs "https://git.xiph.org/flac.git"; then
    # release = #tag=1.3.1
    do_pacman_install libogg
    do_autogen
    if [[ $standalone = y ]]; then
        _check+=(bin-audio/metaflac.exe)
    else
        sed -i "/^SUBDIRS/,/[^\\]$/{/flac/d;}" src/Makefile.in
    fi
    do_uninstall include/FLAC{,++} share/aclocal/libFLAC{,++}.m4 "${_check[@]}"
    do_separate_confmakeinstall audio --disable-{xmms-plugin,doxygen-docs}
    do_checkIfExist
elif [[ $sox = y ]] || { [[ $standalone = y ]] && enabled_any libvorbis libopus; }; then
    do_pacman_install flac
fi

_check=(libvo-amrwbenc.{l,}a vo-amrwbenc.pc)
if [[ $ffmpeg != n ]] && enabled libvo-amrwbenc &&
    do_pkgConfig "vo-amrwbenc = 0.1.2"; then
    do_wget_sf -h 588205f686adc23532e31fe3646ddcb6 \
        "opencore-amr/vo-amrwbenc/vo-amrwbenc-0.1.2.tar.gz"
    do_uninstall include/vo-amrwbenc "${_check[@]}"
    do_separate_confmakeinstall
    do_checkIfExist
fi

if { [[ $ffmpeg != n ]] && enabled libfdk-aac; } || [[ $fdkaac = "y" ]]; then
    _check=(libfdk-aac.{l,}a fdk-aac.pc)
    if do_vcs "https://github.com/mstorsjo/fdk-aac"; then
        do_autoreconf
        do_uninstall include/fdk-aac "${_check[@]}"
        CXXFLAGS+=" -O2 -fno-exceptions -fno-rtti" do_separate_confmakeinstall
        do_checkIfExist
    fi
    _check=(bin-audio/fdkaac.exe)
    _deps=(libfdk-aac.a)
    if [[ $standalone = y ]] &&
        do_vcs "https://github.com/nu774/fdkaac" bin-fdk-aac; then
        do_autoreconf
        do_uninstall "${_check[@]}"
        CXXFLAGS+=" -O2" do_separate_confmakeinstall audio
        do_checkIfExist
    else
        ! disabled libfdk-aac && do_addOption --enable-libfdk-aac
    fi
fi

[[ $faac = y ]] && do_pacman_install faac
_check=(bin-audio/faac.exe)
if [[ $standalone = y && $faac = y ]] && ! files_exist "${_check[@]}"; then
    do_wget_sf -h c5dde68840cefe46532089c9392d1df0 \
        "faac/faac-src/faac-1.28/faac-1.28.tar.bz2"
    ./bootstrap 2>/dev/null
    do_uninstall libfaac.a faac{,cfg}.h "${_check[@]}"
    [[ $standalone = y ]] || sed -i 's|frontend||' Makefile.am
    do_separate_conf --without-mp4v2
    do_make
    do_install frontend/faac.exe bin-audio/
    do_checkIfExist
fi

_check=(bin-audio/oggenc.exe)
_deps=("$MINGW_PREFIX"/lib/libvorbis.a)
if [[ $standalone = y ]] && enabled libvorbis && ! files_exist "${_check[@]}" &&
    do_vcs "https://git.xiph.org/vorbis-tools.git" vorbis-tools; then
    _check+=(bin-audio/oggdec.exe)
    do_autoreconf
    do_uninstall "${_check[@]}"
    extracommands=()
    enabled libspeex || extracommands+=(--without-speex)
    do_separate_conf --disable-{ogg123,vorbiscomment,vcut,ogginfo} \
        --with-lib{iconv,intl}-prefix="$MINGW_PREFIX" "${extracommands[@]}"
    do_make
    do_install oggenc/oggenc.exe oggdec/oggdec.exe bin-audio/
    do_checkIfExist
    add_to_remove
fi

_check=(bin-audio/opusenc.exe)
if [[ $standalone = y ]] && enabled libopus &&
    test_newer installed "$MINGW_PREFIX"/lib/pkgconfig/opus.pc "${_check[0]}"; then
    _check+=(bin-audio/opus{dec,info}.exe)
    do_wget -h 20682e4d8d1ae9ec5af3cf43e808b8cb \
        "http://downloads.xiph.org/releases/opus/opus-tools-0.1.9.tar.gz"
    do_uninstall "${_check[@]}"
    do_separate_confmakeinstall audio
    do_checkIfExist
fi

_check=(soxr.h libsoxr.a)
if [[ $ffmpeg != "n" ]] && enabled libsoxr; then
    if files_exist "${_check[@]}" && [[ "$(get_api_version soxr.h VERSION_STR)" = "0.1.2" ]]; then
        do_print_status "libsoxr 0.1.2" "$green" "Up-to-date"
    else
        do_wget_sf -h 0866fc4320e26f47152798ac000de1c0 "soxr/soxr-0.1.2-Source.tar.xz"
        do_uninstall "${_check[@]}"
        do_cmakeinstall -DWITH_LSR_BINDINGS=off -DBUILD_TESTS=off
        do_checkIfExist
    fi
    do_addOption --extra-cflags=-fopenmp --extra-libs=-lgomp
fi

if [[ $standalone = y ]] && enabled libmp3lame; then
    _check=(bin-audio/lame.exe)
    if files_exist "${_check[@]}" &&
        grep -q "3.99.5" "$LOCALDESTDIR/bin-audio/lame.exe"; then
        do_print_status "lame 3.99.5" "$green" "Up-to-date"
    else
        do_wget_sf -h 84835b313d4a8b68f5349816d33e07ce "lame/lame/3.99/lame-3.99.5.tar.gz"
        do_uninstall include/lame libmp3lame.{l,}a "${_check[@]}"
        sed -i '/xmmintrin\.h/d' configure
        do_separate_conf --disable-decoder "${extracommands[@]}"
        do_make
        do_install frontend/lame.exe bin-audio/
        do_checkIfExist
    fi
fi

_check=(libgme.{a,pc})
if [[ $ffmpeg != "n" ]] && enabled libgme && do_pkgConfig "libgme = 0.6.1" &&
    do_vcs "https://bitbucket.org/mpyne/game-music-emu.git" libgme; then
    do_uninstall include/gme "${_check[@]}"
    do_cmakeinstall
    do_checkIfExist
    add_to_remove
fi

_check=(libbs2b.{{l,}a,pc})
if [[ $ffmpeg != "n" ]] && enabled libbs2b && do_pkgConfig "libbs2b = 3.1.0"; then
    do_wget_sf -h c1486531d9e23cf34a1892ec8d8bfc06 "bs2b/libbs2b/3.1.0/libbs2b-3.1.0.tar.bz2"
    do_uninstall include/bs2b "${_check[@]}"
    # sndfile check is disabled since we don't compile binaries anyway
    /usr/bin/grep -q sndfile configure && sed -i '20119,20133d' configure
    sed -i "s|bin_PROGRAMS = .*||" src/Makefile.in
    do_separate_confmakeinstall
    do_checkIfExist
fi

_check=(libsndfile.{l,}a sndfile.{h,pc})
if [[ $sox = y ]] && do_vcs "https://github.com/erikd/libsndfile.git" sndfile; then
    sed -i 's/ examples regtest tests programs//g' Makefile.am
    do_autogen
    do_uninstall include/sndfile.hh "${_check[@]}"
    do_separate_confmakeinstall
    do_checkIfExist
fi

_check=(bin-audio/sox.exe sox.pc)
_deps=(lib{sndfile,mp3lame}.a "$MINGW_PREFIX"/lib/libopus.a)
if [[ $sox = y ]] && do_pkgConfig "sox = 14.4.2"; then
    do_wget_sf -h ba804bb1ce5c71dd484a102a5b27d0dd "sox/sox/14.4.2/sox-14.4.2.tar.bz2"
    do_pacman_install libmad
    do_uninstall sox.{pc,h} bin-audio/{soxi,play,rec}.exe libsox.{l,}a "${_check[@]}"
    extracommands=()
    enabled libmp3lame || extracommands+=(--without-lame)
    enabled_any libopencore-amr{wb,nb} || extracommands+=(--without-amr{wb,nb})
    if enabled libopus; then
        do_pacman_install opusfile
    else
        extracommands+=(--without-opus)
    fi
    enabled libtwolame || extracommands+=(--without-twolame)
    enabled libvorbis || extracommands+=(--without-oggvorbis)
    enabled libwavpack || extracommands+=(--without-wavpack)
    hide_conflicting_libs
    sed -i 's|found_libgsm=yes|found_libgsm=no|g' configure
    do_separate_conf --disable-symlinks LIBS='-lshlwapi -lz' "${extracommands[@]}"
    do_make
    do_install src/sox.exe bin-audio/
    do_install sox.pc
    hide_conflicting_libs -R
    do_checkIfExist
fi

_check=(libebur128.a ebur128.h)
if [[ $ffmpeg != n ]] && enabled libebur128 && ! files_exist "${_check[@]}" &&
    do_vcs "https://github.com/jiixyj/libebur128.git"; then
    do_uninstall "${_check[@]}"
    do_cmakeinstall -DENABLE_INTERNAL_QUEUE_H=on
    do_uninstall q "$LOCALDESTDIR"/lib/libebur128.dll{,.a}
    do_checkIfExist
    add_to_remove
fi

_check=(libopenmpt.{a,pc})
if [[ $ffmpeg != n ]] && enabled libopenmpt && do_pkgConfig "libopenmpt = 0.2.6611"; then
    do_wget -h d906c4b9e8083fcd3ba420496f393fc4 \
        "https://lib.openmpt.org/files/libopenmpt/src/libopenmpt-0.2.6611-beta18.tar.gz" \
        "libopenmpt-0.2.6611.tar.gz"
    do_uninstall include/libopenmpt "${_check[@]}"
    extracommands=(CONFIG="mingw64-win${bits%bit}" AR=ar STATIC_LIB=1 EXAMPLES=0 OPENMPT123=0
        TEST=0 OS=)
    log clean make clean "${extracommands[@]}"
    do_makeinstall PREFIX="$LOCALDESTDIR" "${extracommands[@]}"
    sed -i 's/Libs.private.*/& -lstdc++/' "$LOCALDESTDIR/lib/pkgconfig/libopenmpt.pc"
    do_checkIfExist
fi

set_title "compiling video tools"
echo -e "\n\t${orange}Starting $bits compilation of video tools${reset}"

if [[ $rtmpdump = "y" ]] ||
    { [[ $ffmpeg != "n" ]] && enabled librtmp; }; then
    req=""
    pc_exists librtmp && req="$(pkg-config --print-requires "$(file_installed librtmp.pc)")"
    if enabled gnutls || [[ $rtmpdump = "y" && $license != "nonfree" ]]; then
        ssl=GnuTLS
        crypto=GNUTLS
        pc=gnutls
    else
        ssl=LibreSSL
        crypto=OPENSSL
        pc=libssl
    fi
    _check=(librtmp.{a,pc})
    _deps=("${pc}.pc")
    [[ $rtmpdump = "y" ]] && _check+=(bin-video/rtmpdump.exe)
    if do_vcs "http://repo.or.cz/rtmpdump.git" librtmp || [[ $req != *$pc* ]]; then
        [[ $rtmpdump = y ]] && _check+=(bin-video/rtmp{suck,srv,gw}.exe)
        do_uninstall include/librtmp "${_check[@]}"
        [[ -f "librtmp/librtmp.a" ]] && log "clean" make clean
        _ver="$(printf '%s-%s-%s_%s-%s-static' "$(/usr/bin/grep -oP "(?<=^VERSION=).+" Makefile)" \
                "$(git log -1 --format=format:%cd-g%h --date=format:%Y%m%d)" "$ssl" \
                "$(pkg-config --modversion "$pc")" "$CARCH")"
        do_makeinstall XCFLAGS="$CFLAGS -I$MINGW_PREFIX/include" XLDFLAGS="$LDFLAGS" SHARED= \
            SYS=mingw prefix="$LOCALDESTDIR" bindir="$LOCALDESTDIR"/bin-video \
            sbindir="$LOCALDESTDIR"/bin-video mandir="$LOCALDESTDIR"/share/man \
            CRYPTO="$crypto" LIB_${crypto}="$($PKG_CONFIG --libs $pc) -lz" VERSION="$_ver"
        do_checkIfExist
        unset ssl crypto pc req
    fi
fi

_check=(libvpx.a vpx.pc)
[[ $standalone = y ]] && _check+=(bin-video/vpxenc.exe)
if [[ $vpx = y ]] && do_vcs "https://chromium.googlesource.com/webm/libvpx" vpx; then
    extracommands=()
    [[ -f config.mk ]] && log "distclean" make distclean
    [[ $standalone = y ]] && _check+=(bin-video/vpxdec.exe) ||
        extracommands+=(--disable-examples)
    do_uninstall include/vpx "${_check[@]}"
    create_build_dir
    log "configure" ../configure --target="${arch}-win${bits%bit}-gcc" --prefix="$LOCALDESTDIR" \
        --disable-{shared,unit-tests,docs,install-bins} \
        --enable-{vp9-postproc,vp9-highbitdepth} \
        "${extracommands[@]}"
    for _ff in *.mk; do
        sed -i 's;HAVE_GNU_STRIP=yes;HAVE_GNU_STRIP=no;' "$_ff"
    done
    do_make
    do_makeinstall
    [[ $standalone = y ]] && do_install vpx{enc,dec}.exe bin-video/
    do_checkIfExist
    unset extracommands _ff
else
    pc_exists vpx || do_removeOption --enable-libvpx
fi

_check=(libaom.a aom.pc)
[[ $standalone = y ]] && _check+=(bin-video/aomenc.exe)
if [[ $aom = y ]] && do_vcs https://aomedia.googlesource.com/aom; then
    extracommands=()
    [[ $standalone = y ]] && _check+=(bin-video/aomdec.exe) ||
        extracommands+=(--disable-examples)
    do_uninstall include/aom "${_check[@]}"
    create_build_dir
    log "configure" ../configure --target="${arch}-win${bits%bit}-gcc" --prefix="$LOCALDESTDIR" \
        --disable-{shared,unit-tests,docs,install-bins} \
        --enable-{static,runtime-cpu-detect,aom-highbitdepth} \
        "${extracommands[@]}"
    for _ff in *.mk; do
        sed -i 's;HAVE_GNU_STRIP=yes;HAVE_GNU_STRIP=no;' "$_ff"
    done
    do_make
    do_makeinstall
    [[ $standalone = y ]] && do_install aom{enc,dec}.exe bin-video/
    do_checkIfExist
    unset extracommands _ff
fi

_check=(libkvazaar.{,l}a kvazaar.pc kvazaar.h)
[[ $standalone = y ]] && _check+=(bin-video/kvazaar.exe)
if { [[ $other265 = "y" ]] || { [[ $ffmpeg != "n" ]] && enabled libkvazaar; }; } &&
    do_vcs "https://github.com/ultravideo/kvazaar.git"; then
    do_uninstall kvazaar_version.h "${_check[@]}"
    do_autogen
    [[ $standalone = y || $other265 = y ]] ||
        sed -i "s|bin_PROGRAMS = .*||" src/Makefile.in
    do_separate_confmakeinstall video
    do_checkIfExist
fi

_check=(libdaala{base,dec,enc}.{,l}a daala{dec,enc}.pc)
[[ $standalone = y ]] && _check+=(bin-video/{{encoder,player}_example,dump_video}.exe)
if [[ $daala = y ]] && do_vcs "https://git.xiph.org/daala.git"; then
    do_pacman_install libogg
    extracommands=()
    do_uninstall include/daala "${_check[@]}"
    do_autogen
    if [[ $standalone = y ]]; then
        do_pacman_install SDL2 libjpeg-turbo
    else
        extracommands+=(--disable-player --disable-tools)
    fi
    do_separate_conf video --disable-{unit-tests,doc} "${extracommands[@]}"
    do_make && do_makeinstall
    [[ $standalone = y ]] && do_install examples/{{encoder,player}_example,dump_video}.exe bin-video/
    do_checkIfExist
fi

if [[ $mplayer = "y" ]] || ! mpv_disabled_all dvdread dvdnav; then
    _check=(libdvdread.{l,}a dvdread.pc)
    if do_vcs "https://code.videolan.org/videolan/libdvdread.git" dvdread; then
        do_autoreconf
        do_uninstall include/dvdread "${_check[@]}"
        do_separate_confmakeinstall
        do_checkIfExist
    fi
    grep -q 'ldl' "$LOCALDESTDIR"/lib/pkgconfig/dvdread.pc ||
        sed -i "/Libs:.*/ a\Libs.private: -ldl" "$LOCALDESTDIR"/lib/pkgconfig/dvdread.pc

    _check=(libdvdnav.{l,}a dvdnav.pc)
    if do_vcs "https://code.videolan.org/videolan/libdvdnav.git" dvdnav; then
        do_autoreconf
        do_uninstall include/dvdnav "${_check[@]}"
        do_separate_confmakeinstall
        do_checkIfExist
    fi
fi

_check=(libbluray.{{l,}a,pc})
if { { [[ $ffmpeg != "n" ]] && enabled libbluray; } || ! mpv_disabled libbluray; } &&
    do_vcs "https://git.videolan.org/git/libbluray.git"; then
    [[ -f contrib/libudfread/.git ]] || log git.submodule git submodule update --init
    do_autoreconf
    do_uninstall include/libbluray "${_check[@]}"
    do_separate_confmakeinstall --disable-{examples,bdjava,doxygen-doc} \
        --without-{libxml2,fontconfig,freetype}
    do_checkIfExist
fi

_check=(ass/ass{,_types}.h libass.{{,l}a,pc})
_deps=(lib{freetype,fontconfig,harfbuzz,fribidi}.a)
if { [[ $mplayer = "y" ]] || ! mpv_disabled libass ||
    { [[ $ffmpeg != "n" ]] && enabled libass; }; } &&
    do_vcs "https://github.com/libass/libass.git"; then
    do_autoreconf
    do_uninstall "${_check[@]}"
    extracommands=()
    enabled_any {lib,}fontconfig || extracommands+=(--disable-fontconfig)
    do_separate_confmakeinstall "${extracommands[@]}"
    do_checkIfExist
fi

_check=(libxavs.a xavs.{h,pc})
if [[ $ffmpeg != "n" ]] && enabled libxavs && do_pkgConfig "xavs = 0.1." "0.1" &&
    do_vcs "https://github.com/Distrotech/xavs.git"; then
    [[ -f "libxavs.a" ]] && log "distclean" make distclean
    do_uninstall "${_check[@]}"
    sed -i 's|"NUL"|"/dev/null"|g' configure
    do_configure --host="$MINGW_CHOST" --prefix="$LOCALDESTDIR"
    do_make libxavs.a
    for _file in xavs.h libxavs.a xavs.pc; do do_install "$_file"; done
    do_checkIfExist
    add_to_remove
    unset _file
fi

if [[ $mediainfo = "y" ]]; then
    _check=(libzen.{a,pc})
    if do_vcs "https://github.com/MediaArea/ZenLib" libzen; then
        do_uninstall include/ZenLib bin-global/libzen-config "${_check[@]}" libzen.la
        sed -i -e 's|NOT SIZE_T_IS_NOT_LONG|false|' -e 's|NOT WIN32|UNIX|' Project/CMake/CMakeLists.txt
        do_cmakeinstall Project/CMake
        do_checkIfExist
    fi

    _check=(libmediainfo.{a,pc})
    _deps=(lib{zen,curl}.a)
    if do_vcs "https://github.com/MediaArea/MediaInfoLib" libmediainfo; then
        do_uninstall include/MediaInfo{,DLL} bin-global/libmediainfo-config "${_check[@]}" libmediainfo.la
        sed -i 's|NOT WIN32|UNIX|g' Project/CMake/CMakeLists.txt
        do_cmakeinstall Project/CMake
        sed -i 's|libzen|libcurl libzen|' "$LOCALDESTDIR/lib/pkgconfig/libmediainfo.pc"
        do_checkIfExist
    fi

    _check=(bin-video/mediainfo.exe)
    _deps=(libmediainfo.a)
    if do_vcs "https://github.com/MediaArea/MediaInfo" mediainfo; then
        cd_safe Project/GNU/CLI
        do_autogen
        do_uninstall "${_check[@]}"
        [[ -f Makefile ]] && log distclean make distclean
        do_configure --build="$MINGW_CHOST" --disable-shared --bindir="$LOCALDESTDIR/bin-video" \
            --enable-staticlibs LIBS="$($PKG_CONFIG --libs libmediainfo)"
        do_makeinstall
        do_checkIfExist
    fi
fi

_check=(libvidstab.a vidstab.pc)
if [[ $ffmpeg != "n" ]] && enabled libvidstab && do_pkgConfig "vidstab = 1.10" &&
    do_vcs "https://github.com/georgmartius/vid.stab.git" vidstab; then
    do_uninstall include/vid.stab "${_check[@]}"
    do_cmakeinstall
    do_checkIfExist
    add_to_remove
fi

_check=(libzvbi.{h,{l,}a})
if [[ $ffmpeg != "n" ]] && enabled libzvbi &&
    { ! files_exist "${_check[@]}" || ! grep -q "0.2.35" "$LOCALDESTDIR/lib/libzvbi.a"; }; then
    do_wget_sf -h 95e53eb208c65ba6667fd4341455fa27 \
        "zapping/zvbi/0.2.35/zvbi-0.2.35.tar.bz2"
    do_uninstall "${_check[@]}" zvbi-0.2.pc
    do_patch "zvbi-win32.patch"
    do_patch "zvbi-ioctl.patch"
    CFLAGS+=" -DPTW32_STATIC_LIB" do_separate_conf --disable-{dvb,bktr,nls,proxy} \
        --without-doxygen LIBS="$LIBS -lpng"
    cd_safe src
    do_makeinstall
    do_checkIfExist
fi

_check=(frei0r.{h,pc})
if [[ $ffmpeg != "n" ]] && enabled frei0r && do_pkgConfig "frei0r = 1.5.0" &&
    do_vcs https://github.com/dyne/frei0r.git; then
    sed -i 's/find_package (Cairo)//' "CMakeLists.txt"
    do_uninstall lib/frei0r-1 "${_check[@]}"
    do_cmakeinstall
    do_checkIfExist
    add_to_remove
fi

if [[ $ffmpeg != "n" ]] && enabled decklink; then
    _check=(DeckLinkAPI.h
           DeckLinkAPIVersion.h
           DeckLinkAPI_i.c)
    _hash=(7b6e82653ef93890dc3f4904dbe8a200
           9e06e3a3c1cef8be7f4b18985045dd8e
           966cc3e59970f6052bfb5a6fba31fb3d)
    if files_exist -v "${_check[@]}" &&
        {
            count=0
            while [[ x"${_check[$count]}" != x"" ]]; do
                check_hash "$(file_installed "${_check[$count]}")" "${_hash[$count]}" || break
                let count+=1
            done
            test x"${_check[$count]}" = x""
        }; then
        do_print_status "DeckLinkAPI 10.7" "$green" "Up-to-date"
    else
        mkdir -p "$LOCALBUILDDIR/DeckLinkAPI" &&
            cd_safe "$LOCALBUILDDIR/DeckLinkAPI"
        count=0
        while [[ x"${_check[$count]}" != x"" ]]; do
            do_wget -r -c -h "${_hash[$count]}" "/extras/${_check[$count]}"
            do_install "${_check[$count]}"
            let count+=1
        done
        do_checkIfExist
    fi
    unset count
fi

_check=(libmfx.{{l,}a,pc})
if [[ $ffmpeg != "n" ]] && enabled libmfx &&
    do_vcs "https://github.com/lu-zero/mfx_dispatch.git" libmfx; then
    do_autoreconf
    do_uninstall include/mfx "${_check[@]}"
    do_separate_confmakeinstall
    do_checkIfExist
fi

_check=(libgpac_static.a bin-video/MP4Box.exe)
if [[ $mp4box = "y" ]] && do_vcs "https://github.com/gpac/gpac.git"; then
    do_uninstall include/gpac "${_check[@]}"
    git grep -PIl "\xC2\xA0" | xargs -r sed -i 's/\xC2\xA0/ /g'
    LDFLAGS+=" -L$LOCALDESTDIR/lib -L$MINGW_PREFIX/lib" \
        do_separate_conf --static-mp4box
    do_make
    log "install" make install-lib
    do_install bin/gcc/MP4Box.exe bin-video/
    do_checkIfExist
fi

if [[ $x264 != n ]]; then
    _check=(x264{,_config}.h libx264.a x264.pc)
    [[ $standalone = y ]] && _check+=(bin-video/x264.exe)
    if do_vcs "https://git.videolan.org/git/x264.git" ||
        [[ $x264 != h && "$(get_api_version x264_config.h BIT_DEPTH)" = "10" ]] ||
        [[ $x264  = h && "$(get_api_version x264_config.h BIT_DEPTH)" = "8" ]]; then
        extracommands=(--host="$MINGW_CHOST" --prefix="$LOCALDESTDIR" --enable-static)
        if [[ $standalone = y && $x264 = f ]]; then
            _check=(libav{codec,format}.{a,pc})
            do_vcs "https://git.ffmpeg.org/ffmpeg.git"
            do_uninstall "${_check[@]}" include/libav{codec,device,filter,format,util,resample} \
                include/lib{sw{scale,resample},postproc} \
                libav{codec,device,filter,format,util,resample}.{a,pc} \
                lib{sw{scale,resample},postproc}.{a,pc}
            [[ -f "config.mak" ]] && log "distclean" make distclean
            create_build_dir light
            LDFLAGS+=" -L$LOCALDESTDIR/lib -L$MINGW_PREFIX/lib" \
                log configure ../configure "${FFMPEG_BASE_OPTS[@]}" --prefix="$LOCALDESTDIR" \
                --disable-{programs,devices,filters,encoders,muxers} --enable-gpl
            do_makeinstall
            files_exist "${_check[@]}" && touch "build_successful${bits}_light"

            _check=(ffms{,compat}.h libffms2.{,l}a ffms2.pc bin-video/ffmsindex.exe)
            if do_vcs https://github.com/FFMS/ffms2.git; then
                do_uninstall "${_check[@]}"
                sed -i 's/Libs.private.*/& -lstdc++/;s/Cflags.*/& -DFFMS_STATIC/' ffms2.pc.in
                do_separate_confmakeinstall video
                do_checkIfExist
            fi
            cd_safe "$LOCALBUILDDIR"/x264-git
        fi

        if [[ $standalone = y ]]; then
            _check=(lsmash.h liblsmash.{a,pc})
            if do_vcs "https://github.com/l-smash/l-smash.git" liblsmash; then
                [[ -f "config.mak" ]] && log "distclean" make distclean
                do_uninstall "${_check[@]}"
                create_build_dir
                log configure ../configure --prefix="$LOCALDESTDIR"
                do_make install-lib
                do_checkIfExist
            fi
            cd_safe "$LOCALBUILDDIR"/x264-git
        fi

        _check=(x264{,_config}.h libx264.a x264.pc)
        [[ -f "config.h" ]] && log "distclean" make distclean
        if [[ $standalone = y ]]; then
            extracommands+=(--bindir="$LOCALDESTDIR/bin-video")
            _check+=(bin-video/x264.exe)
        else
            extracommands+=(--disable-cli)
        fi
        if [[ $standalone = y && $x264 != h ]]; then
            do_print_progress "Building 10-bit x264"
            _check+=(bin-video/x264-10bit.exe)
            do_uninstall "${_check[@]}"
            create_build_dir
            CFLAGS="${CFLAGS// -O2 / }" log configure ../configure --bit-depth=10 "${extracommands[@]}"
            do_make
            do_install x264.exe bin-video/x264-10bit.exe
            cd_safe ..
            do_print_progress "Building 8-bit x264"
        else
            do_uninstall "${_check[@]}"
            if [[ $x264 = h ]]; then
                extracommands+=(--bit-depth=10) && do_print_progress "Building 10-bit x264"
            else
                do_print_progress "Building 8-bit x264"
            fi
        fi
        create_build_dir
        CFLAGS="${CFLAGS// -O2 / }" log configure ../configure "${extracommands[@]}"
        do_make
        do_makeinstall
        do_checkIfExist
        unset extracommands
    fi
else
    pc_exists x264 || do_removeOption --enable-libx264
fi

_check=(x265{,_config}.h libx265.a x265.pc)
[[ $standalone = y ]] && _check+=(bin-video/x265.exe)
if [[ ! $x265 = "n" ]] && do_vcs "hg::https://bitbucket.org/multicoreware/x265"; then
    do_uninstall libx265{_main10,_main12}.a bin-video/libx265_main{10,12}.dll "${_check[@]}"
    [[ $bits = "32bit" ]] && assembly="-DENABLE_ASSEMBLY=OFF"
    [[ $xpcomp = "y" ]] && xpsupport="-DWINXP_SUPPORT=ON"

    build_x265() {
        create_build_dir
        local build_root
        build_root="$(pwd)"
        mkdir -p {8,10,12}bit

    do_x265_cmake() {
        do_print_progress "Building $1" && shift 1
        log "cmake" cmake "$LOCALBUILDDIR/$(get_first_subdir)/source" -G Ninja \
        -DCMAKE_INSTALL_PREFIX="$LOCALDESTDIR" -DBIN_INSTALL_DIR="$LOCALDESTDIR/bin-video" \
        -DENABLE_SHARED=OFF -DENABLE_CLI=OFF -DHIGH_BIT_DEPTH=ON -DHG_EXECUTABLE=/usr/bin/hg.bat \
        $xpsupport "$@"
        log "ninja" ninja -j "${cpuCount:-1}"
    }
    [[ $standalone = y ]] && cli="-DENABLE_CLI=ON"

    if [[ $x265 != o* ]]; then
        cd_safe "$build_root/12bit"
        if [[ $x265 = s ]]; then
            do_x265_cmake "shared 12-bit lib" $assembly -DENABLE_SHARED=ON -DMAIN12=ON
            do_install libx265.dll bin-video/libx265_main12.dll
            _check+=(bin-video/libx265_main12.dll)
        else
            do_x265_cmake "12-bit lib for multilib" $assembly -DEXPORT_C_API=OFF -DMAIN12=ON
            cp libx265.a ../8bit/libx265_main12.a
        fi
    fi

    if [[ $x265 != o8 ]]; then
        cd_safe "$build_root/10bit"
        if [[ $x265 = s ]]; then
            do_x265_cmake "shared 10-bit lib" $assembly -DENABLE_SHARED=ON
            do_install libx265.dll bin-video/libx265_main10.dll
            _check+=(bin-video/libx265_main10.dll)
        elif [[ $x265 = o10 ]]; then
            do_x265_cmake "10-bit lib/bin" $assembly $cli
        else
            do_x265_cmake "10-bit lib for multilib" $assembly -DEXPORT_C_API=OFF
            cp libx265.a ../8bit/libx265_main10.a
        fi
    fi

    if [[ $x265 != o10 ]]; then
        cd_safe "$build_root/8bit"
        if [[ $x265 = s || $x265 = o8 ]]; then
            do_x265_cmake "8-bit lib/bin" $cli -DHIGH_BIT_DEPTH=OFF
        else
            do_x265_cmake "multilib lib/bin" -DEXTRA_LIB="x265_main10.a;x265_main12.a" \
                -DEXTRA_LINK_FLAGS=-L. $cli -DHIGH_BIT_DEPTH=OFF -DLINKED_{10,12}BIT=ON
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
    fi
    }
    build_x265
    log "install" ninja -j "${cpuCount:=1}" install
    if [[ $standalone = y && $x265 = d ]]; then
        cd_safe "${LOCALBUILDDIR}/$(get_first_subdir)"
        do_uninstall bin-video/x265-numa.exe
        do_print_progress "Building NUMA version of binary"
        xpsupport="" build_x265
        do_install x265.exe bin-video/x265-numa.exe
        _check+=(bin-video/x265-numa.exe)
    fi
    do_checkIfExist
    unset xpsupport assembly cli
else
    pc_exists x265 || do_removeOption "--enable-libx265"
fi

_check=(libopenh264.a openh264.pc wels/codec_api.h)
if [[ $ffmpeg != "n" ]] && enabled libopenh264 &&
    do_vcs https://github.com/cisco/openh264.git; then
    do_uninstall include/wels "${_check[@]}"
    create_build_dir
    do_make -f ../Makefile AR=ar ARCH="$CARCH" OS=mingw_nt PREFIX="$LOCALDESTDIR" install-static
    do_checkIfExist
fi

if [[ $ffmpeg != "n" ]]; then
    enabled libschroedinger && do_pacman_install schroedinger
    enabled libgsm && do_pacman_install gsm
    enabled libsnappy && do_addOption --extra-libs=-lstdc++ && do_pacman_install snappy
    if enabled libxvid; then
        do_pacman_install xvidcore
        [[ -f $MINGW_PREFIX/lib/xvidcore.a ]] && mv -f "$MINGW_PREFIX"/lib/{,lib}xvidcore.a
        [[ -f $MINGW_PREFIX/lib/xvidcore.dll.a ]] && mv -f "$MINGW_PREFIX"/lib/xvidcore.dll.a{,.dyn}
    fi
    if enabled libssh; then
        do_pacman_install libssh
        do_addOption --extra-cflags=-DLIBSSH_STATIC "--extra-ldflags=-Wl,--allow-multiple-definition"
        grep -q "Requires.private" "$MINGW_PREFIX"/lib/pkgconfig/libssh.pc ||
            sed -i "/Libs:/ i\Requires.private: libssl" "$MINGW_PREFIX"/lib/pkgconfig/libssh.pc
    fi
    enabled libtheora && do_pacman_install libtheora
    enabled libcdio && do_pacman_install libcdio-paranoia
    if enabled libcaca; then
        do_pacman_install libcaca
        do_addOption --extra-cflags=-DCACA_STATIC
    fi
    if enabled libmodplug; then
        do_pacman_install libmodplug
        do_addOption --extra-cflags=-DMODPLUG_STATIC
    fi
    if enabled netcdf; then
        do_pacman_install netcdf
        sed -i 's/-lhdf5 -lz/-lhdf5 -lszip -lz/' "$MINGW_PREFIX"/lib/pkgconfig/netcdf.pc
    fi

    do_hide_all_sharedlibs

    if [[ $ffmpeg = "s" ]]; then
        _check=(bin-video/ffmpegSHARED)
    else
        _check=(libavutil.{a,pc})
        disabled_any avfilter ffmpeg || _check+=(bin-video/ffmpeg.exe)
    fi
    [[ $ffmpegUpdate = y ]] && enabled_any lib{ass,x264,x265,vpx} &&
        _deps=(lib{ass,x264,x265,vpx}.a)
    if do_vcs "https://git.ffmpeg.org/ffmpeg.git"; then

        [[ -f ffmpeg_extra.sh ]] && source ffmpeg_extra.sh

        _patches="$(git rev-list origin/master.. --count)"
        [[ $_patches -gt 0 ]] &&
            do_addOption "--extra-version=g$(git rev-parse --short origin/master)+$_patches"
        do_changeFFmpegConfig "$license"

        _uninstall=(include/libav{codec,device,filter,format,util,resample}
            include/lib{sw{scale,resample},postproc}
            libav{codec,device,filter,format,util,resample}.{a,pc}
            lib{sw{scale,resample},postproc}.{a,pc})
        _check=()
        sedflags="prefix|bindir|extra-(cflags|libs|ldflags|version)|pkg-config-flags"

        # shared
        if [[ $ffmpeg != "y" ]] && [[ ! -f build_successful${bits}_shared ]]; then
            do_print_progress "Compiling ${bold}shared${reset} FFmpeg"
            [[ -f config.mak ]] && log "distclean" make distclean
            do_uninstall bin-video/ffmpegSHARED "${_uninstall[@]}"
            create_build_dir shared
            LDFLAGS+=" -L$LOCALDESTDIR/lib -L$MINGW_PREFIX/lib" \
                log configure ../configure --prefix="$LOCALDESTDIR/bin-video/ffmpegSHARED" \
                --disable-static --enable-shared "${FFMPEG_OPTS_SHARED[@]}"
            # cosmetics
            sed -ri "s/ ?--($sedflags)=(\S+[^\" ]|'[^']+')//g" config.h
            do_make && do_makeinstall
            if ! disabled_any programs avcodec avformat; then
                _check+=(bin-video/ffmpegSHARED)
                if ! disabled swresample; then
                    disabled_any avfilter ffmpeg || _check+=(bin-video/ffmpegSHARED/bin/ffmpeg.exe)
                    disabled_any sdl ffplay || _check+=(bin-video/ffmpegSHARED/bin/ffplay.exe)
                fi
                disabled ffprobe || _check+=(bin-video/ffmpegSHARED/bin/ffprobe.exe)
            fi
            cd_safe ..
            files_exist "${_check[@]}" && touch "build_successful${bits}_shared"
        fi

        # static
        if [[ $ffmpeg != "s" ]]; then
            do_print_progress "Compiling ${bold}static${reset} FFmpeg"
            [[ -f config.mak ]] && log "distclean" make distclean
            if ! disabled_any programs avcodec avformat; then
                _check+=(libavutil.{a,pc})
                if ! disabled swresample; then
                    disabled_any avfilter ffmpeg || _check+=(bin-video/ffmpeg.exe)
                    disabled_any sdl ffplay || _check+=(bin-video/ffplay.exe)
                fi
                disabled ffprobe || _check+=(bin-video/ffprobe.exe)
            fi
            do_uninstall bin-video/ff{mpeg,play,probe}.exe{,.debug} "${_uninstall[@]}"
            create_build_dir static
            LDFLAGS+=" -L$LOCALDESTDIR/lib -L$MINGW_PREFIX/lib" \
                log configure ../configure --prefix="$LOCALDESTDIR" \
                --bindir="$LOCALDESTDIR/bin-video" "${FFMPEG_OPTS[@]}"
            # cosmetics
            sed -ri "s/ ?--($sedflags)=(\S+[^\" ]|'[^']+')//g" config.h
            do_make && do_makeinstall
            enabled debug &&
                create_debug_link "$LOCALDESTDIR"/bin-video/ff{mpeg,probe,play}.exe
            cd_safe ..
        fi
        do_checkIfExist
    fi
fi

_check=(bin-video/m{player,encoder}.exe)
if [[ $mplayer = "y" ]] &&
    do_vcs "svn::svn://svn.mplayerhq.hu/mplayer/trunk" mplayer; then
    [[ $license != "nonfree" || $faac = n ]] && faac_opts=(--disable-faac --disable-faac-lavc)
    do_uninstall "${_check[@]}"
    [[ -f config.mak ]] && log "distclean" make distclean
    if [[ ! -d ffmpeg ]]; then
        if [[ "$ffmpeg" != "n" ]] &&
            git clone -q "$LOCALBUILDDIR"/ffmpeg-git ffmpeg; then
            pushd ffmpeg >/dev/null
            git checkout -qf --no-track -B master origin/HEAD
            popd >/dev/null
        elif ! git clone "https://git.ffmpeg.org/ffmpeg.git" ffmpeg; then
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
    --extra-ldflags='-Wl,--allow-multiple-definition' --enable-{static,runtime-cpudetection} \
    --disable-{gif,cddb} "${faac_opts[@]}" --with-dvdread-config="$PKG_CONFIG dvdread" \
    --with-freetype-config="$PKG_CONFIG freetype2" --with-dvdnav-config="$PKG_CONFIG dvdnav" &&
        do_makeinstall && do_checkIfExist
    unset _notrequired faac_opts
fi

if [[ $xpcomp = "n" && $mpv != "n" ]] && pc_exists libavcodec libavformat libswscale libavfilter; then
    _check=(libluajit-5.1.a luajit.pc luajit-2.0/luajit.h)
    if ! mpv_disabled lua && [[ ${MPV_OPTS[@]} != "${MPV_OPTS[@]#--lua=lua51}" ]]; then
        do_pacman_install lua51
    elif ! mpv_disabled lua && do_pkgConfig luajit &&
        do_vcs "http://luajit.org/git/luajit-2.0.git" luajit; then
        do_pacman_remove lua51
        do_uninstall include/luajit-2.0 lib/lua "${_check[@]}"
        rm -rf ./temp
        [[ -f "src/luajit.exe" ]] && log "clean" make clean
        do_make BUILDMODE=static amalg
        do_makeinstall BUILDMODE=static PREFIX="$LOCALDESTDIR" DESTDIR="$(pwd)/temp"
        cd_safe "temp${LOCALDESTDIR}"
        mkdir -p "$LOCALDESTDIR/include/luajit-2.0"
        do_install include/luajit-2.0/*.h include/luajit-2.0/
        do_install lib/libluajit-5.1.a lib/
        # luajit comes with a broken .pc file
        sed -r -i "s/(Libs.private:).*/\1 -liconv/" lib/pkgconfig/luajit.pc
        do_install lib/pkgconfig/luajit.pc lib/pkgconfig/
        do_checkIfExist
        add_to_remove
    fi

    do_pacman_remove uchardet-git
    _check=(uchardet/uchardet.h uchardet.pc libuchardet.a)
    [[ $standalone = y ]] && _check+=(bin-global/uchardet.exe)
    if ! mpv_disabled uchardet && do_vcs "https://github.com/BYVoid/uchardet.git"; then
        do_uninstall "${_check[@]}"
        do_cmakeinstall -DCMAKE_INSTALL_BINDIR="$LOCALDESTDIR/bin-global" \
            $([[ $standalone = y ]] || echo -DBUILD_BINARY=off)
        do_checkIfExist
    fi

    mpv_enabled libarchive && do_pacman_install libarchive
    ! mpv_disabled lcms2 && do_pacman_install lcms2

    if ! mpv_disabled egl-angle; then
        _check=(EGL/egl.h bin-video/lib{GLESv2,EGL}.dll)
        do_pacman_remove angleproject-git
        if [[ $bits = 64bit && $angle = y ]]; then
            if do_vcs "https://chromium.googlesource.com/angle/angle#commit=2963985" angleproject; then
                do_wget -c -r -q /patches/Makefile.angle
                log "uninstall" make -f Makefile.angle PREFIX="$LOCALDESTDIR" \
                    BINDIR="$LOCALDESTDIR/bin-video" uninstall
                [[ -f libEGL.dll ]] && log "clean" make -f Makefile.angle clean
                do_makeinstall -f Makefile.angle PREFIX="$LOCALDESTDIR" BINDIR="$LOCALDESTDIR/bin-video"
            fi
            do_checkIfExist
        elif [[ $angle = h ]] &&
            do_wget -r -z https://i.fsbn.eu/pub/angle/angle-latest-win"${bits%bit}".7z; then
            do_install lib{EGL,GLESv2}.dll bin-video/
            cp -rf include/* "$LOCALDESTDIR/include/"
            do_checkIfExist
            add_to_remove
        fi
        if files_exist "EGL/egl.h"; then
            printf "%s\n" \
                "${orange}mpv will depend on libEGL.dll and libGLESv2.dll for angle backend" \
                "but they're not needed if angle backend isn't required.${reset}"
        fi
    fi

    vsprefix=$(get_vs_prefix)
    if ! mpv_disabled vapoursynth && [[ -n $vsprefix ]]; then
        vsversion=$("$vsprefix"/vspipe -v | grep -Po "(?<=Core R)\d+")
        if [[ $vsversion -ge 24 ]]; then
            echo -e "${green}Compiling mpv with Vapoursynth R${vsversion}${reset}"
            echo -e "${orange}mpv will need vapoursynth.dll and vsscript.dll to run!${reset}"
        else
            vsprefix=""
            echo -e "${red}Update to at least Vapoursynth R24 to use with mpv${reset}"
        fi
        _check=(lib{vapoursynth,vsscript}.a vapoursynth{,-script}.pc
            vapoursynth/{VS{Helper,Script},VapourSynth}.h)
        if [[ x"$vsprefix" != x ]] &&
            { ! pc_exists "vapoursynth = $vsversion" || ! files_exist "${_check[@]}"; }; then
            do_uninstall {vapoursynth,vsscript}.lib "${_check[@]}"
            baseurl="https://github.com/vapoursynth/vapoursynth/raw/"
            ret="$("${curl_opts[@]}" -w "%{response_code}" -o /dev/null "${baseurl}/R${vsversion}/configure.ac")"
            if [[ $ret != 404 ]]; then
                baseurl+="R${vsversion}"
            else
                baseurl+="master"
            fi
            mkdir -p "$LOCALBUILDDIR/vapoursynth" && cd_safe "$LOCALBUILDDIR/vapoursynth"

            # headers
            for _file in {VS{Helper,Script},VapourSynth}.h; do
                do_wget -r -c -q "${baseurl}/include/${_file}"
                [[ -f $_file ]] && do_install "$_file" "vapoursynth/$_file"
            done

            # import libs
            create_build_dir
            for _file in vapoursynth vsscript; do
                gendef - "$vsprefix/${_file}.dll" 2>/dev/null |
                    sed -r -e 's|^_||' -e 's|@[1-9]+$||' > "${_file}.def"
                dlltool -l "lib${_file}.a" -d "${_file}.def" \
                    $([[ $bits = 32bit ]] && echo "-U") 2>/dev/null
                [[ -f lib${_file}.a ]] && do_install "lib${_file}.a"
            done

            "${curl_opts[@]}" "$baseurl/pc/vapoursynth.pc.in" |
            sed -e "s;@prefix@;$LOCALDESTDIR;" \
                -e 's;@exec_prefix@;${prefix};' \
                -e 's;@libdir@;${prefix}/lib;' \
                -e 's;@includedir@;${prefix}/include;' \
                -e "s;@VERSION@;$vsversion;" \
                -e '/Libs.private/ d' \
                > vapoursynth.pc
            [[ -f vapoursynth.pc ]] && do_install vapoursynth.pc
            "${curl_opts[@]}" "$baseurl/pc/vapoursynth-script.pc.in" |
            sed -e "s;@prefix@;$LOCALDESTDIR;" \
                -e 's;@exec_prefix@;${prefix};' \
                -e 's;@libdir@;${prefix}/lib;' \
                -e 's;@includedir@;${prefix}/include;' \
                -e "s;@VERSION@;$vsversion;" \
                -e '/Requires.private/ d' \
                -e 's;lvapoursynth-script;lvsscript;' \
                -e '/Libs.private/ d' \
                > vapoursynth-script.pc
            [[ -f vapoursynth-script.pc ]] && do_install vapoursynth-script.pc

            do_checkIfExist
            add_to_remove
        elif [[ -z "$vsprefix" ]]; then
            mpv_disable vapoursynth
        fi
        unset vsprefix vsversion _file baseurl ret
    elif ! mpv_disabled vapoursynth; then
        mpv_disable vapoursynth
    fi

    _check=(bin-video/mpv.{exe,com})
    _deps=(lib{ass,avcodec,uchardet,vapoursynth}.a)
    if do_vcs "https://github.com/mpv-player/mpv.git"; then
        hide_conflicting_libs

        [[ ! -f waf ]] && /usr/bin/python bootstrap.py >/dev/null 2>&1
        if [[ -d build ]]; then
            /usr/bin/python waf distclean >/dev/null 2>&1
            do_uninstall bin-video/mpv{.exe,-1.dll}.debug "${_check[@]}"
        fi

        mpv_ldflags=("-L$LOCALDESTDIR/lib" "-L$MINGW_PREFIX/lib")
        if enabled_any cuda cuvid libnpp; then
            mpv_cflags=("-I$(cygpath -sm "$CUDA_PATH")/include")
            if [[ $bits = 64bit ]]; then
                mpv_ldflags+=("-L$(cygpath -sm "$CUDA_PATH")/lib/x64")
            else
                mpv_ldflags+=("-L$(cygpath -sm "$CUDA_PATH")/lib/Win32")
            fi
        fi
        [[ $bits = "64bit" ]] && mpv_ldflags+=("-Wl,--image-base,0x140000000,--high-entropy-va")
        enabled libssh && mpv_ldflags+=("-Wl,--allow-multiple-definition")

        [[ -f mpv_extra.sh ]] && source mpv_extra.sh

        # for purely cosmetic reasons, show the last release version when doing -V
        git tag -l --sort=version:refname | tail -1 | cut -c 2- > VERSION

        CFLAGS+=" ${mpv_cflags[*]}" LDFLAGS+=" ${mpv_ldflags[*]}" \
            log configure /usr/bin/python waf configure \
            "--prefix=$LOCALDESTDIR" "--bindir=$LOCALDESTDIR/bin-video" --enable-static-build \
            "--libdir=$LOCALDESTDIR/lib" --disable-{libguess,vapoursynth-lazy} "${MPV_OPTS[@]}"

        # Windows(?) has a lower argument limit than *nix so
        # we replace tons of repeated -L flags with just two
        replace="LIBPATH_lib\1 = ['${LOCALDESTDIR}/lib','${MINGW_PREFIX}/lib']"
        sed -r -i "s:LIBPATH_lib(ass|av(|device|filter)) = .*:$replace:g" ./build/c4che/_cache.py

        log build /usr/bin/python waf -j "${cpuCount:-1}"

        unset mpv_ldflags replace
        hide_conflicting_libs -R
        do_install build/mpv.{exe,com} bin-video/
        ! mpv_disabled manpage-build && [[ -f build/DOCS/man/mpv.1 ]] &&
            do_install build/DOCS/man/mpv.1 share/man/man1/
        if mpv_enabled libmpv-shared; then
            do_install build/mpv-1.dll bin-video/
            do_install build/libmpv.dll.a lib/
            do_install libmpv/{{client,opengl_cb}.h,qthelper.hpp} include/
            _check+=(bin-video/mpv-1.dll libmpv.dll.a)
        fi
        ! mpv_disabled debug-build &&
            create_debug_link "$LOCALDESTDIR"/bin-video/mpv{.exe,-1.dll}
        do_checkIfExist
    fi
fi

if [[ $bmx = "y" ]]; then
    _check=(liburiparser.{{,l}a,pc})
    if do_pkgConfig "liburiparser = 0.8.2"; then
        do_wget_sf -h c5cf6b3941d887deb7defc2a86c40f1d \
            "uriparser/Sources/0.8.2/uriparser-0.8.2.tar.bz2"
        do_uninstall include/uriparser "${_check[@]}"
        sed -i '/bin_PROGRAMS/ d' Makefile.am
        do_separate_confmakeinstall --disable-{test,doc}
        do_checkIfExist
    fi

    _check=(bin-video/MXFDump.exe libMXF-1.0.{{,l}a,pc})
    if do_vcs http://git.code.sf.net/p/bmxlib/libmxf libMXF-1.0; then
        do_autogen
        do_uninstall include/libMXF-1.0 "${_check[@]}"
        do_separate_confmakeinstall video --disable-examples
        do_checkIfExist
    fi

    _check=(libMXF++-1.0.{{,l}a,pc})
    _deps=(libMXF-1.0.a)
    if do_vcs http://git.code.sf.net/p/bmxlib/libmxfpp libMXF++-1.0; then
        do_autogen
        do_uninstall include/libMXF++-1.0 "${_check[@]}"
        do_separate_confmakeinstall video --disable-examples
        do_checkIfExist
    fi

    _check=(bin-video/{bmxtranswrap,{h264,mov}dump,mxf2raw,raw2bmx}.exe)
    _deps=(lib{uriparser,MXF{,++}-1.0,curl}.a)
    if do_vcs http://git.code.sf.net/p/bmxlib/bmx; then
        do_autogen
        do_uninstall libbmx-0.1.{{,l}a,pc} bin-video/bmxparse.exe \
            include/bmx-0.1 "${_check[@]}"
        do_separate_confmakeinstall video
        do_checkIfExist
    fi
fi

echo -e "\n\t${orange}Finished $bits compilation of all tools${reset}"
}

run_builds() {
    new_updates="no"
    new_updates_packages=""
    if [[ $build32 = "yes" ]]; then
        source /local32/etc/profile2.local
        buildProcess
    fi

    if [[ $build64 = "yes" ]]; then
        source /local64/etc/profile2.local
        buildProcess
    fi
}

cd_safe "$LOCALBUILDDIR"
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

clean_suite

echo -e "\n\t${green}Compilation successful.${reset}"
echo -e "\t${green}This window will close automatically in 5 seconds.${reset}"
sleep 5
