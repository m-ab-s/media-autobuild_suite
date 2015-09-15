echo -ne "\033]0;update autobuild suite\007"

while true; do
  case $1 in
--build32=* ) build32="${1#*=}"; shift ;;
--build64=* ) build64="${1#*=}"; shift ;;
--remove=* ) remove="${1#*=}"; shift ;;
    -- ) shift; break ;;
    -* ) echo "Error, unknown option: '$1'."; exit 1 ;;
    * ) break ;;
  esac
done

[[ -d "/build" ]] && cd "/build" || cd "$(cygpath -w /)../build"
[[ -f media-suite_helper.sh ]] && source media-suite_helper.sh

# --------------------------------------------------
# packet update system
# --------------------------------------------------

pacman -Sy
pacman -Qqe | grep -q sed && pacman -Qqg base | pacman -D --asdeps - > /dev/null

if [[ -f /etc/pac-base.pk ]] && [[ -f /etc/pac-mingw.pk ]]; then
    echo
    echo "-------------------------------------------------------------------------------"
    echo "check pacman packages..."
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
                    pacman -R --noconfirm $uninstall
                    do_pacman_remove "$uninstall"
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
echo "check profiles..."
echo "-------------------------------------------------------------------------------"
echo

[[ -d "/trunk" ]] && cd "/trunk" || cd "$(cygpath -w /).."

if [[ $build32 = "yes" ]]; then
    if [ -f "/local32/etc/profile.local" ]; then
        newProfiles32=$(sed -n "/echo.# \/local32\/etc\/profile.local/,/export PATH PS1 HOME GIT_GUI_LIB_DIR/p" media-autobuild_suite.bat | sed "s/echo.//g")
        oldProfiles32=$(sed -n "/# \/local32\/etc\/profile.local/,/export PATH PS1 HOME GIT_GUI_LIB_DIR/p" /local32/etc/profile.local)

        if ! diff -q <(echo $newProfiles32) <(echo $oldProfiles32) &> /dev/null; then
            echo
            echo "-------------------------------------------------------------------------------"
            echo "delete old 32 bit profile..."
            echo "-------------------------------------------------------------------------------"
            echo
            rm -f /local32/etc/profile.local
        fi
    fi
fi

if [[ $build64 = "yes" ]]; then
        if [ -f "/local64/etc/profile.local" ]; then
        newProfiles64=$(sed -n "/echo.# \/local64\/etc\/profile.local/,/export PATH PS1 HOME GIT_GUI_LIB_DIR/p" media-autobuild_suite.bat | sed "s/echo.//g")
        oldProfiles64=$(sed -n "/# \/local64\/etc\/profile.local/,/export PATH PS1 HOME GIT_GUI_LIB_DIR/p" /local64/etc/profile.local)

        if ! diff -q <(echo $newProfiles64) <(echo $oldProfiles64) &> /dev/null; then
            echo
            echo "-------------------------------------------------------------------------------"
            echo "delete old 64 bit profile..."
            echo "-------------------------------------------------------------------------------"
            echo
            rm -f /local64/etc/profile.local
        fi
    fi
fi

# --------------------------------------------------
# packet msys2 system
# --------------------------------------------------

echo "-------------------------------------------------------------------------------"
echo "updating msys2 system..."
echo "-------------------------------------------------------------------------------"
pacman --noconfirm -Su --force --asdeps --ignoregroup base
pacman --noconfirm -Su --force --asdeps
if [[ ! -s /usr/ssl/certs/ca-bundle.crt ]]; then
    pacman --noconfirm -S --asdeps ca-certificates
fi

do_hide_all_sharedlibs

echo "-------------------------------------------------------------------------------"
echo "updating msys2 done..."
echo "-------------------------------------------------------------------------------"

sleep 4

exit