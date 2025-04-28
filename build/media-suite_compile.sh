#!/bin/bash
# shellcheck disable=SC2034,SC1090,SC1117,SC1091,SC2119
shopt -s extglob

if [[ -z $LOCALBUILDDIR ]]; then
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
FFMPEG_BASE_OPTS=("--pkg-config=pkgconf" --pkg-config-flags="--keep-system-libs --keep-system-cflags --static" "--cc=$CC" "--cxx=$CXX" "--ld=$CXX" "--extra-cxxflags=-fpermissive" "--extra-cflags=-Wno-int-conversion")
printf '\nBuild start: %(%F %T %z)T\n' -1 >> "$LOCALBUILDDIR/newchangelog"

printf '#!/bin/bash\nbash %s %s\n' "$LOCALBUILDDIR/media-suite_compile.sh" "$*" > "$LOCALBUILDDIR/last_run"

while true; do
    case $1 in
    --cpuCount=* ) cpuCount=${1#*=} && shift ;;
    --build32=* ) build32=${1#*=} && shift ;;
    --build64=* ) build64=${1#*=} && shift ;;
    --mp4box=* ) mp4box=${1#*=} && shift ;;
    --rtmpdump=* ) rtmpdump=${1#*=} && shift ;;
    --vpx=* ) vpx=${1#*=} && shift ;;
    --x264=* ) x264=${1#*=} && shift ;;
    --x265=* ) x265=${1#*=} && shift ;;
    --other265=* ) other265=${1#*=} && shift ;;
    --flac=* ) flac=${1#*=} && shift ;;
    --fdkaac=* ) fdkaac=${1#*=} && shift ;;
    --mediainfo=* ) mediainfo=${1#*=} && shift ;;
    --sox=* ) sox=${1#*=} && shift ;;
    --ffmpeg=* ) ffmpeg=${1#*=} && shift ;;
    --ffmpegUpdate=* ) ffmpegUpdate=${1#*=} && shift ;;
    --ffmpegPath=* ) ffmpegPath="${1#*=}"; shift ;;
    --ffmpegChoice=* ) ffmpegChoice=${1#*=} && shift ;;
    --mplayer=* ) mplayer=${1#*=} && shift ;;
    --mpv=* ) mpv=${1#*=} && shift ;;
    --deleteSource=* ) deleteSource=${1#*=} && shift ;;
    --license=* ) license=${1#*=} && shift ;;
    --standalone=* ) standalone=${1#*=} && shift ;;
    --stripping* ) stripping=${1#*=} && shift ;;
    --packing* ) packing=${1#*=} && shift ;;
    --logging=* ) logging=${1#*=} && shift ;;
    --bmx=* ) bmx=${1#*=} && shift ;;
    --aom=* ) aom=${1#*=} && shift ;;
    --faac=* ) faac=${1#*=} && shift ;;
    --exhale=* ) exhale=${1#*=} && shift ;;
    --ffmbc=* ) ffmbc=${1#*=} && shift ;;
    --curl=* ) curl=${1#*=} && shift ;;
    --cyanrip=* ) cyanrip=${1#*=} && shift ;;
    --ripgrep=* ) ripgrep=${1#*=} && shift ;;
    --rav1e=* ) rav1e=${1#*=} && shift ;;
    --dav1d=* ) dav1d=${1#*=} && shift ;;
    --libavif=* ) libavif=${1#*=} && shift ;;
    --libheif=* ) libheif=${1#*=} && shift ;;
    --jpegxl=* ) jpegxl=${1#*=} && shift ;;
    --av1an=* ) av1an=${1#*=} && shift ;;
    --vvc=* ) vvc=${1#*=} && shift ;;
    --uvg266=* ) uvg266=${1#*=} && shift ;;
    --vvenc=* ) vvenc=${1#*=} && shift ;;
    --vvdec=* ) vvdec=${1#*=} && shift ;;
    --jq=* ) jq=${1#*=} && shift ;;
    --jo=* ) jo=${1#*=} && shift ;;
    --dssim=* ) dssim=${1#*=} && shift ;;
    --gifski=* ) gifski=${1#*=} && shift ;;
    --avs2=* ) avs2=${1#*=} && shift ;;
    --dovitool=* ) dovitool=${1#*=} && shift ;;
    --hdr10plustool=* ) hdr10plustool=${1#*=} && shift ;;
    --timeStamp=* ) timeStamp=${1#*=} && shift ;;
    --noMintty=* ) noMintty=${1#*=} && shift ;;
    --ccache=* ) ccache=${1#*=} && shift ;;
    --svthevc=* ) svthevc=${1#*=} && shift ;;
    --svtav1=* ) svtav1=${1#*=} && shift ;;
    --svtvp9=* ) svtvp9=${1#*=} && shift ;;
    --xvc=* ) xvc=${1#*=} && shift ;;
    --vlc=* ) vlc=${1#*=} && shift ;;
    --zlib=* ) zlib=${1#*=} && shift ;;
    --exitearly=* ) exitearly=${1#*=} && shift ;;
    # --autouploadlogs=* ) autouploadlogs=${1#*=} && shift ;;
    -- ) shift && break ;;
    -* ) echo "Error, unknown option: '$1'." && exit 1 ;;
    * ) break ;;
    esac
done

[[ $ccache != y ]] && export CCACHE_DISABLE=1

# shellcheck source=media-suite_deps.sh
source "$LOCALBUILDDIR"/media-suite_deps.sh

# shellcheck source=media-suite_helper.sh
source "$LOCALBUILDDIR"/media-suite_helper.sh

if [[ $exitearly = EE1 ]]; then
    do_simple_print -p '\n\t'"${orange}Exit due to env var MABS_EXIT_EARLY set to EE1"
    exit 0
fi

do_simple_print -p "${orange}Warning: We will not accept any issues lacking any form of logs or logs.zip!$reset"

buildProcess() {
set_title
do_simple_print -p '\n\t'"${orange}Starting $bits compilation of all tools$reset"
[[ -f $HOME/custom_build_options ]] &&
    echo "Imported custom build options (unsupported)" &&
    source "$HOME"/custom_build_options

cd_safe "$LOCALBUILDDIR"

do_getFFmpegConfig "$license"
declare -A MPV_OPTS="($(do_getMpvConfig))"

do_fix_pkgconfig_abspaths
do_clean_old_builds

# In case a build was interrupted before reversing hide_conflicting_libs
[[ -d $LOCALDESTDIR/opt/cyanffmpeg ]] &&
    hide_conflicting_libs -R "$LOCALDESTDIR/opt/cyanffmpeg"
hide_conflicting_libs -R
do_hide_all_sharedlibs
create_ab_pkgconfig
create_cmake_toolchain
create_ab_ccache

set_title "compiling global tools"
do_simple_print -p '\n\t'"${orange}Starting $bits compilation of global tools${reset}"

if [[ $bits = 32bit && $av1an != n ]]; then
    do_simple_print "${orange}Av1an cannot be compiled due to Vapoursynth being broken on 32-bit and will be disabled"'!'"${reset}"
    _reenable_av1an=$av1an # so that av1an can be built if both 32 bit and 64 bit targets are enabled
    av1an=n
fi

if [[ ! -z $_reenable_av1an ]] && [[ $bits = 64bit ]]; then
    av1an=$_reenable_av1an
    unset _reenable_av1an
fi

if [[ $packing = y &&
    ! "$(/opt/bin/upx -V 2> /dev/null | head -1)" = "upx 5.0.0" ]] &&
    do_wget -h 8c34b9cec2c225bf71f43cf2b788043d0d203d23edb54f649fbec16f34938d80 \
        "https://github.com/upx/upx/releases/download/v5.0.0/upx-5.0.0-win32.zip"; then
    do_install upx.exe /opt/bin/upx.exe
fi

if [[ "$ripgrep|$rav1e|$dssim|$libavif|$dovitool|$hdr10plustool" = *y* ]] ||
    [[ $av1an != n ]] || [[ $gifski != n ]] || [[ $zlib = rs ]] || enabled librav1e; then
    do_pacman_install rust
    [[ $CC =~ clang ]] && rust_target_suffix="llvm"
fi

if [[ $libavif = y ]] || [[ $dovitool = y ]] || [[ $zlib = rs ]] || enabled librav1e; then
    do_pacman_install cargo-c
fi

_check=(libz.a zlib.pc)
_zlib_uninstall=(lib/cmake/{zlib,minizip} z{conf,lib,lib_name_mangling}.h include/minizip libminizip.{,l}a minizip.pc)
if [[ $zlib = n ]]; then
    # uninstall existing zlib files, if the user switched from building zlib to using the msys2 package
    do_uninstall "${_check[@]}" "${_zlib_uninstall[@]}"
    zlib_dir="$MINGW_PREFIX"
else
    zlib_dir="$LOCALDESTDIR"
    if [[ $zlib = y ]]; then
        [[ $standalone = y ]] && _check+=(bin-global/mini{,un}zip.exe)
        if do_vcs "$SOURCE_REPO_ZLIB"; then
            do_uninstall "${_check[@]}" "${_zlib_uninstall[@]}"
            sed -i 's; -L${sharedlibdir};;' zlib.pc.in
            do_cmakeinstall -DZLIB_BUILD_{TESTING,SHARED}=OFF -DZLIB_INSTALL_COMPAT_DLL=OFF
            if [[ $standalone = y ]]; then
                cd_safe ../contrib/minizip
                sed -i 's/Libs.private.*/& -lbz2/' minizip.pc.in
                do_autoreconf
                CFLAGS+=" -DHAVE_BZIP2" do_separate_confmakeinstall global --enable-demos LIBS="-lbz2"
            fi
            [[ -f "$LOCALDESTDIR"/lib/libzs.a ]] && mv -f "$LOCALDESTDIR"/lib/libz{s,}.a
            do_checkIfExist
        fi
    elif [[ $zlib = chromium ]]; then
        [[ $standalone = y ]] && _check+=(bin-global/mini{,g}zip.exe)
        if do_vcs "$SOURCE_REPO_ZLIBCHROMIUM"; then
            do_uninstall "${_check[@]}" "${_zlib_uninstall[@]}"
            extracommands=()
            [[ $standalone = y ]] && extracommands=(-DBUILD_MINIZIP_BIN=YES -DBUILD_MINIGZIP=YES)
            # these macros are for some reason not set, even though they should be according to CMakeLists.txt
            local zlib_macros="-DINFLATE_CHUNK_SIMD_SSE2 -DADLER32_SIMD_SSSE3 -DINFLATE_CHUNK_READ_64LE -DCRC32_SIMD_SSE42_PCLMUL -DDEFLATE_SLIDE_HASH_SSE2 -D_LARGEFILE64_SOURCE=1 -DX86_WINDOWS"
            sed -i 's; -L${sharedlibdir};;' zlib.pc.cmakein
            # add missing header and source files needed for compilation, and force all executables to link with static zlib
            sed -e 's;ioapi.h;ioapi.h contrib/minizip/iowin32.c contrib/minizip/iowin32.h;' \
                -e 's;zlib);zlibstatic);' -i CMakeLists.txt
            # the win32 dir is missing, so copy the folder from original zlib
            do_wget -c -r -q "https://github.com/madler/zlib/archive/refs/heads/develop.tar.gz"
            tar --strip-components=1 -xzf develop.tar.gz zlib-develop/win32
            do_cmakeinstall -DINSTALL_PKGCONFIG_DIR="${LOCALDESTDIR}/lib/pkgconfig" \
                -DUSE_ZLIB_RABIN_KARP_HASH=ON -DENABLE_SIMD_OPTIMIZATIONS=ON \
                -DCMAKE_C_FLAGS="${CFLAGS} ${zlib_macros} -msse4.2 -mpclmul" "${extracommands[@]}"
            [[ $standalone = y ]] && do_install minizip_bin.exe bin-global/minizip.exe &&
                do_install minigzip_bin.exe bin-global/minigzip.exe
            # there's no option to disable building the shared library, so delete them manually
            [[ -f "$LOCALDESTDIR"/lib/libz.dll.a ]] && rm -f "$LOCALDESTDIR"/lib/libz.dll.a
            [[ -f "$LOCALDESTDIR"/bin/libz.dll ]] && rm -f "$LOCALDESTDIR"/bin/libz.dll
            do_checkIfExist
            unset extracommands
        fi
    elif [[ $zlib = cloudflare ]]; then
        [[ $standalone = y ]] && _check+=(bin-global/minigzip.exe)
        if do_vcs "$SOURCE_REPO_ZLIBCLOUDFLARE"; then
            do_uninstall "${_check[@]}" "${_zlib_uninstall[@]}"
            extracommands=()
            [[ $standalone = y ]] && extracommands=(-DBUILD_EXAMPLES=YES)
            sed -i 's; -L${sharedlibdir};;' zlib.pc.in
            do_cmakeinstall -DCMAKE_POLICY_VERSION_MINIMUM=3.5 "${extracommands[@]}"
            [[ $standalone = y ]] && do_install minigzip.exe bin-global/
            do_checkIfExist
            unset extracommands
        fi
        if enabled zlib; then
            do_addOption --extra-cflags=-Wno-error=incompatible-pointer-types
        fi
    elif [[ $zlib = ng ]]; then
        [[ $standalone = y ]] && _check+=(bin-global/mini{,g}zip.exe)
        if do_vcs "$SOURCE_REPO_ZLIBNG"; then
            do_uninstall "${_check[@]}" "${_zlib_uninstall[@]}"
            do_cmakeinstall global -DZLIB_COMPAT=ON -DWITH_GTEST=OFF -DZLIB_ENABLE_TESTS=OFF
            if [[ $standalone = y ]] &&
                do_vcs "$SOURCE_REPO_MINIZIPNG"; then
                do_cmakeinstall global -DMZ_BUILD_TESTS=ON
            fi
            do_checkIfExist
        fi
    elif [[ $zlib = rs ]]; then
        if do_vcs "$SOURCE_REPO_ZLIBRS"; then
            do_uninstall "${_check[@]}" "${_zlib_uninstall[@]}"
            cd_safe libz-rs-sys-cdylib
            # edit package metadata and library name to match zlib
            sed -e 's;libz_rs;libz;' -e 's;z_rs;z;' -i Cargo.toml
            PKG_CONFIG="$LOCALDESTDIR/bin/ab-pkg-config-static.bat" \
                log "rust.capi" cargo capi build \
                --release --jobs "$cpuCount" --prefix="$LOCALDESTDIR"
            do_install "target/$CARCH-pc-windows-gnu$rust_target_suffix/release/libz.a" libz.a
            do_install "target/$CARCH-pc-windows-gnu$rust_target_suffix/release/libz.pc" zlib.pc
            do_checkIfExist
        fi
    fi
fi
unset _zlib_uninstall

_check=(bin-global/rg.exe)
if [[ $ripgrep = y ]] &&
    do_vcs "$SOURCE_REPO_RIPGREP"; then
    do_uninstall "${_check[@]}"
    do_rust
    do_install "target/$CARCH-pc-windows-gnu$rust_target_suffix/release/rg.exe" bin-global/
    do_checkIfExist
fi

_check=(bin-global/jo.exe)
if [[ $jo = y ]] &&
    do_vcs "$SOURCE_REPO_JO"; then
    do_mesoninstall global
    do_checkIfExist
fi

_deps=("$MINGW_PREFIX"/lib/pkgconfig/oniguruma.pc)
_check=(bin-global/jq.exe)
if [[ $jq = y ]] &&
    do_vcs "$SOURCE_REPO_JQ"; then
    do_pacman_install -m bison flex
    do_pacman_install oniguruma
    do_uninstall "${_check[@]}"
    do_autoreconf
    CFLAGS+=' -D_POSIX_C_SOURCE' YFLAGS='--warnings=no-yacc' \
        do_separate_conf global --enable-{all-static,pthread-tls,maintainer-mode} --disable-docs
    do_make && do_install jq.exe bin-global/
    do_checkIfExist
fi

_check=(bin-global/dssim.exe)
if [[ $dssim = y ]] &&
    do_vcs "$SOURCE_REPO_DSSIM"; then
    do_uninstall "${_check[@]}"
    CFLAGS+=" -fno-PIC" do_rust
    do_install "target/$CARCH-pc-windows-gnu$rust_target_suffix/release/dssim.exe" bin-global/
    do_checkIfExist
fi

if [[ $gifski != n ]]; then
    if [[ $gifski = video ]]; then
        _check=("$LOCALDESTDIR"/opt/gifskiffmpeg/lib/pkgconfig/lib{av{codec,device,filter,format,util},swscale}.pc)
        if flavor=gifski do_vcs "https://git.ffmpeg.org/ffmpeg.git#branch=release/6.1"; then
            do_uninstall "$LOCALDESTDIR"/opt/gifskiffmpeg
            [[ -f config.mak ]] && log "distclean" make distclean
            create_build_dir gifski
            mapfile -t audio_codecs < <(
                sed -n '/audio codecs/,/external libraries/p' ../libavcodec/allcodecs.c |
                sed -n 's/^[^#]*extern.* *ff_\([^ ]*\)_decoder;/\1/p')
            mapfile -t image_demuxers < <(
                sed -n '/image demuxers/,/external libraries/p' ../libavformat/allformats.c |
                sed -n 's/^[^#]*extern.* *ff_\([^ ]*\)_demuxer;/\1/p')
            config_path=.. do_configure "${FFMPEG_BASE_OPTS[@]}" \
                --prefix="$LOCALDESTDIR/opt/gifskiffmpeg" \
                --enable-static --disable-shared --disable-programs \
                --disable-autodetect --disable-everything \
                --disable-{debug,doc,network,postproc,protocols} \
                --enable-{decoders,demuxers} \
                --enable-filter=format,fps,scale --enable-protocol=file \
                --disable-bsf=evc_frame_merge,media100_to_mjpegb,vp9_superframe_split \
                --disable-decoder="$(IFS=, ; echo "${audio_codecs[*]}")" \
                --disable-demuxer="$(IFS=, ; echo "${image_demuxers[*]}"),image2pipe,yuv4mpegpipe"
            do_make && do_makeinstall
            files_exist "${_check[@]}" && touch ../"build_successful${bits}_gifski"
            unset audio_codecs image_demuxers gifski_ffmpeg_opts
        fi
        old_PKG_CONFIG_PATH=$PKG_CONFIG_PATH
        PKG_CONFIG_PATH=$LOCALDESTDIR/opt/gifskiffmpeg/lib/pkgconfig:$PKG_CONFIG_PATH
    fi

    _check=(bin-global/gifski.exe)
    if do_vcs "$SOURCE_REPO_GIFSKI"; then
        do_uninstall "${_check[@]}"
        extracommands=()
        if [[ $gifski = video ]]; then
            extracommands=("--release" "--features=video-prebuilt-static")
            do_pacman_install clang
        fi
        PKG_CONFIG="$LOCALDESTDIR/bin/ab-pkg-config-static.bat" \
            do_rust "${extracommands[@]}"
        do_install "target/$CARCH-pc-windows-gnu$rust_target_suffix/release/gifski.exe" bin-global/
        do_checkIfExist
        unset extracommands
    fi
    if [[ $gifski = video ]]; then
        PKG_CONFIG_PATH=$old_PKG_CONFIG_PATH
        unset old_PKG_CONFIG_PATH
    fi
fi

_deps=("$zlib_dir"/lib/libz.a)
_check=(libxml2.a libxml2/libxml/xmlIO.h libxml-2.0.pc)
if { enabled_any libxml2 libbluray || [[ $cyanrip = y ]] || ! mpv_disabled libbluray; } &&
    do_vcs "$SOURCE_REPO_LIBXML2"; then
    do_uninstall include/libxml2/libxml "${_check[@]}"
    extracommands=("-DLIBXML2_WITH_PYTHON=OFF" "-DLIBXML2_WITH_TESTS=OFF")
    [[ $standalone = y ]] || extracommands+=("-DLIBXML2_WITH_PROGRAMS=OFF")
    do_cmakeinstall "${extracommands[@]}"
    do_checkIfExist
    unset extracommands
fi

# Fixes an issue with ordering with libbluray libxml2 and libz and liblzma
# Probably caused by https://gitlab.gnome.org/GNOME/libxml2/-/commit/93e8bb2a402012858500b608b4146cd5c756e34d
grep_or_sed Requires.private "$LOCALDESTDIR/lib/pkgconfig/libxml-2.0.pc" 's/Requires:/Requires.private:/'

if [[ $ffmpeg != no ]] && enabled libaribb24; then
    _deps=("$zlib_dir"/lib/libz.a)
    _check=(libpng.{pc,{,l}a} libpng16.{pc,{,l}a} libpng16/png.h)
    if do_vcs "$SOURCE_REPO_LIBPNG"; then
        do_uninstall include/libpng16 "${_check[@]}"
        do_autoupdate
        do_separate_confmakeinstall --with-pic
        do_checkIfExist
    fi

    _deps=(libpng.{pc,a} libpng16.{pc,a})
    _check=(aribb24.pc libaribb24.{,l}a)
    if do_vcs "$SOURCE_REPO_ARRIB24"; then
        do_patch "https://raw.githubusercontent.com/BtbN/FFmpeg-Builds/master/patches/aribb24/12.patch"
        do_patch "https://raw.githubusercontent.com/BtbN/FFmpeg-Builds/master/patches/aribb24/13.patch"
        do_patch "https://raw.githubusercontent.com/BtbN/FFmpeg-Builds/master/patches/aribb24/17.patch"
        do_uninstall include/aribb24 "${_check[@]}"
        do_autoreconf
        do_separate_confmakeinstall --with-pic
        do_checkIfExist
    fi
fi

if [[ $mplayer = y || $mpv = y ]] ||
    { [[ $ffmpeg != no ]] && enabled_any libass libfreetype {lib,}fontconfig libfribidi; }; then
    do_pacman_remove freetype fontconfig harfbuzz fribidi

    _check=(libfreetype.a freetype2.pc)
    [[ $ffmpeg = sharedlibs ]] && _check+=(bin-video/libfreetype-6.dll libfreetype.dll.a)
    if do_vcs "$SOURCE_REPO_FREETYPE"; then
        do_uninstall include/freetype2 bin-global/freetype-config \
            bin{,-video,-global}/libfreetype-6.dll libfreetype.dll.a "${_check[@]}"
        extracommands=(-D{harfbuzz,png,bzip2,brotli,zlib,tests}"=disabled")
        [[ $ffmpeg = sharedlibs ]] && extracommands+=(--default-library=both)
        do_mesoninstall global "${extracommands[@]}"
        [[ $ffmpeg = sharedlibs ]] && do_install "$LOCALDESTDIR"/bin-global/libfreetype-6.dll bin-video/
        do_checkIfExist
        unset extracommands
    fi

    _deps=(libfreetype.a)
    _check=(libfontconfig.a fontconfig.pc)
    if [[ $ffmpeg = sharedlibs ]]; then
        enabled_any {lib,}fontconfig && do_removeOption "--enable-(lib|)fontconfig"
        _check+=(bin-global/libfontconfig-1.dll libfontconfig.dll.a)
    fi
    if enabled_any {lib,}fontconfig &&
        do_vcs "$SOURCE_REPO_FONTCONFIG"; then
        do_uninstall include/fontconfig "${_check[@]}"
        do_pacman_install gperf
        extracommands=()
        [[ $standalone = y ]] || extracommands+=(-Dtools=disabled)
        [[ $ffmpeg = sharedlibs ]] && extracommands+=(--default-both-libraries=both)
        do_mesoninstall global -D{doc,tests}=disabled -Diconv=enabled "${extracommands[@]}"
        do_checkIfExist
        unset extracommands
    fi
    # Prevents ffmpeg from trying to link to a broken libfontconfig.dll.a
    [[ $ffmpeg = sharedlibs ]] || do_uninstall bin-global/libfontconfig-1.dll libfontconfig.dll.a

    _deps=(libfreetype.a)
    _check=(libharfbuzz.a harfbuzz.pc)
    [[ $ffmpeg = sharedlibs ]] && _check+=(libharfbuzz.dll.a bin-video/libharfbuzz-{subset-,}0.dll)
    if do_vcs "$SOURCE_REPO_HARFBUZZ"; then
        do_pacman_install ragel
        do_uninstall include/harfbuzz "${_check[@]}" libharfbuzz{-subset,}.la
        extracommands=(-D{glib,gobject,cairo,icu,tests,introspection,docs,benchmark}"=disabled")
        [[ $ffmpeg = sharedlibs ]] && extracommands+=(--default-library=both)
        do_mesoninstall global "${extracommands[@]}"
        # directwrite shaper doesn't work with mingw headers, maybe too old
        [[ $ffmpeg = sharedlibs ]] && do_install "$LOCALDESTDIR"/bin-global/libharfbuzz-{subset-,}0.dll bin-video/
        do_checkIfExist
        unset extracommands
    fi

    _check=(libfribidi.a fribidi.pc)
    [[ $standalone = y ]] && _check+=(bin-video/fribidi.exe)
    [[ $ffmpeg = sharedlibs ]] && _check+=(bin-video/libfribidi-0.dll libfribidi.dll.a)
    if do_vcs "$SOURCE_REPO_FRIBIDI"; then
        do_patch "https://raw.githubusercontent.com/m-ab-s/mabs-patches/master/fribidi/0001-bin-only-use-vendored-getopt-if-not-provided.patch" am
        extracommands=("-Ddocs=false" "-Dtests=false")
        [[ $standalone = n ]] && extracommands+=("-Dbin=false")
        [[ $ffmpeg = sharedlibs ]] && extracommands+=(--default-library=both)
        do_mesoninstall video "${extracommands[@]}"
        do_checkIfExist
        unset extracommands
    fi

    _check=(ass/ass{,_types}.h libass.{{,l}a,pc})
    _deps=(lib{freetype,fontconfig,harfbuzz,fribidi}.a)
    [[ $ffmpeg = sharedlibs ]] && _check+=(bin-video/libass-9.dll libass.dll.a)
    if do_vcs "$SOURCE_REPO_LIBASS"; then
        do_autoreconf
        do_uninstall bin{,-video}/libass-9.dll libass.dll.a include/ass "${_check[@]}"
        extracommands=()
        enabled_any {lib,}fontconfig || extracommands+=(--disable-fontconfig)
        [[ $ffmpeg = sharedlibs ]] && extracommands+=(--disable-fontconfig --enable-shared)
        do_separate_confmakeinstall video "${extracommands[@]}"
        [[ $ffmpeg = sharedlibs ]] && do_install "$LOCALDESTDIR"/bin/libass-9.dll bin-video/
        do_checkIfExist
        unset extracommands
    fi
    if [[ $ffmpeg != sharedlibs && $ffmpeg != shared ]]; then
        _libs=(lib{freetype,harfbuzz{-subset,},fribidi,ass}.dll.a
            libav{codec,device,filter,format,util,resample}.dll.a
            lib{sw{scale,resample},postproc}.dll.a)
        for _lib in "${_libs[@]}"; do
            rm -f "$LOCALDESTDIR/lib/$_lib"
        done
        unset _lib _libs
    fi
fi

[[ $ffmpeg != no ]] && enabled gcrypt && do_pacman_install libgcrypt

if [[ $curl = y ]]; then
    enabled libtls && curl=libressl
    enabled openssl && curl=openssl
    enabled gnutls && curl=gnutls
    enabled mbedtls && curl=mbedtls
    [[ $curl = y ]] && curl=schannel
fi

if enabled_any gnutls librtmp || [[ $rtmpdump = y || $curl = gnutls ]]; then
    do_pacman_install nettle
    grep_and_sed '__declspec(__dllimport__)' "$MINGW_PREFIX"/include/gmp.h \
        's|__declspec\(__dllimport__\)||g' "$MINGW_PREFIX"/include/gmp.h
    _check=(libgnutls.{,l}a gnutls.pc)
    _gnutls_ver=3.8.9
    _gnutls_hash=69e113d802d1670c4d5ac1b99040b1f2d5c7c05daec5003813c049b5184820ed
    if do_pkgConfig "gnutls = $_gnutls_ver" && do_wget -h $_gnutls_hash \
        "https://www.gnupg.org/ftp/gcrypt/gnutls/v${_gnutls_ver%.*}/gnutls-${_gnutls_ver}.tar.xz"; then
        do_uninstall include/gnutls "${_check[@]}"
        grep_or_sed crypt32 lib/gnutls.pc.in 's/Libs.private.*/& -lcrypt32/'
        CFLAGS="-Wno-int-conversion" \
            do_separate_confmakeinstall \
            --disable-{cxx,doc,tools,tests,nls,rpath,libdane,guile,gcc-warnings} \
            --without-{p11-kit,idn,tpm} --enable-local-libopts \
            --with-included-unistring --disable-code-coverage \
            LDFLAGS="$LDFLAGS -L${LOCALDESTDIR}/lib -L${MINGW_PREFIX}/lib"
        do_checkIfExist
    fi
fi

if [[ $curl = openssl ]] || { [[ $ffmpeg != no ]] && enabled openssl; }; then
    do_pacman_install openssl
fi
hide_libressl -R
if [[ $curl = libressl ]] || { [[ $ffmpeg != no ]] && enabled libtls; }; then
    _check=(tls.h lib{crypto,ssl,tls}.{pc,{,l}a} openssl.pc)
    [[ $standalone = y ]] && _check+=(bin-global/openssl.exe)
    if do_vcs "$SOURCE_REPO_LIBRESSL" libressl; then
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

if [[ $mediainfo = y || $bmx = y || $curl != n ]]; then
    do_pacman_install libunistring
    grep_and_sed dllimport "$MINGW_PREFIX"/include/unistring/woe32dll.h \
        's|__declspec \(dllimport\)||g' "$MINGW_PREFIX"/include/unistring/woe32dll.h
    _deps=("$MINGW_PREFIX/lib/libunistring.a")
    _check=(libidn2.{{,l}a,pc} idn2.h)
    [[ $standalone == y ]] && _check+=(bin-global/idn2.exe)
    if do_pkgConfig "libidn2 = 2.3.8" &&
        do_wget -h f557911bf6171621e1f72ff35f5b1825bb35b52ed45325dcdee931e5d3c0787a \
        "https://ftp.gnu.org/gnu/libidn/libidn2-2.3.8.tar.gz"; then
        do_uninstall "${_check[@]}"
        do_pacman_install gtk-doc
        [[ $standalone == y ]] || sed -ri 's|(bin_PROGRAMS = ).*|\1|g' src/Makefile.am
        # unistring also depends on iconv
        grep_or_sed '@LTLIBUNISTRING@ @LTLIBICONV@' libidn2.pc.in \
            's|(@LTLIBICONV@) (@LTLIBUNISTRING@)|\2 \1|'
        AUTOPOINT=true do_autoreconf
        do_separate_confmakeinstall global --disable-{doc,rpath,nls}
        do_checkIfExist
    fi
    _deps=(libidn2.a)
    _check=(libpsl.{{,l}a,h,pc})
    [[ $standalone == y ]] && _check+=(bin-global/psl.exe)
    if do_pkgConfig "libpsl = 0.21.5" &&
        do_wget -h 1dcc9ceae8b128f3c0b3f654decd0e1e891afc6ff81098f227ef260449dae208 \
        "https://github.com/rockdaboot/libpsl/releases/download/0.21.5/libpsl-0.21.5.tar.gz"; then
        do_uninstall "${_check[@]}"
        [[ $standalone == y ]] || sed -ri 's|(bin_PROGRAMS = ).*|\1|g' tools/Makefile.in
        grep_or_sed "Requires.private" libpsl.pc.in "/Libs:/ i\Requires.private: libidn2"
        CFLAGS+=" -DPSL_STATIC" do_separate_confmakeinstall global --disable-{nls,rpath,gtk-doc-html,man,runtime}
        do_checkIfExist
    fi
fi

if [[ $mediainfo = y || $bmx = y || $curl != n || $cyanrip = y ]]; then
    do_pacman_install brotli nghttp2
    _check=(curl/curl.h libcurl.{{,l}a,pc})
    case $curl in
    libressl) _deps=(libssl.a) ;;
    openssl) _deps=("$MINGW_PREFIX/lib/libssl.a") ;;
    gnutls) _deps=(libgnutls.a) ;;
    mbedtls) _deps=("$MINGW_PREFIX/lib/libmbedtls.a") ;;
    *) _deps=() ;;
    esac
    [[ $standalone = y || $curl != n ]] && _check+=(bin-global/curl.exe)
    if do_vcs "$SOURCE_REPO_CURL"; then
        do_uninstall include/curl bin-global/curl-config "${_check[@]}"
        extra_opts=()
        case $curl in
        libressl|openssl)
            extra_opts+=(--with-{nghttp2,openssl} --without-{gnutls,mbedtls})
            ;;
        mbedtls) extra_opts+=(--with-{mbedtls,nghttp2} --without-openssl) ;;
        gnutls) extra_opts+=(--with-gnutls --without-{nghttp2,mbedtls,openssl}) ;;
        *) extra_opts+=(--with-{schannel,winidn,nghttp2} --without-{gnutls,mbedtls,openssl});;
        esac
       
        [[ ! -f configure || configure.ac -nt configure ]] &&
            do_autoreconf
        [[ $curl = openssl ]] && hide_libressl
        hide_conflicting_libs
        CPPFLAGS+=" -DGNUTLS_INTERNAL_BUILD -DNGHTTP2_STATICLIB -DPSL_STATIC" \
            do_separate_confmakeinstall global "${extra_opts[@]}" \
            --without-{libssh2,random,ca-bundle,ca-path,librtmp} \
            --with-brotli --enable-sspi --disable-debug
        hide_conflicting_libs -R
        [[ $curl = openssl ]] && hide_libressl -R
        if [[ $curl != schannel ]]; then
            _notrequired=true
            cd_safe "build-$bits"
            PATH=/usr/bin log ca-bundle make ca-bundle
            unset _notrequired
            [[ -f lib/ca-bundle.crt ]] &&
                cp -f lib/ca-bundle.crt "$LOCALDESTDIR"/bin-global/curl-ca-bundle.crt
            cd_safe ..
        fi
        do_checkIfExist
    fi
