#!/bin/bash

if which tput >/dev/null 2>&1; then
    ncolors=$(tput colors)
    if test -n "$ncolors" && test "$ncolors" -ge 8; then
        bold_color=$(tput bold)
        blue_color=$(tput setaf 4)
        orange_color=$(tput setaf 3)
        green_color=$(tput setaf 2)
        red_color=$(tput setaf 1)
        reset_color=$(tput sgr0)
    fi
    ncols=72
fi

[[ -f "$LOCALBUILDDIR"/grep.exe ]] &&
    rm -f "$LOCALBUILDDIR"/{7za,wget,grep}.exe

do_print_status() {
    local name="$1 "
    local color="$2"
    local status="$3"
    local pad
    pad=$(printf '%0.1s' "."{1..72})
    local padlen=$((ncols-${#name}-${#status}-3))
    printf '%s%*.*s [%s]\n' "${bold_color}$name${reset_color}" 0 \
        "$padlen" "$pad" "${color}${status}${reset_color}"
}

do_print_progress() {
    if [[ $logging != n ]]; then
        echo "├ $*..."
    else
        echo -e "\e]0;$* in $(get_first_subdir)\007"
        echo -e "${bold_color}$* in $(get_first_subdir)${reset_color}"
    fi
}

cd_safe() {
    cd "$1" ||
        { do_prompt "Failed changing to directory $1." && exit 1; }
}

vcs_clone() {
    if [[ "$vcsType" = "svn" ]]; then
        svn checkout -q -r "$ref" "$vcsURL" "$vcsFolder"-svn
    else
        "$vcsType" clone -q "$vcsURL" "$vcsFolder-$vcsType"
    fi
}

vcs_update() {
    if [[ "$vcsType" = "svn" ]]; then
        oldHead=$(svnversion)
        svn update -q -r "$ref"
        newHead=$(svnversion)
    elif [[ "$vcsType" = "hg" ]]; then
        hg -q update -C -r "$ref"
        oldHead=$(hg id --id)
        hg -q pull
        hg -q update -C -r "$ref"
        newHead=$(hg id --id)
    elif [[ "$vcsType" = "git" ]]; then
        local unshallow=""
        [[ -f .git/shallow ]] && unshallow="--unshallow"
        [[ "$vcsURL" != "$(git config --get remote.origin.url)" ]] &&
            git remote set-url origin "$vcsURL"
        [[ "ab-suite" != "$(git rev-parse --abbrev-ref HEAD)" ]] && git reset -q --hard "@{u}"
        [[ "$(git config --get remote.origin.fetch)" = "+refs/heads/master:refs/remotes/origin/master" ]] &&
            git config -q remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
        git checkout -qf --no-track -B ab-suite "$ref"
        git fetch -qt $unshallow origin
        oldHead=$(git rev-parse HEAD)
        git checkout -qf --no-track -B ab-suite "$ref"
        newHead=$(git rev-parse HEAD)
    fi
}

vcs_log() {
    if [[ "$vcsType" = "git" ]]; then
        git log --no-merges --pretty="%ci %h %s" \
            --abbrev-commit "$oldHead".."$newHead" >> "$LOCALBUILDDIR"/newchangelog
    elif [[ "$vcsType" = "hg" ]]; then
        hg log --template "{date|localdate|isodatesec} {node|short} {desc|firstline}\n" \
            -r "reverse($oldHead:$newHead)" >> "$LOCALBUILDDIR"/newchangelog
    fi
}

# get source from VCS
# example:
#   do_vcs "url#branch|revision|tag|commit=NAME" "folder" "lib/libname.a"
do_vcs() {
    local vcsType="${1%::*}"
    local vcsURL="${1#*::}"
    shift
    [[ "$vcsType" = "$vcsURL" ]] && vcsType="git"
    local vcsBranch="${vcsURL#*#}"
    [[ "$vcsBranch" = "$vcsURL" ]] && vcsBranch=""
    local vcsFolder="$1"
    shift
    local vcsCheck=()
    for opt; do vcsCheck+=($opt); done
    local ref=""
    if [[ -n "$vcsBranch" ]]; then
        vcsURL="${vcsURL%#*}"
        case ${vcsBranch%%=*} in
            commit|tag|revision)
                ref=${vcsBranch##*=}
                ;;
            branch)
                ref=origin/${vcsBranch##*=}
                ;;
        esac
    else
        if [[ "$vcsType" = "git" ]]; then
            ref="origin/HEAD"
        elif [[ "$vcsType" = "hg" ]]; then
            ref="tip"
        elif [[ "$vcsType" = "svn" ]]; then
            ref="HEAD"
        fi
    fi
    [[ -z "$vcsFolder" ]] && vcsFolder="${vcsURL##*/}" && vcsFolder="${vcsFolder%.*}"
    compile="false"

    cd_safe "$LOCALBUILDDIR"
    if [[ ! -d "$vcsFolder-$vcsType" ]]; then
        vcs_clone
        if [[ -d "$vcsFolder-$vcsType" ]]; then
            cd_safe "$vcsFolder-$vcsType"
            touch recently_updated
        else
            echo "$vcsFolder $vcsType seems to be down"
            echo "Try again later or <Enter> to continue"
            do_prompt "if you're sure nothing depends on it."
            return
        fi
    else
        cd_safe "$vcsFolder-$vcsType"
    fi
    vcs_update
    compile="true"
    if [[ "$oldHead" != "$newHead" ]]; then
        touch recently_updated
        rm -f build_successful{32,64}bit
        if [[ $build32 = "yes" && $build64 = "yes" ]] && [[ $bits = "64bit" ]]; then
            new_updates="yes"
            new_updates_packages="$new_updates_packages [$vcsFolder]"
        fi
        echo "$vcsFolder" >> "$LOCALBUILDDIR"/newchangelog
        vcs_log
        echo "" >> "$LOCALBUILDDIR"/newchangelog
        do_print_status "┌ ${vcsFolder} ${vcsType}" "$orange_color" "Updates found"
    elif [[ -f recently_updated && ! -f "build_successful$bits" ]]; then
        do_print_status "┌ ${vcsFolder} ${vcsType}" "$orange_color" "Recently updated"
    elif [[ -z "$vcsCheck" ]] && ! files_exist "$vcsFolder.pc"; then
        do_print_status "┌ ${vcsFolder} ${vcsType}" "$orange_color" "Missing pkg-config"
    elif [[ ! -z "$vcsCheck" ]] && ! files_exist "${vcsCheck[@]}"; then
        do_print_status "┌ ${vcsFolder} ${vcsType}" "$orange_color" "Files missing"
    else
        do_print_status "${vcsFolder} ${vcsType}" "$green_color" "Up-to-date"
        compile="false"
    fi
}

# get wget download
do_wget() {
    local url="$1"
    local archive="$2"
    local dirName="$3"
    if [[ -z $archive ]]; then
        # remove arguments and filepath
        archive=${url%%\?*}
        archive=${archive##*/}
    fi
    [[ -z "$dirName" ]] && dirName=$(expr "$archive" : '\(.\+\)\.\(tar\(\.\(gz\|bz2\|xz\)\)\?\|7z\|zip\)$')
    local response_code
    cd_safe "$LOCALBUILDDIR"
    response_code="$(curl --retry 20 --retry-max-time 5 -s -L -k -f -w "%{response_code}" -o "$archive" "$url")"
    if [[ $response_code = "200" || $response_code = "226" ]]; then
        do_print_status "┌ $dirName" "$orange_color" "Updates found"
        archive="$(pwd)/${archive}"
        log "extract" do_extract "$archive" "$dirName"
        [[ $deleteSource = "y" ]] && rm -f "$archive"
    elif [[ $response_code -gt 400 ]]; then
        echo "Error $response_code while downloading $URL"
        echo "Try again later or <Enter> to continue"
        do_prompt "if you're sure nothing depends on it."
    fi
}

do_extract() {
    local archive="$1"
    local dirName="$2"
    # accepted: zip, 7z, tar.gz, tar.bz2 and tar.xz
    local archive_type
    archive_type=$(expr "$archive" : '.\+\(tar\(\.\(gz\|bz2\|xz\)\)\?\|7z\|zip\)$')

    if [[ -d "$dirName" && $archive_type = tar* ]] &&
        { [[ $build32 = "yes" && ! -f "$dirName"/build_successful32bit ]] ||
          [[ $build64 = "yes" && ! -f "$dirName"/build_successful64bit ]]; }; then
        rm -rf "$dirName"
    fi
    case $archive_type in
    zip)
        unzip "$archive"
        ;;
    7z)
        7z x -o"$dirName" "$archive"
        ;;
    tar*)
        tar -xaf "$archive" || 7z x "$archive" -so | 7z x -aoa -si -ttar
        cd_safe "$dirName"
        ;;
    esac
}

do_wget_sf() {
    # do_wget_sf "faac/faac-src/faac-1.28/faac-$_ver.tar.bz2" "faac-$_ver"
    local url="$1"
    shift 1
    local dir="${url:0:1}/${url:0:2}"
    do_wget "http://download.sourceforge.net/${url}" "$@"
}

do_strip() {
    local nostrip="x265|x265-numa|ffmpeg|ffprobe|ffplay"
    local file
    [[ -n $(find "$LOCALDESTDIR"/bin-video -name "mpv.exe.debug") ]] && nostrip+="|mpv"
    [[ ${*%.exe} != $* || ${*%.dll} != $* ]] && do_print_progress Stripping
    for file; do
        if echo "$file" | grep -qE "\.(exe|dll|com)$" &&
            echo "$file" | grep -qvE "(${nostrip})\.exe"; then
            strip -s "$LOCALDESTDIR/$file"
        elif echo "$file" | grep -qE "x265(|-numa)\.exe"; then
            strip --strip-unneeded "$LOCALDESTDIR/$file"
        fi
    done
}

# check if compiled file exist
do_checkIfExist() {
    local packetName
    packetName="$(get_first_subdir)"
    [[ $1 = dry ]] && local dry=y && shift
    if [[ $dry ]]; then
        files_exist -v -s "$@"
    else
        if files_exist -v "$@"; then
            [[ $stripping = y ]] && do_strip "$@"
            do_print_status "└ $packetName" "$blue_color" "Updated"
            [[ $build32 = yes || $build64 = yes ]] && [[ -d "$LOCALBUILDDIR/$packetName" ]] &&
                touch "$LOCALBUILDDIR/$packetName/build_successful$bits"
        else
            [[ $build32 = yes || $build64 = yes ]] && [[ -d "$LOCALBUILDDIR/$packetName" ]] &&
                rm -f "$LOCALBUILDDIR/$packetName/build_successful$bits"
            do_print_status "└ $packetName" "$red_color" "Failed"
            echo
            echo "Try deleting '$LOCALBUILDDIR/$packetName' and start the script again."
            echo "If you're sure there are no dependencies <Enter> to continue building."
            do_prompt "Close this window if you wish to stop building."
        fi
    fi
}

file_installed() {
    local file
    case $1 in
        *.pc )
            file="lib/pkgconfig/$1" ;;
        *.a|*.la|*.lib )
            file="lib/$1" ;;
        *.h|*.hpp )
            file="include/$1" ;;
        * )
            file="$1" ;;
    esac
    file="$LOCALDESTDIR/$file"
    echo "$file" && test -e "$file"
}

