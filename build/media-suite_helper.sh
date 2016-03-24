#!/bin/bash
shopt -q extglob; extglob_set=$?
((extglob_set)) && shopt -s extglob

if [[ ! $cpuCount =~ ^[0-9]+$ ]]; then
    cpuCount="$(($(nproc)/2))"
fi
bits="${bits:-64bit}"

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
        [[ ${1} =~ ^[a-zA-Z] ]] && echo "├ $*..." || echo -e "$*..."
    else
        set_title "$* in $(get_first_subdir)"
        echo -e "${bold_color}$* in $(get_first_subdir)${reset_color}"
    fi
}

set_title() {
    local title="media-autobuild_suite ($bits)"
    [[ -z $1 ]] || title="$title: $1"
    echo -ne "\e]0;$title\a"
}

cd_safe() {
    cd "$1" ||
        { create_diagnostic && zip_logs &&
            do_prompt "Failed changing to directory $1." && exit 1; }
}

test_newer() {
    [[ $1 = installed ]] && local installed=y && shift
    local file
    local files=("$@")
    local cmp="${files[-1]}"
    [[ $installed ]] && cmp="$(file_installed $cmp)"
    [[ ${#files[@]} -gt 1 ]] && unset files[-1]
    [[ -f $cmp ]] || return 0
    for file in ${files[@]}; do
        [[ $installed ]] && file="$(file_installed $file)"
        [[ -f $file ]] &&
            [[ $file -nt "$cmp" ]] && return
    done
    return 1
}

vcs_clone() {
    if [[ "$vcsType" = "svn" ]]; then
        svn checkout -q -r "$ref" "$vcsURL" "$vcsFolder"-svn
    else
        "$vcsType" clone -q "$vcsURL" "$vcsFolder-$vcsType"
    fi
}

vcs_update() {
    if [[ $vcsType = svn ]]; then
        oldHead=$(svnversion)
        svn update -r "$ref"
        newHead=$(svnversion)
    elif [[ $vcsType = hg ]]; then
        hg update -C -r "$ref"
        oldHead=$(hg id --id)
        hg pull
        hg update -C -r "$ref"
        newHead=$(hg id --id)
    elif [[ $vcsType = git ]]; then
        local unshallow
        [[ -f .git/shallow ]] && unshallow="--unshallow"
        git remote set-url origin "$vcsURL"
        git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
        [[ -f .git/refs/heads/ab-suite ]] || git branch -f --no-track ab-suite
        git checkout ab-suite
        git reset --hard "$ref"
        git fetch -t $unshallow origin
        oldHead=$(git rev-parse HEAD)
        git reset --hard "$ref"
        newHead=$(git rev-parse HEAD)
    fi
}

vcs_log() {
    if [[ "$vcsType" = "git" ]]; then
        git log --no-merges --pretty="%ci: %an - %h%n    %s" \
            "$oldHead".."$newHead" >> "$LOCALBUILDDIR"/newchangelog
    elif [[ "$vcsType" = "hg" ]]; then
        hg log --template "{date|localdate|isodatesec}: {author|person} - {node|short}\n    {desc|firstline}\n" \
            -r "reverse($oldHead:$newHead)" >> "$LOCALBUILDDIR"/newchangelog
    fi
}

# get source from VCS
# example:
#   do_vcs "url#branch|revision|tag|commit=NAME" "folder" "lib/libname.a"
do_vcs() {
    local vcsType="${1%::*}"
    local vcsURL="${1#*::}"
    [[ "$vcsType" = "$vcsURL" ]] && vcsType="git"
    local vcsBranch="${vcsURL#*#}"
    [[ "$vcsBranch" = "$vcsURL" ]] && vcsBranch=""
    local vcsFolder="$2"
    local vcsCheck=("${_check[@]}")
    local deps=("${_deps[@]}") && unset _deps
    local ref
    if [[ $vcsBranch ]]; then
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
        if [[ $vcsType = git ]]; then
            ref="origin/HEAD"
        elif [[ $vcsType = hg ]]; then
            ref="tip"
        elif [[ $vcsType = svn ]]; then
            ref="HEAD"
        fi
    fi
    [[ ! "$vcsFolder" ]] && vcsFolder="${vcsURL##*/}" && vcsFolder="${vcsFolder%.*}"

    echo
    cd_safe "$LOCALBUILDDIR"
    if [[ ! -d "$vcsFolder-$vcsType" ]]; then
        do_print_progress "  Running $vcsType clone for $vcsFolder"
        log quiet "$vcsType.clone" vcs_clone
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
    do_print_progress "  Running $vcsType update for $vcsFolder"
    log quiet "$vcsType.update" vcs_update
    if [[ "$oldHead" != "$newHead" ]]; then
        touch recently_updated
        rm -f build_successful{32,64}bit
        if [[ $build32 = "yes" && $build64 = "yes" ]] && [[ $bits = "64bit" ]]; then
            new_updates="yes"
            new_updates_packages="$new_updates_packages [$vcsFolder]"
        fi
        echo "$vcsFolder" >> "$LOCALBUILDDIR"/newchangelog
        vcs_log
        echo >> "$LOCALBUILDDIR"/newchangelog
        do_print_status "┌ ${vcsFolder} ${vcsType}" "$orange_color" "Updates found"
    elif [[ -f recently_updated && ! -f "build_successful$bits" ]]; then
        do_print_status "┌ ${vcsFolder} ${vcsType}" "$orange_color" "Recently updated"
    elif [[ -z "${vcsCheck[@]}" ]] && ! files_exist "$vcsFolder.pc"; then
        do_print_status "┌ ${vcsFolder} ${vcsType}" "$orange_color" "Missing pkg-config"
    elif [[ -n "${vcsCheck[@]}" ]] && ! files_exist "${vcsCheck[@]}"; then
        do_print_status "┌ ${vcsFolder} ${vcsType}" "$orange_color" "Files missing"
    elif [[ ${deps[@]} ]] && test_newer installed "${deps[@]}" "${vcsCheck[0]}"; then
        do_print_status "┌ ${vcsFolder} ${vcsType}" "$orange_color" "Newer dependencies"
    else
        do_print_status "${vcsFolder} ${vcsType}" "$green_color" "Up-to-date"
        return 1
    fi
    return 0
}

guess_dirname() {
    expr "$1" : '\(.\+\)\.\(tar\(\.\(gz\|bz2\|xz\)\)\?\|7z\|zip\)$'
}

check_hash() {
    local file="$1" check="$2" sum
    if [[ -f $file ]]; then
        sum=$(md5sum "$file" | awk '{ print $1 }')
        if [[ $check = print ]]; then
            echo "$sum"
        else
            test "$sum" = "$check"
        fi
    else
        return 1
    fi
}

# get wget download
do_wget() {
    local nocd norm quiet hash notmodified
    while true; do
        case $1 in
            -c) nocd=nocd && shift;;
            -r) norm=y && shift;;
            -q) quiet=y && shift;;
            -h) hash="$2" && shift 2;;
            -z) notmodified=y && shift;;
            --) shift; break;;
            *) break;;
        esac
    done
    local url="$1" archive="$2" dirName="$3" response_code curlcmds tries=1
    if [[ -z $archive ]]; then
        # remove arguments and filepath
        archive=${url%%\?*}
        archive=${archive##*/}
    fi
    [[ ! $dirName ]] && dirName=$(guess_dirname "$archive")

    [[ ! $nocd ]] && cd_safe "$LOCALBUILDDIR"
    if ! check_hash "$archive" "$hash"; then
        [[ ${url#$LOCALBUILDDIR} != "${url}" ]] &&
            url="https://raw.githubusercontent.com/jb-alvarado/media-autobuild_suite/master${url}"

        curlcmds=(/usr/bin/curl --retry 20 --retry-max-time 5 -sLkf)
        [[ $notmodified && -f $archive ]] && curlcmds+=(-z "$archive")
        [[ $hash ]] && tries=3
        while [[ $tries -gt 0 ]]; do
            response_code="$("${curlcmds[@]}" -w "%{response_code}" -o "$archive" "$url")"
            let tries-=1

            if [[ $response_code = "200" || $response_code = "226" ]]; then
                [[ $quiet ]] || do_print_status "┌ ${dirName:-$archive}" "$orange_color" "Downloaded"
                if { [[ $hash ]] && check_hash "$archive" "$hash"; } || [[ ! $hash ]]; then
                    tries=0
                else
                    rm -f "$archive"
                fi
            elif [[ $response_code = "304" ]]; then
                [[ $quiet ]] || do_print_status "┌ ${dirName:-$archive}" "$orange_color" "File up-to-date"
                if { [[ $hash ]] && check_hash "$archive" "$hash"; } || [[ ! $hash ]]; then
                    tries=0
                else
                    rm -f "$archive"
                fi
            fi
        done
        if [[ $response_code -gt 400 ]]; then
            if [[ -f $archive ]]; then
                echo -e "${orange_color}${archive}${reset_color}"
                echo -e "\tFile not found online. Using local copy."
            elif [[ -f $LOCALBUILDDIR/${url#*media-autobuild_suite/master/build/} ]]; then
                echo -e "${orange_color}${archive}${reset_color}"
                echo -e "\tFile not found online. Using local copy."
                cp -f "$LOCALBUILDDIR/${url#*media-autobuild_suite/master/build/}" .
            else
                do_print_status "└ ${dirName:-$archive}" "$red_color" "Failed"
                echo "Error $response_code while downloading $url"
                echo "<Ctrl+c> to cancel build or <Enter> to continue"
                do_prompt "if you're sure nothing depends on it."
                return 1
            fi
        fi
    else
        [[ $quiet ]] || do_print_status "├ ${dirName:-$archive}" "$green_color" "File up-to-date"
    fi
    [[ $norm ]] || add_to_remove "$(pwd)/$archive"
    [[ $nocd ]] && do_extract nocd "$archive" "$dirName" ||
        do_extract "$archive" "$dirName"
    [[ ! $norm && $dirName && ! $nocd ]] && add_to_remove
}

real_extract() {
    case $archive_type in
    zip|7z)
        7z x -aoa -o"$2" "$1"
        ;;
    tar*)
        [[ $archive_type = tar.* ]] && 7z x -aoa "$1"
        if [[ $(/usr/bin/file -b "${1%.tar*}.tar") = POSIX* ]]; then
            tar -xf "${1%.tar*}.tar" || 7z x -aoa "${1%.tar*}.tar"
        else
           7z x -aoa "${1%.tar*}.tar"
        fi
        rm -f "${1%.tar*}.tar"
        ;;
    esac
}

do_extract() {
    [[ $1 = nocd ]] && local nocd=y && shift
    local archive="$1" dirName="$2" archive_type
    # accepted: zip, 7z, tar, tar.gz, tar.bz2 and tar.xz
    [[ -z "$dirName" ]] && dirName=$(guess_dirname "$archive")
    archive_type=$(expr "$archive" : '.\+\(tar\(\.\(gz\|bz2\|xz\)\)\?\|7z\|zip\)$')

    if [[ $dirName != "." && -d "$dirName" ]] &&
        { [[ $build32 = "yes" && ! -f "$dirName"/build_successful32bit ]] ||
          [[ $build64 = "yes" && ! -f "$dirName"/build_successful64bit ]]; }; then
        rm -rf "$dirName"
    elif [[ -d "$dirName" ]]; then
        [[ $nocd ]] || cd_safe "$dirName"
        return 0
    elif [[ ! $archive_type ]]; then
        return 0
    fi
    log extract real_extract "$archive" "$dirName"
    [[ -d "$dirName/$dirName" ]] &&
        find "$dirName/$dirName" -maxdepth 1 -print0 | xargs -0 mv -t "$dirName/" &&
        rmdir "$dirName/$dirName" 2>/dev/null
    [[ $nocd ]] || cd_safe "$dirName"
}

do_wget_sf() {
    # do_wget_sf "faac/faac-src/faac-1.28/faac-$_ver.tar.bz2" "faac-$_ver"
    local hash baseurl
    [[ $1 = "-h" ]] && hash="$2" && shift 2
    local url="http://download.sourceforge.net/$1"
    shift 1
    if [[ -n $hash ]]; then
        do_wget -h "$hash" "$url" "$@"
    else
        do_wget "$url" "$@"
    fi
}

do_strip() {
    local cmd exts nostrip file
    local cmd=(strip)
    local nostrip="x265|x265-numa|ffmpeg|ffprobe|ffplay"
    local exts="exe|dll|com|a"
    [[ -f $LOCALDESTDIR/bin-video/mpv.exe.debug ]] && nostrip+="|mpv"
    [[ "$@" =~ \.($exts)$ ]] &&
        [[ ! "$@" =~ ($nostrip)\.exe$ ]] && do_print_progress Stripping
    for file; do
        file="$(file_installed $file)"
        [[ $? = 0 ]] || continue
        if [[ $file =~ \.(exe|com)$ ]] &&
            [[ ! $file =~ ($nostrip)\.exe$ ]]; then
            cmd+=(--strip-all)
        elif [[ $file =~ \.dll$ ]] ||
            [[ $file =~ x265(|-numa)\.exe$ ]]; then
            cmd+=(--strip-unneeded)
        elif ! enabled debug && [[ $file =~ \.a$ ]]; then
            cmd+=(--strip-debug)
        else
            file=""
        fi
        [[ $file ]] &&
            { eval "${cmd[@]}" "$file" 2>/dev/null ||
              eval "${cmd[@]}" "$file" -o "$file.stripped" 2>/dev/null; }
        [[ -f ${file}.stripped ]] && mv -f "${file}"{.stripped,}
    done
}

do_pack() {
    local file
    local cmd=(/usr/bin/upx -9 -qq)
    local nopack=""
    local exts="exe|dll"
    [[ $bits = 64bit ]] && enabled openssl && nopack="ffmpeg|mplayer|mpv"
    [[ "$@" =~ \.($exts)$ ]] && ! [[ $nopack && "$@" =~ ($nopack)\.exe$ ]] &&
        do_print_progress Packing with UPX
    for file; do
        file="$(file_installed $file)"
        [[ $? = 0 ]] || continue
        if [[ $file =~ \.($exts)$ ]] && ! [[ $nopack && "$@" =~ ($nopack)\.exe$ ]]; then
            [[ $stripping = y ]] && cmd+=(--strip-relocs=0)
        else
            file=""
        fi
        [[ $file ]] && eval "${cmd[@]}" "$file"
    done
}

# check if compiled file exist
do_checkIfExist() {
    local packetName
    packetName="$(get_first_subdir)"
    [[ $1 = dry ]] && local dry=y && shift
    local check=("$@")
    check+=("${_check[@]}")
    [[ -z $check ]] && echo "No files to check" && exit 1
    if [[ $dry ]]; then
        files_exist -v -s "${check[@]}"
    else
        if files_exist -v "${check[@]}"; then
            [[ $stripping = y ]] && do_strip "${check[@]}"
            [[ $packing = y ]] && do_pack "${check[@]}"
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
    unset _check
}

file_installed() {
    local file
    case $1 in
        *.pc )
            file="lib/pkgconfig/$1" ;;
        *.a|*.la|*.lib )
            file="lib/$1" ;;
        *.h|*.hpp|*.c )
            file="include/$1" ;;
        * )
            file="$1" ;;
    esac
    file="$LOCALDESTDIR/$file"
    echo "$file" && test -e "$file"
}

