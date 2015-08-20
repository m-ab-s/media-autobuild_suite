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

# --------------------------------------------------
# packet update system
# --------------------------------------------------

pacman -Qqe | grep -q bash && pacman -Qqg base | pacman -D --asdeps - > /dev/null

if [[ -f "/etc/pac-base.pk" ]] && [[ -f "/etc/pac-mingw32.pk" ]] || [[ -f "/etc/pac-mingw64.pk" ]]; then
    echo
    echo "-------------------------------------------------------------------------------"
    echo "check pacman packages..."
    echo "-------------------------------------------------------------------------------"
    echo
    old=$(pacman -Qqe | sort)
    new=$(cat /etc/pac-base.pk)
    [[ "$build32" = "yes" ]] && new=$(printf "$new\n$(cat /etc/pac-mingw32.pk)")
    [[ "$build64" = "yes" ]] && new=$(printf "$new\n$(cat /etc/pac-mingw64.pk)")
    diff=$(diff <(echo "$old") <(echo "$new" | sed 's/ /\n/g' | sort) | grep '^[<>]')
    install=$(echo "$diff" | grep '>' | sed 's/[<>] //g')
    uninstall=$(echo "$diff" | grep '<' | sed 's/[<>] //g')

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
                [Yy]* ) pacman --noconfirm --needed -S $install; break;;
                [Nn]* ) exit;;
                * ) echo "Please answer yes or no";;
            esac
        done
    fi
    if [[ "$remove" = "y" ]] && [[ "$uninstall" != "" ]]; then
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
                [Yy]* ) pacman --noconfirm -R $uninstall; break;;
                [Nn]* ) break;;
                * ) echo "Please answer yes or no";;
            esac
        done
    fi
    rm -f /etc/pac-{base,mingw32,mingw64}.pk
fi

# --------------------------------------------------
# check profiles
# --------------------------------------------------

echo "-------------------------------------------------------------------------------"
echo "check profiles..."
echo "-------------------------------------------------------------------------------"
echo

iPath=`cygpath -w /`

cd $iPath/..

if [[ $build32 = "yes" ]]; then
    if [ -f "/local32/etc/profile.local" ]; then
        newProfiles32=`sed -n "/echo.# \/local32\/etc\/profile.local/,/echo.cross='i686-w64-mingw32-'/p" media-autobuild_suite.bat | sed "s/echo.//g"`

        oldProfiles32=`sed -n "/# \/local32\/etc\/profile.local/,/cross='i686-w64-mingw32-'/p" /local32/etc/profile.local`

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
        newProfiles64=`sed -n "/echo.# \/local64\/etc\/profile.local/,/echo.cross='x86_64-w64-mingw32-'/p" media-autobuild_suite.bat | sed "s/echo.//g"`

        oldProfiles64=`sed -n "/# \/local64\/etc\/profile.local/,/cross='x86_64-w64-mingw32-'/p" /local64/etc/profile.local`

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
pacman --noconfirm -Syu --force --asdeps --ignoregroup base
pacman --noconfirm -Su --force --asdeps
if [[ ! -s /usr/ssl/certs/ca-bundle.crt ]]; then
    pacman --noconfirm -S --asdeps ca-certificates
fi
echo "-------------------------------------------------------------------------------"
echo "updating msys2 done..."
echo "-------------------------------------------------------------------------------"

sleep 4

exit