#!/bin/bash
# shellcheck disable=SC2086

while true; do
    case $1 in
    --build32=*)
        build32="${1#*=}"
        shift
        ;;
    --build64=*)
        build64="${1#*=}"
        shift
        ;;
    --update=*)
        update="${1#*=}"
        shift
        ;;
    --CC=*)
        CC="${1#*=}"
        shift
        ;;
    --)
        shift
        break
        ;;
    -*)
        echo "Error, unknown option: '$1'."
        exit 1
        ;;
    *) break ;;
    esac
done

[[ "$(uname)" == *6.1* ]] && nargs="-n 4"

# start suite update
if [[ -d "/trunk/build" ]]; then
    cd "/trunk/build" || exit 1
else
    cd "$(cygpath -w /)../build" || exit 1
fi
[[ -f media-suite_helper.sh ]] && source media-suite_helper.sh
[[ -f media-suite_deps.sh ]] && source media-suite_deps.sh

# --------------------------------------------------
# update suite
# --------------------------------------------------

if [[ $update == "yes" ]]; then
    echo
    echo "-------------------------------------------------------------------------------"
    echo "checking if suite has been updated..."
    echo "-------------------------------------------------------------------------------"
    echo

    if [[ ! -d ../.git ]] && command -v git > /dev/null; then
        if ! git clone "${SOURCE_REPO_MABS:-https://github.com/m-ab-s/media-autobuild_suite.git}" ab-git; then
            git -C ab-git fetch
        fi
        cp -fr ab-git/.git ..
    fi
    cd_safe ..
    if [[ -d .git ]]; then
        if [[ -n "$(git diff --name-only)" ]]; then
            diffname="$(date +%F-%H.%M.%S)"
            git diff --diff-filter=M >> "build/user-changes-${diffname}.diff"
            echo "Your changes have been exported to build/user-changes-${diffname}.diff."
            git reset --hard "@{upstream}"
        fi
        git fetch -t
        oldHead=$(git rev-parse HEAD)
        git reset --hard "@{upstream}"
        newHead=$(git rev-parse HEAD)
        if [[ $oldHead != "$newHead" ]]; then
            echo "Suite has been updated!"
            echo "If you had an issue try running the suite again before reporting."
        else
            echo "Suite up-to-date."
            echo "If you had an issue, please report it in GitHub."
        fi
        read -r -t 15 -p '<Enter> to close' ret
    fi
fi # end suite update

# --------------------------------------------------
# packet update system
# --------------------------------------------------

# remove buggy crap
grep -q abrepo /etc/pacman.conf && sed -i '/abrepo/d' /etc/pacman.conf
rm -f /etc/pacman.d/abrepo.conf

rm -rf /opt/cargo/bin

echo
echo "-------------------------------------------------------------------------------"
echo "Updating pacman database..."
echo "-------------------------------------------------------------------------------"
echo

pacman -Sy --ask=20 --noconfirm
{ pacman -Qqe | grep -q sed && pacman -Qqg base | pacman -D --asdeps - && pacman -D --asexplicit mintty flex; } > /dev/null
do_unhide_all_sharedlibs

# make sure that pacutils is always installed for pacsift
{ pacman -Qq pacutils || pacman -S --needed --noconfirm pacutils; } > /dev/null 2>&1

extract_pkg_prefix() (
    case $1 in
    *32) [[ $build32 != "yes" ]] && return 1 ;;
    *64) [[ $build64 != "yes" ]] && return 1 ;;
    esac
    . shell "$1"
    echo "$MINGW_PACKAGE_PREFIX-"
)

