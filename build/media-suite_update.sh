#!/bin/bash

while true; do
  case $1 in
--build32=* ) build32="${1#*=}"; shift ;;
--build64=* ) build64="${1#*=}"; shift ;;
--update=* ) update="${1#*=}"; shift ;;
    -- ) shift; break ;;
    -* ) echo "Error, unknown option: '$1'."; exit 1 ;;
    * ) break ;;
  esac
done

# start suite update
if [[ -d "/trunk/build" ]]; then
    cd "/trunk/build" || exit 1
else
    cd "$(cygpath -w /)../build" || exit 1
fi
[[ -f media-suite_helper.sh ]] && source media-suite_helper.sh
[[ "$(uname)" = *6.1* ]] && nargs="-n 4"

# --------------------------------------------------
# update suite
# --------------------------------------------------

if [[ "$update" = "yes" ]]; then
    echo
    echo "-------------------------------------------------------------------------------"
    echo "checking if suite has been updated..."
    echo "-------------------------------------------------------------------------------"
    echo

    if [[ ! -d ../.git ]] && which git > /dev/null; then
        if ! git clone "https://github.com/jb-alvarado/media-autobuild_suite.git" ab-git; then
            git -C ab-git fetch
        fi
        cp -fr ab-git/.git ..
    fi
    cd_safe ..
    if [[ -d .git ]]; then
        if [[ -n $(git status --short --untracked-files=no) ]]; then
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

echo
echo "-------------------------------------------------------------------------------"
echo "Updating pacman database..."
echo "-------------------------------------------------------------------------------"
echo

pacman -Sy
pacman -Qqe | grep -q sed && pacman -Qqg base | pacman -D --asdeps - > /dev/null
do_unhide_all_sharedlibs
if [[ -f /etc/pac-base.pk ]] && [[ -f /etc/pac-mingw.pk ]]; then
    echo
    echo "-------------------------------------------------------------------------------"
    echo "Checking pacman packages..."
    echo "-------------------------------------------------------------------------------"
    echo
    old=$(pacman -Qqe | sort)
    new=$(cat /etc/pac-base.pk | dos2unix)
    newmingw=$(cat /etc/pac-mingw.pk | dos2unix)
    [[ -f /etc/pac-mingw-extra.pk ]] && newmingw+=$(printf "\n%s" "$(cat /etc/pac-mingw-extra.pk | dos2unix)")
    [[ "$build32" = "yes" ]] && new+=$(printf "\n%s" "$(echo "$newmingw" | sed 's/^/mingw-w64-i686-&/g')")
    [[ "$build64" = "yes" ]] && new+=$(printf "\n%s" "$(echo "$newmingw" | sed 's/^/mingw-w64-x86_64-&/g')")
    diff=$(diff <(echo "$old") <(echo "$new" | sed 's/ /\n/g' | sort -u) | grep '^[<>]')
    install=$(echo "$diff" | sed -nr 's/> (.*)/\1/p')
    uninstall=$(echo "$diff" | sed -nr 's/< (.*)/\1/p')

    if [[ ! -z "$uninstall" ]]; then
        echo
        echo "-------------------------------------------------------------------------------"
        echo "You have more packages than needed!"
        echo "Do you want to remove them?"
        echo "-------------------------------------------------------------------------------"
        echo
        echo "Remove:"
        echo "$uninstall"
        while true; do
            read -r -p "remove packs [y/n]? " yn
            case $yn in
                [Yy]* )
                    for pkg in $uninstall; do
                        pacman -Rs --noconfirm "$pkg" 2>/dev/null
                        pacman -Qs "^${pkg}$" >/dev/null && pacman -D --noconfirm --asdeps "$pkg" >/dev/null
                    done
                    break;;
                [Nn]* ) pacman --noconfirm -D --asdeps $uninstall; break;;
                * ) echo "Please answer yes or no";;
            esac
        done
    fi
    if [[ ! -z "$install" ]]; then
        echo
        echo "-------------------------------------------------------------------------------"
        echo "You're missing some packages!"
        echo "Do you want to install them?"
        echo "-------------------------------------------------------------------------------"
        echo
        echo "Install:"
        echo "$install"
        while true; do
            read -r -p "install packs [y/n]? " yn
            case $yn in
                [Yy]* )
                    echo $install | xargs $nargs pacman -Sw --noconfirm --needed
                    echo $install | xargs $nargs pacman -S --noconfirm --needed
                    pacman -D --asexplicit $install
                    break;;
                [Nn]* ) exit;;
                * ) echo "Please answer yes or no";;
            esac
        done
    fi
    rm -f /etc/pac-{base,mingw}.pk
fi

# --------------------------------------------------
# check profiles
# --------------------------------------------------

echo "-------------------------------------------------------------------------------"
echo "Checking profiles..."
echo "-------------------------------------------------------------------------------"
echo

if [[ -d "/trunk" ]]; then
    cd "/trunk" || exit 1
else
    cd_safe "$(cygpath -w /).."
fi

check_profiles() {
    local profile="/local${1}/etc/profile2.local"
    local bat="media-autobuild_suite.bat"
    [[ -f "${bat}" ]] || return 1
    local new common tmp
    new="$(sed -n "/# ${profile////.}$/,/${profile////.}$/p" < <(dos2unix < "${bat}") | head -n -1)"
    common="$(sed -n "/^:writeCommonProfile/,/%instdir%.local%1/p" < <(dos2unix < "${bat}") | head -n -1 | tail -n +3)"
    tmp="$(printf '%s\n' "$new" "$common" | sed 's,^\s*echo\.,,g')"
    [[ -f ."${profile//2}" ]] &&
        rm -f ."${profile//2}" && echo "Deleted old profiles"
    if [[ -f ."${profile}" ]]; then
        [[ "$(file ."${profile}")" =~ CRLF ]] && dos2unix -q ."${profile}"
        if ! diff <(echo "$tmp") ."${profile}" &> /dev/null; then
            echo "Updating ${profile%/etc*} profile"
        else
            echo "${profile%/etc*} profile up-to-date!"
            return 0
        fi
    else
        echo "Creating ${profile%/etc*} profile"
    fi
    echo "$tmp" > ."${profile}"
}

if [[ $build32 = "yes" ]]; then
    check_profiles 32
fi

if [[ $build64 = "yes" ]]; then
    check_profiles 64
fi

# --------------------------------------------------
# packet msys2 system
# --------------------------------------------------

have_updates="$(pacman -Quq)"
if [[ -n "$have_updates" ]]; then
    echo "-------------------------------------------------------------------------------"
    echo "Updating msys2 system and installed packages..."
    echo "-------------------------------------------------------------------------------"
    echo "$have_updates" | /usr/bin/grep -Eq '^(pacman|bash|msys2-runtime)$' &&
        touch build/update_core &&
        have_updates="$(echo "$have_updates" | /usr/bin/grep -Ev '^(pacman|bash|msys2-runtime)$')"
    echo $have_updates | xargs $nargs pacman -S --noconfirm --force
    sed -i "s;^IgnorePkg.*;#&;" /etc/pacman.conf
fi
[[ ! -s /usr/ssl/certs/ca-bundle.crt ]] &&
    pacman --noconfirm -S --asdeps ca-certificates

do_hide_all_sharedlibs

echo "-------------------------------------------------------------------------------"
echo "Updates finished."
echo "-------------------------------------------------------------------------------"

sleep 2

exit
