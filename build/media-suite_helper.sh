#!/bin/bash
# shellcheck disable=SC2154,SC2120,SC2119,SC2034,SC1090,SC1117

if [[ ! $cpuCount =~ ^[0-9]+$ ]]; then
    cpuCount="$(($(nproc)/2))"
fi
bits="${bits:-64bit}"
curl_opts=(/usr/bin/curl --connect-timeout 15 --retry 3
    --retry-delay 5 --silent --location --insecure --fail)

if test -n "$(tput colors)" && test "$(tput colors)" -ge 8; then
    bold=$(tput bold)
    blue=$(tput setaf 12)
    orange=$(tput setaf 11)
    purple=$(tput setaf 13)
    green=$(tput setaf 2)
    red=$(tput setaf 1)
    reset=$(tput sgr0)
fi
ncols=72

[[ -f "$LOCALBUILDDIR"/grep.exe ]] &&
    rm -f "$LOCALBUILDDIR"/{7za,wget,grep}.exe

do_simple_print() {
    local plain formatString='' dateValue
    [[ $1 == -p ]] && plain=y && shift

    if [[ $timeStamp == y ]]; then
        formatString+="${purple}"'%(%H:%M:%S)T'"${reset}"' '
        dateValue='-1'
    else
        [[ $plain == y ]] && formatString+='\t'
    fi
    if [[ -z $plain ]]; then
        formatString+="${bold}├${reset} "
    fi
    printf "$formatString"'%b'"$reset"'\n' $dateValue "$*"
}

do_print_status() {
    local name="$1 "
    local color="$2"
    local status="$3"
    local pad
    printf -v pad ".%.0s" $(seq -s ' ' 1 $ncols)
    if [[ $timeStamp == y ]]; then
        printf "${purple}"'%(%H:%M:%S)T'"${reset}"' %s %s [%s]\n' -1 "${bold}$name${reset}" \
        "${pad:0:$((ncols - ${#name} - ${#status} - 12))}" "${color}${status}${reset}"
    else
        printf '%s %s [%s]\n' "${bold}$name${reset}" "${pad:0:$((ncols - ${#name} - ${#status} - 3))}" "${color}${status}${reset}"
    fi
}

do_print_progress() {
    if [[ $logging == y ]]; then
        if [[ $timeStamp == y ]]; then
            [[ $1 =~ ^[a-zA-Z] ]] && printf "${purple}"'%(%H:%M:%S)T'"${reset}"' %s\n' -1 \
            "${bold}├${reset} $*..." || printf "${purple}"'%(%H:%M:%S)T'"${reset}"' %s\n' -1 "$*..."
        else
            [[ $1 =~ ^[a-zA-Z] ]] && echo "${bold}├${reset} $*..." || echo -e "$*..."
        fi
    else
        set_title "$* in $(get_first_subdir)"
        if [[ $timeStamp == y ]]; then
            printf "${purple}"'%(%H:%M:%S)T'"${reset}"' %s\n' -1 "${bold}$* in $(get_first_subdir)${reset}"
        else
            echo -e "${bold}$* in $(get_first_subdir)${reset}"
        fi
    fi
}

set_title() {
    local title="media-autobuild_suite ($bits)"
    [[ -z $1 ]] || title="$title: $1"
    printf '\033]0;%s\a' "$title"
}

do_exit_prompt() {
    if [[ -n "$build32$build64" ]]; then # meaning "executing this in the suite's context"
        create_diagnostic
        zip_logs
    fi
    do_prompt "$*"
    [[ -n "$build32$build64" ]] && exit 1
}

cd_safe() {
    cd "$1" || do_exit_prompt "Failed changing to directory $1."
}

test_newer() {
    [[ $1 == installed ]] && local installed=y && shift
    local file
    local files=("$@")
    local cmp="${files[-1]}"
    [[ $installed ]] && cmp="$(file_installed "$cmp")"
    [[ ${#files[@]} -gt 1 ]] && unset 'files[-1]'
    [[ -f $cmp ]] || return 0
    for file in "${files[@]}"; do
        [[ $installed ]] && file="$(file_installed "$file")"
        [[ -f $file ]] &&
            [[ $file -nt $cmp ]] && return
    done
    return 1
}

check_valid_vcs() {
    local root="${1:-.}"
    local _type="${vcsType:-git}"
    [[ $_type == "git" && -d "$root"/.git ]] ||
        [[ $_type == "hg" && -d "$root"/.hg ]] ||
        [[ $_type == "svn" && -d "$root"/.svn ]]
}

vcs_clone() {
    set -x
    if [[ $vcsType == "svn" ]]; then
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
    if [[ $vcsType == svn ]]; then
        svn revert --recursive .
        oldHead=$(svnversion)
    elif [[ $vcsType == hg ]]; then
        hg update -C -r "$ref"
        oldHead=$(hg id --id)
    elif [[ $vcsType == git ]]; then
        [[ -n $vcsURL ]] && git remote set-url origin "$vcsURL"
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
    if [[ $vcsType == svn ]]; then
        svn update -r "$ref"
        newHead=$(svnversion)
    elif [[ $vcsType == hg ]]; then
        hg pull
        hg update -C -r "$ref"
        newHead=$(hg id --id)
    elif [[ $vcsType == git ]]; then
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
    if [[ $vcsType == "git" ]]; then
        git log --no-merges --pretty="%ci: %an - %h%n    %s" \
            "$oldHead".."$newHead" >> "$LOCALBUILDDIR"/newchangelog
    elif [[ $vcsType == "hg" ]]; then
        hg log --template '{date|localdate|isodatesec}: {author|person} - {node|short}\n    {desc|firstline}\n' \
            -r "reverse($oldHead:$newHead)" >> "$LOCALBUILDDIR"/newchangelog
    fi
}

vcs_getlatesttag() {
    local ref="$1"
    if [[ -n $vcsType && $vcsType != git ]]; then
        echo "$ref"
        return
    fi
    local tag
    if [[ $ref == "LATEST" ]]; then
        tag="$(git describe --abbrev=0 --tags "$(git rev-list --tags --max-count=1)")"
    elif [[ $ref == "GREATEST" ]]; then
        tag="$(git describe --abbrev=0 --tags)"
    elif [[ ${ref//\*/} != "$ref" ]]; then
        tag="$(git describe --abbrev=0 --tags "$(git tag -l "$ref" | sort -Vr | head -1)")"
    fi
    echo "${tag:-${ref}}"
}

# get source from VCS
# example:
#   do_vcs "url#branch|revision|tag|commit=NAME" "folder"
do_vcs() {
    local vcsType="${1%::*}"
    local vcsURL="${1#*::}"
    [[ $vcsType == "$vcsURL" ]] && vcsType="git"
    local vcsBranch="${vcsURL#*#}"
    [[ $vcsBranch == "$vcsURL" ]] && vcsBranch=""
    local vcsFolder="$2"
    local vcsCheck=("${_check[@]}")
    local deps=("${_deps[@]}") && unset _deps
    local ref
    if [[ $vcsBranch ]]; then
        vcsURL="${vcsURL%#*}"
        case ${vcsBranch%%=*} in
        commit | tag | revision)
            ref=${vcsBranch##*=}
            ;;
        branch)
            ref=${vcsBranch##*=}
            [[ $vcsType == git && $ref == "${ref%/*}" ]] && ref=origin/$ref
            ;;
        esac
    else
        if [[ $vcsType == git ]]; then
            ref="origin/HEAD"
        elif [[ $vcsType == hg ]]; then
            ref="default"
        elif [[ $vcsType == svn ]]; then
            ref="HEAD"
        fi
    fi
    [[ ! $vcsFolder ]] && vcsFolder="${vcsURL##*/}" && vcsFolder="${vcsFolder%.*}"

    cd_safe "$LOCALBUILDDIR"
    if [[ ! -d "$vcsFolder-$vcsType" ]]; then
        do_print_progress "  Running $vcsType clone for $vcsFolder"
        if ! log quiet "$vcsType.clone" vcs_clone && [[ $vcsType == git ]] &&
            [[ $vcsURL != *"media-autobuild_suite-dependencies"* ]]; then
            local repoName=${vcsURL##*/}
            vcsURL="https://gitlab.com/media-autobuild_suite-dependencies/${repoName}"
            log quiet "$vcsType.clone" vcs_clone ||
            do_exit_prompt "Failed cloning to $vcsFolder-$vcsType"
        fi
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

    if [[ $ffmpegUpdate == onlyFFmpeg ]] &&
        [[ $vcsFolder != ffmpeg ]] && [[ $vcsFolder != mpv ]] &&
        { { [[ -z ${vcsCheck[*]} ]] && files_exist "$vcsFolder.pc"; } ||
            { [[ -n ${vcsCheck[*]} ]] && files_exist "${vcsCheck[@]}"; }; }; then
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

    rm -f custom_updated
    check_custom_patches

    if [[ $oldHead != "$newHead" || -f custom_updated ]]; then
        touch recently_updated
        rm -f ./build_successful{32,64}bit{,_*}
        if [[ $build32 == "yes" && $build64 == "yes" && $bits == "64bit" ]]; then
            new_updates="yes"
            new_updates_packages="$new_updates_packages [$vcsFolder]"
        fi
        echo "$vcsFolder" >> "$LOCALBUILDDIR"/newchangelog
        vcs_log
        echo >> "$LOCALBUILDDIR"/newchangelog
        do_print_status "┌ ${vcsFolder} ${vcsType}" "$orange" "Updates found"
    elif [[ -f recently_updated ]] && { [[ ! -f "build_successful$bits" ]] ||
        [[ -n $flavor && ! -f "build_successful${bits}_${flavor}" ]]; }; then
        do_print_status "┌ ${vcsFolder} ${vcsType}" "$orange" "Recently updated"
    elif [[ -z ${vcsCheck[*]} ]] && ! files_exist "$vcsFolder.pc"; then
        do_print_status "┌ ${vcsFolder} ${vcsType}" "$orange" "Missing pkg-config"
    elif [[ -n ${vcsCheck[*]} ]] && ! files_exist "${vcsCheck[@]}"; then
        do_print_status "┌ ${vcsFolder} ${vcsType}" "$orange" "Files missing"
    elif [[ -n ${deps[*]} ]] && test_newer installed "${deps[@]}" "${vcsCheck[0]}"; then
        do_print_status "┌ ${vcsFolder} ${vcsType}" "$orange" "Newer dependencies"
    else
        do_print_status "${vcsFolder} ${vcsType}" "$green" "Up-to-date"
        if [[ -f recompile ]]; then
            do_print_status "┌ ${vcsFolder} ${vcsType}" "$orange" "Forcing recompile"
            do_print_status "${bold}├${reset} Found recompile flag" "$orange" "Recompiling"
        else
            return 1
        fi
    fi
    return 0
}

guess_dirname() {
    expr "$1" : '\(.\+\)\.\(tar\(\.\(gz\|bz2\|xz\)\)\?\|7z\|zip\)$'
}

check_hash() {
    local file="$1" check="$2" md5sum sha256sum
    if [[ -z $file || ! -f $file ]]; then
        return 1
    elif [[ -z $check ]]; then
        # if no hash to check, just check if the file exists
        return 0
    fi

    sha256sum=$(sha256sum "$file" | cut -d' ' -f1)
    if [[ $check == print ]]; then
        echo "$sha256sum"
    else
        md5sum=$(md5sum "$file" | cut -d' ' -f1)
        if [[ $sha256sum == "$check" || $md5sum == "$check" ]]; then
            return 0
        fi
        do_simple_print "${orange}Hash mismatch, file may be broken: ${check} != ${sha256sum} || ${md5sum}"
        return 1
    fi
}

# get wget download
do_wget() {
    local nocd norm quiet hash notmodified
    while true; do
        case $1 in
        -c) nocd=nocd && shift ;;
        -r) norm=y && shift ;;
        -q) quiet=y && shift ;;
        -h) hash="$2" && shift 2 ;;
        -z) notmodified=y && shift ;;
        --)
            shift
            break
            ;;
        *) break ;;
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
        curlcmds=("${curl_opts[@]}")
        [[ $notmodified && -f $archive ]] && curlcmds+=(-z "$archive" -R)
        [[ $hash ]] && tries=3
        while [[ $tries -gt 0 ]]; do
            response_code="$("${curlcmds[@]}" -w "%{response_code}" -o "$archive" "$url")"
            (( tries-=1 ))

            if [[ $response_code == "200" || $response_code == "226" ]]; then
                [[ $quiet ]] || do_print_status "┌ ${dirName:-$archive}" "$orange" "Downloaded"
            elif [[ $response_code == "304" ]]; then
                [[ $quiet ]] || do_print_status "┌ ${dirName:-$archive}" "$orange" "File up-to-date"
            fi
            if check_hash "$archive" "$hash"; then
                tries=0
            else
                rm -f "$archive"
            fi
        done
        if [[ $response_code -gt 400 || $response_code == "000" ]]; then
            if [[ -f $archive ]]; then
                echo -e "${orange}${archive}${reset}"
                echo -e '\tFile not found online. Using local copy.'
            else
                do_print_status "└ ${dirName:-$archive}" "$red" "Failed"
                echo "Error $response_code while downloading $url"
                echo "<Ctrl+c> to cancel build or <Enter> to continue"
                do_prompt "if you're sure nothing depends on it."
                return 1
            fi
        fi
    else
        [[ $quiet ]] || do_print_status "${bold}├${reset} ${dirName:-$archive}" "$green" "File up-to-date"
    fi
    [[ $norm ]] || add_to_remove "$(pwd)/$archive"
    do_extract "$archive" "$dirName"
    [[ ! $norm && $dirName && ! $nocd ]] && add_to_remove
    [[ -z $response_code || $response_code != "304" ]] && return 0
}

