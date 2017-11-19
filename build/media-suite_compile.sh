#!/bin/bash
shopt -s extglob

FFMPEG_BASE_OPTS=(--pkg-config-flags=--static)
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

{
    echo '#!/bin/bash'
    echo "bash $LOCALBUILDDIR/media-suite_compile.sh $*"
} > "$LOCALBUILDDIR/last_run"

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
--aom=* ) aom="${1#*=}"; shift ;;
--daala=* ) daala="${1#*=}"; shift ;;
--faac=* ) faac="${1#*=}"; shift ;;
--ffmbc=* ) ffmbc="${1#*=}"; shift ;;
--curl=* ) curl="${1#*=}"; shift ;;
--cyanrip=* ) cyanrip="${1#*=}"; shift ;;
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

# in case the root was moved, this fixes windows abspaths
_pkg_config_files=$(find "$LOCALDESTDIR/lib/pkgconfig/" -name "*.pc")
if [[ -n "$_pkg_config_files" ]]; then
    screwed_prefixes=($(grep -E -l "(prefix|libdir|includedir)=[^/$].*" $_pkg_config_files))
    [[ -n "${screwed_prefixes[@]}" ]] &&
        screwed_prefixes=($(grep -qL "$(cygpath -m "$LOCALDESTDIR")" "${screwed_prefixes[@]}"))
    [[ -n "${screwed_prefixes[@]}" ]] && sed -ri \
        "s;(prefix|libdir|includedir)=.*${LOCALDESTDIR};\1=$(cygpath -m /trunk)${LOCALDESTDIR};g" \
        "${screwed_prefixes[@]}"
fi

_clean_old_builds=(j{config,error,morecfg,peglib}.h
    lib{jpeg,nettle,ogg,vorbis{,enc,file},opus{file,url},gnurx,regex}.{,l}a
    lib{opencore-amr{nb,wb},twolame,theora{,enc,dec},caca,magic,luajit-5.1,uchardet}.{l,}a
    libSDL{,main}.{l,}a libopen{jpwl,mj2,jp2}.{a,pc} lib/lua
    include/{nettle,ogg,opencore-amr{nb,wb},theora,cdio,SDL,openjpeg-2.{1,2},luajit-2.0,uchardet,wels}
    opus/opusfile.h regex.h magic.h
    {nettle,ogg,vorbis{,enc,file},opus{file,url},vo-aacenc,sdl,luajit,uchardet}.pc
    {opencore-amr{nb,wb},twolame,theora{,enc,dec},caca,dcadec,libEGL,openh264}.pc
    libcdio_{cdda,paranoia}.{{l,}a,pc}
    share/aclocal/{ogg,vorbis}.m4
    twolame.h bin-audio/{twolame,cd-paranoia}.exe
    bin-global/{{file,uchardet}.exe,sdl-config,luajit{,-2.0.4.exe}}
    libebur128.a ebur128.h
    libopenh264.a
    liburiparser.{{,l}a,pc}
    libchromaprint.{a,pc} chromaprint.h
    libopus.{,l}a opus.pc include/opus
)

do_uninstall q all "${_clean_old_builds[@]}"
unset _clean_old_builds

# In case a build was interrupted before reversing hide_conflicting_libs
[[ -d "$LOCALDESTDIR/opt/cyanffmpeg" ]] &&
    hide_conflicting_libs -R "$LOCALDESTDIR/opt/cyanffmpeg"
hide_conflicting_libs -R
do_hide_all_sharedlibs

set_title "compiling global tools"
echo -e "\n\t${orange}Starting $bits compilation of global tools${reset}"

if [[ $packing = y ]] &&
    ! [[ -e /opt/bin/upx.exe && "$(/opt/bin/upx -V | head -1)" = "upx 3.94" ]]; then
    do_wget -h 74308db1183436576d011bfcc3e7c99c836fb052de7b7eb0539026366453d6e8 \
        "https://github.com/upx/upx/releases/download/v3.94/upx394w.zip"
    do_install upx.exe /opt/bin/upx.exe
fi

if [[ "$mplayer" = "y" ]] || ! mpv_disabled libass ||
    { [[ $ffmpeg != "no" ]] && enabled_any libass libfreetype {lib,}fontconfig libfribidi; }; then
    do_pacman_remove freetype fontconfig harfbuzz fribidi

    _check=(libfreetype.{l,}a freetype2.pc)
    [[ $ffmpeg = "sharedlibs" ]] && _check+=(bin-video/libfreetype-6.dll libfreetype.dll.a)
    if do_pkgConfig "freetype2 = 21.0.15" "2.8.1"; then
        do_wget_sf -h e5435f02e02d2b87bb8e4efdcaa14b1f78c9cf3ab1ed80f94b6382fb6acc7d78 \
            "freetype/freetype2/2.8.1/freetype-2.8.1.tar.bz2"
        do_uninstall include/freetype2 bin-global/freetype-config \
            bin{,-video}/libfreetype-6.dll libfreetype.dll.a "${_check[@]}"
        extracommands=(--with-{harfbuzz,png,bzip2}=no)
        [[ $ffmpeg = "sharedlibs" ]] && extracommands+=(--enable-shared)
        do_separate_confmakeinstall global "${extracommands[@]}"
        [[ $ffmpeg = "sharedlibs" ]] && do_install "$LOCALDESTDIR"/bin/libfreetype-6.dll bin-video/
        do_checkIfExist
    fi

    _deps=(libfreetype.a)
    _check=(libfontconfig.{,l}a fontconfig.pc)
    [[ $ffmpeg = "sharedlibs" ]] && enabled_any {lib,}fontconfig &&
        do_removeOption "--enable-(lib|)fontconfig"
    if enabled_any {lib,}fontconfig &&
        do_vcs "https://anongit.freedesktop.org/git/fontconfig#tag=2.12.6"; then
        do_pacman_install python2-lxml python2-six
        do_uninstall include/fontconfig "${_check[@]}"
        [[ $standalone = y ]] || sed -ri Makefile.am \
            -e '/^SUBDIRS=/,+2{s;fontconfig.*;fontconfig src;g;/fc-[^b]/d}' \
            -e 's;(RUN_FC_CACHE_TEST=).*;\1false;g'
        do_autogen --noconf
        PYTHON="$MINGW_PREFIX/bin/python2" do_separate_confmakeinstall global --disable-docs
        do_checkIfExist
    fi

    _deps=(libfreetype.a)
    _check=(libharfbuzz.{,l}a harfbuzz.pc)
    if [[ $ffmpeg != "sharedlibs" ]] && do_vcs "https://github.com/behdad/harfbuzz.git"; then
        do_pacman_install ragel
        NOCONFIGURE=y do_autogen
        do_uninstall include/harfbuzz "${_check[@]}"
        do_separate_confmakeinstall --with-{icu,glib,gobject,cairo,fontconfig,uniscribe}=no
        # directwrite shaper doesn't work with mingw headers, maybe too old
        do_checkIfExist
    fi
    unset _deps

    _check=(libfribidi.{l,}a fribidi.pc)
    [[ $standalone = y ]] && _check+=(bin-global/fribidi.exe)
    [[ $ffmpeg = "sharedlibs" ]] && _check+=(bin-video/libfribidi-0.dll libfribidi.dll.a)
    if do_pkgConfig "fribidi = 0.19.7"; then
        do_wget -h 6c7e7cfdd39c908f7ac619351c1c5c23 \
            "http://pkgs.fedoraproject.org/repo/pkgs/fribidi/fribidi-0.19.7.tar.bz2/6c7e7cfdd39c908f7ac619351c1c5c23/fribidi-0.19.7.tar.bz2"
        do_uninstall include/fribidi bin{,-video}/libfribidi-0.dll libfribidi.dll.a \
            bin-global/fribidi.exe "${_check[@]}"
        [[ $standalone = y ]] || sed -i 's|bin doc test||' Makefile.in
        [[ $ffmpeg = "sharedlibs" ]] &&
            sed -i 's/$(am__append_1) $(am__append_2)/-export-symbols-regex "^fribidi_.*"/' lib/Makefile.in
        extracommands=(--disable-{deprecated,debug} --with-glib=no)
        [[ $ffmpeg = "sharedlibs" ]] && extracommands+=(--enable-shared)
        do_separate_confmakeinstall global "${extracommands[@]}"
        [[ $ffmpeg = "sharedlibs" ]] && do_install "$LOCALDESTDIR"/bin/libfribidi-0.dll bin-video/
        do_checkIfExist
    fi

    _check=(ass/ass{,_types}.h libass.{{,l}a,pc})
    _deps=(lib{freetype,fontconfig,harfbuzz,fribidi}.a)
    [[ $ffmpeg = "sharedlibs" ]] && _check+=(bin-video/libass-9.dll libass.dll.a)
    if do_vcs "https://github.com/libass/libass.git"; then
        do_autoreconf
        do_uninstall bin{,-video}/libass-9.dll libass.dll.a include/ass "${_check[@]}"
        extracommands=()
        enabled_any {lib,}fontconfig || extracommands+=(--disable-fontconfig)
        [[ $ffmpeg = "sharedlibs" ]] && extracommands+=(--disable-{harfbuzz,fontconfig} --enable-shared)
        do_separate_confmakeinstall "${extracommands[@]}"
        [[ $ffmpeg = "sharedlibs" ]] && do_install "$LOCALDESTDIR"/bin/libass-9.dll bin-video/
        do_checkIfExist
    fi
    if [[ $ffmpeg != "sharedlibs" ]]; then
        find "$LOCALDESTDIR/lib" -name "*.dll.a" -exec rm -f '{}' \;
    fi
