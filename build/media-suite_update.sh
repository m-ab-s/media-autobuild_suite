#!/bin/bash

echo -ne "\033]0;update autobuild suite\007"

while true; do
  case $1 in
--build32=* ) build32="${1#*=}"; shift ;;
--build64=* ) build64="${1#*=}"; shift ;;
--remove=* ) remove="${1#*=}"; shift ;;
--update=* ) update="${1#*=}"; shift ;;
    -- ) shift; break ;;
    -* ) echo "Error, unknown option: '$1'."; exit 1 ;;
    * ) break ;;
  esac
done

[[ -d "/trunk/build" ]] && cd "/trunk/build" || cd "$(cygpath -w /)../build"
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
    cd ..
    if [[ -d .git ]]; then
        if [[ -n $(git status -s) ]]; then
            diffname="$(date +%F-%H.%M.%S)"
            git diff --diff-filter=M >> build/user-changes-${diffname}.diff
            echo "Your changes have been exported to build/user-changes-${diffname}.diff."
            git reset --hard origin/master
        fi
        oldHead=$(git rev-parse HEAD)
        git fetch -qt origin
        git checkout -qfB master "origin/HEAD"
        newHead=$(git rev-parse HEAD)
        if git apply build/user-changes-${diffname}.diff; then
            rm build/user-changes-${diffname}.diff
            echo "Your changes have been successfully applied!"
        elif [[ -f build/user-changes-${diffname}.diff ]]; then
            echo "Your changes couldn't be applied. Script will run without them."
        fi
        if [[ $oldHead != $newHead ]]; then
            touch build/suite_updated
            echo "Script will now restart to use the new changes."
            sleep 5
            exit
        fi
    fi
fi

# --------------------------------------------------
# packet update system
# --------------------------------------------------

pacman -Sy
pacman -Qqe | grep -q sed && pacman -Qqg base | pacman -D --asdeps - > /dev/null

if [[ -f /etc/pac-base.pk ]] && [[ -f /etc/pac-mingw.pk ]]; then
    echo
    echo "-------------------------------------------------------------------------------"
    echo "checking pacman packages..."
    echo "-------------------------------------------------------------------------------"
    echo
    old=$(pacman -Qqe | sort)
    new=$(cat /etc/pac-base.pk)
    newmingw=$(cat /etc/pac-mingw.pk)
    [[ -f /etc/pac-mingw-extra.pk ]] && newmingw+=$(printf "\n$(cat /etc/pac-mingw-extra.pk)")
    [[ "$build32" = "yes" ]] && new+=$(printf "\n$(echo "$newmingw" | sed 's/^/mingw-w64-i686-&/g')")
    [[ "$build64" = "yes" ]] && new+=$(printf "\n$(echo "$newmingw" | sed 's/^/mingw-w64-x86_64-&/g')")
    diff=$(diff <(echo "$old") <(echo "$new" | sed 's/ /\n/g' | sort -u) | grep '^[<>]')
    install=$(echo "$diff" | sed -nr 's/> (.*)/\1/p')
    uninstall=$(echo "$diff" | sed -nr 's/< (.*)/\1/p')

    if [[ "$install" != "" ]]; then
        echo
        echo "-------------------------------------------------------------------------------"
        echo "You're missing some packages!"
        echo "Do you want to install them?"
        echo "-------------------------------------------------------------------------------"
        echo
        echo "Install:"
        echo "$install"
        while true; do
            read -p "install packs [y/n]? " yn
            case $yn in
                [Yy]* )
                    pacman -S --noconfirm --needed $install
                    pacman -D --asexplicit $install
                    break;;
                [Nn]* ) exit;;
                * ) echo "Please answer yes or no";;
            esac
        done
    fi
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
            read -p "remove packs [y/n]? " yn
            case $yn in
                [Yy]* )
                    for pkg in $uninstall; do
                        pacman -Rs --noconfirm $pkg 2>/dev/null
                        pacman -Qs "^${pkg}$" >/dev/null && pacman -D --noconfirm --asdeps $pkg >/dev/null
                    done
                    break;;
                [Nn]* ) pacman --noconfirm -D --asdeps $uninstall; break;;
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
echo "checking profiles..."
echo "-------------------------------------------------------------------------------"
echo

[[ -d "/trunk" ]] && cd "/trunk" || cd "$(cygpath -w /).."

check_profiles() {
    local profilebits="$1"
    local newProfile=""
    if [[ -f "/${profilebits}/etc/profile.local" ]]; then
        newProfile=$(sed -n "/# .${profilebits}.etc.profile.local$/,/${profilebits}.etc.profile.local$/p" \
            media-autobuild_suite.bat | head -n -1 | sed "s/^\s*echo\.//")
        if ! diff <(echo "$newProfile") <(tail -n +2 "/${profilebits}/etc/profile.local") &> /dev/null; then
            echo "Updating profile in /${profilebits}..."
            printf "#\n%s\n" "$newProfile" > "/${profilebits}/etc/profile.local"
        fi
    fi
}

if [[ $build32 = "yes" ]]; then
    check_profiles "local32"
fi

if [[ $build64 = "yes" ]]; then
    check_profiles "local64"
fi

# --------------------------------------------------
# packet msys2 system
# --------------------------------------------------

echo "-------------------------------------------------------------------------------"
echo "updating msys2 system..."
echo "-------------------------------------------------------------------------------"
pacman --noconfirm -Su --force --ignoregroup base
pacman --noconfirm -Su --force
if [[ ! -s /usr/ssl/certs/ca-bundle.crt ]]; then
    pacman --noconfirm -S --asdeps ca-certificates
fi

do_hide_all_sharedlibs

echo "-------------------------------------------------------------------------------"
echo "updating msys2 done..."
echo "-------------------------------------------------------------------------------"

sleep 2

exit