files_exist() {
    local verbose list soft ignorebinaries term="\n"
    while true; do
        case $1 in
            -v) verbose=y && shift;;
            -l) list=y && shift;;
            -s) soft=y && shift;;
            -b) ignorebinaries=y && shift;;
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
            if [[ $list ]]; then
                if [[ $ignorebinaries && $file =~ .(exe|com)$ ]]; then
                    continue
                fi
                echo -n "$file" && echo -ne "$term"
            fi
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

do_install() {
    [[ $1 = dry ]] && local dryrun=y && shift
    local files=("$@")
    local dest="${files[-1]}"
    [[ ${dest::1} != "/" ]] && dest="$(file_installed "$dest")"
    [[ ${#files[@]} -gt 1 ]] && unset files[-1]
    if [[ -n $dryrun ]]; then
        echo install -D "${files[@]}" "$dest"
    else
        install -D "${files[@]}" "$dest"
    fi
}

do_uninstall() {
    local dry quiet all files
    [[ $1 = dry ]] && dry=y && shift
    [[ $1 = q ]] && quiet=y && shift
    [[ $1 = all ]] && all=y && shift
    [[ $all ]] && files=($(files_exist -l "$@")) || files=($(files_exist -l -b "$@"))
    if [[ -n ${files[@]} ]]; then
        [[ ! $quiet ]] && do_print_progress Running uninstall
        if [[ $dry ]]; then
            echo "rm -rf ${files[*]}"
        else
            rm -rf "${files[@]}"
        fi
    fi
}

do_pkgConfig() {
    local pkg="${1%% *}"
    local check="${1#$pkg}"
    local pkg_and_version="$pkg"
    [[ $pkg = "$check" ]] && check=""
    local version=$2
    local deps=("${_deps[@]}") && unset _deps
    [[ ! "$version" && "$check" ]] && version="${check#*= }"
    [[ "$version" ]] && pkg_and_version="${pkg} ${version}"
    if ! pc_exists "${pkg}"; then
        do_print_status "${pkg_and_version}" "$red_color" "Not installed"
    elif ! pc_exists "${pkg}${check}"; then
        do_print_status "${pkg_and_version}" "$orange_color" "Outdated"
    elif [[ ${deps[@]} ]] && test_newer installed "${deps[@]}" "${pkg}.pc"; then
        do_print_status "${pkg_and_version}" "$orange_color" "Newer dependencies"
    else
        do_print_status "${pkg_and_version}" "$green_color" "Up-to-date"
        return 1
    fi
}

do_getFFmpegConfig() {
    local license=nonfree
    [[ $1 ]] && license="$1"
    local configfile="$LOCALBUILDDIR"/ffmpeg_options.txt
    if [[ -f "$configfile" ]] && [[ $ffmpegChoice = y ]]; then
        FFMPEG_DEFAULT_OPTS=($(sed -e 's:\\::g' -e 's/#.*//' "$configfile" | tr '\n' ' '))
        echo "Imported FFmpeg options from ffmpeg_options.txt"
    elif [[ -f "/trunk/media-autobuild_suite.bat" && $ffmpegChoice && $ffmpegChoice != y ]]; then
        FFMPEG_DEFAULT_OPTS=($(sed -rne '/ffmpeg_options=/,/[^^]$/p' /trunk/media-autobuild_suite.bat | \
            sed -e 's/.*ffmpeg_options=//' -e 's/ ^//g' | tr '\n' ' '))
        [[ $ffmpegChoice = z || $ffmpegChoice = f ]] &&
            FFMPEG_DEFAULT_OPTS+=($(sed -rne '/ffmpeg_options_zeranoe=/,/[^^]$/p' /trunk/media-autobuild_suite.bat | \
                sed -e 's/.*ffmpeg_options_zeranoe=//' -e 's/ ^//g' | tr '\n' ' '))
        [[ $ffmpegChoice = f ]] &&
            FFMPEG_DEFAULT_OPTS+=($(sed -rne '/ffmpeg_options_full=/,/[^^]$/p' /trunk/media-autobuild_suite.bat | \
                sed -e 's/.*ffmpeg_options_full=//' -e 's/ ^//g' | tr '\n' ' '))
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

    enabled_any lib{vo-aacenc,aacplus,utvideo} && do_removeOption "--enable-lib(vo-aacenc|aacplus|utvideo)" &&
        sed -ri 's;--enable-lib(vo-aacenc|aacplus|utvideo);;g' "$LOCALBUILDDIR/ffmpeg_options.txt"
}

do_changeFFmpegConfig() {
    local license=nonfree
    [[ $1 ]] && license="$1"
    do_print_progress Changing options to comply to "$license"
    # if w32threads is disabled, pthreads is used and needs this cflag
    # decklink depends on pthreads
    if disabled w32threads || enabled_any pthreads decklink; then
        do_removeOption --enable-w32threads
        do_addOption --disable-w32threads --extra-cflags=-DPTW32_STATIC_LIB \
            --extra-libs=-lpthread --extra-libs=-lwsock32
    fi

    # add options for static kvazaar
    enabled libkvazaar && do_addOption --extra-cflags=-DKVZ_STATIC_LIB

    # handle gpl libs
    local gpl=(frei0r lib{cdio,rubberband,vidstab,x264,x265,xavs,xvid} postproc)
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
        do_addOption --enable-nonfree
    else
        do_removeOptions "${nonfree[*]/#/--enable-} --enable-nonfree"
    fi

    # handle gpl-incompatible libs
    local nonfreegpl=(libfdk-aac openssl)
    if enabled_any "${nonfreegpl[@]}"; then
        if [[ $license = "nonfree" ]]; then
            do_addOption --enable-nonfree
        elif [[ $license = gpl* ]]; then
            do_removeOptions "${nonfreegpl[*]/#/--enable-}"
        fi
        # no lgpl here because they are accepted with it
    fi

    enabled frei0r && do_addOption --enable-filter=frei0r

    if enabled debug; then
        # fix issue with ffprobe not working with debug and strip
        do_addOption --disable-stripping
    else
        do_addOption --disable-debug
    fi

    enabled openssl && do_removeOption "--enable-(gcrypt|gmp)"

    # remove libs that don't work with shared
    if [[ $ffmpeg = "s" || $ffmpeg = "b" ]]; then
        FFMPEG_OPTS_SHARED=("${FFMPEG_OPTS[@]}")
        do_removeOptions "--enable-decklink --enable-libgme" y
        FFMPEG_OPTS_SHARED+=("--extra-ldflags=-static-libgcc")
    fi
}

opt_exists() {
    local array="${1}[@]" && shift 1
    local opt value
    for opt; do
        for value in "${!array}"; do
            [[ "$value" =~ $opt ]] && return
        done
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
    local opt
    for opt; do
        enabled "$opt" && return 0
    done
    return 1
}

disabled_any() {
    local opt
    for opt; do
        disabled "$opt" && return 0
    done
    return 1
}

enabled_all() {
    local opt
    for opt; do
        enabled "$opt" || return 1
    done
    return 0
}

disabled_all() {
    local opt
    for opt; do
        disabled "$opt" || return 1
    done
    return 0
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
        ! mpv_disabled vapoursynth && do_addOption MPV_OPTS --enable-vapoursynth
    elif [[ $mpv = "y" ]]; then
        mpv_enabled vapoursynth && mpv_disable vapoursynth ||
            do_addOption MPV_OPTS --disable-vapoursynth
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
    mpv_disabled "$1" && MPV_OPTS=(${MPV_OPTS[@]//--disable-$1/--enable-$1})
}

mpv_disable() {
    mpv_enabled "$1" && MPV_OPTS=(${MPV_OPTS[@]//--enable-$1/--disable-$1})
}

do_addOption() {
    local varname="$1" array
    if [[ -v $varname ]]; then
        array="$varname" && shift 1
    else
        array="FFMPEG_OPTS"
    fi
    ! opt_exists "$array" "$@" && eval "$array"+=\("$@"\)
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
    local am=$2          # "am" to apply patch with "git am"
    local strip=${3:-1}  # value of "patch" -p i.e. leading directories to strip
    do_wget -c -r -q "$LOCALBUILDDIR/patches/$patch"
    if [[ -f "$patch" ]]; then
        if [[ "$am" = "am" ]]; then
            if ! git am -q --ignore-whitespace "$patch" >/dev/null 2>&1; then
                git am -q --abort
                echo -e "${orange_color}${patch}${reset_color}"
                echo -e "\tPatch couldn't be applied with 'git am'. Continuing without patching."
            fi
        else
            if patch --dry-run --binary -s -N -p"$strip" -i "$patch" >/dev/null 2>&1; then
                patch --binary -s -N -p"$strip" -i "$patch"
            else
                echo -e "${orange_color}${patch}${reset_color}"
                echo -e "\tPatch couldn't be applied with 'patch'. Continuing without patching."
            fi
        fi
    else
        echo -e "${orange_color}${patch}${reset_color}"
        echo -e "\tPatch not found anywhere. Continuing without patching."
    fi
}

do_cmakeinstall() {
    local root=".."
    create_build_dir
    [[ $1 && -d "../$1" ]] && root="../$1" && shift
    log "cmake" cmake "$root" -G Ninja -DBUILD_SHARED_LIBS=off -DCMAKE_INSTALL_PREFIX="$LOCALDESTDIR" -DUNIX=on "$@"
    log "install" ninja install
}

compilation_fail() {
    local reason="$1"
    local operation
    operation="$(echo "$reason" | tr '[:upper:]' '[:lower:]')"
    if [[ $loggging = y ]]; then
        echo "Likely error:"
        tail "ab-suite.${operation}.log"
        echo "${red_color}$reason failed. Check $(pwd)/ab-suite.$operation.log${reset_color}"
    fi
    if [[ $_notrequired ]]; then
        echo "This isn't required for anything so we can move on."
        return 1
    else
        echo "${red_color}This is required for other packages, so this script will exit.${reset_color}"
        create_diagnostic
        zip_logs
        do_prompt "Try running the build again at a later time."
        exit 1
    fi
}

strip_ansi() {
    local txtfile newfile
    for txtfile; do
        [[ $txtfile != ${txtfile//stripped/} ]] && continue
        local name="${txtfile%.*}"
        local ext="${txtfile#*.}"
        [[ $txtfile != $name ]] && newfile="${name}.stripped.${ext}" || newfile="${txtfile}-stripped"
        sed -r 's#(\x1B[\[\(]([0-9][0-9]?)?[mBHJ]|\x07|\x1B]0;)##g' "$txtfile" > "${newfile}"
    done
}

zip_logs() {
    local failed url
    failed="$(get_first_subdir)"
    pushd "$LOCALBUILDDIR" >/dev/null
    rm -f logs.zip
    strip_ansi ./*.log
    7za -mx=9 a logs.zip ./*.stripped.log ./*.ini ./*_options.txt ./last_run ./media-suite_*.sh \
        ./diagnostics.txt /trunk/media-autobuild_suite.bat -ir!"$failed/*.log" >/dev/null
    [[ $build32 || $build64 ]] && url="$(/usr/bin/curl -sF'file=@logs.zip' https://0x0.st)"
    popd >/dev/null
    echo
    if [[ $url ]]; then
        echo "${green_color}All relevant logs have been anonymously uploaded to $url"
        echo "${green_color}Copy and paste ${red_color}[logs.zip]($url)${green_color} in the GitHub issue.${reset_color}"
    elif [[ -f "$LOCALBUILDDIR/logs.zip" ]]; then
        echo "${green_color}Attach $(cygpath -w "$LOCALBUILDDIR/logs.zip") to the GitHub issue.${reset_color}"
    fi
}

log() {
    [[ $1 = quiet ]] && local quiet=y && shift
    local name="${1// /.}"
    local cmd="$2"
    shift 2
    local extra
    [[ $quiet ]] || do_print_progress Running "$name"
    [[ $cmd =~ ^(make|ninja)$ ]] && extra="-j$cpuCount"
    if [[ $logging != "n" ]]; then
        echo "$cmd $@" > "ab-suite.$name.log"
        $cmd $extra "$@" >> "ab-suite.$name.log" 2>&1 ||
            { [[ $extra ]] && $cmd -j1 "$@" >> "ab-suite.$name.log" 2>&1; } ||
            compilation_fail "$name"
    else
        $cmd $extra "$@" || { [[ $extra ]] && $cmd -j1 "$@"; } ||
            compilation_fail "$name"
    fi
}

create_build_dir() {
    local extra
    [[ $1 ]] && extra="-$1"
    [[ -d build${extra}-$bits ]] && rm -rf "build${extra}-$bits"
    mkdir "build${extra}-$bits" && cd_safe "build${extra}-$bits"
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
    log "make" make "$@"
}

do_makeinstall() {
    log "install" make install "$@"
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
    [[ x"$1" = "xdry" ]] || local dryrun="n"
    local files
    files="$(find /mingw{32,64}/lib /mingw{32/i686,64/x86_64}-w64-mingw32/lib -name "*.dll.a" 2>/dev/null)"
    local tomove=()
    for file in $files; do
        [[ -f "${file%*.dll.a}.a" ]] && tomove+=("$file")
    done
    [[ $dryrun = "n" ]] &&
        printf "%s\n" "${tomove[@]}" | xargs -i mv -f '{}' '{}.dyn' || printf "%s\n" "${tomove[@]}"
}

do_unhide_all_sharedlibs() {
    [[ x"$1" = "xdry" ]] || local dryrun="n"
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
    if [[ $dryrun = "n" ]]; then
        printf "%s\n" "${todelete[@]}" | xargs -i rm -f '{}'
        printf "%s\n" "${tomove[@]}" | xargs -i mv -f '{}.dyn' '{}'
    else
        printf "rm %s\n" "${todelete[@]}"
        printf "%s\n" "${tomove[@]}"
    fi
}

do_pacman_install() {
    local installed
    local pkg
    local noop
    installed="$(pacman -Qqe | /usr/bin/grep "^${MINGW_PACKAGE_PREFIX}-")"
    for pkg; do
        [[ "$pkg" != "${MINGW_PACKAGE_PREFIX}-"* ]] && pkg="${MINGW_PACKAGE_PREFIX}-${pkg}"
        if /usr/bin/grep -q "^${pkg}$" <(echo "$installed"); then
            [[ -z $noop ]] && noop=y
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
    local installed
    local pkg
    installed="$(pacman -Qqe | /usr/bin/grep "^${MINGW_PACKAGE_PREFIX}-")"
    for pkg; do
        [[ "$pkg" != "${MINGW_PACKAGE_PREFIX}-"* ]] && pkg="${MINGW_PACKAGE_PREFIX}-${pkg}"
        [[ -f /etc/pac-mingw-extra.pk ]] &&
            sed -i "/^${pkg#$MINGW_PACKAGE_PREFIX-}$/d" /etc/pac-mingw-extra.pk >/dev/null 2>&1
        /usr/bin/grep -q "^${pkg}$" <(echo "$installed") || continue
        echo -n "Uninstalling ${pkg#$MINGW_PACKAGE_PREFIX-}... "
        do_hide_pacman_sharedlibs "$pkg" revert
        if pacman -Rs --noconfirm "$pkg" >/dev/null 2>&1; then
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
    for file; do
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
    local regkey="/HKLM/software/vapoursynth"
    if [[ -n $(find "$LOCALDESTDIR"/bin-video -iname vspipe.exe) ]]; then
        # look for .dlls in bin-video
        vsprefix=$(find "$LOCALDESTDIR"/bin-video -iname vspipe.exe)
        vsprefix="${vsprefix%/*}"
        [[ -d "$vsprefix/vapoursynth${bits:0:2}" ]] &&
            echo "$vsprefix"
    elif [[ $bits = 64bit ]] && regtool -q check "$regkey"; then
        # check in native HKLM for installed VS (R31+)
        vsprefix="$(regtool -q get "$regkey/path")"
        [[ -n "$vsprefix" ]] && vsprefix="$(cygpath -u "$vsprefix/core64")" || vsprefix=""
        [[ -n "$vsprefix" && -f "$vsprefix/vspipe.exe" ]] &&
            echo "$vsprefix"
    elif regtool -qW check "$regkey"; then
        # check in registry for installed VS
        vsprefix="$(regtool -W get "$regkey/path")"
        [[ -n "$vsprefix" ]] && vsprefix=$(cygpath -u "$vsprefix/core${bits:0:2}") || vsprefix=""
        [[ -n "$vsprefix" && -f "$vsprefix/vspipe.exe" ]] &&
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

add_to_remove() {
    [[ $1 ]] && echo "$1" >> "$LOCALBUILDDIR/_to_remove" ||
        echo "$(pwd)" >> "$LOCALBUILDDIR/_to_remove"
}

clean_suite() {
    echo -e "\n\t${orange_color}Deleting status files...${reset_color}"
    cd_safe "$LOCALBUILDDIR" >/dev/null
    find . -maxdepth 2 -name recently_updated -print0 | xargs -0 rm -f
    find . -maxdepth 2 -regex ".*build_successful\(32\|64\)bit\(_shared\)?\$" -print0 |
        xargs -0 rm -f

    if [[ $deleteSource = y ]]; then
        echo -e "\t${orange_color}Deleting temporary build dirs...${reset_color}"
        find . -maxdepth 5 -name "ab-suite.*.log" -print0 | xargs -0 rm -f
        find . -maxdepth 5 -type d -name "build-*bit" -print0 | xargs -0 rm -rf
        find . -maxdepth 2 -type d -name "build" -exec test -f "{}/CMakeCache.txt" ';' -print0 |
            xargs -0 rm -rf

        if [[ -f _to_remove ]]; then
            echo -e "\n\t${orange_color}Deleting source folders...${reset_color}"
            grep -E "^($LOCALBUILDDIR|/trunk$LOCALBUILDDIR)" < _to_remove |
                grep -Ev "^$LOCALBUILDDIR/(patches|extras|$)" | sort -u | xargs -r rm -rf
        fi
    fi

    rm -f {firstrun,firstUpdate,secondUpdate,pacman,mingw32,mingw64}.log diagnostics.txt \
        logs.zip _to_remove

    [[ -f last_run ]] && mv last_run last_successful_run && touch last_successful_run
    [[ -f CHANGELOG.txt ]] && cat CHANGELOG.txt >> newchangelog
    unix2dos -n newchangelog CHANGELOG.txt 2> /dev/null && rm -f newchangelog
}

create_diagnostic() {
    local cmd cmds=("uname -a" "pacman -Qe" "pacman -Qd")
    do_print_progress "  Creating diagnostics file"
    [[ -d /trunk/.git ]] && cmds+=("git -C /trunk log -1 --pretty=%h")
    rm -f "$LOCALBUILDDIR/diagnostics.txt"
    for cmd in "${cmds[@]}"; do
        printf '\t%s\n%s\n\n' "$cmd" "$($cmd)" >>"$LOCALBUILDDIR/diagnostics.txt"
    done
}

((extglob_set)) && shopt -u extglob