fi

_check=(bin-global/libgcrypt-config libgcrypt.a gcrypt.h)
_ver="1.7.8"
if [[ $ffmpeg != "no" ]] && enabled gcrypt; then
    do_pacman_install libgpg-error
    do_pacman_remove libgcrypt
    if files_exist "${_check[@]}" && [[ "$(libgcrypt-config --version)" = "$_ver" ]]; then
        do_print_status "libgcrypt $_ver" "$green" "Up-to-date"
    else
        do_wget -h 948276ea47e6ba0244f36a17b51dcdd52cfd1e664b0a1ac3bc82134fb6cec199 \
            "https://gnupg.org/ftp/gcrypt/libgcrypt/libgcrypt-$_ver.tar.bz2"
        do_uninstall "${_check[@]}"
        extracommands=()
        [[ $bits = 64bit ]] && sed -ri 's;movq;movabs;g' cipher/rijndael.c &&
            extracommands+=(--disable-{padlock-support,asm})
        [[ $standalone = y ]] || sed -ri "s|(^bin_PROGRAMS = ).*|\1\\\|" src/Makefile.in
        sed -ri "s;(^SUBDIRS .*) tests;\1;" Makefile.in
        do_separate_confmakeinstall global --disable-doc \
            --enable-ciphers=aes,des,rfc2268,arcfour \
            --enable-digests=sha1,md5,rmd160,sha256,sha512 \
            --enable-pubkey-ciphers=dsa,rsa,ecc \
            --with-gpg-error-prefix="$MINGW_PREFIX" \
            "${extracommands[@]}"
        do_checkIfExist
        unset extracommands
    fi
fi

if { { [[ $ffmpeg != "no" ]] && enabled gnutls; } ||
    [[ $rtmpdump = y && $license != nonfree ]]; }; then
    [[ -z "$gnutls_ver" ]] &&
        gnutls_ver="$("${curl_opts[@]}" -l "ftp://ftp.gnutls.org/gcrypt/gnutls/v3.5/")" &&
        gnutls_ver="$(get_last_version "$gnutls_ver" "xz$" '3\.5\.\d+(\.\d+)?')"
    gnutls_ver="${gnutls_ver:-3.5.12}"
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
            --with-included-unistring \
            LDFLAGS="$LDFLAGS -L${LOCALDESTDIR}/lib -L${MINGW_PREFIX}/lib"
        do_checkIfExist
    fi
    grep -q "lib.*\.a" "$(file_installed gnutls.pc)" &&
        sed -ri "s;($LOCALDESTDIR|$MINGW_PREFIX)/lib/lib(\w+).a;-l\2;g" "$(file_installed gnutls.pc)"
fi

if { { [[ $ffmpeg != "no" ]] && enabled openssl; } ||
    [[ $rtmpdump = y && $license = nonfree ]]; }; then
    [[ ! "$libressl_ver" ]] &&
        libressl_ver="$(clean_html_index "http://ftp.openbsd.org/pub/OpenBSD/LibreSSL/")" &&
        libressl_ver="$(get_last_version "$libressl_ver" "" '2\.\d+\.\d+')"
    libressl_ver="${libressl_ver:-2.5.4}"
    _check=(tls.h lib{crypto,ssl,tls}.{pc,{,l}a} openssl.pc)
    [[ $standalone = y ]] && _check+=("bin-global/openssl.exe")
    if do_pkgConfig "libssl = $libressl_ver"; then
        sha256sum="$(curl -s http://ftp.openbsd.org/pub/OpenBSD/LibreSSL/SHA256 | \
            grep "libressl-${libressl_ver}.tar.gz" | awk '{print $4}')"
        do_wget -h "$sha256sum" \
            "http://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-${libressl_ver}.tar.gz"
        do_uninstall etc/ssl include/openssl "${_check[@]}"
        _sed="man"
        [[ $standalone = y ]] || _sed="apps tests $_sed"
        sed -ri "s;(^SUBDIRS .*) $_sed;\1;" Makefile.in
        do_separate_confmakeinstall global
        do_checkIfExist
        unset _sed sha256sum
    fi
fi

[[ ! "$curl_ver" ]] &&
    curl_ver="$(clean_html_index https://curl.haxx.se/download/)" &&
    curl_ver="$(get_last_version "$curl_ver" bz2 "7\.\d+\.\d")"
curl_ver="${curl_ver:-7.54.0}"
_check=(curl/curl.h libcurl.{{,l}a,pc})
_deps=()
enabled openssl && _deps+=(libssl.a)
enabled gnutls && _deps+=(libgnutls.a)
[[ $standalone = y || $curl = y ]] && _check+=(bin-global/curl.exe)
if [[ $mediainfo = y || $bmx = y || $curl = y ]] &&
    do_pkgConfig "libcurl = $curl_ver"; then
    do_pacman_install nghttp2
    do_wget "https://curl.haxx.se/download/curl-${curl_ver}.tar.bz2"
    do_uninstall include/curl bin-global/curl-config "${_check[@]}"
    [[ $standalone = y || $curl = y ]] ||
        sed -ri "s;(^SUBDIRS = lib) src (include) scripts;\1 \2;" Makefile.in
    extra_opts=()
    if enabled openssl; then
        extra_opts+=(--with-{ssl,nghttp2} --without-gnutls)
    elif enabled gnutls; then
        extra_opts+=(--with-gnutls --without-{ssl,nghttp2})
    else
        extra_opts+=(--with-{winssl,winidn,nghttp2} --without-{ssl,gnutls})
    fi
    /usr/bin/grep -q "NGHTTP2_STATICLIB" libcurl.pc.in ||
        { sed -i 's;Cflags.*;& -DNGHTTP2_STATICLIB;' libcurl.pc.in &&
          sed -i 's;-DCURL_STATICLIB ;&-DNGHTTP2_STATICLIB ;' curl-config.in; }
    hide_conflicting_libs
    CPPFLAGS+=" -DNGHTTP2_STATICLIB" \
        do_separate_confmakeinstall global "${extra_opts[@]}" \
        --without-{libssh2,random,ca-bundle,ca-path,librtmp,libidn2} \
        --enable-sspi --disable-{debug,manual}
    hide_conflicting_libs -R
    _notrequired=yes
    PATH=/usr/bin log ca-bundle make ca-bundle
    unset _notrequired
    enabled_any openssl gnutls && [[ -f lib/ca-bundle.crt ]] &&
        cp -f lib/ca-bundle.crt "$LOCALDESTDIR"/bin-global/curl-ca-bundle.crt
    do_checkIfExist
fi
unset _deps

_check=(libwebp{,mux}.{{,l}a,pc})
[[ $standalone = y ]] && _check+=(libwebp{demux,decoder}.{{,l}a,pc}
    bin-global/{{c,d}webp,webpmux,img2webp}.exe)