fi

if [[ $exitearly = EE2 ]]; then
    do_simple_print -p '\n\t'"${orange}Exit due to env var MABS_EXIT_EARLY set to EE2"
    return
fi

if { { [[ $ffmpeg != no || $standalone = y ]] && enabled libtesseract; } ||
    { [[ $standalone = y ]] && enabled libwebp; }; }; then
    _check=(libglut.a glut.pc)
    if do_vcs "$SOURCE_REPO_LIBGLUT" freeglut; then
        do_uninstall lib/cmake/FreeGLUT include/GL "${_check[@]}"
        do_cmakeinstall -D{UNIX,FREEGLUT_BUILD_DEMOS,FREEGLUT_BUILD_SHARED_LIBS}=OFF -DFREEGLUT_REPLACE_GLUT=ON
        do_checkIfExist
    fi

    do_pacman_install libjpeg-turbo xz zlib zstd libdeflate
    _deps=(libglut.a "$zlib_dir"/lib/libz.a)
    _check=(libtiff{.a,-4.pc})
    [[ $standalone = y ]] && _check+=(bin-global/tiff{cp,dump,info,set,split}.exe)
    if do_vcs "$SOURCE_REPO_LIBTIFF"; then
        do_patch "https://raw.githubusercontent.com/m-ab-s/mabs-patches/master/libtiff/0001-tiffgt-Link-winmm-if-windows.patch" am
        do_patch "https://raw.githubusercontent.com/m-ab-s/mabs-patches/master/libtiff/0002-tiffgt-link-gl-after-glut.patch" am
        do_uninstall lib/cmake/tiff "${_check[@]}"
        extracommands=("-Dtiff-tests=OFF" "-Dtiff-docs=OFF")
        if [[ $standalone = y ]]; then
            extracommands+=("-Dtiff-tools=ON")
        else
            extracommands+=("-Dtiff-tools=OFF")
        fi
        grep_or_sed 'Requires.private' libtiff-4.pc.in \
            '/Libs:/ a\Requires.private: libjpeg liblzma zlib libzstd glut'
        CFLAGS+=" -DFREEGLUT_STATIC" \
            do_cmakeinstall global -D{webp,jbig,lerc}=OFF "${extracommands[@]}"
        do_checkIfExist
        unset extracommands
    fi
fi

file_installed -s libtiff-4.pc &&
    grep_or_sed '-ldeflate' "$(file_installed libtiff-4.pc)" \
        's/Libs.private:.*/& -ldeflate/'

if [[ $ffmpeg != no || $standalone = y ]] && enabled libwebp; then
    do_pacman_install giflib
    _check=(libwebp{,mux}.{a,pc})
    [[ $standalone = y ]] && _check+=(libwebp{demux,decoder}.{a,pc}
    bin-global/{{c,d}webp,webpmux,img2webp}.exe)
    if do_vcs "$SOURCE_REPO_LIBWEBP"; then
        do_uninstall include/webp bin-global/gif2webp.exe "${_check[@]}"
        extracommands=("-DWEBP_BUILD_EXTRAS=OFF" "-DWEBP_BUILD_VWEBP=OFF")
        if [[ $standalone = y ]]; then
            extracommands+=(-DWEBP_BUILD_{{C,D,GIF2,IMG2}WEBP,ANIM_UTILS,WEBPMUX}"=ON")
        else
            extracommands+=(-DWEBP_BUILD_{{C,D,GIF2,IMG2,V}WEBP,ANIM_UTILS,WEBPMUX}"=OFF")
        fi
        CFLAGS+=" -DFREEGLUT_STATIC" \
            do_cmakeinstall global -DWEBP_ENABLE_SWAP_16BIT_CSP=ON "${extracommands[@]}"
        do_checkIfExist
        unset extracommands
    fi
fi

if [[ $jpegxl = y ]] || { [[ $ffmpeg != no ]] && enabled libjxl; }; then
    _check=(bin/gflags_completions.sh gflags.pc gflags/gflags.h libgflags{,_nothreads}.a)
    if do_vcs "$SOURCE_REPO_GFLAGS"; then
        do_patch "https://raw.githubusercontent.com/m-ab-s/mabs-patches/master/gflags/0001-cmake-chop-off-.lib-extension-from-shlwapi.patch" am
        do_uninstall "${_check[@]}" lib/cmake/gflags include/gflags
        do_cmakeinstall -D{BUILD,INSTALL}_STATIC_LIBS=ON -DBUILD_gflags_LIB=ON -DINSTALL_HEADERS=ON \
            -DREGISTER_{BUILD_DIR,INSTALL_PREFIX}=OFF
        do_checkIfExist
    fi

    do_pacman_install brotli lcms2
    _deps=(libgflags.a)
    _check=(libjxl{{,_threads}.a,.pc} jxl/decode.h)
    [[ $jpegxl = y ]] && _check+=(bin-global/{{c,d}jxl,{c,d}jpegli,jxlinfo}.exe)
    if do_vcs "$SOURCE_REPO_LIBJXL"; then
        do_git_submodule
        do_patch "https://raw.githubusercontent.com/m-ab-s/mabs-patches/master/libjxl/0001-brotli-link-enc-before-common.patch" am
        do_uninstall "${_check[@]}" include/jxl
        do_pacman_install asciidoc
        extracommands=()
        [[ $jpegxl = y ]] || extracommands=("-DJPEGXL_ENABLE_TOOLS=OFF")
        CXXFLAGS+=" -DJXL_CMS_STATIC_DEFINE -DJXL_STATIC_DEFINE -DJXL_THREADS_STATIC_DEFINE" \
            do_cmakeinstall global -D{BUILD_TESTING,JPEGXL_ENABLE_{BENCHMARK,DOXYGEN,MANPAGES,OPENEXR,SKCMS,EXAMPLES}}=OFF \
            -DJPEGXL_{FORCE_SYSTEM_{BROTLI,LCMS2},STATIC}=ON "${extracommands[@]}"
        do_checkIfExist
        unset extracommands
    fi
fi

if files_exist bin-video/OpenCL.dll; then
    opencldll=$LOCALDESTDIR/bin-video/OpenCL.dll
else
    syspath=$(cygpath -S)
    [[ $bits = 32bit && -d $syspath/../SysWOW64 ]] && syspath+=/../SysWOW64
    opencldll=$syspath/OpenCL.dll
    unset syspath
fi
if [[ $ffmpeg != no && -f $opencldll ]] && enabled opencl; then
    do_simple_print "${orange}FFmpeg and related apps will depend on OpenCL.dll$reset"
    do_pacman_remove opencl-headers
    do_pacman_install tools-git
    _check=(CL/cl.h)
    if do_vcs "$SOURCE_REPO_OPENCLHEADERS"; then
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
        [[ -f OpenCL.def ]] && do_dlltool libOpenCL.a OpenCL.def
        [[ -f libOpenCL.a ]] && do_install libOpenCL.a
        do_checkIfExist
    fi
else
    do_removeOption --enable-opencl
fi
unset opencldll

if [[ $ffmpeg != no || $standalone = y ]] && enabled libtesseract; then
    do_pacman_remove tesseract-ocr
    _check=(libleptonica.{,l}a lept.pc)
    if do_vcs "$SOURCE_REPO_LEPT"; then
        do_uninstall include/leptonica "${_check[@]}"
        [[ -f configure ]] || do_autogen
        do_separate_confmakeinstall --disable-programs --without-{lib{openjpeg,webp},giflib}
        do_checkIfExist
    fi

    do_pacman_install libarchive pango asciidoc
    _check=(libtesseract.{,l}a tesseract.pc)
    if do_vcs "$SOURCE_REPO_TESSERACT"; then
        do_pacman_install docbook-xsl omp
        # Reverts a commit that breaks the pkgconfig file
        {
            git revert --no-edit b4a4f5c || git revert --abort
        } > /dev/null 2>&1
        do_autogen
        _check+=(bin-global/tesseract.exe)
        do_uninstall include/tesseract "${_check[@]}"
        sed -i 's|Requires.private.*|& libarchive iconv libtiff-4|' tesseract.pc.in
        grep_or_sed ws2_32 "$MINGW_PREFIX/lib/pkgconfig/libarchive.pc" 's;Libs.private:.*;& -lws2_32;g'
        case $CC in
        *clang) sed -i -e 's|Libs.private.*|& -fopenmp=libomp|' tesseract.pc.in ;;
        *) sed -i -e 's|Libs.private.*|& -fopenmp -lgomp|' tesseract.pc.in ;;
        esac
        do_separate_confmakeinstall global --disable-{graphics,tessdata-prefix} \
            --without-curl \
            LIBLEPT_HEADERSDIR="$LOCALDESTDIR/include" \
            LIBS="$($PKG_CONFIG --libs iconv lept libtiff-4)" --datadir="$LOCALDESTDIR/bin-global"
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
fi

_check=(librubberband.a rubberband.pc rubberband/{rubberband-c,RubberBandStretcher}.h)
if { { [[ $ffmpeg != no ]] && enabled librubberband; } ||
    ! mpv_disabled rubberband; } &&
    do_vcs "$SOURCE_REPO_RUBBERBAND"; then
    do_uninstall "${_check[@]}"
    log "distclean" make distclean
    do_make PREFIX="$LOCALDESTDIR" install-static
    do_checkIfExist
