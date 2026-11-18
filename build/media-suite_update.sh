#!/bin/bash
# shellcheck disable=SC2086,SC1091

while true; do
    case $1 in
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

# start suite update
if [[ -d "/trunk/build" ]]; then
    cd "/trunk/build" || exit 1
else
    cd "$(cygpath -w /)../build" || exit 1
fi
[[ -f media-suite_helper.sh ]] && source media-suite_helper.sh
[[ -f media-suite_deps.sh ]] && source media-suite_deps.sh
[[ -f media-suite_deps_extra.sh ]] && source media-suite_deps_extra.sh

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

echo
echo "-------------------------------------------------------------------------------"
echo "Updating pacman packages..."
echo "-------------------------------------------------------------------------------"
echo

pacman -Sy --ask=20 --noconfirm
do_unhide_all_sharedlibs

have_updates="$(pacman -Qu | grep -v ignored]$ | cut -d' ' -f1)"
if [[ -n $have_updates ]]; then
    echo "-------------------------------------------------------------------------------"
    echo "Updating msys2 system and installed packages..."
    echo "-------------------------------------------------------------------------------"
    grep -Eq '^(pacman|bash|msys2-runtime)$' <<< "$have_updates" &&
        touch /build/update_core &&
        have_updates="$(grep -Ev '^(pacman|bash|msys2-runtime)$' <<< "$have_updates")"
    mapfile -t updates <<< "$have_updates"
    [[ -n $have_updates ]] && pacman -S --noconfirm --needed --overwrite "/mingw64/*" \
        --overwrite "/mingw32/*" --overwrite "/clang64/*" --overwrite "/ucrt64/*" --overwrite "/usr/*" "${updates[@]}"
fi

# do an overall installation for potential downgrades
pacman -Syuu --noconfirm --overwrite "/mingw64/*" \
    --overwrite "/mingw32/*" --overwrite "/clang64/*" --overwrite "/ucrt64/*" --overwrite "/usr/*"

# -------------------------------------------------------------------------------
# check packages
# -------------------------------------------------------------------------------

# make sure that pacutils is always installed for pacsift
{ pacman -Qq pacutils || pacman -S --needed --noconfirm pacutils; } > /dev/null 2>&1

extract_pkg_prefix() (
    . shell "$1"
    echo "$MINGW_PACKAGE_PREFIX-"
)

add_pkg_group() {
    local packages
    packages=$(pacman -Sgq "$1" 2> /dev/null)
    [[ -n $packages ]] || return 1
    printf '%s\n' "$packages" >> "$new"
}

if [[ -f /etc/pac-base.pk && -f /etc/pac-mingw.pk ]]; then
    new=$(mktemp)
    old=$(mktemp)
    echo
    echo "-------------------------------------------------------------------------------"
    echo "Checking pacman packages..."
    echo "-------------------------------------------------------------------------------"
    echo
    mapfile -t newmingw < <(dos2unix -O /etc/pac-mingw.pk /etc/pac-mingw-extra.pk 2>/dev/null | sort -u)
    mapfile -t newmsys < <(dos2unix -O /etc/pac-base.pk /etc/pac-msys-extra.pk 2> /dev/null | sort -u)
    case $CC in
    *clang) prefix=$(extract_pkg_prefix clang64) ;;
    *) prefix=$(extract_pkg_prefix ucrt64) ;;
    esac
    for pkg in "${newmingw[@]}"; do
        add_pkg_group "$prefix$pkg" || {
            pacman -Ss "$prefix$pkg" > /dev/null 2>&1 &&
            printf '%s\n' "$prefix$pkg" >> "$new"
        }
    done
    for pkg in "${newmsys[@]}"; do
        add_pkg_group "$pkg" || {
            pacman -Ss "^${pkg}$" > /dev/null 2>&1 && printf '%s\n' "$pkg" >> "$new"
        }
    done
    pacman -Qqe | sort -u >> "$old"
    sort -uo "$new"{,}
    # mapfile -t new < <(printf %s\\n "${new[@]}" | sort -u)
    mapfile -t install < <(diff --changed-group-format='%>' --unchanged-group-format='' "$old" "$new")
    mapfile -t uninstall < <(diff --changed-group-format='%<' --unchanged-group-format='' "$old" "$new")

    if [[ ${#install[@]} -gt 0 ]]; then
        echo "You're missing some packages!"
        echo "Proceeding with installation..."
        pacman -S --noconfirm --needed "${install[@]}"
        pacman -D --asexplicit "${install[@]}"
    fi
    [[ ${#uninstall[@]} -gt 0 ]] && pacman --noconfirm -D --asdeps "${uninstall[@]}"
    mapfile -t orphans < <(pacman -Qqdtt)
    if [[ ${#orphans[@]} -gt 0 ]]; then
        echo
        echo "-------------------------------------------------------------------------------"
        echo "You have more packages than needed!"
        echo "Do you want to remove them?"
        echo "-------------------------------------------------------------------------------"
        echo
        echo "Remove:"
        printf '%s\n' "${orphans[@]}"
        while true; do
            read -r -p "remove packs [y/n]? " yn
            case $yn in
            [Yy]*)
                pacman -Rns --noconfirm "${orphans[@]}" >&2 2> /dev/null
                break
                ;;
            [Nn]*)
                break
                ;;
            *) echo "Please answer yes or no" ;;
            esac
        done
    fi
    rm -f /etc/pac-{base,mingw}.pk "$new" "$old"
fi

if [[ -d "/trunk" ]]; then
    cd "/trunk" || exit 1
else
    cd_safe "$(cygpath -w /).."
fi

do_hide_all_sharedlibs

echo "-------------------------------------------------------------------------------"
echo "Updates finished."
echo "-------------------------------------------------------------------------------"

sleep 2

exit