if [[ $ffmpeg != "no" || $standalone = y ]] && enabled libwebp &&
    do_vcs "https://chromium.googlesource.com/webm/libwebp"; then
    do_pacman_install libtiff
    if [[ $standalone = y ]]; then
        extracommands=(--enable-{experimental,libwebp{demux,decoder,extras}}
            LIBS="$($PKG_CONFIG --libs libpng libtiff-4)")
    else
        extracommands=()
        sed -i -e '/examples/d' -e 's/ man//' Makefile.am
    fi
    do_autoreconf
    do_uninstall include/webp bin-global/gif2webp.exe "${_check[@]}"
    do_separate_confmakeinstall global --enable-{swap-16bit-csp,libwebpmux} \
        "${extracommands[@]}"
    do_checkIfExist
fi

syspath=$(cygpath -S)
[[ $bits = "32bit" && -d "$syspath/../SysWOW64" ]] && syspath="$syspath/../SysWOW64"
if [[ $ffmpeg != "no" ]] && enabled opencl && [[ -f "$syspath/OpenCL.dll" ]]; then
    echo -e "${orange}FFmpeg and related apps will depend on OpenCL.dll${reset}"
    _check=(libOpenCL.a)
    do_pacman_install opencl-headers
    if ! files_exist "${_check[@]}"; then
        cd_safe "$LOCALBUILDDIR"
        [[ -d opencl ]] && rm -rf opencl
        mkdir -p opencl && cd_safe opencl
        create_build_dir
        gendef "$syspath/OpenCL.dll" >/dev/null 2>&1
        [[ -f OpenCL.def ]] && dlltool -y libOpenCL.a -d OpenCL.def -k -A
        [[ -f libOpenCL.a ]] && do_install libOpenCL.a
        do_checkIfExist
    fi
else
    do_removeOption --enable-opencl
fi
unset syspath

if [[ $ffmpeg != "no" || $standalone = y ]] && enabled libtesseract; then
    do_pacman_remove tesseract-ocr
    do_pacman_install libtiff
    _check=(liblept.{,l}a lept.pc)
    if do_pkgConfig "lept = 1.74.4"; then
        do_wget -h 29c35426a416bf454413c6fec24c24a0b633e26144a17e98351b6dffaa4a833b \
            "http://www.leptonica.com/source/leptonica-1.74.4.tar.gz"
        do_uninstall include/leptonica "${_check[@]}"
        do_separate_confmakeinstall --disable-programs --without-{lib{openjpeg,webp},giflib}
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
    do_addOption --extra-cflags=-fopenmp --extra-libs=-lgomp
fi

_check=(librubberband.a rubberband.pc rubberband/{rubberband-c,RubberBandStretcher}.h)
if { { [[ $ffmpeg != "no" ]] && enabled librubberband; } ||
    ! mpv_disabled rubberband; } && do_pkgConfig "rubberband = 1.8.1" &&
    do_vcs https://github.com/lachs0r/rubberband.git; then
    do_uninstall "${_check[@]}"
    log "distclean" make distclean
    do_make PREFIX="$LOCALDESTDIR" install-static
    do_checkIfExist
    add_to_remove
fi

_check=(zimg{.h,++.hpp} libzimg.{,l}a zimg.pc)
if [[ $ffmpeg != "no" ]] && enabled libzimg &&
    do_vcs "https://github.com/sekrit-twc/zimg.git"; then
    do_uninstall "${_check[@]}"
    do_autoreconf
    do_separate_confmakeinstall
    do_checkIfExist
fi


set_title "compiling audio tools"
echo -e "\n\t${orange}Starting $bits compilation of audio tools${reset}"

if [[ $ffmpeg != "no" || $sox = y ]]; then
    enabled libwavpack && do_pacman_install wavpack
    enabled_any libopencore-amr{wb,nb} && do_pacman_install opencore-amr
    if enabled libtwolame; then
        do_pacman_install twolame
        do_addOption --extra-cflags=-DLIBTWOLAME_STATIC
    fi
    enabled libmp3lame && do_pacman_install lame
fi

_check=(ilbc.h libilbc.{{l,}a,pc})
if [[ $ffmpeg != "no" ]] && enabled libilbc && do_pkgConfig "libilbc = 2.0.3-dev" &&
    do_vcs "https://github.com/TimothyGu/libilbc.git"; then
    do_autoreconf
    do_uninstall "${_check[@]}"
    do_separate_confmakeinstall
    do_checkIfExist
    add_to_remove
fi

enabled libvorbis && do_pacman_install libvorbis
enabled libspeex && do_pacman_install speex
enabled libopus && do_pacman_install opus

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
if [[ $ffmpeg != "no" ]] && enabled libvo-amrwbenc &&
    do_pkgConfig "vo-amrwbenc = 0.1.3"; then
    do_wget_sf -h f63bb92bde0b1583cb3cb344c12922e0 \
        "opencore-amr/vo-amrwbenc/vo-amrwbenc-0.1.3.tar.gz"
    do_uninstall include/vo-amrwbenc "${_check[@]}"
    do_separate_confmakeinstall
    do_checkIfExist
fi

if { [[ $ffmpeg != "no" ]] && enabled libfdk-aac; } || [[ $fdkaac = "y" ]]; then
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
    unset _deps
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
unset _deps

_check=(bin-audio/opusenc.exe)
_deps=("$MINGW_PREFIX"/lib/libopus.a)
if [[ $standalone = y ]] && enabled libopus &&
    do_vcs "https://github.com/xiph/opus-tools.git" opus-tools; then
    _check+=(bin-audio/opus{dec,info}.exe)
    do_uninstall "${_check[@]}"
    do_autogen
    do_separate_confmakeinstall audio
    do_checkIfExist
fi
unset _deps

if [[ $ffmpeg != "no" ]] && enabled libsoxr; then
    _check=(soxr.h libsoxr.a)
    if do_vcs https://notabug.org/RiCON/soxr.git libsoxr; then
        do_uninstall "${_check[@]}"
        do_cmakeinstall -DWITH_LSR_BINDINGS=off -DBUILD_TESTS=off -DWITH_OPENMP=off
        do_checkIfExist
    fi
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
if [[ $ffmpeg != "no" ]] && enabled libgme && do_pkgConfig "libgme = 0.6.1" &&
    do_vcs "https://bitbucket.org/mpyne/game-music-emu.git" libgme; then
    do_uninstall include/gme "${_check[@]}"
    sed -i 's|__declspec(dllexport)||g' gme/blargg_source.h
    do_cmakeinstall -DENABLE_UBSAN=off
    do_checkIfExist
    add_to_remove
fi

_check=(libbs2b.{{l,}a,pc})
if [[ $ffmpeg != "no" ]] && enabled libbs2b && do_pkgConfig "libbs2b = 3.1.0"; then
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
    sed -i 's/ examples tests//g' Makefile.am
    do_autogen
    do_uninstall include/sndfile.hh "${_check[@]}"
    do_separate_confmakeinstall --disable-full-suite
    do_checkIfExist
fi

_check=(bin-audio/sox.exe sox.pc)
_deps=(libsndfile.a "$MINGW_PREFIX"/lib/lib{opus,mp3lame}.a)
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
unset _deps

_check=(libopenmpt.{a,pc})
[[ ! $openmpt_rev ]] &&
    openmpt_rev="$(clean_html_index "https://lib.openmpt.org/files/libopenmpt/src/")" &&
    openmpt_rev="$(get_last_version "$openmpt_rev" libopenmpt "(?<=0\.2\.)(\d+)")"
openmpt_rev="${openmpt_rev:-8043}"
openmpt_url="svn::https://source.openmpt.org/svn/openmpt/trunk/OpenMPT/"
if [[ $ffmpeg != "no" ]] && enabled libopenmpt &&
    do_vcs "${openmpt_url}#revision=$openmpt_rev" openmpt; then
    do_uninstall include/libopenmpt "${_check[@]}"
    extracommands=(CONFIG="mingw64-win${bits%bit}" AR=ar STATIC_LIB=1 EXAMPLES=0 OPENMPT123=0
        TEST=0 OS=)
    log clean make clean "${extracommands[@]}"
    do_makeinstall PREFIX="$LOCALDESTDIR" "${extracommands[@]}"
    sed -i 's/Libs.private.*/& -lrpcrt4 -lstdc++/' "$LOCALDESTDIR/lib/pkgconfig/libopenmpt.pc"
    do_checkIfExist
fi

_check=(libmysofa.a mysofa.h)
if [[ $ffmpeg != "no" ]] && enabled libmysofa &&
    do_vcs "https://github.com/hoene/libmysofa.git#tag=v0.5"; then
    do_uninstall "${_check[@]}"
    do_cmakeinstall -DBUILD_TESTS=no
    do_checkIfExist
