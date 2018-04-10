#!/bin/bash

if [[ ! $cpuCount =~ ^[0-9]+$ ]]; then
    cpuCount="$(($(nproc)/2))"
fi
bits="${bits:-64bit}"
curl_opts=(/usr/bin/curl --connect-timeout 15 --retry 3
    --retry-delay 5 --silent --location --insecure --fail)

if which tput >/dev/null 2>&1; then
    ncolors=$(tput colors)
    if test -n "$ncolors" && test "$ncolors" -ge 8; then
        bold=$(tput bold)
        blue=$(tput setaf 12)
        orange=$(tput setaf 11)
        green=$(tput setaf 2)
        red=$(tput setaf 1)
        reset=$(tput sgr0)
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
    printf '%s%*.*s [%s]\n' "${bold}$name${reset}" 0 \
        "$padlen" "$pad" "${color}${status}${reset}"
}

do_print_progress() {
    if [[ $logging = y ]]; then
        [[ ${1} =~ ^[a-zA-Z] ]] && echo "├ $*..." || echo -e "$*..."
    else
        set_title "$* in $(get_first_subdir)"
        echo -e "${bold}$* in $(get_first_subdir)${reset}"
    fi
}

set_title() {
    local title="media-autobuild_suite ($bits)"
    [[ -z $1 ]] || title="$title: $1"
    echo -ne "\e]0;$title\a"
}

do_exit_prompt() {
    if [[ -n $build32 || -n $build64 ]]; then
        create_diagnostic
        zip_logs
    fi
    do_prompt "$*"
    [[ -n $build32 || -n $build64 ]] && exit 1
}

cd_safe() {
    cd "$1" || do_exit_prompt "Failed changing to directory $1."
}