real_extract() {
    local archive="$1" dirName="$2" archive_type
    [[ -z $archive ]] && return 1
    archive_type=$(expr "$archive" : '.\+\(tar\(\.\(gz\|bz2\|xz\)\)\?\|7z\|zip\)$')
    [[ ! $dirName ]] && dirName=$(guess_dirname "$archive" || echo "${archive}")
    case $archive_type in
    zip | 7z)
        7z x -aoa -o"$dirName" "$archive"
        ;;
    tar*)
        [[ -n $dirName && ! -d $dirName ]] && mkdir -p "$dirName"
        [[ $archive_type == tar.* ]] && 7z x -aoa "$archive"
        [[ $(tar -tf "$archive" | cut -d'/' -f1 | sort -u | wc -l) == 1 ]] && strip_comp="--strip-components=1"
        if ! tar $strip_comp -C "$dirName" -xf "${1%.tar*}.tar"; then
            7z x -aoa "${archive%.tar*}.tar" -o"$dirName"
        fi
        rm -f "${archive%.tar*}.tar"
        ;;
    esac
    local temp_dir
    temp_dir=$(find "$dirName/" -maxdepth 1 ! -wholename "$dirName/")
    if [[ -n $temp_dir && $(wc -l <<< "$temp_dir") == 1 ]]; then
        find "$temp_dir" -maxdepth 1 ! -wholename "$temp_dir" -exec mv -t "$dirName/" {} +
        rmdir "$temp_dir" 2> /dev/null
    fi
}

do_extract() {
    local nocd="${nocd:-}"
    local archive="$1" dirName="$2"
    # accepted: zip, 7z, tar, tar.gz, tar.bz2 and tar.xz
    [[ -z $dirName ]] && dirName=$(guess_dirname "$archive")
    if [[ $dirName != "." && -d $dirName ]] &&
        {
            [[ $build32 == "yes" ]] && { [[ ! -f "$dirName"/build_successful32bit ]] ||
                [[ -n $flavor && ! -f "$dirName/build_successful32bit_${flavor}" ]]; } ||
                [[ $build64 == "yes" ]] && { [[ ! -f "$dirName"/build_successful64bit ]] ||
                    [[ -n $flavor && ! -f "$dirName/build_successful64bit_${flavor}" ]]; }
        }; then
        rm -rf "$dirName"
    elif [[ -d $dirName ]]; then
        [[ $nocd ]] || cd_safe "$dirName"
        return 0
    elif  ! expr "$archive" : '.\+\(tar\(\.\(gz\|bz2\|xz\)\)\?\|7z\|zip\)$' > /dev/null; then
        return 0
    fi
    log "extract" real_extract "$archive" "$dirName"
    [[ $nocd ]] || cd_safe "$dirName"
}

do_wget_sf() {
    # do_wget_sf "faac/faac-src/faac-1.28/faac-$_ver.tar.bz2" "faac-$_ver"
    local hash
    [[ $1 == "-h" ]] && hash="$2" && shift 2
    local url="https://download.sourceforge.net/$1"
    shift 1
    check_custom_patches
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
    for file; do
        if [[ $file =~ \.($exts)$ && ! $file =~ ($nostrip)\.exe$ ]]; then
            do_print_progress Stripping
            break
        fi
    done
    for file; do
        local orig_file="$file"
        if ! file="$(file_installed "$orig_file")"; then
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
            { eval "${cmd[@]}" "$file" 2> /dev/null ||
                eval "${cmd[@]}" "$file" -o "$file.stripped" 2> /dev/null; }
        [[ -f ${file}.stripped ]] && mv -f "${file}"{.stripped,}
    done
}

do_pack() {
    local file
    local cmd=(/opt/bin/upx -9 -qq)
    local nopack=""
    local exts="exe|dll"
    [[ $bits == 64bit ]] && enabled_any libtls openssl && nopack="ffmpeg|mplayer|mpv"
    for file; do
        if [[ $file =~ \.($exts)$ && ! $file =~ ($nopack)\.exe$ ]]; then
            do_print_progress Packing with UPX
            break
        fi
    done
    for file; do
        local orig_file="$file"
        if ! file="$(file_installed "$orig_file")"; then
            continue
        fi
        if [[ $file =~ \.($exts)$ ]] &&
            ! [[ -n $nopack && $file =~ ($nopack)\.exe$ ]]; then
            [[ $stripping == y ]] && cmd+=("--strip-relocs=0")
        else
            file=""
        fi
        [[ $file ]] && eval "${cmd[@]}" "$file"
    done
}

do_zipman() {
    local file files
    local man_dirs=(/local{32,64}/share/man)
    files=$(find "${man_dirs[@]}" -type f \! -name "*.gz" \! -name "*.db" \! -name "*.bz2" 2> /dev/null)
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
    if [[ $dry == y ]]; then
        files_exist -v -s "${check[@]}"
    else
        if files_exist -v "${check[@]}"; then
            [[ $stripping == y ]] && do_strip "${check[@]}"
            [[ $packing == y ]] && do_pack "${check[@]}"
            do_print_status "└ $packetName" "$blue" "Updated"
            [[ $build32 == yes || $build64 == yes ]] && [[ -d "$LOCALBUILDDIR/$packetName" ]] &&
                touch "$LOCALBUILDDIR/$packetName/build_successful$bits"
        else
            [[ $build32 == yes || $build64 == yes ]] && [[ -d "$LOCALBUILDDIR/$packetName" ]] &&
                rm -f "$LOCALBUILDDIR/$packetName/build_successful$bits"
            do_print_status "└ $packetName" "$red" "Failed"
            echo
            echo "Try deleting '$LOCALBUILDDIR/$packetName' and start the script again."
            echo "If you're sure there are no dependencies <Enter> to continue building."
            do_prompt "Close this window if you wish to stop building."
        fi
    fi
    unset _check
    unset_extra_script
}