if [[ -f /etc/pac-base.pk && -f /etc/pac-mingw.pk ]] && ! [[ $build32 == "yes" && $CC =~ clang ]]; then
    new=$(mktemp)
    old=$(mktemp)
    echo
    echo "-------------------------------------------------------------------------------"
    echo "Checking pacman packages..."
    echo "-------------------------------------------------------------------------------"
    echo
    dos2unix -O /etc/pac-base.pk 2> /dev/null | sort -u >> "$new"
    mapfile -t newmingw < <(dos2unix -O /etc/pac-mingw.pk /etc/pac-mingw-extra.pk 2>/dev/null | sort -u)
    mapfile -t newmsys < <(dos2unix -O /etc/pac-msys-extra.pk 2> /dev/null | sort -u)
    prefix_32='' prefix_64=''
    case $CC in
    *clang) prefix_64=$(extract_pkg_prefix clang64) ;;
    *) prefix_32=$(extract_pkg_prefix mingw32) prefix_64=$(extract_pkg_prefix mingw64) ;;
    esac
    for pkg in "${newmingw[@]}"; do
        if [[ $build32 == "yes" ]] && [[ ! $CC =~ clang ]] &&
            pacman -Ss "$prefix_32$pkg" > /dev/null 2>&1; then
            printf %s\\n "$prefix_32$pkg" >> "$new"
        fi
        if [[ $build64 == "yes" ]] &&
            pacman -Ss "$prefix_64$pkg" > /dev/null 2>&1; then
            printf %s\\n "$prefix_64$pkg" >> "$new"
        fi
    done
    for pkg in "${newmsys[@]}"; do
        pacman -Ss "^${pkg}$" > /dev/null 2>&1 && printf %s\\n "$pkg" >> "$new"
    done
    pacman -Qqe | sort -u >> "$old"
    sort -uo "$new"{,}
    # mapfile -t new < <(printf %s\\n "${new[@]}" | sort -u)
    mapfile -t install < <(diff --changed-group-format='%>' --unchanged-group-format='' "$old" "$new")
    mapfile -t uninstall < <(diff --changed-group-format='%<' --unchanged-group-format='' "$old" "$new")

    if [[ ${#uninstall[@]} -gt 0 ]]; then
        echo
        echo "-------------------------------------------------------------------------------"
        echo "You have more packages than needed!"
        echo "Do you want to remove them?"
        echo "-------------------------------------------------------------------------------"
        echo
        echo "Remove:"
        echo "${uninstall[*]}"
        while true; do
            read -r -p "remove packs [y/n]? " yn
            case $yn in
            [Yy]*)
                pacman -Rs --noconfirm "${uninstall[@]}" >&2 2> /dev/null
                for pkg in "${uninstall[@]}"; do
                    pacman -Qs "^${pkg}$" && pacman -D --noconfirm --asdeps "$pkg" > /dev/null
                done
                break
                ;;
            [Nn]*)
                pacman --noconfirm -D --asdeps "${uninstall[@]}"
                break
                ;;
            *) echo "Please answer yes or no" ;;
            esac
        done
    fi
    if [[ ${#install[@]} -gt 0 ]]; then
        echo "You're missing some packages!"
        echo "Proceeding with installation..."
        pacman -Sw --noconfirm --needed "${install[@]}"
        pacman -S --noconfirm --needed "${install[@]}"
        pacman -D --asexplicit "${install[@]}"
    fi
    rm -f /etc/pac-{base,mingw}.pk "$new" "$old"
elif [[ $build32 == "yes" && $CC =~ clang ]]; then
    echo "The CLANG32 environment is no longer supported"
    exit 1
fi

if [[ -d "/trunk" ]]; then
    cd "/trunk" || exit 1
else
    cd_safe "$(cygpath -w /).."
fi

# --------------------------------------------------
# packet msys2 system
# --------------------------------------------------

have_updates="$(pacman -Qu | grep -v ignored]$ | cut -d' ' -f1)"
if [[ -n $have_updates ]]; then
    echo "-------------------------------------------------------------------------------"
    echo "Updating msys2 system and installed packages..."
    echo "-------------------------------------------------------------------------------"
    grep -Eq '^(pacman|bash|msys2-runtime)$' <<< "$have_updates" &&
        touch /build/update_core &&
        have_updates="$(grep -Ev '^(pacman|bash|msys2-runtime)$' <<< "$have_updates")"
    xargs $nargs pacman -S --noconfirm --overwrite "/mingw64/*" \
        --overwrite "/mingw32/*" --overwrite "/clang64/*" --overwrite "/usr/*" <<< "$have_updates"
fi

[[ ! -s /usr/ssl/certs/ca-bundle.crt ]] &&
    pacman -S --noconfirm --asdeps ca-certificates

# do a final overall installation for potential downgrades
pacman -Syuu --noconfirm --overwrite "/mingw64/*" \
    --overwrite "/mingw32/*" --overwrite "/clang64/*" --overwrite "/usr/*"

do_hide_all_sharedlibs

echo "-------------------------------------------------------------------------------"
echo "Updates finished."
echo "-------------------------------------------------------------------------------"

sleep 2

exit
