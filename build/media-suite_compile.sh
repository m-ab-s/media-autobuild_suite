#!/bin/bash
# shellcheck disable=SC2034,SC1090,SC1117,SC1091,SC2119
shopt -s extglob

FFMPEG_BASE_OPTS=("--pkg-config-flags=--static")
if [[ x"$LOCALBUILDDIR" = "x" ]]; then
    printf '%s\n' \
        "Something went wrong." \
        "MSYSTEM: $MSYSTEM" \
        "pwd: $(cygpath -w "$(pwd)")" \
        "fstab: " \
        "$(cat /etc/fstab)" \
        "Create a new issue and upload all logs you can find, especially compile.log"
    read -r -p "Enter to continue" ret
    exit 1
fi
printf '\nBuild start: %(%F %T %z)T\n' -1 >> "$LOCALBUILDDIR/newchangelog"

printf '#!/bin/bash\nbash %s %s\n' "$LOCALBUILDDIR/media-suite_compile.sh" "$*" > "$LOCALBUILDDIR/last_run"

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
--logging=* ) logging="${1#*=}"; shift ;;
--bmx=* ) bmx="${1#*=}"; shift ;;
--aom=* ) aom="${1#*=}"; shift ;;
--faac=* ) faac="${1#*=}"; shift ;;
--ffmbc=* ) ffmbc="${1#*=}"; shift ;;
--curl=* ) curl="${1#*=}"; shift ;;
--cyanrip=* ) cyanrip="${1#*=}"; shift ;;
--redshift=* ) redshift="${1#*=}"; shift ;;
--ripgrep=* ) ripgrep="${1#*=}"; shift ;;
--rav1e=* ) rav1e="${1#*=}"; shift ;;
--dav1d=* ) dav1d="${1#*=}"; shift ;;
--vvc=* ) vvc="${1#*=}"; shift ;;
--jq=* ) jq="${1#*=}"; shift ;;
--dssim=* ) dssim="${1#*=}"; shift ;;
--avs2=* ) avs2="${1#*=}"; shift ;;
--timeStamp=* ) timeStamp="${1#*=}"; shift ;;
--noMintty=* ) noMintty="${1#*=}"; [ -f "$LOCALBUILDDIR/fail.var" ] && rm "$LOCALBUILDDIR/fail.var"; (declare -p | grep -vE "BASH|LINES|COLUMNS|CommonProgramFiles") > "$LOCALBUILDDIR/old.var"; shift ;;
--svthevc=* ) svthevc="${1#*=}"; shift ;;
    -- ) shift; break ;;
    -* ) echo "Error, unknown option: '$1'."; exit 1 ;;
    * ) break ;;
  esac
done

# shellcheck source=media-suite_helper.sh
source "$LOCALBUILDDIR"/media-suite_helper.sh

[[ -f "$LOCALBUILDDIR/no_logs" ||  $logging = n ]] &&
    do_simple_print -p "${orange}Warning: We will not accept any issues lacking any form of logs or logs.zip!${reset}"

