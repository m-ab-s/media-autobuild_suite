# set CPU count global. This can be overwrite from the compiler script (media-autobuild_suite.bat)
cpuCount=1
compile="false"
buildFFmpeg="false"
newFfmpeg="no"
FFMPEG_BASE_OPTS="--disable-debug --disable-doc --enable-gpl --disable-w32threads --enable-avisynth"
FFMPEG_DEFAULT_OPTS="--enable-librtmp --enable-gnutls --enable-frei0r --enable-libbluray --enable-libcaca \
--enable-libopenjpeg --enable-libass --enable-libgsm --enable-libilbc --enable-libmodplug --enable-libmp3lame \
--enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libvo-amrwbenc --enable-libschroedinger \
--enable-libsoxr --enable-libtwolame --enable-libspeex --enable-libtheora --enable-libvorbis \
--enable-libvo-aacenc --enable-libopus --enable-libvidstab --enable-libxavs --enable-libxvid \
--enable-libzvbi --enable-libdcadec --enable-libbs2b --enable-libmfx --enable-libcdio --enable-libfreetype \
--enable-fontconfig --enable-libfribidi --enable-opengl --enable-libvpx --enable-libx264 --enable-libx265 \
--enable-decklink --enable-libutvideo --enable-libgme \
--enable-nonfree --enable-nvenc --enable-libfdk-aac"
[[ ! -f "$LOCALBUILDDIR/last_run" ]] \
    && echo "bash $(cygpath -u $(cygpath -m /)../media-suite_compile.sh) $*" > "$LOCALBUILDDIR/last_run"
printf "$(date +"%F %T %z")\n" >> newchangelog

while true; do
  case $1 in
--cpuCount=* ) cpuCount="${1#*=}"; shift ;;
--build32=* ) build32="${1#*=}"; shift ;;
--build64=* ) build64="${1#*=}"; shift ;;
--mp4box=* ) mp4box="${1#*=}"; shift ;;
--ffmbc=* ) ffmbc="${1#*=}"; shift ;;
--vpx=* ) vpx="${1#*=}"; shift ;;
--x264=* ) x264="${1#*=}"; shift ;;
--x265=* ) x265="${1#*=}"; shift ;;
--other265=* ) other265="${1#*=}"; shift ;;
--flac=* ) flac="${1#*=}"; shift ;;
--mediainfo=* ) mediainfo="${1#*=}"; shift ;;
--sox=* ) sox="${1#*=}"; shift ;;
--ffmpeg=* ) ffmpeg="${1#*=}"; shift ;;
--ffmpegUpdate=* ) ffmpegUpdate="${1#*=}"; shift ;;
--ffmpegChoice=* ) ffmpegChoice="${1#*=}"; shift ;;
--mplayer=* ) mplayer="${1#*=}"; shift ;;
--mpv=* ) mpv="${1#*=}"; shift ;;
--deleteSource=* ) deleteSource="${1#*=}"; shift ;;
--nonfree=* ) nonfree="${1#*=}"; shift ;;
--stripping* ) stripping="${1#*=}"; shift ;;
--packing* ) packing="${1#*=}"; shift ;;
--xpcomp=* ) xpcomp="${1#*=}"; shift ;;
    -- ) shift; break ;;
    -* ) echo "Error, unknown option: '$1'."; exit 1 ;;
    * ) break ;;
  esac
done

# get git clone, or update
do_git() {
local gitURL="$1"
local gitFolder="$2"
local gitDepth="$3"
local gitBranch="$4"
local gitCheck="$5"
local unshallow=""
compile="true"

if [[ $gitDepth = "noDepth" ]]; then
    gitDepth=""
elif [[ $gitDepth = "shallow" ]] || [[ -z "$gitDepth" ]]; then
    gitDepth="--depth 1"
fi

if [ -z "$gitBranch" ]; then
    gitBranch="master"
fi

echo -ne "\033]0;compiling $gitFolder $bits\007"
if [ ! -d "$gitFolder"-git ]; then
    git clone $gitDepth -b "$gitBranch" "$gitURL" "$gitFolder"-git
    if [[ -d "$gitFolder"-git ]]; then
        cd "$gitFolder"-git
        touch recently_updated
    else
        echo "$gitFolder git seems to be down"
        echo "Try again later or <Enter> to continue"
        read -p "if you're sure nothing depends on it."
        compile="false"
    fi
else
    cd "$gitFolder"-git
    [[ "$gitDepth" = "" && -f .git/shallow ]] && unshallow="--unshallow"
    [[ $(git remote -v | grep origin | head -1 | awk '{print $2}') != "$gitURL" ]] &&
        git remote set-url origin "$gitURL"
    git reset --quiet --hard @{u}
    oldHead=$(git rev-parse HEAD)
    [[ $(git rev-parse --abbrev-ref HEAD) != "$gitBranch" ]] && git checkout "$gitBranch"
    git pull --no-edit $unshallow origin "$gitBranch"
    newHead=$(git rev-parse HEAD)

    pkg-config --exists "$gitFolder"
    local pcExists=$?

    if [[ "$oldHead" != "$newHead" ]]; then
        touch recently_updated
        rm -f build_successful*
        if [[ $build32 = "yes" && $build64 = "yes" ]] && [[ $bits = "64bit" ]]; then
            new_updates="yes"
            new_updates_packages="$new_updates_packages [$gitFolder]"
        fi
        echo "$gitFolder" >> "$LOCALBUILDDIR"/newchangelog
        git log --no-merges --pretty="%ci %h %s" \
            --abbrev-commit "$oldHead".."$newHead" >> "$LOCALBUILDDIR"/newchangelog
        echo "" >> "$LOCALBUILDDIR"/newchangelog
    elif [[ -f recently_updated && ! -f build_successful$bits ]] ||
         [[ -z "$gitCheck" && $pcExists = 1 ]] ||
         [[ ! -z "$gitCheck" && ! -f $LOCALDESTDIR/"$gitCheck" ]]; then
        compile="true"
    else
        echo -------------------------------------------------
        echo "$gitFolder is already up to date"
        echo -------------------------------------------------
        compile="false"
    fi
fi
}

# get svn checkout, or update
do_svn() {
local svnURL="$1"
local svnFolder="$2"
local svnCheck="$3"
compile="true"
echo -ne "\033]0;compiling $svnFolder $bits\007"
if [ ! -d "$svnFolder"-svn ]; then
    svn checkout "$svnURL" "$svnFolder"-svn
    if [[ -d "$svnFolder"-svn ]]; then
        cd "$svnFolder"-svn
        touch recently_updated
    else
        echo "$svnFolder svn seems to be down"
        echo "Try again later or <Enter> to continue"
        read -p "if you're sure nothing depends on it."
        compile="false"
    fi
else
    cd "$svnFolder"-svn
    oldRevision=$(svnversion)
    svn update
    newRevision=$(svnversion)

    pkg-config --exists "$svnFolder"
    local pcExists=$?

    if [[ "$oldRevision" != "$newRevision" ]]; then
        touch recently_updated
        rm -f build_successful*
        if [[ $build32 = "yes" && $build64 = "yes" ]] && [[ $bits = "64bit" ]]; then
            new_updates="yes"
            new_updates_packages="$new_updates_packages [$svnFolder]"
        fi
    elif [[ -f recently_updated && ! -f build_successful$bits ]] ||
         [[ -z "$svnCheck" && $pcExists = 1 ]] ||
         [[ ! -z "$svnCheck" && ! -f $LOCALDESTDIR/"$svnCheck" ]]; then
        compile="true"
    else
        echo -------------------------------------------------
        echo "$svnFolder is already up to date"
        echo -------------------------------------------------
        compile="false"
    fi
fi
}

# get hg clone, or update
do_hg() {
local hgURL="$1"
local hgFolder="$2"
local hgCheck="$3"
compile="true"
echo -ne "\033]0;compiling $hgFolder $bits\007"
if [ ! -d "$hgFolder"-hg ]; then
    hg clone "$hgURL" "$hgFolder"-hg
    if [[ -d "$hgFolder"-hg ]]; then
        cd "$hgFolder"-hg
        touch recently_updated
    else
        echo "$hgFolder hg seems to be down"
        echo "Try again later or <Enter> to continue"
        read -p "if you're sure nothing depends on it."
        compile="false"
    fi
else
    cd "$hgFolder"-hg
    oldHead=$(hg id --id)
    hg pull
    hg update
    newHead=$(hg id --id)

    pkg-config --exists "$hgFolder"
    local pcExists=$?

    if [[ "$oldHead" != "$newHead" ]]; then
        touch recently_updated
        rm -f build_successful*
        if [[ $build32 = "yes" && $build64 = "yes" ]] && [[ $bits = "64bit" ]]; then
            new_updates="yes"
            new_updates_packages="$new_updates_packages [$hgFolder]"
        fi
        echo "$hgFolder" >> "$LOCALBUILDDIR"/newchangelog
        hg log --template "{date|localdate|isodatesec} {node|short} {desc|firstline}\n" \
            -r "reverse($oldHead:$newHead)" >> "$LOCALBUILDDIR"/newchangelog
        echo "" >> "$LOCALBUILDDIR"/newchangelog
    elif [[ -f recently_updated && ! -f build_successful$bits ]] ||
         [[ -z "$hgCheck" && $pcExists = 1 ]] ||
         [[ ! -z "$hgCheck" && ! -f $LOCALDESTDIR/"$hgCheck" ]]; then
         compile="true"
    else
        echo -------------------------------------------------
        echo "$hgFolder is already up to date"
        echo -------------------------------------------------
        compile="false"
    fi
fi
}

# get wget download
do_wget() {
    local url="$1"
    local archive="$2"
    local dirName="$3"
    if [[ -z $archive ]]; then
        # remove arguments and filepath
        archive=${url%%\?*}
        archive=${archive##*/}
    fi
    # accepted: zip, 7z, tar.gz, tar.bz2 and tar.xz
    local archive_type=$(expr $archive : '.\+\(tar\(\.\(gz\|bz2\|xz\)\)\?\|7z\|zip\)$')
    [[ -z "$dirName" ]] && dirName=$(expr $archive : '\(.\+\)\.\(tar\(\.\(gz\|bz2\|xz\)\)\?\|7z\|zip\)$')
    if [[ -d "$dirName" && $archive_type = tar* ]] &&
        { [[ $build32 = "yes" && ! -f "$dirName"/build_successful32bit ]] ||
          [[ $build64 = "yes" && ! -f "$dirName"/build_successful64bit ]]; }; then
        rm -rf $dirName
    fi
    local response_code=$(curl --retry 20 --retry-max-time 5 -L -k -f -w "%{response_code}" -o "$archive" "$url")
    if [[ $response_code = "200" || $response_code = "226" ]]; then
        case $archive_type in
        zip)
            unzip "$archive"
            rm "$archive"
            ;;
        7z)
            7z x -o"$dirName" "$archive"
            rm "$archive"
            ;;
        tar*)
            tar -xaf "$archive"
            rm "$archive"
            cd "$dirName"
            ;;
        esac
    elif [[ $response_code -gt 400 ]]; then
        echo "Error $response_code while downloading $URL"
        echo "Try again later or <Enter> to continue"
        read -p "if you're sure nothing depends on it."
    fi
}