fi

_check=(zimg{.h,++.hpp} libzimg.{,l}a zimg.pc)
if [[ $ffmpeg != no ]] && enabled libzimg &&
    do_vcs "$SOURCE_REPO_ZIMG"; then
    do_git_submodule
    do_uninstall "${_check[@]}"
    do_patch "https://raw.githubusercontent.com/m-ab-s/mabs-patches/master/zimg/0001-libm_wrapper-define-__CRT__NO_INLINE-before-math.h.patch" am
    do_autoreconf
    do_separate_confmakeinstall
    do_checkIfExist
fi

if [[ $exitearly = EE3 ]]; then
    do_simple_print -p '\n\t'"${orange}Exit due to env var MABS_EXIT_EARLY set to EE3"
    return
fi

set_title "compiling audio tools"
do_simple_print -p '\n\t'"${orange}Starting $bits compilation of audio tools${reset}"

if [[ $ffmpeg != no || $sox = y ]]; then
    do_pacman_install wavpack
    enabled_any libopencore-amr{wb,nb} && do_pacman_install opencore-amr
    if enabled libtwolame; then
        do_pacman_install twolame
        do_addOption --extra-cflags=-DLIBTWOLAME_STATIC
    fi
    enabled libmp3lame && do_pacman_install lame
fi

_check=(ilbc.h libilbc.{a,pc})
if [[ $ffmpeg != no ]] && enabled libilbc &&
    do_vcs "$SOURCE_REPO_LIBILBC"; then
    do_git_submodule
    do_uninstall "${_check[@]}"
    do_cmakeinstall -DUNIX=OFF
    do_checkIfExist
fi

_check=(libogg.{,l}a ogg/ogg.h ogg.pc)
if { [[ $flac = y ]] || enabled libvorbis; } &&
    do_vcs "$SOURCE_REPO_LIBOGG"; then
    do_uninstall include/ogg "${_check[@]}"
    do_autogen
    do_separate_confmakeinstall audio
    do_checkIfExist
fi

_check=(libvorbis{,enc,file}.{,l}a vorbis{,enc,file}.pc vorbis/vorbisenc.h)
if enabled libvorbis && do_vcs "$SOURCE_REPO_LIBVORBIS"; then
    do_uninstall include/vorbis "${_check[@]}"
    do_autogen
    do_separate_confmakeinstall audio --disable-docs
    do_checkIfExist
fi

_check=(libspeex.{,l}a speex.pc speex/speex.h)
[[ $standalone = y ]] && _check+=(bin-audio/speex{enc,dec}.exe)
if enabled libspeex && do_vcs "$SOURCE_REPO_SPEEX"; then
    do_pacman_remove speex
    do_uninstall include/speex "${_check[@]}"
    do_autogen
    extracommands=()
    [[ $standalone = y ]] || extracommands+=(--disable-binaries)
    do_separate_confmakeinstall audio --enable-vorbis-psy "${extracommands[@]}"
    do_checkIfExist
    unset extracommands
fi

_check=(libFLAC{,++}.a flac{,++}.pc)
[[ $standalone = y ]] && _check+=(bin-audio/flac.exe)
if [[ $flac = y ]]; then
    if do_vcs "$SOURCE_REPO_FLAC"; then
        if [[ $standalone = y ]]; then
            _check+=(bin-audio/metaflac.exe)
        fi
        do_uninstall include/FLAC{,++} share/aclocal/libFLAC{,++}.m4 "${_check[@]}"
        do_cmakeinstall audio -DBUILD_{DOCS,DOXYGEN,EXAMPLES,TESTING}=OFF -DINSTALL_MANPAGES=OFF
        do_checkIfExist
    fi
elif [[ $sox = y ]] || { [[ $standalone = y ]] && enabled_any libvorbis libopus; }; then
    do_pacman_install flac
    grep_and_sed dllimport "$MINGW_PREFIX"/include/FLAC++/export.h \
        's|__declspec\(dllimport\)||g' "$MINGW_PREFIX"/include/FLAC{,++}/export.h
fi
grep_and_sed dllimport "$LOCALDESTDIR"/include/FLAC++/export.h \
        's|__declspec\(dllimport\)||g' "$LOCALDESTDIR"/include/FLAC{,++}/export.h
grep_or_sed pthread "$LOCALDESTDIR/lib/pkgconfig/flac.pc" 's/Libs.private: /&-pthread /;s/Cflags: .*/& -pthread/'

_check=(libvo-amrwbenc.{,l}a vo-amrwbenc.pc)
if [[ $ffmpeg != no ]] && enabled libvo-amrwbenc &&
    do_pkgConfig "vo-amrwbenc = 0.1.3" &&
    do_wget_sf -h f63bb92bde0b1583cb3cb344c12922e0 \
        "opencore-amr/vo-amrwbenc/vo-amrwbenc-0.1.3.tar.gz"; then
    do_uninstall include/vo-amrwbenc "${_check[@]}"
    do_separate_confmakeinstall
    do_checkIfExist
fi

if { [[ $ffmpeg != no ]] && enabled libfdk-aac; } || [[ $fdkaac = y ]]; then
    _check=(libfdk-aac.{,l}a fdk-aac.pc)
    if do_vcs "$SOURCE_REPO_FDKAAC"; then
        do_autoreconf
        do_uninstall include/fdk-aac "${_check[@]}"
        CXXFLAGS+=" -fno-exceptions -fno-rtti" do_separate_confmakeinstall
        do_checkIfExist
    fi
    _check=(bin-audio/fdkaac.exe)
    _deps=(libfdk-aac.a)
    if [[ $standalone = y ]] &&
        do_vcs "$SOURCE_REPO_FDKAACEXE" bin-fdk-aac; then
        do_autoreconf
        do_uninstall "${_check[@]}"
        CFLAGS+=" $($PKG_CONFIG --cflags fdk-aac)" \
        LDFLAGS+=" $($PKG_CONFIG --cflags --libs fdk-aac)" \
            do_separate_confmakeinstall audio
        do_checkIfExist
    fi
fi

if [[ $faac = y ]]; then
    _check=(bin-audio/faac.exe)
    if ! [[ $standalone = y ]]; then
        do_pacman_install faac
    elif do_vcs "$SOURCE_REPO_FAAC"; then
        do_pacman_remove faac
        do_uninstall libfaac.a faac{,cfg}.h "${_check[@]}"
        log bootstrap ./bootstrap
        do_separate_confmakeinstall audio
        do_checkIfExist
    fi
fi

_check=(bin-audio/exhale.exe)
if [[ $exhale = y ]] &&
    do_vcs "$SOURCE_REPO_EXHALE"; then
    do_uninstall "${_check[@]}"
    _notrequired=true
    do_cmakeinstall audio
    do_checkIfExist
    unset _notrequired
fi

_check=(bin-audio/ogg{enc,dec}.exe)
_deps=(ogg.pc vorbis.pc)
if [[ $standalone = y ]] && enabled libvorbis &&
    do_vcs "$SOURCE_REPO_VORBIS_TOOLS"; then
    do_patch "https://raw.githubusercontent.com/m-ab-s/mabs-patches/master/vorbis-tools/0001-utf8-add-empty-convert_free_charset-for-Windows.patch" am
    do_autoreconf
    do_uninstall "${_check[@]}"
    extracommands=()
    enabled libspeex || extracommands+=(--without-speex)
    do_separate_conf --disable-{ogg123,vorbiscomment,vcut,ogginfo} \
        --with-lib{iconv,intl}-prefix="$MINGW_PREFIX" "${extracommands[@]}"
    do_make
    do_install oggenc/oggenc.exe oggdec/oggdec.exe bin-audio/
    do_checkIfExist
    unset extracommands
fi

_check=(libopus.{,l}a opus.pc opus/opus.h)
if enabled libopus && do_vcs "$SOURCE_REPO_OPUS"; then
    do_pacman_remove opus
    do_uninstall include/opus "${_check[@]}"
    (
        sha=$(grep dnn/download_model.sh autogen.sh | awk -F'"' '{print $2}')
        model=opus_data-${sha}.tar.gz
        pushd . > /dev/null
        [ -f "/build/$model" ] || do_wget -r -q -n "https://media.xiph.org/opus/models/$model"
        popd > /dev/null || return 1
        ln -s "$LOCALBUILDDIR/$model" .
    )
    do_autogen
    do_separate_confmakeinstall --disable-{stack-protector,doc,extra-programs}
    do_checkIfExist
fi

if [[ $standalone = y ]] && enabled libopus; then
    do_pacman_install openssl
    hide_libressl
    do_pacman_remove opusfile
    _check=(opus/opusfile.h libopus{file,url}.{,l}a opus{file,url}.pc)
    _deps=(ogg.pc opus.pc "$MINGW_PREFIX"/lib/pkgconfig/libssl.pc)
    if do_vcs "$SOURCE_REPO_OPUSFILE"; then
        do_uninstall "${_check[@]}"
        do_patch "https://raw.githubusercontent.com/m-ab-s/mabs-patches/master/opusfile/0001-Disable-cert-store-integration-if-OPENSSL_VERSION_NU.patch" am
        do_patch "https://raw.githubusercontent.com/m-ab-s/mabs-patches/master/opusfile/0002-configure-Only-add-std-c89-if-not-mingw-because-of-c.patch" am
        do_autogen
        do_separate_confmakeinstall --disable-{examples,doc}
        do_checkIfExist
    fi

    _check=(opus/opusenc.h libopusenc.{pc,{,l}a})
    _deps=(opus.pc)
    if do_vcs "$SOURCE_REPO_LIBOPUSENC"; then
        do_uninstall "${_check[@]}"
        do_autogen
        do_separate_confmakeinstall --disable-{examples,doc}
        do_checkIfExist
    fi

    _check=(bin-audio/opusenc.exe)
    _deps=(opusfile.pc libopusenc.pc)
    if do_vcs "$SOURCE_REPO_OPUSEXE"; then
        _check+=(bin-audio/opus{dec,info}.exe)
        do_uninstall "${_check[@]}"
        do_autogen
        do_separate_confmakeinstall audio
        do_checkIfExist
    fi
    hide_libressl -R
fi

_check=(soxr.h libsoxr.a)
if [[ $ffmpeg != no ]] && enabled libsoxr &&
    do_vcs "$SOURCE_REPO_LIBSOXR"; then
    do_uninstall "${_check[@]}"
    do_cmakeinstall -D{WITH_LSR_BINDINGS,BUILD_TESTS,WITH_OPENMP}=off
    do_checkIfExist
fi

_check=(libcodec2.a codec2.pc codec2/codec2.h)
if [[ $ffmpeg != no ]] && enabled libcodec2; then
    if do_vcs "$SOURCE_REPO_CODEC2"; then
        do_uninstall all include/codec2 "${_check[@]}"
        sed -i 's|if(WIN32)|if(FALSE)|g' CMakeLists.txt
        if enabled libspeex; then
            # rename same-named symbols copied from speex
            grep -ERl "\b(lsp|lpc)_to_(lpc|lsp)" --include="*.[ch]" | \
                xargs -r sed -ri "s;((lsp|lpc)_to_(lpc|lsp));c2_\1;g"
        fi
        do_cmakeinstall -D{UNITTEST,INSTALL_EXAMPLES}=off \
            -DCMAKE_INSTALL_BINDIR="$(pwd)/build-$bits/_bin"
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
        do_uninstall include/lame libmp3lame.{,l}a "${_check[@]}"
        _mingw_patches_lame="https://raw.githubusercontent.com/Alexpux/MINGW-packages/master/mingw-w64-lame"
        do_patch "$_mingw_patches_lame/0005-no-gtk.all.patch"
        do_patch "$_mingw_patches_lame/0006-dont-use-outdated-symbol-list.patch"
        do_patch "$_mingw_patches_lame/0007-revert-posix-code.patch"
        do_patch "$_mingw_patches_lame/0008-skip-termcap.patch"
        do_patch "https://raw.githubusercontent.com/m-ab-s/mabs-patches/master/lame/0001-libmp3lame-vector-Makefile.am-Add-msse-to-fix-i686-c.patch"
        do_autoreconf
        do_separate_conf --enable-nasm
        do_make
        do_install frontend/lame.exe bin-audio/
        do_checkIfExist
        unset _mingw_patches_lame
    fi
fi

_check=(libgme.{a,pc})
if [[ $ffmpeg != no ]] && enabled libgme && do_pkgConfig "libgme = 0.6.3" &&
    do_wget -h aba34e53ef0ec6a34b58b84e28bf8cfbccee6585cebca25333604c35db3e051d \
        "https://bitbucket.org/mpyne/game-music-emu/downloads/game-music-emu-0.6.3.tar.xz"; then
    do_uninstall include/gme "${_check[@]}"
    do_cmakeinstall -DENABLE_UBSAN=OFF
    do_checkIfExist
fi

_check=(libbs2b.{{,l}a,pc})
if [[ $ffmpeg != no ]] && enabled libbs2b && do_pkgConfig "libbs2b = 3.1.0" &&
    do_wget_sf -h c1486531d9e23cf34a1892ec8d8bfc06 "bs2b/libbs2b/3.1.0/libbs2b-3.1.0.tar.bz2"; then
    do_uninstall include/bs2b "${_check[@]}"
    # sndfile check is disabled since we don't compile binaries anyway
    grep -q sndfile configure && sed -i '20119,20133d' configure
    sed -i "s|bin_PROGRAMS = .*||" src/Makefile.in
    do_separate_confmakeinstall
    do_checkIfExist
fi

_check=(libsndfile.a sndfile.{h,pc})
if [[ $sox = y ]] && do_vcs "$SOURCE_REPO_SNDFILE" sndfile; then
    do_uninstall include/sndfile.hh "${_check[@]}"
    do_cmakeinstall -DBUILD_EXAMPLES=off -DBUILD_TESTING=off -DBUILD_PROGRAMS=OFF
    do_checkIfExist
fi

_check=(bin-audio/sox.exe sox.pc)
_deps=(libsndfile.a opus.pc "$MINGW_PREFIX"/lib/libmp3lame.a)
if [[ $sox = y ]]; then
    do_pacman_install libmad
    extracommands=()
    if enabled libopus; then
        [[ $standalone = y ]] || do_pacman_install opusfile
    else
        extracommands+=(--without-opus)
    fi
    if do_vcs "$SOURCE_REPO_SOX" sox; then
        do_patch "https://raw.githubusercontent.com/m-ab-s/mabs-patches/master/sox/0001-sox_version-fold-function-into-sox_version_info.patch" am
        do_patch "https://raw.githubusercontent.com/msys2/MINGW-packages/master/mingw-w64-sox/0001-ucrt-no-rewind-pipe.patch"
        do_uninstall sox.{pc,h} bin-audio/{soxi,play,rec}.exe libsox.{,l}a "${_check[@]}"
        do_autoreconf
        extralibs=(-lshlwapi -lz)
        enabled libmp3lame || extracommands+=(--without-lame)
        enabled_any libopencore-amr{wb,nb} &&
            extralibs+=(-lvo-amrwbenc) ||
            extracommands+=(--without-amr{wb,nb})
        enabled libtwolame &&
            extracommands+=(CFLAGS="$CFLAGS -DLIBTWOLAME_STATIC") ||
            extracommands+=(--without-twolame)
        enabled libvorbis || extracommands+=(--without-oggvorbis)
        hide_conflicting_libs
        sed -i 's|found_libgsm=yes|found_libgsm=no|g' configure
        do_separate_conf --disable-symlinks LIBS="-L$LOCALDESTDIR/lib ${extralibs[*]}" "${extracommands[@]}"
        do_make
        do_install src/sox.exe bin-audio/
        do_install sox.pc
        hide_conflicting_libs -R
        do_checkIfExist
        unset extralibs
    fi
    unset extracommands
fi

_check=(libopenmpt.{a,pc})
if [[ $ffmpeg != no ]] && enabled libopenmpt &&
    do_vcs "$SOURCE_REPO_LIBOPENMPT"; then
    do_uninstall include/libopenmpt "${_check[@]}"
    mkdir bin 2> /dev/null
    extracommands=("CONFIG=mingw64-win${bits%bit}" "AR=ar" "STATIC_LIB=1" "SHARED_LIB=0" "EXAMPLES=0" "OPENMPT123=0"
        "TEST=0" "OS=" "CC=$CC" "CXX=$CXX" "MINGW_COMPILER=${CC##* }")
    log clean make clean "${extracommands[@]}"
    do_makeinstall PREFIX="$LOCALDESTDIR" "${extracommands[@]}"
    sed -i 's/Libs.private.*/& -lrpcrt4/' "$LOCALDESTDIR/lib/pkgconfig/libopenmpt.pc"
    do_checkIfExist
    unset extracommands
fi

_check=(libmysofa.{a,pc} mysofa.h)
if [[ $ffmpeg != no ]] && enabled libmysofa &&
    do_vcs "$SOURCE_REPO_LIBMYSOFA"; then
    do_uninstall "${_check[@]}"
    do_cmakeinstall -DBUILD_TESTS=no -DCODE_COVERAGE=OFF
    do_checkIfExist
fi

_check=(libflite.a flite/flite.h)
if enabled libflite && do_vcs "$SOURCE_REPO_FLITE"; then
    do_patch "https://raw.githubusercontent.com/m-ab-s/mabs-patches/master/flite/0001-tools-find_sts_main.c-Include-windows.h-before-defin.patch" am
    do_uninstall libflite_cmu_{grapheme,indic}_{lang,lex}.a \
        libflite_cmu_us_{awb,kal,kal16,rms,slt}.a \
        libflite_{cmulex,usenglish,cmu_time_awb}.a "${_check[@]}" include/flite
    log clean make clean
    do_configure --bindir="$LOCALDESTDIR"/bin-audio --disable-shared \
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
if { { [[ $ffmpeg != no ]] &&
    enabled openal; } || mpv_enabled openal; } &&
    do_vcs "$SOURCE_REPO_OPENAL"; then
    do_uninstall "${_check[@]}"
    do_patch "https://raw.githubusercontent.com/m-ab-s/mabs-patches/master/openal-soft/0001-CMake-Fix-issues-for-mingw-w64.patch" am
    CC=${CC/ccache /}.bat CXX=${CXX/ccache /}.bat \
        do_cmakeinstall -DLIBTYPE=STATIC -DALSOFT_UTILS=OFF -DALSOFT_EXAMPLES=OFF
    sed -i 's/Libs.private.*/& -luuid -lole32/' "$LOCALDESTDIR/lib/pkgconfig/openal.pc" # uuid is for FOLDERID_* stuff
    do_checkIfExist
    unset _mingw_patches
fi

_check=(liblc3.a lc3.pc)
if [[ $ffmpeg != no ]] && enabled liblc3 &&
    do_vcs "$SOURCE_REPO_LIBLC3"; then
    do_uninstall "${_check[@]}"
    if [[ $standalone = y ]]; then
        _check+=(bin-audio/{d,e}lc3.exe)
        LDFLAGS+=" -lpthread" do_mesoninstall audio -Dtools=true
    else
        do_mesoninstall audio
    fi
    do_checkIfExist
fi

if [[ $exitearly = EE4 ]]; then
    do_simple_print -p '\n\t'"${orange}Exit due to env var MABS_EXIT_EARLY set to EE4"
    return
fi

set_title "compiling video tools"
do_simple_print -p '\n\t'"${orange}Starting $bits compilation of video tools${reset}"