fi

_check=(libflite.a flite/flite.h)
if enabled libflite && do_vcs "https://github.com/kubo/flite.git"; then
    do_uninstall libflite_cmu_{grapheme,indic}_{lang,lex}.a \
        libflite_cmu_us_{awb,kal,kal16,rms,slt}.a \
        libflite_{cmulex,usenglish,cmu_time_awb}.a "${_check[@]}" include/flite
    log clean make clean
    do_configure --prefix="$LOCALDESTDIR" --bindir="$LOCALDESTDIR"/bin-audio --disable-shared \
        --with-audio=none
    do_make && do_makeinstall
    do_checkIfExist
fi

set_title "compiling video tools"
echo -e "\n\t${orange}Starting $bits compilation of video tools${reset}"

if [[ $rtmpdump = "y" ]] ||
    { [[ $ffmpeg != "no" ]] && enabled librtmp; }; then
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
    unset _deps
fi

_check=(libvpx.a vpx.pc)
[[ $standalone = y ]] && _check+=(bin-video/vpxenc.exe)
if [[ $vpx = y ]] && do_vcs "https://chromium.googlesource.com/webm/libvpx" vpx; then
    extracommands=()
    [[ -f config.mk ]] && log "distclean" make distclean
    [[ $standalone = y ]] && _check+=(bin-video/vpxdec.exe) ||
        extracommands+=(--disable-{examples,webm-io,libyuv,postproc})
    do_uninstall include/vpx "${_check[@]}"
    create_build_dir
    for _c in vp8 vp9; do
        disabled "encoder=libvpx_${_c}" && extracommands+=("--disable-${_c}-encoder")
        disabled "decoder=libvpx_${_c}" && extracommands+=("--disable-${_c}-decoder")
    done
    [[ $bits = 32bit ]] && arch=x86 || arch=x86_64
    [[ $ffmpeg = "sharedlibs" ]] || extracommands+=(--enable-{vp9-postproc,vp9-highbitdepth})
    log "configure" ../configure --target="${arch}-win${bits%bit}-gcc" --prefix="$LOCALDESTDIR" \
        --disable-{shared,unit-tests,docs,install-bins} \
        "${extracommands[@]}"
    for _ff in *.mk; do
        sed -i 's;HAVE_GNU_STRIP=yes;HAVE_GNU_STRIP=no;' "$_ff"
    done
    do_make
    do_makeinstall
    [[ $standalone = y ]] && do_install vpx{enc,dec}.exe bin-video/
    do_checkIfExist
    unset extracommands _ff _c
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
    [[ $bits = 32bit ]] && arch=x86 || arch=x86_64
    log "configure" ../configure --target="${arch}-win${bits%bit}-gcc" \
        --prefix="$LOCALDESTDIR" \
        --disable-{docs,install-bins} \
        --enable-runtime-cpu-detect \
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
if { [[ $other265 = "y" ]] || { [[ $ffmpeg != "no" ]] && enabled libkvazaar; }; } &&
    do_vcs "https://github.com/ultravideo/kvazaar.git"; then
    do_uninstall kvazaar_version.h "${_check[@]}"
    do_autogen
    [[ $standalone = y || $other265 = y ]] ||
        sed -i "s|bin_PROGRAMS = .*||" src/Makefile.in
    do_separate_confmakeinstall video
    do_checkIfExist
fi

_check=(libSDL2{,_test,main}.a sdl2.pc SDL2/SDL.h)
if { { [[ $ffmpeg != "no" ]] && ! disabled sdl2; } ||
    mpv_enabled sdl2 || [[ $daala = y ]]; } &&
    do_pkgConfig "sdl2 = 2.0.5"; then
    do_wget -h d4055424d556b4a908aa76fad63abd3c \
        "http://libsdl.org/release/SDL2-2.0.5.tar.gz"
    do_uninstall include/SDL2 lib/cmake/SDL2 bin/sdl2-config "${_check[@]}"
    do_patch sdl2-0001-remove-conflicting-xinput-structs.patch
    sed -i 's|__declspec(dllexport)||g' include/{begin_code,SDL_opengl}.h
    do_separate_confmakeinstall
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
        do_pacman_install libjpeg-turbo
    else
        extracommands+=(--disable-player --disable-tools)
    fi
    do_separate_conf video --disable-{unit-tests,doc} "${extracommands[@]}"
    do_make && do_makeinstall
    [[ $standalone = y ]] && do_install examples/{{encoder,player}_example,dump_video}.exe bin-video/
    do_checkIfExist
fi

_check=(libdvdread.{l,}a dvdread.pc)
if { [[ $mplayer = "y" ]] || mpv_enabled_any dvdread dvdnav; } &&
    do_vcs "https://code.videolan.org/videolan/libdvdread.git" dvdread; then
    do_autoreconf
    do_uninstall include/dvdread "${_check[@]}"
    do_separate_confmakeinstall
    do_checkIfExist
    grep -q 'ldl' "$LOCALDESTDIR"/lib/pkgconfig/dvdread.pc ||
        sed -i "/Libs:.*/ a\Libs.private: -ldl -lpsapi" "$LOCALDESTDIR"/lib/pkgconfig/dvdread.pc
fi
[[ -f "$LOCALDESTDIR"/lib/pkgconfig/dvdread.pc ]] &&
    ! grep -q 'psapi' "$LOCALDESTDIR"/lib/pkgconfig/dvdread.pc &&
    sed -ri "s;(Libs.private: .+);\1 -lpsapi;" "$LOCALDESTDIR"/lib/pkgconfig/dvdread.pc

_check=(libdvdnav.{l,}a dvdnav.pc)
_deps=(libdvdread.a)
if { [[ $mplayer = "y" ]] || mpv_enabled dvdnav; } &&
    do_vcs "https://code.videolan.org/videolan/libdvdnav.git" dvdnav; then
    do_autoreconf
    do_uninstall include/dvdnav "${_check[@]}"
    do_separate_confmakeinstall
    do_checkIfExist
fi
unset _deps

_check=(libbluray.{{l,}a,pc})
if { { [[ $ffmpeg != "no" ]] && enabled libbluray; } || ! mpv_disabled libbluray; } &&
    do_vcs "https://git.videolan.org/git/libbluray.git"; then
    [[ -f contrib/libudfread/.git ]] || log git.submodule git submodule update --init
    do_autoreconf
    do_uninstall include/libbluray share/java "${_check[@]}"
    sed -i 's|__declspec(dllexport)||g' jni/win32/jni_md.h
    extracommands=()
    JAVA_HOME="$(get_java_home)"
    OLD_PATH="$PATH"
    if [[ -n "$JAVA_HOME" ]]; then
        if [[ ! -f /opt/apache-ant/bin/ant ]]; then
            do_wget -r -c -h 0a4530999b71f92bf17ae823ed3b0b2d \
                "https://www.apache.org/dist/ant/binaries/apache-ant-1.10.1-bin.zip" \
                apache-ant.zip
            mv apache-ant/apache-ant* /opt/apache-ant
        fi
        PATH="/opt/apache-ant/bin:$JAVA_HOME/bin:$PATH"
        log ant-diagnostics ant -diagnostics
        export JDK_HOME=""
        export JAVA_HOME
    else
        extracommands+=(--disable-bdjava-jar)
    fi
    do_separate_confmakeinstall --disable-{examples,doxygen-doc} \
        --without-{libxml2,fontconfig,freetype} "${extracommands[@]}"
    do_checkIfExist
    PATH="$OLD_PATH"
    unset extracommands JDK_HOME JAVA_HOME OLD_PATH
fi

_check=(libxavs.a xavs.{h,pc})
if [[ $ffmpeg != "no" ]] && enabled libxavs && do_pkgConfig "xavs = 0.1." "0.1" &&
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
        do_cmakeinstall Project/CMake
        do_checkIfExist
    fi

    _check=(libmediainfo.{a,pc})
    _deps=(lib{zen,curl}.a)
    if do_vcs "https://github.com/MediaArea/MediaInfoLib" libmediainfo; then
        do_uninstall include/MediaInfo{,DLL} bin-global/libmediainfo-config "${_check[@]}" libmediainfo.la
        do_cmakeinstall Project/CMake -DBUILD_ZLIB=off -DBUILD_ZENLIB=off
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
            --enable-staticlibs
        do_makeinstall
        do_checkIfExist
    fi