file_installed() {
    local file
    local silent
    [[ $1 == "-s" ]] && silent=y
    case $1 in
    /* | ./*)
        file="$1"
        ;;
    *.pc)
        file="lib/pkgconfig/$1"
        ;;
    *.a | *.la | *.lib)
        file="lib/$1"
        ;;
    *.h | *.hpp | *.c)
        file="include/$1"
        ;;
    *)
        file="$1"
        ;;
    esac
    [[ ${file::1} != "/" ]] && file="$LOCALDESTDIR/$file"
    [[ -z $silent ]] && echo "$file"
    test -e "$file"
}

files_exist() {
    local verbose list soft ignorebinaries term='\n' file
    while true; do
        case $1 in
        -v) verbose=y && shift ;;
        -l) list=y && shift ;;
        -s) soft=y && shift ;;
        -b) ignorebinaries=y && shift ;;
        -l0) list=y && term='\0' && shift ;;
        --)
            shift
            break
            ;;
        *) break ;;
        esac
    done
    [[ $list ]] && verbose= && soft=y
    for opt; do
        if file=$(file_installed "$opt"); then
            [[ $verbose && $soft ]] && do_print_status "${bold}├${reset} $file" "${green}" "Found"
            if [[ $list ]]; then
                if [[ $ignorebinaries && $file =~ .(exe|com)$ ]]; then
                    continue
                fi
                printf "%s%b" "$file" "$term"
            fi
        else
            [[ $verbose ]] && do_print_status "${bold}├${reset} $file" "${red}" "Not found"
            [[ ! $soft ]] && return 1
        fi
    done
    return 0
}

pc_exists() {
    for opt; do
        local _pkg=${opt%% *}
        local _check=${opt#$_pkg}
        [[ $_pkg == "$_check" ]] && _check=""
        [[ $_pkg == *.pc ]] || _pkg="${LOCALDESTDIR}/lib/pkgconfig/${_pkg}.pc"
        pkg-config --exists --silence-errors "${_pkg}${_check}" || return
    done
}

do_install() {
    [[ $1 == dry ]] && local dryrun=y && shift
    local files=("$@")
    local dest="${files[-1]}"
    [[ ${dest::1} != "/" ]] && dest="$(file_installed "$dest")"
    [[ ${#files[@]} -gt 1 ]] && unset 'files[-1]'
    [[ ${dest: -1:1} == "/" ]] && mkdir -p "$dest"
    if [[ -n $dryrun ]]; then
        echo install -D -p "${files[@]}" "$dest"
    else
        extra_script pre install
        install -D -p "${files[@]}" "$dest"
        extra_script post install
    fi
}

do_uninstall() {
    local dry quiet all files
    [[ $1 == dry ]] && dry=y && shift
    [[ $1 == q ]] && quiet=y && shift
    [[ $1 == all ]] && all=y && shift
    if [[ $all ]]; then
        mapfile -t files < <(files_exist -l "$@")
    else
        mapfile -t files < <(files_exist -l -b "$@")
    fi
    if [[ -n ${files[*]} ]]; then
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
    [[ $pkg == "$pc_check" ]] && pc_check=""
    local version=$2
    local deps=("${_deps[@]}") && unset _deps
    [[ ! $version && $pc_check ]] && version="${pc_check#*= }"
    [[ "$version" ]] && pkg_and_version="${pkg} ${version}"
    if ! pc_exists "${pkg}"; then
        do_print_status "${pkg_and_version}" "$red" "Not installed"
    elif ! pc_exists "${pkg}${pc_check}"; then
        do_print_status "${pkg_and_version}" "$orange" "Outdated"
    elif [[ -n ${deps[*]} ]] && test_newer installed "${deps[@]}" "${pkg}.pc"; then
        do_print_status "${pkg_and_version}" "$orange" "Newer dependencies"
    elif [[ -n ${_check[*]} ]] && ! files_exist "${_check[@]}"; then
        do_print_status "${pkg_and_version}" "$orange" "Files missing"
    else
        do_print_status "${pkg_and_version}" "$green" "Up-to-date"
        return 1
    fi
}

do_readoptionsfile() {
    local filename="$1"
    if [[ -f $filename ]]; then
        sed -r '# remove commented text
                s/#.*//
                # delete empty lines
                /^\s*$/d
                # remove leading whitespace
                s/^\s+//
                # remove trailing whitespace
                s/\s+$//
                ' "$filename" | tr -d '\r' # cut cr out from any crlf files
        echo "Imported options from ${filename##*/}" >&2
    fi
}

do_readbatoptions() {
    local varname="$1"
    # shellcheck disable=SC1117
    printf '%s\n' "${bat[@]}" |
        sed -En "/set ${varname}=/,/[^^]$/p" |
        sed -E "/^:/d;s/(set ${varname}=| \\^|\")//g;s/ /\\n/g" |
        sed -E '/^#/d;/^[^-]/{s/^/--enable-/g}'
}

do_getFFmpegConfig() {
    local license="${1:-nonfree}"

    FFMPEG_DEFAULT_OPTS=()
    if [[ -f "/trunk/media-autobuild_suite.bat" && $ffmpegChoice =~ (n|z|f) ]]; then
        IFS=$'\r\n' read -d '' -r -a bat < /trunk/media-autobuild_suite.bat
        mapfile -t FFMPEG_DEFAULT_OPTS < <(do_readbatoptions "ffmpeg_options_(builtin|basic)")
        local option
        [[ $ffmpegChoice != n ]] && while read -r option; do
            FFMPEG_DEFAULT_OPTS+=("$option")
        done < <(do_readbatoptions "ffmpeg_options_zeranoe")
        [[ $ffmpegChoice == f ]] && while read -r option; do
            FFMPEG_DEFAULT_OPTS+=("$option")
        done < <(do_readbatoptions "ffmpeg_options_full(|_shared)")
        echo "Imported default FFmpeg options from .bat"
    else
        local custom_opts_file="$LOCALBUILDDIR/ffmpeg_options.txt"
        if [[ -f "$LOCALBUILDDIR/ffmpeg_options_$bits.txt" ]]; then
            custom_opts_file="$LOCALBUILDDIR/ffmpeg_options_$bits.txt"
        fi
        IFS=$'\n' read -d '' -r -a FFMPEG_DEFAULT_OPTS < <(do_readoptionsfile "$custom_opts_file")
        unset FFMPEG_DEFAULT_OPTS_SHARED
        if [[ -f "$LOCALBUILDDIR/ffmpeg_options_shared.txt" ]]; then
            IFS=$'\n' read -d '' -r -a FFMPEG_DEFAULT_OPTS_SHARED < <(
                do_readoptionsfile "$LOCALBUILDDIR/ffmpeg_options_shared.txt"
            )
        fi
    fi

    for opt in "${FFMPEG_BASE_OPTS[@]}" "${FFMPEG_DEFAULT_OPTS[@]}"; do
        [[ -n $opt ]] && FFMPEG_OPTS+=("$opt")
    done

    echo "License: $license"

    # we set these accordingly for static or shared
    do_removeOption "--(en|dis)able-(shared|static)"

    # OK to use GnuTLS for rtmpdump if not nonfree since GnuTLS was built for rtmpdump anyway
    # If nonfree will use SChannel if neither openssl/libtls or gnutls are in the options
    if ! enabled_any libtls openssl gnutls &&
        { enabled librtmp || [[ $rtmpdump == y ]]; }; then
        if [[ $license == nonfree ]] ||
            [[ $license == lgpl* && $rtmpdump == n ]]; then
            do_addOption --enable-openssl
        else
            do_addOption --enable-gnutls
        fi
        do_removeOption "--enable-(gmp|gcrypt|mbedtls)"
    fi

    local _all_tls="--enable-(mbedtls|gnutls|openssl|libtls|schannel)"
    if enabled_any libtls openssl && [[ $license != gpl* ]]; then
        # prefer openssl/libtls if both are in options and not gpl

        # prefer openssl over libtls if both enabled
        local _prefer=libtls
        if enabled openssl; then
            _prefer=openssl
        fi

        do_removeOption "${_all_tls}"
        do_addOption "--enable-${_prefer}"
    elif enabled mbedtls; then
        # prefer mbedtls if any other tls libs are enabled and gpl
        do_removeOption "${_all_tls}"
        do_addOption --enable-mbedtls
    elif enabled gnutls; then
        do_removeOption "${_all_tls}"
        do_addOption --enable-gnutls
    elif ! disabled schannel; then
        # fallback to schannel if no other tls libs are enabled
        do_addOption --enable-schannel
    fi

    enabled_any lib{vo-aacenc,aacplus,utvideo,dcadec,faac,ebur128,ndi_newtek,ndi-newtek} netcdf &&
        do_removeOption "--enable-(lib(vo-aacenc|aacplus|utvideo|dcadec|faac|ebur128|ndi_newtek|ndi-newtek)|netcdf)" &&
        sed -ri 's;--enable-(lib(vo-aacenc|aacplus|utvideo|dcadec|faac|ebur128|ndi_newtek|ndi-newtek)|netcdf);;g' \
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
    [[ -f $config_script ]] || do_exit_prompt "There's no configure script to retrieve libs from"
    eval "$(sed -n '/EXTERNAL_LIBRARY_GPL_LIST=/,/^"/p' "$config_script" | tr -s '\n' ' ')"
    eval "$(sed -n '/HWACCEL_LIBRARY_NONFREE_LIST=/,/^"/p' "$config_script" | tr -s '\n' ' ')"
    eval "$(sed -n '/EXTERNAL_LIBRARY_NONFREE_LIST=/,/^"/p' "$config_script" | tr -s '\n' ' ')"
    eval "$(sed -n '/EXTERNAL_LIBRARY_VERSION3_LIST=/,/^"/p' "$config_script" | tr -s '\n' ' ')"

    # handle gpl libs
    local gpl
    read -ra gpl <<< "${EXTERNAL_LIBRARY_GPL_LIST//_/-} gpl"
    if [[ $license == gpl* || $license == nonfree ]] &&
        { enabled_any "${gpl[@]}" || ! disabled postproc; }; then
        do_addOption --enable-gpl
    else
        do_removeOptions "${gpl[*]/#/--enable-} --enable-postproc --enable-gpl"
    fi

    # handle (l)gplv3 libs
    local version3
    read -ra version3 <<< "${EXTERNAL_LIBRARY_VERSION3_LIST//_/-}"
    if [[ $license =~ (l|)gplv3 || $license == nonfree ]] && enabled_any "${version3[@]}"; then
        do_addOption --enable-version3
    else
        do_removeOptions "${version3[*]/#/--enable-} --enable-version3"
    fi

    local nonfreehwaccel
    read -ra nonfreehwaccel <<< "(${HWACCEL_LIBRARY_NONFREE_LIST//_/-}"
    if [[ $license == "nonfree" ]] && enabled_any "${nonfreehwaccel[@]}"; then
        do_addOption --enable-nonfree
    else
        do_removeOptions "${nonfreehwaccel[*]/#/--enable-} --enable-nonfree"
    fi

    # cuda-only workarounds
    if verify_cuda_deps; then
        if enabled libnpp; then
            echo -e "${orange}FFmpeg and related apps will depend on CUDA SDK to run!${reset}"
            local fixed_CUDA_PATH
            fixed_CUDA_PATH="$(cygpath -sm "$CUDA_PATH")"
            do_addOption "--extra-cflags=-I$fixed_CUDA_PATH/include"
            do_addOption "--extra-ldflags=-L$fixed_CUDA_PATH/lib/x64"
        fi
        if enabled cuda-nvcc; then
            local fixed_CUDA_PATH_UNIX
            fixed_CUDA_PATH_UNIX="$(cygpath -u "$CUDA_PATH")"
            command -v nvcc.exe &> /dev/null || export PATH="$PATH:$fixed_CUDA_PATH_UNIX/bin"
            echo -e "${orange}FFmpeg and related apps will depend on Nvidia drivers!${reset}"
        fi
    else
        do_removeOption "--enable-(libnpp|cuda-nvcc)"
    fi

    # handle gpl-incompatible libs
    local nonfreegpl
    read -ra nonfreegpl <<< "${EXTERNAL_LIBRARY_NONFREE_LIST//_/-}"
    if enabled_any "${nonfreegpl[@]}"; then
        if [[ $license == "nonfree" ]] && enabled gpl; then
            do_addOption --enable-nonfree
        elif [[ $license == gpl* ]]; then
            do_removeOptions "${nonfreegpl[*]/#/--enable-}"
        fi
        # no lgpl here because they are accepted with it
    fi

    if ! disabled debug "debug=gdb"; then
        # fix issue with ffprobe not working with debug and strip
        do_addOption --disable-stripping
    fi

    # both openssl and mbedtls don't need gcrypt/gmp for rtmpe
    enabled_any openssl mbedtls && do_removeOption "--enable-(gcrypt|gmp)"

    # remove libs that don't work with shared
    if [[ $ffmpeg =~ "shared" || $ffmpeg =~ "both" ]]; then
        FFMPEG_OPTS_SHARED=()
        for opt in "${FFMPEG_OPTS[@]}" "${FFMPEG_DEFAULT_OPTS_SHARED[@]}"; do
            [[ -n $opt ]] && FFMPEG_OPTS_SHARED+=("$opt")
        done
    fi
    if [[ $ffmpeg == "bothstatic" ]]; then
        do_removeOption "--enable-(opencl|opengl|cuda-nvcc|libnpp|libopenh264)"
    fi
}