_deps=(gnutls.pc)
_check=(librtmp.{a,pc})
[[ $rtmpdump = y || $standalone = y ]] && _check+=(bin-video/rtmpdump.exe)
if { [[ $rtmpdump = y ]] ||
    { [[ $ffmpeg != no ]] && enabled librtmp; }; } &&
    do_vcs "$SOURCE_REPO_LIBRTMP" librtmp; then
    [[ $rtmpdump = y || $standalone = y ]] && _check+=(bin-video/rtmp{suck,srv,gw}.exe)
    do_uninstall include/librtmp "${_check[@]}"
    [[ -f librtmp/librtmp.a ]] && log "clean" make clean

    _rtmp_pkgver() {
        printf '%s-%s-%s_%s-%s-static' \
            "$(grep -oP "(?<=^VERSION=).+" Makefile)" \
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
[[ $standalone = y || $av1an != n ]] && _check+=(bin-video/vpxenc.exe)
if { enabled libvpx || [[ $vpx = y ]]; } && do_vcs "$SOURCE_REPO_VPX" vpx; then
    do_pacman_install yasm
    extracommands=()
    [[ -f config.mk ]] && log "distclean" make distclean
    [[ $standalone = y || $av1an != n ]] && _check+=(bin-video/vpxdec.exe) ||
        extracommands+=(--disable-{examples,webm-io,libyuv,postproc})
    do_uninstall include/vpx "${_check[@]}"
    create_build_dir
    [[ $bits = 32bit ]] && arch=x86 || arch=x86_64
    [[ $ffmpeg = sharedlibs ]] || extracommands+=(--enable-{vp9-postproc,vp9-highbitdepth})
    get_external_opts extracommands
    config_path=.. do_configure --target="${arch}-win${bits%bit}-gcc" \
        --disable-{shared,unit-tests,docs,install-bins} \
        "${extracommands[@]}"
    sed -i 's;HAVE_GNU_STRIP=yes;HAVE_GNU_STRIP=no;' -- ./*.mk
    do_make
    do_makeinstall
    [[ $standalone = y || $av1an != n ]] && do_install vpx{enc,dec}.exe bin-video/
    do_checkIfExist
    unset extracommands
else
    pc_exists vpx || do_removeOption --enable-libvpx
fi

_check=(libvmaf.{a,pc} libvmaf/libvmaf.h)
if [[ $ffmpeg != no ]] && enabled libvmaf &&
    do_vcs "$SOURCE_REPO_LIBVMAF"; then
    do_uninstall share/model "${_check[@]}"
    do_pacman_install -m vim # for built_in_models
    cd_safe libvmaf
    CFLAGS="-msse2 -mfpmath=sse -mstackrealign $CFLAGS" do_mesoninstall video \
        -Denable_float=true -Dbuilt_in_models=true -Denable_tests=false
    do_checkIfExist
fi
file_installed -s libvmaf.dll.a && rm "$(file_installed libvmaf.dll.a)"

_check=(libaom.a aom.pc)
[[ $aom = y || $standalone = y || $av1an != n ]] && _check+=(bin-video/aom{dec,enc}.exe)
if { [[ $aom = y ]] || [[ $libavif = y ]] || { [[ $ffmpeg != no ]] && enabled libaom; }; } &&
    do_vcs "$SOURCE_REPO_LIBAOM"; then
    do_pacman_install yasm
    extracommands=()
    if [[ $aom = y || $standalone = y || $av1an != n ]]; then
        # fix google's shit
        sed -ri 's;_PREFIX.+CMAKE_INSTALL_BINDIR;_FULL_BINDIR;' \
            build/cmake/aom_install.cmake
    else
        extracommands+=("-DENABLE_EXAMPLES=off")
    fi
    do_uninstall include/aom "${_check[@]}"
    get_external_opts extracommands
    do_cmakeinstall video -DENABLE_{DOCS,TOOLS,TEST{S,DATA}}=off \
        -DENABLE_NASM=on -DFORCE_HIGHBITDEPTH_DECODING=0 "${extracommands[@]}"
    do_checkIfExist
    unset extracommands
fi

_check=(dav1d/dav1d.h dav1d.pc libdav1d.a)
[[ $standalone = y ]] && _check+=(bin-video/dav1d.exe)
if { [[ $dav1d = y ]] || [[ $libavif = y ]] || { [[ $ffmpeg != no ]] && enabled libdav1d; }; } &&
    do_vcs "$SOURCE_REPO_DAV1D"; then
    do_uninstall include/dav1d "${_check[@]}"
    extracommands=()
    [[ $standalone = y ]] || extracommands=("-Denable_tools=false")
    do_mesoninstall video -Denable_{tests,examples}=false "${extracommands[@]}"
    do_checkIfExist
    unset extracommands
fi

_check=()
{ [[ $rav1e = y ]] || [[ $av1an != n ]] ||
    { enabled librav1e && [[ $standalone = y ]]; } } &&
    _check+=(bin-video/rav1e.exe)
{ enabled librav1e || [[ $libavif = y ]]; } && _check+=(librav1e.a rav1e.pc rav1e/rav1e.h)
if { [[ $rav1e = y ]] || [[ $libavif = y ]] || enabled librav1e; } &&
    do_vcs "$SOURCE_REPO_LIBRAV1E"; then
    do_uninstall "${_check[@]}" include/rav1e

    # We want to hide libgit2 unless we have a static library
    _libgit2_pc="$MINGW_PREFIX/lib/pkgconfig/libgit2.pc"
    if ! [[ -f $MINGW_PREFIX/lib/libgit2.a ]]; then
        if  [[ -f $_libgit2_pc ]]; then
            mv -f "$_libgit2_pc"{,.dyn}
        fi
    else
        if ! [[ -f $_libgit2_pc ]]; then
            cp -f "$_libgit2_pc"{.dyn,}
        fi
    fi
    unset _libgit2_pc

    # standalone binary
    if [[ $rav1e = y || $standalone = y || $av1an != n ]]; then
        do_rust --profile release-no-lto
        find "target/$CARCH-pc-windows-gnu$rust_target_suffix" -name "rav1e.exe" | while read -r f; do
            do_install "$f" bin-video/
        done
    fi

    # C lib
    if [[ $libavif = y ]] || enabled librav1e; then
        rm -f "$CARGO_HOME/config" 2> /dev/null
        PKG_CONFIG="$LOCALDESTDIR/bin/ab-pkg-config-static.bat" \
            log "install-rav1e-c" cargo capi install \
            --release --jobs "$cpuCount" --prefix="$LOCALDESTDIR" \
            --destdir="$PWD/install-$bits"

        # do_install "install-$bits/bin/rav1e.dll" bin-video/
        # do_install "install-$bits/lib/librav1e.dll.a" lib/
        do_install "$(find "install-$bits/" -name "librav1e.a")" lib/
        do_install "$(find "install-$bits/" -name "rav1e.pc")" lib/pkgconfig/
        sed -i 's/\\/\//g' "$LOCALDESTDIR/lib/pkgconfig/rav1e.pc" >/dev/null 2>&1
        do_install "$(find "install-$bits/" -name "rav1e")"/*.h include/rav1e/
    fi

    do_checkIfExist
fi
# add allow-multiple-definition to the .pc file to fix linking with other rust libraries
sed -i 's/Libs.private:.*/& -Wl,--allow-multiple-definition/' "$LOCALDESTDIR/lib/pkgconfig/rav1e.pc" >/dev/null 2>&1

_check=(bin-video/SvtAv1EncApp.exe
    libSvtAv1Enc.a SvtAv1Enc.pc)
if [[ $bits = 32bit ]]; then
    do_removeOption --enable-libsvtav1
elif { [[ $svtav1 = y ]] || enabled libsvtav1; } &&
    do_vcs "$SOURCE_REPO_SVTAV1"; then
    do_uninstall include/svt-av1 "${_check[@]}" include/svt-av1
    do_cmakeinstall video -DUNIX=OFF -DENABLE_AVX512=ON
    do_checkIfExist
fi

if [[ $libavif = y ]]; then
    do_pacman_install libjpeg-turbo libyuv
    _check=(libavif.{a,pc} avif/avif.h)
    [[ $standalone = y ]] && _check+=(bin-video/avif{enc,dec}.exe)
    if { pc_exists "aom" || pc_exists "dav1d" || pc_exists "rav1e" || pc_exists "SvtAv1Enc"; } &&
        do_vcs "$SOURCE_REPO_LIBAVIF"; then
        # chop off any .lib suffixes that is attached to a library name
        grep_and_sed '\.lib' CMakeLists.txt 's|(\w)\.lib\b|\1|g'
        do_uninstall "${_check[@]}"
        extracommands=()
        pc_exists "dav1d" && extracommands+=("-DAVIF_CODEC_DAV1D=SYSTEM")
        pc_exists "rav1e" && extracommands+=("-DAVIF_CODEC_RAV1E=SYSTEM")
        pc_exists "aom" && extracommands+=("-DAVIF_CODEC_AOM=SYSTEM")
        pc_exists "SvtAv1Enc" && extracommands+=("-DAVIF_CODEC_SVT=SYSTEM")
        case $standalone in
        y) extracommands+=("-DAVIF_BUILD_APPS=ON") ;;
        *) extracommands+=("-DAVIF_BUILD_APPS=OFF") ;;
        esac
        do_cmakeinstall video -DAVIF_ENABLE_WERROR=OFF "${extracommands[@]}"
        do_checkIfExist
        unset extracommands
    fi
fi

_check=(libkvazaar.{,l}a kvazaar.pc kvazaar.h)
[[ $standalone = y ]] && _check+=(bin-video/kvazaar.exe)
if { [[ $other265 = y ]] || { [[ $ffmpeg != no ]] && enabled libkvazaar; }; } &&
    do_vcs "$SOURCE_REPO_LIBKVAZAAR"; then
    do_patch "https://github.com/m-ab-s/mabs-patches/raw/master/kvazaar/0001-Mingw-w64-Re-enable-avx2.patch" am
    do_uninstall kvazaar_version.h "${_check[@]}"
    do_autogen
    [[ $standalone = y || $other265 = y ]] ||
        sed -i "s|bin_PROGRAMS = .*||" src/Makefile.in
    CFLAGS+=" -fno-asynchronous-unwind-tables -DKVZ_BIT_DEPTH=10" \
        do_separate_confmakeinstall video
    do_checkIfExist
fi

_check=(libSDL2{,_test,main}.a sdl2.pc SDL2/SDL.h)
if { { [[ $ffmpeg != no ]] &&
    { enabled sdl2 || ! disabled_any sdl2 autodetect; }; } ||
    mpv_enabled sdl2; } &&
    do_vcs "$SOURCE_REPO_SDL2"; then
    do_uninstall include/SDL2 lib/cmake/SDL2 bin/sdl2-config "${_check[@]}"
    do_autogen
    sed -i 's|__declspec(dllexport)||g' include/{begin_code,SDL_opengl}.h
    do_separate_confmakeinstall
    do_checkIfExist
fi

_check=(libdvdread.{,l}a dvdread.pc)
if { { [[ $ffmpeg != no ]] && enabled_any libdvdread libdvdnav; } ||
    [[ $mplayer = y ]] || mpv_enabled dvdnav; } &&
    do_vcs "$SOURCE_REPO_LIBDVDREAD" dvdread; then
    do_autoreconf
    do_uninstall include/dvdread "${_check[@]}"
    do_separate_confmakeinstall
    do_checkIfExist
fi
[[ -f $LOCALDESTDIR/lib/pkgconfig/dvdread.pc ]] &&
    grep_or_sed "Libs.private" "$LOCALDESTDIR"/lib/pkgconfig/dvdread.pc \
        "/Libs:/ a\Libs.private: -ldl -lpsapi"

_check=(libdvdnav.{,l}a dvdnav.pc)
_deps=(libdvdread.a)
if { { [[ $ffmpeg != no ]] && enabled libdvdnav; } ||
    [[ $mplayer = y ]] || mpv_enabled dvdnav; } &&
    do_vcs "$SOURCE_REPO_LIBDVDNAV" dvdnav; then
    do_autoreconf
    do_uninstall include/dvdnav "${_check[@]}"
    do_separate_confmakeinstall
    do_checkIfExist
fi

if { [[ $ffmpeg != no ]] && enabled_any gcrypt libbluray; } ||
    ! mpv_disabled libbluray; then
    do_pacman_install libgcrypt
    grep_or_sed ws2_32 "$MINGW_PREFIX/bin/libgcrypt-config" 's;-lgpg-error;& -lws2_32;'
    grep_or_sed ws2_32 "$MINGW_PREFIX/bin/gpg-error-config" 's;-lgpg-error;& -lws2_32;'
fi

if { [[ $ffmpeg != no ]] && enabled libbluray; } || ! mpv_disabled libbluray; then
    _check=(bin-video/libaacs.dll libaacs.{{,l}a,pc} libaacs/aacs.h)
    if do_vcs "$SOURCE_REPO_LIBAACS"; then
        do_pacman_install -m bison flex
        sed -ri 's;bin_PROGRAMS.*;bin_PROGRAMS = ;' Makefile.am
        do_autoreconf
        do_uninstall "${_check[@]}" include/libaacs
        do_separate_confmakeinstall video --enable-shared --with-libgcrypt-prefix="$MINGW_PREFIX"
        mv -f "$LOCALDESTDIR/bin/libaacs-0.dll" "$LOCALDESTDIR/bin-video/libaacs.dll"
        rm -f "$LOCALDESTDIR/bin-video/${MINGW_CHOST}-aacs_info.exe"
        do_checkIfExist
    fi

    _check=(bin-video/libbdplus.dll libbdplus.{{,l}a,pc} libbdplus/bdplus.h)
    if do_vcs "$SOURCE_REPO_LIBBDPLUS"; then
        sed -ri 's;noinst_PROGRAMS.*;noinst_PROGRAMS = ;' Makefile.am
        do_autoreconf
        do_uninstall "${_check[@]}" include/libbdplus
        do_separate_confmakeinstall video --enable-shared
        mv -f "$LOCALDESTDIR/bin/libbdplus-0.dll" "$LOCALDESTDIR/bin-video/libbdplus.dll"
        do_checkIfExist
    fi
fi

_check=(libbluray.{{,l}a,pc})
if { { [[ $ffmpeg != no ]] && enabled libbluray; } || ! mpv_disabled libbluray; } &&
    do_vcs "$SOURCE_REPO_LIBBLURAY"; then
    [[ -f contrib/libudfread/.git ]] || do_git_submodule
    do_patch "https://raw.githubusercontent.com/m-ab-s/mabs-patches/master/libbluray/0001-dec-prefix-with-libbluray-for-now.patch" am
    do_autoreconf
    do_uninstall include/libbluray share/java "${_check[@]}"
    sed -i 's|__declspec(dllexport)||g' jni/win32/jni_md.h
    extracommands=()
    log javahome get_java_home
    OLD_PATH=$PATH
    if [[ -n $JAVA_HOME ]]; then
        if [[ ! -f /opt/apache-ant/bin/ant ]] ; then
            apache_ant_ver=$(clean_html_index "https://www.apache.org/dist/ant/binaries/")
            apache_ant_ver=$(get_last_version "$apache_ant_ver" "apache-ant" "1\.\d+\.\d+")
            if do_wget -r -c \
                "https://www.apache.org/dist/ant/binaries/apache-ant-${apache_ant_ver:-1.10.6}-bin.zip" \
                apache-ant.zip; then
                rm -rf /opt/apache-ant
                mv apache-ant /opt/apache-ant
            fi
        fi
        PATH=/opt/apache-ant/bin:$JAVA_HOME/bin:$PATH
        log ant-diagnostics ant -diagnostics
        export JDK_HOME=''
        export JAVA_HOME
    else
        extracommands+=(--disable-bdjava-jar)
    fi
    if enabled libxml2; then
        sed -ri 's;(Cflags.*);\1 -DLIBXML_STATIC;' src/libbluray.pc.in
    else
        extracommands+=(--without-libxml2)
    fi
    CFLAGS+=" $(enabled libxml2 && echo "-DLIBXML_STATIC")" \
        do_separate_confmakeinstall --disable-{examples,doxygen-doc} \
        --without-{fontconfig,freetype} "${extracommands[@]}"
    do_checkIfExist
    PATH=$OLD_PATH
    unset extracommands JDK_HOME JAVA_HOME OLD_PATH
fi

_check=(libxavs.a xavs.{h,pc})
if [[ $ffmpeg != no ]] && enabled libxavs && do_pkgConfig "xavs = 0.1." "0.1" &&
    do_vcs "$SOURCE_REPO_XAVS"; then
    do_pacman_install yasm
    do_patch "https://github.com/Distrotech/xavs/pull/1.patch" am
    [[ -f libxavs.a ]] && log "distclean" make distclean
    do_uninstall "${_check[@]}"
    sed -i 's|"NUL"|"/dev/null"|g' configure
    do_configure
    do_make libxavs.a
    for _file in xavs.h libxavs.a xavs.pc; do do_install "$_file"; done
    do_checkIfExist
    unset _file
fi

_check=(libxavs2.a xavs2_config.h xavs2.{h,pc})
[[ $standalone = y ]] && _check+=(bin-video/xavs2.exe)
if [[ $bits = 32bit ]]; then
    do_removeOption --enable-libxavs2
elif { [[ $avs2 = y ]] || { [[ $ffmpeg != no ]] && enabled libxavs2; }; } &&
    do_vcs "$SOURCE_REPO_XAVS2"; then
    do_patch "https://github.com/pkuvcl/xavs2/compare/master...1480c1:xavs2:gcc14/pointerconversion.patch" am
    cd_safe build/linux
    [[ -f config.mak ]] && log "distclean" make distclean
    do_uninstall all "${_check[@]}"
    do_configure --bindir="$LOCALDESTDIR"/bin-video --enable-static --enable-strip
    do_makeinstall
    do_checkIfExist
fi

_check=(libdavs2.a davs2_config.h davs2.{h,pc})
[[ $standalone = y ]] && _check+=(bin-video/davs2.exe)
if [[ $bits = 32bit ]]; then
    do_removeOption --enable-libdavs2
elif { [[ $avs2 = y ]] || { [[ $ffmpeg != no ]] && enabled libdavs2; }; } &&
    do_vcs "$SOURCE_REPO_DAVS"; then
    cd_safe build/linux
    [[ -f config.mak ]] && log "distclean" make distclean
    do_uninstall all "${_check[@]}"
    do_configure --bindir="$LOCALDESTDIR"/bin-video --enable-strip
    do_makeinstall
    do_checkIfExist
fi

_check=(libuavs3d.a uavs3d.{h,pc})
[[ $standalone = y ]] && _check+=(bin-video/uavs3dec.exe)
if [[ $ffmpeg != no ]] && enabled libuavs3d &&
    do_vcs "$SOURCE_REPO_UAVS3D"; then
    do_cmakeinstall
    [[ $standalone = y ]] && do_install uavs3dec.exe bin-video/
    do_checkIfExist
fi

_check=(libdovi.a libdovi/rpu_parser.h dovi.pc bin-video/dovi_tool.exe)
if [[ $dovitool = y ]] &&
    do_vcs "$SOURCE_REPO_DOVI_TOOL"; then
    do_uninstall "${_check[@]}" include/libdovi bin-video/dovi.dll dovi.def dovi.dll.a
    do_rust
    do_install "target/$CARCH-pc-windows-gnu$rust_target_suffix/release/dovi_tool.exe" bin-video/
    cd_safe dolby_vision
    do_rustcinstall --bindir="$LOCALDESTDIR"/bin-video/ --library-type=staticlib
    do_checkIfExist
fi

_check=(bin-video/hdr10plus_tool.exe)
if [[ $hdr10plustool = y ]] &&
    do_vcs "$SOURCE_REPO_HDR10PLUS_TOOL"; then
    do_uninstall "${_check[@]}"
    do_rust
    do_install "target/$CARCH-pc-windows-gnu$rust_target_suffix/release/hdr10plus_tool.exe" bin-video/
    do_checkIfExist
fi

if [[ $mediainfo = y ]]; then
    [[ $curl = openssl ]] && hide_libressl
    _check=(libzen.{a,pc})
    if do_vcs "$SOURCE_REPO_LIBZEN" libzen; then
        do_uninstall include/ZenLib bin-global/libzen-config \
            "${_check[@]}" libzen.la lib/cmake/zenlib
        do_cmakeinstall Project/CMake
        do_checkIfExist
    fi
    fix_cmake_crap_exports "$LOCALDESTDIR/lib/cmake/zenlib"

    sed -i 's;message(FATAL_ERROR "The imported target;message(WARNING "The imported target;' \
        "$MINGW_PREFIX"/lib/cmake/CURL/CURLTargets.cmake
    _check=(libmediainfo.{a,pc})
    _deps=(lib{zen,curl}.a)
    if do_vcs "$SOURCE_REPO_LIBMEDIAINFO" libmediainfo; then
        do_uninstall include/MediaInfo{,DLL} bin-global/libmediainfo-config \
            "${_check[@]}" libmediainfo.la lib/cmake/mediainfolib
        CFLAGS+=" $($PKG_CONFIG --cflags libzen)" \
        LDFLAGS+=" $($PKG_CONFIG --cflags --libs libzen)" \
            do_cmakeinstall Project/CMake -DBUILD_ZLIB=off -DBUILD_ZENLIB=off
        do_checkIfExist
    fi
    fix_cmake_crap_exports "$LOCALDESTDIR/lib/cmake/mediainfolib"

    _check=(bin-video/mediainfo.exe)
    _deps=(libmediainfo.a)
    if do_vcs "$SOURCE_REPO_MEDIAINFO" mediainfo; then
        cd_safe Project/GNU/CLI
        do_autogen
        do_uninstall "${_check[@]}"
        [[ -f Makefile ]] && log distclean make distclean
        do_configure --disable-shared --bindir="$LOCALDESTDIR/bin-video" \
            --enable-staticlibs
        do_makeinstall
        do_checkIfExist
    fi
    [[ $curl = openssl ]] && hide_libressl -R
fi

if [[ $ffmpeg != no ]] && enabled libvidstab; then
    do_pacman_install omp
    _check=(libvidstab.a vidstab.pc)
    if do_vcs "$SOURCE_REPO_VIDSTAB" vidstab; then
        do_uninstall include/vid.stab "${_check[@]}"
        do_cmakeinstall
        do_checkIfExist
    fi
fi

_check=(libzvbi.{h,{,l}a} zvbi-0.2.pc)
if [[ $ffmpeg != no ]] && enabled libzvbi &&
    do_vcs "$SOURCE_REPO_ZVBI"; then
    do_uninstall "${_check[@]}" zvbi-0.2.pc
    do_autoreconf
    do_separate_conf --disable-{dvb,bktr,examples,nls,proxy,tests} --without-doxygen
    cd_safe src
    do_makeinstall
    cd_safe ..
    log pkgconfig make SUBDIRS=. install
    do_checkIfExist
    unset _vlc_zvbi_patches
fi

if [[ $ffmpeg != no ]] && enabled_any frei0r ladspa; then
    _check=(libdl.a dlfcn.h)
    if do_vcs "$SOURCE_REPO_DLFCN"; then
        do_uninstall "${_check[@]}"
        do_cmakeinstall
        do_checkIfExist
    fi

    _check=(frei0r.{h,pc})
    if do_vcs "$SOURCE_REPO_FREI0R"; then
        sed -i 's/find_package (Cairo)//' "CMakeLists.txt"
        do_uninstall lib/frei0r-1 "${_check[@]}"
        do_pacman_install gavl
        do_cmakeinstall -DWITHOUT_OPENCV=on
        do_checkIfExist
    fi
