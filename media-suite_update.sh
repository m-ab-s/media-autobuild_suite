echo -ne "\033]0;update autobuild suite\007"

while true; do
  case $1 in
--build32=* ) build32="${1#*=}"; shift ;;
--build64=* ) build64="${1#*=}"; shift ;;
    -- ) shift; break ;;
    -* ) echo "Error, unknown option: '$1'."; exit 1 ;;
    * ) break ;;
  esac
done

# --------------------------------------------------
# packet update system
# --------------------------------------------------

if [[ -f "/etc/pac-base-old.pk" ]] && [[ -f "/etc/pac-mingw32-old.pk" ]] || [[ -f "/etc/pac-mingw64-old.pk" ]]; then
	echo
	echo "-------------------------------------------------------------------------------"
	echo "check pacman packs..."
	echo "-------------------------------------------------------------------------------"
	echo
		
	sed -i 's/ /\n/g' /etc/pac-base-old.pk
	sed -i 's/ /\n/g' /etc/pac-base-new.pk
	oldBase=/etc/pac-base-old.pk
	newBase=/etc/pac-base-new.pk
	installBasePacks=`diff $oldBase $newBase | grep ">" | sed "s/> //g" | tr '\n' ' '` 
	removeBasePacks=`diff $oldBase $newBase | grep "<" | sed "s/< //g" | tr '\n' ' '`
	rm -f /etc/pac-base-old.pk

	if [[ $build32 = "yes" ]]; then
		sed -i 's/ /\n/g' /etc/pac-mingw32-old.pk
		sed -i 's/ /\n/g' /etc/pac-mingw32-new.pk
		oldMingw32=/etc/pac-mingw32-old.pk
		newMingw32=/etc/pac-mingw32-new.pk
		installMingw32Packs=`diff $oldMingw32 $newMingw32 | grep ">" | sed "s/> //g" | tr '\n' ' '` 
		removeMingw32Packs=`diff $oldMingw32 $newMingw32 | grep "<" | sed "s/< //g" | tr '\n' ' '`
		rm -f /etc/pac-mingw32-old.pk
	fi

	if [[ $build64 = "yes" ]]; then
		sed -i 's/ /\n/g' /etc/pac-mingw64-old.pk
		sed -i 's/ /\n/g' /etc/pac-mingw64-new.pk
		oldMingw64=/etc/pac-mingw64-old.pk
		newMingw64=/etc/pac-mingw64-new.pk
		installMingw64Packs=`diff $oldMingw64 $newMingw64 | grep ">" | sed "s/> //g" | tr '\n' ' '` 
		removeMingw64Packs=`diff $oldMingw64 $newMingw64 | grep "<" | sed "s/< //g" | tr '\n' ' '`
		rm -f /etc/pac-mingw64-old.pk
	fi

	if [[ ! "$installBasePacks" == "" ]] || [[ ! "$installMingw32Packs" == "" ]] || [[ ! "$installMingw64Packs" == "" ]]; then
		echo
		echo "-------------------------------------------------------------------------------"
		echo "You don't have the all the packs installed what the actual script need."
		echo "Do you want to install them?"
		echo "-------------------------------------------------------------------------------"
		echo
		while true; do
			read -p "install packs: $installBasePacks $installMingw32Packs $installMingw64Packs:" yn
			case $yn in
				[Yy]* ) pacman --noconfirm -S $installBasePacks $installMingw32Packs $installMingw64Packs; break;;
				[Nn]* ) exit;;
				* ) echo "Please answer yes or no";;
			esac
		done
	fi

	if [[ ! "$removeBasePacks" == "" ]] || [[ ! "$removeMingw32Packs" == "" ]] || [[ ! "$removeMingw64Packs" == "" ]]; then
		echo
		echo "-------------------------------------------------------------------------------"
		echo "You have more base packs installed then the actual compiler script need."
		echo "Do you want to remove them?"
		echo "-------------------------------------------------------------------------------"
		echo
		while true; do
			read -p "remove packs: $removeBasePacks $removeMingw32Packs $removeMingw64Packs:" yn
			case $yn in
				[Yy]* ) pacman --noconfirm -R $removeBasePacks $removeMingw32Packs $removeMingw64Packs; break;;
				[Nn]* ) exit;;
				* ) echo "Please answer yes or no";;
			esac
		done
	fi
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

		if ! cmp -s <(echo $newProfiles32) <(echo $oldProfiles32); then 
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

		if ! cmp -s <(echo $newProfiles64) <(echo $oldProfiles64); then 
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
pacman --noconfirm -Syu --force --ignoregroup base
pacman --noconfirm -Su --force
echo "-------------------------------------------------------------------------------"
echo "updating msys2 done..."
echo "-------------------------------------------------------------------------------"

sleep 4

exit