test_newer() {
    [[ $1 = installed ]] && local installed=y && shift
    local file
    local files=("$@")
    local cmp="${files[-1]}"
    [[ $installed ]] && cmp="$(file_installed "$cmp")"
    [[ ${#files[@]} -gt 1 ]] && unset 'files[-1]'
    [[ -f $cmp ]] || return 0
    for file in "${files[@]}"; do
        [[ $installed ]] && file="$(file_installed "$file")"
        [[ -f $file ]] &&
            [[ $file -nt "$cmp" ]] && return
    done
    return 1
}

check_valid_vcs() {
    local root="${1:-.}"
    local _type="${vcsType:-git}"
    [[ "$_type" = "git" && -d "$root"/.git ]] ||
    [[ "$_type" = "hg" && -d "$root"/.hg ]] ||
    [[ "$_type" = "svn" && -d "$root"/.svn ]]
}

vcs_clone() {
    set -x
    if [[ "$vcsType" = "svn" ]]; then
        svn checkout -r "$ref" "$vcsURL" "$vcsFolder"-svn
    else
        "$vcsType" clone "$vcsURL" "$vcsFolder-$vcsType"
    fi
    set +x
    check_valid_vcs "$vcsFolder-$vcsType"
}

vcs_reset() {
    local ref="$1"
    check_valid_vcs
    set -x
    if [[ $vcsType = svn ]]; then
        svn revert --recursive .
        oldHead=$(svnversion)
    elif [[ $vcsType = hg ]]; then
        hg update -C -r "$ref"
        oldHead=$(hg id --id)
    elif [[ $vcsType = git ]]; then
        git remote set-url origin "$vcsURL"
        git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
        [[ -f .git/refs/heads/ab-suite ]] || git branch -f --no-track ab-suite
        git checkout ab-suite
        git reset --hard "$(vcs_getlatesttag "$ref")"
        oldHead=$(git rev-parse HEAD)
    fi
    set +x
}

vcs_update() {
    local ref="$1"
    check_valid_vcs
    set -x
    if [[ $vcsType = svn ]]; then
        svn update -r "$ref"
        newHead=$(svnversion)
    elif [[ $vcsType = hg ]]; then
        hg pull
        hg update -C -r "$ref"
        newHead=$(hg id --id)
    elif [[ $vcsType = git ]]; then
        local unshallow
        [[ -f .git/shallow ]] && unshallow="--unshallow"
        git fetch -t $unshallow origin
        ref="$(vcs_getlatesttag "$ref")"
        git reset --hard "$ref"
        newHead=$(git rev-parse HEAD)
    fi
    set +x
}

vcs_log() {
    check_valid_vcs
    if [[ "$vcsType" = "git" ]]; then
        git log --no-merges --pretty="%ci: %an - %h%n    %s" \
            "$oldHead".."$newHead" >> "$LOCALBUILDDIR"/newchangelog
    elif [[ "$vcsType" = "hg" ]]; then
        hg log --template "{date|localdate|isodatesec}: {author|person} - {node|short}\n    {desc|firstline}\n" \
            -r "reverse($oldHead:$newHead)" >> "$LOCALBUILDDIR"/newchangelog
    fi
}

vcs_getlatesttag() {
    local ref="$1"
    if [[ -n "$vcsType" && "$vcsType" != git ]]; then
        echo "$ref"
        return
    fi
    local tag
    if [[ "$ref" = "LATEST" ]]; then
        tag="$(git describe --abbrev=0 --tags $(git rev-list --tags --max-count=1))"
    elif [[ "$ref" = "GREATEST" ]]; then
        tag="$(git describe --abbrev=0 --tags)"
    elif [[ "${ref//\*}" != "$ref" ]]; then
        tag="$(git describe --abbrev=0 --tags $(git tag -l "$ref" | sort -Vr | head -1))"
    fi
    echo "${tag:-${ref}}"
}

# get source from VCS
# example:
#   do_vcs "url#branch|revision|tag|commit=NAME" "folder"
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

    cd_safe "$LOCALBUILDDIR"
    if [[ ! -d "$vcsFolder-$vcsType" ]]; then
        do_print_progress "  Running $vcsType clone for $vcsFolder"
        log quiet "$vcsType.clone" vcs_clone || do_exit_prompt "Failed cloning to $vcsFolder-$vcsType"
        if [[ -d "$vcsFolder-$vcsType" ]]; then
            cd_safe "$vcsFolder-$vcsType"
            touch recently_updated recently_checked
        else
            echo "$vcsFolder $vcsType seems to be down"
            echo "Try again later or <Enter> to continue"
            do_prompt "if you're sure nothing depends on it."
            return
        fi
    else
        cd_safe "$vcsFolder-$vcsType"
    fi

    if [[ $ffmpegUpdate = onlyFFmpeg ]] &&
        [[ $vcsFolder != ffmpeg ]] && [[ $vcsFolder != mpv ]] &&
        { { [[ -z "${vcsCheck[*]}" ]] && files_exist "$vcsFolder.pc"; } ||
          { [[ -n "${vcsCheck[*]}" ]] && files_exist "${vcsCheck[@]}"; }; }; then
        do_print_status "${vcsFolder} ${vcsType}" "$green" "Already built"
        return 1
    fi

    log quiet "$vcsType.reset" vcs_reset "$ref" || do_exit_prompt "Failed resetting in $vcsFolder-$vcsType"
    if ! [[ -f recently_checked && recently_checked -nt "$LOCALBUILDDIR"/last_run ]]; then
        do_print_progress "  Running $vcsType update for $vcsFolder"
        log quiet "$vcsType.update" vcs_update "$ref" || do_exit_prompt "Failed updating in $vcsFolder-$vcsType"
        touch recently_checked
    else
        newHead="$oldHead"
    fi
    if [[ "$oldHead" != "$newHead" ]]; then
        touch recently_updated
        rm -f build_successful{32,64}bit{,_shared}
        if [[ $build32 = "yes" && $build64 = "yes" ]] && [[ $bits = "64bit" ]]; then
            new_updates="yes"
            new_updates_packages="$new_updates_packages [$vcsFolder]"
        fi
        echo "$vcsFolder" >> "$LOCALBUILDDIR"/newchangelog
        vcs_log
        echo >> "$LOCALBUILDDIR"/newchangelog
        do_print_status "┌ ${vcsFolder} ${vcsType}" "$orange" "Updates found"
    elif [[ -f recently_updated && ! -f "build_successful$bits" ]]; then
        do_print_status "┌ ${vcsFolder} ${vcsType}" "$orange" "Recently updated"
    elif [[ -z "${vcsCheck[*]}" ]] && ! files_exist "$vcsFolder.pc"; then
        do_print_status "┌ ${vcsFolder} ${vcsType}" "$orange" "Missing pkg-config"
    elif [[ -n "${vcsCheck[*]}" ]] && ! files_exist "${vcsCheck[@]}"; then
        do_print_status "┌ ${vcsFolder} ${vcsType}" "$orange" "Files missing"
    elif [[ -n "${deps[*]}" ]] && test_newer installed "${deps[@]}" "${vcsCheck[0]}"; then
        do_print_status "┌ ${vcsFolder} ${vcsType}" "$orange" "Newer dependencies"
    else
        do_print_status "${vcsFolder} ${vcsType}" "$green" "Up-to-date"
        return 1
    fi
    return 0
}

guess_dirname() {
    expr "$1" : '\(.\+\)\.\(tar\(\.\(gz\|bz2\|xz\)\)\?\|7z\|zip\)$'
}

check_hash() {
    local file="$1" check="$2" md5sum sha256sum
    if [[ -f $file ]]; then
        md5sum=$(md5sum "$file" | awk '{ print $1 }')
        sha256sum=$(sha256sum "$file" | awk '{ print $1 }')
        if [[ $check = print ]]; then
            echo "$sha256sum"
        else
            test "$sha256sum" = "$check" || test "$md5sum" = "$check"
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
        [[ ${url#/patches} != "$url" || ${url#/extras} != "$url" ]] &&
            url="https://jb-alvarado.github.io/media-autobuild_suite${url}"

        curlcmds=("${curl_opts[@]}")
        [[ $notmodified && -f $archive ]] && curlcmds+=(-z "$archive" -R)
        [[ $hash ]] && tries=3
        while [[ $tries -gt 0 ]]; do
            response_code="$("${curlcmds[@]}" -w "%{response_code}" -o "$archive" "$url")"
            let tries-=1

            if [[ $response_code = "200" || $response_code = "226" ]]; then
                [[ $quiet ]] || do_print_status "┌ ${dirName:-$archive}" "$orange" "Downloaded"
                if { [[ $hash ]] && check_hash "$archive" "$hash"; } || [[ ! $hash ]]; then
                    tries=0
                else
                    rm -f "$archive"
                fi
            elif [[ $response_code = "304" ]]; then
                [[ $quiet ]] || do_print_status "┌ ${dirName:-$archive}" "$orange" "File up-to-date"
                if { [[ $hash ]] && check_hash "$archive" "$hash"; } || [[ ! $hash ]]; then
                    tries=0
                else
                    rm -f "$archive"
                fi
            fi
        done
        if [[ $response_code -gt 400 || $response_code = "000" ]]; then
            if [[ -f $archive ]]; then
                echo -e "${orange}${archive}${reset}"
                echo -e "\tFile not found online. Using local copy."
            else
                do_print_status "└ ${dirName:-$archive}" "$red" "Failed"
                echo "Error $response_code while downloading $url"
                echo "<Ctrl+c> to cancel build or <Enter> to continue"
                do_prompt "if you're sure nothing depends on it."
                return 1
            fi
        fi
    else
        [[ $quiet ]] || do_print_status "├ ${dirName:-$archive}" "$green" "File up-to-date"
    fi
    [[ $norm ]] || add_to_remove "$(pwd)/$archive"
    do_extract "$archive" "$dirName"
    [[ ! $norm && $dirName && ! $nocd ]] && add_to_remove
    [[ -z $response_code || $response_code != "304" ]] && return 0
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
    local nocd="${nocd:-}"
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
    local hash
    [[ $1 = "-h" ]] && hash="$2" && shift 2
    local url="https://download.sourceforge.net/$1"
    shift 1
    if [[ -n $hash ]]; then
        do_wget -h "$hash" "$url" "$@"
    else
        do_wget "$url" "$@"
    fi
}

do_strip() {
    local cmd exts nostrip file val
    local cmd=(strip)
    local nostrip="x265|x265-numa|ffmpeg|ffprobe|ffplay"
    local exts="exe|dll|com|a"
    [[ -f $LOCALDESTDIR/bin-video/mpv.exe.debug ]] && nostrip+="|mpv"
    for file; do
        if [[ "$file" =~ \.($exts)$ && ! "$file" =~ ($nostrip)\.exe$ ]]; then
            do_print_progress Stripping
            break
        fi
    done
    for file; do
        local orig_file="$file"
        if ! file="$(file_installed $orig_file)"; then
            continue
        fi
        if [[ $file =~ \.(exe|com)$ ]] &&
            [[ ! $file =~ ($nostrip)\.exe$ ]]; then
            cmd+=(--strip-all)
        elif [[ $file =~ \.dll$ ]] ||
            [[ $file =~ x265(|-numa)\.exe$ ]]; then
            cmd+=(--strip-unneeded)
        elif ! disabled debug && [[ $file =~ \.a$ ]]; then
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
    local cmd=(/opt/bin/upx -9 -qq)
    local nopack=""
    local exts="exe|dll"
    [[ $bits = 64bit ]] && enabled_any libtls openssl && nopack="ffmpeg|mplayer|mpv"
    for file; do
        if [[ "$file" =~ \.($exts)$ && ! "$file" =~ ($nopack)\.exe$ ]]; then
            do_print_progress Packing with UPX
            break
        fi
    done
    for file; do
        local orig_file="$file"
        if ! file="$(file_installed $orig_file)"; then
            continue
        fi
        if [[ $file =~ \.($exts)$ ]] &&
            ! [[ -n "$nopack" && $file =~ ($nopack)\.exe$ ]]; then
            [[ $stripping = y ]] && cmd+=(--strip-relocs=0)
        else
            file=""
        fi
        [[ $file ]] && eval "${cmd[@]}" "$file"
    done
}

do_zipman() {
    local file
    local man_dirs=(/local{32,64}/share/man)
    local files=$(find ${man_dirs[@]} -type f \! -name "*.gz" \! -name "*.db" \! -name "*.bz2" 2>/dev/null)
    for file in $files; do
        gzip -9 -n -f "$file"
        rm -f "$file"
    done
}

# check if compiled file exist
do_checkIfExist() {
    local packetName
    packetName="$(get_first_subdir)"
    local dry="${dry:-n}"
    local check=("${_check[@]}")
    [[ -z ${check[*]} ]] && echo "No files to check" && exit 1
    if [[ $dry = y ]]; then
        files_exist -v -s "${check[@]}"
    else
        if files_exist -v "${check[@]}"; then
            [[ $stripping = y ]] && do_strip "${check[@]}"
            [[ $packing = y ]] && do_pack "${check[@]}"
            do_print_status "└ $packetName" "$blue" "Updated"
            [[ $build32 = yes || $build64 = yes ]] && [[ -d "$LOCALBUILDDIR/$packetName" ]] &&
                touch "$LOCALBUILDDIR/$packetName/build_successful$bits"
        else
            [[ $build32 = yes || $build64 = yes ]] && [[ -d "$LOCALBUILDDIR/$packetName" ]] &&
                rm -f "$LOCALBUILDDIR/$packetName/build_successful$bits"
            do_print_status "└ $packetName" "$red" "Failed"
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
    local silent
    [[ "$1" = "-s" ]] && silent=y
    case $1 in
        /*|./* )
            file="$1" ;;
        *.pc )
            file="lib/pkgconfig/$1" ;;
        *.a|*.la|*.lib )
            file="lib/$1" ;;
        *.h|*.hpp|*.c )
            file="include/$1" ;;
        * )
            file="$1" ;;
    esac
    [[ ${file::1} != "/" ]] && file="$LOCALDESTDIR/$file"
    [[ -z $silent ]] && echo "$file"
    test -e "$file"
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
            [[ $verbose && $soft ]] && do_print_status "├ $file" "${green}" "Found"
            if [[ $list ]]; then
                if [[ $ignorebinaries && $file =~ .(exe|com)$ ]]; then
                    continue
                fi
                echo -n "$file" && echo -ne "$term"
            fi
        else
            [[ $verbose ]] && do_print_status "├ $file" "${red}" "Not found"
            [[ ! $soft ]] && return 1
        fi
    done
    return 0
}

pc_exists() {
    for opt; do
        local _pkg=${opt%% *}
        local _check=${opt#$_pkg}
        [[ $_pkg = "$_check" ]] && _check=""
        [[ $_pkg = *.pc ]] || _pkg="${LOCALDESTDIR}/lib/pkgconfig/${_pkg}.pc"
        pkg-config --exists --silence-errors "${_pkg}${_check}" || return
    done
}

do_install() {
    [[ $1 = dry ]] && local dryrun=y && shift
    local files=("$@")
    local dest="${files[-1]}"
    [[ ${dest::1} != "/" ]] && dest="$(file_installed "$dest")"
    [[ ${#files[@]} -gt 1 ]] && unset 'files[-1]'
    [[ ${dest: -1:1} = "/" ]] && mkdir -p "$dest"
    if [[ -n $dryrun ]]; then
        echo install -D -p "${files[@]}" "$dest"
    else
        install -D -p "${files[@]}" "$dest"
    fi
}

do_uninstall() {
    local dry quiet all files
    [[ $1 = dry ]] && dry=y && shift
    [[ $1 = q ]] && quiet=y && shift
    [[ $1 = all ]] && all=y && shift
    [[ $all ]] && files=($(files_exist -l "$@")) || files=($(files_exist -l -b "$@"))
    if [[ -n "${files[*]}" ]]; then
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
    local pc_check="${1#$pkg}"
    local pkg_and_version="$pkg"
    [[ $pkg = "$pc_check" ]] && pc_check=""
    local version=$2
    local deps=("${_deps[@]}") && unset _deps
    [[ ! "$version" && "$pc_check" ]] && version="${pc_check#*= }"
    [[ "$version" ]] && pkg_and_version="${pkg} ${version}"
    if ! pc_exists "${pkg}"; then
        do_print_status "${pkg_and_version}" "$red" "Not installed"
    elif ! pc_exists "${pkg}${pc_check}"; then
        do_print_status "${pkg_and_version}" "$orange" "Outdated"
    elif [[ -n "${deps[*]}" ]] && test_newer installed "${deps[@]}" "${pkg}.pc"; then
        do_print_status "${pkg_and_version}" "$orange" "Newer dependencies"
    elif [[ -n "${_check[*]}" ]] && ! files_exist "${_check[@]}"; then
        do_print_status "${pkg_and_version}" "$orange" "Files missing"
    else
        do_print_status "${pkg_and_version}" "$green" "Up-to-date"
        return 1
    fi
}

do_readoptionsfile() {
    local filename="$1"
    if [[ -f "$filename" ]]; then
        < $filename dos2unix |
            sed -r '# remove commented text
                    s/#.*//
                    # delete empty lines
                    /^\s*$/d
                    # remove leading/trailing whitespace
                    s/(^\s+|\s+$)//
                    '
        echo "Imported options from ${filename##*/}" >&2
    fi
}

do_readbatoptions() {
    local varname="$1"
    printf '%s\n' "${bat[@]}" | \
        sed -rne "/set ${varname}=/,/[^^]$/p" | \
        sed -re '/^:/d' -e "s/(set ${varname}=| \^|\")//g" | tr ' ' '\n' | \
        sed -re '/^#/d' -e '/^[^-]/{s/^/--enable-/g}'
}

do_getFFmpegConfig() {
    local license="${1:-nonfree}"

    FFMPEG_DEFAULT_OPTS=()
    if [[ -f "/trunk/media-autobuild_suite.bat" && $ffmpegChoice =~ (n|z|f) ]]; then
        IFS=$'\n' read -d '' -r -a bat < <(< /trunk/media-autobuild_suite.bat dos2unix)
        FFMPEG_DEFAULT_OPTS=($(do_readbatoptions "ffmpeg_options_(builtin|basic)"))
        [[ $ffmpegChoice != n ]] &&
            FFMPEG_DEFAULT_OPTS+=($(do_readbatoptions "ffmpeg_options_zeranoe"))
        [[ $ffmpegChoice = f ]] &&
            FFMPEG_DEFAULT_OPTS+=($(do_readbatoptions "ffmpeg_options_full"))
        echo "Imported default FFmpeg options from .bat"
    else
        IFS=$'\n' read -d '' -r -a FFMPEG_DEFAULT_OPTS < \
            <(do_readoptionsfile "$LOCALBUILDDIR/ffmpeg_options.txt")
    fi
    echo "License: $license"
    FFMPEG_OPTS=("${FFMPEG_BASE_OPTS[@]}" "${FFMPEG_DEFAULT_OPTS[@]}")

    # we set these accordingly for static or shared
    do_removeOption "--(en|dis)able-(shared|static)"

    # OK to use GnuTLS for rtmpdump if not nonfree since GnuTLS was built for rtmpdump anyway
    # If nonfree will use SChannel if neither openssl/libtls or gnutls are in the options
    if ! enabled_any libtls openssl gnutls &&
        { enabled librtmp || [[ $rtmpdump = y ]]; }; then
        if [[ $license = nonfree ]] ||
            [[ $license = lgpl* && $rtmpdump = n ]]; then
            do_addOption --enable-openssl
        else
            do_addOption --enable-gnutls
        fi
        do_removeOption "--enable-(gmp|gcrypt)"
    fi

    if enabled_any libtls openssl && [[ $license != gpl* ]]; then
        # prefer openssl/libtls if both are in options and not gpl

        # prefer openssl over libtls if both enabled
        local _remove=openssl
        if enabled openssl; then
            _remove=libtls
        fi

        do_removeOption "--enable-(gnutls|schannel|$_remove)"

    elif enabled gnutls; then
        # prefer gnutls if both are in options and gpl
        do_removeOption "--enable-(openssl|libtls|schannel)"
        do_addOption --enable-gnutls
    else
        do_removeOption "--enable-(openssl|libtls)"
    fi

    enabled_any lib{vo-aacenc,aacplus,utvideo,dcadec,faac,ebur128} netcdf &&
        do_removeOption "--enable-(lib(vo-aacenc|aacplus|utvideo|dcadec|faac|ebur128)|netcdf)" &&
        sed -ri 's;--enable-(lib(vo-aacenc|aacplus|utvideo|dcadec|faac|ebur128)|netcdf);;g' \
        "$LOCALBUILDDIR/ffmpeg_options.txt"
}

do_changeFFmpegConfig() {
    local license="${1:-nonfree}"
    do_print_progress Changing options to comply to "$license"
    # if w32threads is disabled, pthreads is used and needs this cflag
    # decklink includes zvbi, which requires pthreads
    if disabled w32threads || enabled pthreads || enabled_all decklink libzvbi || enabled libvmaf; then
        do_removeOption --enable-w32threads
        do_addOption --disable-w32threads
    fi

    # add options for static kvazaar
    enabled libkvazaar && do_addOption --extra-cflags=-DKVZ_STATIC_LIB

    # get libs restricted by license
    local config_script=configure
    [[ $(get_first_subdir) != "ffmpeg-git" ]] && config_script="$LOCALBUILDDIR/ffmpeg-git/configure"
    [[ -f "$config_script" ]] || do_exit_prompt "There's no configure script to retrieve libs from"
    eval "$(sed -n '/EXTERNAL_LIBRARY_GPL_LIST=/,/^"/p' "$config_script")"
    eval "$(sed -n '/HWACCEL_LIBRARY_NONFREE_LIST=/,/^"/p' "$config_script")"
    eval "$(sed -n '/EXTERNAL_LIBRARY_NONFREE_LIST=/,/^"/p' "$config_script")"
    eval "$(sed -n '/EXTERNAL_LIBRARY_VERSION3_LIST=/,/^"/p' "$config_script")"

    # handle gpl libs
    local gpl=(${EXTERNAL_LIBRARY_GPL_LIST//_/-} gpl)
    if [[ $license = gpl* || $license = nonfree ]] &&
        { enabled_any "${gpl[@]}" || ! disabled postproc; }; then
        do_addOption --enable-gpl
    else
        do_removeOptions "${gpl[*]/#/--enable-} --enable-postproc --enable-gpl"
    fi

    # handle (l)gplv3 libs
    local version3=(${EXTERNAL_LIBRARY_VERSION3_LIST//_/-})
    if [[ $license =~ (l|)gplv3 || $license = nonfree ]] && enabled_any "${version3[@]}"; then
        do_addOption --enable-version3
    else
        do_removeOptions "${version3[*]/#/--enable-} --enable-version3"
    fi

    local nonfreehwaccel=(${HWACCEL_LIBRARY_NONFREE_LIST//_/-})
    if [[ $license = "nonfree" ]] && enabled_any "${nonfreehwaccel[@]}"; then
        do_addOption --enable-nonfree
    else
        do_removeOptions "${nonfreehwaccel[*]/#/--enable-} --enable-nonfree"
    fi

    # cuda-only workarounds
    if [[ $license = "nonfree" && $bits = 64bit ]] && enabled_any libnpp cuda-sdk &&
        [[ -n "$CUDA_PATH" && -f "$CUDA_PATH/include/cuda.h" ]] &&
        [[ -f "$CUDA_PATH/lib/x64/cuda.lib" ]] && get_cl_path; then
            if enabled libnpp && [[ ! -f "$CUDA_PATH/lib/x64/nppc.lib" ]]; then
                do_removeOption "--enable-libnpp"
            elif enabled libnpp; then
                echo -e "${orange}FFmpeg and related apps will depend on CUDA SDK!${reset}"
            fi
            local fixed_CUDA_PATH="$(cygpath -sm "$CUDA_PATH")"
            do_addOption "--extra-cflags=-I$fixed_CUDA_PATH/include"
            do_addOption "--extra-ldflags=-L$fixed_CUDA_PATH/lib/x64"
            echo -e "${orange}FFmpeg and related apps will depend on Nvidia drivers!${reset}"
    else
        do_removeOption "--enable-(libnpp|cuda-sdk)"
    fi

    # handle gpl-incompatible libs
    local nonfreegpl=(${EXTERNAL_LIBRARY_NONFREE_LIST//_/-})
    if enabled_any "${nonfreegpl[@]}"; then
        if [[ $license = "nonfree" ]] && enabled gpl; then
            do_addOption --enable-nonfree
        elif [[ $license = gpl* ]]; then
            do_removeOptions "${nonfreegpl[*]/#/--enable-}"
        fi
        # no lgpl here because they are accepted with it
    fi

    if ! disabled debug "debug=gdb"; then
        # fix issue with ffprobe not working with debug and strip
        do_addOption --disable-stripping
    fi

    enabled openssl && do_removeOption "--enable-(gcrypt|gmp)"

    # remove libs that don't work with shared
    if [[ $ffmpeg =~ "shared" || $ffmpeg = "both" ]]; then
        FFMPEG_OPTS_SHARED=("${FFMPEG_OPTS[@]}")
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
    MPV_OPTS=()
    if [[ -f "/trunk/media-autobuild_suite.bat" && "$ffmpegChoice" =~ (n|z|f) ]]; then
        IFS=$'\n' read -d '' -r -a bat < <(< /trunk/media-autobuild_suite.bat dos2unix)
        MPV_OPTS=($(do_readbatoptions "mpv_options_(builtin|basic)"))
        [[ $ffmpegChoice = f ]] &&
            MPV_OPTS+=($(do_readbatoptions "mpv_options_full"))
        echo "Imported default mpv options from .bat"
    else
        IFS=$'\n' read -d '' -r -a MPV_OPTS < \
            <(do_readoptionsfile "$LOCALBUILDDIR/mpv_options.txt")
    fi
    do_removeOption MPV_OPTS \
        "--(en|dis)able-(vapoursynth-lazy|libguess|static-build|enable-gpl3|egl-angle-lib)"
    if [[ $mpv = "y" ]]; then
        mpv_disabled vapoursynth || do_addOption MPV_OPTS --disable-vapoursynth
    elif [[ $mpv = "v" ]] && ! mpv_disabled vapoursynth; then
        do_addOption MPV_OPTS --enable-vapoursynth
    fi
}

mpv_enabled() {
    local option
    [[ $mpv = n ]] && return 1
    for option in "${MPV_OPTS[@]}"; do
        [[ "$option" =~ "--enable-$1"$ ]] && return
    done
    return 1
}

mpv_disabled() {
    local option
    [[ $mpv = n ]] && return 0
    for option in "${MPV_OPTS[@]}"; do
        [[ "$option" =~ "--disable-$1"$ ]] && return
    done
    return 1
}

mpv_enabled_any() {
    local opt
    for opt; do
        mpv_enabled "$opt" && return 0
    done
    return 1
}

mpv_enabled_all() {
    local opt
    for opt; do
        mpv_enabled $opt || return 1
    done
}

mpv_disabled_all() {
    local opt
    for opt; do
        mpv_disabled $opt || return 1
    done
}

mpv_enable() {
    local opt newopts=()
    for opt in "${MPV_OPTS[@]}"; do
        if [[ "$opt" =~ "--disable-$1"$ ]]; then
            newopts+=("--enable-$1")
        else
            newopts+=("$opt")
        fi
    done
    MPV_OPTS=("${newopts[@]}")
}

mpv_disable() {
    local opt newopts=()
    for opt in "${MPV_OPTS[@]}"; do
        if [[ "$opt" =~ "--enable-$1"$ ]]; then
            newopts+=("--disable-$1")
        else
            newopts+=("$opt")
        fi
    done
    MPV_OPTS=("${newopts[@]}")
}

do_addOption() {
    local varname="$1" array opt
    if [[ ${varname#--} = $varname ]]; then
        array="$varname" && shift 1
    else
        array="FFMPEG_OPTS"
    fi
    for opt; do
        ! opt_exists "$array" "$opt" && declare -ag "$array+=(\"$opt\")"
    done
}

do_removeOption() {
    local varname="$1"
    local arrayname
    if [[ ${varname#--} = $varname ]]; then
        arrayname="$varname" && shift 1
    else
        arrayname="FFMPEG_OPTS"
    fi

    local option="$1"
    local basearray opt temp=()
    basearray="${arrayname}[@]"
    local orig=("${!basearray}")

    for ((i = 0; i < ${#orig[@]}; i++)); do
        if [[ ! "${orig[$i]}" =~ ^${option}$ ]]; then
            temp+=("${orig[$i]}")
        fi
    done
    eval "$arrayname"=\(\"\${temp[@]}\"\)
}

do_removeOptions() {
    local option
    local shared=$2
    for option in $1; do
        do_removeOption "$option" $shared
    done
}

do_patch() {
    local patch=${1%% *}
    local am=$2          # "am" to apply patch with "git am"
    local strip=${3:-1}  # value of "patch" -p i.e. leading directories to strip
    [[ $patch = ${patch##*/} ]] &&
        patch="/patches/$patch"
    do_wget -c -r -q "$patch"
    [[ ! -f "$patch" ]] && patch=${patch##*/}
    if [[ -f "$patch" ]]; then
        if [[ "$am" = "am" ]]; then
            if ! git am -q --ignore-whitespace "$patch" >/dev/null 2>&1; then
                git am -q --abort
                echo -e "${orange}${patch}${reset}"
                echo -e "\tPatch couldn't be applied with 'git am'. Continuing without patching."
            fi
        else
            if patch --dry-run --binary -s -N -p"$strip" -i "$patch" >/dev/null 2>&1; then
                patch --binary -s -N -p"$strip" -i "$patch"
            else
                echo -e "${orange}${patch}${reset}"
                echo -e "\tPatch couldn't be applied with 'patch'. Continuing without patching."
            fi
        fi
    else
        echo -e "${orange}${patch}${reset}"
        echo -e "\tPatch not found anywhere. Continuing without patching."
    fi
}

do_custom_patches() {
    local patch
    for patch in "$@"; do
        [[ "${patch##*.}" = "patch" ]] && do_patch "$patch" am
        [[ "${patch##*.}" = "diff" ]] && do_patch "$patch"
    done
}

do_cmake() {
    local root=".."
    local PKG_CONFIG=pkg-config
    create_build_dir
    [[ $1 && -d "../$1" ]] && root="../$1" && shift
    log "cmake" cmake "$root" -G Ninja -DBUILD_SHARED_LIBS=off \
        -DCMAKE_INSTALL_PREFIX="$LOCALDESTDIR" -DUNIX=on \
        -DCMAKE_BUILD_TYPE=Release "$@"
}

do_cmakeinstall() {
    do_cmake "$@"
    log build ninja
    cpuCount=1 log install ninja install
}

do_meson() {
    local root=".."
    local PKG_CONFIG=pkg-config
    create_build_dir
    [[ $1 && -d "../$1" ]] && root="../$1" && shift
    log meson meson "$root" --default-library=static \
        --prefix="$LOCALDESTDIR" "$@"
}

do_mesoninstall() {
    do_meson "$@"
    log build ninja
    cpuCount=1 log install ninja install
}

compilation_fail() {
    [[ -z $build32 || -z $build64 ]] && return 1
    local reason="$1"
    local operation
    operation="$(echo "$reason" | tr '[:upper:]' '[:lower:]')"
    if [[ $logging = y ]]; then
        echo "Likely error:"
        tail "ab-suite.${operation}.log"
        echo "${red}$reason failed. Check $(pwd -W)/ab-suite.$operation.log${reset}"
    fi
    if [[ $_notrequired ]]; then
        echo "This isn't required for anything so we can move on."
        return 1
    else
        echo "${red}This is required for other packages, so this script will exit.${reset}"
        create_diagnostic
        zip_logs
        echo "Make sure the suite is up-to-date before reporting an issue. It might've been fixed already."
        do_prompt "Try running the build again at a later time."
        exit 1
    fi
}

strip_ansi() {
    local txtfile newfile
    for txtfile; do
        [[ $txtfile != "${txtfile//stripped/}" ]] && continue
        local name="${txtfile%.*}"
        local ext="${txtfile##*.}"
        [[ $txtfile != "$name" ]] && newfile="${name}.stripped.${ext}" || newfile="${txtfile}-stripped"
        sed -r 's#(\x1B[\[\(]([0-9][0-9]?)?[mBHJ]|\x07|\x1B]0;)##g' "$txtfile" > "${newfile}"
    done
}

zip_logs() {
    local failed url files
    failed="$(get_first_subdir)"
    pushd "$LOCALBUILDDIR" >/dev/null
    rm -f logs.zip
    strip_ansi ./*.log
    files=(/trunk/media-autobuild_suite.bat)
    [[ $failed ]] && files+=($(find "$failed" -name "*.log"))
    files+=($(find . -maxdepth 1 -name "*.stripped.log" -o -name "*_options.txt" -o -name "media-suite_*.sh" \
        -o -name "last_run" -o -name "media-autobuild_suite.ini" -o -name "diagnostics.txt"))
    7za -mx=9 a logs.zip "${files[@]}" >/dev/null
    [[ $build32 || $build64 ]] && url="$(/usr/bin/curl -sF'file=@logs.zip' https://0x0.st)"
    popd >/dev/null
    echo
    if [[ $url ]]; then
        echo "${green}All relevant logs have been anonymously uploaded to $url"
        echo "${green}Copy and paste ${red}[logs.zip]($url)${green} in the GitHub issue.${reset}"
    elif [[ -f "$LOCALBUILDDIR/logs.zip" ]]; then
        echo "${green}Attach $(cygpath -w "$LOCALBUILDDIR/logs.zip") to the GitHub issue.${reset}"
    fi
}

log() {
    [[ $1 = quiet ]] && local quiet=y && shift
    local name="${1// /.}"
    local _cmd="$2"
    shift 2
    local extra
    [[ $quiet ]] || do_print_progress Running "$name"
    [[ $_cmd =~ ^(make|ninja)$ ]] && extra="-j$cpuCount"
    if [[ $logging = "y" ]]; then
        echo -e "CFLAGS: $CFLAGS\nLDFLAGS: $LDFLAGS" > "ab-suite.$name.log"
        echo "$_cmd $*" >> "ab-suite.$name.log"
        $_cmd $extra "$@" >> "ab-suite.$name.log" 2>&1 ||
            { [[ $extra ]] && $_cmd -j1 "$@" >> "ab-suite.$name.log" 2>&1; } ||
            compilation_fail "$name"
    else
        $_cmd $extra "$@" || { [[ $extra ]] && $_cmd -j1 "$@"; } ||
            compilation_fail "$name"
    fi
}

create_build_dir() {
    local build_dir="build${1:+-$1}-$bits"
    if [[ "$(basename "$(pwd)")" = "$build_dir" ]]; then
        rm -rf ./*
    elif [[ -d "$build_dir" ]] && ! rm -rf ./"$build_dir"; then
        cd_safe "$build_dir" && rm -rf ./*
    else
        mkdir "$build_dir" && cd_safe "$build_dir"
    fi
}

get_external_opts() {
    local pkgname="$(get_first_subdir)"
    do_readoptionsfile "$LOCALBUILDDIR/${pkgname%-*}_options.txt"
}

do_separate_conf() {
    local bindir=""
    local last config_path
    case "$1" in
    global|audio|video)
        bindir="--bindir=$LOCALDESTDIR/bin-$1" ;;
    *) bindir="$1" ;;
    esac
    shift 1
    for last; do true; done
    if test -x "${last}/configure"; then
        config_path="$last"
    else
        config_path=".."
        create_build_dir
    fi
    log configure ${config_path}/configure --{build,host,target}="$MINGW_CHOST" \
        --prefix="$LOCALDESTDIR" --disable-shared --enable-static "$bindir" "$@"
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
    local dryrun="${dry:-n}"
    local files
    files="$(find /mingw{32,64}/lib /mingw{32/i686,64/x86_64}-w64-mingw32/lib -name "*.dll.a" 2>/dev/null)"
    local tomove=()
    for file in $files; do
        [[ -f "${file%*.dll.a}.a" ]] && tomove+=("$file")
    done
    if [[ $dryrun = "n" ]]; then
        printf "%s\n" "${tomove[@]}" | xargs -i mv -f '{}' '{}.dyn'
    else
        printf "%s\n" "${tomove[@]}"
    fi
}

do_unhide_all_sharedlibs() {
    local dryrun="${dry:-n}"
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
    installed="$(pacman -Qqe | /usr/bin/grep "^${MINGW_PACKAGE_PREFIX}-")"
    for pkg; do
        [[ "$pkg" != "${MINGW_PACKAGE_PREFIX}-"* ]] && pkg="${MINGW_PACKAGE_PREFIX}-${pkg}"
        /usr/bin/grep -q "^${pkg}$" <(echo "$installed") && continue
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
        log "autoreconf" autoreconf -fiv $*
    fi
}

do_autogen() {
    local basedir="$LOCALBUILDDIR"
    basedir+="/$(get_first_subdir)" || basedir="."
    if { [[ -f "$basedir"/recently_updated &&
        -z "$(ls "$basedir"/build_successful* 2> /dev/null)" ]]; } ||
        [[ ! -f configure ]]; then
        git clean -qxfd -e "/build_successful*" -e "/recently_updated"
        log "autogen" ./autogen.sh $*
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

clean_html_index() {
    local url="$1"
    local filter="${2:-(?<=href=\")[^\"]+\.(tar\.(gz|bz2|xz)|7z)}"
    "${curl_opts[@]}" -l "$url" | grep -ioP "$filter" | sort -uV
}

get_last_version() {
    local filelist="$1"
    local filter="$2"
    local version="$3"
    local ret
    ret="$(echo "$filelist" | /usr/bin/grep -E "$filter" | sort -V | tail -1)"
    [[ -n "$version" ]] && ret="$(echo "$ret" | /usr/bin/grep -oP "$version")"
    echo "$ret"
}

create_debug_link() {
    for file; do
        if [[ -f "$file" && ! -f "$file".debug ]]; then
            echo "Stripping and creating debug link for ${file##*/}..."
            objcopy --only-keep-debug "$file" "$file".debug
            if [[ ${file: -3} = "dll" ]]; then
                strip --strip-debug "$file"
            else
                strip --strip-all "$file"
            fi
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
    elif regtool -qW check "$regkey" && [[ $(regtool -qW list "$regkey") = *Path* ]]; then
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

get_cl_path() {
    local vswhere="$(cygpath -u "$(cygpath -F 0x002a)/Microsoft Visual Studio/Installer/vswhere.exe")"
    if [[ -f "$vswhere" ]]; then
        local installationpath="$("$vswhere" -legacy -version 14 -property installationPath | tail -n1)"
        [[ -z "$installationpath" ]] && return 1
        local basepath="$(cygpath -u "$installationpath/VC/bin")"
        if [[ "$bits" = 32bit && -f "$basepath/cl.exe" ]]; then
            export PATH="$basepath":$PATH
        elif [[ "$bits" = 64bit && -f "$basepath/amd64/cl.exe" ]]; then
            export PATH="$basepath/amd64":$PATH
        else
            return 1
        fi
    else
        local clpath
        local regpath="/HKLM/Software/Microsoft/VisualStudio/VC/19.0"
        if [[ $bits = 32bit ]]; then
            clpath="$(regtool -qW get "$regpath/x86/x86/Compiler")"
        elif [[ $bits = 64bit ]]; then
            clpath="$(regtool -qW get "$regpath/x64/x64/Compiler")"
        fi
        [[ -z "$clpath" ]] && return 1
        clpath="$(dirname "$(cygpath -u "$clpath")")"
        [[ ! -f "$clpath"/cl.exe ]] && return 1
        export PATH="$clpath":$PATH
    fi
}

get_java_home() {
    local javahome version
    local javabasereg="/HKLM/software/javasoft"
    local regkey="$javabasereg/java development kit"
    export JAVA_HOME=
    export JDK_HOME=""
    if ! regtool -q check "$regkey"; then
        echo "no version of JDK found"
        return
    fi

    version="$(regtool -q get "$regkey/CurrentVersion")"
    [[ $(vercmp "$version" 1.8) != 0 ]] &&
        echo "JDK 1.8 required, 9 doesn't work" && return
    javahome="$(regtool -q get "$regkey/$version/JavaHome")"
    javahome="$(cygpath -u "$javahome")"
    [[ -f "$javahome/bin/java.exe" ]] &&
        export JAVA_HOME="$javahome"
}

get_api_version() {
    local header="$1"
    [[ -n $(file_installed "$header") ]] && header="$(file_installed "$header")"
    local line="$2"
    local column="$3"
    /usr/bin/grep "${line:-VERSION}" "$header" | awk '{ print $c }' c="${column:-3}" | sed 's|"||g'
}

hide_files() {
    local reverse=n echo_cmd
    [[ $1 = "-R" ]] && reverse=y && shift
    [[ $dryrun = y ]] && echo_cmd="echo"
    for opt; do
        if [[ $reverse = n ]]; then
            [[ -f "$opt" ]] && $echo_cmd mv -f "$opt" "$opt.bak"
        else
            [[ -f "$opt.bak" ]] && $echo_cmd mv -f "$opt.bak" "$opt"
        fi
    done
}

hide_conflicting_libs() {
    # meant for rude build systems
    local reverse=n
    [[ $1 = "-R" ]] && reverse=y && shift
    local priority_prefix
    local -a installed
    installed=($(find "$LOCALDESTDIR/lib" -maxdepth 1 -name "*.a"))
    if [[ $reverse = n ]]; then
        hide_files "${installed[@]//$LOCALDESTDIR/$MINGW_PREFIX}"
    else
        hide_files -R "${installed[@]//$LOCALDESTDIR/$MINGW_PREFIX}"
    fi
    if [[ -n "$1" ]]; then
        priority_prefix="$1"
        installed=($(find "$priority_prefix/lib" -maxdepth 1 -name "*.a"))
        if [[ $reverse = n ]]; then
            hide_files "${installed[@]//$1/$LOCALDESTDIR}"
        else
            hide_files -R "${installed[@]//$1/$LOCALDESTDIR}"
        fi
    fi
}

function hide_libressl() {
    local _hide_files=(include/openssl
        lib/lib{crypto,ssl,tls}.{,l}a
        lib/pkgconfig/openssl.pc
        lib/pkgconfig/lib{crypto,ssl,tls}.pc)
    local reverse=n
    local _f
    [[ $1 = "-R" ]] && reverse=y && shift
    for _f in ${_hide_files[*]}; do
        _f="$LOCALDESTDIR/$_f"
        if [[ $reverse = n ]]; then
            [[ -e "$_f" ]] && mv -f "$_f" "$_f.bak"
        else
            [[ -e "$_f.bak" ]] && mv -f "$_f.bak" "$_f"
        fi
    done
}

add_to_remove() {
    local garbage="$1"
    [[ ! $garbage ]] && garbage="$LOCALBUILDDIR/$(get_first_subdir)"
    echo "$garbage" >> "$LOCALBUILDDIR/_to_remove"
}

clean_suite() {
    echo -e "\n\t${orange}Deleting status files...${reset}"
    cd_safe "$LOCALBUILDDIR" >/dev/null
    find . -maxdepth 2 \( -name recently_updated -o -name recently_checked \) -print0 | xargs -0 rm -f
    find . -maxdepth 2 -regex ".*build_successful\(32\|64\)bit\(_shared\|_light\)?\$" -print0 |
        xargs -0 rm -f
    echo -e "\n\t${green}Zipping man files...${reset}"
    do_zipman

    if [[ $deleteSource = y ]]; then
        echo -e "\t${orange}Deleting temporary build dirs...${reset}"
        find . -maxdepth 5 -name "ab-suite.*.log" -print0 | xargs -0 rm -f
        find . -maxdepth 5 -type d -name "build-*bit" -print0 | xargs -0 rm -rf
        find . -maxdepth 2 -type d -name "build" -exec test -f "{}/CMakeCache.txt" ';' -print0 |
            xargs -0 rm -rf

        if [[ -f _to_remove ]]; then
            echo -e "\n\t${orange}Deleting source folders...${reset}"
            grep -E "^($LOCALBUILDDIR|/trunk$LOCALBUILDDIR)" < _to_remove |
                grep -Ev "^$LOCALBUILDDIR/(patches|extras|$)" | sort -u | xargs -r rm -rf
        fi
        if [[ $(du -s /var/cache/pacman/pkg/ | awk '{print $1}') -gt 1000000 ]]; then
            echo -e "\t${orange}Deleting unneeded Pacman packages...${reset}"
            pacman -Sc --noconfirm
        fi
    fi

    rm -f {firstrun,firstUpdate,secondUpdate,pacman,mingw32,mingw64}.log diagnostics.txt \
        logs.zip _to_remove ./*.stripped.log

    [[ -f last_run ]] && mv last_run last_successful_run && touch last_successful_run
    [[ -f CHANGELOG.txt ]] && cat CHANGELOG.txt >> newchangelog
    unix2dos -n newchangelog CHANGELOG.txt 2> /dev/null && rm -f newchangelog
}

create_diagnostic() {
    local cmd cmds=("uname -a" "pacman -Qe" "pacman -Qd")
    local _env envs=(MINGW_{PACKAGE_PREFIX,CHOST,PREFIX} MSYSTEM CPATH
        LIBRARY_PATH {LD,C,CPP,CXX}FLAGS)
    do_print_progress "  Creating diagnostics file"
    [[ -d /trunk/.git ]] && cmds+=("git -C /trunk log -1 --pretty=%h")
    rm -f "$LOCALBUILDDIR/diagnostics.txt"
    echo "Env variables:" >>"$LOCALBUILDDIR/diagnostics.txt"
    for _env in "${envs[@]}"; do
        printf '\t%s=%s\n' "$_env" "${!_env}" >>"$LOCALBUILDDIR/diagnostics.txt"
    done
    echo >>"$LOCALBUILDDIR/diagnostics.txt"
    for cmd in "${cmds[@]}"; do
        printf '\t%s\n%s\n\n' "$cmd" "$($cmd)" >>"$LOCALBUILDDIR/diagnostics.txt"
    done
}

create_winpty_exe() {
    local exename="$1"
    local installdir="$2"
    shift 2
    [[ -f "${installdir}/${exename}".exe ]] && mv "${installdir}/${exename}"{.,_}exe
    printf '%s\n' "#!/usr/bin/env bash" "$@" \
        'if [[ -t 1 ]]; then' \
        '/usr/bin/winpty "$( dirname ${BASH_SOURCE[0]} )/'"${exename}"'.exe" "$@"' \
        'else "$( dirname ${BASH_SOURCE[0]} )/'"${exename}"'.exe" "$@"; fi' \
        > "${installdir}/${exename}"
    [[ -f "${installdir}/${exename}"_exe ]] && mv "${installdir}/${exename}"{_,.}exe
}

_define(){ IFS='\n' read -r -d '' ${1} || true; }
create_ab_pkgconfig() {
    # from https://stackoverflow.com/a/8088167
    local script_file
    _define script_file <<'EOF'
#!/bin/sh

while true; do
case $1 in
    --libs|--libs-*) libs_args+=" $1"; shift ;;
    --static) static="--static"; shift ;;
    --* ) base_args+=" $1"; shift ;;
    * ) break ;;
esac
done

run_pkgcfg() {
    "$MINGW_PREFIX/bin/pkg-config" "$@" || exit 1
}

deduplicateLibs() {
    otherflags="$(run_pkgcfg $static $base_args "$@")"
    unordered="$(run_pkgcfg $static $libs_args "$@")"
    libdirs="$(printf '%s\n' $unordered | grep '^-L' | tr '\n' ' ')"
    unordered="${unordered//$libdirs}"
    ord_libdirs=""
    for libdir in $libdirs; do
        libdir="$(cygpath -m ${libdir#-L})"
        ord_libdirs+=" -L$libdir"
    done
    ord_libdirs="$(printf '%s\n' $ord_libdirs | awk '!x[$0]++' | tr '\n' ' ')"
    ord_libs="$(printf '%s\n' $unordered | tac | awk '!x[$0]++' | tac | tr '\n' ' ')"
    printf '%s ' $otherflags $ord_libdirs $ord_libs
    echo
}

if [[ -n $libs_args ]]; then
    deduplicateLibs "$@"
else
    run_pkgcfg $static $base_args $libs_args "$@"
fi
EOF
    [[ -f "$LOCALDESTDIR"/bin/ab-pkg-config ]] &&
        diff -q <(printf '%s' "$script_file") "$LOCALDESTDIR"/bin/ab-pkg-config >/dev/null ||
        printf '%s' "$script_file" > "$LOCALDESTDIR"/bin/ab-pkg-config
}