fi

_check=(DeckLinkAPI.h DeckLinkAPIVersion.h DeckLinkAPI_i.c)
if [[ $ffmpeg != no ]] && enabled decklink &&
    do_vcs "$SOURCE_REPO_DECKLINK"; then
    do_makeinstall PREFIX="$LOCALDESTDIR"
    do_checkIfExist
fi

_check=(libvpl.a vpl.pc)
if [[ $ffmpeg != no ]] && enabled libvpl; then
    if enabled libmfx; then
        do_removeOption --enable-libmfx
    fi
    if do_vcs "$SOURCE_REPO_LIBVPL" libvpl; then
    if [[ $bits = 32bit ]]; then
        do_patch https://raw.githubusercontent.com/msys2/MINGW-packages/master/mingw-w64-libvpl/0003-cmake-fix-32bit-install.patch
    fi
    do_uninstall include/vpl "${_check[@]}"
    do_cmakeinstall -DUNIX=OFF
    do_checkIfExist
    fi
fi

_check=(libmfx.{{,l}a,pc})
if [[ $ffmpeg != no ]] && enabled libmfx &&
    do_vcs "$SOURCE_REPO_LIBMFX" libmfx; then
    do_autoreconf
    do_uninstall include/mfx "${_check[@]}"
    do_separate_confmakeinstall
    do_checkIfExist
fi

_check=(AMF/core/Version.h)
if [[ $ffmpeg != no ]] && { enabled amf || ! disabled_any autodetect amf; } &&
    do_vcs "$SOURCE_REPO_AMF"; then
    do_uninstall include/AMF
    cd_safe amf/public/include
    install -D -p -t "$LOCALDESTDIR/include/AMF/core" core/*.h
    install -D -p -t "$LOCALDESTDIR/include/AMF/components" components/*.h
    do_checkIfExist
fi

_check=(libgpac_static.a bin-video/{MP4Box,gpac}.exe)
if [[ $mp4box = y ]] && do_vcs "$SOURCE_REPO_GPAC"; then
    do_uninstall include/gpac "${_check[@]}"
    git grep -PIl "\xC2\xA0" | xargs -r sed -i 's/\xC2\xA0/ /g'
    # Disable passing rpath to the linker, as it's a no-op with ld, but an error with lld
    find . -name "Makefile" -exec grep -q rpath {} \; -exec sed -i '/^LINKFLAGS.*-rpath/s/^/#/' {} +
    LIBRARY_PATH="$(cygpath -pm "$LOCALDESTDIR/lib:$MINGW_PREFIX/lib")" \
        do_separate_conf --static-bin --static-build --static-modules
    do_make
    log "install" make install-lib
    do_install bin/gcc/MP4Box.exe bin/gcc/gpac.exe bin-video/
    do_checkIfExist
fi

_check=(SvtHevcEnc.pc libSvtHevcEnc.a svt-hevc/EbApi.h
    bin-video/SvtHevcEncApp.exe)
if [[ $bits = 32bit ]]; then
    do_removeOption --enable-libsvthevc
elif { [[ $svthevc = y ]] || enabled libsvthevc; } &&
    do_vcs "$SOURCE_REPO_SVTHEVC"; then
    do_uninstall "${_check[@]}" include/svt-hevc
    do_cmakeinstall video -DUNIX=OFF
    do_checkIfExist
fi

_check=(bin-video/SvtVp9EncApp.exe
    libSvtVp9Enc.a SvtVp9Enc.pc)
if [[ $bits = 32bit ]]; then
    do_removeOption --enable-libsvtvp9
elif { [[ $svtvp9 = y ]] || enabled libsvtvp9; } &&
    do_vcs "$SOURCE_REPO_SVTVP9"; then
    do_uninstall include/svt-vp9 "${_check[@]}" include/svt-vp9
    do_cmakeinstall video -DUNIX=OFF
    do_checkIfExist
fi

_check=(xvc.pc xvc{enc,dec}.h libxvc{enc,dec}.a bin-video/xvc{enc,dec}.exe)
if [[ $xvc == y ]] &&
    do_vcs "$SOURCE_REPO_XVC"; then
    do_uninstall "${_check[@]}"
    do_cmakeinstall video -DBUILD_TESTS=OFF -DENABLE_ASSERTIONS=OFF
    do_checkIfExist
fi

if [[ $x264 != no ]] ||
    { [[ $ffmpeg != no ]] && enabled libx264; }; then
    _check=(x264{,_config}.h libx264.a x264.pc)
    [[ $standalone = y || $av1an != n ]] && _check+=(bin-video/x264.exe)
    _bitdepth=$(get_api_version x264_config.h BIT_DEPTH)
    if do_vcs "$SOURCE_REPO_X264" ||
        [[ $x264 = o8   && $_bitdepth =~ (0|10) ]] ||
        [[ $x264 = high && $_bitdepth =~ (0|8) ]] ||
        [[ $x264 =~ (yes|full|shared|fullv) && "$_bitdepth" != 0 ]]; then

        extracommands=("--host=$MINGW_CHOST" "--prefix=$LOCALDESTDIR"
            "--bindir=$LOCALDESTDIR/bin-video")

        # light ffmpeg build
        old_PKG_CONFIG_PATH=$PKG_CONFIG_PATH
        PKG_CONFIG_PATH=$LOCALDESTDIR/opt/lightffmpeg/lib/pkgconfig:$MINGW_PREFIX/lib/pkgconfig
        unset_extra_script
        if [[ $standalone = y || $av1an != n ]] && [[ $x264 =~ (full|fullv) ]]; then
            _check=("$LOCALDESTDIR"/opt/lightffmpeg/lib/pkgconfig/libav{codec,format}.pc)
            do_vcs "$ffmpegPath"
            do_uninstall "$LOCALDESTDIR"/opt/lightffmpeg
            [[ -f config.mak ]] && log "distclean" make distclean
            create_build_dir light
            if [[ $x264 = fullv ]]; then
                mapfile -t audio_codecs < <(
                    sed -n '/audio codecs/,/external libraries/p' ../libavcodec/allcodecs.c |
                    sed -n 's/^[^#]*extern.* *ff_\([^ ]*\)_decoder;/\1/p')
                config_path=.. LDFLAGS+=" -L$MINGW_PREFIX/lib" \
                    do_configure "${FFMPEG_BASE_OPTS[@]}" \
                    --prefix="$LOCALDESTDIR/opt/lightffmpeg" \
                    --disable-{programs,devices,filters,encoders,muxers,debug,sdl2,network,protocols,doc} \
                    --enable-protocol=file,pipe \
                    --disable-decoder="$(IFS=, ; echo "${audio_codecs[*]}")" --enable-gpl \
                    --disable-bsf=aac_adtstoasc,text2movsub,noise,dca_core,mov2textsub,mp3_header_decompress \
                    --disable-autodetect --enable-{lzma,bzlib,zlib}
                unset audio_codecs
            else
                config_path=.. LDFLAGS+=" -L$MINGW_PREFIX/lib" \
                    do_configure "${FFMPEG_BASE_OPTS[@]}" \
                    --prefix="$LOCALDESTDIR/opt/lightffmpeg" \
                    --disable-{programs,devices,filters,encoders,muxers,debug,sdl2,doc} --enable-gpl
            fi
            do_makeinstall
            files_exist "${_check[@]}" && touch "build_successful${bits}_light"
            unset_extra_script

            _check=("$LOCALDESTDIR"/opt/lightffmpeg/lib/pkgconfig/ffms2.pc bin-video/ffmsindex.exe)
            if do_vcs "$SOURCE_REPO_FFMS2"; then
                do_uninstall "${_check[@]}"
                sed -i 's/Cflags.*/& -DFFMS_STATIC/' ffms2.pc.in
                do_patch "https://raw.githubusercontent.com/m-ab-s/mabs-patches/master/ffms2/0001-ffmsindex-fix-linking-issues.patch" am
                mkdir -p src/config
                do_autoreconf
                do_separate_confmakeinstall video --prefix="$LOCALDESTDIR/opt/lightffmpeg"
                do_checkIfExist
            fi
            cd_safe "$LOCALBUILDDIR"/x264-git
        else
            extracommands+=(--disable-lavf --disable-ffms)
        fi

        if [[ $standalone = y || $av1an != n ]]; then
            _check=("$LOCALDESTDIR/opt/lightffmpeg/lib/pkgconfig/liblsmash.pc")
            if do_vcs "$SOURCE_REPO_LIBLSMASH" liblsmash; then
                [[ -f config.mak ]] && log "distclean" make distclean
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
        [[ $standalone = y || $av1an != n ]] && _check+=(bin-video/x264.exe)
        [[ -f config.h ]] && log "distclean" make distclean

        x264_build=$(grep ' X264_BUILD ' x264.h | cut -d' ' -f3)
        if [[ $x264 = shared ]]; then
            extracommands+=(--enable-shared)
            _check+=(libx264.dll.a bin-video/libx264-"${x264_build}".dll)
        else
            extracommands+=(--enable-static)
            _check+=(libx264.a)
        fi

        case $x264 in
        high) extracommands+=("--bit-depth=10") ;;
        o8) extracommands+=("--bit-depth=8") ;;
        *) extracommands+=("--bit-depth=all") ;;
        esac

        do_uninstall "${_check[@]}"
        check_custom_patches
        create_build_dir
        extra_script pre configure
        PKGCONFIG="$PKG_CONFIG" CFLAGS="${CFLAGS// -O2 / }" \
            log configure ../configure "${extracommands[@]}"
        extra_script post configure
        do_make
        do_makeinstall
        do_checkIfExist
        PKG_CONFIG_PATH=$old_PKG_CONFIG_PATH
        unset extracommands x264_build old_PKG_CONFIG_PATH
    fi
    unset _bitdepth
else
    pc_exists x264 || do_removeOption --enable-libx264
fi