fi

_check=(libvidstab.a vidstab.pc)
if [[ $ffmpeg != "no" ]] && enabled libvidstab && do_pkgConfig "vidstab = 1.10" &&
    do_vcs "https://github.com/georgmartius/vid.stab.git" vidstab; then
    do_uninstall include/vid.stab "${_check[@]}"
    do_cmakeinstall
    do_checkIfExist
    add_to_remove
fi

_check=(libzvbi.{h,{l,}a})
if [[ $ffmpeg != "no" ]] && enabled libzvbi &&
    do_pkgConfig "zvbi-0.2 = 0.2.35"; then
    do_wget_sf -h 95e53eb208c65ba6667fd4341455fa27 \
        "zapping/zvbi/0.2.35/zvbi-0.2.35.tar.bz2"
    do_uninstall "${_check[@]}" zvbi-0.2.pc
    do_patch "zvbi-win32.patch"
    do_patch "zvbi-ioctl.patch"
    CFLAGS+=" -DPTW32_STATIC_LIB" do_separate_conf --disable-{dvb,bktr,nls,proxy} \
        --without-doxygen LIBS="$LIBS -lpng"
    cd_safe src
    do_makeinstall
    log pkgconfig make -C .. install-pkgconfigDATA
    do_checkIfExist
fi


if [[ $ffmpeg != "no" ]] && enabled frei0r; then
    _check=(libdl.a dlfcn.h)
    if do_vcs https://github.com/dlfcn-win32/dlfcn-win32.git; then
        do_uninstall "${_check[@]}"
        [[ -f config.mak ]] && log clean make distclean
        sed -i 's|__declspec(dllexport)||g' dlfcn.h
        do_configure --prefix="$LOCALDESTDIR" --disable-shared
        do_make && do_makeinstall
        do_checkIfExist
    fi

    _check=(frei0r.{h,pc})
    if do_vcs https://github.com/dyne/frei0r.git; then
        sed -i 's/find_package (Cairo)//' "CMakeLists.txt"
        do_uninstall lib/frei0r-1 "${_check[@]}"
        do_cmakeinstall
        do_checkIfExist
    fi
fi

if [[ $ffmpeg != "no" ]] && enabled decklink; then
    _check=(DeckLinkAPI.h
           DeckLinkAPIVersion.h
           DeckLinkAPI_i.c)
    _hash=(e197cd6b828a008972da3dc86a53508c0d33ccff1437a702745fdd2b54f560bd
           01e09d87f41e3e0a1c15fdfa4750ebd82455787d54e3f8c4e58b7e85eee809a6
           c201e18620de4440bd79aab880ea6bf6fa71676b1c9172e1f71c8b10f1564268)
    if files_exist -v "${_check[@]}" &&
        {
            count=0
            while [[ x"${_check[$count]}" != x"" ]]; do
                check_hash "$(file_installed "${_check[$count]}")" "${_hash[$count]}" || break
                let count+=1
            done
            test x"${_check[$count]}" = x""
        }; then
        do_print_status "DeckLinkAPI 10.9.5" "$green" "Up-to-date"
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
if [[ $ffmpeg != "no" ]] && enabled libmfx &&
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

if [[ $x264 != no ]]; then
    _check=(x264{,_config}.h libx264.a x264.pc)
    [[ $standalone = y ]] && _check+=(bin-video/x264.exe)
    if do_vcs "https://git.videolan.org/git/x264.git" ||
        [[ $x264 != high && "$(get_api_version x264_config.h BIT_DEPTH)" = "10" ]] ||
        [[ $x264  = high && "$(get_api_version x264_config.h BIT_DEPTH)" = "8" ]]; then
        extracommands=(--host="$MINGW_CHOST" --prefix="$LOCALDESTDIR" --enable-static
            --bindir="$LOCALDESTDIR/bin-video")
        old_PKG_CONFIG_PATH="$PKG_CONFIG_PATH"
        PKG_CONFIG_PATH="$LOCALDESTDIR/opt/lightffmpeg/lib/pkgconfig:$MINGW_PREFIX/lib/pkgconfig"
        if [[ $standalone = y && $x264 =~ (full|fullv) ]]; then
            _check=("$LOCALDESTDIR"/opt/lightffmpeg/lib/pkgconfig/libav{codec,format}.pc)
            do_vcs "https://git.ffmpeg.org/ffmpeg.git"
            do_uninstall "$LOCALDESTDIR"/opt/lightffmpeg
            [[ -f "config.mak" ]] && log "distclean" make distclean
            create_build_dir light
            if [[ $x264 = fullv ]]; then
                non_video_codecs=(
                    $(sed -n '/audio codecs/,/subtitles/p' ../libavcodec/allcodecs.c | \
                      grep -P 'REGISTER_(ENCDEC|DECODER)' | grep -oP "[a-z0-9_]+(?=\);)")
                )
                LDFLAGS+=" -L$MINGW_PREFIX/lib" \
                    log configure ../configure "${FFMPEG_BASE_OPTS[@]}" \
                    --prefix="$LOCALDESTDIR/opt/lightffmpeg" \
                    --disable-{programs,devices,filters,encoders,muxers,debug,sdl2,network,protocols,doc} \
                    --disable-decoder="$(IFS=, ; echo "${non_video_codecs[*]}")" --enable-gpl \
                    --disable-bsf=aac_adtstoasc,text2movsub,noise,dca_core,mov2textsub,mp3_header_decompress
            else
                LDFLAGS+=" -L$MINGW_PREFIX/lib" \
                    log configure ../configure "${FFMPEG_BASE_OPTS[@]}" \
                    --prefix="$LOCALDESTDIR/opt/lightffmpeg" \
                    --disable-{programs,devices,filters,encoders,muxers,debug,sdl2,doc} --enable-gpl
            fi
            do_makeinstall
            files_exist "${_check[@]}" && touch "build_successful${bits}_light"

            _check=("$LOCALDESTDIR"/opt/lightffmpeg/lib/pkgconfig/ffms2.pc bin-video/ffmsindex.exe)
            if do_vcs https://github.com/FFMS/ffms2.git; then
                do_uninstall "${_check[@]}"
                sed -i 's/Libs.private.*/& -lstdc++/;s/Cflags.*/& -DFFMS_STATIC/' ffms2.pc.in
                do_separate_confmakeinstall video --prefix="$LOCALDESTDIR/opt/lightffmpeg"
                do_checkIfExist
            fi
            cd_safe "$LOCALBUILDDIR"/x264-git
        else
            extracommands+=(--disable-lavf --disable-ffms)
        fi

        if [[ $standalone = y ]]; then
            _check=("$LOCALDESTDIR/opt/lightffmpeg/lib/pkgconfig/liblsmash.pc")
            if do_vcs "https://github.com/l-smash/l-smash.git" liblsmash; then
                [[ -f "config.mak" ]] && log "distclean" make distclean
                do_uninstall "${_check[@]}"
                create_build_dir
                log configure ../configure --prefix="$LOCALDESTDIR/opt/lightffmpeg"
                do_make install-lib
                do_checkIfExist
            fi
            cd_safe "$LOCALBUILDDIR"/x264-git
        else
            extracommands+=(--disable-cli)
        fi

        _check=(x264{,_config}.h x264.pc)
        [[ $standalone = y ]] && _check+=(bin-video/x264.exe)
        [[ -f "config.h" ]] && log "distclean" make distclean
        do_uninstall "${_check[@]}" libx264{,.dll}.a \
            bin-video/libx264-"${x264_build}"{,-10bits}.dll

        x264_build="$(grep X264_BUILD x264.h | awk '{ print $3 }' | head -1)"
        if [[ $x264 = shared ]]; then
            extracommands+=(--enable-shared)
            _check+=(libx264{,.dll}.a bin-video/libx264-"${x264_build}"-10bits.dll
                bin-video/libx264-"${x264_build}".dll)
        else
            extracommands+=(--disable-shared)
            _check+=(libx264.a)
        fi

        if [[ $standalone = y && $x264 =~ (yes|full|fullv) ]]; then
            do_print_progress "Building 10-bit x264"
            _check+=(bin-video/x264-10bit.exe)
            create_build_dir
            CFLAGS="${CFLAGS// -O2 / }" log configure ../configure --bit-depth=10 "${extracommands[@]}"
            do_make
            do_install x264.exe bin-video/x264-10bit.exe
            cd_safe ..
            do_print_progress "Building 8-bit x264"
        elif [[ $x264 = shared ]]; then
            do_print_progress "Building 10-bit x264 shared lib"
            create_build_dir
            CFLAGS="${CFLAGS// -O2 / }" log configure ../configure --bit-depth=10 --disable-cli "${extracommands[@]}"
            do_make
            do_install libx264-"${x264_build}".dll bin-video/libx264-"${x264_build}"-10bits.dll
            cd_safe ..
            do_print_progress "Building 8-bit x264 shared lib"
        else
            if [[ $x264 = high ]]; then
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
        PKG_CONFIG_PATH="$old_PKG_CONFIG_PATH"
        unset extracommands x264_build old_PKG_CONFIG_PATH
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
    implicitlibs="$(printf '"%s" ' -lmingwex -lmingwthrd -lmingw32 -lmoldname -lmsvcrt -ladvapi32 -lshell32 -luser32 -lkernel32)"
    sed -ri "s|(\"-lc\").*(\"-lpthread\")|\1 ${implicitlibs} \2|" source/CMakeLists.txt
    sed -i 's|__declspec(dllexport)||g' source/x265-extras.h

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
        -DENABLE_HDR10_PLUS=ON $xpsupport "$@"
        log "ninja" ninja -j "${cpuCount:-1}"
    }
    [[ $standalone = y ]] && cli="-DENABLE_CLI=ON"

    if [[ $x265 =~ (o12|s|d|y) ]]; then
        cd_safe "$build_root/12bit"
        if [[ $x265 = s ]]; then
            do_x265_cmake "shared 12-bit lib" $assembly -DENABLE_SHARED=ON -DMAIN12=ON
            do_install libx265.dll bin-video/libx265_main12.dll
            _check+=(bin-video/libx265_main12.dll)
        elif [[ $x265 = o12 ]]; then
            do_x265_cmake "12-bit lib/bin" $assembly $cli -DMAIN12=ON
        else
            do_x265_cmake "12-bit lib for multilib" $assembly -DEXPORT_C_API=OFF -DMAIN12=ON
            cp libx265.a ../8bit/libx265_main12.a
        fi
    fi

    if [[ $x265 =~ (o10|s|d|y) ]]; then
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

    if [[ $x265 =~ (o8|s|d|y) ]]; then
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
pc_exists x265 && sed -i 's|-lmingwex||g' "$(file_installed x265.pc)"