opt_exists() {
    local array="${1}[@]" && shift 1
    local opt value
    for opt; do
        for value in "${!array}"; do
            [[ $value =~ $opt ]] && return
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
    local MPV_TEMP_OPTS=()
    MPV_OPTS=()
    if [[ -f "/trunk/media-autobuild_suite.bat" && $ffmpegChoice =~ (n|z|f) ]]; then
        IFS=$'\r\n' read -d '' -r -a bat < /trunk/media-autobuild_suite.bat
        mapfile -t MPV_TEMP_OPTS < <(do_readbatoptions "mpv_options_(builtin|basic)")
        local option
        [[ $ffmpegChoice == f ]] && while read -r option; do
            [[ -n $option ]] && MPV_TEMP_OPTS+=("$option")
        done < <(do_readbatoptions "mpv_options_full")
        echo "Imported default mpv options from .bat"
    else
        IFS=$'\n' read -d '' -r -a MPV_TEMP_OPTS < <(do_readoptionsfile "$LOCALBUILDDIR/mpv_options.txt")
    fi
    do_removeOption MPV_TEMP_OPTS \
        "--(en|dis)able-(vapoursynth-lazy|libguess|static-build|enable-gpl3|egl-angle-lib|encoding|crossc)"
    for opt in "${MPV_TEMP_OPTS[@]}"; do
        [[ -n $opt ]] && MPV_OPTS+=("$opt")
    done
}

mpv_enabled() {
    local option
    [[ $mpv == n ]] && return 1
    for option in "${MPV_OPTS[@]}"; do
        [[ $option =~ "--enable-$1"$ ]] && return
    done
    return 1
}

mpv_disabled() {
    local option
    [[ $mpv == n ]] && return 0
    for option in "${MPV_OPTS[@]}"; do
        [[ $option =~ "--disable-$1"$ ]] && return
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
        mpv_enabled "$opt" || return 1
    done
}

mpv_disabled_all() {
    local opt
    for opt; do
        mpv_disabled "$opt" || return 1
    done
}

mpv_enable() {
    local opt newopts=()
    for opt in "${MPV_OPTS[@]}"; do
        if [[ $opt =~ "--disable-$1"$ ]]; then
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
        if [[ $opt =~ "--enable-$1"$ ]]; then
            newopts+=("--disable-$1")
        else
            newopts+=("$opt")
        fi
    done
    MPV_OPTS=("${newopts[@]}")
}