_check=(x265{,_config}.h libx265.a x265.pc)
[[ $standalone = y || $av1an != n ]] && _check+=(bin-video/x265.exe)
if [[ ! $x265 = n ]] && do_vcs "$SOURCE_REPO_X265"; then
    grep_and_sed CMAKE_CXX_IMPLICIT_LINK_LIBRARIES source/CMakeLists.txt 's|\$\{CMAKE_CXX_IMPLICIT_LINK_LIBRARIES\}||g'
    grep_or_sed cstdint source/dynamicHDR10/json11/json11.cpp "/cstdlib/ i\#include <cstdint>"
    do_uninstall libx265{_main10,_main12}.a bin-video/libx265_main{10,12}.dll "${_check[@]}"
    [[ $bits = 32bit ]] && assembly=-DENABLE_ASSEMBLY=OFF
    [[ $x265 = d ]] && xpsupport=-DWINXP_SUPPORT=ON

    build_x265() {
        create_build_dir
        local build_root=$PWD
        mkdir -p {8,10,12}bit

    do_x265_cmake() {
        do_print_progress "Building $1" && shift 1
        extra_script pre cmake
        log "cmake" cmake "$(get_first_subdir -f)/source" -G Ninja \
        -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
        -DCMAKE_INSTALL_PREFIX="$LOCALDESTDIR" -DBIN_INSTALL_DIR="$LOCALDESTDIR/bin-video" \
        -DENABLE_SHARED=OFF -DENABLE_CLI=OFF -DHIGH_BIT_DEPTH=ON \
        -DENABLE_HDR10_PLUS=ON $xpsupport -DCMAKE_CXX_COMPILER="$LOCALDESTDIR/bin/${CXX#ccache }.bat" \
        -DCMAKE_TOOLCHAIN_FILE="$LOCALDESTDIR/etc/toolchain.cmake" "$@"
        extra_script post cmake
        do_ninja
    }
    [[ $standalone = y || $av1an != n ]] && cli=-DENABLE_CLI=ON

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
    if [[ $standalone = y || $av1an != n ]] && [[ $x265 = d ]]; then
        cd_safe "$(get_first_subdir -f)"
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

_check=(xvid.h libxvidcore.a bin-video/xvid_encraw.exe)
if enabled libxvid && [[ $standalone = y ]] &&
    do_vcs "$SOURCE_REPO_XVID"; then
    do_pacman_install yasm
    do_patch "https://github.com/m-ab-s/xvid/compare/lighde.patch" am
    do_pacman_remove xvidcore
    do_uninstall "${_check[@]}"
    cd_safe xvidcore/build/generic
    log "bootstrap" ./bootstrap.sh
    do_configure
    do_make
    do_install ../../src/xvid.h include/
    do_install '=build/libxvidcore.a' libxvidcore.a
    do_install '=build/libxvidcore.dll' bin-video/
    cd_safe ../../examples
    do_make xvid_encraw
    do_install xvid_encraw.exe bin-video/
    do_checkIfExist
fi

_check=(ffnvcodec/nvEncodeAPI.h ffnvcodec.pc)
if [[ $ffmpeg != no ]] && { enabled ffnvcodec ||
    ! disabled_any ffnvcodec autodetect || ! mpv_disabled cuda-hwaccel; } &&
    do_vcs "$SOURCE_REPO_FFNVCODEC" ffnvcodec; then
    do_makeinstall PREFIX="$LOCALDESTDIR"
    do_checkIfExist
fi

if enabled libsrt; then
    do_pacman_install openssl
    _check=(libsrt.a srt.pc srt/srt.h)
    [[ $standalone = y ]] && _check+=(bin-video/srt-live-transmit.exe)
    if do_vcs "$SOURCE_REPO_SRT"; then
        hide_libressl
        do_cmakeinstall video -DENABLE_SHARED=off -DENABLE_SUFLIP=off \
            -DENABLE_EXAMPLES=off -DUSE_OPENSSL_PC=on -DUSE_STATIC_LIBSTDCXX=ON
        hide_libressl -R
        do_checkIfExist
    fi
fi

if enabled librist; then
    do_pacman_install cjson
    _check=(librist.{a,pc} librist/librist.h)
    [[ $standalone = y ]] && _check+=(bin-global/rist{sender,receiver,2rist,srppasswd}.exe)
    if do_vcs "$SOURCE_REPO_LIBRIST"; then
        do_uninstall include/librist "${_check[@]}"
        extracommands=("-Dbuiltin_cjson=false")
        [[ $standalone = y ]] || extracommands+=("-Dbuilt_tools=false")
        do_mesoninstall global -Dhave_mingw_pthreads=true -Dtest=false "${extracommands[@]}"
        do_checkIfExist
        unset extracommands
    fi
fi

_vapoursynth_install() {
    if [[ $bits = 32bit ]]; then
        do_simple_print "${orange}Vapoursynth is known to be broken on 32-bit and will be disabled"'!'"${reset}"
        return 1
    fi
    do_pacman_install tools-git
    _python_ver=3.12.10
    _python_lib=python312
    _vsver=70
    _check=("lib$_python_lib.a")
    if files_exist "${_check[@]}"; then
        do_print_status "python $_python_ver" "$green" "Up-to-date"
    elif do_wget "https://www.python.org/ftp/python/$_python_ver/python-$_python_ver-embed-amd64.zip"; then
        gendef "$_python_lib.dll" >/dev/null 2>&1
        do_dlltool "lib$_python_lib.a" "$_python_lib.def"
        [[ -f lib$_python_lib.a ]] && do_install "lib$_python_lib.a"
        do_checkIfExist
    fi

    _check=(lib{vapoursynth,vsscript}.a vapoursynth{,-script}.pc vapoursynth/{VS{Helper,Script},VapourSynth}.h)
    if pc_exists "vapoursynth = $_vsver" && files_exist "${_check[@]}"; then
        do_print_status "vapoursynth R$_vsver" "$green" "Up-to-date"
    elif do_wget "https://github.com/vapoursynth/vapoursynth/releases/download/R$_vsver/VapourSynth${bits%bit}-Portable-R$_vsver.zip"; then
        do_uninstall {vapoursynth,vsscript}.lib include/vapoursynth "${_check[@]}"
        do_install sdk/include/vapoursynth/*.h include/vapoursynth/

        # Extract the .dll from the pip wheel
        log "7z" 7z e -y -aoa wheel/VapourSynth-$_vsver-cp${_python_lib:6:3}-cp${_python_lib:6:3}-win_amd64.whl \
            VapourSynth-$_vsver.data/data/Lib/site-packages/vapoursynth.dll

        create_build_dir
        declare -A _pc_vars=(
            [vapoursynth-name]=vapoursynth
            [vapoursynth-description]='A frameserver for the 21st century'
            [vapoursynth-cflags]="-DVS_CORE_EXPORTS"

            [vsscript-name]=vapoursynth-script
            [vsscript-description]='Library for interfacing VapourSynth with Python'
            [vsscript-private]="-l$_python_lib"
        )
        for _file in vapoursynth vsscript; do
            gendef - "../$_file.dll" 2>/dev/null |
                sed -E 's|^_||;s|@[1-9]+$||' > "${_file}.def"
            do_dlltool "lib${_file}.a" "${_file}.def"
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
    unset _file _python_lib _python_ver _vsver _pc_vars
    return 0
}
if ! { { ! mpv_disabled vapoursynth || enabled vapoursynth || [[ $av1an != n ]]; } && _vapoursynth_install; }; then
    mpv_disable vapoursynth
    do_removeOption --enable-vapoursynth
fi

if [[ $av1an != n ]]; then
    local av1an_bindir="bin-video"
    local av1an_ffmpeg_prefix="opt/av1anffmpeg"
    [[ $av1an = shared ]] && av1an_bindir="bin-video/av1an/bin" && av1an_ffmpeg_prefix="bin-video/av1an"

    _check=("$LOCALDESTDIR"/"$av1an_ffmpeg_prefix"/lib/pkgconfig/lib{av{codec,device,filter,format,util},swscale}.pc)
    if flavor=av1an do_vcs "https://git.ffmpeg.org/ffmpeg.git#branch=release/7.1"; then
        do_uninstall "$LOCALDESTDIR"/"$av1an_ffmpeg_prefix"
        [[ -f config.mak ]] && log "distclean" make distclean
        local av1an_ffmpeg_opts=("--enable-static" "--disable-shared")
        [[ $av1an = shared ]] && av1an_ffmpeg_opts=("--disable-static" "--enable-shared")
        # compile ffmpeg executable if ffmpeg is disabled so av1an can function
        if [[ $ffmpeg != no ]]; then
            av1an_ffmpeg_opts+=("--disable-programs")
        else
            # enable filters too so they can be used with av1an
            av1an_ffmpeg_opts+=("--disable-ffprobe" "--disable-ffplay" "--enable-filters")
        fi
        create_build_dir av1an
        config_path=.. do_configure "${FFMPEG_BASE_OPTS[@]}" \
            --prefix="$LOCALDESTDIR/$av1an_ffmpeg_prefix" \
            --disable-autodetect --disable-everything \
            --disable-{debug,doc,postproc,network} \
            --enable-{decoders,demuxers,protocols} \
            "${av1an_ffmpeg_opts[@]}"
        do_make && do_makeinstall
        # move static ffmpeg to a reasonable location if ffmpeg is disabled
        [[ $av1an != shared ]] && [[ $ffmpeg = no ]] && [[ ! -f "$LOCALDESTDIR"/bin-video/ffmpeg.exe ]] &&
            mv -f "$LOCALDESTDIR"/{"$av1an_ffmpeg_prefix"/bin,bin-video}/ffmpeg.exe
        files_exist "${_check[@]}" && touch ../"build_successful${bits}_av1an"
        unset av1an_ffmpeg_opts
    fi

    old_PKG_CONFIG_PATH=$PKG_CONFIG_PATH
    PKG_CONFIG_PATH=$LOCALDESTDIR/$av1an_ffmpeg_prefix/lib/pkgconfig:$PKG_CONFIG_PATH

    _check=("$av1an_bindir"/av1an.exe)
    if do_vcs "$SOURCE_REPO_AV1AN"; then
        do_uninstall "${_check[@]}"
        do_pacman_install clang
        PKG_CONFIG="$LOCALDESTDIR/bin/ab-pkg-config-static.bat" \
            VAPOURSYNTH_LIB_DIR="$LOCALDESTDIR/lib" do_rust
        do_install "target/$CARCH-pc-windows-gnu$rust_target_suffix/release/av1an.exe" $av1an_bindir/
        do_checkIfExist
    fi

    PKG_CONFIG_PATH=$old_PKG_CONFIG_PATH
    unset old_PKG_CONFIG_PATH av1an_{bindir,ffmpeg_prefix}
fi

if [[ $ffmpeg != no ]] && enabled liblensfun; then
    do_pacman_install glib2
    grep_or_sed liconv "$MINGW_PREFIX/lib/pkgconfig/glib-2.0.pc" 's;-lintl;& -liconv;g'
    _check=(liblensfun.a lensfun.pc lensfun/lensfun.h)
    if do_vcs "$SOURCE_REPO_LENSFUN"; then
        do_patch "https://github.com/m-ab-s/mabs-patches/raw/master/lensfun/0001-CMake-exclude-mingw-w64-from-some-msvc-exclusive-thi.patch" am
        do_patch "https://github.com/m-ab-s/mabs-patches/raw/master/lensfun/0002-CMake-don-t-add-glib2-s-includes-as-SYSTEM-dirs.patch" am
        do_uninstall "bin-video/lensfun" "${_check[@]}"
        CFLAGS+=" -DGLIB_STATIC_COMPILATION" CXXFLAGS+=" -DGLIB_STATIC_COMPILATION" \
            do_cmakeinstall -DBUILD_STATIC=on -DBUILD_{TESTS,LENSTOOL,DOC}=off \
            -DINSTALL_HELPER_SCRIPTS=off -DCMAKE_INSTALL_DATAROOTDIR="$LOCALDESTDIR/bin-video" \
            -DINSTALL_PYTHON_MODULE=OFF
        do_checkIfExist
    fi
fi

_check=(bin-video/vvc/{Encoder,Decoder}App.exe)
if [[ $bits = 64bit && $vvc = y ]] &&
    do_vcs "$SOURCE_REPO_VVC" vvc; then
    do_uninstall bin-video/vvc
    do_patch "https://raw.githubusercontent.com/m-ab-s/mabs-patches/master/VVCSoftware_VTM/0001-BBuildEnc.cmake-Remove-Werror-for-gcc-and-clang.patch" am
    # patch for easier install of apps
    # probably not of upstream's interest because of how experimental the codec is
    do_patch "https://raw.githubusercontent.com/m-ab-s/mabs-patches/master/VVCSoftware_VTM/0002-cmake-allow-installing-apps.patch" am
    do_patch "https://raw.githubusercontent.com/m-ab-s/mabs-patches/master/VVCSoftware_VTM/0003-CMake-add-USE_CCACHE-variable-to-disable-using-found.patch" am
    _notrequired=true
    # install to own dir because the binaries' names are too generic
    do_cmakeinstall -DCMAKE_INSTALL_BINDIR="$LOCALDESTDIR"/bin-video/vvc \
        -DBUILD_STATIC=on -DSET_ENABLE_SPLIT_PARALLELISM=ON -DENABLE_SPLIT_PARALLELISM=OFF \
        -DUSE_CCACHE=OFF
    do_checkIfExist
    unset _notrequired
fi

_check=(bin-video/uvg266.exe libuvg266.a uvg266.pc uvg266.h)
if [[ $bits = 64bit && $uvg266 = y ]] &&
    do_vcs "$SOURCE_REPO_UVG266"; then
    do_uninstall version.h "${_check[@]}"
    do_cmakeinstall video -DBUILD_TESTING=OFF
    do_checkIfExist
fi

_check=(bin-video/vvenc{,FF}app.exe
    vvenc/vvenc.h
    libvvenc.{a,pc}
    lib/cmake/vvenc/vvencConfig.cmake)
if [[ $bits = 64bit && $vvenc = y ]] ||
    { [[ $ffmpeg != no && $bits = 64bit ]] && enabled libvvenc; } &&
    do_vcs "$SOURCE_REPO_LIBVVENC"; then
    do_pacman_install nlohmann-json
    do_uninstall include/vvenc lib/cmake/vvenc "${_check[@]}"
    do_cmakeinstall video -DVVENC_ENABLE_LINK_TIME_OPT=OFF -DVVENC_INSTALL_FULLFEATURE_APP=ON -DVVENC_ENABLE_THIRDPARTY_JSON=SYSTEM
    do_checkIfExist
else
    pc_exists libvvenc || do_removeOption "--enable-libvvenc"
fi

_check=(bin-video/vvdecapp.exe
    vvdec/vvdec.h
    libvvdec.{a,pc}
    lib/cmake/vvdec/vvdecConfig.cmake)
if [[ $bits = 64bit && $vvdec = y ]] ||
    { [[ $ffmpeg != no && $bits = 64bit ]] && enabled libvvdec; } &&
    do_vcs "$SOURCE_REPO_LIBVVDEC"; then
    do_patch "https://raw.githubusercontent.com/m-ab-s/mabs-patches/master/vvdec/0001-TypeDef-cast-mem-cpy-set-this-.-with-void-to-silence.patch" am
    do_patch "https://raw.githubusercontent.com/m-ab-s/mabs-patches/master/vvdec/0002-CodingStructure-cast-memset-with-void-to-silence-non.patch" am
    do_uninstall include/vvdec lib/cmake/vvdec "${_check[@]}"
    do_cmakeinstall video -DVVDEC_ENABLE_LINK_TIME_OPT=OFF -DVVDEC_INSTALL_VVDECAPP=ON
    do_checkIfExist
else
    pc_exists libvvdec || do_removeOption "--enable-libvvdec"
fi

_check=(bin-video/xeve_app.exe xeve/xeve{,_exports}.h libxeve.a xeve.pc)
if [[ $ffmpeg != no ]] && enabled libxeve &&
    do_vcs "$SOURCE_REPO_XEVE"; then
    do_uninstall bin-video/libxeve.dll lib/libxeve.dll.a.dyn "${_check[@]}"
    sed -i 's/-Werror //' CMakeLists.txt
    do_cmakeinstall video
    # no way to disable shared lib building in cmake
    # move the static library out from subfolder to make ffmpeg configure find it easier
    mv -f "$LOCALDESTDIR"/lib/xeve/libxeve.a "$LOCALDESTDIR"/lib/libxeve.a
    mv -f "$LOCALDESTDIR"/lib/libxeve.dll.a "$LOCALDESTDIR"/lib/libxeve.dll.a.dyn
    # delete the now empty subfolder
    rmdir "$LOCALDESTDIR/lib/xeve" > /dev/null 2>&1
    do_checkIfExist
fi

_check=(bin-video/xevd_app.exe xevd/xevd{,_exports}.h libxevd.a xevd.pc)
if [[ $ffmpeg != no ]] && enabled libxevd &&
    do_vcs "$SOURCE_REPO_XEVD"; then
    do_uninstall bin-video/libxevd.dll lib/libxevd.dll.a.dyn "${_check[@]}"
    sed -i 's/-Werror //' CMakeLists.txt
    do_cmakeinstall video
    # no way to disable shared lib building in cmake
    # move the static library out from subfolder to make ffmpeg configure find it easier
    mv -f "$LOCALDESTDIR"/lib/xevd/libxevd.a "$LOCALDESTDIR"/lib/libxevd.a
    mv -f "$LOCALDESTDIR"/lib/libxevd.dll.a "$LOCALDESTDIR"/lib/libxevd.dll.a.dyn
    # delete the now empty subfolder
    rmdir "$LOCALDESTDIR/lib/xevd" > /dev/null 2>&1
    do_checkIfExist
fi

_check=(avisynth/avisynth{,_c}.h
        avisynth/avs/{alignment,arch,capi,config,cpuid,minmax,posix,types,win,version}.h)
if [[ $ffmpeg != no ]] && enabled avisynth &&
    do_vcs "$SOURCE_REPO_AVISYNTH"; then
    do_uninstall "${_check[@]}"
    do_cmake -DHEADERS_ONLY=ON
    do_ninja VersionGen
    do_ninjainstall
    do_checkIfExist
fi

_check=(libvulkan.a vulkan.pc vulkan/vulkan.h d3d{kmthk,ukmdt}.h)
if { { [[ $ffmpeg != no ]] && enabled_any vulkan libplacebo; } ||
     { [[ $mpv != n ]] && ! mpv_disabled_any vulkan libplacebo; } } &&
    do_vcs "$SOURCE_REPO_VULKANLOADER" vulkan-loader; then
    _wine_mirror=https://raw.githubusercontent.com/wine-mirror/wine/master/include
    _mabs=https://raw.githubusercontent.com/m-ab-s/mabs-patches/master/vulkan-loader
    do_pacman_install uasm
    do_uninstall "${_check[@]}"
    do_patch "$_mabs/0001-pc-remove-CMAKE_CXX_IMPLICIT_LINK_LIBRARIES.patch" am
    do_patch "$_mabs/0002-loader-CMake-related-static-hacks.patch" am
    do_patch "$_mabs/0003-loader-Re-add-private-libs-to-pc-file.patch" am
    do_patch "$_mabs/0004-loader-Static-library-name-related-hacks.patch" am

    grep_and_sed VULKAN_LIB_SUFFIX loader/vulkan.pc.in \
            's/@VULKAN_LIB_SUFFIX@//'
    create_build_dir
    log dependencies "$MINGW_PREFIX"/bin/python ../scripts/update_deps.py --no-build
    cd_safe Vulkan-Headers
        do_print_progress "Installing Vulkan-Headers"
        do_uninstall include/vulkan
        # disable module header because clang-scan-deps can't understand `ccache clang++` as the "compiler."
        do_cmakeinstall -DVULKAN_HEADERS_ENABLE_MODULE=OFF
        do_wget -c -r -q "$_wine_mirror/ddk/d3dkmthk.h"
        do_wget -c -r -q "$_wine_mirror/d3dukmdt.h"
        do_install d3d{kmthk,ukmdt}.h include/
    cd_safe "$(get_first_subdir -f)"
    do_print_progress "Building Vulkan-Loader"
    CC="${CC##ccache }" CXX="${CXX##ccache }" \
        CFLAGS+=" -DSTRSAFE_NO_DEPRECATE" \
        do_cmakeinstall -DBUILD_TESTS=OFF \
    -DVULKAN_HEADERS_INSTALL_DIR="$LOCALDESTDIR" \
    -DBUILD_STATIC_LOADER=ON -DUNIX=OFF
    do_checkIfExist
    unset _wine_mirror _mabs
fi

if [[ $exitearly = EE5 ]]; then
    do_simple_print -p '\n\t'"${orange}Exit due to env var MABS_EXIT_EARLY set to EE5"
    return
fi

_check=(spirv_cross/spirv_cross_c.h spirv-cross.pc libspirv-cross.a)
if { [[ $mpv != n ]] ||
     { [[ $ffmpeg != no ]] && enabled libplacebo; } } &&
    do_vcs "$SOURCE_REPO_SPIRV_CROSS"; then
    do_uninstall include/spirv_cross "${_check[@]}" spirv-cross-c-shared.pc libspirv-cross-c-shared.a
    do_patch "https://raw.githubusercontent.com/m-ab-s/mabs-patches/master/SPIRV-Cross/0001-add-a-basic-Meson-build-system-for-use-as-a-subproje.patch" am
    sed -i 's/0.13.0/0.48.0/' meson.build
    do_mesoninstall
    do_checkIfExist
fi

_check=(lib{glslang,OSDependent,SPVRemapper}.a
        libSPIRV{,-Tools{,-opt,-link,-reduce}}.a glslang/SPIRV/GlslangToSpv.h)
if { [[ $mpv != n ]] ||
     { [[ $ffmpeg != no ]] && enabled_any libplacebo libglslang; } } &&
    do_vcs "$SOURCE_REPO_GLSLANG"; then
    do_uninstall libHLSL.a "${_check[@]}"
    log dependencies "$MINGW_PREFIX"/bin/python ./update_glslang_sources.py
    do_cmakeinstall -DUNIX=OFF
    do_checkIfExist
fi

_check=(shaderc/shaderc.h libshaderc_combined.a)
if { [[ $mpv != n ]] ||
     { [[ $ffmpeg != no ]] && enabled libplacebo; } } ||
     ! mpv_disabled shaderc &&
    do_vcs "$SOURCE_REPO_SHADERC"; then
    do_patch "https://raw.githubusercontent.com/m-ab-s/mabs-patches/master/shaderc/0001-third_party-set-INSTALL-variables-as-cache.patch" am
    do_patch "https://raw.githubusercontent.com/m-ab-s/mabs-patches/master/shaderc/0002-shaderc_util-add-install.patch" am
    do_uninstall "${_check[@]}" include/shaderc include/libshaderc_util

    grep_and_sed d0e67c58134377f065a509845ca6b7d463f5b487 DEPS 's/d0e67c58134377f065a509845ca6b7d463f5b487/76cc41d26f6902de543773023611e40fbcdde58b/g'
    log dependencies "$MINGW_PREFIX"/bin/python ./utils/git-sync-deps

    # fix python indentation errors from non-existant code review
    grep -ZRlP --include="*.py" '\t' third_party/spirv-tools/ | xargs -r -0 -n1 sed -i 's;\t;    ;g'

    do_cmakeinstall -GNinja -DSHADERC_SKIP_{TESTS,EXAMPLES}=ON -DSHADERC_ENABLE_WERROR_COMPILE=OFF -DSKIP_{GLSLANG,GOOGLETEST}_INSTALL=ON -DSPIRV_HEADERS_SKIP_{INSTALL,EXAMPLES}=ON
    do_checkIfExist
    unset add_third_party
fi

file_installed -s shaderc_static.pc &&
    mv "$(file_installed shaderc_static.pc)" "$(file_installed shaderc.pc)"

_check=(libplacebo.{a,pc})
_deps=(lib{vulkan,shaderc_combined}.a spirv-cross.pc shaderc/shaderc.h)
if { [[ $mpv != n ]] ||
     { [[ $ffmpeg != no ]] && enabled libplacebo; } } &&
    do_vcs "$SOURCE_REPO_LIBPLACEBO"; then
    do_git_submodule
    do_patch "https://raw.githubusercontent.com/m-ab-s/mabs-patches/master/libplacebo/0001-meson-use-shaderc_combined.patch" am
    do_patch "https://raw.githubusercontent.com/m-ab-s/mabs-patches/master/libplacebo/0002-spirv-cross-use-spirv-cross-instead-of-c-shared.patch" am
    do_pacman_install python-{mako,setuptools}
    do_uninstall "${_check[@]}"
    do_mesoninstall -Dvulkan-registry="$LOCALDESTDIR/share/vulkan/registry/vk.xml" -Ddemos=false -Dd3d11=enabled
    do_checkIfExist
fi

if [[ $exitearly = EE6 ]]; then
    do_simple_print -p '\n\t'"${orange}Exit due to env var MABS_EXIT_EARLY set to EE6"
    return
fi

enabled openssl && hide_libressl
if [[ $ffmpeg != no ]]; then
    enabled libgsm && do_pacman_install gsm
    enabled libsnappy && do_pacman_install snappy
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
        # We use msys2's package for the header and import library so we don't build it, for licensing reasons
        do_pacman_install openh264
        if [[ -f $MINGW_PREFIX/lib/libopenh264.dll.a.dyn ]]; then
            # backup the static library
            mv -f "$MINGW_PREFIX"/lib/libopenh264.a{,.bak}
            # use the import library as a phony static library, as mpv doesn't look for .dll.a
            mv -f "$MINGW_PREFIX"/lib/libopenh264.{dll.a.dyn,a}
        fi
        [[ -f $MINGW_PREFIX/lib/libopenh264.dll.a ]] && mv -f "$MINGW_PREFIX"/lib/libopenh264.{dll.,}a
        _openh264_ver=2.6.0
        _pacman_openh264_ver=$(pacman -Q "${MINGW_PACKAGE_PREFIX}-openh264" | awk '{print $2}')
        if [[ $(vercmp.exe $_openh264_ver "$_pacman_openh264_ver") -ne 0 ]]; then
            do_simple_print "${orange}Openh264 version differs from msys2's, current: $_openh264_ver, msys2: $_pacman_openh264_ver${reset}"
            do_simple_print "${orange}Check if this is the latest suite and update if possible, else open an issue${reset}"
        fi
        if test_newer "$MINGW_PREFIX"/lib/libopenh264.dll.a "$LOCALDESTDIR/bin-video/libopenh264-7.dll" ||
            ! get_dll_version "$LOCALDESTDIR/bin-video/libopenh264-7.dll" | grep -q "$_openh264_ver"; then
            pushd "$LOCALDESTDIR/bin-video" >/dev/null || do_exit_prompt "Did you delete the bin-video folder?"
            if [[ $bits = 64bit ]]; then
                _sha256=dab5f2a872777f9a58b69bfa9fbcf20d9f82f2d6ec91383fd70bff49bd34ac9f
            else
                _sha256=a9445ed1fa2ce9665b22461a7ed0aeb52274add899aa55a93ef6278dbc17c90d
            fi
            do_wget -c -r -q -h $_sha256 \
            "http://ciscobinary.openh264.org/openh264-${_openh264_ver}-win${bits%bit}.dll.bz2" \
                libopenh264.dll.bz2
            [[ -f libopenh264.dll.bz2 ]] && bunzip2 -f libopenh264.dll.bz2
            mv -f libopenh264.dll libopenh264-7.dll
            popd >/dev/null || do_exit_prompt "Did you delete the previous folder?"
        fi
        unset _sha256 _openh264_ver
    fi
    enabled chromaprint && do_addOption --extra-cflags=-DCHROMAPRINT_NODLL &&
        { do_pacman_remove fftw; do_pacman_install chromaprint; }
    if enabled libzmq; then
        if [[ $bits = 64bit ]]; then
            do_pacman_install zeromq
            grep_or_sed ws2_32 "$MINGW_PREFIX"/lib/pkgconfig/libzmq.pc \
                's/-lpthread/& -lws2_32/'
            do_addOption --extra-cflags=-DZMQ_STATIC
        else
            do_removeOption --enable-libzmq
            do_simple_print "${orange}libzmq is not available for 32-bit, disabling${reset}"
        fi
    fi
    enabled frei0r && do_addOption --extra-libs=-lpsapi
    enabled libxml2 && do_addOption --extra-cflags=-DLIBXML_STATIC
    enabled ladspa && do_pacman_install ladspa-sdk
    if enabled vapoursynth && pc_exists "vapoursynth-script"; then
        _ver=$($PKG_CONFIG --modversion vapoursynth-script)
        do_simple_print "${green}Compiling FFmpeg with Vapoursynth R${_ver}${reset}"
        do_simple_print "${orange}FFmpeg will need vapoursynth.dll and vsscript.dll to run using vapoursynth demuxers"'!'"${reset}"
        unset _ver
    fi
    disabled autodetect && enabled iconv && do_addOption --extra-libs=-liconv

    do_hide_all_sharedlibs

    _check=(libavutil.pc)
    disabled_any avfilter ffmpeg || _check+=(bin-video/ffmpeg.exe)
    if [[ $ffmpeg =~ shared ]]; then
        _check+=(libavutil.dll.a)
    else
        _check+=(libavutil.a)
        [[ $ffmpeg =~ both ]] && _check+=(bin-video/ffmpegSHARED)
    fi
    # todo: make this more easily customizable
    [[ $ffmpegUpdate = y ]] && enabled_any lib{aom,tesseract,vmaf,x265,vpx} &&
        _deps=(lib{aom,tesseract,vmaf,x265,vpx}.a)
    [[ $ffmpegUpdate = y ]] && enabled zlib &&
        _deps+=("$zlib_dir"/lib/libz.a)
    if do_vcs "$ffmpegPath"; then
        ff_base_commit=$(git rev-parse HEAD)
        do_changeFFmpegConfig "$license"
        [[ -f ffmpeg_extra.sh ]] && source ffmpeg_extra.sh
        if enabled libvvdec; then
            do_patch "https://raw.githubusercontent.com/wiki/fraunhoferhhi/vvdec/data/patch/v6-0001-avcodec-add-external-dec-libvvdec-for-H266-VVC.patch" am  ||
                do_removeOptions --enable-libvvdec
        fi
        if enabled libsvthevc; then
            do_patch "https://raw.githubusercontent.com/1480c1/SVT-HEVC/master/ffmpeg_plugin/master-0001-lavc-svt_hevc-add-libsvt-hevc-encoder-wrapper.patch" am ||
                do_removeOption --enable-libsvthevc
        fi
        if enabled libsvtvp9; then
            do_patch "https://raw.githubusercontent.com/OpenVisualCloud/SVT-VP9/master/ffmpeg_plugin/master-0001-Add-ability-for-ffmpeg-to-run-svt-vp9.patch" am ||
                do_removeOption --enable-libsvtvp9
        fi
        if enabled libsvtav1; then
            do_patch "https://code.ffmpeg.org/FFmpeg/FFmpeg/pulls/12.patch" am
        fi

        enabled libsvthevc || do_removeOption FFMPEG_OPTS_SHARED "--enable-libsvthevc"
        enabled libsvtav1 || do_removeOption FFMPEG_OPTS_SHARED "--enable-libsvtav1"
        enabled libsvtvp9 || do_removeOption FFMPEG_OPTS_SHARED "--enable-libsvtvp9"

        enabled libvvdec && grep_and_sed FF_PROFILE libavcodec/libvvdec.c 's/FF_PROFILE/AV_PROFILE/g'

        if enabled openal &&
            pc_exists "openal"; then
            OPENAL_LIBS=$($PKG_CONFIG --libs openal)
            export OPENAL_LIBS
            do_addOption "--extra-cflags=-DAL_LIBTYPE_STATIC"
            do_addOption FFMPEG_OPTS_SHARED "--extra-cflags=-DAL_LIBTYPE_STATIC"
            for _openal_flag in $($PKG_CONFIG --cflags openal); do
                do_addOption "--extra-cflags=$_openal_flag"
            done
            unset _openal_flag
        fi

        if enabled gmp; then
            do_pacman_install gmp
            grep_and_sed '__declspec(__dllimport__)' "$MINGW_PREFIX"/include/gmp.h \
                's|__declspec\(__dllimport__\)||g' "$MINGW_PREFIX"/include/gmp.h
        fi

        _patches=$(git rev-list $ff_base_commit.. --count)
        [[ $_patches -gt 0 ]] &&
            do_addOption "--extra-version=g$(git rev-parse --short $ff_base_commit)+$_patches"

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
            build_suffix=$(printf '%s\n' "${FFMPEG_OPTS[@]}" |
                sed -rn '/build-suffix=/{s;.+=(.+);\1;p}') ||
                build_suffix=""

        if [[ $ffmpeg =~ both ]]; then
            _check+=(bin-video/ffmpegSHARED/lib/"libavutil${build_suffix}.dll.a")
            FFMPEG_OPTS_SHARED+=("--prefix=$LOCALDESTDIR/bin-video/ffmpegSHARED")
        elif [[ $ffmpeg =~ shared ]]; then
            _check+=("libavutil${build_suffix}".{dll.a,pc})
            FFMPEG_OPTS_SHARED+=("--prefix=$LOCALDESTDIR"
                "--bindir=$LOCALDESTDIR/bin-video"
                "--shlibdir=$LOCALDESTDIR/bin-video")
        fi
        ! disabled_any debug "debug=gdb" &&
            ffmpeg_cflags=$(sed -r 's/ (-O[1-3]|-mtune=\S+)//g' <<< "$CFLAGS")

        # shared
        if [[ $ffmpeg != static ]] && [[ ! -f build_successful${bits}_shared ]]; then
            do_print_progress "Compiling ${bold}shared${reset} FFmpeg"
            do_uninstall bin-video/ffmpegSHARED "${_uninstall[@]}"
            [[ -f config.mak ]] && log "distclean" make distclean
            create_build_dir shared
            config_path=.. CFLAGS="${ffmpeg_cflags:-$CFLAGS}" \
            LDFLAGS+=" -L$LOCALDESTDIR/lib -L$MINGW_PREFIX/lib" \
                do_configure \
                --disable-static --enable-shared "${FFMPEG_OPTS_SHARED[@]}"
            # cosmetics
            sed -ri "s/ ?--($sedflags)=(\S+[^\" ]|'[^']+')//g" config.h
            do_make && do_makeinstall
            cd_safe ..
            files_exist "${_check[@]}" && touch "build_successful${bits}_shared"
        fi

        # static
        if [[ ! $ffmpeg =~ shared ]] && _check=(libavutil.{a,pc}); then
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
            config_path=.. CFLAGS="${ffmpeg_cflags:-$CFLAGS}" \
            cc=$CC cxx=$CXX LDFLAGS+=" -L$LOCALDESTDIR/lib -L$MINGW_PREFIX/lib" \
                do_configure \
                --bindir="$LOCALDESTDIR/bin-video" "${FFMPEG_OPTS[@]}"
            # cosmetics
            sed -ri "s/ ?--($sedflags)=(\S+[^\" ]|'[^']+')//g" config.h
            do_make && do_makeinstall
            ! disabled_any debug "debug=gdb" &&
                create_debug_link "$LOCALDESTDIR"/bin-video/ff{mpeg,probe,play}.exe
            cd_safe ..
        fi
        do_checkIfExist
        [[ -f $LOCALDESTDIR/bin-video/ffmpeg.exe ]] &&
            create_winpty_exe ffmpeg "$LOCALDESTDIR"/bin-video/
        unset ffmpeg_cflags build_suffix
    fi
fi

_check=(libde265.a)
[[ $standalone = y ]] && _check+=(bin-video/dec265.exe)
if [[ $libheif != n ]] &&
    do_vcs "$SOURCE_REPO_LIBDE265"; then
    do_uninstall "${_check[@]}"
    extracommands=()
    [[ $standalone = n ]] && extracommands+=(-DENABLE_{DE,EN}CODER=OFF)
    do_cmakeinstall video "${extracommands[@]}"
    do_checkIfExist
fi

_check=(bin-video/heif-{dec,enc,info,thumbnailer}.exe)
[[ $libheif = shared ]] && _check+=(bin-video/libheif.dll)
if [[ $libheif != n ]] &&
    do_vcs "$SOURCE_REPO_LIBHEIF"; then
    do_uninstall "${_check[@]}"

    do_pacman_install libjpeg-turbo
    pc_exists "libpng" || do_pacman_install libpng

    do_patch https://raw.githubusercontent.com/m-ab-s/mabs-patches/master/libheif/0001-Edit-CMakeLists.patch

    extracflags=()
    extracommands=(-DWITH_HEADER_COMPRESSION=ON -DWITH_UNCOMPRESSED_CODEC=ON)

    pc_exists "libde265" &&
        extracommands+=(-DWITH_LIBDE265=ON -DWITH_LIBDE265_PLUGIN=OFF) &&
        extracflags+=(-DLIBDE265_STATIC_BUILD=1)
    pc_exists "kvazaar" &&
        extracommands+=(-DWITH_KVAZAAR=ON -DWITH_KVAZAAR_PLUGIN=OFF) &&
        extracflags+=(-DKVZ_STATIC_LIB=1)
    pc_exists "uvg266" &&
        extracommands+=(-DWITH_UVG266=ON -DWITH_UVG266_PLUGIN=OFF) &&
        extracflags+=(-DUVG_STATIC_LIB=1)

    pc_exists "x265" &&
        extracommands+=(-DWITH_X265=ON -DWITH_X265_PLUGIN=OFF)
    pc_exists "aom" &&
        extracommands+=(-DWITH_AOM_{DE,EN}CODER=ON -DWITH_AOM_{DE,EN}CODER_PLUGIN=OFF)
    pc_exists "dav1d" &&
        extracommands+=(-DWITH_DAV1D=ON -DWITH_DAV1D_PLUGIN=OFF)
    pc_exists "SvtAv1Enc" &&
        extracommands+=(-DWITH_SvtEnc=ON -DWITH_SvtEnc_PLUGIN=OFF)
    pc_exists "libvvenc" &&
        extracommands+=(-DWITH_VVENC=ON -DWITH_VVENC_PLUGIN=OFF)
    pc_exists "libvvdec" &&
        extracommands+=(-DWITH_VVDEC=ON -DWITH_VVDEC_PLUGIN=OFF)
    pacman -Q $MINGW_PACKAGE_PREFIX-libjpeg > /dev/null 2>&1 &&
        extracommands+=(-DWITH_JPEG_{DE,EN}CODER=ON -DWITH_JPEG_{DE,EN}CODER_PLUGIN=OFF)
    pacman -Q $MINGW_PACKAGE_PREFIX-openh264 > /dev/null 2>&1 &&
        extracommands+=(-DWITH_OpenH264_DECODER=ON -DWITH_OpenH264_DECODER_PLUGIN=OFF)

    # don't fail on .dll.a not found because we hide it
    # still need to make it link to static lib as it still wants to link to .dll.a and fails
    # pacman -Q $MINGW_PACKAGE_PREFIX-openjpeg2 > /dev/null 2>&1 &&
    #     sed -i 's/message(FATAL_ERROR "The imported target/message(WARNING "The imported target/' \
    #     "$MINGW_PREFIX"/lib/cmake/openjpeg-2.5/OpenJPEGTargets.cmake &&
    #     extracommands+=(-DWITH_OpenJPEG_{DE,EN}CODER=ON -DWITH_OpenJPEG_{DE,EN}CODER_PLUGIN=OFF)

    # linking difficulties
    pc_exists "rav1e" &&
        extracommands+=(-DWITH_RAV1E=OFF -DWITH_RAV1E_PLUGIN=OFF)
    pc_exists "libavcodec" "libavutil" &&
        extracommands+=(-DWITH_FFMPEG_DECODER=OFF -DWITH_FFMPEG_DECODER_PLUGIN=OFF)

    # this depends on CMake overrides -DBUILD_SHARED_LIBS=off in do_cmake, may break if that behavior changes.
    [[ $libheif = shared ]] && extracommands+=(-DBUILD_SHARED_LIBS=ON)
    CFLAGS+=" ${extracflags[@]}" CXXFLAGS+=" ${extracflags[@]}" \
        do_cmakeinstall video -DBUILD_TESTING=OFF -DWITH_GDK_PIXBUF=OFF "${extracommands[@]}"

    # this subfolder is for plugins and is empty since we didn't build any plugin so we delete it
    rmdir "$LOCALDESTDIR/lib/libheif" > /dev/null 2>&1
    do_checkIfExist
fi

# static do_vcs just for svn
check_mplayer_updates() {
    cd_safe "$LOCALBUILDDIR"
    if [[ ! -d mplayer-svn/.svn ]]; then
        rm -rf mplayer-svn
        do_print_progress "  Running svn clone for mplayer"
        svn_clone() (
            set -x
            svn --non-interactive checkout -r HEAD svn://svn.mplayerhq.hu/mplayer/trunk mplayer-svn &&
                [[ -d mplayer-svn/.svn ]]
        )
        if svn --non-interactive ls svn://svn.mplayerhq.hu/mplayer/trunk > /dev/null 2>&1 &&
            log -q "svn.clone" svn_clone; then
            touch mplayer-svn/recently_{updated,checked}
        else
            echo "mplayer svn seems to be down"
            echo "Try again later or <Enter> to continue"
            do_prompt "if you're sure nothing depends on it."
            return
        fi
        unset svn_clone
    fi

    cd_safe mplayer-svn

    oldHead=$(svn info --show-item last-changed-revision .)
    log -q "svn.reset" svn revert --recursive .
    if ! [[ -f recently_checked && recently_checked -nt $LOCALBUILDDIR/last_run ]]; then
        do_print_progress "  Running svn update for mplayer"
        log -q "svn.update" svn update -r HEAD
        newHead=$(svn info --show-item last-changed-revision .)
        touch recently_checked
    else
        newHead="$oldHead"
    fi

    rm -f custom_updated
    check_custom_patches

    if [[ $oldHead != "$newHead" || -f custom_updated ]]; then
        touch recently_updated
        rm -f ./build_successful{32,64}bit{,_*}
        if [[ $build32$build64$bits == yesyes64bit ]]; then
            new_updates="yes"
            new_updates_packages="$new_updates_packages [mplayer]"
        fi
        printf 'mplayer\n' >> "$LOCALBUILDDIR"/newchangelog
        do_print_status "┌ mplayer svn" "$orange" "Updates found"
    elif [[ -f recently_updated && ! -f build_successful$bits ]]; then
        do_print_status "┌ mplayer svn" "$orange" "Recently updated"
    elif ! files_exist "${_check[@]}"; then
        do_print_status "┌ mplayer svn" "$orange" "Files missing"
    else
        do_print_status "mplayer svn" "$green" "Up-to-date"
        [[ ! -f recompile ]] &&
            return 1
        do_print_status "┌ mplayer svn" "$orange" "Forcing recompile"
        do_print_status prefix "$bold├$reset " "Found recompile flag" "$orange" "Recompiling"
    fi
    return 0
}

_check=(bin-video/m{player,encoder}.exe)
if [[ $mplayer = y ]] && check_mplayer_updates; then
    [[ $license != nonfree || $faac == n ]] && faac_opts=(--disable-faac)
    do_uninstall "${_check[@]}"
    [[ -f config.mak ]] && log "distclean" make distclean
    if [[ ! -d ffmpeg ]] &&
        ! { [[ -d $LOCALBUILDDIR/ffmpeg-git ]] &&
        git clone -q "$LOCALBUILDDIR/ffmpeg-git" ffmpeg; } &&
        ! git clone "$ffmpegPath" ffmpeg; then
        rm -rf ffmpeg
        printf '%s\n' \
            "Failed to get a FFmpeg checkout" \
            "Please try again or put FFmpeg source code copy into ffmpeg/ manually." \
            "Nightly snapshot: http://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2" \
            "Either re-run the script or extract above to inside /build/mplayer-svn."
        do_prompt "<Enter> to continue or <Ctrl+c> to exit the script"
    fi
    [[ ! -d ffmpeg ]] && compilation_fail "Finding valid ffmpeg dir"
    [[ -d ffmpeg/.git ]] && {
        git -C ffmpeg fetch -q origin
        git -C ffmpeg checkout -qf --no-track -B master origin/HEAD
    }

    do_patch "https://raw.githubusercontent.com/m-ab-s/mabs-patches/master/mplayer/0001-ae_lavc-fix-deprecated-warnings.patch"
    do_patch "https://raw.githubusercontent.com/m-ab-s/mabs-patches/master/mplayer/0002-configure-fix-cddb-on-mingw-w64.patch"
    do_patch "https://raw.githubusercontent.com/m-ab-s/mabs-patches/master/mplayer/0003-w32_common-add-casts-for-Wint-conversion.patch"
    do_patch "https://raw.githubusercontent.com/m-ab-s/mabs-patches/master/mplayer/0004-configure-add-checking-libass-from-pkg-config.patch"

    # grep_or_sed windows libmpcodecs/ad_spdif.c '/#include "mp_msg.h/ a\#include <windows.h>'
    # grep_or_sed gnu11 configure 's/c11/gnu11/g'
    # shellcheck disable=SC2016
    sed -i '/%\$(EXESUF):/{n; s/\$(CC)/\$(CXX)/g};/mencoder$(EXESUF)/{n; s/\$(CC)/\$(CXX)/g}' Makefile

    _notrequired=true
    # do_configure --bindir="$LOCALDESTDIR"/bin-video \
    # --extra-cflags='-fpermissive -DPTW32_STATIC_LIB -O3 -DMODPLUG_STATIC -Wno-int-conversion -Wno-error=incompatible-function-pointer-types' \
    # --extra-libs="-llzma -liconv -lws2_32 -lpthread -lwinpthread -lpng -lwinmm $($PKG_CONFIG --libs libilbc) \
    #     $(enabled vapoursynth && $PKG_CONFIG --libs vapoursynth-script)" \
    # --extra-ldflags='-Wl,--allow-multiple-definition' --enable-{static,runtime-cpudetection} \
    # --disable-{gif,cddb} "${faac_opts[@]}" --with-dvdread-config="$PKG_CONFIG dvdread" \
    # --with-freetype-config="$PKG_CONFIG freetype2" --with-dvdnav-config="$PKG_CONFIG dvdnav" &&
    #     do_makeinstall CXX="$CXX" && do_checkIfExist

    do_configure \
        --bindir="$LOCALDESTDIR"/bin-video \
        --enable-{static,runtime-cpudetection} \
        --extra-cflags='-Wno-error=incompatible-pointer-types' \
        "${faac_opts[@]}" &&
        do_makeinstall CXX="$CXX" && do_checkIfExist

    unset _notrequired faac_opts
fi

if [[ $mpv != n ]] && pc_exists libavcodec libavformat libswscale libavfilter; then
    if [[ ${MPV_OPTS[lua]} == 5.1 ]]; then
        do_pacman_install lua51
    elif ! mpv_disabled lua &&
        _check=(bin-global/luajit.exe libluajit-5.1.a luajit.pc luajit-2.1/lua.h) &&
        do_vcs "$SOURCE_REPO_LUAJIT" luajit; then
        do_pacman_remove luajit lua51
        do_uninstall include/luajit-2.1 lib/lua "${_check[@]}"
        [[ -f src/luajit.exe ]] && log "clean" make clean
        do_patch "https://raw.githubusercontent.com/m-ab-s/mabs-patches/master/LuaJIT/0001-Add-win32-UTF-8-filesystem-functions.patch" am
        do_patch "https://raw.githubusercontent.com/m-ab-s/mabs-patches/master/LuaJIT/0002-win32-UTF-8-Remove-va-arg-and-.-and-unused-functions.patch" am
        do_patch "https://raw.githubusercontent.com/m-ab-s/mabs-patches/master/LuaJIT/0003-make-don-t-override-user-provided-CC.patch" am
        do_patch "https://raw.githubusercontent.com/m-ab-s/mabs-patches/master/LuaJIT/0004-pkgconfig-fix-pkg-config-file-for-mingw64.patch" am
        do_patch "https://raw.githubusercontent.com/m-ab-s/mabs-patches/master/LuaJIT/0005-Undo-rolling-release-stuff-since-it-s-not-useful-to-.patch" am
        sed -i "s|export PREFIX= /usr/local|export PREFIX=${LOCALDESTDIR}|g" Makefile
        sed -i "s|^prefix=.*|prefix=$LOCALDESTDIR|" etc/luajit.pc
        _luajit_args=("PREFIX=$LOCALDESTDIR" "INSTALL_BIN=$LOCALDESTDIR/bin-global" "INSTALL_TNAME=luajit.exe")
        do_make amalg HOST_CC="$CC" BUILDMODE=static \
            CFLAGS='-D_WIN32_WINNT=0x0602 -DUNICODE' \
            XCFLAGS="-DLUAJIT_ENABLE_LUA52COMPAT$([[ $bits = 64bit ]] && echo " -DLUAJIT_ENABLE_GC64")" \
            "${_luajit_args[@]}"
        do_makeinstall "${_luajit_args[@]}"
        do_checkIfExist
        unset _luajit_args
    fi

    do_pacman_remove uchardet-git
    ! mpv_disabled uchardet && do_pacman_install uchardet
    ! mpv_disabled libarchive && do_pacman_install libarchive
    ! mpv_disabled lcms2 && do_pacman_install lcms2

    do_pacman_remove angleproject-git
    _check=(EGL/egl.h)
    if mpv_enabled egl-angle && do_vcs "$SOURCE_REPO_ANGLE"; then
        do_simple_print "${orange}mpv will need libGLESv2.dll and libEGL.dll to use gpu-context=angle"'!'
        do_simple_print "You can find these in your browser's installation directory, usually."
        do_uninstall include/{EGL,GLES{2,3},KHR,platform} angle_gl.h \
            lib{GLESv2,EGL}.a "${_check[@]}"
        cp -rf include/{EGL,KHR} "$LOCALDESTDIR/include/"
        do_checkIfExist
    elif ! mpv_disabled egl-angle && ! files_exist "${_check[@]}"; then
        mpv_disable egl-angle
    fi

    if ! mpv_disabled vapoursynth && pc_exists "vapoursynth-script"; then
        _ver=$($PKG_CONFIG --modversion vapoursynth-script)
        do_simple_print "${green}Compiling mpv with Vapoursynth R${_ver}${reset}"
        do_simple_print "${orange}mpv will need vapoursynth.dll and vsscript.dll to use vapoursynth filter"'!'"${reset}"
        unset _ver
    fi

    _check=(mujs.{h,pc} libmujs.a)
    if ! mpv_disabled javascript &&
        do_vcs "$SOURCE_REPO_MUJS"; then
        do_uninstall bin-global/mujs.exe "${_check[@]}"
        log clean env -i PATH="$PATH" "$(command -v make)" clean
        mujs_targets=(build/release/{mujs.pc,libmujs.a})
        if [[ $standalone != n ]]; then
            mujs_targets+=(build/release/mujs)
            _check+=(bin-global/mujs.exe)
            sed -i "s;-lreadline;$($PKG_CONFIG --libs readline);g" Makefile
        fi
        extra_script pre make
        TEMP="${TEMP:-/tmp}" CPATH="${CPATH:-}" log "make" "$(command -v make)" \
            "${mujs_targets[@]}" prefix="$LOCALDESTDIR" bindir="$LOCALDESTDIR/bin-global"
        extra_script post make
        extra_script pre install
        [[ $standalone != n ]] && do_install build/release/mujs "$LOCALDESTDIR/bin-global"
        do_install build/release/mujs.pc lib/pkgconfig/
        do_install build/release/libmujs.a lib/
        do_install mujs.h include/
        extra_script post install
        grep_or_sed "Requires.private:" "$LOCALDESTDIR/lib/pkgconfig/mujs.pc" \
            's;Version:.*;&\nRequires.private: readline;'
        unset mujs_targets
        do_checkIfExist
    fi

    _check=(libmpv.a mpv.pc)
    ! mpv_disabled cplayer && _check+=(bin-video/mpv.{exe,com})
    _deps=(lib{ass,avcodec,vapoursynth,shaderc_combined,spirv-cross,placebo}.a "$MINGW_PREFIX"/lib/libuchardet.a)
    if do_vcs "$SOURCE_REPO_MPV"; then
        do_patch "https://github.com/1480c1/mpv/commit/e26713d7b0e4a096c2039a263532ce818cc8043e.patch" am
        do_uninstall share/man/man1/mpv.1 include/mpv share/doc/mpv etc/mpv "${_check[@]}"
        hide_conflicting_libs
        create_ab_pkgconfig
        if ! mpv_disabled manpage-build || mpv_enabled html-build; then
            do_pacman_install python-docutils
        fi
        mpv_enabled pdf-build && do_pacman_install python-rst2pdf

        [[ -f mpv_extra.sh ]] && source mpv_extra.sh

        mapfile -t MPV_ARGS < <(mpv_build_args)
        do_mesoninstall video "${MPV_ARGS[@]}"
        unset MPV_ARGS
        hide_conflicting_libs -R
        files_exist share/man/man1/mpv.1 && dos2unix -q "$LOCALDESTDIR"/share/man/man1/mpv.1
        create_winpty_exe mpv "$LOCALDESTDIR"/bin-video/ "export _started_from_console=yes"
        do_checkIfExist
    fi
fi

if [[ $bmx = y ]]; then
    _check=(bin-global/uriparse.exe liburiparser.a liburiparser.pc uriparser/Uri.h)
    do_pacman_remove uriparser
    if do_vcs "$SOURCE_REPO_URIPARSER"; then
        do_uninstall include/uriparser "${_check[@]}"
        do_cmakeinstall global -DURIPARSER_BUILD_{DOCS,TESTS}=OFF
        do_checkIfExist
    fi

    # libMXF and libMXF++ were moved into bmx.
    _check=(bin-video/{bmxtranswrap,{h264,mov,vc2}dump,mxf2raw,raw2bmx}.exe)
    _deps=(liburiparser.a)
    if do_vcs "$SOURCE_REPO_LIBBMX"; then
        (
            pushd deps/libMXF >/dev/null
            do_patch "https://github.com/bbc/libMXF/commit/0a9d2129f2a883d600369b031e1ee29dc808a193.patch" am
            popd >/dev/null
        ) || do_exit_prompt "Did you delete the libMXF folder?"
        do_uninstall libbmx-0.1.{{,l}a,pc} bin-video/bmxparse.exe \
            include/bmx-0.1 "${_check[@]}"
        do_cmakeinstall video -DUNIX=OFF -DBMX_BUILD_TESTING=OFF -DBMX_BUILD_WITH_LIBCURL=OFF -DLIBMXF_BUILD_TOOLS=OFF -DLIBMXF_BUILD_MXFDUMP=OFF
        do_checkIfExist
    fi
fi
enabled openssl && hide_libressl -R

if [[ $cyanrip = y ]]; then
    do_pacman_install libcdio-paranoia jansson
    sed -ri 's;-R[^ ]*;;g' "$MINGW_PREFIX/lib/pkgconfig/libcdio.pc"

    _check=(neon/ne_utils.h libneon.a neon.pc)
    if do_vcs "$SOURCE_REPO_NEON"; then
        do_patch "https://github.com/notroj/neon/pull/69.patch" am
        do_uninstall include/neon "${_check[@]}"
        do_autogen
        do_separate_confmakeinstall --disable-{nls,debug,webdav}
        do_checkIfExist
    fi

    _deps=(libneon.a libxml2.a)
    _check=(musicbrainz5/mb5_c.h libmusicbrainz5{,cc}.{a,pc})
    if do_vcs "$SOURCE_REPO_LIBMUSICBRAINZ"; then
        do_patch "https://github.com/metabrainz/libmusicbrainz/compare/master...wiiaboo:libmusicbrainz:master.patch" am
        do_uninstall "${_check[@]}" include/musicbrainz5
        CXXFLAGS+=" $($PKG_CONFIG --cflags libxml-2.0)" \
            LDFLAGS+=" $($PKG_CONFIG --libs libxml-2.0)" \
            do_cmakeinstall
        do_checkIfExist
    fi

    _deps=(libmusicbrainz5.a libcurl.a)
    _check=(bin-audio/cyanrip.exe)
    if do_vcs "$SOURCE_REPO_CYANRIP"; then
        old_PKG_CONFIG_PATH=$PKG_CONFIG_PATH
        _check=("$LOCALDESTDIR"/opt/cyanffmpeg/lib/pkgconfig/libav{codec,format}.pc)
        if flavor=cyan do_vcs "$ffmpegPath"; then
            do_uninstall "$LOCALDESTDIR"/opt/cyanffmpeg
            [[ -f config.mak ]] && log "distclean" make distclean
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
            config_path=.. do_configure "${FFMPEG_BASE_OPTS[@]}" \
                --prefix="$LOCALDESTDIR/opt/cyanffmpeg" \
                --disable-{programs,devices,filters,decoders,hwaccels,encoders,muxers} \
                --disable-{debug,protocols,demuxers,parsers,doc,swscale,postproc,network} \
                --disable-{avdevice,autodetect} \
                --disable-bsfs --enable-protocol=file,data \
                --enable-encoder=flac,tta,aac,wavpack,alac,pcm_s16le,pcm_s32le \
                --enable-muxer=flac,tta,ipod,wv,mp3,opus,ogg,wav,pcm_s16le,pcm_s32le,image2,singlejpeg \
                --enable-parser=png,mjpeg --enable-decoder=mjpeg,png \
                --enable-demuxer=image2,singlejpeg \
                --enable-{bzlib,zlib,lzma,iconv} \
                --enable-filter=hdcd \
                "${cyan_ffmpeg_opts[@]}"
            do_makeinstall
            files_exist "${_check[@]}" && touch ../"build_successful${bits}_cyan"
        fi
        unset cyan_ffmpeg_opts
        PKG_CONFIG_PATH=$LOCALDESTDIR/opt/cyanffmpeg/lib/pkgconfig:$PKG_CONFIG_PATH

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
        PKG_CONFIG_PATH=$old_PKG_CONFIG_PATH
        unset old_PKG_CONFIG_PATH _extra_ldflags _extra_cflags
    fi
fi

if [[ $vlc == y ]]; then
    do_pacman_install lib{cddb,nfs,shout,samplerate,microdns,secret} \
        a52dec taglib gtk3 lua perl

    # Remove useless shell scripts file that causes errors when stdout is not a tty.
    find "$MINGW_PREFIX/bin/" -name "luac" -delete

    _check=("$DXSDK_DIR/fxc2.exe" "$DXSDK_DIR/d3dcompiler_47.dll")
    if do_vcs "https://github.com/mozilla/fxc2.git"; then
        do_uninstall "${_check[@]}"
        do_patch "https://code.videolan.org/videolan/vlc/-/raw/master/contrib/src/fxc2/0001-make-Vn-argument-as-optional-and-provide-default-var.patch" am
        do_patch "https://code.videolan.org/videolan/vlc/-/raw/master/contrib/src/fxc2/0002-accept-windows-style-flags-and-splitted-argument-val.patch" am
        do_patch "https://code.videolan.org/videolan/vlc/-/raw/master/contrib/src/fxc2/0004-Revert-Fix-narrowing-conversion-from-int-to-BYTE.patch" am
        $CXX $CFLAGS -static -static-libgcc -static-libstdc++ -o "$DXSDK_DIR/fxc2.exe" fxc2.cpp -ld3dcompiler $LDFLAGS
        case $bits in
        32*) cp -f "dll/d3dcompiler_47_32.dll" "$DXSDK_DIR/d3dcompiler_47.dll" ;;
        *) cp -f "dll/d3dcompiler_47.dll" "$DXSDK_DIR/d3dcompiler_47.dll" ;;
        esac
        do_checkIfExist
    fi

    # Taken from https://code.videolan.org/videolan/vlc/blob/master/contrib/src/qt/AddStaticLink.sh
    _add_static_link() {
        local PRL_SOURCE=$LOCALDESTDIR/$2/lib$3.prl LIBS
        [[ -f $PRL_SOURCE ]] || PRL_SOURCE=$LOCALDESTDIR/$2/$3.prl
        [[ ! -f $PRL_SOURCE ]] && return 1
        LIBS=$(sed -e "
            /QMAKE_PRL_LIBS =/ {
                s@QMAKE_PRL_LIBS =@@
                s@$LOCALDESTDIR/lib@\${libdir}@g
                s@\$\$\[QT_INSTALL_LIBS\]@\${libdir}@g
                p
            }
            d" "$PRL_SOURCE" | grep -v QMAKE_PRL_LIBS_FOR_CMAKE)
        sed -i.bak "
            s# -l$1# -l$3 -l$1#
            s#Libs.private:.*#& $LIBS -L\${prefix}/$2#
            " "$LOCALDESTDIR/lib/pkgconfig/$1.pc"
    }

    _qt_version=5.15 # Version that vlc uses
    # $PKG_CONFIG --exists Qt5{Core,Widgets,Gui,Quick{,Widgets,Controls2},Svg}

    # Qt compilation takes ages.
    export QMAKE_CXX=$CXX QMAKE_CC=$CC
    export MSYS2_ARG_CONV_EXCL="--foreign-types="
    _check=(bin/qmake.exe Qt5Core.pc Qt5Gui.pc Qt5Widgets.pc)
    if do_vcs "https://github.com/qt/qtbase.git#branch=${_qt_version:=5.15}"; then
        do_uninstall include/QtCore share/mkspecs "${_check[@]}"
        # Enable ccache on !unix and use cygpath to fix certain issues
        do_patch "https://raw.githubusercontent.com/m-ab-s/mabs-patches/master/qtbase/0001-qtbase-mabs.patch" am
        do_patch "https://code.videolan.org/videolan/vlc/-/raw/master/contrib/src/qt/0003-allow-cross-compilation-of-angle-with-wine.patch" am
        do_patch "https://raw.githubusercontent.com/m-ab-s/mabs-patches/master/qtbase/0003-Remove-wine-prefix-before-fxc2.patch" am
        do_patch "https://code.videolan.org/videolan/vlc/-/raw/master/contrib/src/qt/0006-ANGLE-don-t-use-msvc-intrinsics-when-crosscompiling-.patch" am
        do_patch "https://code.videolan.org/videolan/vlc/-/raw/master/contrib/src/qt/0009-Add-KHRONOS_STATIC-to-allow-static-linking-on-Windows.patch" am
        do_patch "https://raw.githubusercontent.com/m-ab-s/mabs-patches/master/qtbase/0006-qt_module.prf-don-t-create-libtool-if-not-unix.patch" am
        do_patch "https://raw.githubusercontent.com/m-ab-s/mabs-patches/master/qtbase/0007-qmake-Patch-win32-g-for-static-builds.patch" am
        cp -f src/3rdparty/angle/src/libANGLE/{,libANGLE}Debug.cpp
        grep_and_sed "src/libANGLE/Debug.cpp" src/angle/src/common/gles_common.pri \
            "s#src/libANGLE/Debug.cpp#src/libANGLE/libANGLEDebug.cpp#g"

        QT5Base_config=(
            -prefix "$LOCALDESTDIR"
            -datadir "$LOCALDESTDIR"
            -archdatadir "$LOCALDESTDIR"
            -opensource
            -confirm-license
            -release
            -static
            -platform "$(
                case $CC in
                *clang) echo win32-clang-g++ ;;
                *) echo win32-g++ ;;
                esac
            )"
            -make-tool make
            -qt-{libjpeg,freetype,zlib}
            -angle
            -no-{shared,fontconfig,pkg-config,sql-sqlite,gif,openssl,dbus,vulkan,sql-odbc,pch,compile-examples,glib,direct2d,feature-testlib}
            -skip qtsql
            -nomake examples
            -nomake tests
        )
        if [[ $strip == y ]]; then
            QT5Base_config+=(-strip)
        fi
        if [[ $ccache == y ]]; then
            QT5Base_config+=(-ccache)
        fi
        # can't use regular do_configure since their configure doesn't follow
        # standard and uses single dash args
        log "configure" ./configure "${QT5Base_config[@]}"

        do_make
        do_makeinstall

        _add_static_link Qt5Gui plugins/imageformats qjpeg
        grep_or_sed "QtGui/$(qmake -query QT_VERSION)/QtGui" "$LOCALDESTDIR/lib/pkgconfig/Qt5Gui.pc" \
            "s;Cflags:.*;& -I\${includedir}/QtGui/$(qmake -query QT_VERSION)/QtGui;"
        _add_static_link Qt5Gui plugins/platforms qwindows
        _add_static_link Qt5Widgets plugins/styles qwindowsvistastyle

        cat >> "$LOCALDESTDIR/mkspecs/win32-g++/qmake.conf" <<'EOF'
CONFIG += static
EOF
        do_checkIfExist
    fi

    _deps=(Qt5Core.pc)
    _check=(Qt5Quick.pc Qt5Qml.pc)
    if do_vcs "https://github.com/qt/qtdeclarative.git#branch=$_qt_version"; then
        do_uninstall "${_check[@]}"
        do_patch "https://raw.githubusercontent.com/m-ab-s/mabs-patches/master/qtdeclarative/0001-features-hlsl_bytecode_header.prf-Use-DXSDK_DIR-for-.patch" am
        git cherry-pick 0b9fcb829313d0eaf2b496bf3ad44e5628fa43b2 > /dev/null 2>&1 ||
            git cherry-pick --abort
        do_qmake
        do_makeinstall
        _add_static_link Qt5Quick qml/QtQuick.2 qtquick2plugin
        _add_static_link Qt5Quick qml/QtQuick/Layouts qquicklayoutsplugin
        _add_static_link Qt5Quick qml/QtQuick/Window.2 windowplugin
        _add_static_link Qt5Qml qml/QtQml/Models.2 modelsplugin
        do_checkIfExist
    fi

    _deps=(Qt5Core.pc)
    _check=(Qt5Svg.pc)
    if do_vcs "https://github.com/qt/qtsvg.git#branch=$_qt_version"; then
        do_uninstall "${_check[@]}"
        do_qmake
        do_makeinstall
        _add_static_link Qt5Svg plugins/iconengines qsvgicon
        _add_static_link Qt5Svg plugins/imageformats qsvg
        do_checkIfExist
    fi

    _deps=(Qt5Core.pc Qt5Quick.pc Qt5Qml.pc)
    _check=("$LOCALDESTDIR/qml/QtGraphicalEffects/libqtgraphicaleffectsplugin.a")
    if do_vcs "https://github.com/qt/qtgraphicaleffects.git#branch=$_qt_version"; then
        do_uninstall "${_check[@]}"
        do_qmake
        do_makeinstall
        _add_static_link Qt5QuickWidgets qml/QtGraphicalEffects qtgraphicaleffectsplugin
	    _add_static_link Qt5QuickWidgets qml/QtGraphicalEffects/private qtgraphicaleffectsprivate
        do_checkIfExist
    fi

    _deps=(Qt5Core.pc Qt5Quick.pc Qt5Qml.pc)
    _check=(Qt5QuickControls2.pc)
    if do_vcs "https://github.com/qt/qtquickcontrols2.git#branch=$_qt_version"; then
        do_uninstall "${_check[@]}"
        do_qmake
        do_makeinstall
        _add_static_link Qt5QuickControls2 qml/QtQuick/Controls.2 qtquickcontrols2plugin
        _add_static_link Qt5QuickControls2 qml/QtQuick/Templates.2 qtquicktemplates2plugin
        do_checkIfExist
    fi

    _check=(libspatialaudio.a spatialaudio/Ambisonics.h spatialaudio.pc)
    if do_vcs "https://github.com/videolabs/libspatialaudio.git"; then
        do_uninstall include/spatialaudio "${_check[@]}"
        do_cmakeinstall
        do_checkIfExist
    fi

    _check=(libshout.{,l}a shout.pc shout/shout.h)
    if do_vcs "https://gitlab.xiph.org/xiph/icecast-libshout.git" libshout; then
        do_git_submodule
        do_uninstall "${_check[@]}"
        do_autoreconf
        CFLAGS+=" -include ws2tcpip.h" do_separate_confmakeinstall --disable-examples LIBS="$($PKG_CONFIG --libs openssl)"
        do_checkIfExist
    fi

    _check=(bin/protoc.exe libprotobuf-lite.{,l}a libprotobuf.{,l}a protobuf{,-lite}.pc)
    if do_vcs "https://github.com/protocolbuffers/protobuf.git"; then
        do_uninstall include/google/protobuf "${_check[@]}"
        do_autogen
        do_separate_confmakeinstall
        do_checkIfExist
    fi

    _check=(pixman-1.pc libpixman-1.a pixman-1/pixman.h)
    if do_vcs "https://gitlab.freedesktop.org/pixman/pixman.git"; then
        do_uninstall include/pixman-1 "${_check[@]}"
        do_patch "https://raw.githubusercontent.com/m-ab-s/mabs-patches/master/pixman/0001-pixman-pixman-mmx-fix-redefinition-of-_mm_mulhi_pu16.patch" am
        NOCONFIGURE=y do_autogen
        CFLAGS="-msse2 -mfpmath=sse -mstackrealign $CFLAGS" \
            do_separate_confmakeinstall
        do_checkIfExist
    fi

    _check=(libmedialibrary.a medialibrary.pc medialibrary/IAlbum.h)
    if do_vcs "https://code.videolan.org/videolan/medialibrary.git"; then
        do_uninstall include/medialibrary "${_check[@]}"
        do_mesoninstall -Dtests=disabled -Dlibvlc=disabled
        do_checkIfExist
    fi

    _check=(libthai.pc libthai.{,l}a thai/thailib.h)
    if do_vcs "https://github.com/tlwg/libthai.git"; then
        do_uninstall include/thai "${_check[@]}"
        do_autogen
        do_separate_confmakeinstall
        do_checkIfExist
    fi

    _check=(libebml.a ebml/ebml_export.h libebml.pc lib/cmake/EBML/EBMLTargets.cmake)
    if do_vcs "https://github.com/Matroska-Org/libebml.git"; then
        do_uninstall include/ebml lib/cmake/EBML "${_check[@]}"
        do_cmakeinstall
        do_checkIfExist
    fi

    _check=(libmatroska.a libmatroska.pc matroska/KaxTypes.h lib/cmake/Matroska/MatroskaTargets.cmake)
    if do_vcs "https://github.com/Matroska-Org/libmatroska.git"; then
        do_uninstall include/matroska lib/cmake/Matroska "${_check[@]}"
        do_cmakeinstall
        do_checkIfExist
    fi

    _check=("$LOCALDESTDIR"/vlc/bin/{{c,r}vlc,vlc.exe,libvlc.dll}
            "$LOCALDESTDIR"/vlc/libexec/vlc/vlc-cache-gen.exe
            "$LOCALDESTDIR"/vlc/lib/pkgconfig/libvlc.pc
            "$LOCALDESTDIR"/vlc/include/vlc/libvlc_version.h)
    if do_vcs "https://code.videolan.org/videolan/vlc.git"; then
        do_uninstall bin/plugins lib/vlc "${_check[@]}"
        _mabs_vlc=https://raw.githubusercontent.com/m-ab-s/mabs-patches/master/vlc
        do_patch "https://code.videolan.org/videolan/vlc/-/merge_requests/155.patch" am
        do_patch "$_mabs_vlc/0001-modules-access-srt-Use-srt_create_socket-instead-of-.patch" am
        do_patch "$_mabs_vlc/0002-modules-codec-libass-Use-ass_set_pixel_aspect-instea.patch" am
        do_patch "$_mabs_vlc/0003-Use-libdir-for-plugins-on-msys2.patch" am
        do_patch "$_mabs_vlc/0004-include-vlc_fixups.h-fix-iovec-is-redefined-errors.patch" am
        do_patch "$_mabs_vlc/0005-include-vlc_common.h-fix-snprintf-and-vsnprintf-rede.patch" am
        do_patch "$_mabs_vlc/0006-configure.ac-check-if-_WIN32_IE-is-already-defined.patch" am
        do_patch "$_mabs_vlc/0007-modules-stream_out-rtp-don-t-redefine-E-defines.patch" am
        do_patch "$_mabs_vlc/0008-include-vlc_codecs.h-don-t-redefine-WAVE_FORMAT_PCM.patch" am
        do_patch "$_mabs_vlc/0009-modules-audio_filter-channel_mixer-spatialaudio-add-.patch" am
        do_patch "$_mabs_vlc/0010-modules-access_output-don-t-put-lgpg-error-for-liveh.patch" am

        do_autoreconf
        # All of the disabled are because of multiple issues both on the installed libs and on vlc's side.
        # Maybe set up vlc_options.txt

        # Can't disable shared since vlc will error out. I don't think enabling static will really do anything for us other than breaking builds.
        create_build_dir
        config_path=".." do_configure \
            --prefix="$LOCALDESTDIR/vlc" \
            --sysconfdir="$LOCALDESTDIR/vlc/etc" \
            --{build,host,target}="$MINGW_CHOST" \
            --enable-{shared,avcodec,merge-ffmpeg,qt,nls} \
            --disable-{static,dbus,fluidsynth,svgdec,aom,mod,ncurses,mpg123,notify,svg,secret,telx,ssp,lua,gst-decode,nvdec} \
            --with-binary-version="MABS" BUILDCC="$CC" \
            CFLAGS="$CFLAGS -DGLIB_STATIC_COMPILATION -DQT_STATIC -DGNUTLS_INTERNAL_BUILD -DLIBXML_STATIC -DLIBXML_CATALOG_ENABLED" \
            LIBS="$($PKG_CONFIG --libs libcddb regex iconv) -lwsock32 -lws2_32 -lpthread -liphlpapi"
        do_makeinstall
        do_checkIfExist
        PATH="$LOCALDESTDIR/vlc/bin:$PATH" "$LOCALDESTDIR/vlc/libexec/vlc/vlc-cache-gen" "$LOCALDESTDIR/vlc/lib/plugins"
    fi
fi

_check=(bin-video/ffmbc.exe)
if [[ $ffmbc = y ]] && do_vcs "$SOURCE_REPO_FFMBC"; then
    _notrequired=true
    create_build_dir
    # Too many errors with GCC 15 due to really old code.
    CFLAGS+=" -Wno-error=incompatible-pointer-types" \
        log configure ../configure --target-os=mingw32 --enable-gpl \
        --disable-{dxva2,ffprobe} --extra-cflags=-DNO_DSHOW_STRSAFE \
        --cc="$CC" --ld="$CXX"
    do_make
    do_install ffmbc.exe bin-video/
    do_checkIfExist
    unset _notrequired
fi

do_simple_print -p "${orange}Finished $bits compilation of all tools${reset}"
}

run_builds() {
    new_updates=no
    new_updates_packages=""
    if [[ $build32 = yes ]]; then
        source /local32/etc/profile2.local
        buildProcess
    fi

    if [[ $build64 = yes ]]; then
        source /local64/etc/profile2.local
        buildProcess
    fi
}

cd_safe "$LOCALBUILDDIR"
run_builds

if [[ $exitearly = EE2 || $exitearly = EE3 || $exitearly = EE4 || $exitearly = EE5 || $exitearly = EE6 ]]; then
    exit 0
fi

while [[ $new_updates = yes ]]; do
    ret=no
    printf '%s\n' \
        "-------------------------------------------------------------------------------" \
        "There were new updates while compiling." \
        "Updated:$new_updates_packages" \
        "Would you like to run compilation again to get those updates? Default: no"
    do_prompt "y/[n] "
    echo "-------------------------------------------------------------------------------"
    if [[ $ret = y || $ret = Y || $ret = yes ]]; then
        run_builds
    else
        break
    fi
done

clean_suite
if [[ -f $LOCALBUILDDIR/post_suite.sh ]]; then
    do_simple_print -p "${green}Executing post_suite.sh${reset}"
    source "$LOCALBUILDDIR"/post_suite.sh || true
fi
do_simple_print -p "${green}Compilation successful.${reset}"
do_simple_print -p "${green}This window will close automatically in 5 seconds.${reset}"
sleep 5