files_exist() {
    local verbose list soft term="\n"
    while true; do
        case $1 in
            -v) verbose=y && shift;;
            -l) list=y && shift;;
            -s) soft=y && shift;;
            -l0) list=y && term="\0" && shift;;
            --) shift; break;;
            *) break;;
        esac
    done
    local file
    [[ $list ]] && verbose= && soft=y
    for opt; do
        if file=$(file_installed $opt); then
            [[ $verbose && $soft ]] && do_print_status "├ $file" "${green_color}" "Found"
            [[ $list ]] && echo -n "$file" && echo -ne "$term"
        else
            [[ $verbose ]] && do_print_status "├ $file" "${red_color}" "Not found"
            [[ ! $soft ]] && return 1
        fi
    done
    return 0
}

pc_exists() {
    for opt; do
        local pkg=${opt%% *}
        local check=${opt#$pkg}
        [[ $pkg = "$check" ]] && check=""
        [[ $pkg = *.pc ]] || pkg="${LOCALDESTDIR}/lib/pkgconfig/${pkg}.pc"
        pkg-config --exists --silence-errors "${pkg}${check}" || return
    done
}

do_uninstall() {
    [[ $1 = dry ]] && local dry=y && shift
    [[ $1 = q ]] && local quiet=y && shift
    local files=($(files_exist -l "$@"))
    if [[ $files ]]; then
        [[ ! quiet ]] && do_print_progress Running uninstall
        if [[ $dry ]]; then
            echo "rm -rf ${files[@]}"
        else
            rm -rf "${files[@]}"
        fi
    fi
}

do_pkgConfig() {
    local pkg=${1%% *}
    local check=${1#$pkg}
    [[ $pkg = "$check" ]] && check=""
    local version=$2
    [[ -z "$version" && -n "$check" ]] && version="${check#*= }"
    if ! pc_exists "${pkg}"; then
        do_print_status "${pkg} ${version}" "$red_color" "Not found"
    elif ! pc_exists "${pkg}${check}"; then
        do_print_status "${pkg} ${version}" "$orange_color" "Outdated"
    else
        do_print_status "${pkg} ${version}" "$green_color" "Up-to-date"
        return 1
    fi
}

do_getFFmpegConfig() {
    local license="$1"
    local configfile="$LOCALBUILDDIR"/ffmpeg_options.txt
    if [[ -f "$configfile" ]] && [[ $ffmpegChoice != "n" ]]; then
        FFMPEG_DEFAULT_OPTS=($(sed -e 's:\\::g' -e 's/#.*//' "$configfile" | tr '\n' ' '))
        echo "Imported FFmpeg options from ffmpeg_options.txt"
    elif [[ -f "/trunk/media-autobuild_suite.bat" ]] && [[ $ffmpegChoice != "y" ]]; then
        FFMPEG_DEFAULT_OPTS=($(sed -rne '/ffmpeg_options=/,/[^^]$/p' /trunk/media-autobuild_suite.bat | \
            sed -e 's/.*ffmpeg_options=//' -e 's/ ^//g' | tr '\n' ' '))
        echo "Imported default FFmpeg options from .bat"
    else
        echo "Using default FFmpeg options"
    fi
    echo "License: $license"
    FFMPEG_OPTS=("${FFMPEG_BASE_OPTS[@]}" "${FFMPEG_DEFAULT_OPTS[@]}")

    if [[ $bits = "32bit" ]]; then
        arch=x86
    else
        arch=x86_64
    fi
    export arch

    # we set these accordingly for static or shared
    do_removeOption "--(en|dis)able-(shared|static)"

    # OK to use GnuTLS for rtmpdump if not nonfree since GnuTLS was built for rtmpdump anyway
    # If nonfree will use SChannel if neither openssl or gnutls are in the options
    if ! enabled_any openssl gnutls && enabled librtmp; then
        if [[ $license = gpl* ]]; then
            do_addOption --enable-gnutls
        else
            do_addOption --enable-openssl
        fi
        do_removeOption "--enable-(gmp|gcrypt)"
    fi

    if enabled openssl && [[ $license != gpl* ]]; then
        # prefer openssl if both are in options and not gpl
        do_removeOption --enable-gnutls
    elif enabled openssl; then
        # prefer gnutls if both are in options and gpl
        do_removeOption --enable-openssl
        do_addOption --enable-gnutls
    fi

    # handle WinXP-incompatible libs
    if [[ $xpcomp = "y" ]]; then
        do_removeOptions --enable-libmfx --enable-decklink --enable-tesseract \
            --enable-opencl --enable-libcaca
    fi
}

do_changeFFmpegConfig() {
    local license="$1"
    do_print_progress Changing options to comply to "$license"
    # if w32threads is disabled, pthreads is used and needs this cflag
    # decklink depends on pthreads
    if disabled w32threads || enabled_any pthreads decklink; then
        do_removeOption --enable-w32threads
        do_addOptions --disable-w32threads --extra-cflags=-DPTW32_STATIC_LIB \
            --extra-libs=-lpthread --extra-libs=-lwsock32
    fi

    # add options for static kvazaar
    enabled libkvazaar && do_addOption "--extra-cflags=-DKVZ_STATIC_LIB"

    # handle gpl libs
    local gpl=(frei0r lib{cdio,rubberband,utvideo,vidstab,x264,x265,xavs,xvid,zvbi})
    if [[ $license = gpl* || $license = nonfree ]] && enabled_any "${gpl[@]}"; then
        do_addOption --enable-gpl
    else
        do_removeOptions "${gpl[*]/#/--enable-} --enable-gpl"
    fi

    # handle (l)gplv3 libs
    local version3=(libopencore-amr{wb,nb} libvo-amrwbenc gmp)
    if [[ $license = *v3 || $license = nonfree ]] && enabled_any "${version3[@]}"; then
        do_addOption --enable-version3
    else
        do_removeOptions "${version3[*]/#/--enable-} --enable-version3"
    fi

    # handle non-free libs
    local nonfree=(nvenc libfaac)
    if [[ $license = "nonfree" ]] && enabled_any "${nonfree[@]}"; then
        do_addOption "--enable-nonfree"
    else
        do_removeOptions "${nonfree[*]/#/--enable-} --enable-nonfree"
    fi

    # handle gpl-incompatible libs
    local nonfreegpl=(libfdk-aac openssl)
    if enabled_any "${nonfreegpl[@]}"; then
        if [[ $license = "nonfree" ]]; then
            do_addOption "--enable-nonfree"
        elif [[ $license = gpl* ]]; then
            do_removeOptions "${nonfreegpl[*]/#/--enable-}"
        fi
        # no lgpl here because they are accepted with it
    fi

    enabled frei0r && do_addOption "--enable-filter=frei0r"

    if enabled debug; then
        # fix issue with ffprobe not working with debug and strip
        do_addOption "--disable-stripping"
    else
        do_addOption "--disable-debug"
    fi

    enabled openssl && do_removeOption "--enable-(gcrypt|gmp)"

    # remove libs that don't work with shared
    if [[ $ffmpeg = "s" || $ffmpeg = "b" ]]; then
        FFMPEG_OPTS_SHARED=("${FFMPEG_OPTS[@]}")
        do_removeOptions "--enable-decklink --enable-libutvideo --enable-libgme" y
        FFMPEG_OPTS_SHARED+=("--extra-ldflags=-static-libgcc")
    fi
}

do_checkForOptions() {
    local option
    for option in "$@"; do
        if /usr/bin/grep -qE -e "$option" <(echo "${FFMPEG_OPTS[*]}"); then
            return
        fi
    done
    return 1
}

enabled() {
    test "${FFMPEG_OPTS[*]}" != "${FFMPEG_OPTS[*]#--enable-$1}"
}

disabled() {
    test "${FFMPEG_OPTS[*]}" != "${FFMPEG_OPTS[*]#--disable-$1}"
}

enabled_any() {
    for opt; do
        enabled "$opt" && return 0
    done
    return 1
}

disabled_any() {
    for opt; do
        disabled "$opt" && return 0
    done
    return 1
}

do_getMpvConfig() {
    local configfile="$LOCALBUILDDIR"/mpv_options.txt
    if [[ -f $configfile ]]; then
        MPV_OPTS=($(sed -e 's:\\::g' -e 's/#.*//' "$configfile" | tr '\n' ' '))
        echo "Imported mpv options from mpv_options.txt"
    elif [[ -f "/trunk/media-autobuild_suite.bat" ]] && [[ $ffmpegChoice != "y" ]]; then
        MPV_OPTS=($(sed -rne '/mpv_options=/,/[^^]$/p' /trunk/media-autobuild_suite.bat | \
            sed -e 's/.*mpv_options=//' -e 's/ ^//g' | tr '\n' ' '))
        echo "Imported default mpv options from .bat"
    else
        echo "Using default mpv options"
    fi
    if [[ $mpv = "v" ]]; then
        ! mpv_enabled vapoursynth && ! mpv_disabled vapoursynth &&
            MPV_OPTS+=(--enable-vapoursynth)
    elif [[ $mpv = "y" ]]; then
        mpv_enabled vapoursynth && mpv_disable vapoursynth
        mpv_disabled vapoursynth || MPV_OPTS+=(--disable-vapoursynth)
    fi
}

mpv_enabled() {
    [[ $mpv = n ]] && return 1
    test "${MPV_OPTS[*]}" != "${MPV_OPTS[*]#--enable-$1}"
}

mpv_disabled() {
    [[ $mpv = n ]] && return 0
    test "${MPV_OPTS[*]}" != "${MPV_OPTS[*]#--disable-$1}"
}

mpv_enabled_all() {
    for opt; do
        mpv_enabled $opt || return 1
    done
}

mpv_disabled_all() {
    for opt; do
        mpv_disabled $opt || return 1
    done
}

mpv_enable() {
    mpv_disabled $1 && MPV_OPTS=(${MPV_OPTS[@]//--disable-$1/--enable-$1})
}

mpv_disable() {
    mpv_enabled $1 && MPV_OPTS=(${MPV_OPTS[@]//--enable-$1/--disable-$1})
}

do_addOption() {
    local option="$1"
    if ! do_checkForOptions $option; then
        FFMPEG_OPTS+=("$option")
    fi
}

do_addOptions() {
    local option
    for option in "$@"; do
        do_addOption "$option"
    done
}

do_removeOption() {
    local option=$1
    local shared=$2
    if [[ $shared = "y" ]]; then
        FFMPEG_OPTS_SHARED=($(echo "${FFMPEG_OPTS_SHARED[*]}" | sed -r "s/ *$option//g"))
    else
        FFMPEG_OPTS=($(echo "${FFMPEG_OPTS[*]}" | sed -r "s/ *$option//g"))
    fi
}

do_removeOptions() {
    local option
    local shared=$2
    for option in $1; do
        do_removeOption "$option" "$shared"
    done
}

do_patch() {
    local patch=${1%% *}
    local am=$2     # "am" to apply patch with "git am"
    local strip=$3  # value of "patch" -p i.e. leading directories to strip
    if [[ -z $strip ]]; then
        strip="1"
    fi
    local patchpath=""
    local response_code
    response_code="$(curl -s --retry 20 --retry-max-time 5 -L -k -f -w "%{response_code}" \
        -O "https://raw.github.com/jb-alvarado/media-autobuild_suite/master${LOCALBUILDDIR}/patches/$patch")"

    if [[ $response_code != "200" ]]; then
        echo -e "${orange_color}${patch}${reset_color}"
        echo -e "\tPatch not found online. Trying local copy."
        if [[ -f "./$patch" ]]; then
            patchpath="$patch"
        elif [[ -f "$LOCALBUILDDIR/patches/${patch}" ]]; then
            patchpath="$LOCALBUILDDIR/patches/${patch}"
        fi
    else
        patchpath="$patch"
    fi
    if [[ -n "$patchpath" ]]; then
        if [[ "$am" = "am" ]]; then
            if ! git am -q --ignore-whitespace "$patchpath" >/dev/null 2>&1; then
                git am -q --abort
                echo -e "${orange_color}${patchpath##*/}${reset_color}"
                echo -e "\tPatch couldn't be applied with 'git am'. Continuing without patching."
            fi
        else
            if patch --dry-run -s -N -p$strip -i "$patchpath" >/dev/null 2>&1; then
                patch -s -N -p$strip -i "$patchpath"
            else
                echo -e "${orange_color}${patchpath##*/}${reset_color}"
                echo -e "\tPatch couldn't be applied with 'patch'. Continuing without patching."
            fi
        fi
    else
        echo -e "${orange_color}${patchpath##*/}${reset_color}"
        echo -e "\tPatch not found anywhere. Continuing without patching."
    fi
}

do_cmakeinstall() {
    create_build_dir
    log "cmake" cmake .. -G Ninja -DBUILD_SHARED_LIBS=off -DCMAKE_INSTALL_PREFIX="$LOCALDESTDIR" -DUNIX=on "$@"
    log "install" ninja -j"${cpuCount:-$(($(nproc)/2))}" install
}

compilation_fail() {
    local reason="$1"
    local operation
    operation="$(echo "$reason" | tr '[:upper:]' '[:lower:]')"
    echo "Likely error:"
    tail "ab-suite.${operation}.error.log"
    echo "${red_color}$reason failed. Check $(pwd)/ab-suite.$operation.error.log${reset_color}"
    if [[ -n "$_notrequired" ]]; then
        echo "This isn't required for anything so we can move on."
        return 1
    else
        echo "${red_color}This is required for other packages, so this script will exit.${reset_color}"
        zip_logs
        do_prompt "Try running the build again at a later time."
        exit 1
    fi
}

zip_logs() {
    local failed=$(get_first_subdir)
    pushd "$LOCALBUILDDIR" >/dev/null
    rm -f logs.zip
    7za -mx=9 a logs.zip *.log *.ini *_options.txt -ir!"$failed/*.log" >/dev/null
    popd >/dev/null
    [[ -f "$LOCALBUILDDIR/logs.zip" ]] &&
        echo "${green_color}Attach $LOCALBUILDDIR/logs.zip to the GitHub issue.${reset_color}"
}

log() {
    local cmd="$1"
    shift 1
    do_print_progress Running "$cmd"
    if [[ $logging != "n" ]]; then
        echo "$@" > "ab-suite.$cmd.log"
        "$@" >> "ab-suite.$cmd.log" 2> "ab-suite.$cmd.error.log" || compilation_fail "$cmd"
    else
        "$@" || compilation_fail "$cmd"
    fi
}

create_build_dir() {
    [[ -d build-$bits ]] && rm -rf "build-$bits"
    mkdir "build-$bits" && cd_safe "build-$bits"
}

do_separate_conf() {
    local bindir=""
    case "$1" in
    global) bindir="--bindir=$LOCALDESTDIR/bin-global" ;;
    audio) bindir="--bindir=$LOCALDESTDIR/bin-audio" ;;
    video) bindir="--bindir=$LOCALDESTDIR/bin-video" ;;
    *) bindir="$1" ;;
    esac
    shift 1
    create_build_dir
    log configure ../configure --build="$MINGW_CHOST" --prefix="$LOCALDESTDIR" \
        --disable-shared "$bindir" "$@"
}

do_separate_confmakeinstall() {
    do_separate_conf "$@"
    do_make
    do_makeinstall
    cd_safe ..
}

do_configure() {
    log "configure" ./configure "$@"
}

do_make() {
    log "make" make -j"${cpuCount:-$(($(nproc)/2))}" "$@"
}

do_makeinstall() {
    log "install" make -j"${cpuCount:-$(($(nproc)/2))}" install "$@"
}

do_hide_pacman_sharedlibs() {
    local packages="$1"
    local revert="$2"
    local files
    files="$(pacman -Qql "$packages" 2>/dev/null | /usr/bin/grep .dll.a)"

    for file in $files; do
        if [[ -f "${file%*.dll.a}.a" ]]; then
            if [[ -z "$revert" ]]; then
                mv -f "${file}" "${file}.dyn"
            elif [[ -n "$revert" && -f "${file}.dyn" && ! -f "${file}" ]]; then
                mv -f "${file}.dyn" "${file}"
            elif [[ -n "$revert" && -f "${file}.dyn" ]]; then
                rm -f "${file}.dyn"
            fi
        fi
    done
}

do_hide_all_sharedlibs() {
    [[ x"$1" = "xdry" ]] && local dryrun="y"
    local files
    files="$(find /mingw{32,64}/lib /mingw{32/i686,64/x86_64}-w64-mingw32/lib -name "*.dll.a" 2>/dev/null)"
    local tomove=()
    for file in $files; do
        [[ -f "${file%*.dll.a}.a" ]] && tomove+=("$file")
    done
    [[ $dryrun != "y" ]] &&
        printf "%s\n" "${tomove[@]}" | xargs -i mv -f '{}' '{}.dyn' || printf "%s\n" "${tomove[@]}"
}

do_unhide_all_sharedlibs() {
    [[ x"$1" = "xdry" ]] && local dryrun="y"
    local files
    files="$(find /mingw{32,64}/lib /mingw{32/i686,64/x86_64}-w64-mingw32/lib -name "*.dll.a.dyn" 2>/dev/null)"
    local tomove=()
    local todelete=()
    for file in $files; do
        if [[ -f "${file%*.dyn}" ]]; then
            todelete+=("$file")
        else
            tomove+=("${file%*.dyn}")
        fi
    done
    if [[ $dryrun != "y" ]]; then
        printf "%s\n" "${todelete[@]}" | xargs -i rm -f '{}'
        printf "%s\n" "${tomove[@]}" | xargs -i mv -f '{}.dyn' '{}'
    else
        printf "rm %s\n" "${todelete[@]}"
        printf "%s\n" "${tomove[@]}"
    fi
}

do_pacman_install() {
    local packages="$1"
    local installed
    local pkg
    local noop
    installed="$(pacman -Qqe | /usr/bin/grep "^${MINGW_PACKAGE_PREFIX}-")"
    for pkg in $packages; do
        [[ "$pkg" != "${MINGW_PACKAGE_PREFIX}-"* ]] && pkg="${MINGW_PACKAGE_PREFIX}-${pkg}"
        if /usr/bin/grep -q "^${pkg}$" <(echo "$installed"); then
            [[ -z $noop ]] && none=y
            continue
        else
            noop=n
        fi
        echo -n "Installing ${pkg#$MINGW_PACKAGE_PREFIX-}... "
        if pacman -S --force --noconfirm --needed "$pkg" >/dev/null 2>&1; then
            pacman -D --asexplicit "$pkg" >/dev/null
            /usr/bin/grep -q "^${pkg#$MINGW_PACKAGE_PREFIX-}$" /etc/pac-mingw-extra.pk >/dev/null 2>&1 ||
                echo "${pkg#$MINGW_PACKAGE_PREFIX-}" >> /etc/pac-mingw-extra.pk
            echo "done"
        else
            echo "failed"
        fi
    done
    do_hide_all_sharedlibs
    [[ $noop = y ]] && return 1
}

do_pacman_remove() {
    local packages="$1"
    local installed
    local pkg
    installed="$(pacman -Qqe | /usr/bin/grep "^${MINGW_PACKAGE_PREFIX}-")"
    for pkg in $packages; do
        [[ "$pkg" != "${MINGW_PACKAGE_PREFIX}-"* ]] && pkg="${MINGW_PACKAGE_PREFIX}-${pkg}"
        /usr/bin/grep -q "^${pkg}$" <(echo "$installed") || continue
        echo -n "Uninstalling ${pkg#$MINGW_PACKAGE_PREFIX-}... "
        do_hide_pacman_sharedlibs "$pkg" revert
        if pacman -Rs --noconfirm "$pkg" >/dev/null 2>&1; then
            sed -i "/^${pkg#$MINGW_PACKAGE_PREFIX-}$/d" /etc/pac-mingw-extra.pk >/dev/null 2>&1
            echo "done"
        else
            pacman -D --asdeps "$pkg" >/dev/null 2>&1
            echo "failed"
        fi
    done
    do_hide_all_sharedlibs
}

do_prompt() {
    # from http://superuser.com/a/608509
    while read -r -s -e -t 0.1; do : ; done
    read -r -p "$1" ret
}

do_autoreconf() {
    local basedir="$LOCALBUILDDIR"
    basedir+="/$(get_first_subdir)" || basedir="."
    if { [[ -f "$basedir"/recently_updated &&
        -z "$(ls "$basedir"/build_successful* 2> /dev/null)" ]]; } ||
        [[ ! -f configure ]]; then
        log "autoreconf" autoreconf -fiv
    fi
}

do_autogen() {
    local basedir="$LOCALBUILDDIR"
    basedir+="/$(get_first_subdir)" || basedir="."
    if { [[ -f "$basedir"/recently_updated &&
        -z "$(ls "$basedir"/build_successful* 2> /dev/null)" ]]; } ||
        [[ ! -f configure ]]; then
        git clean -qxfd -e "/build_successful*" -e "/recently_updated"
        log "autogen" ./autogen.sh
    fi
}

get_first_subdir() {
    local subdir="${PWD#*build/}"
    if [[ "$subdir" != "$PWD" ]]; then
        subdir="${subdir%%/*}"
        echo "$subdir"
    else
        echo "."
    fi
}

get_last_version() {
    local filelist="$1"
    local filter="$2"
    local version="$3"
    local ret
    ret="$(echo "$filelist" | /usr/bin/grep -E "$filter" | sort -V | tail -1)"
    if [[ -z "$version" ]]; then
        echo "$ret"
    else
        echo "$ret" | /usr/bin/grep -oP "$version"
    fi
}

create_debug_link() {
    local file=
    for file in "$@"; do
        if [[ -f "$file" && ! -f "$file".debug ]]; then
            echo "Stripping and creating debug link for ${file##*/}..."
            objcopy --only-keep-debug "$file" "$file".debug
            strip -s "$file"
            objcopy --add-gnu-debuglink="$file".debug "$file"
        fi
    done
}

get_vs_prefix() {
    local vsprefix
    local programfiles
    local regkey="/HKLM/software/vapoursynth"
    if [[ -n $(find "$LOCALDESTDIR"/bin-video -iname vspipe.exe) ]]; then
        # look for .dlls in bin-video
        vsprefix=$(find "$LOCALDESTDIR"/bin-video -iname vspipe.exe)
        vsprefix="${vsprefix%/*}"
        [[ -d "$vsprefix/vapoursynth${bits:0:2}" ]] &&
            echo "$vsprefix"
    elif regtool -W check "$regkey" >/dev/null 2>&1; then
        # check in registry for installed VS
        vsprefix=$(cygpath -u "$(regtool -W get "$regkey/path")")
        vsprefix="$vsprefix/core${bits:0:2}"
        [[ -d "$vsprefix" && -f "$vsprefix/vspipe.exe" ]] &&
            echo "$vsprefix"
    elif [[ -n $(which vspipe.exe 2>/dev/null) ]]; then
        # last resort, check if vspipe is in path
        vsprefix=$(which vspipe.exe)
        vsprefix="${vsprefix%/*}"
        [[ -f "$vsprefix/vapoursynth.dll" && -f "$vsprefix/vsscript.dll" ]] &&
            echo "$vsprefix"
    fi
}

get_api_version() {
    local header="$1"
    local line="$2"
    local column="$3"
    /usr/bin/grep "${line:-VERSION}" "$header" | awk '{ print $c }' c="${column:-3}" | sed 's|"||g'
}

hide_files() {
    [[ $1 = "-R" ]] && local reverse=y && shift
    for opt; do
        if [[ -z $reverse ]]; then
            [[ -f "$opt" ]] && mv -f "$opt" "$opt.bak"
        else
            [[ -f "$opt.bak" ]] && mv -f "$opt.bak" "$opt"
        fi
    done
}

unhide_files() {
    local dryrun
    hide_files -R "$@"
}

clean_suite() {
    echo -e "\n\t${orange_color}Deleting status files...${reset_color}"
    pushd "$LOCALBUILDDIR" >/dev/null
    find . -maxdepth 2 -name recently_updated -print0 | xargs -0 rm -f
    find . -maxdepth 2 -regex ".*build_successful\(32\|64\)bit\(_shared\)?\$" -print0 |
        xargs -0 rm -f
    find . -maxdepth 6 -name "ab-suite.*.log" -print0 | xargs -0 rm -f
    find . -maxdepth 5 -type d '(' -name "build-32bit" -o -name "build-64bit" ')' -print0 |
        xargs -0 rm -rf
    find . -maxdepth 2 -name "build" -type d -exec test -f "{}/CMakeCache.txt" ';' -print0 |
        xargs -0 rm -rf
    rm -rf ./x265-hg/build/msys/{8,10,12}bit

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
    popd >/dev/null
}