if [[ $ffmpeg != "no" ]]; then
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
        grep -q "Requires.private: zlib" "$MINGW_PREFIX"/lib/pkgconfig/libssh.pc ||
            sed -i "/Libs:/ i\Requires.private: zlib libssl" "$MINGW_PREFIX"/lib/pkgconfig/libssh.pc
    fi
    enabled libtheora && do_pacman_install libtheora
    if enabled libcdio; then
        do_pacman_install libcdio-paranoia
        grep -ZlER -- "-R/mingw\S+" "$MINGW_PREFIX"/lib/pkgconfig/* | xargs -r -0 sed -ri 's;-R/mingw\S+;;g'
    fi
    enabled libcaca && do_addOption --extra-cflags=-DCACA_STATIC && do_pacman_install libcaca
    enabled libmodplug && do_addOption --extra-cflags=-DMODPLUG_STATIC && do_pacman_install libmodplug
    enabled libopenjpeg && do_pacman_install openjpeg2
    enabled libopenh264 && do_pacman_install openh264
    enabled chromaprint && do_addOption --extra-cflags=-DCHROMAPRINT_NODLL --extra-libs=-lstdc++ &&
        do_pacman_remove fftw && do_pacman_install chromaprint
    if enabled libzmq; then
        do_pacman_install zeromq
        grep -q ws2_32 "$MINGW_PREFIX"/lib/pkgconfig/libzmq.pc ||
            sed -i 's/-lsodium/& -lws2_32 -liphlpapi/' "$MINGW_PREFIX"/lib/pkgconfig/libzmq.pc
        do_addOption --extra-cflags=-DZMQ_STATIC
    fi
    enabled frei0r && do_addOption --extra-libs=-lpsapi

    do_hide_all_sharedlibs

    _check=(libavutil.pc)
    disabled_any avfilter ffmpeg || _check+=(bin-video/ffmpeg.exe)
    if [[ $ffmpeg =~ "shared" ]]; then
        _check+=(libavutil.dll.a)
    else
        _check+=(libavutil.a)
        [[ $ffmpeg = "both" ]] && _check+=(bin-video/ffmpegSHARED)
    fi
    [[ $ffmpegUpdate = y ]] && enabled_any lib{ass,x264,x265,vpx} &&
        _deps=(lib{ass,x264,x265,vpx}.a)
    if do_vcs "https://git.ffmpeg.org/ffmpeg.git"; then

        do_changeFFmpegConfig "$license"
        [[ -f ffmpeg_extra.sh ]] && source ffmpeg_extra.sh

        _patches="$(git rev-list origin/master.. --count)"
        [[ $_patches -gt 0 ]] &&
            do_addOption "--extra-version=g$(git rev-parse --short origin/master)+$_patches"

        _uninstall=(include/libav{codec,device,filter,format,util,resample}
            include/lib{sw{scale,resample},postproc}
            libav{codec,device,filter,format,util,resample}.{dll.a,a,pc}
            lib{sw{scale,resample},postproc}.{dll.a,a,pc}
            "$LOCALDESTDIR"/lib/av{codec,device,filter,format,util}-*.def
            "$LOCALDESTDIR"/lib/{sw{scale,resample},postproc}-*.def
            "$LOCALDESTDIR"/bin-video/av{codec,device,filter,format,util}-*.dll
            "$LOCALDESTDIR"/bin-video/{sw{scale,resample},postproc}-*.dll
            "$LOCALDESTDIR"/bin-video/av{codec,device,filter,format,util}.lib
            "$LOCALDESTDIR"/bin-video/{sw{scale,resample},postproc}.lib
            )
        _check=()
        sedflags="prefix|bindir|extra-version|pkg-config-flags"

        if [[ $ffmpeg = "both" ]]; then
            _check+=(bin-video/ffmpegSHARED/lib/libavutil.dll.a)
            FFMPEG_OPTS_SHARED+=(--prefix="$LOCALDESTDIR/bin-video/ffmpegSHARED")
        elif [[ $ffmpeg =~ "shared" ]]; then
            _check+=(libavutil.{dll.a,pc})
            FFMPEG_OPTS_SHARED+=(--prefix="$LOCALDESTDIR"
                --bindir="$LOCALDESTDIR/bin-video"
                --shlibdir="$LOCALDESTDIR/bin-video")
        fi
        enabled_any debug "debug=gdb" &&
            ffmpeg_cflags="$(echo $CFLAGS | sed -r 's/ (-O[1-3]|-mtune=\S+)//g')"

        # remove redundant -L and -l flags from extralibs
        do_patch ffmpeg-0001-configure-fix-failures-with-long-command-lines.patch

        # shared
        if [[ $ffmpeg != "static" ]] && [[ ! -f build_successful${bits}_shared ]]; then
            do_print_progress "Compiling ${bold}shared${reset} FFmpeg"
            do_uninstall bin-video/ffmpegSHARED "${_uninstall[@]}"
            [[ -f config.mak ]] && log "distclean" make distclean
            create_build_dir shared
            CFLAGS="${ffmpeg_cflags:-$CFLAGS}" \
            LDFLAGS+=" -L$LOCALDESTDIR/lib -L$MINGW_PREFIX/lib" \
                log configure ../configure \
                --disable-static --enable-shared "${FFMPEG_OPTS_SHARED[@]}"
            # cosmetics
            sed -ri "s/ ?--($sedflags)=(\S+[^\" ]|'[^']+')//g" config.h
            do_make && do_makeinstall
            cd_safe ..
            files_exist "${_check[@]}" && touch "build_successful${bits}_shared"
        fi

        # static
        if [[ ! $ffmpeg =~ "shared" ]] && _check=(libavutil.{a,pc}); then
            do_print_progress "Compiling ${bold}static${reset} FFmpeg"
            [[ -f config.mak ]] && log "distclean" make distclean
            if ! disabled_any programs avcodec avformat; then
                if ! disabled swresample; then
                    disabled_any avfilter ffmpeg || _check+=(bin-video/ffmpeg.exe)
                    disabled_any sdl2 ffplay || _check+=(bin-video/ffplay.exe)
                fi
                disabled ffprobe || _check+=(bin-video/ffprobe.exe)
            fi
            do_uninstall bin-video/ff{mpeg,play,probe}.exe{,.debug} "${_uninstall[@]}"
            create_build_dir static
            CFLAGS="${ffmpeg_cflags:-$CFLAGS}" \
            LDFLAGS+=" -L$LOCALDESTDIR/lib -L$MINGW_PREFIX/lib" \
                log configure ../configure --prefix="$LOCALDESTDIR" \
                --bindir="$LOCALDESTDIR/bin-video" "${FFMPEG_OPTS[@]}"
            # cosmetics
            sed -ri "s/ ?--($sedflags)=(\S+[^\" ]|'[^']+')//g" config.h
            do_make && do_makeinstall
            enabled_any debug "debug=gdb" &&
                create_debug_link "$LOCALDESTDIR"/bin-video/ff{mpeg,probe,play}.exe
            cd_safe ..
        fi
        do_checkIfExist
        [[ -f "$LOCALDESTDIR"/bin-video/ffmpeg.exe ]] &&
            create_winpty_exe ffmpeg "$LOCALDESTDIR"/bin-video/
        unset ffmpeg_cflags
    fi
fi

_check=(bin-video/m{player,encoder}.exe)
if [[ $mplayer = "y" ]] &&
    do_vcs "svn::svn://svn.mplayerhq.hu/mplayer/trunk" mplayer; then
    [[ $license != "nonfree" || $faac = n ]] && faac_opts=(--disable-faac --disable-faac-lavc)
    do_uninstall "${_check[@]}"
    [[ -f config.mak ]] && log "distclean" make distclean
    if [[ ! -d ffmpeg ]]; then
        if [[ "$ffmpeg" != "no" ]] &&
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
    --extra-libs='-llzma -liconv -lws2_32 -lpthread -lwinpthread -lpng -lwinmm' \
    --extra-ldflags='-Wl,--allow-multiple-definition' --enable-{static,runtime-cpudetection} \
    --disable-{gif,cddb} "${faac_opts[@]}" --with-dvdread-config="$PKG_CONFIG dvdread" \
    --with-freetype-config="$PKG_CONFIG freetype2" --with-dvdnav-config="$PKG_CONFIG dvdnav" &&
        do_makeinstall && do_checkIfExist
    unset _notrequired faac_opts
fi

if [[ $xpcomp = "n" && $mpv != "n" ]] && pc_exists libavcodec libavformat libswscale libavfilter; then
    if ! mpv_disabled lua && opt_exists MPV_OPTS "--lua=5.1"; then
        do_pacman_install lua51
    elif ! mpv_disabled lua; then
        do_pacman_install luajit-git
    fi

    do_pacman_remove uchardet-git
    ! mpv_disabled uchardet && do_pacman_install uchardet
    mpv_enabled libarchive && do_pacman_install libarchive
    ! mpv_disabled lcms2 && do_pacman_install lcms2

    do_pacman_remove angleproject-git
    _check=(EGL/egl.h bin-video/lib{GLESv2,EGL}.dll)
    if ! mpv_disabled egl-angle &&
        do_wget -z -r "https://i.fsbn.eu/pub/angle/angle-latest-win${bits%bit}.7z" &&
        test_newer installed ./libGLESv2.dll bin-video/libGLESv2.dll; then
            do_uninstall include/{EGL,GLES{2,3},GLSLANG,KHR,platform} angle_gl.h \
                lib{GLESv2,EGL}.a "${_check[@]}"
            do_install lib{GLESv2,EGL}.dll bin-video/
            cp -rf include/* "$LOCALDESTDIR/include/"
            if ! [[ -f "$LOCALDESTDIR/bin-video/d3dcompiler_47.dll" ]]; then
                do_wget -c -q "https://i.fsbn.eu/pub/angle/d3dcompiler_47-win${bits%bit}.7z"
                do_install d3dcompiler_47-win${bits%bit}/d3dcompiler_47.dll bin-video/
            fi
            stripping=n do_checkIfExist
    elif ! mpv_disabled egl-angle &&
        ! test_newer installed ./libGLESv2.dll bin-video/libGLESv2.dll; then
        do_print_status "└ $(get_first_subdir)" "$green" "Files up-to-date"
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
            do_vcs "https://github.com/vapoursynth/vapoursynth.git"
            if git show-ref -q "R${vsversion}"; then
                git reset -q --hard "R${vsversion}"
            else
                git reset -q --hard origin/master
            fi

            do_install include/*.h include/vapoursynth/

            create_build_dir
            for _file in vapoursynth vsscript; do
                gendef - "$vsprefix/${_file}.dll" 2>/dev/null |
                    sed -r -e 's|^_||' -e 's|@[1-9]+$||' > "${_file}.def"
                dlltool -l "lib${_file}.a" -d "${_file}.def" \
                    $([[ $bits = 32bit ]] && echo "-U") 2>/dev/null
                [[ -f lib${_file}.a ]] && do_install "lib${_file}.a"
            done

            for _file in vapoursynth{,-script}.pc; do
                sed -e "s;@prefix@;$LOCALDESTDIR;" \
                    -e 's;@exec_prefix@;${prefix};' \
                    -e 's;@libdir@;${prefix}/lib;' \
                    -e 's;@includedir@;${prefix}/include;' \
                    -e "s;@VERSION@;$vsversion;" \
                    -e '/Libs.private/ d' \
                    -e '/Requires.private/ d' \
                    -e 's;lvapoursynth-script;lvsscript;' \
                    "../pc/$_file.in" > "$_file"
                    do_install "$_file"
            done

            do_checkIfExist
            add_to_remove
        elif [[ -z "$vsprefix" ]]; then
            mpv_disable vapoursynth
        fi
        unset vsprefix vsversion _file
    elif ! mpv_disabled vapoursynth; then
        mpv_disable vapoursynth
    fi

    _check=(mujs.h libmujs.a)
    if ! mpv_disabled javascript &&
        do_vcs http://git.ghostscript.com/user/tor/mujs.git; then
        do_uninstall bin-global/mujs.exe "$_{check[@]}"
        log clean make clean
        do_make install-static prefix="$LOCALDESTDIR" bindir="$LOCALDESTDIR/bin-global"
        do_checkIfExist
    fi

    _check=(bin-video/mpv.{exe,com})
    _deps=(lib{ass,avcodec,vapoursynth}.a "$MINGW_PREFIX"/lib/libuchardet.a)
    if do_vcs "https://github.com/mpv-player/mpv.git"; then
        hide_conflicting_libs
        create_ab_pkgconfig

        [[ ! -f waf ]] && /usr/bin/python bootstrap.py >/dev/null 2>&1
        if [[ -d build ]]; then
            /usr/bin/python waf distclean >/dev/null 2>&1
            do_uninstall bin-video/mpv{.exe,-1.dll}.debug "${_check[@]}"
        fi

        mpv_ldflags=("-L$LOCALDESTDIR/lib" "-L$MINGW_PREFIX/lib")
        if [[ $bits = "64bit" ]]; then
            mpv_ldflags+=("-Wl,--image-base,0x140000000,--high-entropy-va")
            if enabled_any libnpp cuda-sdk && [[ -n "$CUDA_PATH" ]]; then
                mpv_cflags=("-I$(cygpath -sm "$CUDA_PATH")/include")
                mpv_ldflags+=("-L$(cygpath -sm "$CUDA_PATH")/lib/x64")
            fi
        fi
        enabled libssh && mpv_ldflags+=("-Wl,--allow-multiple-definition")
        if ! mpv_disabled manpage-build || mpv_enabled html-build; then
            do_pacman_install python3-docutils
        fi
        do_pacman_remove python3-rst2pdf
        mpv_enabled pdf-build && do_pacman_install python2-rst2pdf

        [[ -f mpv_extra.sh ]] && source mpv_extra.sh

        files_exist libavutil.a && MPV_OPTS+=(--enable-static-build)
        CFLAGS+=" ${mpv_cflags[*]}" LDFLAGS+=" ${mpv_ldflags[*]}" \
            RST2MAN="${MINGW_PREFIX}/bin/rst2man3" \
            RST2HTML="${MINGW_PREFIX}/bin/rst2html3" \
            RST2PDF="${MINGW_PREFIX}/bin/rst2pdf2" \
            PKG_CONFIG="$LOCALDESTDIR/bin/ab-pkg-config" \
            log configure /usr/bin/python waf configure \
            "--prefix=$LOCALDESTDIR" "--bindir=$LOCALDESTDIR/bin-video" \
            --disable-vapoursynth-lazy "${MPV_OPTS[@]}"

        # Windows(?) has a lower argument limit than *nix so
        # we replace tons of repeated -L flags with just two
        replace="LIBPATH_lib\1 = ['${LOCALDESTDIR}/lib','${MINGW_PREFIX}/lib']"
        sed -r -i "s:LIBPATH_lib(ass|av(|device|filter)) = .*:$replace:g" ./build/c4che/_cache.py

        log build /usr/bin/python waf -j "${cpuCount:-1}"
        log install /usr/bin/python waf -j1 install ||
            log install /usr/bin/python waf -j1 install

        unset mpv_ldflags replace
        hide_conflicting_libs -R
        files_exist share/man/man1/mpv.1 && dos2unix -q "$LOCALDESTDIR"/share/man/man1/mpv.1
        ! mpv_disabled debug-build &&
            create_debug_link "$LOCALDESTDIR"/bin-video/mpv{.exe,-1.dll}
        create_winpty_exe mpv "$LOCALDESTDIR"/bin-video/ "export _started_from_console=yes"
        do_checkIfExist
    fi
fi

if [[ $bmx = "y" ]]; then
    do_pacman_install uriparser

    _check=(bin-video/MXFDump.exe libMXF-1.0.{{,l}a,pc})
    if do_vcs https://notabug.org/RiCON/libmxf.git libMXF-1.0; then
        do_autogen
        do_uninstall include/libMXF-1.0 "${_check[@]}"
        do_separate_confmakeinstall video --disable-examples
        do_checkIfExist
    fi

    _check=(libMXF++-1.0.{{,l}a,pc})
    _deps=(libMXF-1.0.a)
    if do_vcs https://notabug.org/RiCON/libmxfpp.git libMXF++-1.0; then
        do_autogen
        do_uninstall include/libMXF++-1.0 "${_check[@]}"
        do_separate_confmakeinstall video --disable-examples
        do_checkIfExist
    fi

    _check=(bin-video/{bmxtranswrap,{h264,mov,vc2}dump,mxf2raw,raw2bmx}.exe)
    _deps=("$MINGW_PREFIX"/lib/liburiparser.a lib{MXF{,++}-1.0,curl}.a)
    if do_vcs https://notabug.org/RiCON/bmx.git; then
        do_autogen
        do_uninstall libbmx-0.1.{{,l}a,pc} bin-video/bmxparse.exe \
            include/bmx-0.1 "${_check[@]}"
        do_separate_confmakeinstall video
        do_checkIfExist
    fi
fi

if [[ $cyanrip != no ]]; then
    do_pacman_install libxml2
    do_pacman_install libcdio-paranoia

    _check=(neon/ne_utils.h libneon.a neon.pc)
    if do_pkgConfig "neon = 0.30.2"; then
        do_wget -h db0bd8cdec329b48f53a6f00199c92d5ba40b0f015b153718d1b15d3d967fbca \
            "http://download.openpkg.org/components/cache/neon/neon-0.30.2.tar.gz"
        do_uninstall include/neon "${_check[@]}"
        extracommands=()
        do_separate_confmakeinstall --disable-{nls,debug,webdav} "${extracommands[@]}"
        unset extracommands
        do_checkIfExist
    fi

    _check=(discid/discid.h libdiscid.{a,pc})
    if do_vcs "https://github.com/wiiaboo/libdiscid.git"; then
        do_uninstall "${_check[@]}"
        do_cmakeinstall
        do_checkIfExist
    fi

    _deps=(libneon.a "$MINGW_PREFIX"/lib/libxml2.a)
    _check=(musicbrainz5/mb5_c.h libmusicbrainz5{,cc}.{a,pc})
    if do_vcs "https://github.com/wiiaboo/libmusicbrainz.git"; then
        do_uninstall "${_check[@]}" include/musicbrainz5
        do_cmake -G "MSYS Makefiles"
        do_makeinstall
        do_checkIfExist
    fi

    _deps=(libdiscid.a libmusicbrainz5.a)
    _check=(bin-audio/cyanrip.exe)
    if do_vcs "https://github.com/atomnuker/cyanrip.git"; then
        create_ab_pkgconfig
        old_PKG_CONFIG_PATH="$PKG_CONFIG_PATH"
        if [[ $cyanrip = small ]]; then
            _check=("$LOCALDESTDIR"/opt/cyanffmpeg/lib/pkgconfig/libav{codec,format}.pc)
            if [[ ! -f "$LOCALBUILDDIR/ffmpeg-git/build_successful${bits}_cyan" ]] &&
                do_vcs "https://git.ffmpeg.org/ffmpeg.git"; then
                do_uninstall "$LOCALDESTDIR"/opt/cyanffmpeg
                [[ -f "config.mak" ]] && log "distclean" make distclean
                create_build_dir cyan
                log configure ../configure "${FFMPEG_BASE_OPTS[@]}" \
                    --prefix="$LOCALDESTDIR/opt/cyanffmpeg" \
                    --disable-{programs,devices,filters,decoders,hwaccels,encoders,muxers} \
                    --disable-{debug,protocols,demuxers,parsers,doc,swscale,postproc,network} \
                    --disable-{avdevice,avfilter,dxva2,d3d11va,cuda,cuvid,nvenc,schannel,sdl2} \
                    --enable-protocol=file \
                    --enable-encoder=flac,tta,aac,wavpack,alac \
                    --enable-muxer=flac,tta,ipod,wv,mp3,opus,ogg \
                    --enable-parser=png,mjpeg --enable-decoder=mjpeg,png \
                    --enable-demuxer=image2,png_pipe,bmp_pipe \
                    $(enabled libmp3lame && echo '--enable-libmp3lame --enable-encoder=libmp3lame') \
                    $(enabled libvorbis && echo '--enable-libvorbis --enable-encoder=libvorbis' ||
                        echo '--enable-encoder=vorbis') \
                    $(enabled libopus && echo '--enable-libopus --enable-encoder=libopus' ||
                        echo '--enable-encoder=opus')
                do_makeinstall
                files_exist "${_check[@]}" && touch "build_successful${bits}_cyan"
            fi
            PKG_CONFIG_PATH="$LOCALDESTDIR/opt/cyanffmpeg/lib/pkgconfig:$PKG_CONFIG_PATH"
        fi

        cd_safe "$LOCALBUILDDIR"/cyanrip-git
        _check=(bin-audio/cyanrip.exe)
        [[ ! -f waf ]] && /usr/bin/python bootstrap.py >/dev/null 2>&1
        if [[ $cyanrip = small ]]; then
            hide_conflicting_libs "$LOCALDESTDIR/opt/cyanffmpeg"
        else
            hide_conflicting_libs
        fi
        [[ -d build ]] && /usr/bin/python waf distclean >/dev/null 2>&1
        CFLAGS+=" -DLIBXML_STATIC" PKGCONFIG="$LOCALDESTDIR/bin/ab-pkg-config" \
            log configure /usr/bin/python waf configure --no-debug \
            --static-build --bindir="$LOCALDESTDIR"/bin-audio
        log build /usr/bin/python waf -j "${cpuCount:-1}"
        log install /usr/bin/python waf -j1 install ||
            log install /usr/bin/python waf -j1 install
        if [[ $cyanrip = small ]]; then
            hide_conflicting_libs -R "$LOCALDESTDIR/opt/cyanffmpeg"
        else
            hide_conflicting_libs -R
        fi
        do_checkIfExist
        PKG_CONFIG_PATH="$old_PKG_CONFIG_PATH"
    fi
fi

_check=(bin-video/ffmbc.exe)
if [[ $ffmbc = y ]] && do_vcs https://github.com/bcoudurier/FFmbc.git; then
    _notrequired=yes
    create_build_dir
    log configure ../configure --target-os=mingw32 --enable-gpl \
        --disable-{dxva2,ffprobe} --extra-cflags=-DNO_DSHOW_STRSAFE
    do_make && do_install ffmbc.exe bin-video/ && do_checkIfExist
    unset _notrequired
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
