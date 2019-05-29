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

/usr/bin/pacman-key -f EFD16019AE4FF531 || pacman-key -r EFD16019AE4FF531 >/dev/null
/usr/bin/pacman-key --list-sigs AE4FF531 | grep -q pacman@localhost || pacman-key --lsign AE4FF531 >/dev/null

#always kill gpg-agent
ps|grep gpg-agent|awk '{print $1}'|xargs -r kill -9

# for some people the signature is broken
printf 'Server = %s\nSigLevel = Optional\n' \
    'https://i.fsbn.eu/abrepo/' > /etc/pacman.d/abrepo.conf

# fix fuckup
grep -q 'i.fsbn.eu/abrepo' /etc/pacman.conf &&
    sed -i '/\[abrepo\]/,+2d' /etc/pacman.conf

/usr/bin/grep -q abrepo /etc/pacman.conf ||
    sed -i '/\[mingw32\]/ i\[abrepo]\
Include = /etc/pacman.d/abrepo.conf\
' /etc/pacman.conf

echo
echo "-------------------------------------------------------------------------------"
echo "Updating pacman database..."
echo "-------------------------------------------------------------------------------"
echo

pacman -Sy --ask=20 --noconfirm
pacman -Qqe | grep -q sed && pacman -Qqg base | pacman -D --asdeps - && pacman -D --asexplicit mintty flex > /dev/null
do_unhide_all_sharedlibs
if [[ -f /etc/pac-base.pk ]] && [[ -f /etc/pac-mingw.pk ]]; then
    echo
    echo "-------------------------------------------------------------------------------"
    echo "Checking pacman packages..."
    echo "-------------------------------------------------------------------------------"
    echo
    old=$(pacman -Qqe | sort)
    new=$(dos2unix < /etc/pac-base.pk)
    newmingw=$(dos2unix < /etc/pac-mingw.pk)
    [[ -f /etc/pac-mingw-extra.pk ]] && newmingw+=$(printf "\n%s" "$(dos2unix < /etc/pac-mingw-extra.pk)")
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
                        pacman -Rs --noconfirm --ask 20 "$pkg" 2>/dev/null
                        pacman -Qs "^${pkg}$" >/dev/null && pacman -D --noconfirm --ask 20 --asdeps "$pkg" >/dev/null
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
                    echo $install | xargs $nargs pacman -Sw --noconfirm --ask 20 --needed
                    echo $install | xargs $nargs pacman -S --noconfirm --ask 20 --needed
                    pacman -D --asexplicit $install
                    break;;
                [Nn]* ) exit;;
                * ) echo "Please answer yes or no";;
            esac
        done
    fi
    rm -f /etc/pac-{base,mingw}.pk
fi

if [[ -d "/trunk" ]]; then
    cd "/trunk" || exit 1
else
    cd_safe "$(cygpath -w /).."
fi

if which rustup &> /dev/null; then
    echo "Updating rust..."
    rustup update
fi

# --------------------------------------------------
# packet msys2 system
# --------------------------------------------------

have_updates="$(pacman -Qu|grep -v ignored]$|awk '{print $1}')"
if [[ -n "$have_updates" ]]; then
    echo "-------------------------------------------------------------------------------"
    echo "Updating msys2 system and installed packages..."
    echo "-------------------------------------------------------------------------------"
    echo "$have_updates" | /usr/bin/grep -Eq '^(pacman|bash|msys2-runtime)$' &&
        touch build/update_core &&
        have_updates="$(echo "$have_updates" | /usr/bin/grep -Ev '^(pacman|bash|msys2-runtime)$')"
    echo $have_updates | xargs $nargs pacman -S --noconfirm --ask 20 \
        --overwrite "/mingw64/*" --overwrite "/mingw32/*" --overwrite "/usr/*"
fi

[[ ! -s /usr/ssl/certs/ca-bundle.crt ]] &&
    pacman -S --noconfirm --ask 20 --asdeps ca-certificates

# do a final overall installation for potential downgrades
pacman -Syyuu --noconfirm --ask 20 --overwrite "/mingw64/*" \
    --overwrite "/mingw32/*" --overwrite "/usr/*"

do_hide_all_sharedlibs

echo "-------------------------------------------------------------------------------"
echo "Updates finished."
echo "-------------------------------------------------------------------------------"

sleep 2

exit