do_addOption() {
    local varname="$1" array opt
    if [[ ${varname#--} == "$varname" ]]; then
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
    if [[ ${varname#--} == "$varname" ]]; then
        arrayname="$varname" && shift 1
    else
        arrayname="FFMPEG_OPTS"
    fi

    local option="$1"
    local basearray temp=()
    basearray="${arrayname}[@]"
    local orig=("${!basearray}")

    for ((i = 0; i < ${#orig[@]}; i++)); do
        if [[ ! ${orig[$i]} =~ ^${option}$ ]]; then
            temp+=("${orig[$i]}")
        fi
    done
    # shellcheck disable=SC1117,SC1083
    eval "$arrayname"=\(\"\${temp[@]}\"\)
}

do_removeOptions() {
    local option
    local shared=$2
    for option in $1; do
        do_removeOption "$option" "$shared"
    done
}

do_patch() {
    local binarypatch="--binary"
    case $1 in -p) binarypatch="" && shift;; esac
    local patch=${1%% *} # Location or link to patch.
    local am=$2          # Use git am to apply patch. Use with .patch files
    local strip=${3:-1}  # Leading directories to strip. "patch -p${strip}"
    local patchName="${1##* }" # Basename of file. (test-diff-files.diff)
    [[ $patchName == "$patch" ]] && patchName="${patch##*/}"

    if [[ -z $patchName ]]; then
        # hack for URLs without filename
        patchName="$(/usr/bin/curl -sI "$patch" | grep -Pio '(?<=filename=)(.+)')"
        if [[ -z $patchName ]]; then
            echo -e "${red}Failed to apply patch '$patch'${reset}"
            echo -e "${red}Patch without filename, ignoring. Specify an explicit filename.${reset}"
            return 1
        fi
    fi

    # Just don't. Make a fork or use the suite's directory as the root for
    # your diffs or manually edit the scripts if you are trying to modify
    # the helper and compile scripts. If you really need to, use patch instead.
    # Else create a patch file for the individual folders you want to apply
    # the patch to.
    [[ $PWD == "$LOCALBUILDDIR" ]] &&
        do_exit_prompt "Running patches in the build folder is not supported.
        Please make a patch for individual folders or modify the script directly"

    if [[ ${patch:0:4} == "http" ]] || [[ ${patch:0:3} == "ftp" ]]; then
        # Filter out patches that would require curl
        do_wget -c -r -q "$patch" "$patchName"
    elif [[ -f $patch ]]; then
        # Check if the patch is a local patch and copy it to the current dir
        patch="$(realpath "$patch")" # Resolve fullpatch
        [[ ${patch%/*} != "$PWD" ]] &&
            cp -f "$patch" "$patchName" > /dev/null 2>&1
    else
        # Fall through option if the patch is from some other protocol
        # I don't know why anyone would use this but just in case.
        do_wget -c -r -q "$patch" "$patchName"
    fi

    if [[ -f $patchName ]]; then
        if [[ $am == "am" ]]; then
            if ! git am -q --ignore-whitespace --no-gpg-sign "$patchName" > /dev/null 2>&1; then
                git am -q --abort
                echo -e "${orange}${patchName}${reset}"
                echo -e "\\tPatch couldn't be applied with 'git am'. Continuing without patching."
                return 1
            fi
        else
            if patch --dry-run $binarypatch -s -N -p"$strip" -i "$patchName" > /dev/null 2>&1; then
                patch $binarypatch -s -N -p"$strip" -i "$patchName"
            else
                echo -e "${orange}${patchName}${reset}"
                echo -e "\\tPatch couldn't be applied with 'patch'. Continuing without patching."
                return 1
            fi
        fi
    else
        echo -e "${orange}${patchName}${reset}"
        echo -e "\\tPatch not found anywhere. Continuing without patching."
        return 1
    fi
    return 0
}

do_custom_patches() {
    local patch
    for patch in "$@"; do
        [[ ${patch##*.} == "patch" ]] && do_patch "$patch" am
        [[ ${patch##*.} == "diff" ]] && do_patch "$patch"
    done
}

do_cmake() {
    local bindir=""
    local root=".."
    local cmake_build_dir=""
    while [[ -n $* ]]; do
        case "$1" in
        global | audio | video)
            bindir="-DCMAKE_INSTALL_BINDIR=$LOCALDESTDIR/bin-$1"
            shift
            ;;
        builddir=*)
            cmake_build_dir="${1#*=}"
            shift
            ;;
        skip_build_dir)
            local skip_build_dir=y
            shift
            ;;
        *)
            if [[ -d "./$1" ]]; then
                [[ -n $skip_build_dir ]] && root="./$1" || root="../$1"
                shift
            fi
            break
            ;;
        esac
    done

    local PKG_CONFIG="$LOCALDESTDIR/bin/ab-pkg-config-static.bat"
    [[ -z $skip_build_dir ]] && create_build_dir "$cmake_build_dir"
    extra_script pre cmake
    [[ -f "$(get_first_subdir)/do_not_reconfigure" ]] &&
        return
    # shellcheck disable=SC2086
    log "cmake" cmake "$root" -G Ninja -DBUILD_SHARED_LIBS=off \
        -DCMAKE_TOOLCHAIN_FILE="$LOCALDESTDIR/etc/toolchain.cmake" \
        -DCMAKE_INSTALL_PREFIX="$LOCALDESTDIR" -DUNIX=on \
        -DCMAKE_BUILD_TYPE=Release $bindir "${cmake_extras[@]}" "$@"
    extra_script post cmake
    unset cmake_extras
}

do_ninja(){
    extra_script pre ninja
    log "build" ninja "$@"
    extra_script post ninja
}

do_ninjainstall(){
    extra_script pre install
    cpuCount=1 log "install" ninja install "$@"
    extra_script post install
}

do_cmakeinstall() {
    do_cmake "$@"
    do_ninja
    do_ninjainstall
}

do_meson() {
    local bindir=""
    local root=".."
    case "$1" in
    global | audio | video)
        bindir="--bindir=bin-$1"
        ;;
    *)
        [[ -d "./$1" ]] && root="../$1" || bindir="$1"
        ;;
    esac
    shift 1

    create_build_dir
    extra_script pre meson
    # shellcheck disable=SC2086
    PKG_CONFIG=pkg-config CC=gcc CXX=g++ \
        log "meson" meson "$root" --default-library=static --buildtype=release \
        --prefix="$LOCALDESTDIR" --backend=ninja $bindir "$@"
    extra_script post meson
}

do_mesoninstall() {
    do_meson "$@"
    do_ninja
    do_ninjainstall
}

compilation_fail() {
    [[ -z $build32 || -z $build64 ]] && return 1
    local reason="$1"
    local operation
    operation="$(echo "$reason" | tr '[:upper:]' '[:lower:]')"
    if [[ $_notrequired ]]; then
        if [[ $logging == y ]]; then
            echo "Likely error:"
            tail "ab-suite.${operation}.log"
            echo "${red}$reason failed. Check $(pwd -W)/ab-suite.$operation.log${reset}"
        fi
        echo "This isn't required for anything so we can move on."
        return 1
    else
        if [[ $noMintty == y ]]; then
            diff --changed-group-format='%>' --unchanged-group-format='' "$LOCALBUILDDIR/old.var" <(declare -p | grep -vE "BASH|LINES|COLUMNS|CommonProgramFiles") > "$LOCALBUILDDIR/fail.var"
            printf '%s\n%s\n%s\n' "$PWD" "$reasons" "$operation" > "$LOCALBUILDDIR/compilation_failed"
            exit
        else
            if [[ $logging == y ]]; then
                echo "Likely error:"
                tail "ab-suite.${operation}.log"
                echo "${red}$reason failed. Check $(pwd -W)/ab-suite.$operation.log${reset}"
            fi
            echo "${red}This is required for other packages, so this script will exit.${reset}"
            create_diagnostic
            zip_logs
            echo "Make sure the suite is up-to-date before reporting an issue. It might've been fixed already."
            do_prompt "Try running the build again at a later time."
            exit 1
        fi
    fi
}

strip_ansi() {
    local txtfile newfile
    for txtfile; do
        [[ $txtfile != "${txtfile//stripped/}" ]] && continue
        local name="${txtfile%.*}"
        local ext="${txtfile##*.}"
        [[ $txtfile != "$name" ]] && newfile="${name}.stripped.${ext}" || newfile="${txtfile}-stripped"
        sed -r 's#(\x1B[\[\(]([0-9][0-9]?)?[mBHJ]|\x07|\x1B]0;)##g;s/^[0-9]{2}:[0-9]{2}:[0-9]{2}//' "$txtfile" > "${newfile}"
    done
}

zip_logs() {
    local failed url files
    failed="$(get_first_subdir)"
    pushd "$LOCALBUILDDIR" > /dev/null || do_exit_prompt "Did you delete /build?"
    rm -f logs.zip
    strip_ansi ./*.log
    files=(/trunk/media-autobuild_suite.bat)
    local option
    [[ $failed ]] && mapfile -t -O "${#files[@]}" files < <(
        find "$failed" -name "*.log"
    )
    mapfile -t -O "${#files[@]}" files < <(
        find . -maxdepth 1 -name "*.stripped.log" -o -name "*_options.txt" -o -name "media-suite_*.sh" \
            -o -name "last_run" -o -name "media-autobuild_suite.ini" -o -name "diagnostics.txt" -o -name "patchedFolders"
    )
    7za -mx=9 a logs.zip "${files[@]}" > /dev/null
    [[ ! -f "$LOCALBUILDDIR/no_logs" ]] && [[ -n "$build32$build64" ]] &&
        url="$(/usr/bin/curl -sF'file=@logs.zip' https://0x0.st)"
    popd > /dev/null || do_exit_prompt "Did you delete the previous folder?"
    echo
    if [[ $url ]]; then
        echo "${green}All relevant logs have been anonymously uploaded to $url"
        echo "${green}Copy and paste ${red}[logs.zip]($url)${green} in the GitHub issue.${reset}"
    elif [[ -f "$LOCALBUILDDIR/logs.zip" ]]; then
        echo "${green}Attach $(cygpath -w "$LOCALBUILDDIR/logs.zip") to the GitHub issue.${reset}"
    fi
}

log() {
    [[ $1 == quiet ]] && local quiet=y && shift
    local name="${1// /.}"
    local _cmd="$2"
    shift 2
    local extra
    [[ $quiet ]] || do_print_progress Running "$name"
    [[ $_cmd =~ ^(make|ninja)$ ]] && extra="-j$cpuCount"
    if [[ $logging == "y" ]]; then
        printf 'CFLAGS: %s\nLDFLAGS: %s\n%s %s\n' "$CFLAGS" "$LDFLAGS" "$_cmd" "$*" > "ab-suite.$name.log"
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
    if [[ ! -f "$(get_first_subdir)/do_not_clean" ]]; then
        if [[ "$(basename "$(pwd)")" == "$build_dir" ]]; then
            rm -rf ./* && cd_safe ".."
        elif [[ -d $build_dir ]] && ! rm -rf ./"$build_dir"; then
            cd_safe "$build_dir" && rm -rf ./* && cd_safe ".."
        fi
    fi
    [[ ! -d $build_dir ]] && mkdir "$build_dir"
    cd_safe "$build_dir"
}

get_external_opts() {
    local array="$1"
    local pkgname
    pkgname="$(get_first_subdir)"
    local optsfile="$LOCALBUILDDIR/${pkgname%-*}_options.txt"
    if [[ -n $array ]]; then
        # shellcheck disable=SC2034
        IFS=$'\n' read -d '' -r -a tmp < <(do_readoptionsfile "$optsfile")
        declare -ag "$array+=(\"\${tmp[@]}\")"
    else
        do_readoptionsfile "$optsfile"
    fi
}

do_separate_conf() {
    local bindir=""
    local last config_path
    case "$1" in
    global | audio | video)
        bindir="--bindir=$LOCALDESTDIR/bin-$1"
        ;;
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
    do_configure --{build,host,target}="$MINGW_CHOST" --prefix="$LOCALDESTDIR" --disable-shared --enable-static "$bindir" "$@"
}

do_separate_confmakeinstall() {
    do_separate_conf "$@"
    do_make
    do_makeinstall
    cd_safe ..
}

do_configure() {
    extra_script pre configure
    [[ -f "$(get_first_subdir)/do_not_reconfigure" ]] &&
        return
    log "configure" ${config_path:-.}/configure "$@"
    extra_script post configure
}

do_make() {
    extra_script pre make
    log "make" make "$@"
    extra_script post make
}

do_makeinstall() {
    extra_script pre install
    log "install" make install "$@"
    extra_script post install
}

do_hide_pacman_sharedlibs() {
    local packages="$1"
    local revert="$2"
    local files
    files="$(pacman -Qql "$packages" 2> /dev/null | /usr/bin/grep .dll.a)"

    for file in $files; do
        if [[ -f "${file%*.dll.a}.a" ]]; then
            if [[ -z $revert ]]; then
                mv -f "${file}" "${file}.dyn"
            elif [[ -n $revert && -f "${file}.dyn" && ! -f ${file} ]]; then
                mv -f "${file}.dyn" "${file}"
            elif [[ -n $revert && -f "${file}.dyn" ]]; then
                rm -f "${file}.dyn"
            fi
        fi
    done
}

do_hide_all_sharedlibs() {
    local dryrun="${dry:-n}"
    local files
    files="$(find /mingw{32,64}/lib /mingw{32/i686,64/x86_64}-w64-mingw32/lib -name "*.dll.a" 2> /dev/null)"
    local tomove=()
    for file in $files; do
        [[ -f "${file%*.dll.a}.a" ]] && tomove+=("$file")
    done
    if [[ $dryrun == "n" ]]; then
        printf '%s\n' "${tomove[@]}" | xargs -ri mv -f '{}' '{}.dyn'
    else
        printf '%s\n' "${tomove[@]}"
    fi
}

do_unhide_all_sharedlibs() {
    local dryrun="${dry:-n}"
    local files
    files="$(find /mingw{32,64}/lib /mingw{32/i686,64/x86_64}-w64-mingw32/lib -name "*.dll.a.dyn" 2> /dev/null)"
    local tomove=()
    local todelete=()
    for file in $files; do
        if [[ -f ${file%*.dyn} ]]; then
            todelete+=("$file")
        else
            tomove+=("${file%*.dyn}")
        fi
    done
    if [[ $dryrun == "n" ]]; then
        printf '%s\n' "${todelete[@]}" | xargs -ri rm -f '{}'
        printf '%s\n' "${tomove[@]}" | xargs -ri mv -f '{}.dyn' '{}'
    else
        printf 'rm %s\n' "${todelete[@]}"
        printf '%s\n' "${tomove[@]}"
    fi
}

do_pacman_install() {
    local pkg msyspackage
    while [ -n "$*" ]; do
        case "$1" in
        -m) msyspackage=y ;;
        *) break ;;
        esac
    done
    for pkg; do
        [[ $msyspackage != "y" && $pkg != "${MINGW_PACKAGE_PREFIX}-"* ]] &&
            pkg="${MINGW_PACKAGE_PREFIX}-${pkg}"
        pacman -Qqe "^${pkg}$" > /dev/null 2>&1 && continue
        if [[ $timeStamp == y ]]; then
            printf "${purple}"'%(%H:%M:%S)T'"${reset}"' %s' -1 "Installing ${pkg#$MINGW_PACKAGE_PREFIX-}... "
        else
            echo -n "Installing ${pkg#$MINGW_PACKAGE_PREFIX-}... "
        fi
        if pacman -S --overwrite "/usr/*" --overwrite "/mingw64/*" --overwrite "/mingw32/*" --noconfirm --ask=20 --needed "$pkg" > /dev/null 2>&1; then
            pacman -D --asexplicit "$pkg" > /dev/null
            if [[ $msyspackage == "y" ]]; then
                /usr/bin/grep -q "^${pkg}$" /etc/pac-msys-extra.pk > /dev/null 2>&1 ||
                    echo "${pkg}" >> /etc/pac-msys-extra.pk
            else
                /usr/bin/grep -q "^${pkg#$MINGW_PACKAGE_PREFIX-}$" /etc/pac-mingw-extra.pk > /dev/null 2>&1 ||
                    echo "${pkg#$MINGW_PACKAGE_PREFIX-}" >> /etc/pac-mingw-extra.pk
            fi
            sort -uo /etc/pac-mingw-extra.pk{,} 2> /dev/null >&2
            sort -uo /etc/pac-msys-extra.pk{,} 2> /dev/null >&2
            echo "done"
        else
            echo "failed"
        fi
    done
    do_hide_all_sharedlibs
}

do_pacman_remove() {
    local pkg msyspackage
    while [ -n "$*" ]; do
        case "$1" in
        -m) msyspackage=y ;;
        *) break ;;
        esac
    done
    for pkg; do
        [[ $msyspackage != "y" && $pkg != "${MINGW_PACKAGE_PREFIX}-"* ]] &&
            pkg="${MINGW_PACKAGE_PREFIX}-${pkg}"
        if [[ $msyspackage == "y" ]]; then
            [[ -f /etc/pac-msys-extra.pk ]] &&
                sed -i "/^${pkg}$/d" /etc/pac-msys-extra.pk > /dev/null 2>&1
        else
            [[ -f /etc/pac-mingw-extra.pk ]] &&
                sed -i "/^${pkg#$MINGW_PACKAGE_PREFIX-}$/d" /etc/pac-mingw-extra.pk > /dev/null 2>&1
        fi
        sort -uo /etc/pac-mingw-extra.pk{,} 2> /dev/null >&2
        sort -uo /etc/pac-msys-extra.pk{,} 2> /dev/null >&2
        pacman -Qqe "^${pkg}$" > /dev/null 2>&1 || continue
        if [[ $timeStamp == y ]]; then
            printf "${purple}"'%(%H:%M:%S)T'"${reset}"' %s' -1 "Uninstalling ${pkg#$MINGW_PACKAGE_PREFIX-}... "
        else
            echo -n "Uninstalling ${pkg#$MINGW_PACKAGE_PREFIX-}... "
        fi
        do_hide_pacman_sharedlibs "$pkg" revert
        if pacman -Rs --noconfirm --ask=20 "$pkg" > /dev/null 2>&1; then
            echo "done"
        else
            pacman -D --asdeps "$pkg" > /dev/null 2>&1
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
        extra_script pre autoreconf
        log "autoreconf" autoreconf -fiv "$@"
        extra_script post autoreconf
    fi
}

do_autogen() {
    local basedir="$LOCALBUILDDIR"
    basedir+="/$(get_first_subdir)" || basedir="."
    if { [[ -f "$basedir"/recently_updated &&
        -z "$(ls "$basedir"/build_successful* 2> /dev/null)" ]]; } ||
        [[ ! -f configure ]]; then
        safe_git_clean -q
        extra_script pre autogen
        log "autogen" ./autogen.sh "$@"
        extra_script post autogen
    fi
}

get_first_subdir() {
    local subdir="${PWD#*build/}"
    if [[ $subdir != "$PWD" ]]; then
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
    ret="$(/usr/bin/grep -E "$filter" <<< "$filelist" | sort -V | tail -1)"
    [[ -n $version ]] && ret="$(/usr/bin/grep -oP "$version" <<< "$ret")"
    echo "$ret"
}

create_debug_link() {
    for file; do
        if [[ -f $file && ! -f "$file".debug ]]; then
            echo "Stripping and creating debug link for ${file##*/}..."
            objcopy --only-keep-debug "$file" "$file".debug
            if [[ ${file: -3} == "dll" ]]; then
                strip --strip-debug "$file"
            else
                strip --strip-all "$file"
            fi
            objcopy --add-gnu-debuglink="$file".debug "$file"
        fi
    done
}

get_vs_prefix() {
    unset vsprefix
    local winvsprefix
    local regkey="/HKLM/software/vapoursynth/path"
    local embedded
    embedded="$(find "$LOCALDESTDIR"/bin-video -iname vspipe.exe)"
    if [[ -n $embedded ]]; then
        # look for .dlls in bin-video
        vsprefix="${embedded%/*}"
    elif [[ $bits == 64bit ]] && winvsprefix="$(regtool -q get "$regkey")"; then
        # check in native HKLM for installed VS (R31+)
        [[ -n $winvsprefix && -f "$winvsprefix/core64/vspipe.exe" ]] &&
            vsprefix="$(cygpath -u "$winvsprefix")/core64"
    elif winvsprefix="$(regtool -qW get "$regkey")"; then
        # check in 32-bit registry for installed VS
        [[ -n $winvsprefix && -f "$winvsprefix/core${bits%bit}/vspipe.exe" ]] &&
            vsprefix="$(cygpath -u "$winvsprefix/core${bits%bit}")"
    elif [[ -n $(command -v vspipe.exe 2> /dev/null) ]]; then
        # last resort, check if vspipe is in path
        vsprefix="$(dirname "$(command -v vspipe.exe)")"
    fi
    if [[ -n $vsprefix && -f "$vsprefix/vapoursynth.dll" && -f "$vsprefix/vsscript.dll" ]]; then
        local bitness
        bitness="$(file "$vsprefix/vapoursynth.dll")"
        { [[ $bits == 64bit && $bitness == *x86-64* ]] ||
            [[ $bits == 32bit && $bitness == *80386* ]]; } &&
            return 0
    else
        return 1
    fi
}

get_cl_path() {
    command -v cl.exe &> /dev/null && return 0

    local _sys_vswhere
    local _suite_vswhere="/opt/bin/vswhere.exe"
    _sys_vswhere="$(cygpath -u "$(cygpath -F 0x002a)/Microsoft Visual Studio/Installer/vswhere.exe")"
    if [[ -f $_sys_vswhere ]]; then
        vswhere=$_sys_vswhere
    elif [[ -f $_suite_vswhere ]]; then
        vswhere=$_suite_vswhere
    else
        pushd "$LOCALBUILDDIR" 2> /dev/null || do_exit_prompt "Did you delete /build?"
        do_wget -c -r -q "https://github.com/Microsoft/vswhere/releases/latest/download/vswhere.exe"
        [[ -f vswhere.exe ]] || return 1
        do_install vswhere.exe /opt/bin/
        vswhere=$_suite_vswhere
        popd 2> /dev/null || do_exit_prompt "Did you delete the previous folder?"
    fi

    local installationpath
    installationpath="$("$vswhere" -latest -property installationPath | tail -n1)"
    [[ -z $installationpath ]] && return 1
    # apparently this is MS's official way of knowing the default version ???
    local _version
    _version="$(cat "$installationpath/VC/Auxiliary/Build/Microsoft.VCToolsVersion.default.txt")"
    local _hostbits=HostX64
    [[ "$(uname -m)" != x86_64 ]] && _hostbits=HostX86
    local _arch=x64
    [[ $bits == 32bit ]] && _arch=x86

    local basepath
    basepath="$(cygpath -u "$installationpath/VC/Tools/MSVC/$_version/bin/$_hostbits/$_arch")"
    if [[ -f "$basepath/cl.exe" ]]; then
        export PATH="$basepath:$PATH"
    else
        return 1
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
    [[ ! -f $header ]] && printf '' && return
    /usr/bin/grep "${line:-VERSION}" "$header" | awk '{ print $c }' c="${column:-3}" | sed 's|"||g'
}

hide_files() {
    local reverse=n echo_cmd
    [[ $1 == "-R" ]] && reverse=y && shift
    [[ $dryrun == y ]] && echo_cmd="echo"
    for opt; do
        if [[ $reverse == n ]]; then
            [[ -f $opt ]] && $echo_cmd mv -f "$opt" "$opt.bak"
        else
            [[ -f "$opt.bak" ]] && $echo_cmd mv -f "$opt.bak" "$opt"
        fi
    done
}

hide_conflicting_libs() {
    # meant for rude build systems
    local reverse=n
    [[ $1 == "-R" ]] && reverse=y && shift
    local priority_prefix
    local -a installed
    mapfile -t installed < <(find "$LOCALDESTDIR/lib" -maxdepth 1 -name "*.a")
    if [[ $reverse == n ]]; then
        hide_files "${installed[@]//$LOCALDESTDIR/$MINGW_PREFIX}"
    else
        hide_files -R "${installed[@]//$LOCALDESTDIR/$MINGW_PREFIX}"
    fi
    if [[ -n $1 ]]; then
        priority_prefix="$1"
        mapfile -t installed < <(find "$priority_prefix/lib" -maxdepth 1 -name "*.a")
        if [[ $reverse == n ]]; then
            hide_files "${installed[@]//$1/$LOCALDESTDIR}"
        else
            hide_files -R "${installed[@]//$1/$LOCALDESTDIR}"
        fi
    fi
}

hide_libressl() {
    local _hide_files=(include/openssl
        lib/lib{crypto,ssl,tls}.{,l}a
        lib/pkgconfig/openssl.pc
        lib/pkgconfig/lib{crypto,ssl,tls}.pc)
    local reverse=n
    local _f
    [[ $1 == "-R" ]] && reverse=y && shift
    for _f in ${_hide_files[*]}; do
        _f="$LOCALDESTDIR/$_f"
        if [[ $reverse == n ]]; then
            [[ -e $_f ]] && mv -f "$_f" "$_f.bak"
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
    if [[ $timeStamp == y ]]; then
        printf "\\n${purple}%(%H:%M:%S)T${reset} %s\\n" -1 "${orange}Deleting status files...${reset}"
    else
        echo -e "\\n\\t${orange}Deleting status files...${reset}"
    fi
    cd_safe "$LOCALBUILDDIR" > /dev/null
    find . -maxdepth 2 \( -name recently_updated -o -name recently_checked \) -delete
    find . -maxdepth 2 -regex ".*build_successful\(32\|64\)bit\(_\\w+\)?\$" -delete
    echo -e "\\n\\t${green}Zipping man files...${reset}"
    do_zipman

    if [[ $deleteSource == y ]]; then
        echo -e "\\t${orange}Deleting temporary build dirs...${reset}"
        find . -maxdepth 5 -name "ab-suite.*.log" -delete
        find . -maxdepth 5 -type d -name "build-*bit" -exec rm -rf {} +
        find . -maxdepth 2 -type d -name "build" -exec test -f "{}/CMakeCache.txt" ';' -exec rm -rf {} ';'

        if [[ -f _to_remove ]]; then
            echo -e "\\n\\t${orange}Deleting source folders...${reset}"
            grep -E "^($LOCALBUILDDIR|/trunk$LOCALBUILDDIR)" < _to_remove |
                grep -Ev "^$LOCALBUILDDIR/(patches|extras|$)" | sort -u | xargs -r rm -rf
        fi
        if [[ $(du -s /var/cache/pacman/pkg/ | awk '{print $1}') -gt 1000000 ]]; then
            echo -e "\\t${orange}Deleting unneeded Pacman packages...${reset}"
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
    echo "Env variables:" >> "$LOCALBUILDDIR/diagnostics.txt"
    for _env in "${envs[@]}"; do
        printf '\t%s=%s\n' "$_env" "${!_env}" >> "$LOCALBUILDDIR/diagnostics.txt"
    done
    echo >> "$LOCALBUILDDIR/diagnostics.txt"
    for cmd in "${cmds[@]}"; do
        printf '\t%s\n%s\n\n' "$cmd" "$($cmd)" >> "$LOCALBUILDDIR/diagnostics.txt"
    done
}

create_winpty_exe() {
    local exename="$1"
    local installdir="$2"
    shift 2
    [[ -f "${installdir}/${exename}".exe ]] && mv "${installdir}/${exename}"{.,_}exe
    # shellcheck disable=SC2016
    printf '%s\n' "#!/usr/bin/env bash" "$@" \
        'if [[ -t 1 ]]; then' \
        '/usr/bin/winpty "$( dirname ${BASH_SOURCE[0]} )/'"${exename}"'.exe" "$@"' \
        'else "$( dirname ${BASH_SOURCE[0]} )/'"${exename}"'.exe" "$@"; fi' \
        > "${installdir}/${exename}"
    [[ -f "${installdir}/${exename}"_exe ]] && mv "${installdir}/${exename}"{_,.}exe
}

create_ab_pkgconfig() {
    # from https://stackoverflow.com/a/8088167
    local script_file
    IFS=$'\n' read -r -d '' script_file <<'EOF' || true
#!/bin/sh

while true; do
case $1 in
    --libs|--libs-*) libs_args+=" $1"; shift ;;
    --static) static="--static"; shift ;;
    --* ) base_args+=" $1"; shift ;;
    * ) break ;;
esac
done

[[ -n $PKGCONF_STATIC ]] && static="--static"

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
        diff -q <(printf '%s' "$script_file") "$LOCALDESTDIR"/bin/ab-pkg-config > /dev/null ||
        printf '%s' "$script_file" > "$LOCALDESTDIR"/bin/ab-pkg-config
    [[ -f "$LOCALDESTDIR"/bin/ab-pkg-config.bat ]] ||
        printf '%s\r\n' "@echo off" "" "bash $LOCALDESTDIR/bin/ab-pkg-config %*" > "$LOCALDESTDIR"/bin/ab-pkg-config.bat
    [[ -f "$LOCALDESTDIR"/bin/ab-pkg-config-static.bat ]] ||
        printf '%s\r\n' "@echo off" "" "bash $LOCALDESTDIR/bin/ab-pkg-config --static %*" > "$LOCALDESTDIR"/bin/ab-pkg-config-static.bat
}

create_cmake_toolchain() {
    local _win_path_LOCALDESTDIR _win_path_MINGW_PREFIX
    _win_path_LOCALDESTDIR="$(cygpath -m "$LOCALDESTDIR")"
    _win_path_MINGW_PREFIX="$(cygpath -m "$MINGW_PREFIX")"
    local toolchain_file=(
        "SET(CMAKE_RC_COMPILER_INIT windres)"
        ""
        "LIST(APPEND CMAKE_PROGRAM_PATH $_win_path_LOCALDESTDIR/bin)"
        "SET(CMAKE_FIND_ROOT_PATH $_win_path_LOCALDESTDIR $_win_path_MINGW_PREFIX $_win_path_MINGW_PREFIX/$MINGW_CHOST)"
        "SET(CMAKE_PREFIX_PATH $_win_path_LOCALDESTDIR $_win_path_MINGW_PREFIX $_win_path_MINGW_PREFIX/$MINGW_CHOST)"
        "SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)"
        "SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)"
    )

    [[ -f "$LOCALDESTDIR"/etc/toolchain.cmake ]] &&
        diff -q <(printf '%s\n' "${toolchain_file[@]}") "$LOCALDESTDIR"/etc/toolchain.cmake > /dev/null ||
        printf '%s\n' "${toolchain_file[@]}" > "$LOCALDESTDIR"/etc/toolchain.cmake
}

grep_or_sed() {
    local grep_re="$1"
    local grep_file="$2"
    [[ ! -f $grep_file ]] && return
    local sed_re="$3"
    shift 3
    local sed_files=("$grep_file")
    [[ -n $1 ]] && sed_files=("$@")

    /usr/bin/grep -q -- "$grep_re" "$grep_file" ||
        /usr/bin/sed -ri -- "$sed_re" "${sed_files[@]}"
}

compare_with_zeranoe() {
    local comparison="${1:-builtin}"
    local zeranoebase="https://ffmpeg.zeranoe.com/builds/readme"
    local zeranoe32 zeranoe64
    zeranoe32="$(curl -s "${zeranoebase}"/win32/static/ffmpeg-latest-win32-static-readme.txt |
        sed -n '/Configuration/,/Libraries/{/\s*--/{s/\s*//gp}}' | sort)"
    zeranoe64="$(curl -s "${zeranoebase}"/win64/static/ffmpeg-latest-win64-static-readme.txt |
        sed -n '/Configuration/,/Libraries/{/\s*--/{s/\s*//gp}}' | sort)"
    local localopts32=""
    local localopts64=""
    if [[ $comparison == "custom" ]]; then
        local custom32="$LOCALBUILDDIR/ffmpeg_options_32bit.txt"
        local custom64="$LOCALBUILDDIR/ffmpeg_options_64bit.txt"
        local custom="$LOCALBUILDDIR/ffmpeg_options.txt"
        [[ -f $custom32 ]] || custom32="$custom"
        [[ -f $custom64 ]] || custom64="$custom"
        if [[ -f $custom32 ]]; then
            IFS=$'\n' read -d '' -r -a localopts32 < <(do_readoptionsfile "$custom32")
        fi
        if [[ -f $custom64 ]]; then
            IFS=$'\n' read -d '' -r -a localopts64 < <(do_readoptionsfile "$custom64")
        fi
    else
        IFS=$'\r\n' read -d '' -r -a bat < /trunk/media-autobuild_suite.bat
        localopts32="$(do_readbatoptions "ffmpeg_options_(builtin|basic|zeranoe)" | sort)"
        localopts64="$localopts32"
    fi
    echo "Missing options from zeranoe 32-bits in $comparison options:"
    comm -23 <(echo "$zeranoe32") <(echo "$localopts32")
    printf '\n'
    echo "Missing options from zeranoe 64-bits in $comparison options:"
    comm -23 <(echo "$zeranoe64") <(echo "$localopts64")
    printf '\n'
}

do_rust() {
    log "update" "$RUSTUP_HOME/bin/cargo.exe" update
    extra_script pre rust
    log "build" "$RUSTUP_HOME/bin/cargo.exe" build --release \
        --target="$CARCH"-pc-windows-gnu \
        --jobs="$cpuCount" "$@"
    extra_script post rust
}

fix_libtiff_pc() {
    pc_exists libtiff-4 || return
    local _pkgconfLoc
    _pkgconfLoc="$(cygpath -u "$(pkg-config --debug libtiff-4 2>&1 |
        sed -rn "/Reading/{s/.*'(.*\.pc)'.*/\1/gp}")")"
    [[ ! -f $_pkgconfLoc ]] && return
    grep_or_sed zstd "$_pkgconfLoc" 's;Libs.private:.*;& -lzstd;'
}

fix_cmake_crap_exports() {
    local _dir="$1"
    # noop if passed directory is not valid
    test -d "$_dir" || return 1

    local _mixeddestdir _oldDestDir _cmakefile
    declare -a _cmakefiles

    _mixeddestdir="$(cygpath -m "$LOCALDESTDIR")"
    mapfile -t _cmakefiles < <(grep -Plr '\w:/[\w/]*local(?:32|64)' "$_dir"/*.cmake)

    # noop if array is empty
    test ${#_cmakefiles[@]} -lt 1 && return

    for _cmakefile in "${_cmakefiles[@]}"; do
        # find at least one
        _oldDestDir="$(grep -oP -m1 '\w:/[\w/]*local(?:32|64)' "$_cmakefile")"

        # noop if there's no expected install prefix found
        [[ -z $_oldDestDir ]] && continue
        # noop if old and current install prefix are equal
        [[ $_mixeddestdir == "$_oldDestDir" ]] && continue

        # use perl for the matching and replacing, a bit simpler than with sed
        perl -i -p -e 's;([A-Z]:/.*?)local(?:32|64);'"$_mixeddestdir"'\2;' "$_cmakefile"
    done
}

verify_cuda_deps() {
    enabled cuda-sdk && do_removeOption --enable-cuda-sdk && do_addOption --enable-cuda-nvcc
    if enabled_any libnpp cuda-nvcc && [[ $license != "nonfree" ]]; then
        do_removeOption "--enable-(cuda-nvcc|libnpp)"
    fi
    if enabled libnpp && [[ $bits == 32bit ]]; then
        echo -e "${orange}libnpp is only supported in 64-bit.${reset}"
        do_removeOption --enable-libnpp
    fi
    if enabled_any libnpp cuda-nvcc && [[ -z $CUDA_PATH || ! -d $CUDA_PATH ]]; then
        echo -e "${orange}CUDA_PATH environment variable not set or directory does not exist.${reset}"
        do_removeOption "--enable-(cuda-nvcc|libnpp)"
    fi
    if enabled libnpp && [[ ! -f "$CUDA_PATH/lib/x64/nppc.lib" ]]; then
        do_removeOption --enable-libnpp
    fi
    if ! disabled cuda-llvm && do_pacman_install clang; then
        do_removeOption --enable-cuda-nvcc
    else
        do_removeOption --enable-cuda-llvm
        do_addOption --disable-cuda-llvm
    fi
    if enabled cuda-nvcc; then
        if ! get_cl_path; then
            echo -e "${orange}MSVC cl.exe not found in PATH or through vswhere; needed by nvcc.${reset}"
            do_removeOption --enable-cuda-nvcc
        elif enabled cuda-nvcc && ! command -v nvcc.exe &> /dev/null &&
            ! command -v "$(cygpath -sm "$CUDA_PATH")/bin/nvcc.exe" &> /dev/null; then
            echo -e "${orange}nvcc.exe not found in PATH or installed in CUDA_PATH.${reset}"
            do_removeOption --enable-cuda-nvcc
        fi
    fi
    enabled_any libnpp cuda-nvcc || ! disabled cuda-llvm
}

check_custom_patches(){
    local _basedir
    _basedir="$(get_first_subdir)"
    local vcsFolder="${_basedir%-*}"
    local vcsType="${_basedir##*-}"
    if [[ -d $LOCALBUILDDIR && -f "$LOCALBUILDDIR/${vcsFolder}_extra.sh" ]]; then
        export REPO_DIR="$LOCALBUILDDIR/${_basedir}"
        export REPO_NAME="${vcsFolder}"
        do_print_progress "Found ${vcsFolder}_extra.sh. Sourcing script"
        source "$LOCALBUILDDIR/${vcsFolder}_extra.sh"
        echo "${vcsFolder}" >> "$LOCALBUILDDIR/patchedFolders"
        sort -uo "$LOCALBUILDDIR/patchedFolders"{,}
    fi
}

extra_script(){
    local stage="$1"
    local commandname="$2"
    local vcsFolder="${REPO_DIR%-*}"
    vcsFolder="${vcsFolder#*build/}"
    if [[ $commandname =~ ^(make|meson|ninja)$ ]] &&
        type "_${stage}_build" > /dev/null 2>&1; then
        pushd "${REPO_DIR}" > /dev/null || true
        do_print_progress "Running ${stage} build from ${vcsFolder}_extra.sh"
        log quiet "${stage}_build" "_${stage}_build"
        popd > /dev/null || true
    elif type "_${stage}_${commandname}" > /dev/null 2>&1; then
        pushd "${REPO_DIR}" > /dev/null || true
        do_print_progress "Running ${stage} ${commandname} from ${vcsFolder}_extra.sh"
        log quiet "${stage}_${commandname}" "_${stage}_${commandname}"
        popd > /dev/null || true
    fi
}

unset_extra_script(){
    # The current repository folder (/build/ffmpeg-git)
    unset REPO_DIR
    # The repository name (ffmpeg)
    unset REPO_NAME

    # Each of the _{pre,post}_<Command> means that there is a "_pre_<Command>"
    # and "_post_<Command>"

    # Runs before and after building rust packages (do_rust)
    unset _{pre,post}_rust

    ## Pregenerational hooks

    # Runs before and after running autoreconf -fiv (do_autoreconf)
    unset _{pre,post}_autoreconf

    # Runs before and after running ./autogen.sh (do_autogen)
    unset _{pre,post}_autogen

    # Generational hooks

    # Runs before and after running ./configure (do_separate_conf, do_configure)
    unset _{pre,post}_configure

    # Runs before and after running cmake (do_cmake)
    unset _{pre,post}_cmake

    ## Build hooks

    # Runs before and after runing make (do_make)
    unset _{pre,post}_make

    # Runs before and after running meson (do_meson)
    unset _{pre,post}_meson

    # Runs before and after running ninja (do_ninja)
    unset _{pre,post}_ninja

    # Runs before and after running make, meson, ninja, and waf (Generic hook for the previous build hooks)
    # If this is present, it will override the other hooks
    # Use for mpv and python waf based stuff.
    unset _{pre,post}_build

    ## Post build hooks

    # Runs before and after either ninja install
    # or make install or using install
    # (do_makeinstall, do_ninjainstall, do_install)
    unset _{pre,post}_install
}

create_extra_skeleton() {
    local overwrite
    while true; do
        case $1 in
        -f) overwrite=y && shift ;;
        --)
            shift
            break
            ;;
        *) break ;;
        esac
    done
    local extraName="$1"
    [[ -z $extraName ]] &&
        printf '%s\n' \
            'Usage: create_extra_skeleton [-f] <vcs folder name without the vcs type suffix>' \
            'For example, to create a ffmpeg_extra.sh skeleton file in '"$LOCALBUILDDIR"':' \
            '> create_extra_skeleton ffmpeg' && return 1
    [[ -f "$LOCALBUILDDIR/$extraName"_extra.sh && -z $overwrite ]] &&
        echo "$LOCALBUILDDIR/$extraName_extra.sh already exists. Use -f if you are sure you want to overwrite it." && return 1

    IFS=$'\n' read -r -d '' script_file <<'EOF' || true
#!/bin/bash

# Force to the suite to think the package has updates to recompile.
# Alternatively, you can use "touch recompile" for a similar effect.
#touch custom_updated

# Runs before and after building rust packages (do_rust)
_pre_rust() {
    true
}
_post_rust() {
    true
}

# Runs before and after running autoreconf -fiv (do_autoreconf)
_pre_autoreconf() {
    true
}
_post_autoreconf() {
    true
}

# Runs before and after running ./autogen.sh (do_autogen)
_pre_autogen() {
    true
}
_post_autogen() {
    true
}

# Commands to run before and after running configure on a Autoconf/Automake/configure-using package
_pre_configure(){
    true
    #
    # Apply a patch from ffmpeg's patchwork site.
    #do_patch "https://patchwork.ffmpeg.org/patch/12563/mbox/" am
    #
    # Apply a local patch inside the directory where is "ffmpeg_extra.sh"
    #patch -p1 -i "$LOCALBUILDDIR/ffmpeg-0001-my_patch.patch"
    #
    # Add extra configure options to ffmpeg (ffmpeg specific)
    # If you want to add something to ffmpeg not within the suite already
    # you will need to install it yourself, either through pacman
    # or compiling from source.
    #FFMPEG_OPTS+=(--enable-libsvthevc)
    #
}
_post_configure(){
    true
}

# Commands to run before and after running cmake (do_cmake)
_pre_cmake(){
    true
    # Installs libwebp
    #do_pacman_install libwebp
    # Downloads the patch and then applies the patch
    #do_patch "https://gist.githubusercontent.com/1480c1/9fa9292afedadcea2b3a3e067e96dca2/raw/50a3ed39543d3cf21160f9ad38df45d9843d8dc5/0001-Example-patch-for-learning-purpose.patch"
    # Change directory to the build folder
    #cd_safe "build-${bits}"
    # Add additional options to suite's cmake execution
    #cmake_extras=(-DENABLE_SWEET_BUT_BROKEN_FEATURE=on)
}

_post_cmake(){
    true
    # Run cmake directly with custom options. $LOCALDESTDIR refers to local64 or local32
    #cmake .. -G"Ninja" -DCMAKE_INSTALL_PREFIX="$LOCALDESTDIR" \
    #    -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER=clang \
    #    -DBUILD_SHARED_LIBS=off -DENABLE_TOOLS=off
    # You can also do the same thing in _pre_cmake after creating a 'do_not_reconfigure'
    # file in the source directory. This way you can avoid running cmake twice.
    #touch "$(get_first_subdir)/do_not_reconfigure"
}

# Runs before and after runing make (do_make)
_pre_make(){
    true
}
_post_make(){
    true
    # Don't run configure again.
    #touch "$(get_first_subdir)/do_not_reconfigure"
    # Don't clean the build folder on each successive run.
    # This is for if you want to keep the current build folder as is and just recompile only.
    #touch "$(get_first_subdir)/do_not_clean"
}

# Runs before and after running meson (do_meson)
_pre_meson() {
    true
}
_post_meson() {
    true
}

# Runs before and after running ninja (do_ninja)
_pre_ninja() {
    true
}
_post_ninja() {
    true
}

# Runs before and after running make, meson, ninja, and waf (Generic hook for the previous build hooks)
# If this is present, it will override the other hooks
# Use for mpv and python waf based stuff.
_pre_build() {
    true
}
_post_build() {
    true
}

# Runs before and after either ninja install
# or make install or using install
# (do_makeinstall, do_ninjainstall, do_install)
_pre_install() {
    true
}
_post_install() {
    true
}

EOF
    printf '%s' "$script_file" > "${LOCALBUILDDIR}/${extraName}_extra.sh"
    echo "Created skeleton file ${LOCALBUILDDIR}/${extraName}_extra.sh"
}

# if you absolutely need to remove some of these,
# add a "-e '!<hardcoded rule>'"  option
# ex: "-e '!/recently_updated'"
safe_git_clean() {
    git clean -xfd \
        -e "/build_successful*" \
        -e "/recently_updated" \
        -e '/recently_checked' \
        -e '/custom_updated' \
        -e '**/ab-suite.*.log' \
        "${@}"
}