# check if compiled file exist
do_checkIfExist() {
    local packetName="$1"
    local fileName="$2"
    local fileExtension=${fileName##*.}
    local buildSuccess="n"

    if [[ "$fileExtension" = "a" ]] || [[ "$fileExtension" = "dll" ]]; then
        if [ -f "$LOCALDESTDIR/lib/$fileName" ]; then
            buildSuccess="y"
        fi
    else
        if [ -f "$LOCALDESTDIR/$fileName" ]; then
            buildSuccess="y"
        fi
    fi
    
    if [[ $buildSuccess = "y" ]]; then
        echo -
        echo -------------------------------------------------
        echo "build $packetName done..."
        echo -------------------------------------------------
        echo -
        if [[ -d "$LOCALBUILDDIR/$packetName" ]]; then
            touch $LOCALBUILDDIR/$packetName/build_successful$bits
        fi
    else
        if [[ -d "$LOCALBUILDDIR/$packetName" ]]; then
            rm -f $LOCALBUILDDIR/$packetName/build_successful$bits
        fi
        echo -------------------------------------------------
        echo "Build of $packetName failed..."
        echo "Delete the source folder under '$LOCALBUILDDIR' and start again."
        echo "If you're sure there are no dependencies <Enter> to continue building."
        read -p "Close this window if you wish to stop building."
    fi
}

do_pkgConfig() {
    local pkg=${1%% *}
    echo -ne "\033]0;compiling $pkg $bits\007"

    if pkg-config --exists "$1"; then
        echo -------------------------------------------------
        echo "$pkg is already compiled"
        echo -------------------------------------------------
        return 1
    fi
}

do_getFFmpegConfig() {
    configfile="$LOCALBUILDDIR"/ffmpeg_options.txt
    if [[ -f "$configfile" ]] && [[ $ffmpegChoice = "y" ]]; then
        FFMPEG_OPTS="$FFMPEG_BASE_OPTS $(cat "$configfile" | sed -e 's:\\::g' -e 's/#.*//')"
    else
        FFMPEG_OPTS="$FFMPEG_BASE_OPTS $FFMPEG_DEFAULT_OPTS"
    fi

    if [[ $bits = "32bit" ]]; then
        arch=x86
    else
        arch=x86_64
    fi
    export arch

    # add options if ffmbc is being compiled
    if [[ $ffmbc = "y" ]]; then
        do_addOption "--enable-librtmp"
        do_addOption "--enable-frei0r"
        do_addOption "--enable-libopenjpeg"
        do_addOption "--enable-libass"
        do_addOption "--enable-libspeex"
        do_addOption "--enable-libtheora"
        do_addOption "--enable-libvorbis"
        do_addOption "--enable-libxavs"
        do_addOption "--enable-libmp3lame"
        do_addOption "--enable-libfaac"
    fi

    # add options for mplayer
    if [[ $mplayer = "y" ]]; then
        do_addOption "--enable-libfreetype"
        do_addOption "--enable-libbluray"
        do_addOption "--enable-libfaac"
    fi

    # prefer openssl if in options
    if do_checkForOptions "--enable-openssl" && [[ $nonfree = "y" ]]; then
        do_removeOption "--enable-gnutls"
    elif do_checkForOptions "--enable-openssl"; then
        do_removeOption "--enable-openssl"
        do_addOption "--enable-gnutls"
    fi
}

do_changeFFmpegConfig() {
    # add options for static modplug
    if do_checkForOptions "--enable-libmodplug"; then
        do_addOption "--extra-cflags=-DMODPLUG_STATIC"
    fi

    # handle gplv3 libs
    if do_checkForOptions "--enable-libopencore-amrwb --enable-libopencore-amrnb \
        --enable-libvo-aacenc --enable-libvo-amrwbenc"; then
        do_addOption "--enable-version3"
    fi

    # handle non-free libs
    if [[ $nonfree = "y" ]] && do_checkForOptions "--enable-libfdk-aac --enable-nvenc \
        --enable-libfaac --enable-openssl"; then
        do_addOption "--enable-nonfree"
    else
        do_removeOption "--enable-nonfree"
        do_removeOption "--enable-libfdk-aac"
        do_removeOption "--enable-nvenc"
        do_removeOption "--enable-libfaac"
    fi

    # remove libs that don't work with shared
    if [[ $ffmpeg = "s" || $ffmpeg = "b" ]]; then
        FFMPEG_OPTS_SHARED=$FFMPEG_OPTS
        do_removeOption "--enable-decklink" y
        do_removeOption "--enable-libutvideo" y
        do_removeOption "--enable-libgme" y
    fi
}

do_checkForOptions() {
    local isPresent=1
    for option in "$@"; do
        for option2 in $option; do
            if echo "$FFMPEG_OPTS" | grep -q -E -e "$option2"; then
                isPresent=0
            fi
        done
    done
    return $isPresent
}

do_addOption() {
    local option=${1%% *}
    if ! do_checkForOptions "$option"; then
        FFMPEG_OPTS="$FFMPEG_OPTS $option"
    fi
}

do_removeOption() {
    local option=${1%% *}
    local shared=$2
    if [[ $shared = "y" ]]; then
        FFMPEG_OPTS_SHARED=$(echo "$FFMPEG_OPTS_SHARED" | sed "s/ *$option//g")
    else
        FFMPEG_OPTS=$(echo "$FFMPEG_OPTS" | sed "s/ *$option//g")
    fi
}

do_patch() {
    local patch=${1%% *}
    local strip=$2
    if [[ -z $strip ]]; then
        strip="1"
    fi
    local response_code="$(curl --retry 20 --retry-max-time 5 -L -k -f -w "%{response_code}" \
        -O "https://raw.github.com/jb-alvarado/media-autobuild_suite/master/patches/$patch")"

    if [[ $response_code = "404" ]]; then
        echo "Patch not found online. Trying local patch. Probably not up-to-date."
        iPath=$(cygpath -w /)
        if [ -f ./"$patch" ]; then
            patch -N -p$strip -i "$patch"
        elif [ -f "$iPath/../patches/$patch" ]; then
            patch -N -p$strip -i "$iPath/../patches/$patch"
        else
            echo "No local patch found. Moving on without patching."
        fi
    elif [[ $response_code = "200" ]]; then
        patch -N -p$strip -i "$patch"
    else
        echo "No patch found anywhere. Moving on without patching."
    fi
}

do_cmake() {
    local source=$1
    shift 1
    if [ -d "build" ]; then
        rm -rf ./build/*
    else
        mkdir build
    fi
    cd build
    cmake $source -G "MSYS Makefiles" -DBUILD_SHARED_LIBS:bool=off \
    -DCMAKE_INSTALL_PREFIX=$LOCALDESTDIR -DUNIX:bool=on "$@"
}

do_generic_confmakeinstall() {
    local bindir=""
    case "$1" in
    global)
        bindir="--bindir=$LOCALDESTDIR/bin-global"
        ;;
    audio)
        bindir="--bindir=$LOCALDESTDIR/bin-audio"
        ;;
    video)
        bindir="--bindir=$LOCALDESTDIR/bin-video"
        ;;
    *)
        bindir="$1"
        ;;
    esac
    shift 1
    do_generic_conf $bindir "$@"
    do_makeinstall
}

do_generic_conf() {
    ./configure --build=$targetBuild --prefix=$LOCALDESTDIR --disable-shared "$@"
}

do_makeinstall() {
    make -j $cpuCount "$@"
    make install
}

buildProcess() {
cd $LOCALBUILDDIR
echo "-------------------------------------------------------------------------------"
echo
echo "compile global tools $bits"
echo
echo "-------------------------------------------------------------------------------"

do_getFFmpegConfig

if do_checkForOptions "--enable-libopenjpeg" && do_pkgConfig "libopenjpeg1 = 1.5.2"; then
    do_wget "http://downloads.sourceforge.net/project/openjpeg.mirror/1.5.2/openjpeg-1.5.2.tar.gz"

    if [[ -d $LOCALDESTDIR/lib/openjpeg-1.5 ]]; then
        rm -rf $LOCALDESTDIR/include/openjpeg-1.5 $LOCALDESTDIR/include/openjpeg.h
        rm -f $LOCALDESTDIR/lib/libopenj{peg{,_JPWL},pip_local}.a
        rm -f $LOCALDESTDIR/lib/pkgconfig/libopenjpeg1.pc
        rm -rf $LOCALDESTDIR/lib/openjpeg-1.5
    fi
    do_cmake .. -DBUILD_MJ2:BOOL=on -DBUILD_JPWL:BOOL=on -DBUILD_JPIP:BOOL=on \
    -DBUILD_THIRDPARTY:BOOL=on -DOPENJPEG_INSTALL_BIN_DIR=$LOCALDESTDIR/bin-global \
    -DCMAKE_C_FLAGS="-mms-bitfields -mthreads -mtune=generic -pipe -DOPJ_STATIC"
    do_makeinstall
    do_checkIfExist openjpeg-1.5.2 libopenjpeg.a
fi

if do_checkForOptions "--enable-libfreetype --enable-libbluray --enable-libass" && \
    do_pkgConfig "freetype2 = 17.4.11"; then
    cd $LOCALBUILDDIR
    do_wget "http://downloads.sourceforge.net/project/freetype/freetype2/2.5.5/freetype-2.5.5.tar.bz2"

    if [[ -f "objs/.libs/libfreetype.a" ]]; then
        make distclean
    fi
    if [[ -d "$LOCALDESTDIR/include/freetype2" ]]; then
        rm -rf $LOCALDESTDIR/include/freetype2 $LOCALDESTDIR/bin-global/freetype-config
        rm -rf $LOCALDESTDIR/lib/libfreetype.{l,}a $LOCALDESTDIR/lib/pkgconfig/freetype.pc
    fi
    do_generic_confmakeinstall global --with-harfbuzz=no
    do_checkIfExist freetype-2.5.5 libfreetype.a
fi

if do_checkForOptions "--enable-fontconfig --enable-libbluray --enable-libass" && \
    do_pkgConfig "fontconfig = 2.11.92"; then
    cd $LOCALBUILDDIR
    do_wget "http://www.freedesktop.org/software/fontconfig/release/fontconfig-2.11.92.tar.gz"

    if [[ -f "src/.libs/libfontconfig.a" ]]; then
        make distclean
    fi
    if [[ -d "$LOCALDESTDIR/include/fontconfig" ]]; then
        rm -rf $LOCALDESTDIR/include/fontconfig $LOCALDESTDIR/bin-global/fc-*
        rm -rf $LOCALDESTDIR/lib/libfontconfig.{l,}a $LOCALDESTDIR/lib/pkgconfig/fontconfig.pc
    fi
    do_generic_confmakeinstall global
    do_checkIfExist fontconfig-2.11.92 libfontconfig.a
fi

if do_checkForOptions "--enable-libfribidi --enable-libass" && do_pkgConfig "fribidi = 0.19.6"; then
    cd $LOCALBUILDDIR
    do_wget "http://fribidi.org/download/fribidi-0.19.6.tar.bz2"

    if [[ -f "lib/.libs/libfribidi.a" ]]; then
        make distclean
    fi
    if [[ -d "$LOCALDESTDIR/include/fribidi" ]]; then
        rm -rf $LOCALDESTDIR/include/fribidi $LOCALDESTDIR/bin-global/fribidi*
        rm -rf $LOCALDESTDIR/lib/libfribidi.{l,}a $LOCALDESTDIR/lib/pkgconfig/fribidi.pc
    fi
    do_generic_confmakeinstall global --enable-static --disable-deprecated --with-glib=no
    do_checkIfExist fribidi-0.19.6 libfribidi.a
fi

if do_checkForOptions "--enable-libass"; then
    if $LOCALDESTDIR/bin-global/ragel --version | grep -q -e "version 6.9"; then
        echo -------------------------------------------------
        echo "ragel-6.9 is already compiled"
        echo -------------------------------------------------
    else
        cd $LOCALBUILDDIR
        echo -ne "\033]0;compile ragel $bits\007"

        do_wget "http://www.colm.net/files/ragel/ragel-6.9.tar.gz"

        if [[ -f "ragel/ragel.exe" ]]; then
            make distclean
        fi
        if [[ -f "$LOCALDESTDIR/bin-global/ragel.exe" ]]; then
            rm -rf $LOCALDESTDIR/bin-global/ragel.exe
        fi
        do_generic_confmakeinstall global
        do_checkIfExist ragel-6.9 bin-global/ragel.exe
    fi

    cd $LOCALBUILDDIR
    do_git "git://anongit.freedesktop.org/harfbuzz" harfbuzz
    if [[ $compile = "true" ]]; then
        if [[ ! -f "configure" ]]; then
            ./autogen.sh -V
        else
            rm -rf $LOCALDESTDIR/include/harfbuzz $LOCALDESTDIR/bin-global/hb-fc-list.exe
            rm -rf $LOCALDESTDIR/lib/libharfbuzz.{l,}a $LOCALDESTDIR/lib/pkgconfig/harfbuzz.pc
            make distclean
        fi
        do_generic_confmakeinstall global --with-icu=no --with-glib=no --with-gobject=no \
        LDFLAGS="$LDFLAGS -static -static-libgcc -static-libstdc++"
        do_checkIfExist harfbuzz-git libharfbuzz.a
    fi
fi

if ! do_checkForOptions "--disable-sdl --disable-ffplay" && do_pkgConfig "sdl = 1.2.15"; then
    cd $LOCALBUILDDIR
    do_wget "http://www.libsdl.org/release/SDL-1.2.15.tar.gz"

    if [[ -f "build/.libs/libSDL.a" ]]; then
        make distclean
    fi
    if [[ -d "$LOCALDESTDIR/include/SDL" ]]; then
        rm -rf $LOCALDESTDIR/include/SDL $LOCALDESTDIR/bin-global/sdl-config
        rm -rf $LOCALDESTDIR/lib/libSDL{,main}.{l,}a $LOCALDESTDIR/lib/pkgconfig/sdl.pc
    fi
    CFLAGS="-DDECLSPEC=" do_generic_confmakeinstall global
    sed -i "s/-mwindows//" "$LOCALDESTDIR/bin-global/sdl-config"
    sed -i "s/-mwindows//" "$LOCALDESTDIR/lib/pkgconfig/sdl.pc"
    do_checkIfExist SDL-1.2.15 libSDL.a
fi

#----------------------
# crypto engine
#----------------------

if do_checkForOptions "--enable-gnutls --enable-librtmp" ; then
    if [[ `libgcrypt-config --version` = "1.6.3" ]]; then
        echo -------------------------------------------------
        echo "libgcrypt-1.6.3 is already compiled"
        echo -------------------------------------------------
    else
        cd $LOCALBUILDDIR
        echo -ne "\033]0;compile libgcrypt $bits\007"

        do_wget "ftp://ftp.gnupg.org/gcrypt/libgcrypt/libgcrypt-1.6.3.tar.bz2"

        if [[ -f "src/.libs/libgcrypt.a" ]]; then
            make distclean
        fi
        if [[ -f "$LOCALDESTDIR/include/libgcrypt.h" ]]; then
            rm -f $LOCALDESTDIR/include/libgcrypt.h
            rm -f $LOCALDESTDIR/bin-global/{dumpsexp,hmac256,mpicalc}.exe
            rm -f $LOCALDESTDIR/lib/libgcrypt.{l,}a $LOCALDESTDIR/bin-global/libgcrypt-config
        fi
        if [[ $bits = "64bit" ]]; then
            extracommands="--disable-asm --disable-padlock-support"
        else
            extracommands=""
        fi
        do_generic_confmakeinstall global --with-gpg-error-prefix=$MINGW_PREFIX $extracommands
        do_checkIfExist libgcrypt-1.6.3 libgcrypt.a
    fi

    if do_pkgConfig "nettle = 2.7.1"; then
        cd $LOCALBUILDDIR
        do_wget "https://ftp.gnu.org/gnu/nettle/nettle-2.7.1.tar.gz"

        if [[ -f "libnettle.a" ]]; then
            make distclean
        fi
        if [[ -d "$LOCALDESTDIR/include/nettle" ]]; then
            rm -rf $LOCALDESTDIR/include/nettle $LOCALDESTDIR/bin-global/nettle-*.exe
            rm -rf $LOCALDESTDIR/lib/libnettle.a $LOCALDESTDIR/lib/pkgconfig/nettle.pc
        fi
        do_generic_confmakeinstall global --disable-documentation --disable-openssl
        do_checkIfExist nettle-2.7.1 libnettle.a
    fi

    if do_pkgConfig "gnutls = 3.3.15"; then
        cd $LOCALBUILDDIR
        do_wget "ftp://ftp.gnutls.org/gcrypt/gnutls/v3.3/gnutls-3.3.15.tar.xz"

        if [[ -f "lib/.libs/libgnutls.a" ]]; then
            make distclean
        fi
        if [[ -d "$LOCALDESTDIR/include/gnutls" ]]; then
            rm -rf $LOCALDESTDIR/include/gnutls $LOCALDESTDIR/bin-global/gnutls-*.exe
            rm -rf $LOCALDESTDIR/lib/libgnutls* $LOCALDESTDIR/lib/pkgconfig/gnutls.pc
        fi
        do_generic_confmakeinstall global --disable-guile --enable-cxx --disable-doc \
        --disable-tests --with-zlib --without-p11-kit --disable-rpath --disable-gtk-doc \
        --disable-libdane --enable-local-libopts
        sed -i 's/-lgnutls *$/-lgnutls -lnettle -lhogweed -liconv -lcrypt32 -lws2_32 -lz -lgmp -lintl/' \
        $LOCALDESTDIR/lib/pkgconfig/gnutls.pc
        do_checkIfExist gnutls-3.3.15 libgnutls.a
    fi
fi

if do_checkForOptions "--enable-librtmp"; then
    cd $LOCALBUILDDIR
    do_git "git://repo.or.cz/rtmpdump.git" librtmp shallow master lib/pkgconfig/librtmp.pc
    if [[ $compile = "true" ]]; then
        if [ -f "$LOCALDESTDIR/lib/librtmp.a" ]; then
            rm -rf $LOCALDESTDIR/include/librtmp
            rm -f $LOCALDESTDIR/lib/librtmp.a $LOCALDESTDIR/lib/pkgconfig/librtmp.pc
            rm -f $LOCALDESTDIR/bin-video/rtmp{dump,suck,srv,w}.exe
        fi
        if [[ -f "librtmp/librtmp.a" ]]; then
            make clean
        fi

        make XCFLAGS="$CFLAGS -I$MINGW_PREFIX/include" XLDFLAGS="$LDFLAGS" CRYPTO=GNUTLS \
        SHARED= SYS=mingw LIB_GNUTLS="$(pkg-config --libs gnutls)" prefix=$LOCALDESTDIR \
        bindir=$LOCALDESTDIR/bin-video sbindir=$LOCALDESTDIR/bin-video install

        do_checkIfExist librtmp-git librtmp.a
    fi
fi

if [[ $sox = "y" ]]; then
    if [ -f "$LOCALDESTDIR/lib/libgnurx.a" ]; then
        echo -------------------------------------------------
        echo "libgnurx-2.5.1 is already compiled"
        echo -------------------------------------------------
    else
        cd $LOCALBUILDDIR
        echo -ne "\033]0;compile libgnurx $bits\007"
        do_wget "http://sourceforge.net/projects/mingw/files/Other/UserContributed/regex/mingw-regex-2.5.1/mingw-libgnurx-2.5.1-src.tar.gz/download" \
            mingw-libgnurx-2.5.1.tar.gz
        if [[ -f "libgnurx.a" ]]; then
            make distclean
        fi
        if [[ -f "$LOCALDESTDIR/lib/libgnurx.a" ]]; then
            rm -f $LOCALDESTDIR/lib/lib{gnurx,regex}.a
            rm -f $LOCALDESTDIR/include/regex.h
        fi
        do_patch "libgnurx-1-additional-makefile-rules.patch"
        ./configure --prefix=$LOCALDESTDIR --disable-shared
        do_makeinstall -f Makefile.mxe install-static
        do_checkIfExist mingw-libgnurx-2.5.1 libgnurx.a
    fi

    if $LOCALDESTDIR/bin-global/file --version | grep -q -e "file.exe-5.24"; then
        echo -------------------------------------------------
        echo "file-5.24[libmagic] is already compiled"
        echo -------------------------------------------------
    else
        cd $LOCALBUILDDIR
        echo -ne "\033]0;compile file $bits\007"
        do_wget "https://fossies.org/linux/misc/file-5.24.tar.gz"
        if [[ -f "src/.libs/libmagic.a" ]]; then
            make distclean
        fi
        if [[ -f "$LOCALDESTDIR/lib/libmagic.a" ]]; then
            rm -rf $LOCALDESTDIR/include/magic.h $LOCALDESTDIR/bin-global/file.exe
            rm -rf $LOCALDESTDIR/lib/libmagic.{l,}a
        fi
        do_patch "file-1-fixes.patch"
        do_generic_confmakeinstall global CFLAGS=-DHAVE_PREAD
        do_checkIfExist file-5.24 libmagic.a
    fi
fi

echo "-------------------------------------------------------------------------------"
echo
echo "compile global tools $bits done..."
echo
echo "-------------------------------------------------------------------------------"

echo "-------------------------------------------------------------------------------"
echo
echo "compile audio tools $bits"
echo
echo "-------------------------------------------------------------------------------"

if do_checkForOptions "--enable-libdcadec"; then
    cd $LOCALBUILDDIR
    do_git "https://github.com/foo86/dcadec.git" dcadec
    if [[ $compile = "true" ]]; then
        if [[ -d $LOCALDESTDIR/include/libdcadec ]]; then
            rm -rf $LOCALDESTDIR/include/libdcadec
            rm -f $LOCALDESTDIR/lib/libdcadec.a
            rm -f $LOCALDESTDIR/lib/pkgconfig/dcadec.pc
            rm -f $LOCALDESTDIR/bin-audio/dcadec.exe
        fi

        if [[ -f libdcadec/libdcadec.a ]]; then
            make clean
        fi

        make CONFIG_WINDOWS=1 LDFLAGS=-lm lib
        make PREFIX=$LOCALDESTDIR PKG_CONFIG_PATH=$LOCALDESTDIR/lib/pkgconfig install-lib
        do_checkIfExist dcadec-git libdcadec.a
    fi
fi

if do_checkForOptions "--enable-libilbc"; then
    cd $LOCALBUILDDIR
    do_git "https://github.com/TimothyGu/libilbc.git" libilbc
    if [[ $compile = "true" ]]; then
        if [[ ! -f "configure" ]]; then
            autoreconf -fiv
        else
            rm -rf $LOCALDESTDIR/include/ilbc.h
            rm -rf $LOCALDESTDIR/lib/libilbc.{l,}a $LOCALDESTDIR/lib/pkgconfig/libilbc.pc
            make distclean
        fi
        do_generic_confmakeinstall
        do_checkIfExist libilbc-git libilbc.a
    fi
fi

if do_checkForOptions "--enable-libtheora --enable-libvorbis --enable-libspeex" ||
    [[ $flac = "y" ]] && do_pkgConfig "ogg = 1.3.2"; then
    cd $LOCALBUILDDIR
    do_wget "http://downloads.xiph.org/releases/ogg/libogg-1.3.2.tar.gz"

    if [[ -f "./src/.libs/libogg.a" ]]; then
        make distclean
    fi
    if [[ -d "$LOCALDESTDIR/include/ogg" ]]; then
        rm -rf $LOCALDESTDIR/include/ogg $LOCALDESTDIR/share/aclocal/ogg.m4
        rm -rf $LOCALDESTDIR/lib/libogg.{l,}a $LOCALDESTDIR/lib/pkgconfig/ogg.pc
    fi
    do_generic_confmakeinstall
    do_checkIfExist libogg-1.3.2 libogg.a
fi

if do_checkForOptions "--enable-libvorbis --enable-libtheora" || [[ $sox = "y" ]] ||
    do_pkgConfig "vorbis = 1.3.5"; then
    cd $LOCALBUILDDIR
    do_wget "http://downloads.xiph.org/releases/vorbis/libvorbis-1.3.5.tar.gz"

    if [[ -f "./lib/.libs/libvorbis.a" ]]; then
        make distclean
    fi
    if [[ -d "$LOCALDESTDIR/include/vorbis" ]]; then
        rm -rf $LOCALDESTDIR/include/vorbis $LOCALDESTDIR/share/aclocal/vorbis.m4
        rm -f $LOCALDESTDIR/lib/libvorbis{,enc,file}.{l,}a
        rm -f $LOCALDESTDIR/lib/pkgconfig/vorbis{,enc,file}.pc
    fi
    do_generic_confmakeinstall
    do_checkIfExist libvorbis-1.3.5 libvorbis.a
fi

if do_checkForOptions "--enable-libopus" || [[ $sox = "y" ]] && do_pkgConfig "opus = 1.1"; then
    cd $LOCALBUILDDIR
    do_wget "http://downloads.xiph.org/releases/opus/opus-1.1.tar.gz"

    if [[ -f ".libs/libopus.a" ]]; then
        make distclean
    fi
    if [[ -d "$LOCALDESTDIR/include/opus" ]]; then
        rm -rf $LOCALDESTDIR/include/opus
        rm -rf $LOCALDESTDIR/lib/libopus.{l,}a $LOCALDESTDIR/lib/pkgconfig/opus.pc
    fi

    do_patch "opus11.patch"
    do_generic_confmakeinstall --disable-doc
    do_checkIfExist opus-1.1 libopus.a
fi

if do_checkForOptions "--enable-libspeex" && do_pkgConfig "speex = 1.2rc2"; then
    cd $LOCALBUILDDIR
    do_wget "http://downloads.xiph.org/releases/speex/speex-1.2rc2.tar.gz"

    if [[ -f "libspeex/.libs/libspeex.a" ]]; then
        make distclean
    fi
    if [[ -d "$LOCALDESTDIR/include/speex" ]]; then
        rm -rf $LOCALDESTDIR/include/speex $LOCALDESTDIR/bin-audio/speex{enc,dec}.exe
        rm -rf $LOCALDESTDIR/lib/libspeex.{l,}a $LOCALDESTDIR/lib/pkgconfig/speex.pc
    fi
    do_patch speex-mingw-winmm.patch
    do_generic_confmakeinstall audio --enable-vorbis-psy --enable-binaries
    do_checkIfExist speex-1.2rc2 libspeex.a
fi

if do_checkForOptions "--enable-libopus" || [[ $flac = "y" ]] ||
    [[ $sox = "y" ]] &&
    [[ ! -f $LOCALDESTDIR/bin-audio/flac.exe ]] || do_pkgConfig "flac = 1.3.1"; then
    cd $LOCALBUILDDIR
    do_wget "http://downloads.xiph.org/releases/flac/flac-1.3.1.tar.xz"

    if [[ -f "src/libFLAC/.libs/libFLAC.a" ]]; then
        make distclean
    fi
    if [[ -d "$LOCALDESTDIR/include/FLAC" ]]; then
        rm -rf $LOCALDESTDIR/include/FLAC{,++} $LOCALDESTDIR/bin-audio/{meta,}flac.exe
        rm -rf $LOCALDESTDIR/lib/libFLAC.{l,}a $LOCALDESTDIR/lib/pkgconfig/flac{,++}.pc
    fi
    do_generic_confmakeinstall audio --disable-xmms-plugin --disable-doxygen-docs
    do_checkIfExist flac-1.3.1 bin-audio/flac.exe
fi

if do_checkForOptions "--enable-libvo-aacenc" && do_pkgConfig "vo-aacenc = 0.1.3"; then
    cd $LOCALBUILDDIR
    do_wget "http://sourceforge.net/projects/opencore-amr/files/vo-aacenc/vo-aacenc-0.1.3.tar.gz/download" vo-aacenc-0.1.3.tar.gz

    if [[ -f ".libs/libvo-aacenc.a" ]]; then
        make distclean
    fi
    if [[ -d "$LOCALDESTDIR/include/vo-aacenc" ]]; then
        rm -rf $LOCALDESTDIR/include/vo-aacenc
        rm -rf $LOCALDESTDIR/lib/libvo-aacenc.{l,}a $LOCALDESTDIR/lib/pkgconfig/vo-aacenc.pc
    fi
    do_generic_confmakeinstall
    do_checkIfExist vo-aacenc-0.1.3 libvo-aacenc.a
fi

if do_checkForOptions "--enable-libopencore-amr(wb|nb)" && do_pkgConfig "opencore-amrnb = 0.1.3 \
    opencore-amrwb = 0.1.3"; then
    cd $LOCALBUILDDIR
    do_wget "http://downloads.sourceforge.net/project/opencore-amr/opencore-amr/opencore-amr-0.1.3.tar.gz"

    if [[ -f "amrnb/.libs/libopencore-amrnb.a" ]]; then
        make distclean
    fi
    if [[ -d "$LOCALDESTDIR/include/opencore-amrnb" ]]; then
        rm -rf $LOCALDESTDIR/include/opencore-amr{nb,wb}
        rm -r $LOCALDESTDIR/lib/libopencore-amr{nb,wb}.{l,}a
        rm -f $LOCALDESTDIR/lib/pkgconfig/opencore-amr{nb,wb}.pc
    fi
    do_generic_confmakeinstall
    do_checkIfExist opencore-amr-0.1.3 libopencore-amrnb.a
fi

if do_checkForOptions "--enable-libvo-amrwbenc" && do_pkgConfig "vo-amrwbenc = 0.1.2"; then
    cd $LOCALBUILDDIR
    do_wget "http://downloads.sourceforge.net/project/opencore-amr/vo-amrwbenc/vo-amrwbenc-0.1.2.tar.gz"

    if [[ -f ".libs/libvo-amrwbenc.a" ]]; then
        make distclean
    fi
    if [[ -d "$LOCALDESTDIR/include/vo-amrwbenc" ]]; then
        rm -rf $LOCALDESTDIR/include/vo-amrwbenc
        rm -rf $LOCALDESTDIR/lib/libvo-amrwbenc.{l,}a $LOCALDESTDIR/lib/pkgconfig/vo-amrwbenc.pc
    fi
    do_generic_confmakeinstall
    do_checkIfExist vo-amrwbenc-0.1.2 libvo-amrwbenc.a
fi

if do_checkForOptions "--enable-libfdk-aac"; then
    cd $LOCALBUILDDIR
    do_git "https://github.com/mstorsjo/fdk-aac" fdk-aac
    if [[ $compile = "true" ]]; then
        if [[ ! -f ./configure ]]; then
            ./autogen.sh
        else
            rm -rf $LOCALDESTDIR/include/fdk-aac
            rm -rf $LOCALDESTDIR/lib/libfdk-aac.{l,}a $LOCALDESTDIR/lib/pkgconfig/fdk-aac.pc
            make distclean
        fi
        CXXFLAGS+=" -O2 -fno-exceptions -fno-rtti" do_generic_confmakeinstall
        do_checkIfExist fdk-aac-git libfdk-aac.a
    fi

    cd $LOCALBUILDDIR
    do_git "https://github.com/nu774/fdkaac" bin-fdk-aac shallow master bin-audio/fdkaac.exe
    if [[ $compile = "true" ]]; then
        if [[ ! -f ./configure ]]; then
            autoreconf -i
        else
            rm -f $LOCALDESTDIR/bin-audio/fdkaac.exe
            make distclean
        fi
        CXXFLAGS+=" -O2" do_generic_confmakeinstall audio
        do_checkIfExist bin-fdk-aac-git bin-audio/fdkaac.exe
    fi
fi

if do_checkForOptions "--enable-libfaac"; then
    if $LOCALDESTDIR/bin-audio/faac.exe | grep -q -e "FAAC 1.28"; then
        echo -------------------------------------------------
        echo "faac-1.28 is already compiled"
        echo -------------------------------------------------
    else
        cd $LOCALBUILDDIR
        echo -ne "\033]0;compile faac $bits\007"

        do_wget "http://sourceforge.net/projects/faac/files/faac-src/faac-1.28/faac-1.28.tar.gz/download" faac-1.28.tar.gz

        if [[ -f configure ]]; then
            make distclean
        else
            sh bootstrap
        fi
        do_generic_confmakeinstall audio --without-mp4v2
        do_checkIfExist faac-1.28 libfaac.a
    fi
fi

if do_checkForOptions "--enable-libvorbis"; then
    if oggenc.exe --version | grep -q "vorbis-tools 1.4.0"; then
        echo -------------------------------------------------
        echo "vorbis-tools-1.4.0 is already compiled"
        echo -------------------------------------------------
    else
        cd $LOCALBUILDDIR
        echo -ne "\033]0;compile vorbis-tools $bits\007"

        do_wget "http://downloads.xiph.org/releases/vorbis/vorbis-tools-1.4.0.tar.gz"

        if [[ -f "oggenc/oggenc.exe" ]]; then
            make distclean
        fi
        if [[ -d "$LOCALDESTDIR/bin-audio/oggenc.exe" ]]; then
            rm -r $LOCALDESTDIR/bin-audio/ogg{enc,dec}.exe
        fi
        do_generic_conf --disable-ogg123 --disable-vorbiscomment --disable-vcut --disable-ogginfo --disable-flac --disable-speex
        make -j $cpuCount
        [[ -f oggenc/oggenc.exe ]] && cp -f oggenc/oggenc.exe oggdec/oggdec.exe $LOCALDESTDIR/bin-audio/
        do_checkIfExist vorbis-tools-1.4.0 bin-audio/oggenc.exe
    fi
fi

if do_checkForOptions "--enable-libopus"; then
    if opusenc.exe --version | grep -q -e "opus-tools 0.1.9"; then
        echo -------------------------------------------------
        echo "opus-tools-0.1.9 is already compiled"
        echo -------------------------------------------------
    else
        cd $LOCALBUILDDIR
        echo -ne "\033]0;compile opus-tools $bits\007"

        do_wget "http://downloads.xiph.org/releases/opus/opus-tools-0.1.9.tar.gz"

        if [[ -f "opusenc.exe" ]]; then
            make distclean
        fi
        if [[ -d "$LOCALDESTDIR/bin-audio/opusenc.exe" ]]; then
            rm -rf $LOCALDESTDIR/bin-audio/opus*
        fi
        do_generic_confmakeinstall audio LDFLAGS="$LDFLAGS -static -static-libgcc -static-libstdc++"
        do_checkIfExist opus-tools-0.1.9 bin-audio/opusenc.exe
    fi
fi

if do_checkForOptions "--enable-libsoxr" && do_pkgConfig "soxr = 0.1.1"; then
    cd $LOCALBUILDDIR
    do_wget "http://sourceforge.net/projects/soxr/files/soxr-0.1.1-Source.tar.xz"

    sed -i 's|NOT WIN32|UNIX|g' ./src/CMakeLists.txt
    if [[ -f $LOCALDESTDIR/include/soxr.h ]]; then
        rm -rf $LOCALDESTDIR/include/soxr{,-lsr}.h
        rm -f $LOCALDESTDIR/lib/soxr{,-lsr}.a
        rm -f $LOCALDESTDIR/lib/pkgconfig/soxr{,-lsr}.pc
    fi
    do_cmake .. -DHAVE_WORDS_BIGENDIAN_EXITCODE:bool=off -DBUILD_EXAMPLES:bool=off -DWITH_SIMD:bool=on \
    -DBUILD_TESTS:bool=off -DWITH_OPENMP:bool=off -DBUILD_LSR_TESTS:bool=off
    do_makeinstall
    do_checkIfExist soxr-0.1.1-Source libsoxr.a
fi

if do_checkForOptions "--enable-libmp3lame" || [[ $sox = "y" ]]; then
    if $LOCALDESTDIR/bin-audio/lame.exe 2>&1 | grep -q "version 3.99.5"; then
        echo -------------------------------------------------
        echo "lame 3.99.5 is already compiled"
        echo -------------------------------------------------
    else
        cd $LOCALBUILDDIR
        echo -ne "\033]0;compiling lame $bits\007"
        do_wget "http://sourceforge.net/projects/lame/files/lame/3.99/lame-3.99.5.tar.gz"
        if grep "xmmintrin\.h" configure.in; then
            do_patch lame-fixes.patch
            autoreconf -fi
        fi
        if [[ -f libmp3lame/.libs/libmp3lame.a ]]; then
            make distclean
        fi
        if [[ -f $LOCALDESTDIR/include/lame/lame.h ]]; then
            rm -rf $LOCALDESTDIR/include/lame
            rm -f $LOCALDESTDIR/lib/libmp3lame.{l,}a $LOCALDESTDIR/bin-audio/lame.exe
        fi
        do_generic_confmakeinstall audio --disable-decoder
        do_checkIfExist lame-3.99.5 libmp3lame.a
    fi
fi

if do_checkForOptions "--enable-libgme"; then
    cd $LOCALBUILDDIR
    do_git "https://bitbucket.org/mpyne/game-music-emu.git" libgme
    if [[ $compile = "true" ]]; then
        if [[ -d $LOCALDESTDIR/include/gme ]]; then
            rm -rf $LOCALDESTDIR/include/gme
            rm -f $LOCALDESTDIR/lib/libgme.a
            rm -f $LOCALDESTDIR/lib/pkgconfig/libgme.pc
        fi
        do_cmake ..
        do_makeinstall
        do_checkIfExist libgme-git libgme.a
    fi
fi

if do_checkForOptions "--enable-libtwolame"; then
    cd $LOCALBUILDDIR
    do_git "https://github.com/qyot27/twolame.git" twolame shallow mingw-static
    if [[ $compile = "true" ]]; then
        if [[ ! -f ./configure ]]; then
            ./autogen.sh -V
        else
            make distclean
        fi
        if [[ -f "$LOCALDESTDIR/include/twolame.h" ]]; then
            rm -rf $LOCALDESTDIR/include/twolame.h $LOCALDESTDIR/bin-audio/twolame.exe
            rm -rf $LOCALDESTDIR/lib/libtwolame.{l,}a $LOCALDESTDIR/lib/pkgconfig/twolame.pc
        fi

        do_generic_conf
        sed -i 's/frontend simplefrontend//' Makefile
        do_makeinstall
        do_checkIfExist twolame-git libtwolame.a
    fi
fi

if do_checkForOptions "--enable-libbs2b" && do_pkgConfig "libbs2b = 3.1.0"; then
    cd $LOCALBUILDDIR
    do_wget "http://sourceforge.net/projects/bs2b/files/libbs2b/3.1.0/libbs2b-3.1.0.tar.gz/download" libbs2b-3.1.0.tar.gz

    if [[ -f "src/.libs/libbs2b.a" ]]; then
        make distclean
    fi
    if [[ -d "$LOCALDESTDIR/include/bs2b" ]]; then
        rm -rf $LOCALDESTDIR/include/bs2b $LOCALDESTDIR/bin-audio/bs2b*
        rm -rf $LOCALDESTDIR/lib/libbs2b.{l,}a $LOCALDESTDIR/lib/pkgconfig/libbs2b.pc
    fi

    do_patch "libbs2b-disable-sndfile.patch"
    do_patch "libbs2b-libs-only.patch"
    do_generic_confmakeinstall
    do_checkIfExist libbs2b-3.1.0 libbs2b.a
fi

if [[ $sox = "y" ]]; then
    cd $LOCALBUILDDIR
    do_git "https://github.com/erikd/libsndfile.git" sndfile
    if [[ $compile = "true" ]]; then
        if [[ ! -f ./configure ]]; then
            ./autogen.sh
        else
            make distclean
        fi
        if [[ -f "$LOCALDESTDIR/include/sndfile.h" ]]; then
            rm -rf $LOCALDESTDIR/include/sndfile.{h,}h $LOCALDESTDIR/bin-audio/sndfile-*
            rm -rf $LOCALDESTDIR/lib/libsndfile.{l,}a $LOCALDESTDIR/lib/pkgconfig/sndfile.pc
        fi
        do_generic_conf
        sed -i 's/ examples regtest tests programs//g' Makefile
        do_makeinstall
        do_checkIfExist sndfile-git libsndfile.a
    fi

    if [ -f "$LOCALDESTDIR/lib/libmad.a" ]; then
        echo -------------------------------------------------
        echo "libmad-0.15.1b is already compiled"
        echo -------------------------------------------------
    else
        cd $LOCALBUILDDIR
        echo -ne "\033]0;compile libmad $bits\007"

        do_wget "ftp://ftp.mars.org/pub/mpeg/libmad-0.15.1b.tar.gz"

        if [[ -f ".libs/libmad.a" ]]; then
            make distclean
        fi
        if [[ -f "$LOCALDESTDIR/lib/libmad.a" ]]; then
            rm -rf $LOCALDESTDIR/include/mad.h
            rm -rf $LOCALDESTDIR/lib/libmad.{l,}a
        fi

        do_generic_confmakeinstall --enable-fpm=intel --disable-debugging
        do_checkIfExist libmad-0.15.1b libmad.a
    fi

    if do_pkgConfig "opusfile = 0.6"; then
        cd $LOCALBUILDDIR
        do_wget "http://downloads.xiph.org/releases/opus/opusfile-0.6.tar.gz"

        if [[ -f ".libs/libopusfile.a" ]]; then
            make distclean
        fi
        if [[ -d "$LOCALDESTDIR/include/opus" ]]; then
            rm -rf $LOCALDESTDIR/include/opus/opusfile.h $LOCALDESTDIR/lib/libopus{file,url}.{l,}a
            rm -rf $LOCALDESTDIR/lib/pkgconfig/opus{file,url}.pc
        fi
        do_generic_confmakeinstall
        do_checkIfExist opusfile-0.6 libopusfile.a
    fi

    cd $LOCALBUILDDIR
    do_git "git://git.code.sf.net/p/sox/code" sox shallow master bin-audio/sox.exe
    if [[ $compile = "true" ]]; then
        sed -i 's|found_libgsm=yes|found_libgsm=no|g' configure.ac

        if [[ ! -f ./configure ]]; then
            autoreconf -i
        else
            rm -rf $LOCALDESTDIR/include/sox.h $LOCALDESTDIR/bin-audio/sox.exe
            rm -rf $LOCALDESTDIR/lib/libsox.{l,}a $LOCALDESTDIR/lib/pkgconfig/sox.pc
            make distclean
        fi
        do_generic_confmakeinstall audio CPPFLAGS='-DPCRE_STATIC' LIBS='-lpcre -lshlwapi -lz -lgnurx'
        do_checkIfExist sox-git bin-audio/sox.exe
    fi
fi

echo "-------------------------------------------------------------------------------"
echo
echo "compile audio tools $bits done..."
echo
echo "-------------------------------------------------------------------------------"

echo "-------------------------------------------------------------------------------"
echo
echo "compile video tools $bits"
echo
echo "-------------------------------------------------------------------------------"

if do_checkForOptions "--enable-libtheora" && do_pkgConfig "theora = 1.1.1"; then
    cd $LOCALBUILDDIR
    do_wget "http://downloads.xiph.org/releases/theora/libtheora-1.1.1.tar.bz2"

    if [[ -f "lib/.libs/libtheora.a" ]]; then
        make distclean
    fi
    if [[ -d "$LOCALDESTDIR/include/theora" ]]; then
        rm -rf $LOCALDESTDIR/include/theora $LOCALDESTDIR/lib/libtheora{,enc,dec}.{l,}a
        rm -rf $LOCALDESTDIR/lib/pkgconfig/theora{,enc,dec}.pc
    fi
    do_generic_confmakeinstall --disable-examples
    do_checkIfExist libtheora-1.1.1 libtheora.a
fi

if [[ ! $vpx = "n" ]] || [[ $ffmbc = "y" ]]; then
    cd $LOCALBUILDDIR
    do_git "https://chromium.googlesource.com/webm/libvpx.git" vpx noDepth
    if [[ $compile = "true" ]] || [[ $vpx = "y" && ! -f "$LOCALDESTDIR/bin-video/vpxenc.exe" ]]; then
        if [ -d $LOCALDESTDIR/include/vpx ]; then
            rm -rf $LOCALDESTDIR/include/vpx
            rm -f $LOCALDESTDIR/lib/pkgconfig/vpx.pc
            rm -f $LOCALDESTDIR/lib/libvpx.a
        fi

        if [ -f libvpx.a ]; then
            make distclean
        fi
        extracommands="--prefix=$LOCALDESTDIR --disable-shared --enable-static --disable-unit-tests --disable-docs \
        --enable-postproc --enable-vp9-postproc --enable-runtime-cpu-detect --enable-vp9-highbitdepth"
        if [[ $bits = "64bit" ]]; then
            LDFLAGS="$LDFLAGS -static-libgcc -static" ./configure --target=x86_64-win64-gcc $extracommands
            sed -i 's/HAVE_GNU_STRIP=yes/HAVE_GNU_STRIP=no/g' libs-x86_64-win64-gcc.mk
        else
            LDFLAGS="$LDFLAGS -static-libgcc -static" ./configure --target=x86-win32-gcc $extracommands
            sed -i 's/HAVE_GNU_STRIP=yes/HAVE_GNU_STRIP=no/g' libs-x86-win32-gcc.mk
        fi
        do_makeinstall

        if [[ $vpx = "y" ]]; then
            mv $LOCALDESTDIR/bin/vpx{enc,dec}.exe $LOCALDESTDIR/bin-video
        else
            rm -f $LOCALDESTDIR/bin/vpx{enc,dec}.exe
        fi

        do_checkIfExist vpx-git libvpx.a
        buildFFmpeg="true"
        unset extracommands
    fi
else
    pkg-config --exists vpx || do_removeOption "--enable-libvpx"
fi

if [[ $other265 = "y" ]]; then
    cd $LOCALBUILDDIR
    do_git "https://github.com/ultravideo/kvazaar.git" kvazaar shallow master bin-video/kvazaar.exe
    if [[ $compile = "true" ]]; then
        cd src
        if [[ -f intra.o ]]; then
            make clean
        fi

        if [[ "$bits" = "32bit" ]]; then
            make ARCH=i686 -j $cpuCount
        else
            make ARCH=x86_64 -j $cpuCount
        fi

        cp kvazaar.exe $LOCALDESTDIR/bin-video
        do_checkIfExist kvazaar-git bin-video/kvazaar.exe
    fi
fi

if [[ $mplayer = "y" ]] || [[ $mpv = "y" ]]; then

    cd $LOCALBUILDDIR
    do_git "git://git.videolan.org/libdvdread.git" dvdread
    if [[ $compile = "true" ]]; then
        if [[ ! -f "configure" ]]; then
            autoreconf -fiv
        else
            make distclean
        fi

        if [[ -d $LOCALDESTDIR/include/dvdread ]]; then
            rm -rf $LOCALDESTDIR/include/dvdread
            rm -rf $LOCALDESTDIR/lib/libdvdread.{l,}a $LOCALDESTDIR/lib/pkgconfig/dvdread.pc
        fi
        do_generic_confmakeinstall
        do_checkIfExist dvdread-git libdvdread.a
    fi

    cd $LOCALBUILDDIR
    do_git "git://git.videolan.org/libdvdnav.git" dvdnav
    if [[ $compile = "true" ]]; then
        if [[ ! -f "configure" ]]; then
            autoreconf -fiv
        else
            make distclean
        fi

        if [[ -d $LOCALDESTDIR/include/dvdnav ]]; then
            rm -rf $LOCALDESTDIR/include/dvdnav
            rm -rf $LOCALDESTDIR/lib/libdvdnav.{l,}a $LOCALDESTDIR/lib/pkgconfig/dvdnav.pc
        fi
        do_generic_confmakeinstall
        do_checkIfExist dvdnav-git libdvdnav.a
    fi
fi

if do_checkForOptions "--enable-libbluray"; then
    cd $LOCALBUILDDIR
    do_git "git://git.videolan.org/libbluray.git" libbluray
    if [[ $compile = "true" ]]; then
        if [[ ! -f "configure" ]]; then
            autoreconf -fiv
        else
            rm -rf $LOCALDESTDIR/include/bluray
            rm -rf $LOCALDESTDIR/lib/libbluray.{l,}a $LOCALDESTDIR/lib/pkgconfig/libbluray.pc
            make distclean
        fi
        do_generic_confmakeinstall --enable-static --disable-examples --disable-bdjava --disable-doxygen-doc \
        --disable-doxygen-dot --without-libxml2
        do_checkIfExist libbluray-git libbluray.a
    fi
fi

if do_checkForOptions "--enable-libutvideo"; then
    cd $LOCALBUILDDIR
    do_git "https://github.com/qyot27/libutvideo.git" libutvideo shallow 15.1.0
    if [[ $compile = "true" ]]; then
        if [ -f utv_core/libutvideo.a ]; then
            rm -rf $LOCALDESTDIR/include/utvideo
            rm -rf $LOCALDESTDIR/lib/libutvideo.a $LOCALDESTDIR/lib/pkgconfig/libutvideo.pc
            make distclean
        fi

        ./configure --cross-prefix=$cross --prefix=$LOCALDESTDIR

        make -j $cpuCount AR="${AR-ar}" RANLIB="${RANLIB-ranlib}"
        make install RANLIBX="${RANLIB-ranlib}"

        do_checkIfExist libutvideo-git libutvideo.a

        buildFFmpeg="true"
    fi
fi

if do_checkForOptions "--enable-libass"; then
    cd $LOCALBUILDDIR
    do_git "https://github.com/libass/libass.git" libass
    if [[ $compile = "true" ]]; then
        if [[ ! -f "configure" ]]; then
            autoreconf -fiv
        else
            rm -rf $LOCALDESTDIR/include/ass
            rm -rf $LOCALDESTDIR/lib/libass.a $LOCALDESTDIR/lib/pkgconfig/libass.pc
            make distclean
        fi
        do_generic_confmakeinstall
        do_checkIfExist libass-git libass.a
        buildFFmpeg="true"
    fi
fi

if do_checkForOptions "--enable-libxavs"; then
    cd $LOCALBUILDDIR
    if [ -f "$LOCALDESTDIR/lib/libxavs.a" ]; then
        echo -------------------------------------------------
        echo "xavs is already compiled"
        echo -------------------------------------------------
    else
        echo -ne "\033]0;compile xavs $bits\007"
        if [[ ! -d xavs ]] || [[ -d xavs ]] &&
        { [[ $build32 = "yes" && ! -f xavs/build_successful32bit ]] ||
          [[ $build64 = "yes" && ! -f xavs/build_successful64bit ]]; }; then
            rm -f distrotech-xavs.zip
            do_wget https://github.com/Distrotech/xavs/archive/distrotech-xavs.zip
            mv xavs-distrotech-xavs xavs
        fi
        cd xavs
        if [[ -f "libxavs.a" ]]; then
            make distclean
        fi
        if [[ -f "$LOCALDESTDIR/include/xavs.h" ]]; then
            rm -rf $LOCALDESTDIR/include/xavs.h
            rm -rf $LOCALDESTDIR/lib/libxavs.a $LOCALDESTDIR/lib/pkgconfig/xavs.pc
        fi
        do_generic_conf
        make -j $cpuCount libxavs.a
        install -m 644 xavs.h $LOCALDESTDIR/include
        install -m 644 libxavs.a $LOCALDESTDIR/lib
        install -m 644 xavs.pc $LOCALDESTDIR/lib/pkgconfig

        do_checkIfExist xavs libxavs.a
    fi
fi

if [ $mediainfo = "y" ]; then
    cd $LOCALBUILDDIR

	cd $LOCALBUILDDIR
    do_git "https://github.com/MediaArea/ZenLib" ZenLib
	cd Project/GNU/Library
	
    if [[ $compile = "true" ]]; then
        if [[ ! -f "configure" ]]; then
            ./autogen.sh
        else
            make distclean
        fi

        if [[ -d $LOCALDESTDIR/include/ZenLib ]]; then
            rm -rf $LOCALDESTDIR/include/ZenLib
            rm -rf $LOCALDESTDIR/lib/libzen.a.{l,}a $LOCALDESTDIR/lib/pkgconfig/libzen.pc
        fi
		
		./configure --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-global --build=$targetBuild --host=$targetHost

        if [[ $bits = "64bit" ]]; then
            sed -i 's/ -DSIZE_T_IS_LONG//g' Makefile
        fi
        make -j $cpuCount
		make install
 
        do_checkIfExist ZenLib-git libzen.a
    fi
	
	cd $LOCALBUILDDIR
	do_git "https://github.com/MediaArea/MediaInfoLib" MediaInfoLib
	cd Project/GNU/Library

	if [[ $compile = "true" ]]; then
		if [[ ! -f ".libs/libmediainfo.a" ]]; then
			./autogen.sh
		else
			make distclean
		fi

        if [[ -d $LOCALDESTDIR/include/MediaInfo ]]; then
            rm -rf $LOCALDESTDIR/include/MediaInfo $LOCALDESTDIR/include/MediaInfoDLL
            rm -rf $LOCALDESTDIR/lib/libmediainfo.a.{l,}a $LOCALDESTDIR/lib/pkgconfig/libmediainfo.pc
        fi
		
        ./configure --prefix=$LOCALDESTDIR --build=$targetBuild --host=$targetHost LDFLAGS="$LDFLAGS -static-libgcc"

        if [[ $bits = "64bit" ]]; then
            sed -i 's/ -DSIZE_T_IS_LONG//g' Makefile
        fi

        make -j $cpuCount
		make install
		cp libmediainfo.pc $LOCALDESTDIR/lib/pkgconfig/
		cp libmediainfo-config $LOCALDESTDIR/bin-global/
		
        do_checkIfExist MediaInfoLib-git libmediainfo.a
	fi
	
	cd $LOCALBUILDDIR
	
	do_git "https://github.com/MediaArea/MediaInfo" MediaInfo
	cd Project/GNU/CLI
	
	if [[ $compile = "true" ]]; then
		if [[ ! -f "mediainfo.exe" ]]; then
			./autogen.sh
		else
			make distclean
		fi
		
		 if [[ -d $LOCALDESTDIR/bin-video/mediainfo.exe ]]; then
            rm -rf $LOCALDESTDIR/bin-video/mediainfo.exe
        fi

        ./configure --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-video --build=$targetBuild --host=$targetHost \
		--enable-staticlibs --enable-shared=no LDFLAGS="$LDFLAGS -static-libgcc"

        if [[ $bits = "64bit" ]]; then
            sed -i 's/ -DSIZE_T_IS_LONG//g' Makefile
        fi

        make -j $cpuCount
		make install

        do_checkIfExist mediainfo-git bin-video/mediainfo.exe
    fi
fi

if do_checkForOptions "--enable-libvidstab"; then
    cd $LOCALBUILDDIR
    do_git "https://github.com/georgmartius/vid.stab.git" vidstab
    if [[ $compile = "true" ]]; then
        if [[ -d $LOCALDESTDIR/include/vid.stab ]]; then
            rm -rf $LOCALDESTDIR/include/vid.stab $LOCALDESTDIR/lib/libvidstab.a
            rm -rf $LOCALDESTDIR/lib/pkgconfig/vidstab.pc
        fi
        do_cmake .. -DUSE_OMP:bool=off
        sed -i 's/ -fPIC//g' CMakeFiles/vidstab.dir/flags.make
        do_makeinstall
        do_checkIfExist vidstab-git libvidstab.a
        buildFFmpeg="true"
    fi
fi

if do_checkForOptions "--enable-libcaca" && do_pkgConfig "caca = 0.99.beta19"; then
    cd $LOCALBUILDDIR
    do_wget "https://fossies.org/linux/privat/libcaca-0.99.beta19.tar.gz"

    if [[ -f "caca/.libs/libcaca.a" ]]; then
        make distclean
    else
        sed -i -e 's/src //g' -e 's/examples //g' -e 's/doc //g' Makefile.am
        autoreconf -fiv
    fi
    if [[ -f "$LOCALDESTDIR/include/caca.h" ]]; then
        rm -rf $LOCALDESTDIR/include/caca* $LOCALDESTDIR/bin-video/caca*
        rm -rf $LOCALDESTDIR/lib/libcaca.{l,}a $LOCALDESTDIR/lib/pkgconfig/caca.pc
    fi

    cd caca
    sed -i "s/#if defined _WIN32 && defined __GNUC__ && __GNUC__ >= 3/#if defined __MINGW__/g" string.c
    sed -i "s/#if defined(HAVE_VSNPRINTF_S)//g" string.c
    sed -i "s/vsnprintf_s(buf, bufsize, _TRUNCATE, format, args);//g" string.c
    sed -i "s/#elif defined(HAVE_VSNPRINTF)/#if defined(HAVE_VSNPRINTF)/g" string.c
    sed -i "s/#define HAVE_VSNPRINTF_S 1/#define HAVE_VSNPRINTF 1/g" ../win32/config.h
    sed -i "s/#if defined _WIN32 && defined __GNUC__ && __GNUC__ >= 3/#if defined __MINGW__/g" figfont.c
    sed -i "s/__declspec(dllexport)//g" *.h
    sed -i "s/__declspec(dllimport)//g" *.h
    sed -i "s/Cflags: -I\${includedir}/& -DCACA_STATIC/" caca.pc.in
    cd ..

    do_generic_conf --bindir=$LOCALDESTDIR/bin-global --disable-cxx --disable-csharp --disable-ncurses \
    --disable-java --disable-python --disable-ruby --disable-imlib2 --disable-doc
    sed -i 's/ln -sf/$(LN_S)/' "doc/Makefile"
    do_makeinstall
    do_checkIfExist libcaca-0.99.beta19 libcaca.a
elif pkg-config --exists caca && ! pkg-config --cflags caca | grep -q -e "-DCACA_STATIC"; then
    sed -i "s/Cflags: -I\${includedir}/& -DCACA_STATIC/" $LOCALDESTDIR/lib/pkgconfig/caca.pc
fi

if do_checkForOptions "--enable-libzvbi" && do_pkgConfig "zvbi-0.2 = 0.2.35"; then
    cd $LOCALBUILDDIR
    do_wget "http://sourceforge.net/projects/zapping/files/zvbi/0.2.35/zvbi-0.2.35.tar.bz2/download" zvbi-0.2.35.tar.bz2

    if [[ -f "src/.libs/libzvbi.a" ]]; then
        make distclean
    fi
    if [[ -f "$LOCALDESTDIR/include/libzvbi.h" ]]; then
        rm -rf $LOCALDESTDIR/include/libzvbi.h
        rm -rf $LOCALDESTDIR/lib/libzvbi.{l,}a $LOCALDESTDIR/lib/pkgconfig/zvbi-0.2.pc
    fi
    do_patch "zvbi-win32.patch"
    do_patch "zvbi-ioctl.patch"
    do_generic_conf --disable-dvb --disable-bktr --disable-nls --disable-proxy --without-doxygen \
    CFLAGS="$CFLAGS -DPTW32_STATIC_LIB" LIBS="$LIBS -lpng"
    cd src
    do_makeinstall
    cp ../zvbi-0.2.pc $LOCALDESTDIR/lib/pkgconfig
    do_checkIfExist zvbi-0.2.35 libzvbi.a
fi

if do_checkForOptions "--enable-frei0r" && do_pkgConfig "frei0r = 1.3.0"; then
    cd $LOCALBUILDDIR
    do_wget "https://files.dyne.org/frei0r/releases/frei0r-plugins-1.4.tar.gz"

    sed -i 's/find_package (Cairo)//' "CMakeLists.txt"

    [[ -d "build" ]] && rm -rf build/* || mkdir build
    cd build
    if [[ -f $LOCALDESTDIR/include/frei0r.h ]]; then
        rm -rf $LOCALDESTDIR/include/frei0r.h
        rm -rf $LOCALDESTDIR/lib/frei0r-1 $LOCALDESTDIR/lib/pkgconfig/frei0r.pc
    fi

    cmake .. -G "MSYS Makefiles" -DCMAKE_INSTALL_PREFIX=$LOCALDESTDIR

    make -j $cpuCount
    make all install

    do_checkIfExist frei0r-plugins-1.4 frei0r-1/xfade0r.dll
    do_addOption "--enable-filter=frei0r"
fi

if do_checkForOptions "--enable-decklink" && [[ $ffmpeg != "n" ]]; then
    cd $LOCALBUILDDIR

    if [ -f "$LOCALDESTDIR/include/DeckLinkAPI.h" ]; then
        echo -------------------------------------------------
        echo "DeckLinkAPI is already downloaded"
        echo -------------------------------------------------
    else
        echo -ne "\033]0;download DeckLinkAPI $bits\007"
        cd $LOCALDESTDIR/include
        do_wget "https://raw.githubusercontent.com/jb-alvarado/media-autobuild_suite/master/includes/DeckLinkAPI.h"
        do_wget "https://raw.githubusercontent.com/jb-alvarado/media-autobuild_suite/master/includes/DeckLinkAPI_i.c"

        do_checkIfExist DeckLinkAPI "include/DeckLinkAPI.h"
    fi
fi

if do_checkForOptions "--enable-nvenc" && [[ $ffmpeg != "n" ]]; then
    cd $LOCALBUILDDIR

    if [[ -f $LOCALDESTDIR/include/nvEncodeAPI.h ]]; then
        echo -------------------------------------------------
        echo "nvenc is already installed"
        echo -------------------------------------------------
    else
        echo -ne "\033]0;install nvenc $bits\007"
        do_wget "http://developer.download.nvidia.com/compute/nvenc/v5.0/nvenc_5.0.1_sdk.zip"
        
        if [[ $build32 = "yes" ]] && [[ ! -f /local32/include/nvEncodeAPI.h ]]; then
            cp nvenc_5.0.1_sdk/Samples/common/inc/* /local32/include
        fi
        
        if [[ $build64 = "yes" ]] && [[ ! -f /local64/include/nvEncodeAPI.h ]]; then
            cp nvenc_5.0.1_sdk/Samples/common/inc/* /local64/include
        fi
    
        do_checkIfExist nvenc_5.0.1_sdk "include/nvEncodeAPI.h"
    fi
fi

if do_checkForOptions "--enable-libmfx" && [[ $ffmpeg != "n" ]]; then
    cd $LOCALBUILDDIR
    do_git "https://github.com/lu-zero/mfx_dispatch.git" libmfx
    if [[ $compile = "true" ]]; then
        if [[ ! -f configure ]]; then
            autoreconf -fiv
        elif [[ -f Makefile ]]; then
            make distclean
        fi
        if [[ -d $LOCALDESTDIR/include/mfx ]]; then
            rm -rf $LOCALDESTDIR/include/mfx
            rm -f $LOCALDESTDIR/lib/libmfx.{l,}a $LOCALDESTDIR/lib/pkgconfig/libmfx.pc
        fi
        do_generic_confmakeinstall
        do_checkIfExist libmfx-git libmfx.a
    fi
fi

if do_checkForOptions "--enable-libcdio"; then
    cd $LOCALBUILDDIR
    do_git "https://github.com/rocky/libcdio-paranoia.git" libcdio_paranoia
    if [[ $compile = "true" ]]; then
        if [[ ! -f configure ]]; then
            autoreconf -fiv
        elif [[ -f config.h ]]; then
            make distclean
        fi
        if [[ -d $LOCALDESTDIR/include/cdio ]]; then
            rm -rf $LOCALDESTDIR/include/cdio
            rm -f $LOCALDESTDIR/lib/libcdio_{cdda,paranoia}.{l,}a
            rm -f $LOCALDESTDIR/lib/pkgconfig/libcdio_{cdda,paranoia}.pc
            rm -f $LOCALDESTDIR/bin-audio/cd-paranoia.exe
        fi
        do_generic_confmakeinstall audio --disable-example-progs --disable-cpp-progs --enable-silent-rules
        do_checkIfExist libcdio_paranoia-git libcdio_paranoia.a
    fi
fi

#------------------------------------------------
# final tools
#------------------------------------------------

if [[ $mp4box = "y" ]]; then
    cd $LOCALBUILDDIR
    do_git "https://github.com/gpac/gpac.git" gpac noDepth master bin-video/MP4Box.exe
    if [[ $compile = "true" ]]; then
        if [ -d "$LOCALDESTDIR/include/gpac" ]; then
            rm -rf $LOCALDESTDIR/bin-video/gpac $LOCALDESTDIR/lib/libgpac*
            rm -rf $LOCALDESTDIR/include/gpac
        fi

        if [[ -f config.mak ]]; then
            make distclean
        fi

        ./configure --prefix=$LOCALDESTDIR --static-mp4box --extra-libs="-lz"

        make -j $cpuCount
        make install-lib

        cp bin/gcc/MP4Box.exe $LOCALDESTDIR/bin-video

        do_checkIfExist gpac-git bin-video/MP4Box.exe
    fi
fi

if [[ ! $x264 = "n" ]] || [[ $ffmbc = "y" ]]; then
    cd $LOCALBUILDDIR
    do_git "git://git.videolan.org/x264.git" x264 noDepth
    if [[ $compile = "true" ]] || [[ $x264 = "y" && ! -f "$LOCALDESTDIR/bin-video/x264.exe" ]]; then
        if [[ $x264 = "y" ]]; then
            cd $LOCALBUILDDIR
            do_git "git://git.videolan.org/ffmpeg.git" ffmpeg noDepth master lib/libavcodec.a

            if [ -f "$LOCALDESTDIR/lib/libavcodec.a" ]; then
                rm -rf $LOCALDESTDIR/include/libav{codec,device,filter,format,util,resample}
                rm -rf $LOCALDESTDIR/include/{libsw{scale,resample},libpostproc}
                rm -f $LOCALDESTDIR/lib/libav{codec,device,filter,format,util,resample}.a
                rm -f $LOCALDESTDIR/lib/{libsw{scale,resample},libpostproc}.a
                rm -f $LOCALDESTDIR/lib/pkgconfig/libav{codec,device,filter,format,util,resample}.pc
                rm -f $LOCALDESTDIR/lib/pkgconfig/{libsw{scale,resample},libpostproc}.pc
                rm -f $LOCALDESTDIR/bin-video/ff{mpeg,play,probe}.exe
            fi

            if [ -f "config.mak" ]; then
                make distclean
            fi

            ./configure $FFMPEG_BASE_OPTS --target-os=mingw32 --prefix=$LOCALDESTDIR --disable-shared \
            --disable-programs --disable-devices --disable-filters --disable-encoders --disable-muxers

            do_makeinstall
            do_checkIfExist ffmpeg-git libavcodec.a

            cd $LOCALBUILDDIR
            do_git "https://github.com/l-smash/l-smash.git" lsmash
            if [[ $compile = "true" ]]; then
                if [[ -f "config.mak" ]]; then
                    make distclean
                fi
                if [[ -f "$LOCALDESTDIR/lib/liblsmash.a" ]]; then
                    rm -f $LOCALDESTDIR/include/lsmash.h $LOCALDESTDIR/lib/liblsmash.a
                    rm -f $LOCALDESTDIR/lib/pkgconfig/liblsmash.pc
                fi
                ./configure --prefix=$LOCALDESTDIR
                make -j $cpuCount lib
                make install-lib
                do_checkIfExist lsmash-git liblsmash.a
            fi

            cd $LOCALBUILDDIR/x264-git
        fi

        echo -ne "\033]0;compile x264-git $bits\007"

        if [ -f "$LOCALDESTDIR/lib/libx264.a" ]; then
            rm -f $LOCALDESTDIR/include/x264.h $LOCALDESTDIR/include/x264_config.h $LOCALDESTDIR/lib/libx264.a
            rm -f $LOCALDESTDIR/bin/x264.exe $LOCALDESTDIR/bin/x264-10bit.exe $LOCALDESTDIR/lib/pkgconfig/x264.pc
        fi

        if [ -f "libx264.a" ]; then
            make distclean
        fi

        if [[ $x264 = "y" ]]; then
            ./configure --host=$targetHost --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-video --enable-static \
            --bit-depth=10 --enable-win32thread
            make -j $cpuCount

            cp x264.exe $LOCALDESTDIR/bin-video/x264-10bit.exe
            make clean

            ./configure --host=$targetHost --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-video --enable-static \
            --bit-depth=8 --enable-win32thread
        else
            ./configure --host=$targetHost --prefix=$LOCALDESTDIR --enable-static --enable-win32thread \
            --disable-interlaced --disable-swscale --disable-lavf --disable-ffms --disable-gpac --disable-lsmash \
            --bit-depth=8 --disable-cli
        fi

        do_makeinstall
        do_checkIfExist x264-git libx264.a
        buildFFmpeg="true"
    fi
else
    pkg-config --exists x264 ||  do_removeOption "--enable-libx264"
fi

if [[ ! $x265 = "n" ]]; then
    cd $LOCALBUILDDIR
    do_hg "https://bitbucket.org/multicoreware/x265" x265
    if [[ $compile = "true" ]] || [[ $x265 != "l" && ! -f "$LOCALDESTDIR"/bin-video/x265.exe ]]; then
        cd build/msys
        rm -rf $LOCALBUILDDIR/x265-hg/build/msys/{8,10,12}bit
        rm -f $LOCALDESTDIR/include/x265{,_config}.h
        rm -f $LOCALDESTDIR/lib/libx265{,_main10,_main12}.a $LOCALDESTDIR/lib/pkgconfig/x265.pc
        rm -f $LOCALDESTDIR/bin-video/libx265*.dll $LOCALDESTDIR/bin-video/x265.exe

        [[ $bits = "32bit" ]] && assembly="-DENABLE_ASSEMBLY=OFF" || assembly="-DENABLE_ASSEMBLY=ON"
        [[ $xpcomp = "y" ]] && xpsupport="-DWINXP_SUPPORT=ON" || xpsupport="-DWINXP_SUPPORT=OFF"

        do_x265_cmake() {
            cmake ../../../source -G "MSYS Makefiles" $xpsupport -DHG_EXECUTABLE=/usr/bin/hg.bat \
            -DCMAKE_CXX_FLAGS="$CXXFLAGS -static-libgcc -static-libstdc++" \
            -DCMAKE_C_FLAGS="$CFLAGS -static-libgcc -static-libstdc++" \
            -DCMAKE_INSTALL_PREFIX=$LOCALDESTDIR -DBIN_INSTALL_DIR=$LOCALDESTDIR/bin-video \
            -DENABLE_SHARED=OFF -DENABLE_CLI=OFF -DHIGH_BIT_DEPTH=ON -DEXPORT_C_API=ON "$@"
        }
        mkdir -p {8,10,12}bit

        cd 12bit
        if [[ $x265 != "s" ]]; then
            # multilib
            do_x265_cmake $assembly -DEXPORT_C_API=OFF -DMAIN12=ON
            make -j $cpuCount
            cp libx265.a ../8bit/libx265_main12.a
        fi

        cd ../10bit
        if [[ $x265 = "s" ]]; then
            # libx265_main10.dll
            do_x265_cmake $assembly -DENABLE_SHARED=ON
            make -j $cpuCount
            cp libx265.dll $LOCALDESTDIR/bin-video/libx265_main10.dll
        else
            # multilib
            do_x265_cmake $assembly -DEXPORT_C_API=OFF
            make -j $cpuCount
            cp libx265.a ../8bit/libx265_main10.a
        fi

        cd ../8bit
        if [[ $x265 = "s" ]]; then
            # 8-bit static x265.exe
            do_x265_cmake -DENABLE_CLI=ON -DHIGH_BIT_DEPTH=OFF
        else
            # multilib
            [[ $x265 != "l" ]] && cli="-DENABLE_CLI=ON"
            do_x265_cmake -DEXTRA_LIB="x265_main10.a;x265_main12.a" -DEXTRA_LINK_FLAGS=-L. $cli \
                -DHIGH_BIT_DEPTH=OFF -DLINKED_10BIT=ON -DLINKED_12BIT=ON
            # cp libx265_main{10,12}.a $LOCALDESTDIR/lib/
        fi
        do_makeinstall
        if [[ $x265 != "s" ]]; then
            # sed -i "s/Libs: .*$/& -lx265_main10 -lx265_main12/" $LOCALDESTDIR/lib/pkgconfig/x265.pc
            mv libx265.a libx265_main.a
            ar -M <<EOF
CREATE libx265.a
ADDLIB libx265_main.a
ADDLIB libx265_main10.a
ADDLIB libx265_main12.a
SAVE
END
EOF
            cp libx265.a $LOCALDESTDIR/lib/libx265.a
        fi

        do_checkIfExist x265-hg libx265.a
        buildFFmpeg="true"
        unset xpsupport assembly cli
    fi
else
    pkg-config --exists x265 || do_removeOption "--enable-libx265"
fi

if [[ $ffmbc = "y" ]]; then
    cd $LOCALBUILDDIR
    if $LOCALDESTDIR/bin-video/ffmbc.exe 2>&1 | grep -q -e "version 0.7.4"; then
        echo -------------------------------------------------
        echo "ffmbc-0.7.4 is already compiled"
        echo -------------------------------------------------
        else
            echo -ne "\033]0;compile ffmbc $bits\007"

            if [[ $nonfree = "y" ]]; then
                extras="--enable-nonfree --enable-libfaac"
            else
                extras=""
            fi

            do_wget "https://drive.google.com/uc?id=0B0jxxycBojSwZTNqOUg0bzEta00&export=download" FFmbc-0.7.4.tar.bz2

            if [[ $bits = "32bit" ]]; then
                arch='x86'
            else
                arch='x86_64'
            fi

            if [ -f "config.log" ]; then
                make distclean
            fi

            cp $LOCALDESTDIR/include/openjpeg-1.5/openjpeg.h $LOCALDESTDIR/include
            ./configure --target-os=mingw32 --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-video \
            --disable-debug --disable-shared --disable-doc --disable-avdevice --disable-dxva2 --disable-ffprobe \
            --disable-w32threads --enable-gpl --enable-runtime-cpudetect --enable-bzlib --enable-zlib \
            --enable-librtmp --enable-avisynth --enable-frei0r --enable-libopenjpeg --enable-libass \
            --enable-libmp3lame --enable-libschroedinger --enable-libspeex --enable-libtheora \
            --enable-libvorbis --enable-libvpx --enable-libxavs --enable-libx264 --enable-libxvid $extras \
            --extra-cflags='-DPTW32_STATIC_LIB' --extra-libs='-ltasn1 -ldl -liconv -lpng -lorc-0.4'

            make SRC_DIR=. -j $cpuCount
            make SRC_DIR=. install-progs

            do_checkIfExist FFmbc-0.7.4 bin-video/ffmbc.exe
            rm $LOCALDESTDIR/include/openjpeg.h
    fi
fi


if [[ $ffmpeg != "n" ]]; then
    cd $LOCALBUILDDIR
    do_changeFFmpegConfig
    if [[ $ffmpeg != "s" ]]; then
        do_git "git://git.videolan.org/ffmpeg.git" ffmpeg noDepth master bin-video/ffmpeg.exe
    else
        do_git "git://git.videolan.org/ffmpeg.git" ffmpeg noDepth master bin-video/ffmpegSHARED/ffmpeg.exe
    fi
    if [[ $compile = "true" ]] || [[ $buildFFmpeg = "true" ]]; then
        do_patch "ffmpeg-0001-Use-pkg-config-for-more-external-libs.patch"

        # shared
        if [[ $ffmpeg != "y" ]] && [[ ! -f build_successful${bits}_shared ]]; then
            echo -ne "\033]0;compiling shared FFmpeg $bits\007"
            [ -f config.mak ] && make distclean
            if [ -d "$LOCALDESTDIR/bin-video/ffmpegSHARED" ]; then
                rm -rf $LOCALDESTDIR/bin-video/ffmpegSHARED
            fi
            ./configure --target-os=mingw32 --prefix=$LOCALDESTDIR/bin-video/ffmpegSHARED \
            --disable-static --enable-shared \
            $FFMPEG_OPTS_SHARED \
            --extra-cflags=-DPTW32_STATIC_LIB --extra-libs='-lpng -lpthread -lwsock32' --extra-ldflags=-static-libgcc

            sed -i -e "s|--target-os=mingw32 --prefix=$LOCALDESTDIR/bin-video/ffmpegSHARED ||g" \
                   -e "s|--extra-cflags=-DPTW32_STATIC_LIB --extra-libs='-lpng -lpthread -lwsock32' ||g" \
                   -e "s|--extra-ldflags=-static-libgcc||g" config.h
            do_makeinstall
            do_checkIfExist ffmpeg-git bin-video/ffmpegSHARED/bin/ffmpeg.exe
            [ $ffmpeg = b ] && [ -f build_successful${bits} ] &&
                mv build_successful${bits} build_successful${bits}_shared
        fi

        # static
        if [[ $ffmpeg != "s" ]]; then
            echo -ne "\033]0;compiling static FFmpeg $bits\007"
            if [ -f "$LOCALDESTDIR/lib/libavcodec.a" ]; then
                rm -rf $LOCALDESTDIR/include/libav{codec,device,filter,format,util,resample}
                rm -rf $LOCALDESTDIR/include/{libsw{scale,resample},libpostproc}
                rm -f $LOCALDESTDIR/lib/libav{codec,device,filter,format,util,resample}.a
                rm -f $LOCALDESTDIR/lib/{libsw{scale,resample},libpostproc}.a
                rm -f $LOCALDESTDIR/lib/pkgconfig/libav{codec,device,filter,format,util,resample}.pc
                rm -f $LOCALDESTDIR/lib/pkgconfig/{libsw{scale,resample},libpostproc}.pc
                rm -f $LOCALDESTDIR/bin-video/ff{mpeg,play,probe}.exe
            fi
            [ -f config.mak ] && make distclean
            ./configure --target-os=mingw32 --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-video \
            --enable-static --disable-shared \
            $FFMPEG_OPTS \
            --extra-cflags=-DPTW32_STATIC_LIB --extra-libs='-lpng -lpthread -lwsock32'
            sed -i -e "s| --target-os=mingw32 --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-video||g" \
                   -e "s| --extra-cflags=-DPTW32_STATIC_LIB --extra-libs='-lpng -lpthread -lwsock32'||g" config.h
            do_makeinstall
            do_checkIfExist ffmpeg-git libavcodec.a
            newFfmpeg="yes"
        fi
    fi
fi

if [[ $bits = "64bit" && $other265 = "y" ]]; then
if [[ ! -f $LOCALDESTDIR/bin-video/f265cli.exe ]]; then
    cd $LOCALBUILDDIR
    do_wget "http://f265.org/f265/static/bin/f265_development_snapshot.zip"
    rm -rf f265 && mv f265_development_snapshot f265 && cd f265
    if [ -d "build" ]; then
        rm -rf build .sconf_temp
        rm -f .sconsign.dblite config.log options.py
    fi
    scons libav=none
    [ -f build/f265cli.exe ] && cp build/f265cli.exe $LOCALDESTDIR/bin-video/f265cli.exe
    do_checkIfExist f265 bin-video/f265cli.exe
else
    echo -------------------------------------------------
    echo "f265 is already compiled"
    echo -------------------------------------------------
fi
fi

if [[ $mplayer = "y" ]]; then
    cd $LOCALBUILDDIR
    [[ $nonfree = "n" ]] && faac="--disable-faac --disable-faac-lavc"

    do_svn "svn://svn.mplayerhq.hu/mplayer/trunk" mplayer bin-video/mplayer.exe

    if [ -d "ffmpeg" ]; then
        cd ffmpeg
        oldHead=`git rev-parse HEAD`
        git pull origin master
        newHead=`git rev-parse HEAD`
        cd ..
    fi

    if [[ $compile == "true" ]] || [[ "$oldHead" != "$newHead"  ]] || [[ $buildFFmpeg == "true" ]]; then
        if [ -f $LOCALDESTDIR/bin-video/mplayer.exe ]; then
            rm -f $LOCALDESTDIR/bin-video/{mplayer,mencoder}.exe
        fi
        if [ -f config.mak ]; then
            make distclean
        fi

        if ! test -e ffmpeg ; then
            if [ ! $ffmpeg = "n" ]; then
                git clone --depth 1 $LOCALBUILDDIR/ffmpeg-git ffmpeg
            elif ! git clone --depth 1 git://git.videolan.org/ffmpeg.git ffmpeg; then
                rm -rf ffmpeg
                echo "Failed to get a FFmpeg checkout"
                echo "Please try again or put FFmpeg source code copy into ffmpeg/ manually."
                echo "Nightly snapshot: http://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2"
                echo "To use a github mirror via http (e.g. because a firewall blocks git):"
                echo "git clone --depth 1 https://github.com/FFmpeg/FFmpeg ffmpeg; touch ffmpeg/mp_auto_pull"
                exit 1
            fi
            touch ffmpeg/mp_auto_pull
        fi

        sed -i '/#include "mp_msg.h/ a\#include <windows.h>' libmpcodecs/ad_spdif.c

        ./configure --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-video --cc=gcc \
        --extra-cflags='-DPTW32_STATIC_LIB -O3 -std=gnu99 -DMODPLUG_STATIC' \
        --extra-libs='-llzma -lfreetype -lz -lbz2 -liconv -lws2_32 -lpthread -lwinpthread -lpng -lwinmm -ldl' \
        --extra-ldflags='-Wl,--allow-multiple-definition' --enable-static --enable-runtime-cpudetection \
        --enable-ass-internal --enable-bluray --enable-dvdread --disable-gif --enable-freetype --disable-cddb $faac
        do_makeinstall
        do_checkIfExist mplayer-svn bin-video/mplayer.exe
    fi
fi

if [[ $mpv = "y" ]] && pkg-config --exists "libavcodec libavutil libavformat libswscale"; then
    cd $LOCALBUILDDIR
    do_git "git://midipix.org/waio" waio shallow master lib/libwaio.a
    if [[ $compile = "true" ]]; then
        if [[ $bits = "32bit" ]]; then
            if [[ -f lib32/libwaio.a ]]; then
                ./build-mingw-nt32 clean
                rm -rf $LOCALDESTDIR/include/waio
                rm -f $LOCALDESTDIR/lib/libwaio.a
            fi

            build-mingw-nt32 AR=i686-w64-mingw32-gcc-ar LD=ld STRIP=strip lib-static

            cp -r include/waio  $LOCALDESTDIR/include/
            cp -r lib32/libwaio.a $LOCALDESTDIR/lib/
        else
            if [[ -f lib64/libwaio.a ]]; then
                ./build-mingw-nt64 clean
                rm -rf $LOCALDESTDIR/include/waio
                rm -f $LOCALDESTDIR/lib/libwaio.a
            fi

            build-mingw-nt64 AR=x86_64-w64-mingw32-gcc-ar LD=ld STRIP=strip lib-static

            cp -r include/waio  $LOCALDESTDIR/include/
            cp -r lib64/libwaio.a $LOCALDESTDIR/lib/
        fi

        do_checkIfExist waio-git libwaio.a
    fi

    cd $LOCALBUILDDIR
    do_git "http://luajit.org/git/luajit-2.0.git" luajit noDepth
    if [[ $compile = "true" ]]; then
        if [[ -f "$LOCALDESTDIR/lib/libluajit-5.1.a" ]]; then
            rm -rf $LOCALDESTDIR/include/luajit-2.0 $LOCALDESTDIR/bin-global/luajit*.exe $LOCALDESTDIR/lib/lua
            rm -rf $LOCALDESTDIR/lib/libluajit-5.1.a $LOCALDESTDIR/lib/pkgconfig/luajit.pc
        fi
        
        if [[ -f "src/luajit.exe" ]]; then
            make clean
        fi
		
        make BUILDMODE=static amalg
        make BUILDMODE=static PREFIX=$LOCALDESTDIR INSTALL_BIN=$LOCALDESTDIR/bin-global FILE_T=luajit.exe \
        INSTALL_TNAME='luajit-$(VERSION).exe' INSTALL_TSYMNAME=luajit.exe install

        # luajit comes with a broken .pc file
        sed -r -i "s/(Libs.private:).*/\1 -liconv/" $LOCALDESTDIR/lib/pkgconfig/luajit.pc

        do_checkIfExist luajit-git libluajit-5.1.a
    fi

    cd $LOCALBUILDDIR
    do_git "https://github.com/lachs0r/rubberband.git" rubberband
    if [[ $compile = "true" ]]; then
        if [[ -f "$LOCALDESTDIR/lib/librubberband.a" ]]; then
            make PREFIX=$LOCALDESTDIR uninstall
        fi
		
		if [[ -f "lib/librubberband.a" ]]; then
            make clean
        fi

        make PREFIX=$LOCALDESTDIR install-static

        do_checkIfExist rubberband-git librubberband.a
    fi

    cd $LOCALBUILDDIR
    do_git "https://github.com/mpv-player/mpv.git" mpv noDepth master bin-video/mpv.exe
    if [[ $compile = "true" ]] || [[ $newFfmpeg = "yes" ]]; then
        if [ -f waf ]; then
            $python waf distclean
            rm -rf waf .waf-*
            rm -f $LOCALDESTDIR/bin-video/mpv.{exe,com}
        fi
        $python bootstrap.py

        git describe --tags $(git rev-list --tags --max-count=1) | cut -c 2- > VERSION
        [[ $bits = "64bit" ]] && mpv_ldflags="-Wl,--image-base,0x140000000,--high-entropy-va" &&
            mpv_pthreads="--enable-win32-internal-pthreads"

        LDFLAGS="$LDFLAGS $mpv_ldflags" $python waf configure --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-video \
        --disable-debug-build --enable-static-build --disable-manpage-build --disable-pdf-build --lua=luajit $mpv_pthreads \
        --disable-libguess

        $python waf build -j $cpuCount
        $python waf install

        if [[ ! -f fonts.conf ]]; then
            do_wget "https://raw.githubusercontent.com/lachs0r/mingw-w64-cmake/master/packages/mpv/mpv/fonts.conf"
            do_wget "http://srsfckn.biz/noto-mpv.7z"
        fi
        if [ ! -d $LOCALDESTDIR/bin-video/fonts ]; then
            mkdir -p $LOCALDESTDIR/bin-video/mpv
            cp fonts.conf $LOCALDESTDIR/bin-video/mpv/
            cp -R fonts $LOCALDESTDIR/bin-video/fonts
        fi
        unset mpv_ldflags mpv_pthreads
        do_checkIfExist mpv-git bin-video/mpv.exe
    fi
fi

echo "-------------------------------------------------------------------------------"
echo
echo "compile video tools $bits done..."
echo
echo "-------------------------------------------------------------------------------"
}

run_builds() {
    new_updates="no"
    new_updates_packages=""
    if [[ $build32 = "yes" ]]; then
        source /local32/etc/profile.local
        buildProcess
        echo "-------------------------------------------------------------------------------"
        echo "compile all tools 32bit done..."
        echo "-------------------------------------------------------------------------------"
    fi

    if [[ $build64 = "yes" ]]; then
        source /local64/etc/profile.local
        buildProcess
        echo "-------------------------------------------------------------------------------"
        echo "compile all tools 64bit done..."
        echo "-------------------------------------------------------------------------------"
    fi
}

run_builds

while [[ $new_updates = "yes" ]]; do
    ret="no"
    echo "-------------------------------------------------------------------------------"
    echo "There were new updates while compiling."
    echo "Updated:$new_updates_packages"
    echo "Would you like to run compilation again to get those updates? Default: no"
    read -p "y/[n] " ret
    echo "-------------------------------------------------------------------------------"
    [[ $ret = "y" || $ret = "Y" || $ret = "yes" ]] && run_builds || break
done

if [[ $stripping = "y" ]]; then
    echo -ne "\033]0;Stripping $bits binaries\007"
    echo
    echo "-------------------------------------------------------------------------------"
    echo
    printf "Stripping binaries and libs... "
    find /local*/{bin-*,lib} -regex ".*\.\(exe\|dll\)" -not -name x265.exe -newer $LOCALBUILDDIR/last_run | \
        xargs -r strip --strip-all
    find /local*/bin-video -name x265.exe -newer $LOCALBUILDDIR/last_run | xargs -r strip --strip-unneeded
    printf "done!\n"
fi

if [[ $packing = "y" ]]; then
    if [ ! -f "$LOCALBUILDDIR/upx391w/upx.exe" ]; then
        echo -ne "\033]0;Installing UPX\007"
        cd $LOCALBUILDDIR
        rm -rf upx391w
        do_wget "http://upx.sourceforge.net/download/upx391w.zip"
    fi
    echo -ne "\033]0;Packing $bits binaries\007"
    echo
    echo "-------------------------------------------------------------------------------"
    echo
    echo "Packing binaries and shared libs... "
    packcmd="$LOCALBUILDDIR/upx391w/upx.exe -9 -qq"
    [[ $stripping = "y" ]] && packcmd="$packcmd --strip-relocs=0"
    find /local*/bin-*  -regex ".*\.\(exe\|dll\)" -newer $LOCALBUILDDIR/last_run | xargs -r $packcmd
fi

echo
echo "-------------------------------------------------------------------------------"
echo
echo "deleting status files..."
cd $LOCALBUILDDIR
find . -maxdepth 2 -name recently_updated | xargs rm -f
find . -maxdepth 2 -regex ".*build_successful\(32\|64\)bit\(_shared\)?\$" | xargs rm -f
[[ -f ./last_run ]] && mv ./last_run ./last_successful_run
[[ -f ./CHANGELOG.txt ]] && cat ./CHANGELOG.txt >> ./newchangelog
mv ./newchangelog ./CHANGELOG.txt

if [[ $deleteSource = "y" ]]; then
    echo -ne "\033]0;deleting source folders\007"
    echo
    echo "deleting source folders..."
    echo
    find $LOCALBUILDDIR -mindepth 1 -maxdepth 1 -type d ! -regex ".*\(-\(git\|hg\|svn\)\|upx.*\)\$" | xargs rm -rf
fi

echo -ne "\033]0;compiling done...\007"
echo
echo "Window closing in 15 seconds..."
echo
sleep 5
echo
echo "Window closing in 10 seconds..."
echo
sleep 5
echo
echo "Window closing in 5 seconds..."
sleep 5