buildProcess() {
set_title
do_simple_print -p '\n\t'"${orange}Starting $bits compilation of all tools${reset}"
[[ -f "$HOME"/custom_build_options ]] &&
    echo "Imported custom build options (unsupported)" &&
    source "$HOME"/custom_build_options

cd_safe "$LOCALBUILDDIR"

do_getFFmpegConfig "$license"
do_getMpvConfig

# in case the root was moved, this fixes windows abspaths
mkdir -p "$LOCALDESTDIR/lib/pkgconfig"
# pkgconfig keys to find the wrong abspaths from
local _keys="(prefix|exec_prefix|libdir|includedir)"
# current abspath root
local _root
_root="$(cygpath -m /trunk)${LOCALDESTDIR}"
# find .pc files with Windows abspaths
grep -ElZR "${_keys}=[^/$].*" "$LOCALDESTDIR"/lib/pkgconfig | \
    # find those with a different abspath than the current
    xargs -0r grep -LZ "${_root}" | \
    # replace with current abspath
    xargs -0r sed -ri "s;${_keys}=.*${LOCALDESTDIR};\1=${_root};g"
unset _keys _root

_clean_old_builds=(j{config,error,morecfg,peglib}.h
    lib{jpeg,nettle,ogg,vorbis{,enc,file},gnurx,regex}.{,l}a
    lib{opencore-amr{nb,wb},twolame,theora{,enc,dec},caca,magic,luajit-5.1,uchardet}.{l,}a
    libSDL{,main}.{l,}a libopen{jpwl,mj2,jp2}.{a,pc} lib/lua
    include/{nettle,ogg,opencore-amr{nb,wb},theora,cdio,SDL,openjpeg-2.{1,2},luajit-2.0,uchardet,wels}
    regex.h magic.h
    {nettle,ogg,vorbis{,enc,file},vo-aacenc,sdl,luajit,uchardet}.pc
    {opencore-amr{nb,wb},twolame,theora{,enc,dec},caca,dcadec,libEGL,openh264}.pc
    libcdio_{cdda,paranoia}.{{l,}a,pc}
    share/aclocal/{ogg,vorbis}.m4
    twolame.h bin-audio/{twolame,cd-paranoia}.exe
    bin-global/{{file,uchardet}.exe,sdl-config,luajit{,-2.0.4.exe}}
    libebur128.a ebur128.h
    libopenh264.a
    liburiparser.{{,l}a,pc}
    libchromaprint.{a,pc} chromaprint.h
    bin-global/libgcrypt-config libgcrypt.a gcrypt.h
    lib/libgcrypt.def bin-global/{dumpsexp,hmac256,mpicalc}.exe
    crossc.{h,pc} libcrossc.a
)

do_uninstall q all "${_clean_old_builds[@]}"
unset _clean_old_builds

# In case a build was interrupted before reversing hide_conflicting_libs
[[ -d "$LOCALDESTDIR/opt/cyanffmpeg" ]] &&
    hide_conflicting_libs -R "$LOCALDESTDIR/opt/cyanffmpeg"
hide_conflicting_libs -R
do_hide_all_sharedlibs
create_ab_pkgconfig
create_cmake_toolchain

set_title "compiling global tools"
do_simple_print -p '\n\t'"${orange}Starting $bits compilation of global tools${reset}"

if [[ $packing = y ]] &&
    ! [[ -e /opt/bin/upx.exe && "$(/opt/bin/upx -V | head -1)" = "upx 3.95" ]] &&
    do_wget -h f94ff30b175d125d1c238458716f5808aee222547a813918b44d0f67035c0054 \
        "https://github.com/upx/upx/releases/download/v3.95/upx-3.95-win32.zip"; then
    do_install upx.exe /opt/bin/upx.exe
fi

_check=("$RUSTUP_HOME"/bin/rustup.exe)
if [[ $ripgrep = y || $rav1e = y || $dssim = y ]]; then
    if ! files_exist "$RUSTUP_HOME"/bin/rustup.exe; then
        mkdir -p "$LOCALBUILDDIR/rustinstall"
        cd_safe "$LOCALBUILDDIR/rustinstall"
        log download_rustup curl "https://sh.rustup.rs" -sSo rustup.sh
        log install_rust ./rustup.sh -v -y --no-modify-path \
            "--default-host=${MSYSTEM_CARCH}-pc-windows-gnu" \
            --default-toolchain=stable
        do_checkIfExist
        hash -r
        add_to_remove
        cd_safe "$LOCALBUILDDIR"
    fi
    if ! [[ $(rustup toolchain list) =~ stable-$CARCH-pc-windows-gnu ]]; then
        # install current target arch toolchain
        log install_toolchain "$RUSTUP_HOME/bin/rustup.exe" toolchain \
            install "stable-$CARCH-pc-windows-gnu"
    fi
    log rustup_update "$RUSTUP_HOME/bin/rustup.exe" update
    log set_default_toolchain "$RUSTUP_HOME/bin/rustup.exe" default \
        "stable-$CARCH-pc-windows-gnu"
fi

_check=(bin-global/rg.exe)
if [[ $ripgrep = y ]] &&
    do_vcs "https://github.com/BurntSushi/ripgrep.git"; then
    do_uninstall "${_check[@]}"
    do_rust --features 'pcre2'
    do_install "target/$CARCH-pc-windows-gnu/release/rg.exe" bin-global/
    do_checkIfExist
fi

_check=(libonig.a oniguruma.pc)
if [[ "$jq" = y ]] &&
    do_vcs "https://github.com/kkos/oniguruma.git"; then
    do_pacman_remove oniguruma
    do_uninstall include/onig{uruma,gnu,posix}.h "${_check[@]}"
    do_cmakeinstall
    do_checkIfExist
fi

_deps=(oniguruma.pc)
_check=(bin-global/jq.exe)
if [[ "$jq" = y ]] &&
    do_vcs "https://github.com/stedolan/jq.git"; then
    do_uninstall "${_check[@]}"
    do_autoreconf
    CFLAGS+=' -D_POSIX_C_SOURCE' YFLAGS='--warnings=no-yacc' \
        do_separate_confmakeinstall global --enable-all-static --enable-pthread-tls --disable-docs
    do_checkIfExist
fi

_check=(bin-global/dssim.exe)
if [[ $dssim = y ]] &&
    do_vcs "https://github.com/kornelski/dssim.git"; then
    do_uninstall "${_check[@]}"
    do_rust
    do_install "target/$CARCH-pc-windows-gnu/release/dssim.exe" bin-global/
    do_checkIfExist
fi

if [[ "$mplayer" = "y" ]] || ! mpv_disabled libass ||
    { [[ $ffmpeg != "no" ]] && enabled_any libass libfreetype {lib,}fontconfig libfribidi; }; then
    do_pacman_remove freetype fontconfig harfbuzz fribidi

    _check=(libfreetype.{l,}a freetype2.pc)
    [[ $ffmpeg = "sharedlibs" ]] && _check+=(bin-video/libfreetype-6.dll libfreetype.dll.a)
    if do_vcs "https://git.savannah.gnu.org/git/freetype/freetype2.git#tag=LATEST"; then
        do_autogen
        do_uninstall include/freetype2 bin-global/freetype-config \
            bin{,-video}/libfreetype-6.dll libfreetype.dll.a "${_check[@]}"
        # shellcheck disable=SC2191
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
        do_vcs "https://gitlab.freedesktop.org/fontconfig/fontconfig.git#tag=2.13.1"; then
        do_uninstall include/fontconfig "${_check[@]}"
        sed -i 's| test$||' Makefile.am
        sed -i 's|Libs.private:|& -lintl|' fontconfig.pc.in
        _ss=(printf fprintf snprintf vfprintf)
        for _s in "${_ss[@]}"; do
            grep -Rl "$_s" --include="*.[c]" | xargs sed -i "/__mingw_/! s/\b$_s/__mingw_&/g"
        done
        unset _s _ss
        do_autogen --noconf
        extracommands=(--disable-docs --enable-iconv "--with-libiconv-prefix=$MINGW_PREFIX" \
            "--with-libiconv-lib=$MINGW_PREFIX/lib" "--with-libiconv-includes=$MINGW_PREFIX/include" \
            "LDFLAGS=$LDFLAGS -L${LOCALDESTDIR}/lib -L${MINGW_PREFIX}/lib")
        if enabled libxml2; then
            do_pacman_install libxml2
            sed -i 's|Cflags:|& -DLIBXML_STATIC|' fontconfig.pc.in
            extracommands+=(--enable-libxml2)
        fi
        CFLAGS+=" $(enabled libxml2 && echo -DLIBXML_STATIC)"
        do_separate_confmakeinstall global "${extracommands[@]}"
        [[ $standalone = y ]] || rm -f "$LOCALDESTDIR"/bin-global/fc-*.exe
        do_checkIfExist
    fi

    _deps=(libfreetype.a)
    _check=(libharfbuzz.{,l}a harfbuzz.pc)
    if [[ $ffmpeg != "sharedlibs" ]] && do_vcs "https://github.com/behdad/harfbuzz.git#tag=LATEST"; then
        do_pacman_install ragel
        NOCONFIGURE=y do_autogen
        do_uninstall include/harfbuzz "${_check[@]}"
        do_separate_confmakeinstall --with-{icu,glib,gobject,cairo,fontconfig,uniscribe}=no
        # directwrite shaper doesn't work with mingw headers, maybe too old
        do_checkIfExist
    fi
    unset _deps

    _check=(libfribidi.a fribidi.pc)
    [[ $standalone = y ]] && _check+=(bin-video/fribidi.exe)
    [[ $ffmpeg = "sharedlibs" ]] && _check+=(bin-video/libfribidi-0.dll libfribidi.dll.a)
    if do_vcs "https://github.com/fribidi/fribidi.git#tag=LATEST"; then
        extracommands=("--bindir=bin-video" "-Ddocs=false" "-Dglib=false")
        [[ $standalone = n ]] && sed -i "/subdir('bin')/d" meson.build
        sed -i "/subdir('test')/d" meson.build
        if [[ $ffmpeg = "sharedlibs" ]]; then
            create_build_dir shared
            log meson meson .. --default-library=shared \
                --prefix="$LOCALDESTDIR" "${extracommands[@]}"
            log build ninja
            cpuCount=1 log install ninja install
            cd_safe ..
        fi
        do_mesoninstall "${extracommands[@]}"
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
    if [[ $ffmpeg != "sharedlibs" && $ffmpeg != "shared" ]]; then
        _libs=(lib{freetype,fribidi,ass}.dll.a
            libav{codec,device,filter,format,util,resample}.dll.a
            lib{sw{scale,resample},postproc}.dll.a)
        for _lib in "${_libs[@]}"; do
            rm -f "$LOCALDESTDIR/lib/$_lib"
        done
        unset _lib _libs
    fi
fi

[[ $ffmpeg != "no" ]] && enabled gcrypt && do_pacman_install libgcrypt

if [[ $curl = y ]]; then
    enabled libtls && curl=libressl
    enabled openssl && curl=openssl
    enabled gnutls && curl=gnutls
    enabled mbedtls && curl=mbedtls
    [[ $curl = y ]] && curl=schannel
fi
_check=(libgnutls.{,l}a gnutls.pc)
if enabled_any gnutls librtmp || [[ $rtmpdump = y ]] || [[ $curl = gnutls ]] &&
    ! files_exist "${_check[@]}" &&
    do_wget -h aa81944e5635de981171772857e72be231a7e0f559ae0292d2737de475383e83 \
    "https://www.gnupg.org/ftp/gcrypt/gnutls/v3.6/gnutls-3.6.8.tar.xz"; then
        do_pacman_install nettle
        do_uninstall include/gnutls "${_check[@]}"
        grep_or_sed crypt32 lib/gnutls.pc.in 's/Libs.private.*/& -lcrypt32/'
        do_separate_confmakeinstall \
            --disable-{cxx,doc,tools,tests,nls,rpath,libdane,guile,gcc-warnings} \
            --without-{p11-kit,idn,tpm} --enable-local-libopts \
            --with-included-unistring --disable-code-coverage \
            LDFLAGS="$LDFLAGS -L${LOCALDESTDIR}/lib -L${MINGW_PREFIX}/lib"
        do_checkIfExist
fi

if { [[ $ffmpeg != "no" ]] && enabled openssl; } || [[ $curl = openssl ]]; then
    do_pacman_install openssl
fi
hide_libressl -R
if { [[ $ffmpeg != "no" ]] && enabled libtls; } || [[ $curl = libressl ]]; then
    _check=(tls.h lib{crypto,ssl,tls}.{pc,{,l}a} openssl.pc)
    [[ $standalone = y ]] && _check+=("bin-global/openssl.exe")
    if do_vcs "https://github.com/libressl-portable/portable.git#tag=LATEST" libressl; then
        do_uninstall etc/ssl include/openssl "${_check[@]}"
        _sed="man"
        [[ $standalone = y ]] || _sed="apps tests $_sed"
        sed -ri "s;(^SUBDIRS .*) $_sed;\1;" Makefile.am
        do_autogen
        do_separate_confmakeinstall global
        do_checkIfExist
        unset _sed
    fi
fi

{ enabled mbedtls || [[ $curl = mbedtls ]]; } && do_pacman_install mbedtls

_check=(curl/curl.h libcurl.{{,l}a,pc})
_deps=()
[[ $curl = libressl ]] && _deps+=(libssl.a)
[[ $curl = openssl ]] && _deps+=("$MINGW_PREFIX/lib/libssl.a")
[[ $curl = gnutls ]] && _deps+=(libgnutls.a)
[[ $curl = mbedtls ]] && _deps+=("$MINGW_PREFIX/lib/libmbedtls.a")
[[ $standalone = y || $curl != n ]] && _check+=(bin-global/curl.exe)
if [[ $mediainfo = y || $bmx = y || $curl != n ]] &&
    do_vcs "https://github.com/curl/curl.git#tag=LATEST"; then
    do_pacman_install nghttp2 brotli

    # fix retarded google naming schemes for brotli
    ! /usr/bin/grep -q -- "-static" "$MINGW_PREFIX"/lib/pkgconfig/libbrotlidec.pc &&
        sed -i 's;-lbrotli.*;&-static;' \
            "$MINGW_PREFIX"/lib/pkgconfig/libbrotli{enc,dec,common}.pc
    ! /usr/bin/grep -q -- brotlidec-static configure.ac &&
        sed -i 's;CHECK_LIB(brotlidec;&-static;' configure.ac

    do_uninstall include/curl bin-global/curl-config "${_check[@]}"
    [[ $standalone = y || $curl != n ]] ||
        sed -ri "s;(^SUBDIRS = lib) src (include) scripts;\1 \2;" Makefile.in
    extra_opts=()
    if [[ $curl =~ (libre|open)ssl ]]; then
        extra_opts+=(--with-{ssl,nghttp2} --without-{gnutls,mbedtls})
    elif [[ $curl =~ mbedtls ]]; then
        extra_opts+=(--with-{mbedtls,nghttp2} --without-ssl)
    elif [[ $curl = gnutls ]]; then
        extra_opts+=(--with-gnutls --without-{ssl,nghttp2,mbedtls})
    else
        extra_opts+=(--with-{winssl,winidn,nghttp2} --without-{ssl,gnutls,mbedtls})
    fi
    grep_or_sed NGHTTP2_STATICLIB libcurl.pc.in 's;Cflags.*;& -DNGHTTP2_STATICLIB;'
    grep_or_sed NGHTTP2_STATICLIB curl-config.in 's;-DCURL_STATICLIB ;&-DNGHTTP2_STATICLIB ;'
    [[ ! -f configure || configure.ac -nt configure ]] && log autogen ./buildconf
    [[ $curl = openssl ]] && hide_libressl
    hide_conflicting_libs
    CPPFLAGS+=" -DNGHTTP2_STATICLIB" \
        do_separate_confmakeinstall global "${extra_opts[@]}" \
        --without-{libssh2,random,ca-bundle,ca-path,librtmp,libidn2} \
        --with-brotli \
        --enable-sspi --disable-{debug,manual}
    hide_conflicting_libs -R
    [[ $curl = openssl ]] && hide_libressl -R
    if [[ $curl != schannel ]]; then
        _notrequired=yes
        cd_safe "build-$bits"
        PATH=/usr/bin log ca-bundle make ca-bundle
        unset _notrequired
        [[ -f lib/ca-bundle.crt ]] &&
            cp -f lib/ca-bundle.crt "$LOCALDESTDIR"/bin-global/curl-ca-bundle.crt
        cd_safe ..
    fi
    do_checkIfExist
fi
unset _deps

_check=(libtiff{.a,-4.pc})
if enabled_any libwebp libtesseract &&
    do_vcs "https://gitlab.com/libtiff/libtiff.git"; then
    do_pacman_install libjpeg-turbo xz zlib zstd
    do_uninstall "${_check[@]}"
    grep_or_sed 'Requires.private' libtiff-4.pc.in \
        '/Libs:/ a\Requires.private: libjpeg liblzma zlib libzstd'
    do_cmakeinstall global -Dwebp=OFF -DUNIX=OFF
    do_checkIfExist
fi

_check=(libwebp{,mux}.{{,l}a,pc})
[[ $standalone = y ]] && _check+=(libwebp{demux,decoder}.{{,l}a,pc}
    bin-global/{{c,d}webp,webpmux,img2webp}.exe)
if [[ $ffmpeg != "no" || $standalone = y ]] && enabled libwebp &&
    do_vcs "https://chromium.googlesource.com/webm/libwebp"; then
    if [[ $standalone = y ]]; then
        extracommands=(--enable-{experimental,libwebp{demux,decoder,extras}}
            "LIBS=$($PKG_CONFIG --libs libpng libtiff-4)")
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
opencldll="$syspath/OpenCL.dll"
if files_exist "$LOCALDESTDIR/bin-video/OpenCL.dll"; then
    opencldll="$LOCALDESTDIR/bin-video/OpenCL.dll"
fi
if [[ $ffmpeg != "no" ]] && enabled opencl && [[ -f "$opencldll" ]]; then
    do_simple_print "${orange}FFmpeg and related apps will depend on OpenCL.dll${reset}"
    do_pacman_remove opencl-headers
    _check=(CL/cl.h)
    if do_vcs "https://github.com/KhronosGroup/OpenCL-Headers.git"; then
        do_uninstall include/CL
        do_install CL/*.h include/CL/
        do_checkIfExist
    fi
    _check=(libOpenCL.a)
    if test_newer installed "$opencldll" "${_check[@]}"; then
        cd_safe "$LOCALBUILDDIR"
        [[ -d opencl ]] && rm -rf opencl
        mkdir -p opencl && cd_safe opencl
        create_build_dir
        gendef "$opencldll" >/dev/null 2>&1
        [[ -f OpenCL.def ]] && dlltool -y libOpenCL.a -d OpenCL.def -k -A
        [[ -f libOpenCL.a ]] && do_install libOpenCL.a
        do_checkIfExist
    fi
else
    do_removeOption --enable-opencl
fi
unset syspath opencldll

if [[ $ffmpeg != "no" || $standalone = y ]] && enabled libtesseract; then
    do_pacman_remove tesseract-ocr
    _check=(liblept.{,l}a lept.pc)
    if do_vcs "https://github.com/DanBloomberg/leptonica.git#tag=LATEST"; then
        do_uninstall include/leptonica "${_check[@]}"
        [[ -f configure ]] || do_autogen
        do_separate_confmakeinstall --disable-programs --without-{lib{openjpeg,webp},giflib}
        do_checkIfExist
    fi

    _check=(libtesseract.{,l}a tesseract.pc)
    if do_vcs "https://github.com/tesseract-ocr/tesseract.git"; then
        do_pacman_install docbook-xsl libarchive
        do_autogen
        _check+=(bin-global/tesseract.exe)
        do_uninstall include/tesseract "${_check[@]}"
        sed -i -e 's|Libs.private.*|& -lstdc++|' \
               -e 's|Requires.private.*|& libarchive iconv|' tesseract.pc.in
        do_separate_confmakeinstall global --disable-{graphics,tessdata-prefix} \
            LIBLEPT_HEADERSDIR="$LOCALDESTDIR/include" \
            LIBS="$($PKG_CONFIG --libs iconv lept)" --datadir="$LOCALDESTDIR/bin-global"
        if [[ ! -f $LOCALDESTDIR/bin-global/tessdata/eng.traineddata ]]; then
            do_pacman_install tesseract-data-eng
            mkdir -p "$LOCALDESTDIR"/bin-global/tessdata
            do_install "$MINGW_PREFIX/share/tessdata/eng.traineddata" bin-global/tessdata/
            printf '%s\n' \
                "You can get more language data here:" \
                "https://github.com/tesseract-ocr/tessdata" \
                "Just download <lang you want>.traineddata and copy it to this directory." \
                > "$LOCALDESTDIR"/bin-global/tessdata/need_more_languages.txt
        fi
        do_checkIfExist
    fi
    do_addOption --extra-cflags=-fopenmp --extra-libs=-lgomp
fi

_check=(librubberband.a rubberband.pc rubberband/{rubberband-c,RubberBandStretcher}.h)
if { { [[ $ffmpeg != "no" ]] && enabled librubberband; } ||
    ! mpv_disabled rubberband; } && do_pkgConfig "rubberband = 1.8.1" &&
    do_vcs "https://github.com/lachs0r/rubberband.git"; then
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
do_simple_print -p '\n\t'"${orange}Starting $bits compilation of audio tools${reset}"

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

_check=(bin-audio/speex{enc,dec}.exe)
if [[ $standalone = y ]] && enabled libspeex && ! { files_exist "${_check[@]}" &&
    grep -q '1.2.0' "$LOCALDESTDIR/bin-audio/speexenc.exe"; } &&
    do_vcs "https://github.com/xiph/speex.git"; then
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
if [[ $flac = y ]] && do_vcs "https://github.com/xiph/flac.git"; then
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
    do_pkgConfig "vo-amrwbenc = 0.1.3" &&
    do_wget_sf -h f63bb92bde0b1583cb3cb344c12922e0 \
        "opencore-amr/vo-amrwbenc/vo-amrwbenc-0.1.3.tar.gz"; then
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
    fi
    unset _deps
fi

[[ $faac = y ]] && do_pacman_install faac
_check=(bin-audio/faac{,gui}.exe)
if [[ $standalone = y && $faac = y ]] && ! files_exist "${_check[@]}" &&
    do_wget -h e23a05f13f9695a81f250c30bd30e5bd636a0f6891a9ea9093ce4bfbf758217b \
        "https://github.com/knik0/faac/archive/1_29_9_2.tar.gz" "faac-1_29_9_2.tar.gz"; then
    do_uninstall libfaac.a faac{,cfg}.h "${_check[@]}"
    # autoconf: frontend compilation optional
    # blockswitch: add missing stdint include
    # frontend: fix out-of-root build
    do_patch https://0x0.st/zMuQ.txt
    log bootstrap ./bootstrap
    extracommands=()
    [[ $standalone = n ]] && extracommands+=(--disable-frontend)
    do_separate_confmakeinstall audio "${extracommands[@]}"
    do_checkIfExist
fi

_check=(bin-audio/oggenc.exe)
_deps=("$MINGW_PREFIX"/lib/libvorbis.a)
if [[ $standalone = y ]] && enabled libvorbis && ! files_exist "${_check[@]}" &&
    do_vcs "https://github.com/xiph/vorbis-tools.git"; then
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

_check=(libopus.{,l}a opus.pc opus/opus.h)
if enabled libopus && do_vcs "https://github.com/xiph/opus.git"; then
    do_pacman_remove opus
    do_uninstall include/opus "${_check[@]}"
    do_autogen
    do_separate_confmakeinstall --disable-{stack-protector,doc,extra-programs} \
            --enable-ambisonics
    do_checkIfExist
fi

if [[ $standalone = y ]] && enabled libopus; then
    do_pacman_install openssl libogg
    hide_libressl
    _check=(opus/opusfile.h libopus{file,url}.{,l}a opus{file,url}.pc)
    _deps=(opus.pc "$MINGW_PREFIX"/lib/pkgconfig/{libssl,ogg}.pc)
    if do_vcs "https://github.com/xiph/opusfile.git"; then
        do_uninstall "${_check[@]}"
        do_patch "https://0x0.st/sgwa.txt"
        do_autogen
        do_separate_confmakeinstall --disable-{examples,doc}
        do_checkIfExist
    fi

    _check=(opus/opusenc.h libopusenc.{pc,{,l}a})
    _deps=(opus.pc)
    if do_vcs "https://github.com/xiph/libopusenc.git"; then
        do_uninstall "${_check[@]}"
        do_autogen
        do_separate_confmakeinstall --disable-{examples,doc}
        do_checkIfExist
    fi

    _check=(bin-audio/opusenc.exe)
    _deps=(opusfile.pc libopusenc.pc)
    if do_vcs "https://github.com/xiph/opus-tools.git"; then
        _check+=(bin-audio/opus{dec,info}.exe)
        do_uninstall "${_check[@]}"
        do_autogen
        do_separate_confmakeinstall audio
        do_checkIfExist
    fi
    hide_libressl -R
    unset _deps
fi

if [[ $ffmpeg != "no" ]] && enabled libsoxr; then
    _check=(soxr.h libsoxr.a)
    if do_vcs "https://gitlab.com/media-autobuild_suite-dependencies/libsoxr.git"; then
        do_uninstall "${_check[@]}"
        do_cmakeinstall -DWITH_LSR_BINDINGS=off -DBUILD_TESTS=off -DWITH_OPENMP=off
        do_checkIfExist
    fi
fi

_check=(libcodec2.a codec2.pc codec2/codec2.h)
if [[ $ffmpeg != "no" ]] && enabled libcodec2 && do_pkgConfig "codec2 = 0.8"; then
    [[ $standalone = y ]] && _check+=(bin-audio/c2{enc,dec,sim}.exe)
    if do_vcs "svn::svn://svn.code.sf.net/p/freetel/code/codec2/branches/0.8" codec2-0.8; then
        do_uninstall all include/codec2 "${_check[@]}"
        sed -i 's|if(WIN32)|if(FALSE)|g' CMakeLists.txt
        if enabled libspeex; then
            # rename same-named symbols copied from speex
            grep -ERl "\b(lsp|lpc)_to_(lpc|lsp)" --include="*.[ch]" | \
                xargs -r sed -ri "s;((lsp|lpc)_to_(lpc|lsp));c2_\1;g"
        fi
        do_cmakeinstall -D{UNITTEST,INSTALL_EXAMPLES}=off \
            -DCMAKE_INSTALL_BINDIR="$(pwd)/build-$bits/_bin"
        if [[ $standalone = y ]]; then
            do_install _bin/c2{enc,dec,sim}.exe bin-audio/
        fi
        do_checkIfExist
    fi
fi

if [[ $standalone = y ]] && enabled libmp3lame; then
    _check=(bin-audio/lame.exe)
    if files_exist "${_check[@]}" &&
        grep -q "3.100" "$LOCALDESTDIR/bin-audio/lame.exe"; then
        do_print_status "lame 3.100" "$green" "Up-to-date"
    elif do_wget_sf \
            -h ddfe36cab873794038ae2c1210557ad34857a4b6bdc515785d1da9e175b1da1e \
            "lame/lame/3.100/lame-3.100.tar.gz"; then
        do_uninstall include/lame libmp3lame.{l,}a "${_check[@]}"
        _mingw_patches="https://raw.githubusercontent.com/Alexpux/MINGW-packages/master"
        do_patch "$_mingw_patches/mingw-w64-lame/0002-07-field-width-fix.all.patch"
        do_patch "$_mingw_patches/mingw-w64-lame/0005-no-gtk.all.patch"
        do_patch "$_mingw_patches/mingw-w64-lame/0006-dont-use-outdated-symbol-list.patch"
        do_patch "$_mingw_patches/mingw-w64-lame/0007-revert-posix-code.patch"
        do_patch "$_mingw_patches/mingw-w64-lame/0008-skip-termcap.patch"
        do_autoreconf
        do_separate_conf --enable-nasm
        do_make
        do_install frontend/lame.exe bin-audio/
        do_checkIfExist
        unset _mingw_patches
    fi
fi

_check=(libgme.{a,pc})
if [[ $ffmpeg != "no" ]] && enabled libgme && do_pkgConfig "libgme = 0.6.2" &&
    do_wget -h 5046cb471d422dbe948b5f5dd4e5552aaef52a0899c4b2688e5a68a556af7342 \
        "https://bitbucket.org/mpyne/game-music-emu/downloads/game-music-emu-0.6.2.tar.xz"; then
    do_uninstall include/gme "${_check[@]}"
    sed -i 's|__declspec(dllexport)||g' gme/blargg_source.h
    do_cmakeinstall
    do_checkIfExist
fi

_check=(libbs2b.{{l,}a,pc})
if [[ $ffmpeg != "no" ]] && enabled libbs2b && do_pkgConfig "libbs2b = 3.1.0" &&
    do_wget_sf -h c1486531d9e23cf34a1892ec8d8bfc06 "bs2b/libbs2b/3.1.0/libbs2b-3.1.0.tar.bz2"; then
    do_uninstall include/bs2b "${_check[@]}"
    # sndfile check is disabled since we don't compile binaries anyway
    /usr/bin/grep -q sndfile configure && sed -i '20119,20133d' configure
    sed -i "s|bin_PROGRAMS = .*||" src/Makefile.in
    do_separate_confmakeinstall
    do_checkIfExist
fi

_check=(libsndfile.a sndfile.{h,pc})
if [[ $sox = y ]] && do_vcs "https://github.com/erikd/libsndfile.git" sndfile; then
    do_uninstall include/sndfile.hh "${_check[@]}"
    do_cmakeinstall -DBUILD_EXAMPLES=off -DBUILD_TESTING=off -DBUILD_PROGRAMS=OFF
    do_checkIfExist
fi

_check=(bin-audio/sox.exe sox.pc)
_deps=(libsndfile.a opus.pc "$MINGW_PREFIX"/lib/libmp3lame.a)
if [[ $sox = y ]] && do_pkgConfig "sox = 14.4.2" &&
    do_wget_sf -h ba804bb1ce5c71dd484a102a5b27d0dd "sox/sox/14.4.2/sox-14.4.2.tar.bz2"; then
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
if [[ $ffmpeg != "no" ]] && enabled libopenmpt &&
    do_vcs "https://github.com/OpenMPT/openmpt.git#tag=libopenmpt-*"; then
    do_uninstall include/libopenmpt "${_check[@]}"
    [[ -d bin ]] || mkdir bin
    extracommands=("CONFIG=mingw64-win${bits%bit}" "AR=ar" "STATIC_LIB=1" "EXAMPLES=0" "OPENMPT123=0"
        "TEST=0" "OS=")
    log clean make clean "${extracommands[@]}"
    do_makeinstall PREFIX="$LOCALDESTDIR" "${extracommands[@]}"
    sed -i 's/Libs.private.*/& -lrpcrt4 -lstdc++/' "$LOCALDESTDIR/lib/pkgconfig/libopenmpt.pc"
    do_checkIfExist
fi

_check=(libmysofa.a mysofa.h)
if [[ $ffmpeg != "no" ]] && enabled libmysofa &&
    do_vcs "https://github.com/hoene/libmysofa.git"; then
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

_check=(shine/layer3.h libshine.{,l}a shine.pc)
[[ $standalone = y ]] && _check+=(bin-audio/shineenc.exe)
if enabled libshine && do_pkgConfig "shine = 3.1.1" &&
    do_wget -h 58e61e70128cf73f88635db495bfc17f0dde3ce9c9ac070d505a0cd75b93d384 \
        "https://github.com/toots/shine/releases/download/3.1.1/shine-3.1.1.tar.gz"; then
    do_uninstall "${_check[@]}"
    [[ $standalone = n ]] && sed -i '/bin_PROGRAMS/,+4d' Makefile.am
    # fix out-of-root build
    # shellcheck disable=SC2016
    sed -ri -e 's;(libshine.sym)$;$(srcdir)/\1;' \
        -e '/libshine_la_HEADERS/{s;(src/lib);$(srcdir)/\1;}' \
        -e '/shineenc_CFLAGS/{s;(src/lib);$(srcdir)/\1;}' Makefile.am
    rm configure
    do_autoreconf
    do_separate_confmakeinstall audio
    do_checkIfExist
fi

_check=(openal.pc libopenal.a)
if { { [[ $ffmpeg != "no" ]] &&
    enabled openal; } || mpv_enabled openal; } &&
    do_vcs "https://github.com/kcat/openal-soft.git"; then
    do_uninstall "${_check[@]}"
    _mingw_patches="https://raw.githubusercontent.com/msys2/MINGW-packages/master/mingw-w64-openal"
    do_patch "$_mingw_patches/0003-openal-not-32.mingw.patch"
    do_patch "$_mingw_patches/0004-disable-OSS-windows.patch"
    do_cmakeinstall -DLIBTYPE=STATIC -DALSOFT_UTILS=OFF -DALSOFT_EXAMPLES=OFF
    sed -i 's/Libs.private.*/& -lwinmm -latomic -lole32 -lstdc++/' "$LOCALDESTDIR/lib/pkgconfig/openal.pc"
    do_checkIfExist
    unset _mingw_patches
fi

set_title "compiling video tools"
do_simple_print -p '\n\t'"${orange}Starting $bits compilation of video tools${reset}"

_deps=(gnutls.pc)
_check=(librtmp.{a,pc})
[[ $rtmpdump = y || $standalone = y ]] && _check+=(bin-video/rtmpdump.exe)
if { [[ $rtmpdump = "y" ]] ||
    { [[ $ffmpeg != "no" ]] && enabled librtmp; }; } &&
    do_vcs "https://gitlab.com/media-autobuild_suite-dependencies/rtmpdump.git" librtmp; then
    [[ $rtmpdump = y || $standalone = y ]] && _check+=(bin-video/rtmp{suck,srv,gw}.exe)
    do_uninstall include/librtmp "${_check[@]}"
    [[ -f "librtmp/librtmp.a" ]] && log "clean" make clean
    _rtmp_pkgver() {
        printf '%s-%s-%s_%s-%s-static' \
            "$(/usr/bin/grep -oP "(?<=^VERSION=).+" Makefile)" \
            "$(git log -1 --format=format:%cd-g%h --date=format:%Y%m%d)" \
            "GnuTLS" \
            "$($PKG_CONFIG --modversion gnutls)" \
            "$CARCH"
    }
    do_makeinstall XCFLAGS="$CFLAGS -I$MINGW_PREFIX/include" XLDFLAGS="$LDFLAGS" SHARED= \
        SYS=mingw prefix="$LOCALDESTDIR" bindir="$LOCALDESTDIR"/bin-video \
        sbindir="$LOCALDESTDIR"/bin-video mandir="$LOCALDESTDIR"/share/man \
        CRYPTO=GNUTLS LIB_GNUTLS="$($PKG_CONFIG --libs gnutls) -lz" \
        VERSION="$(_rtmp_pkgver)"
    do_checkIfExist
    unset _rtmp_pkgver
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
    [[ $bits = 32bit ]] && arch=x86 || arch=x86_64
    [[ $ffmpeg = "sharedlibs" ]] || extracommands+=(--enable-{vp9-postproc,vp9-highbitdepth})
    get_external_opts extracommands
    log "configure" ../configure --target="${arch}-win${bits%bit}-gcc" --prefix="$LOCALDESTDIR" \
        --disable-{shared,unit-tests,docs,install-bins,avx512} \
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

[[ $aom = y || $standalone = y ]] && _aom_bins=y
_check=(libaom.a aom.pc)
[[ -n $_aom_bins ]] && _check+=(bin-video/aomenc.exe)
if { [[ $aom = y ]] || { [[ $ffmpeg != "no" ]] && enabled libaom; }; } &&
    do_vcs "https://aomedia.googlesource.com/aom"; then
    extracommands=()
    if [[ -n $_aom_bins ]]; then
        _check+=(bin-video/aomdec.exe)
        # fix google's shit
        sed -ri 's;_PREFIX.+CMAKE_INSTALL_BINDIR;_FULL_BINDIR;' \
            build/cmake/aom_install.cmake
    else
        extracommands+=("-DENABLE_EXAMPLES=off")
    fi
    do_uninstall include/aom "${_check[@]}"
    get_external_opts extracommands
    do_cmakeinstall video -DENABLE_{DOCS,TOOLS,TESTS}=off -DENABLE_NASM=on \
        -DENABLE_TEST{S,DATA}=OFF -DCONFIG_LOWBITDEPTH=1 \
        "${extracommands[@]}"
    do_checkIfExist
    unset extracommands
fi
unset _aom_bins

_check=(dav1d/dav1d.h dav1d.pc libdav1d.a)
[[ $standalone = y ]] && _check+=(bin-video/dav1d.exe)
if { [[ $dav1d = y ]] || { [[ $ffmpeg != "no" ]] && enabled libdav1d; }; } &&
    do_vcs "https://code.videolan.org/videolan/dav1d.git"; then
    do_uninstall include/dav1d "${_check[@]}"
    extracommands=()
    sed -i 's/sdl2_dependency.found()/false/' tools/meson.build
    [[ $standalone = y ]] || extracommands=("-Denable_tools=false")
    do_mesoninstall video -Denable_tests=false "${extracommands[@]}"
    do_checkIfExist
fi

_check=()
{ [[ $rav1e = y ]] ||
    { enabled librav1e && [[ $standalone = y ]]; }; } &&
    _check+=(bin-video/rav1e.exe)
enabled librav1e && _check+=(librav1e.a rav1e.pc rav1e/rav1e.h)
if { [[ $rav1e = y ]] || enabled librav1e; } &&
    do_vcs "https://github.com/xiph/rav1e.git"; then
    log submodule git submodule update --init
    do_uninstall "${_check[@]}" include/rav1e

    # standalone binary
    if [[ $rav1e = y || $standalone = y ]]; then
        do_rust
        do_install "target/$CARCH-pc-windows-gnu/release/rav1e.exe" bin-video/
    fi

    # C lib
    if enabled librav1e; then
        command -v cargo-cinstall.exe &>/dev/null ||
            log "install-cargo-c" "$RUSTUP_HOME/bin/cargo.exe" install cargo-c \
            --target="$CARCH"-pc-windows-gnu --jobs "$cpuCount"
        [[ -f $CARGO_HOME/config ]] && rm -f "$CARGO_HOME/config"
        CARGO_BUILD_JOBS="$cpuCount" log "install-rav1e-c" "$RUSTUP_HOME/bin/cargo.exe" \
            cinstall --release --prefix "$(pwd)/install-$bits"
        # do_install "install-$bits/bin/rav1e.dll" bin-video/
        # do_install "install-$bits/lib/librav1e.dll.a" lib/
        do_install "install-$bits/lib/librav1e.a" lib/
        do_install "install-$bits/lib/pkgconfig/rav1e.pc" lib/pkgconfig/
        do_install "install-$bits/include/rav1e"/*.h include/rav1e/
    fi

    do_checkIfExist
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
if { { [[ $ffmpeg != "no" ]] &&
    { enabled sdl2 || ! disabled_any sdl2 autodetect; }; } ||
    mpv_enabled sdl2; } &&
    do_pkgConfig "sdl2 = 2.0.10" &&
    do_wget -h b4656c13a1f0d0023ae2f4a9cf08ec92fffb464e0f24238337784159b8b91d57 \
        "http://www.libsdl.org/release/SDL2-2.0.10.tar.gz"; then
    do_uninstall include/SDL2 lib/cmake/SDL2 bin/sdl2-config "${_check[@]}"
    sed -i 's|__declspec(dllexport)||g' include/{begin_code,SDL_opengl}.h
    do_separate_confmakeinstall
    do_checkIfExist
fi

_check=(libdvdread.{l,}a dvdread.pc)
if { [[ $mplayer = "y" ]] || mpv_enabled_any dvdread dvdnav; } &&
    do_vcs "https://code.videolan.org/videolan/libdvdread.git" dvdread; then
    do_autoreconf
    do_uninstall include/dvdread "${_check[@]}"
    do_separate_confmakeinstall
    do_checkIfExist
fi
[[ -f "$LOCALDESTDIR"/lib/pkgconfig/dvdread.pc ]] &&
    grep_or_sed "Libs.private" "$LOCALDESTDIR"/lib/pkgconfig/dvdread.pc \
        "/Libs:/ a\Libs.private: -ldl -lpsapi"

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

if { [[ $ffmpeg != "no" ]] && enabled_any gcrypt libbluray; } ||
    ! mpv_disabled libbluray; then
    do_pacman_install libgcrypt
    grep_or_sed ws2_32 "$MINGW_PREFIX/bin/libgcrypt-config" 's;-lgpg-error;& -lws2_32;'
    grep_or_sed ws2_32 "$MINGW_PREFIX/bin/gpg-error-config" 's;-lgpg-error;& -lws2_32;'
fi


if { [[ $ffmpeg != "no" ]] && enabled libbluray; } || ! mpv_disabled libbluray; then
    _check=(bin-video/libaacs.dll libaacs.{{,l}a,pc} libaacs/aacs.h)
    if do_vcs "https://code.videolan.org/videolan/libaacs.git"; then
        sed -ri 's;bin_PROGRAMS.*;bin_PROGRAMS = ;' Makefile.am
        do_autoreconf
        do_uninstall "${_check[@]}" include/libaacs
        do_separate_confmakeinstall video --enable-shared --with-libgcrypt-prefix="$MINGW_PREFIX"
        mv -f "$LOCALDESTDIR/bin/libaacs-0.dll" "$LOCALDESTDIR/bin-video/libaacs.dll"
        rm -f "$LOCALDESTDIR/bin-video/${MINGW_CHOST}-aacs_info.exe"
        do_checkIfExist
    fi

    _check=(bin-video/libbdplus.dll libbdplus.{{,l}a,pc} libbdplus/bdplus.h)
    if do_vcs "https://code.videolan.org/videolan/libbdplus.git"; then
        sed -ri 's;noinst_PROGRAMS.*;noinst_PROGRAMS = ;' Makefile.am
        do_autoreconf
        do_uninstall "${_check[@]}" include/libbdplus
        do_separate_confmakeinstall video --enable-shared
        mv -f "$LOCALDESTDIR/bin/libbdplus-0.dll" "$LOCALDESTDIR/bin-video/libbdplus.dll"
        do_checkIfExist
    fi
fi

_check=(libbluray.{{l,}a,pc})
if { { [[ $ffmpeg != "no" ]] && enabled libbluray; } || ! mpv_disabled libbluray; } &&
    do_vcs "https://code.videolan.org/videolan/libbluray.git"; then
    [[ -f contrib/libudfread/.git ]] || log git.submodule git submodule update --init
    do_autoreconf
    do_uninstall include/libbluray share/java "${_check[@]}"
    sed -i 's|__declspec(dllexport)||g' jni/win32/jni_md.h
    extracommands=()
    log javahome get_java_home
    OLD_PATH="$PATH"
    if [[ -n "$JAVA_HOME" ]]; then
        if [[ ! -f /opt/apache-ant/bin/ant ]] ; then
            apache_ant_ver="$(clean_html_index "https://www.apache.org/dist/ant/binaries/")"
            apache_ant_ver="$(get_last_version "$apache_ant_ver" "apache-ant" "1\.\d+\.\d+")"
            apache_ant_ver="${apache_ant_ver:-1.10.6}"
            if do_wget -r -c \
                "https://www.apache.org/dist/ant/binaries/apache-ant-${apache_ant_ver}-bin.zip" \
                apache-ant.zip; then
                rm -rf /opt/apache-ant
                mv apache-ant/apache-ant* /opt/apache-ant
            fi
        fi
        PATH="/opt/apache-ant/bin:$JAVA_HOME/bin:$PATH"
        log ant-diagnostics ant -diagnostics
        export JDK_HOME=""
        export JAVA_HOME
    else
        extracommands+=(--disable-bdjava-jar)
    fi
    if enabled libxml2; then
        do_pacman_install libxml2
        sed -ri 's;(Cflags.*);\1 -DLIBXML_STATIC;' src/libbluray.pc.in
    else
        extracommands+=(--without-libxml2)
    fi
    CFLAGS+=" $(enabled libxml2 && echo "-DLIBXML_STATIC")" \
        do_separate_confmakeinstall --disable-{examples,doxygen-doc} \
        --without-{fontconfig,freetype} "${extracommands[@]}"
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

_check=(libxavs2.a xavs2_config.h xavs2.{h,pc})
[[ $standalone = y ]] && _check+=(bin-video/xavs2.exe)
if [[ $bits = 32bit ]]; then
    do_removeOption --enable-libxavs2
elif { [[ $avs2 = y ]] || { [[ $ffmpeg != "no" ]] && enabled libxavs2; }; } &&
    do_vcs "https://github.com/pkuvcl/xavs2.git"; then
    cd_safe build/linux
    [[ -f "config.mak" ]] && log "distclean" make distclean
    do_uninstall all "${_check[@]}"
    do_configure --host="$MINGW_CHOST" --prefix="$LOCALDESTDIR" \
        --bindir="$LOCALDESTDIR"/bin-video --enable-static --enable-strip
    do_makeinstall
    do_checkIfExist
fi

_check=(libdavs2.a davs2_config.h davs2.{h,pc})
[[ $standalone = y ]] && _check+=(bin-video/davs2.exe)
if [[ $bits = 32bit ]]; then
    do_removeOption --enable-libdavs2
elif { [[ $avs2 = y ]] || { [[ $ffmpeg != "no" ]] && enabled libdavs2; }; } &&
    do_vcs "https://github.com/pkuvcl/davs2.git"; then
    cd_safe build/linux
    [[ -f "config.mak" ]] && log "distclean" make distclean
    do_uninstall all "${_check[@]}"
    do_configure --host="$MINGW_CHOST" --prefix="$LOCALDESTDIR" \
        --bindir="$LOCALDESTDIR"/bin-video --enable-strip
    do_makeinstall
    do_checkIfExist
fi

if [[ $mediainfo = "y" ]]; then
    [[ $curl = openssl ]] && hide_libressl
    _check=(libzen.{a,pc})
    if do_vcs "https://github.com/MediaArea/ZenLib.git" libzen; then
        do_uninstall include/ZenLib bin-global/libzen-config \
            "${_check[@]}" libzen.la lib/cmake/zenlib
        do_cmakeinstall Project/CMake
        do_checkIfExist
    fi
    fix_cmake_crap_exports "$LOCALDESTDIR/lib/cmake/zenlib"

    _check=(libmediainfo.{a,pc})
    _deps=(lib{zen,curl}.a)
    if do_vcs "https://github.com/MediaArea/MediaInfoLib.git" libmediainfo; then
        do_uninstall include/MediaInfo{,DLL} bin-global/libmediainfo-config \
            "${_check[@]}" libmediainfo.la lib/cmake/mediainfolib
        do_cmakeinstall Project/CMake -DBUILD_ZLIB=off -DBUILD_ZENLIB=off
        do_checkIfExist
    fi
    fix_cmake_crap_exports "$LOCALDESTDIR/lib/cmake/mediainfolib"

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
    [[ $curl = openssl ]] && hide_libressl -R
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
    do_pkgConfig "zvbi-0.2 = 0.2.35" &&
    do_wget_sf -h 95e53eb208c65ba6667fd4341455fa27 \
        "zapping/zvbi/0.2.35/zvbi-0.2.35.tar.bz2"; then
    do_uninstall "${_check[@]}" zvbi-0.2.pc
    _vlc_zvbi_patches="https://raw.githubusercontent.com/videolan/vlc/master/contrib/src/zvbi"
    do_patch "$_vlc_zvbi_patches/zvbi-win32.patch"
    # added by zvbi-win32.patch above, not needed anymore
    sed -i 's;-lpthreadGC2 -lwsock32;;' zvbi-0.2.pc.in
    do_separate_conf --disable-{dvb,bktr,nls,proxy} --without-doxygen
    cd_safe src
    do_makeinstall
    cd_safe ..
    log pkgconfig make SUBDIRS=. install
    do_checkIfExist
    unset _vlc_zvbi_patches
fi


if [[ $ffmpeg != "no" ]] && enabled_any frei0r ladspa; then
    _check=(libdl.a dlfcn.h)
    if do_vcs "https://github.com/dlfcn-win32/dlfcn-win32.git"; then
        do_uninstall "${_check[@]}"
        [[ -f config.mak ]] && log clean make distclean
        sed -i 's|__declspec(dllexport)||g' dlfcn.h
        do_configure --prefix="$LOCALDESTDIR" --disable-shared
        do_make && do_makeinstall
        do_checkIfExist
    fi

    _check=(frei0r.{h,pc})
    if do_vcs "https://github.com/dyne/frei0r.git"; then
        sed -i 's/find_package (Cairo)//' "CMakeLists.txt"
        do_uninstall lib/frei0r-1 "${_check[@]}"
        do_pacman_install gavl
        do_cmakeinstall -DWITHOUT_OPENCV=on
        do_checkIfExist
    fi
fi

_check=(DeckLinkAPI.h DeckLinkAPIVersion.h DeckLinkAPI_i.c)
if [[ $ffmpeg != "no" ]] && enabled decklink &&
    do_vcs "https://gitlab.com/media-autobuild_suite-dependencies/decklink-headers.git"; then
    do_makeinstall PREFIX="$LOCALDESTDIR"
    do_checkIfExist
fi

_check=(libmfx.{{l,}a,pc})
if [[ $ffmpeg != "no" ]] && enabled libmfx &&
    do_vcs "https://github.com/lu-zero/mfx_dispatch.git" libmfx; then
    do_autoreconf
    do_uninstall include/mfx "${_check[@]}"
    do_separate_confmakeinstall
    do_checkIfExist
fi

_check=(AMF/core/Version.h)
if [[ $ffmpeg != no ]] && { enabled amf || ! disabled_any autodetect amf; } &&
    do_vcs "https://github.com/GPUOpen-LibrariesAndSDKs/AMF.git"; then
    do_uninstall include/AMF
    cd_safe amf/public/include
    install -D -p -t "$LOCALDESTDIR/include/AMF/core" core/*.h
    install -D -p -t "$LOCALDESTDIR/include/AMF/components" components/*.h
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

_check=(SvtHevcEnc.pc libSvtHevcEnc.dll.a svt-hevc/EbApi.h
    bin-video/{libSvtHevcEnc.dll,SvtHevcEncApp.exe})
if [[ $bits = "32bit" ]]; then
    do_removeOption --enable-libsvthevc
elif { [[ $svthevc = "y" ]] || enabled libsvthevc; } &&
    do_vcs "https://github.com/OpenVisualCloud/SVT-HEVC.git"; then
    do_uninstall "${_check[@]}" include/svt-hevc
    do_cmakeinstall video -DUNIX=OFF -DNATIVE=OFF
    do_checkIfExist
fi

if [[ $x264 != no ]]; then
    _check=(x264{,_config}.h libx264.a x264.pc)
    [[ $standalone = y ]] && _check+=(bin-video/x264.exe)
    _bitdepth="$(get_api_version x264_config.h BIT_DEPTH)"
    if do_vcs "https://code.videolan.org/videolan/x264.git" ||
        [[ $x264 = o8   && "$_bitdepth" =~ (0|10) ]] ||
        [[ $x264 = high && "$_bitdepth" =~ (0|8) ]] ||
        [[ $x264 =~ (yes|full|shared|fullv) && "$_bitdepth" != 0 ]]; then

        extracommands=("--host=$MINGW_CHOST" "--prefix=$LOCALDESTDIR"
            "--bindir=$LOCALDESTDIR/bin-video")

        # light ffmpeg build
        old_PKG_CONFIG_PATH="$PKG_CONFIG_PATH"
        PKG_CONFIG_PATH="$LOCALDESTDIR/opt/lightffmpeg/lib/pkgconfig:$MINGW_PREFIX/lib/pkgconfig"
        unset_extra_script
        if [[ $standalone = y && $x264 =~ (full|fullv) ]]; then
            _check=("$LOCALDESTDIR"/opt/lightffmpeg/lib/pkgconfig/libav{codec,format}.pc)
            do_vcs "https://git.ffmpeg.org/ffmpeg.git"
            do_uninstall "$LOCALDESTDIR"/opt/lightffmpeg
            [[ -f "config.mak" ]] && log "distclean" make distclean
            create_build_dir light
            if [[ $x264 = fullv ]]; then
                mapfile -t audio_codecs < <(
                    sed -n '/audio codecs/,/external libraries/p' ../libavcodec/allcodecs.c |
                    sed -n 's/^[^#]*extern.* *ff_\([^ ]*\)_decoder;/\1/p')
                extra_script pre configure
                LDFLAGS+=" -L$MINGW_PREFIX/lib" \
                    log configure ../configure "${FFMPEG_BASE_OPTS[@]}" \
                    --prefix="$LOCALDESTDIR/opt/lightffmpeg" \
                    --disable-{programs,devices,filters,encoders,muxers,debug,sdl2,network,protocols,doc} \
                    --enable-protocol=file,pipe \
                    --disable-decoder="$(IFS=, ; echo "${audio_codecs[*]}")" --enable-gpl \
                    --disable-bsf=aac_adtstoasc,text2movsub,noise,dca_core,mov2textsub,mp3_header_decompress \
                    --disable-autodetect --enable-{lzma,bzlib,zlib}
                extra_script post configure
                unset audio_codecs
            else
                extra_script pre configure
                LDFLAGS+=" -L$MINGW_PREFIX/lib" \
                    log configure ../configure "${FFMPEG_BASE_OPTS[@]}" \
                    --prefix="$LOCALDESTDIR/opt/lightffmpeg" \
                    --disable-{programs,devices,filters,encoders,muxers,debug,sdl2,doc} --enable-gpl
                    extra_script post configure
            fi
            do_makeinstall
            files_exist "${_check[@]}" && touch "build_successful${bits}_light"
            unset_extra_script

            _check=("$LOCALDESTDIR"/opt/lightffmpeg/lib/pkgconfig/ffms2.pc bin-video/ffmsindex.exe)
            if do_vcs "https://github.com/FFMS/ffms2.git"; then
                do_uninstall "${_check[@]}"
                sed -i 's/Libs.private.*/& -lstdc++/;s/Cflags.*/& -DFFMS_STATIC/' ffms2.pc.in
                do_patch "https://0x0.st/sgEY.txt"
                mkdir -p src/config
                do_autoreconf
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

        x264_build="$(grep X264_BUILD x264.h | awk '{ print $3 }' | head -1)"
        if [[ $x264 = shared ]]; then
            extracommands+=(--enable-shared)
            _check+=(libx264.dll.a bin-video/libx264-"${x264_build}".dll)
        else
            extracommands+=(--enable-static)
            _check+=(libx264.a)
        fi

        if [[ $x264 = high ]]; then
            extracommands+=("--bit-depth=10")
        elif [[ $x264 = o8 ]]; then
            extracommands+=("--bit-depth=8")
        else
            extracommands+=("--bit-depth=all")
        fi

        do_uninstall "${_check[@]}"
        check_custom_patches
        create_build_dir
        extra_script pre configure
        PKGCONFIG="${PKG_CONFIG}" CFLAGS="${CFLAGS// -O2 / }" \
            log configure ../configure "${extracommands[@]}"
        extra_script post configure
        do_make
        do_makeinstall
        do_checkIfExist
        PKG_CONFIG_PATH="$old_PKG_CONFIG_PATH"
        unset extracommands x264_build old_PKG_CONFIG_PATH
    fi
    unset _bitdepth
else
    pc_exists x264 || do_removeOption --enable-libx264
fi

_check=(x265{,_config}.h libx265.a x265.pc)
[[ $standalone = y ]] && _check+=(bin-video/x265.exe)
if [[ ! $x265 = "n" ]] && do_vcs "hg::https://bitbucket.org/multicoreware/x265"; then
    do_uninstall libx265{_main10,_main12}.a bin-video/libx265_main{10,12}.dll "${_check[@]}"
    [[ $bits = "32bit" ]] && assembly="-DENABLE_ASSEMBLY=OFF"
    [[ $x265 = d ]] && xpsupport="-DWINXP_SUPPORT=ON"

    build_x265() {
        create_build_dir
        local build_root
        build_root="$(pwd)"
        mkdir -p {8,10,12}bit

    do_x265_cmake() {
        do_print_progress "Building $1" && shift 1
        extra_script pre cmake
        log "cmake" cmake "$LOCALBUILDDIR/$(get_first_subdir)/source" -G Ninja \
        -DCMAKE_INSTALL_PREFIX="$LOCALDESTDIR" -DBIN_INSTALL_DIR="$LOCALDESTDIR/bin-video" \
        -DENABLE_SHARED=OFF -DENABLE_CLI=OFF -DHIGH_BIT_DEPTH=ON -DHG_EXECUTABLE=/usr/bin/hg.bat \
        -DENABLE_HDR10_PLUS=ON $xpsupport "$@"
        extra_script post cmake
        do_ninja
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
    cpuCount=1 log "install" ninja install
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

_check=(xvid.h libxvidcore.a bin-video/xvid{_encraw.exe,core.dll})
if enabled libxvid && [[ $standalone = y ]] && ! { files_exist "${_check[@]}" &&
    grep -q '1.3.5' "$LOCALDESTDIR/bin-video/xvid_encraw.exe"; } &&
    do_wget -h 165ba6a2a447a8375f7b06db5a3c91810181f2898166e7c8137401d7fc894cf0 \
        "https://downloads.xvid.com/downloads/xvidcore-1.3.5.tar.gz" "xvidcore.tar.gz"; then
    do_pacman_remove xvidcore
    do_uninstall "${_check[@]}"
    cd_safe build/generic
    do_configure --prefix="$LOCALDESTDIR" --{build,host}="$MINGW_CHOST"
    do_make
    do_install ../../src/xvid.h include/
    do_install '=build/xvidcore.a' libxvidcore.a
    do_install '=build/xvidcore.dll' bin-video/
    cd_safe ../../examples
    sed -ri "s;(#define MAX_ZONES\s*) \S.*$;\1 8192;" xvid_encraw.c
    do_make xvid_encraw
    do_install xvid_encraw.exe bin-video/
    do_checkIfExist
fi

_check=(libvmaf.{a,h,pc})
if [[ $bits = 32bit ]]; then
    do_removeOption --enable-libvmaf
elif [[ $ffmpeg != "no" ]] && enabled libvmaf &&
    do_vcs "https://github.com/Netflix/vmaf.git"; then
    do_uninstall share/model "${_check[@]}"
    log clean make clean
    do_make INSTALL_PREFIX="$LOCALDESTDIR"
    do_makeinstall INSTALL_PREFIX="$LOCALDESTDIR"
    do_checkIfExist
fi

_check=(ffnvcodec/nvEncodeAPI.h)
if [[ $ffmpeg != "no" ]] && { enabled ffnvcodec ||
    ! disabled_any ffnvcodec autodetect || ! mpv_disabled cuda-hwaccel; } &&
    do_vcs "https://git.videolan.org/git/ffmpeg/nv-codec-headers.git" ffnvcodec; then
    do_makeinstall PREFIX="$LOCALDESTDIR"
    do_checkIfExist
fi

_check=(libsrt.a srt.pc srt/srt.h)
[[ $standalone = y ]] && _check+=(bin-video/srt-live-transmit.exe)
if enabled libsrt && do_vcs "https://github.com/Haivision/srt.git"; then
    do_pacman_install openssl
    hide_libressl
    do_cmakeinstall video -DENABLE_SHARED=off -DENABLE_SUFLIP=off \
        -DENABLE_EXAMPLES=off -DUSE_OPENSSL_PC=on
    hide_libressl -R
    do_checkIfExist
fi


if  { ! mpv_disabled vapoursynth || enabled vapoursynth; }; then
    _python_ver=3.7.3
    _python_lib=python37
    [[ $bits = 64bit ]] && _arch=amd64 || _arch=win32
    _check=("lib$_python_lib.a")
    if files_exist "${_check[@]}"; then
        do_print_status "python $_python_ver" "$green" "Up-to-date"
    elif do_wget "https://www.python.org/ftp/python/$_python_ver/python-$_python_ver-embed-$_arch.zip"; then
        gendef "$_python_lib.dll" >/dev/null 2>&1
        dlltool -y "lib$_python_lib.a" -d "$_python_lib.def"
        [[ -f "lib$_python_lib.a" ]] && do_install "lib$_python_lib.a"
        do_checkIfExist
    fi

    _vsver=46
    _check=(lib{vapoursynth,vsscript}.a vapoursynth{,-script}.pc vapoursynth/{VS{Helper,Script},VapourSynth}.h)
    if pc_exists "vapoursynth = $_vsver" && files_exist "${_check[@]}"; then
        do_print_status "vapoursynth R$_vsver" "$green" "Up-to-date"
    elif do_wget "https://github.com/vapoursynth/vapoursynth/releases/download/R$_vsver/VapourSynth${bits%bit}-Portable-R$_vsver.7z"; then
        do_uninstall {vapoursynth,vsscript}.lib include/vapoursynth "${_check[@]}"
        do_install sdk/include/*.h include/vapoursynth/

        create_build_dir
        declare -A _pc_vars=(
            [vapoursynth-name]=vapoursynth
            [vapoursynth-description]='A frameserver for the 21st century'
            [vapoursynth-cflags]="-DVS_CORE_EXPORTS"

            [vsscript-name]=vapoursynth-script
            [vsscript-description]='Library for interfacing VapourSynth with Python'
            [vsscript-private]="-l$_python_lib -lstdc++"
        )
        for _file in vapoursynth vsscript; do
            gendef - "../$_file.dll" 2>/dev/null |
                sed -E 's|^_||;s|@[1-9]+$||' > "${_file}.def"
            # shellcheck disable=SC2046
            dlltool -y "lib${_file}.a" -d "${_file}.def" \
                $([[ $bits = 32bit ]] && echo "-U") 2>/dev/null
            [[ -f lib${_file}.a ]] && do_install "lib${_file}.a"
            # shellcheck disable=SC2016
            printf '%s\n' \
               "prefix=$LOCALDESTDIR" \
               'exec_prefix=${prefix}' \
               'libdir=${exec_prefix}/lib' \
               'includedir=${prefix}/include/vapoursynth' \
               "Name: ${_pc_vars[${_file}-name]}" \
               "Description: ${_pc_vars[${_file}-description]}" \
               "Version: $_vsver" \
               "Libs: -L\${libdir} -l${_file}" \
               "Libs.private: ${_pc_vars[${_file}-private]}" \
               "Cflags: -I\${includedir} ${_pc_vars[${_file}-cflags]}" \
               > "${_pc_vars[${_file}-name]}.pc"
        done

        do_install vapoursynth{,-script}.pc lib/pkgconfig/
        do_checkIfExist
    fi
    unset _arch _file _python_lib _python_ver _vsver _pc_vars
else
    mpv_disable vapoursynth
    do_removeOption --enable-vapoursynth
fi

_check=(liblensfun.a lensfun.pc lensfun/lensfun.h)
if [[ $ffmpeg != "no" ]] && enabled liblensfun &&
    do_pkgConfig "lensfun = 0.3.95.0" &&
    do_vcs "https://github.com/lensfun/lensfun.git"; then
    do_pacman_install glib2
    grep_or_sed liconv "$MINGW_PREFIX/lib/pkgconfig/glib-2.0.pc" 's;-lintl;& -liconv;g'
    grep_or_sed Libs.private libs/lensfun/lensfun.pc.cmake '/Libs:/ a\Libs.private: -lstdc++'
    do_uninstall "bin-video/lensfun" "${_check[@]}"
    do_patch "https://github.com/Alexpux/MINGW-packages/raw/master/mingw-w64-lensfun/cmake-mingw.patch"
    do_patch "https://github.com/Alexpux/MINGW-packages/raw/master/mingw-w64-lensfun/lenstool.patch"
    CFLAGS+=" -DGLIB_STATIC_COMPILATION" CXXFLAGS+=" -DGLIB_STATIC_COMPILATION" \
        do_cmakeinstall -DBUILD_STATIC=on -DBUILD_{TESTS,LENSTOOL,DOC}=off \
        -DINSTALL_HELPER_SCRIPTS=off -DCMAKE_INSTALL_DATAROOTDIR="$LOCALDESTDIR/bin-video"
    do_checkIfExist
    add_to_remove
fi

_check=(bin-video/vvc/{Encoder,Decoder}App.exe)
if [[ $vvc = y ]] &&
    do_vcs "https://gitlab.com/media-autobuild_suite-dependencies/VVCSoftware_VTM.git" vvc; then
    do_uninstall bin-video/vvc
    # patch for easier install of apps
    # probably not of upstream's interest because of how experimental the codec is
    do_patch "https://0x0.st/sG0V.txt"
    _notrequired="true"
    # install to own dir because the binaries' names are too generic
    do_cmakeinstall -DCMAKE_INSTALL_BINDIR="$LOCALDESTDIR"/bin-video/vvc \
        -DBUILD_STATIC=on -DSET_ENABLE_SPLIT_PARALLELISM=ON -DENABLE_SPLIT_PARALLELISM=ON
    do_checkIfExist
    unset _notrequired
fi

enabled openssl && hide_libressl
if [[ $ffmpeg != "no" ]]; then
    enabled libgsm && do_pacman_install gsm
    enabled libsnappy && do_addOption --extra-libs=-lstdc++ && do_pacman_install snappy
    if enabled libxvid && [[ $standalone = n ]]; then
        do_pacman_install xvidcore
        [[ -f $MINGW_PREFIX/lib/xvidcore.a ]] && mv -f "$MINGW_PREFIX"/lib/{,lib}xvidcore.a
        [[ -f $MINGW_PREFIX/lib/xvidcore.dll.a ]] && mv -f "$MINGW_PREFIX"/lib/xvidcore.dll.a{,.dyn}
    fi
    if enabled libssh; then
        do_pacman_install libssh
        do_addOption --extra-cflags=-DLIBSSH_STATIC "--extra-ldflags=-Wl,--allow-multiple-definition"
        grep_or_sed "Requires.private" "$MINGW_PREFIX"/lib/pkgconfig/libssh.pc \
            "/Libs:/ i\Requires.private: zlib libssl"
    fi
    enabled libtheora && do_pacman_install libtheora
    if enabled libcdio; then
        do_pacman_install libcdio-paranoia
        grep -ZlER -- "-R/mingw\S+" "$MINGW_PREFIX"/lib/pkgconfig/* | xargs -r -0 sed -ri 's;-R/mingw\S+;;g'
    fi
    enabled libcaca && do_addOption --extra-cflags=-DCACA_STATIC && do_pacman_install libcaca
    enabled libmodplug && do_addOption --extra-cflags=-DMODPLUG_STATIC && do_pacman_install libmodplug
    enabled libopenjpeg && do_pacman_install openjpeg2
    if enabled libopenh264; then
        do_pacman_install openh264
        if [[ -f $MINGW_PREFIX/lib/libopenh264.dll.a.dyn ]]; then
            mv -f "$MINGW_PREFIX"/lib/libopenh264.a{,.bak}
            mv -f "$MINGW_PREFIX"/lib/libopenh264.{dll.a.dyn,a}
        fi
        [[ -f $MINGW_PREFIX/lib/libopenh264.dll.a ]] && mv -f "$MINGW_PREFIX"/lib/libopenh264.{dll.,}a
        if test_newer "$MINGW_PREFIX"/lib/libopenh264.dll.a "$LOCALDESTDIR/bin-video/libopenh264.dll"; then
            pushd "$LOCALDESTDIR/bin-video" >/dev/null || do_exit_prompt "Did you delete the bin-video folder?"
            if [[ $bits = "64bit" ]]; then
              _sha256="427e3dfb264f6aab23d6057ce26d3f4f87a3c53bec40e48ddbcbcb6ac71f3bb2"
            else
              _sha256="86c025ef302dcb56482e5b43d3de778ea4d4ddd02180a3b858a653a25e00390d"
            fi
            do_wget -c -r -q -h $_sha256 \
            "http://ciscobinary.openh264.org/openh264-1.8.0-win${bits%bit}.dll.bz2" \
                libopenh264.dll.bz2
            [[ -f libopenh264.dll.bz2 ]] && bunzip2 libopenh264.dll.bz2
            unset _sha256
            popd >/dev/null || do_exit_prompt "Did you delete the previous folder?"
        fi
    fi
    enabled chromaprint && do_addOption --extra-cflags=-DCHROMAPRINT_NODLL --extra-libs=-lstdc++ &&
        do_pacman_remove fftw && do_pacman_install chromaprint
    if enabled libzmq; then
        do_pacman_install zeromq
        grep_or_sed ws2_32 "$MINGW_PREFIX"/lib/pkgconfig/libzmq.pc \
            's/-lpthread/& -lws2_32/'
        do_addOption --extra-cflags=-DZMQ_STATIC
    fi
    enabled frei0r && do_addOption --extra-libs=-lpsapi
    enabled libxml2 && do_addOption --extra-cflags=-DLIBXML_STATIC && do_pacman_install libxml2
    enabled ladspa && do_pacman_install ladspa-sdk
    if enabled vapoursynth && pc_exists "vapoursynth-script >= 42"; then
        _ver="$(pkg-config --modversion vapoursynth-script)"
        do_simple_print "${green}Compiling FFmpeg with Vapoursynth R${_ver}${reset}"
        do_simple_print "${orange}FFmpeg will need vapoursynth.dll and vsscript.dll to run using vapoursynth demuxers"'!'"${reset}"
        unset _ver
    elif enabled vapoursynth; then
        do_removeOption --enable-vapoursynth
        do_simple_print "${red}Update to at least Vapoursynth R42 to use with FFmpeg${reset}"
    fi
    disabled autodetect && enabled iconv && do_addOption --extra-libs=-liconv

    do_hide_all_sharedlibs

    _check=(libavutil.pc)
    disabled_any avfilter ffmpeg || _check+=(bin-video/ffmpeg.exe)
    if [[ $ffmpeg =~ "shared" ]]; then
        _check+=(libavutil.dll.a)
    else
        _check+=(libavutil.a)
        [[ $ffmpeg = "both" ]] && _check+=(bin-video/ffmpegSHARED)
    fi
    # todo: make this more easily customizable
    [[ $ffmpegUpdate = y ]] && enabled_any lib{aom,tesseract,vmaf,x265,vpx} &&
        _deps=(lib{aom,tesseract,vmaf,x265,vpx}.a)
    if do_vcs "https://git.ffmpeg.org/ffmpeg.git"; then

        do_changeFFmpegConfig "$license"
        [[ -f ffmpeg_extra.sh ]] && source ffmpeg_extra.sh

        if enabled libsvthevc; then
            do_patch "https://gist.githubusercontent.com/wiiaboo/9a570057d6bc605a3c72429cfe0cf45b/raw/ffmpeg-libsvthevc-patches.patch" am ||
                do_removeOption --enable-libsvthevc
        fi

        enabled vapoursynth &&
            do_patch "https://0x0.st/zp4W.txt vapoursynth_alt.patch" am

        # librav1e
        if enabled librav1e; then
            do_patch "https://patchwork.ffmpeg.org/patch/13874/mbox/" am ||
                do_removeOption "--enable-librav1e"
        fi

        if enabled openal; then
            do_patch "https://gist.githubusercontent.com/Helenerineium/406d836f81f99a0656bdaf885265ca2e/raw/openal-pkgconfig.patch" ||
                do_removeOption "--enable-openal"
        fi

        if [[ ${#FFMPEG_OPTS[@]} -gt 35 ]]; then
            # remove redundant -L and -l flags from extralibs
            do_patch "https://0x0.st/zLsN.txt" am
        fi

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

        # --build-suffix handling
        opt_exists FFMPEG_OPTS "^--build-suffix=[a-zA-Z0-9-]+$" &&
            build_suffix="$(printf '%s\n' "${FFMPEG_OPTS[@]}" |
                sed -rn '/build-suffix=/{s;.+=(.+);\1;p}')" ||
                build_suffix=""

        if [[ $ffmpeg = "both" ]]; then
            _check+=(bin-video/ffmpegSHARED/lib/"libavutil${build_suffix}.dll.a")
            FFMPEG_OPTS_SHARED+=("--prefix=$LOCALDESTDIR/bin-video/ffmpegSHARED")
        elif [[ $ffmpeg =~ "shared" ]]; then
            _check+=("libavutil${build_suffix}".{dll.a,pc})
            FFMPEG_OPTS_SHARED+=("--prefix=$LOCALDESTDIR"
                "--bindir=$LOCALDESTDIR/bin-video"
                "--shlibdir=$LOCALDESTDIR/bin-video")
        fi
        ! disabled_any debug "debug=gdb" &&
            ffmpeg_cflags="$(sed -r 's/ (-O[1-3]|-mtune=\S+)//g' <<< "$CFLAGS")"

        # shared
        if [[ $ffmpeg != "static" ]] && [[ ! -f build_successful${bits}_shared ]]; then
            do_print_progress "Compiling ${bold}shared${reset} FFmpeg"
            do_uninstall bin-video/ffmpegSHARED "${_uninstall[@]}"
            [[ -f config.mak ]] && log "distclean" make distclean
            create_build_dir shared
            extra_script pre configure
            CFLAGS="${ffmpeg_cflags:-$CFLAGS}" \
            LDFLAGS+=" -L$LOCALDESTDIR/lib -L$MINGW_PREFIX/lib" \
                log configure ../configure \
                --disable-static --enable-shared "${FFMPEG_OPTS_SHARED[@]}"
            extra_script post configure
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
                    if { disabled autodetect && enabled_any sdl2 ffplay; } ||
                        { ! disabled autodetect && ! disabled_any sdl2 ffplay; }; then
                        _check+=(bin-video/ffplay.exe)
                    fi
                fi
                disabled ffprobe || _check+=(bin-video/ffprobe.exe)
            fi
            do_uninstall bin-video/ff{mpeg,play,probe}.exe{,.debug} "${_uninstall[@]}"
            create_build_dir static
            extra_script pre configure
            CFLAGS="${ffmpeg_cflags:-$CFLAGS}" \
            LDFLAGS+=" -L$LOCALDESTDIR/lib -L$MINGW_PREFIX/lib" \
                log configure ../configure --prefix="$LOCALDESTDIR" \
                --bindir="$LOCALDESTDIR/bin-video" "${FFMPEG_OPTS[@]}"
            extra_script post configure
            # cosmetics
            sed -ri "s/ ?--($sedflags)=(\S+[^\" ]|'[^']+')//g" config.h
            do_make && do_makeinstall
            ! disabled_any debug "debug=gdb" &&
                create_debug_link "$LOCALDESTDIR"/bin-video/ff{mpeg,probe,play}.exe
            cd_safe ..
        fi
        do_checkIfExist
        [[ -f "$LOCALDESTDIR"/bin-video/ffmpeg.exe ]] &&
            create_winpty_exe ffmpeg "$LOCALDESTDIR"/bin-video/
        unset ffmpeg_cflags build_suffix
    fi
fi

_check=(bin-video/m{player,encoder}.exe)
if [[ $mplayer = "y" ]] &&
    do_vcs "svn::svn://svn.mplayerhq.hu/mplayer/trunk" mplayer; then
    [[ $license != "nonfree" || $faac = n ]] && faac_opts=(--disable-faac)
    do_uninstall "${_check[@]}"
    [[ -f config.mak ]] && log "distclean" make distclean
    if [[ ! -d ffmpeg ]]; then
        if [[ "$ffmpeg" != "no" && -d "$LOCALBUILDDIR/ffmpeg-git" ]] &&
            git clone -q "$LOCALBUILDDIR/ffmpeg-git" ffmpeg; then
            cd_safe ffmpeg
            git checkout -qf --no-track -B master origin/HEAD
            cd_safe ..
        elif ! git clone "https://git.ffmpeg.org/ffmpeg.git" ffmpeg; then
            rm -rf ffmpeg
            printf '%s\n' \
                "Failed to get a FFmpeg checkout" \
                "Please try again or put FFmpeg source code copy into ffmpeg/ manually." \
                "Nightly snapshot: http://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2" \
                "Either re-run the script or extract above to inside /build/mplayer-svn."
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

    grep_or_sed windows libmpcodecs/ad_spdif.c '/#include "mp_msg.h/ a\#include <windows.h>'

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

if [[ $mpv != "n" ]] && pc_exists libavcodec libavformat libswscale libavfilter; then
    if ! mpv_disabled lua && opt_exists MPV_OPTS "--lua=5.1"; then
        do_pacman_install lua51
    elif ! mpv_disabled lua; then
        do_pacman_install luajit
    fi

    do_pacman_remove uchardet-git
    ! mpv_disabled uchardet && do_pacman_install uchardet
    ! mpv_disabled libarchive && do_pacman_install libarchive
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
            if ! [[ -f "$LOCALDESTDIR/bin-video/d3dcompiler_47.dll" ]] &&
                do_wget -c -q "https://i.fsbn.eu/pub/angle/d3dcompiler_47-win${bits%bit}.7z"; then
                do_install "d3dcompiler_47-win${bits%bit}/d3dcompiler_47.dll" bin-video/
            fi
            stripping=n do_checkIfExist
    elif ! mpv_disabled egl-angle &&
        ! test_newer installed ./libGLESv2.dll bin-video/libGLESv2.dll; then
        do_print_status "└ $(get_first_subdir)" "$green" "Files up-to-date"
    fi

    if ! mpv_disabled vapoursynth && pc_exists "vapoursynth-script >= 24"; then
        _ver="$(pkg-config --modversion vapoursynth-script)"
        do_simple_print "${green}Compiling mpv with Vapoursynth R${_ver}${reset}"
        do_simple_print "${orange}mpv will need vapoursynth.dll and vsscript.dll to use vapoursynth filter"'!'"${reset}"
        unset _ver
    elif ! mpv_disabled vapoursynth; then
        mpv_disable vapoursynth
        do_simple_print "${red}Update to at least Vapoursynth R24 to use with mpv${reset}"
    fi

    _check=(mujs.h libmujs.a)
    if ! mpv_disabled javascript &&
        do_vcs "https://github.com/ccxvii/mujs.git"; then
        do_uninstall bin-global/mujs.exe "${_check[@]}"
        log clean env -i PATH="$PATH" "$(command -v make)" clean
        extra_script pre make
        log "make" env -i PATH="$PATH" TEMP="${TEMP:-/tmp}" CPATH="${CPATH:-}" "$(command -v make)" \
            install prefix="$LOCALDESTDIR" bindir="$LOCALDESTDIR/bin-global"
        extra_script post make
        do_checkIfExist
    fi

    _check=(mruby.h libmruby{,_core}.a)
    if mpv_enabled mruby && do_vcs "https://github.com/mruby/mruby.git"; then
        do_uninstall "${_check[@]}" include/mruby mrbconf.h
        log clean make clean
        log make ./minirake "$(pwd)/build/host/lib/libmruby.a"
        do_install build/host/lib/*.a lib/
        cmake -E copy_directory include "$LOCALDESTDIR/include"
        do_checkIfExist
    fi

    _check=(libvulkan.a vulkan.pc)
    if ! mpv_disabled vulkan &&
        do_vcs "https://github.com/KhronosGroup/Vulkan-Loader.git#tag=v1.1.114" vulkan-loader; then
        _shinchiro_patches="https://raw.githubusercontent.com/shinchiro/mpv-winbuild-cmake/b1f8bc13/packages"
        do_uninstall "${_check[@]}"
        do_patch "$_shinchiro_patches/vulkan-0001-cross-compile-static-linking-hacks.patch"
        create_build_dir
        log dependencies /usr/bin/python3 ../scripts/update_deps.py --no-build
        cd_safe Vulkan-Headers
            _check=(vulkan/vulkan.h)
            do_uninstall include/vulkan
            do_cmakeinstall
            do_checkIfExist
            _check=(libvulkan.a vulkan.pc)
        cd_safe "$LOCALBUILDDIR/$(get_first_subdir)"
        CFLAGS+=" -D_WIN32_WINNT=0x0600 -D__STDC_FORMAT_MACROS" \
            CPPFLAGS+=" -D_WIN32_WINNT=0x0600 -D__STDC_FORMAT_MACROS" \
            CXXFLAGS+=" -D__USE_MINGW_ANSI_STDIO -D__STDC_FORMAT_MACROS -fpermissive -D_WIN32_WINNT=0x0600" \
            do_cmake -DBUILD_TESTS=no -DCMAKE_SYSTEM_NAME=Windows  \
            -DCMAKE_ASM-ATT_COMPILER="$(command -v nasm.exe)" -DVULKAN_HEADERS_INSTALL_DIR="${LOCALDESTDIR}" \
            -DENABLE_STATIC_LOADER=ON -DUNIX=off
        log make ninja
        do_install loader/libvulkan.a lib/
        do_install loader/vulkan.pc lib/pkgconfig/
        do_checkIfExist
        unset _shinchiro_patches
    fi

    _check=(shaderc/shaderc.h libshaderc_combined.a)
    if ! mpv_disabled shaderc &&
        do_vcs "https://github.com/google/shaderc.git"; then
        do_uninstall "${_check[@]}" include/shaderc include/libshaderc_util

        add_third_party() {
            local repo="$1"
            local name="$2"
            [[ ! "$name" ]] && name="${repo##*/}" && name="${name%.*}"
            local dest="third_party/$name"

            if [[ -d "$dest/.git" ]]; then
                log "$name-reset" git -C "$dest" reset --hard "@{u}"
                log "$name-pull" git -C "$dest" pull
            else
                log "$name-clone" git clone --depth 1 "$repo" "$dest"
            fi
        }

        add_third_party "https://github.com/KhronosGroup/glslang.git"
        add_third_party "https://github.com/KhronosGroup/SPIRV-Tools.git" spirv-tools
        add_third_party "https://github.com/KhronosGroup/SPIRV-Headers.git" spirv-headers
        add_third_party "https://github.com/KhronosGroup/SPIRV-Cross.git" spirv-cross

        # fix python indentation errors from non-existant code review
        grep -ZRlP --include="*.py" '\t' third_party/spirv-tools/ | xargs -r -0 -n1 sed -i 's;\t;    ;g'

        do_cmake -GNinja -DSHADERC_SKIP_TESTS=ON
        log make ninja
        cmake -E copy_directory ../libshaderc/include/shaderc "$LOCALDESTDIR/include/shaderc"
        cmake -E copy_directory ../libshaderc_util/include/libshaderc_util "$LOCALDESTDIR/include/libshaderc_util"
        do_install libshaderc/libshaderc_combined.a lib/
        do_checkIfExist
        unset add_third_party
    fi

    _check=(spirv_cross/spirv_cross_c.h spirv-cross.pc libspirv-cross.a)
    if ! mpv_disabled spirv-cross &&
        do_vcs "https://github.com/KhronosGroup/SPIRV-Cross.git"; then
        do_uninstall include/spirv_cross "${_check[@]}" spirv-cross-c-shared.pc libspirv-cross-c-shared.a
        do_patch "https://github.com/KhronosGroup/SPIRV-Cross/compare/master...taisei-project:meson.patch meson.patch" am
        do_mesoninstall
        do_checkIfExist
    fi

    _check=(libplacebo.{a,pc})
    _deps=(lib{vulkan,shaderc_combined}.a)
    if ! mpv_disabled libplacebo &&
        do_vcs "https://code.videolan.org/videolan/libplacebo.git"; then
        do_uninstall "${_check[@]}"
        do_mesoninstall
        do_checkIfExist
    fi

    _check=(bin-video/mpv.{exe,com})
    _deps=(lib{ass,avcodec,vapoursynth,shaderc_combined,spirv-cross}.a "$MINGW_PREFIX"/lib/libuchardet.a)
    if do_vcs "https://github.com/mpv-player/mpv.git"; then
        hide_conflicting_libs
        create_ab_pkgconfig

        log bootstrap /usr/bin/python bootstrap.py
        if [[ -d build ]]; then
            /usr/bin/python waf distclean >/dev/null 2>&1
            do_uninstall bin-video/mpv{.exe,-1.dll}.debug "${_check[@]}"
        fi

        mpv_ldflags=("-L$LOCALDESTDIR/lib" "-L$MINGW_PREFIX/lib")
        if [[ $bits = "64bit" ]]; then
            mpv_ldflags+=("-Wl,--image-base,0x140000000,--high-entropy-va")
            if enabled libnpp && [[ -n "$CUDA_PATH" ]]; then
                mpv_cflags=("-I$(cygpath -sm "$CUDA_PATH")/include")
                mpv_ldflags+=("-L$(cygpath -sm "$CUDA_PATH")/lib/x64")
            fi
        fi
        enabled libtesseract && mpv_cflags+=("-fopenmp") mpv_ldflags+=("-lgomp")
        enabled libssh && mpv_ldflags+=("-Wl,--allow-multiple-definition")
        if ! mpv_disabled manpage-build || mpv_enabled html-build; then
            do_pacman_install python3-docutils
        fi
        # do_pacman_remove python3-rst2pdf
        # mpv_enabled pdf-build && do_pacman_install python2-rst2pdf

        # rst2pdf is broken
        mpv_disable pdf-build

        [[ -f mpv_extra.sh ]] && source mpv_extra.sh

        mpv_enabled mruby &&
            { git merge --no-edit --no-gpg-sign origin/mruby ||
              git merge --abort && do_removeOption MPV_OPTS "--enable-mruby"; }

        if files_exist libavutil.a; then
            MPV_OPTS+=(--enable-static-build)
        else
            # force pkg-config lookup to look for static requirements
            export PKGCONF_STATIC=yes
            # hacky way of ignoring ffmpeg libs own shared dependencies
            for _avpc in avcodec avdevice avfilter avformat avutil swresample swscale; do
                if [[ -f "$LOCALDESTDIR/lib/pkgconfig/lib${_avpc}.pc" ]]; then
                    sed -i 's;^Requires.private;# &;g' "$LOCALDESTDIR/lib/pkgconfig/lib${_avpc}.pc"
                fi
            done
        fi

        extra_script pre configure
        CFLAGS+=" ${mpv_cflags[*]}" LDFLAGS+=" ${mpv_ldflags[*]}" \
            RST2MAN="${MINGW_PREFIX}/bin/rst2man" \
            RST2HTML="${MINGW_PREFIX}/bin/rst2html" \
            RST2PDF="${MINGW_PREFIX}/bin/rst2pdf2" \
            PKG_CONFIG="$LOCALDESTDIR/bin/ab-pkg-config" \
            log configure /usr/bin/python waf configure \
            "--prefix=$LOCALDESTDIR" "--bindir=$LOCALDESTDIR/bin-video" \
            --disable-vapoursynth-lazy "${MPV_OPTS[@]}"
        extra_script post configure

        extra_script pre build
        log build /usr/bin/python waf -j "${cpuCount:-1}"
        extra_script post build

        extra_script pre install
        log install /usr/bin/python waf -j1 install ||
            log install /usr/bin/python waf -j1 install
        extra_script post install

        if ! files_exist libavutil.a; then
            # revert hack
            for _avpc in avcodec avdevice avfilter avformat avutil swresample swscale; do
                if [[ -f "$LOCALDESTDIR/lib/pkgconfig/lib${_avpc}.pc" ]]; then
                    sed -ri 's;#.*(Requires.private);\1;g' "$LOCALDESTDIR/lib/pkgconfig/lib${_avpc}.pc"
                fi
            done
        fi

        unset mpv_ldflags replace PKGCONF_STATIC
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
    if do_vcs "https://gitlab.com/media-autobuild_suite-dependencies/libmxf.git" libMXF-1.0; then
        do_autogen
        do_uninstall include/libMXF-1.0 "${_check[@]}"
        do_separate_confmakeinstall video --disable-examples
        do_checkIfExist
    fi

    _check=(libMXF++-1.0.{{,l}a,pc})
    _deps=(libMXF-1.0.a)
    if do_vcs "https://gitlab.com/media-autobuild_suite-dependencies/libmxfpp.git" libMXF++-1.0; then
        do_autogen
        do_uninstall include/libMXF++-1.0 "${_check[@]}"
        do_separate_confmakeinstall video --disable-examples
        do_checkIfExist
    fi

    _check=(bin-video/{bmxtranswrap,{h264,mov,vc2}dump,mxf2raw,raw2bmx}.exe)
    _deps=("$MINGW_PREFIX"/lib/liburiparser.a lib{MXF{,++}-1.0,curl}.a)
    if do_vcs "https://gitlab.com/media-autobuild_suite-dependencies/bmx.git"; then
        do_autogen
        do_uninstall libbmx-0.1.{{,l}a,pc} bin-video/bmxparse.exe \
            include/bmx-0.1 "${_check[@]}"
        do_separate_confmakeinstall video
        do_checkIfExist
    fi
fi
enabled openssl && hide_libressl -R

if [[ $cyanrip = y ]]; then
    do_pacman_install libxml2
    do_pacman_install libcdio-paranoia
    sed -ri 's;-R[^ ]*;;g' "$MINGW_PREFIX/lib/pkgconfig/libcdio.pc"

    _check=(neon/ne_utils.h libneon.a neon.pc)
    if do_pkgConfig "neon = 0.30.2" &&
        do_wget -h db0bd8cdec329b48f53a6f00199c92d5ba40b0f015b153718d1b15d3d967fbca \
            "https://fossies.org/linux/www/neon-0.30.2.tar.gz"; then
        do_uninstall include/neon "${_check[@]}"
        do_separate_confmakeinstall --disable-{nls,debug,webdav}
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
        old_PKG_CONFIG_PATH="$PKG_CONFIG_PATH"
        _check=("$LOCALDESTDIR"/opt/cyanffmpeg/lib/pkgconfig/libav{codec,format}.pc)
        if flavor=cyan do_vcs "https://git.ffmpeg.org/ffmpeg.git"; then
            do_uninstall "$LOCALDESTDIR"/opt/cyanffmpeg
            [[ -f "config.mak" ]] && log "distclean" make distclean
            mapfile -t cyan_ffmpeg_opts < <(
                enabled libmp3lame &&
                    printf '%s\n' "--enable-libmp3lame" "--enable-encoder=libmp3lame"
                if enabled libvorbis; then
                    printf '%s\n' "--enable-libvorbis" "--enable-encoder=libvorbis"
                else
                    echo "--enable-encoder=vorbis"
                fi
                if enabled libopus; then
                    printf '%s\n' "--enable-libopus" "--enable-encoder=libopus"
                else
                    echo "--enable-encoder=opus"
                fi
            )
            create_build_dir cyan
            log configure ../configure "${FFMPEG_BASE_OPTS[@]}" \
                --prefix="$LOCALDESTDIR/opt/cyanffmpeg" \
                --disable-{programs,devices,filters,decoders,hwaccels,encoders,muxers} \
                --disable-{debug,protocols,demuxers,parsers,doc,swscale,postproc,network} \
                --disable-{avdevice,avfilter,autodetect} \
                --disable-bsfs --enable-protocol=file \
                --enable-encoder=flac,tta,aac,wavpack,alac \
                --enable-muxer=flac,tta,ipod,wv,mp3,opus,ogg \
                --enable-parser=png,mjpeg --enable-decoder=mjpeg,png \
                --enable-demuxer=image2,png_pipe,bmp_pipe \
                --enable-{bzlib,zlib,lzma,iconv} \
                "${cyan_ffmpeg_opts[@]}"
            do_makeinstall
            files_exist "${_check[@]}" && touch ../"build_successful${bits}_cyan"
        fi
        unset cyan_ffmpeg_opts
        PKG_CONFIG_PATH="$LOCALDESTDIR/opt/cyanffmpeg/lib/pkgconfig:$PKG_CONFIG_PATH"

        cd_safe "$LOCALBUILDDIR"/cyanrip-git
        _check=(bin-audio/cyanrip.exe)
        _extra_cflags=("$(cygpath -m "$LOCALDESTDIR/opt/cyanffmpeg/include")"
            "$(cygpath -m "$LOCALDESTDIR/include")")
        _extra_ldflags=("$(cygpath -m "$LOCALDESTDIR/opt/cyanffmpeg/lib")"
            "$(cygpath -m "$LOCALDESTDIR/lib")")
        hide_conflicting_libs "$LOCALDESTDIR/opt/cyanffmpeg"
        CFLAGS+=" -DLIBXML_STATIC $(printf ' -I%s' "${_extra_cflags[@]}")" \
        LDFLAGS+="$(printf ' -L%s' "${_extra_ldflags[@]}")" \
            do_mesoninstall audio
        hide_conflicting_libs -R "$LOCALDESTDIR/opt/cyanffmpeg"
        do_checkIfExist
        PKG_CONFIG_PATH="$old_PKG_CONFIG_PATH"
        unset old_PKG_CONFIG_PATH _extra_ldflags _extra_cflags
    fi
fi

_check=(bin-video/ffmbc.exe)
if [[ $ffmbc = y ]] && do_vcs "https://github.com/bcoudurier/FFmbc.git#branch=ffmbc"; then # no other branch
    _notrequired=yes
    do_patch https://0x0.st/zM5A.patch
    create_build_dir
    log configure ../configure --target-os=mingw32 --enable-gpl \
        --disable-{dxva2,ffprobe} --extra-cflags=-DNO_DSHOW_STRSAFE
    do_make
    do_install ffmbc.exe bin-video/
    do_checkIfExist
    unset _notrequired
fi

_check=(bin-global/redshift.exe)
if [[ $redshift = y ]] && do_vcs "https://github.com/jonls/redshift.git"; then
    [[ -f configure ]] || log bootstrap ./bootstrap
    CFLAGS+=' -D_POSIX_C_SOURCE' \
        do_separate_confmakeinstall global --enable-wingdi \
        --disable-{nls,ubuntu,corelocation,quartz,drm,randr,vidmode,geoclue2,gui}
    do_checkIfExist
fi

do_simple_print -p "${orange}Finished $bits compilation of all tools${reset}"
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
    printf '%s\n' \
        "-------------------------------------------------------------------------------" \
        "There were new updates while compiling." \
        "Updated:$new_updates_packages" \
        "Would you like to run compilation again to get those updates? Default: no"
    do_prompt "y/[n] "
    echo "-------------------------------------------------------------------------------"
    if [[ $ret = "y" || $ret = "Y" || $ret = "yes" ]]; then
        run_builds
    else
        break
    fi
done

clean_suite
do_simple_print -p "${green}Compilation successful.${reset}"
do_simple_print -p "${green}This window will close automatically in 5 seconds.${reset}"
sleep 5
