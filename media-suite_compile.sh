# set CPU count global. This can be overwrite from the compiler script (media-autobuild_suite.bat)
cpuCount=1
compile="false"
buildFFmpeg="false"
newFfmpeg="no"
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
--mediainfo=* ) mediainfo="${1#*=}"; shift ;;
--sox=* ) sox="${1#*=}"; shift ;;
--ffmpeg=* ) ffmpeg="${1#*=}"; shift ;;
--ffmpegUpdate=* ) ffmpegUpdate="${1#*=}"; shift ;;
--mplayer=* ) mplayer="${1#*=}"; shift ;;
--mpv=* ) mpv="${1#*=}"; shift ;;
--mkv=* ) mkv="${1#*=}"; shift ;;
--deleteSource=* ) deleteSource="${1#*=}"; shift ;;
--nonfree=* ) nonfree="${1#*=}"; shift ;;
--stripping* ) stripping="${1#*=}"; shift ;;
--packing* ) packing="${1#*=}"; shift ;;
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
    oldHead=$(git rev-parse HEAD)
    git reset --quiet --hard @{u}
    git pull origin "$gitBranch"
    newHead=$(git rev-parse HEAD)

    pkg-config --exists "$gitFolder"
    local pcExists=$?

    if [[ "$oldHead" != "$newHead" ]]; then
        touch recently_updated
        rm -f build_successful*
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
local URL="$1"
local archive="$2"

if [[ -z $archive ]]; then
    wget --tries=20 --retry-connrefused --waitretry=2 --no-check-certificate -c $URL
else
    wget --tries=20 --retry-connrefused --waitretry=2 --no-check-certificate -c $URL -O $archive
fi
}

do_wget_tar() {
    local URL="$1"
    # rename archive to what the directory should look like, not what wget outputs
    local archive="$2"
    if [[ -z $archive ]]; then
        archive=`expr $URL : '.*/\(.*\.tar\.\(gz\|bz2\|xz\)\)'`
    fi
    local dirName=`expr $archive : '\(.*\)\.tar\.\(gz\|bz2\|xz\)'`

    # if dir exists and no builds were successful, better to redownload
    if [[ -d $dirName ]] && [[ ! -f $dirName/build_successful32bit && ! -f $dirName/build_successful64bit ]]; then
        rm -rf $dirName
    fi

    if [[ ! -d $dirName ]]; then
        wget --tries=20 --retry-connrefused --waitretry=2 --no-check-certificate -c $URL -O $archive
        tar -xaf $archive
        rm -f $archive
    fi
    cd $dirName
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
        touch $LOCALBUILDDIR/$packetName/build_successful$bits
        cd $LOCALBUILDIR
    else
        rm -f $LOCALBUILDDIR/$packetName/build_successful$bits
        echo -------------------------------------------------
        echo "Build of $packetName failed..."
        echo "Delete the source folder under '$LOCALBUILDDIR' and start again."
        echo "If you're sure there are no dependencies <Enter> to continue building."
        read -p "Close this window if you wish to stop building."
        sleep 5
    fi
}

do_pkgConfig() {
    local pkg=${1%% *}
    compile="true"
    echo -ne "\033]0;compiling $pkg $bits\007"

    pkg-config --exists $1

    if [[ $? = 0 ]]; then
        echo -------------------------------------------------
        echo "$pkg is already compiled"
        echo -------------------------------------------------
        compile="false"
    fi
}

buildProcess() {
cd $LOCALBUILDDIR
echo "-------------------------------------------------------------------------------"
echo
echo "compile global tools $bits"
echo
echo "-------------------------------------------------------------------------------"

if [ -f "$LOCALDESTDIR/lib/libopenjpeg.a" ]; then
    echo -------------------------------------------------
    echo "openjpeg-1.5.2 is already compiled"
    echo -------------------------------------------------
    else
        echo -ne "\033]0;compile openjpeg $bits\007"

        do_wget_tar "http://downloads.sourceforge.net/project/openjpeg.mirror/1.5.2/openjpeg-1.5.2.tar.gz"

        if [ -d "build" ]; then
            cd build
            if [[ -d $LOCALDESTDIR/lib/openjpeg-1.5 ]]; then
                rm -rf $LOCALDESTDIR/include/openjpeg-1.5 $LOCALDESTDIR/include/openjpeg.h
                rm -f $LOCALDESTDIR/lib/libopenj{peg{,_JPWL},pip_local}.a
                rm -f $LOCALDESTDIR/lib/openjpeg-1.5
            fi
            make clean
            rm -rf *
        else
            mkdir build
            cd build
        fi

        cmake .. -G "MSYS Makefiles" -DBUILD_SHARED_LIBS:BOOL=off -DBUILD_MJ2:BOOL=on -DBUILD_JPWL:BOOL=on -DBUILD_JPIP:BOOL=on -DBUILD_THIRDPARTY:BOOL=on -DCMAKE_INSTALL_PREFIX=$LOCALDESTDIR -DOPENJPEG_INSTALL_BIN_DIR=$LOCALDESTDIR/bin-global -DCMAKE_C_FLAGS="-mms-bitfields -mthreads -mtune=generic -pipe -DOPJ_STATIC"

        make -j $cpuCount
        make install

        do_checkIfExist openjpeg-1.5.2 libopenjpeg.a
        cp $LOCALDESTDIR/include/openjpeg-1.5/openjpeg.h $LOCALDESTDIR/include
fi

cd $LOCALBUILDDIR

do_pkgConfig "freetype2 = 17.4.11"

if [[ $compile = "true" ]]; then
    do_wget_tar "http://downloads.sourceforge.net/project/freetype/freetype2/2.5.5/freetype-2.5.5.tar.bz2"

    if [[ -f "objs/.libs/libfreetype.a" ]]; then
        make distclean
    fi
    if [[ -d "$LOCALDESTDIR/include/freetype2" ]]; then
        rm -rf $LOCALDESTDIR/include/freetype2 $LOCALDESTDIR/bin-global/freetype-config
        rm -rf $LOCALDESTDIR/lib/libfreetype.{l,}a $LOCALDESTDIR/lib/pkgconfig/freetype.pc
    fi

    ./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-global --disable-shared --with-harfbuzz=no
    make -j $cpuCount
    make install

    do_checkIfExist freetype-2.5.5 libfreetype.a
fi

cd $LOCALBUILDDIR

do_pkgConfig "fontconfig = 2.11.92"

if [[ $compile = "true" ]]; then
    do_wget_tar "http://www.freedesktop.org/software/fontconfig/release/fontconfig-2.11.92.tar.gz"

    if [[ -f "src/.libs/libfontconfig.a" ]]; then
        make distclean
    fi
    if [[ -d "$LOCALDESTDIR/include/fontconfig" ]]; then
        rm -rf $LOCALDESTDIR/include/fontconfig $LOCALDESTDIR/bin-global/fc-*
        rm -rf $LOCALDESTDIR/lib/libfontconfig.{l,}a $LOCALDESTDIR/lib/pkgconfig/fontconfig.pc
    fi

    ./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-global --enable-shared=no
    sed -i 's/-L${libdir} -lfontconfig[^l]*$/-L${libdir} -lfontconfig -lfreetype -lexpat/' fontconfig.pc

    make -j $cpuCount
    make install

    do_checkIfExist fontconfig-2.11.92 libfontconfig.a
fi

cd $LOCALBUILDDIR

do_pkgConfig "fribidi = 0.19.6"

if [[ $compile = "true" ]]; then
    do_wget_tar "http://fribidi.org/download/fribidi-0.19.6.tar.bz2"

    if [[ -f "lib/.libs/libfribidi.a" ]]; then
        make distclean
    fi
    if [[ -d "$LOCALDESTDIR/include/fribidi" ]]; then
        rm -rf $LOCALDESTDIR/include/fribidi $LOCALDESTDIR/bin-global/fribidi*
        rm -rf $LOCALDESTDIR/lib/libfribidi.{l,}a $LOCALDESTDIR/lib/pkgconfig/fribidi.pc
    fi

    ./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-global --enable-shared=no --with-glib=no
    make -j $cpuCount
    make install

if [ ! -f ${LOCALDESTDIR}/bin-global/fribidi-config ]; then
cat > ${LOCALDESTDIR}/bin-global/fribidi-config << "EOF"
#!/bin/sh
case $1 in
  --version)
    pkg-config --modversion fribidi
    ;;
  --cflags)
    pkg-config --cflags fribidi
    ;;
  --libs)
    pkg-config --libs fribidi
    ;;
  *)
    false
    ;;
esac
EOF
fi

    do_checkIfExist fribidi-0.19.6 libfribidi.a
fi

cd $LOCALBUILDDIR

if [[ `ragel --version | grep "version 6.9"` ]]; then
    echo -------------------------------------------------
    echo "ragel-6.9 is already compiled"
    echo -------------------------------------------------
    else
        echo -ne "\033]0;compile ragel $bits\007"

        do_wget_tar "http://www.colm.net/files/ragel/ragel-6.9.tar.gz"

        if [[ -f "ragel/ragel.exe" ]]; then
            make distclean
        fi
        if [[ -f "$LOCALDESTDIR/bin-global/ragel.exe" ]]; then
            rm -rf $LOCALDESTDIR/bin-global/ragel.exe
        fi

        ./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-global
        make -j $cpuCount
        make install

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

    ./configure --host=$targetHost --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-global --disable-shared --with-icu=no --with-glib=no --with-gobject=no LDFLAGS="$LDFLAGS -static -static-libgcc -static-libstdc++"
    make -j $cpuCount
    make install

    do_checkIfExist harfbuzz-git libharfbuzz.a
fi

cd $LOCALBUILDDIR

do_pkgConfig "sdl = 1.2.15"

if [[ $compile = "true" ]]; then
    do_wget_tar "http://www.libsdl.org/release/SDL-1.2.15.tar.gz"

    if [[ -f "build/.libs/libSDL.a" ]]; then
        make distclean
    fi
    if [[ -d "$LOCALDESTDIR/include/SDL" ]]; then
        rm -rf $LOCALDESTDIR/include/SDL $LOCALDESTDIR/bin-global/sdl-config
        rm -rf $LOCALDESTDIR/lib/libSDL{,main}.{l,}a $LOCALDESTDIR/lib/pkgconfig/sdl.pc
    fi

    CFLAGS="-DDECLSPEC=" ./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-global --enable-shared=no
    make -j $cpuCount
    make install

    sed -i "s/-mwindows//" "$LOCALDESTDIR/bin-global/sdl-config"
    sed -i "s/-mwindows//" "$LOCALDESTDIR/lib/pkgconfig/sdl.pc"

    do_checkIfExist SDL-1.2.15 libSDL.a
fi

#----------------------
# crypto engine
#----------------------
cd $LOCALBUILDDIR

if [[ `libgcrypt-config --version` = "1.6.2" ]]; then
    echo -------------------------------------------------
    echo "libgcrypt-1.6.2 is already compiled"
    echo -------------------------------------------------
    else
        echo -ne "\033]0;compile libgcrypt $bits\007"

        do_wget_tar "ftp://ftp.gnupg.org/gcrypt/libgcrypt/libgcrypt-1.6.2.tar.bz2"

        if [[ -f "src/.libs/libgcrypt.a" ]]; then
            make distclean
        fi
        if [[ -f "$LOCALDESTDIR/include/libgcrypt.h" ]]; then
            rm -rf $LOCALDESTDIR/include/libgcrypt.h $LOCALDESTDIR/bin-global/{dumpsexp,hmac256,mpicalc}.exe
            rm -rf $LOCALDESTDIR/lib/libgcrypt.{l,}a $LOCALDESTDIR/bin-global/libgcrypt-config
        fi

        if [[ "$bits" = "32bit" ]]; then
            ./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-global --disable-shared --with-gpg-error-prefix=$MINGW_PREFIX
        else
            ./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-global --disable-shared --with-gpg-error-prefix=$MINGW_PREFIX --disable-asm --disable-padlock-support
        fi
        make -j $cpuCount
        make install

        do_checkIfExist libgcrypt-1.6.2 libgcrypt.a
fi

cd $LOCALBUILDDIR

do_pkgConfig "nettle = 2.7.1"

if [[ $compile = "true" ]]; then
    do_wget_tar "https://ftp.gnu.org/gnu/nettle/nettle-2.7.1.tar.gz"

    if [[ -f "libnettle.a" ]]; then
        make distclean
    fi
    if [[ -d "$LOCALDESTDIR/include/nettle" ]]; then
        rm -rf $LOCALDESTDIR/include/nettle $LOCALDESTDIR/bin-global/nettle-*.exe
        rm -rf $LOCALDESTDIR/lib/libnettle.a $LOCALDESTDIR/lib/pkgconfig/nettle.pc
    fi

    ./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-global --disable-documentation --disable-openssl --disable-shared

    make -j $cpuCount
    make install

    do_checkIfExist nettle-2.7.1 libnettle.a
fi

cd $LOCALBUILDDIR

do_pkgConfig "gnutls = 3.3.15"

if [[ $compile = "true" ]]; then
    do_wget_tar "ftp://ftp.gnutls.org/gcrypt/gnutls/v3.3/gnutls-3.3.15.tar.xz"

    if [[ -f "lib/.libs/libgnutls.a" ]]; then
        make distclean
    fi
    if [[ -d "$LOCALDESTDIR/include/gnutls" ]]; then
        rm -rf $LOCALDESTDIR/include/gnutls $LOCALDESTDIR/bin-global/gnutls-*.exe
        rm -rf $LOCALDESTDIR/lib/libgnutls* $LOCALDESTDIR/lib/pkgconfig/gnutls.pc
    fi

    ./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-global --disable-guile --enable-cxx --disable-doc --disable-tests --disable-shared --with-zlib --without-p11-kit --disable-rpath --disable-gtk-doc --disable-libdane --enable-local-libopts

    make -j $cpuCount
    make install

    sed -i 's/-lgnutls *$/-lgnutls -lnettle -lhogweed -liconv -lcrypt32 -lws2_32 -lz -lgmp -lintl/' $LOCALDESTDIR/lib/pkgconfig/gnutls.pc

    do_checkIfExist gnutls-3.3.15 libgnutls.a
fi

cd $LOCALBUILDDIR

do_git "git://git.ffmpeg.org/rtmpdump" librtmp shallow master bin-video/rtmpdump.exe

if [[ $compile = "true" ]]; then
    if [ -f "$LOCALDESTDIR/lib/librtmp.a" ]; then
        rm -rf $LOCALDESTDIR/include/librtmp
        rm $LOCALDESTDIR/lib/librtmp.a
        rm $LOCALDESTDIR/lib/pkgconfig/librtmp.pc
        rm $LOCALDESTDIR/man/man3/librtmp.3
        rm $LOCALDESTDIR/bin-video/rtmpdump.exe $LOCALDESTDIR/bin-video/rtmpsuck.exe $LOCALDESTDIR/bin-video/rtmpsrv.exe $LOCALDESTDIR/bin-video/rtmpgw.exe
        rm $LOCALDESTDIR/man/man1/rtmpdump.1
        rm $LOCALDESTDIR/man/man8/rtmpgw.8
    fi
    if [[ -f "librtmp/librtmp.a" ]]; then
        make clean
    fi

    make XCFLAGS=$MINGW_PREFIX/include LDFLAGS="$LDFLAGS" prefix=$LOCALDESTDIR bindir=$LOCALDESTDIR/bin-video sbindir=$LOCALDESTDIR/bin-video CRYPTO=GNUTLS SHARED= SYS=mingw install LIBS="$LIBS -liconv -lrtmp -lgnutls -lhogweed -lnettle -lgmp -liconv -ltasn1 -lws2_32 -lwinmm -lgdi32 -lcrypt32 -lintl -lz -liconv" LIB_GNUTLS="-lgnutls -lhogweed -lnettle -lgmp -liconv -ltasn1" LIBS_mingw="-lws2_32 -lwinmm -lgdi32 -lcrypt32 -lintl"

    sed -i 's/Libs:.*/Libs: -L${libdir} -lrtmp -lwinmm -lz -lgmp -lintl/' $LOCALDESTDIR/lib/pkgconfig/librtmp.pc

    do_checkIfExist librtmp-git librtmp.a
fi

cd $LOCALBUILDDIR

do_pkgConfig "libxml-2.0 = 2.9.1"

if [[ $compile = "true" ]]; then
    do_wget_tar "ftp://xmlsoft.org/libxml2/libxml2-2.9.1.tar.gz"

    if [[ -f ".libs/libxml2.a" ]]; then
        make distclean
    fi
    if [[ -d "$LOCALDESTDIR/include/libxml2" ]]; then
        rm -rf $LOCALDESTDIR/include/libxml2 $LOCALDESTDIR/bin-global/xml*
        rm -rf $LOCALDESTDIR/lib/libxml2.{l,}a $LOCALDESTDIR/lib/pkgconfig/libxml-2.0.pc
        rm -rf $LOCALDESTDIR/lib/xml2Conf.sh
    fi

    ./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-global --disable-shared --enable-static

    make -j $cpuCount
    make install

    do_checkIfExist libxml2-2.9.1 libxml2.a
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libgnurx.a" ]; then
    echo -------------------------------------------------
    echo "libgnurx-2.5.1 is already compiled"
    echo -------------------------------------------------
    else
        echo -ne "\033]0;compile libgnurx $bits\007"

        do_wget_tar "http://downloads.sourceforge.net/project/mingw/Other/UserContributed/regex/mingw-regex-2.5.1/mingw-libgnurx-2.5.1-src.tar.gz" mingw-libgnurx-2.5.1.tar.gz

        if [[ -f ".libs/libgnurx.a" ]]; then
            make distclean
        fi
        if [[ -f "$LOCALDESTDIR/lib/libgnurx.a" ]]; then
            rm -rf $LOCALDESTDIR/lib/libgnurx.{l,}a
        fi

        rm -f configure.ac Makefile.am

        do_wget "https://raw.githubusercontent.com/Alexpux/MINGW-packages/master/mingw-w64-libgnurx/mingw32-libgnurx-Makefile.am" Makefile.am
        do_wget "https://raw.githubusercontent.com/Alexpux/MINGW-packages/master/mingw-w64-libgnurx/mingw32-libgnurx-configure.ac" configure.ac

        touch NEWS
        touch AUTHORS
        libtoolize --copy
        aclocal
        autoconf
        automake --add-missing

        ./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --enable-static=yes --enable-shared=no

        make -j $cpuCount
        make install

        do_checkIfExist mingw-libgnurx-2.5.1 libgnurx.a
fi

cd $LOCALBUILDDIR

if [[ `file --version | grep "file.exe-5.22"` ]]; then
    echo -------------------------------------------------
    echo "file-5.22[libmagic] is already compiled"
    echo -------------------------------------------------
    else
        echo -ne "\033]0;compile file $bits\007"

        do_wget_tar "ftp://ftp.astron.com/pub/file/file-5.22.tar.gz"

        if [[ -f "src/.libs/libmagic.a" ]]; then
            make distclean
        fi
        if [[ -f "$LOCALDESTDIR/lib/libmagic.a" ]]; then
            rm -rf $LOCALDESTDIR/include/magic.h $LOCALDESTDIR/bin-global/file.exe
            rm -rf $LOCALDESTDIR/lib/libmagic.{l,}a
        fi

        ./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-global --enable-static=yes --enable-shared=no CPPFLAGS='-DPCRE_STATIC' LIBS='-lpcre -lshlwapi -lz'

        make CPPFLAGS='-D_REGEX_RE_COMP' -j $cpuCount
        make install

        do_checkIfExist file-5.22 libmagic.a
fi

if [[ $mkv = "y" ]]; then

    cd $LOCALBUILDDIR

    if [[ `$LOCALDESTDIR/bin-global/wx-config --version` = "3.0.2" ]]; then
        echo -------------------------------------------------
        echo "wxWidgets is already compiled"
        echo -------------------------------------------------
    else
        echo -ne "\033]0;compile wxWidgets $bits\007"

        do_wget_tar "https://sourceforge.net/projects/wxwindows/files/3.0.2/wxWidgets-3.0.2.tar.bz2"

        if [[ -f config.log ]]; then
            make distclean
        fi

        CPPFLAGS+=" -fno-devirtualize" CFLAGS+=" -fno-devirtualize" configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-global --with-msw --disable-mslu --disable-shared --enable-static --enable-iniconf --enable-iff --enable-permissive --disable-monolithic --enable-unicode --enable-accessibility --disable-precomp-headers LDFLAGS="$LDFLAGS -static -static-libgcc -static-libstdc++"

        make -j $cpuCount
        make install

        do_checkIfExist wxWidgets-3.0.2 libwx_baseu-3.0.a
    fi

fi

echo "-------------------------------------------------------------------------------"
echo
echo "compile global tools $bits done..."
echo
echo "-------------------------------------------------------------------------------"

cd $LOCALBUILDDIR
echo "-------------------------------------------------------------------------------"
echo
echo "compile audio tools $bits"
echo
echo "-------------------------------------------------------------------------------"

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

    ./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --disable-shared

    make -j $cpuCount
    make install

    do_checkIfExist libilbc-git libilbc.a
fi

cd $LOCALBUILDDIR

do_pkgConfig "ogg = 1.3.2"

if [[ $compile = "true" ]]; then
    do_wget_tar "http://downloads.xiph.org/releases/ogg/libogg-1.3.2.tar.gz"

    if [[ -f "./src/.libs/libogg.a" ]]; then
        make distclean
    fi
    if [[ -d "$LOCALDESTDIR/include/ogg" ]]; then
        rm -rf $LOCALDESTDIR/include/ogg $LOCALDESTDIR/share/aclocal/ogg.m4
        rm -rf $LOCALDESTDIR/lib/libogg.{l,}a $LOCALDESTDIR/lib/pkgconfig/ogg.pc
    fi

    ./configure --build=$targetBuild --prefix=$LOCALDESTDIR --disable-shared

    make -j $cpuCount
    make install

    do_checkIfExist libogg-1.3.2 libogg.a
fi

cd $LOCALBUILDDIR

do_pkgConfig "vorbis = 1.3.5"

if [[ $compile = "true" ]]; then
    do_wget_tar "http://downloads.xiph.org/releases/vorbis/libvorbis-1.3.5.tar.gz"

    if [[ -f "./lib/.libs/libvorbis.a" ]]; then
        make distclean
    fi
    if [[ -d "$LOCALDESTDIR/include/vorbis" ]]; then
        rm -rf $LOCALDESTDIR/include/vorbis $LOCALDESTDIR/share/aclocal/vorbis.m4
        rm -rf $LOCALDESTDIR/lib/libvorbis{,enc,file}.{l,}a $LOCALDESTDIR/lib/pkgconfig/vorbis{,enc,file}.pc
    fi

    ./configure --build=$targetBuild --prefix=$LOCALDESTDIR --disable-shared

    make -j $cpuCount
    make install

    do_checkIfExist libvorbis-1.3.5 libvorbis.a
fi

cd $LOCALBUILDDIR

do_pkgConfig "opus = 1.1"

if [[ $compile = "true" ]]; then
    do_wget_tar "http://downloads.xiph.org/releases/opus/opus-1.1.tar.gz"

    if [[ -f ".libs/libopus.a" ]]; then
        make distclean
    fi
    if [[ -d "$LOCALDESTDIR/include/opus" ]]; then
        rm -rf $LOCALDESTDIR/include/opus
        rm -rf $LOCALDESTDIR/lib/libopus.{l,}a $LOCALDESTDIR/lib/pkgconfig/opus.pc
    fi

    do_wget "https://raw.github.com/jb-alvarado/media-autobuild_suite/master/patches/opus11.patch"
    patch -N -p0 < opus11.patch

    ./configure --build=$targetBuild --prefix=$LOCALDESTDIR --disable-shared --disable-doc

    make -j $cpuCount
    make install

    do_checkIfExist opus-1.1 libopus.a
fi

cd $LOCALBUILDDIR

do_pkgConfig "speex = 1.2rc1"

if [[ $compile = "true" ]]; then
    do_wget_tar "http://downloads.xiph.org/releases/speex/speex-1.2rc1.tar.gz"

    if [[ -f "libspeex/.libs/libspeex.a" ]]; then
        make distclean
    fi
    if [[ -d "$LOCALDESTDIR/include/speex" ]]; then
        rm -rf $LOCALDESTDIR/include/speex $LOCALDESTDIR/bin-audio/speex{enc,dec}.exe
        rm -rf $LOCALDESTDIR/lib/libspeex{,dsp}.{l,}a $LOCALDESTDIR/lib/pkgconfig/speex{,dsp}.pc
    fi

    ./configure --build=$targetBuild --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-audio --disable-shared --disable-oggtest

    make -j $cpuCount
    make install

    do_checkIfExist speex-1.2rc1 libspeex.a
fi

cd $LOCALBUILDDIR

do_pkgConfig "flac = 1.3.1"

if [[ $compile = "true" ]]; then
    do_wget_tar "http://downloads.xiph.org/releases/flac/flac-1.3.1.tar.xz"

    if [[ -f "src/libFLAC/.libs/libFLAC.a" ]]; then
        make distclean
    fi
    if [[ -d "$LOCALDESTDIR/include/FLAC" ]]; then
        rm -rf $LOCALDESTDIR/include/FLAC{,++} $LOCALDESTDIR/bin-audio/{meta,}flac.exe
        rm -rf $LOCALDESTDIR/lib/libFLAC.{l,}a $LOCALDESTDIR/lib/pkgconfig/flac{,++}.pc
    fi

    ./configure --build=$targetBuild --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-audio --disable-xmms-plugin --disable-doxygen-docs --disable-shared

    make -j $cpuCount
    make install

    do_checkIfExist flac-1.3.1 bin-audio/flac.exe
fi

cd $LOCALBUILDDIR

do_pkgConfig "vo-aacenc = 0.1.3"

if [[ $compile = "true" ]]; then
    do_wget_tar "http://downloads.sourceforge.net/project/opencore-amr/vo-aacenc/vo-aacenc-0.1.3.tar.gz"

    if [[ -f ".libs/libvo-aacenc.a" ]]; then
        make distclean
    fi
    if [[ -d "$LOCALDESTDIR/include/vo-aacenc" ]]; then
        rm -rf $LOCALDESTDIR/include/vo-aacenc
        rm -rf $LOCALDESTDIR/lib/libvo-aacenc.{l,}a $LOCALDESTDIR/lib/pkgconfig/vo-aacenc.pc
    fi

    ./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --enable-shared=no

    make -j $cpuCount
    make install

    do_checkIfExist vo-aacenc-0.1.3 libvo-aacenc.a
fi

cd $LOCALBUILDDIR

do_pkgConfig "opencore-amrnb = 0.1.3"

if [[ $compile = "true" ]]; then
    do_wget_tar "http://downloads.sourceforge.net/project/opencore-amr/opencore-amr/opencore-amr-0.1.3.tar.gz"

    if [[ -f "amrnb/.libs/libopencore-amrnb.a" ]]; then
        make distclean
    fi
    if [[ -d "$LOCALDESTDIR/include/opencore-amrnb" ]]; then
        rm -rf $LOCALDESTDIR/include/opencore-amr{nb,wb}
        rm -rf $LOCALDESTDIR/lib/libopencore-amr{nb,wb}.{l,}a $LOCALDESTDIR/lib/pkgconfig/opencore-amr{nb,wb}.pc
    fi

    ./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --enable-shared=no

    make -j $cpuCount
    make install

    do_checkIfExist opencore-amr-0.1.3 libopencore-amrnb.a
fi

cd $LOCALBUILDDIR

do_pkgConfig "vo-amrwbenc = 0.1.2"

if [[ $compile = "true" ]]; then
    do_wget_tar "http://downloads.sourceforge.net/project/opencore-amr/vo-amrwbenc/vo-amrwbenc-0.1.2.tar.gz"

    if [[ -f ".libs/libvo-amrwbenc.a" ]]; then
        make distclean
    fi
    if [[ -d "$LOCALDESTDIR/include/vo-amrwbenc" ]]; then
        rm -rf $LOCALDESTDIR/include/vo-amrwbenc
        rm -rf $LOCALDESTDIR/lib/libvo-amrwbenc.{l,}a $LOCALDESTDIR/lib/pkgconfig/vo-amrwbenc.pc
    fi

    ./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --enable-shared=no

    make -j $cpuCount
    make install

    do_checkIfExist vo-amrwbenc-0.1.2 libvo-amrwbenc.a
fi

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

    ./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --enable-shared=no

    make -j $cpuCount
    make install

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

    ./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-audio

    make -j $cpuCount
    make install

    do_checkIfExist bin-fdk-aac-git bin-audio/fdkaac.exe
fi

if [[ $mplayer = "y" ]] || [[ $ffmbc = "y" ]] && [[ $nonfree = "y" ]]; then

    cd $LOCALBUILDDIR

    if [[ `$LOCALDESTDIR/bin-audio/faac.exe | grep "FAAC 1.28"` ]]; then
        echo -------------------------------------------------
        echo "faac-1.28 is already compiled"
        echo -------------------------------------------------
        else
            echo -ne "\033]0;compile faac $bits\007"

            do_wget_tar "http://downloads.sourceforge.net/faac/faac-1.28.tar.gz"

            if [[ -f configure ]]; then
                make distclean
            else            
                sh bootstrap
            fi

            ./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-audio --enable-shared=no --without-mp4v2

            make -j $cpuCount
            make install

            do_checkIfExist faac-1.28 libfaac.a
    fi

fi

cd $LOCALBUILDDIR

if [[ `opusenc.exe --version | grep "opus-tools 0.1.9"` ]]; then
    echo -------------------------------------------------
    echo "opus-tools-0.1.9 is already compiled"
    echo -------------------------------------------------
    else
        echo -ne "\033]0;compile opus-tools $bits\007"

        do_wget_tar "http://downloads.xiph.org/releases/opus/opus-tools-0.1.9.tar.gz"

        if [[ -f "opusenc.exe" ]]; then
            make distclean
        fi
        if [[ -d "$LOCALDESTDIR/bin-audio/opusenc.exe" ]]; then
            rm -rf $LOCALDESTDIR/bin-audio/opus*
        fi

        ./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-audio LDFLAGS="$LDFLAGS -static -static-libgcc -static-libstdc++"

        make -j $cpuCount
        make install

        do_checkIfExist opus-tools-0.1.9 bin-audio/opusenc.exe
fi

cd $LOCALBUILDDIR

do_pkgConfig "soxr = 0.1.1"

if [[ $compile = "true" ]]; then
    do_wget_tar "http://sourceforge.net/projects/soxr/files/soxr-0.1.1-Source.tar.xz"

    sed -i 's|NOT WIN32|UNIX|g' ./src/CMakeLists.txt

    if [ -d "build" ]; then
        cd build
        if [[ -f $LOCALDESTDIR/include/soxr.h ]]; then
            rm -rf $LOCALDESTDIR/include/soxr{,-lsr}.h
            rm -f $LOCALDESTDIR/lib/soxr{,-lsr}.a
            rm -f $LOCALDESTDIR/lib/pkgconfig/soxr{,-lsr}.pc
        fi
        make clean
        rm -rf *
    else
        mkdir build
        cd build
    fi

    cmake .. -G "MSYS Makefiles" -DCMAKE_INSTALL_PREFIX=$LOCALDESTDIR -DHAVE_WORDS_BIGENDIAN_EXITCODE:bool=off -DBUILD_SHARED_LIBS:bool=off -DBUILD_EXAMPLES:bool=off -DWITH_SIMD:bool=on -DBUILD_TESTS:bool=off -DWITH_OPENMP:bool=off -DBUILD_LSR_TESTS:bool=off -DUNIX:bool=on

    make -j $cpuCount
    make install

    do_checkIfExist soxr-0.1.1-Source libsoxr.a
fi

cd $LOCALBUILDDIR

do_git "https://bitbucket.org/mpyne/game-music-emu.git" libgme

if [[ $compile = "true" ]]; then
    if [ -d "build" ]; then
        cd build
        if [[ -d $LOCALDESTDIR/include/gme ]]; then
            rm -rf $LOCALDESTDIR/include/gme
            rm -f $LOCALDESTDIR/lib/libgme.a
            rm -f $LOCALDESTDIR/lib/pkgconfig/libgme.pc
        fi
        make clean
        rm -rf *
    else
        mkdir build
        cd build
    fi
    
    cmake .. -G "MSYS Makefiles" -DCMAKE_INSTALL_PREFIX=$LOCALDESTDIR -DBUILD_SHARED_LIBS=OFF

    make -j $cpuCount
    make install

    do_checkIfExist libgme-git libgme.a
fi

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

    ./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --disable-shared

    # don't compile programs
    sed -i 's/ examples regtest tests programs//g' Makefile

    make -j $cpuCount
    make install

    do_checkIfExist sndfile-git libsndfile.a
fi

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
        
        ./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --disable-shared
        sed -i 's/frontend simplefrontend//' Makefile
        
        make -j $cpuCount
        make install
        
        do_checkIfExist twolame-git libtwolame.a
fi

cd $LOCALBUILDDIR

do_pkgConfig "libbs2b = 3.1.0"

if [[ $compile = "true" ]]; then
        do_wget_tar "http://downloads.sourceforge.net/project/bs2b/libbs2b/3.1.0/libbs2b-3.1.0.tar.gz"

        if [[ -f "src/.libs/libbs2b.a" ]]; then
            make distclean
        fi
        if [[ -d "$LOCALDESTDIR/include/bs2b" ]]; then
            rm -rf $LOCALDESTDIR/include/bs2b $LOCALDESTDIR/bin-audio/bs2b*
            rm -rf $LOCALDESTDIR/lib/libbs2b.{l,}a $LOCALDESTDIR/lib/pkgconfig/libbs2b.pc
        fi

        sed -i 's/bs2bconvert$(EXEEXT) bs2bstream$(EXEEXT)//' src/Makefile.in
        ./configure --build=$targetBuild --prefix=$LOCALDESTDIR --disable-shared

        make -j $cpuCount
        make install

        do_checkIfExist libbs2b-3.1.0 libbs2b.a
fi

cd $LOCALBUILDDIR

if [[ $sox = "y" ]]; then

    if [ -f "$LOCALDESTDIR/lib/libmad.a" ]; then
        echo -------------------------------------------------
        echo "libmad-0.15.1b is already compiled"
        echo -------------------------------------------------
    else
        echo -ne "\033]0;compile libmad $bits\007"

        do_wget_tar "ftp://ftp.mars.org/pub/mpeg/libmad-0.15.1b.tar.gz"

        if [[ -f ".libs/libmad.a" ]]; then
            make distclean
        fi
        if [[ -f "$LOCALDESTDIR/lib/libmad.a" ]]; then
            rm -rf $LOCALDESTDIR/include/mad.h
            rm -rf $LOCALDESTDIR/lib/libmad.{l,}a
        fi

        ./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --disable-shared --enable-fpm=intel --disable-debugging

        make -j $cpuCount
        make install

        do_checkIfExist libmad-0.15.1b libmad.a
    fi

    cd $LOCALBUILDDIR

    do_pkgConfig "opusfile = 0.6"

    if [[ $compile = "true" ]]; then
        do_wget_tar "http://downloads.xiph.org/releases/opus/opusfile-0.6.tar.gz"

        if [[ -f ".libs/libopusfile.a" ]]; then
            make distclean
        fi
        if [[ -d "$LOCALDESTDIR/include/opus" ]]; then
            rm -rf $LOCALDESTDIR/include/opus/opusfile.h $LOCALDESTDIR/lib/libopus{file,url}.{l,}a
            rm -rf $LOCALDESTDIR/lib/pkgconfig/opus{file,url}.pc
        fi

        ./configure --build=$targetBuild --prefix=$LOCALDESTDIR --disable-shared LIBS="$LIBS -lole32 -lgdi32"

        make -j $cpuCount
        make install

        do_checkIfExist opusfile-0.6 libopusfile.a
    fi

    cd $LOCALBUILDDIR

    do_git "git://git.code.sf.net/p/sox/code" sox

    if [[ $compile = "true" ]]; then
        sed -i 's|found_libgsm=yes|found_libgsm=no|g' configure.ac

        if [[ ! -f ./configure ]]; then
            autoreconf -i
        else
            rm -rf $LOCALDESTDIR/include/sox.h $LOCALDESTDIR/bin-audio/sox.exe
            rm -rf $LOCALDESTDIR/lib/libsox.{l,}a $LOCALDESTDIR/lib/pkgconfig/sox.pc
            make distclean
        fi

        ./configure --build=$targetBuild --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-audio --disable-shared CPPFLAGS='-DPCRE_STATIC' LIBS='-lpcre -lshlwapi -lz -lgnurx'

        make -j $cpuCount
        make install

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

cd $LOCALBUILDDIR

do_pkgConfig "theora = 1.1.1"

if [[ $compile = "true" ]]; then
    do_wget_tar "http://downloads.xiph.org/releases/theora/libtheora-1.1.1.tar.bz2"

    if [[ -f "lib/.libs/libtheora.a" ]]; then
        make distclean
    fi
    if [[ -d "$LOCALDESTDIR/include/theora" ]]; then
        rm -rf $LOCALDESTDIR/include/theora $LOCALDESTDIR/lib/libtheora{,enc,dec}.{l,}a
        rm -rf $LOCALDESTDIR/lib/pkgconfig/theora{,enc,dec}.pc
    fi

    ./configure --build=$targetBuild --prefix=$LOCALDESTDIR --disable-shared --disable-examples

    make -j $cpuCount
    make install

    do_checkIfExist libtheora-1.1.1 libtheora.a
fi

cd $LOCALBUILDDIR

if [[ ! $vpx = "n" ]]; then
    do_git "https://git.chromium.org/git/webm/libvpx.git" vpx noDepth

    if [[ $compile = "true" ]]; then
        if [ -d $LOCALDESTDIR/include/vpx ]; then
            rm -rf $LOCALDESTDIR/include/vpx
            rm -f $LOCALDESTDIR/lib/pkgconfig/vpx.pc
            rm -f $LOCALDESTDIR/lib/libvpx.a
        fi

        if [ -f libvpx.a ]; then
            make distclean
        fi

        if [[ $bits = "64bit" ]]; then
            LDFLAGS="$LDFLAGS -static-libgcc -static" ./configure --prefix=$LOCALDESTDIR --target=x86_64-win64-gcc --disable-shared --enable-static --disable-unit-tests --disable-docs --enable-postproc --enable-vp9-postproc --enable-runtime-cpu-detect --enable-vp9-highbitdepth
            sed -i 's/HAVE_GNU_STRIP=yes/HAVE_GNU_STRIP=no/g' libs-x86_64-win64-gcc.mk
        else
            LDFLAGS="$LDFLAGS -static-libgcc -static" ./configure --prefix=$LOCALDESTDIR --target=x86-win32-gcc --disable-shared --enable-static --disable-unit-tests --disable-docs --enable-postproc --enable-vp9-postproc --enable-runtime-cpu-detect --enable-vp9-highbitdepth
            sed -i 's/HAVE_GNU_STRIP=yes/HAVE_GNU_STRIP=no/g' libs-x86-win32-gcc.mk
        fi

        make -j $cpuCount
        make install

        if [[ $vpx = "y" ]]; then
            mv $LOCALDESTDIR/bin/vpx{enc,dec}.exe $LOCALDESTDIR/bin-video
        else
            rm -f $LOCALDESTDIR/bin/vpx{enc,dec}.exe
        fi

        do_checkIfExist vpx-git libvpx.a
        buildFFmpeg="true"
    fi
    builtvpx="--enable-libvpx"
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

        ./configure --build=$targetBuild --prefix=$LOCALDESTDIR --disable-shared

        make -j $cpuCount
        make install

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

        ./configure --build=$targetBuild --prefix=$LOCALDESTDIR --disable-shared

        make -j $cpuCount
        make install

        do_checkIfExist dvdnav-git libdvdnav.a
    fi
fi

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

    ./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-video --disable-shared --enable-static --disable-examples --disable-bdjava --disable-doxygen-doc --disable-doxygen-dot LIBXML2_LIBS="-L$LOCALDESTDIR/lib -lxml2" LIBXML2_CFLAGS="-I$LOCALDESTDIR/include/libxml2 -DLIBXML_STATIC"

    make -j $cpuCount
    make install

    do_checkIfExist libbluray-git libbluray.a
fi

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

    CPPFLAGS=' -DFRIBIDI_ENTRY="" ' ./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --enable-shared=no

    make -j $cpuCount
    make install

    sed -i 's/-lass -lm/-lass -lfribidi -lm/' "$LOCALDESTDIR/lib/pkgconfig/libass.pc"

    do_checkIfExist libass-git libass.a
    buildFFmpeg="true"
fi

cd $LOCALBUILDDIR

if [ -f "$LOCALDESTDIR/lib/libxavs.a" ]; then
    echo -------------------------------------------------
    echo "xavs is already compiled"
    echo -------------------------------------------------
    else
        echo -ne "\033]0;compile xavs $bits\007"

        if [[ ! -d xavs ]]; then
            svn checkout --trust-server-cert --non-interactive https://svn.code.sf.net/p/xavs/code/trunk/ xavs
        fi

        cd xavs

        if [[ -f "libxavs.a" ]]; then
            make distclean
        fi
        if [[ -f "$LOCALDESTDIR/include/xavs.h" ]]; then
            rm -rf $LOCALDESTDIR/include/xavs.h
            rm -rf $LOCALDESTDIR/lib/libxavs.a $LOCALDESTDIR/lib/pkgconfig/xavs.pc
        fi

        ./configure --host=$targetHost --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-video

        make -j $cpuCount libxavs.a

        install -m 644 xavs.h $LOCALDESTDIR/include
        install -m 644 libxavs.a $LOCALDESTDIR/lib
        install -m 644 xavs.pc $LOCALDESTDIR/lib/pkgconfig

        do_checkIfExist xavs libxavs.a
fi

if [ $mediainfo = "y" ]; then
    cd $LOCALBUILDDIR

    if [ -f "$LOCALDESTDIR/bin-video/mediainfo.exe" ]; then
        echo -------------------------------------------------
        echo "MediaInfo_CLI is already compiled"
        echo -------------------------------------------------
    else
        echo -ne "\033]0;compile MediaInfo_CLI $bits\007"

        if [[ ! -d mediainfo ]]; then
            a=`wget -qO- "http://sourceforge.net/projects/mediainfo/files/source/mediainfo/" | sed "s/<tbody>/\n<tbody>\n/g;s/<\/tbody>/\n<\/tbody>\n/g" | awk "/<tbody>/,/<\/tbody>/" | grep "tr.*title.*class.*folder" | sed "s/<tr.\.*title=\d034//g;s/\d034 class.*$//g" | sed "q1" | sed "s/%%20//g" | sed "s/ //g"`

            b=`wget -qO- "http://sourceforge.net/projects/mediainfo/files/source/mediainfo/$a/" | sed "s/<tbody>/\n<tbody>\n/g;s/<\/tbody>/\n<\/tbody>\n/g" | awk "/<tbody>/,/<\/tbody>/" | grep "tr.*title.*class.*file" | sed "s/<tr.\.*title=\d034//g;s/\d034 class.*$//g" | grep "7z" | sed "s/ //g"`

            do_wget "http://sourceforge.net/projects/mediainfo/files/source/mediainfo/$a/$b/download" mediainfo.7z

            mkdir mediainfo
            7za x -omediainfo mediainfo.7z
            rm mediainfo.7z
        fi

        cd mediainfo

        sed -i '/#include <windows.h>/ a\#include <time.h>' ZenLib/Source/ZenLib/Ztring.cpp
        cd ZenLib/Project/GNU/Library

        if [[ -f ".libs/libzen.a" ]]; then
            make distclean
        fi

        ./autogen
        ./configure --build=$targetBuild --host=$targetHost

        if [[ $bits = "64bit" ]]; then
            sed -i 's/ -DSIZE_T_IS_LONG//g' Makefile
        fi
        make -j $cpuCount

        cd ../../../../MediaInfoLib/Project/GNU/Library

        if [[ -f ".libs/libmediainfo.a" ]]; then
            make distclean
        fi

        ./autogen
        ./configure --build=$targetBuild --host=$targetHost LDFLAGS="$LDFLAGS -static-libgcc"

        if [[ $bits = "64bit" ]]; then
            sed -i 's/ -DSIZE_T_IS_LONG//g' Makefile
        fi

        make -j $cpuCount

        cd ../../../../MediaInfo/Project/GNU/CLI

        if [[ -f "mediainfo.exe" ]]; then
            make distclean
        fi

        ./autogen
        ./configure --build=$targetBuild --host=$targetHost --enable-staticlibs --enable-shared=no LDFLAGS="$LDFLAGS -static-libgcc"

        if [[ $bits = "64bit" ]]; then
            sed -i 's/ -DSIZE_T_IS_LONG//g' Makefile
        fi

        make -j $cpuCount

        cp mediainfo.exe $LOCALDESTDIR/bin-video/mediainfo.exe

        do_checkIfExist mediainfo bin-video/mediainfo.exe
    fi
fi

cd $LOCALBUILDDIR

do_git "https://github.com/georgmartius/vid.stab.git" vidstab

if [[ $compile = "true" ]]; then
    if [ -d "build" ]; then
        cd build
        rm -rf $LOCALDESTDIR/include/vid.stab $LOCALDESTDIR/lib/libvidstab.a
        rm -rf $LOCALDESTDIR/lib/pkgconfig/vidstab.pc
        make clean
        rm -rf *
    else
        mkdir build
        cd build
    fi

    cmake .. -G "MSYS Makefiles" -DCMAKE_INSTALL_PREFIX=$LOCALDESTDIR -DBUILD_SHARED_LIBS:BOOL=off -DUSE_OMP:bool=off
    sed -i 's/ -fPIC//g' CMakeFiles/vidstab.dir/flags.make

    make -j $cpuCount
    make install

    do_checkIfExist vidstab-git libvidstab.a
    buildFFmpeg="true"
fi

cd $LOCALBUILDDIR

do_pkgConfig "caca = 0.99.beta19"

if [[ $compile = "true" ]]; then
    do_wget_tar "https://fossies.org/linux/privat/libcaca-0.99.beta19.tar.gz"

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
    cd ..

    ./configure --build=$targetBuild --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-global --disable-shared --disable-cxx --disable-csharp --disable-ncurses --disable-java --disable-python --disable-ruby --disable-imlib2 --disable-doc

    sed -i 's/ln -sf/$(LN_S)/' "doc/Makefile"

    make -j $cpuCount
    make install

    do_checkIfExist libcaca-0.99.beta19 libcaca.a
fi

cd $LOCALBUILDDIR

do_pkgConfig "zvbi-0.2 = 0.2.35"

if [[ $compile = "true" ]]; then
    do_wget_tar "http://sourceforge.net/projects/zapping/files/zvbi/0.2.35/zvbi-0.2.35.tar.bz2"

    if [[ -f "src/.libs/libzvbi.a" ]]; then
        make distclean
    fi
    if [[ -f "$LOCALDESTDIR/include/libzvbi.h" ]]; then
        rm -rf $LOCALDESTDIR/include/libzvbi.h
        rm -rf $LOCALDESTDIR/lib/libzvbi.{l,}a $LOCALDESTDIR/lib/pkgconfig/zvbi-0.2.pc
    fi

    do_wget "https://raw.github.com/jb-alvarado/media-autobuild_suite/master/patches/zvbi-win32.patch"
    do_wget "https://raw.github.com/jb-alvarado/media-autobuild_suite/master/patches/zvbi-ioctl.patch"
    patch -N -p0 < zvbi-win32.patch
    patch -N -p0 < zvbi-ioctl.patch

    ./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR --disable-shared --disable-dvb --disable-bktr --disable-nls --disable-proxy --without-doxygen CFLAGS="$CFLAGS -DPTW32_STATIC_LIB" LIBS="$LIBS -lpng"

    cd src

    make -j $cpuCount
    make install

    cp ../zvbi-0.2.pc $LOCALDESTDIR/lib/pkgconfig

    do_checkIfExist zvbi-0.2.35 libzvbi.a
fi

cd $LOCALBUILDDIR

do_pkgConfig "frei0r = 1.3.0"

if [[ $compile = "true" ]]; then
    do_wget_tar "https://files.dyne.org/frei0r/releases/frei0r-plugins-1.4.tar.gz"

    sed -i 's/find_package (Cairo)//' "CMakeLists.txt"

    if [ -d "build" ]; then
        cd build
        if [[ -f $LOCALDESTDIR/include/frei0r.h ]]; then
            rm -rf $LOCALDESTDIR/include/frei0r.h
            rm -rf $LOCALDESTDIR/lib/frei0r-1 $LOCALDESTDIR/lib/pkgconfig/frei0r.pc
        fi
        make clean
        rm -rf *
    else
        mkdir build
        cd build
    fi

    cmake -G "MSYS Makefiles" -DCMAKE_INSTALL_PREFIX=$LOCALDESTDIR ..

    make -j $cpuCount
    make all install

    do_checkIfExist frei0r-plugins-1.4 frei0r-1/xfade0r.dll
fi

if [[ $ffmpeg = "y" ]]; then
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

if [[ $ffmpeg = "y" ]] && [[ $nonfree = "y" ]]; then
    cd $LOCALBUILDDIR

    if [[ -f $LOCALDESTDIR/include/nvEncodeAPI.h ]]; then
        echo -------------------------------------------------
        echo "nvenc is already installed"
        echo -------------------------------------------------
    else
        echo -ne "\033]0;install nvenc $bits\007"
        rm -rf nvenc_5.0.1_sdk
        do_wget http://developer.download.nvidia.com/compute/nvenc/v5.0/nvenc_5.0.1_sdk.zip
        unzip nvenc_5.0.1_sdk.zip
        rm nvenc_5.0.1_sdk.zip
        
        if [[ $build32 = "yes" ]] && [[ ! -f /local32/include/nvEncodeAPI.h ]]; then
            cp nvenc_5.0.1_sdk/Samples/common/inc/* /local32/include
        fi
        
        if [[ $build64 = "yes" ]] && [[ ! -f /local64/include/nvEncodeAPI.h ]]; then
            cp nvenc_5.0.1_sdk/Samples/common/inc/* /local64/include
        fi
    
        do_checkIfExist nvEncodeAPI "include/nvEncodeAPI.h"
    fi
fi

#------------------------------------------------
# final tools
#------------------------------------------------

cd $LOCALBUILDDIR

if [[ $mp4box = "y" ]]; then
    do_git "https://github.com/gpac/gpac.git" gpac shallow master bin-video/MP4Box.exe

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

cd $LOCALBUILDDIR

if [[ ! $x264 = "n" ]]; then
    do_git "git://git.videolan.org/x264.git" x264 noDepth

    if [[ $compile = "true" ]]; then
        if [[ $x264 = "y" ]]; then
            cd $LOCALBUILDDIR

            do_git "https://github.com/FFmpeg/FFmpeg.git" ffmpeg noDepth master lib/libavcodec.a

            if [ -f "$LOCALDESTDIR/lib/libavcodec.a" ]; then
                rm -rf $LOCALDESTDIR/include/libavutil
                rm -rf $LOCALDESTDIR/include/libavcodec
                rm -rf $LOCALDESTDIR/include/libpostproc
                rm -rf $LOCALDESTDIR/include/libswresample
                rm -rf $LOCALDESTDIR/include/libswscale
                rm -rf $LOCALDESTDIR/include/libavdevice
                rm -rf $LOCALDESTDIR/include/libavfilter
                rm -rf $LOCALDESTDIR/include/libavformat
                rm -f $LOCALDESTDIR/lib/libavutil.a
                rm -f $LOCALDESTDIR/lib/libswresample.a
                rm -f $LOCALDESTDIR/lib/libswscale.a
                rm -f $LOCALDESTDIR/lib/libavcodec.a
                rm -f $LOCALDESTDIR/lib/libavdevice.a
                rm -f $LOCALDESTDIR/lib/libavfilter.a
                rm -f $LOCALDESTDIR/lib/libavformat.a
                rm -f $LOCALDESTDIR/lib/libpostproc.a
                rm -f $LOCALDESTDIR/lib/pkgconfig/libavcodec.pc
                rm -f $LOCALDESTDIR/lib/pkgconfig/libavutil.pc
                rm -f $LOCALDESTDIR/lib/pkgconfig/libpostproc.pc
                rm -f $LOCALDESTDIR/lib/pkgconfig/libswresample.pc
                rm -f $LOCALDESTDIR/lib/pkgconfig/libswscale.pc
                rm -f $LOCALDESTDIR/lib/pkgconfig/libavdevice.pc
                rm -f $LOCALDESTDIR/lib/pkgconfig/libavfilter.pc
                rm -f $LOCALDESTDIR/lib/pkgconfig/libavformat.pc
            fi

            if [ -f "config.mak" ]; then
                make distclean
            fi

            if [[ $bits = "32bit" ]]; then
                arch='x86'
            else
                arch='x86_64'
            fi

            ./configure --arch=$arch --target-os=mingw32 --prefix=$LOCALDESTDIR --disable-debug --disable-shared --disable-doc --enable-runtime-cpudetect --disable-programs --disable-devices --disable-filters --disable-encoders --disable-muxers

            make -j $cpuCount
            make install

            do_checkIfExist ffmpeg-git libavcodec.a

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
            ./configure --host=$targetHost --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-video --enable-static --bit-depth=10 --enable-win32thread
            make -j $cpuCount

            cp x264.exe $LOCALDESTDIR/bin-video/x264-10bit.exe
            make clean

            ./configure --host=$targetHost --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-video --enable-static --enable-win32thread
        else
            ./configure --host=$targetHost --prefix=$LOCALDESTDIR --enable-static --enable-win32thread --disable-interlaced --disable-swscale --disable-lavf --disable-ffms --disable-gpac --disable-lsmash --bit-depth=8 --disable-cli
        fi

        make -j $cpuCount
        make install

        do_checkIfExist x264-git libx264.a
        buildFFmpeg="true"
    fi
    builtx264="--enable-libx264"
fi

cd $LOCALBUILDDIR

if [[ ! $x265 = "n" ]]; then
    do_hg "https://bitbucket.org/multicoreware/x265" x265

    if [[ $compile = "true" ]]; then
        cd build/msys
        rm -rf $LOCALBUILDDIR/x265-hg/build/msys/*
        rm -f $LOCALDESTDIR/include/x265.h
        rm -f $LOCALDESTDIR/include/x265_config.h
        rm -f $LOCALDESTDIR/lib/libx265.a
        rm -f $LOCALDESTDIR/lib/pkgconfig/x265.pc
        rm -f $LOCALDESTDIR/bin-video/libx265*.dll
        rm -f $LOCALDESTDIR/bin-video/x265.exe

        if [[ $bits = "32bit" ]]; then
            xpsupport="-DWINXP_SUPPORT:BOOL=TRUE"
            assembly="-DENABLE_ASSEMBLY=OFF"
        fi

        # shared 16-bit libx265_main10.dll
        cmake -G "MSYS Makefiles" $xpsupport $assembly -DHIGH_BIT_DEPTH=1 -DENABLE_CLI:BOOLEAN=OFF ../../source -DENABLE_SHARED:BOOLEAN=ON -DHG_EXECUTABLE=/usr/bin/hg.bat -DCMAKE_CXX_FLAGS_RELEASE:STRING="-O3 -DNDEBUG $CXXFLAGS" -DCMAKE_CXX_FLAGS="-static-libgcc -static-libstdc++" -DCMAKE_C_FLAGS="-static-libgcc -static-libstdc++"

        make -j $cpuCount
        cp libx265.dll $LOCALDESTDIR/bin-video/libx265_main10.dll

        rm -rf $LOCALBUILDDIR/x265-hg/build/msys/*

        if [[ $x265 = "y" ]]; then
            # 8-bit static x265.exe
            cmake -G "MSYS Makefiles" $xpsupport -DCMAKE_INSTALL_PREFIX:PATH=$LOCALDESTDIR -DENABLE_CLI:BOOLEAN=ON  ../../source -DENABLE_SHARED:BOOLEAN=OFF -DHG_EXECUTABLE=/usr/bin/hg.bat -DCMAKE_CXX_FLAGS="-static-libgcc -static-libstdc++" -DCMAKE_C_FLAGS="-static-libgcc -static-libstdc++" -DBIN_INSTALL_DIR=$LOCALDESTDIR/bin-video -DCMAKE_CXX_FLAGS_RELEASE:STRING="-O3 -DNDEBUG $CXXFLAGS" -DCMAKE_EXE_LINKER_FLAGS_RELEASE:STRING="$LDFLAGS -static"
        else
            # 8-bit static libx265.a
            cmake -G "MSYS Makefiles" $xpsupport -DCMAKE_INSTALL_PREFIX:PATH=$LOCALDESTDIR -DENABLE_CLI:BOOLEAN=OFF ../../source -DENABLE_SHARED:BOOLEAN=OFF -DHG_EXECUTABLE=/usr/bin/hg.bat -DCMAKE_CXX_FLAGS="-static-libgcc -static-libstdc++" -DCMAKE_C_FLAGS="-static-libgcc -static-libstdc++"
        fi

        make -j $cpuCount
        make install

        do_checkIfExist x265-hg libx265.a
        buildFFmpeg="true"
    fi
    builtx265="--enable-libx265"
fi

cd $LOCALBUILDDIR

if [[ $ffmbc = "y" ]]; then
    if [[ `$LOCALDESTDIR/bin-video/ffmbc.exe 2>&1 | grep "version 0.7.4"` ]]; then
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

            do_wget_tar "https://drive.google.com/uc?id=0B0jxxycBojSwZTNqOUg0bzEta00&export=download" FFmbc-0.7.4.tar.bz2


            if [[ $bits = "32bit" ]]; then
                arch='x86'
            else
                arch='x86_64'
            fi

            if [ -f "config.log" ]; then
                make distclean
            fi

            ./configure --arch=$arch --target-os=mingw32 --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-video --disable-debug --disable-shared --disable-doc --disable-avdevice --disable-dxva2 --disable-ffprobe --disable-w32threads --enable-gpl --enable-runtime-cpudetect --enable-bzlib --enable-zlib --enable-librtmp --enable-avisynth --enable-frei0r --enable-libopenjpeg --enable-libass --enable-libmp3lame --enable-libschroedinger --enable-libspeex --enable-libtheora --enable-libvorbis $builtvpx --enable-libxavs $builtx264 --enable-libxvid $extras --extra-cflags='-DPTW32_STATIC_LIB' --extra-libs='-ltasn1 -ldl -liconv -lpng -lorc-0.4'

            make SRC_DIR=. -j $cpuCount
            make SRC_DIR=. install-progs

            do_checkIfExist FFmbc-0.7.4 bin-video/ffmbc.exe
    fi
fi

cd $LOCALBUILDDIR

if [[ $ffmpeg = "y" ]] || [[ $ffmpeg = "s" ]]; then
    if [[ $nonfree = "y" ]]; then
        extras="--enable-nonfree --enable-libfdk-aac --enable-nvenc"
    else
        extras=""
    fi

    echo "-------------------------------------------------------------------------------"
    echo "compile ffmpeg $bits"
    echo "-------------------------------------------------------------------------------"

    do_git "https://github.com/FFmpeg/FFmpeg.git" ffmpeg noDepth master bin-video/ffmpeg.exe

    if [[ $compile = "true" ]] || [[ $buildFFmpeg = "true" ]]; then
        if [ -f "$LOCALDESTDIR/lib/libavcodec.a" ]; then
            rm -rf $LOCALDESTDIR/include/libavutil
            rm -rf $LOCALDESTDIR/include/libavcodec
            rm -rf $LOCALDESTDIR/include/libpostproc
            rm -rf $LOCALDESTDIR/include/libswresample
            rm -rf $LOCALDESTDIR/include/libswscale
            rm -rf $LOCALDESTDIR/include/libavdevice
            rm -rf $LOCALDESTDIR/include/libavfilter
            rm -rf $LOCALDESTDIR/include/libavformat
            rm -f $LOCALDESTDIR/lib/libavutil.a
            rm -f $LOCALDESTDIR/lib/libswresample.a
            rm -f $LOCALDESTDIR/lib/libswscale.a
            rm -f $LOCALDESTDIR/lib/libavcodec.a
            rm -f $LOCALDESTDIR/lib/libavdevice.a
            rm -f $LOCALDESTDIR/lib/libavfilter.a
            rm -f $LOCALDESTDIR/lib/libavformat.a
            rm -f $LOCALDESTDIR/lib/libpostproc.a
            rm -f $LOCALDESTDIR/lib/pkgconfig/libavcodec.pc
            rm -f $LOCALDESTDIR/lib/pkgconfig/libavutil.pc
            rm -f $LOCALDESTDIR/lib/pkgconfig/libpostproc.pc
            rm -f $LOCALDESTDIR/lib/pkgconfig/libswresample.pc
            rm -f $LOCALDESTDIR/lib/pkgconfig/libswscale.pc
            rm -f $LOCALDESTDIR/lib/pkgconfig/libavdevice.pc
            rm -f $LOCALDESTDIR/lib/pkgconfig/libavfilter.pc
            rm -f $LOCALDESTDIR/lib/pkgconfig/libavformat.pc
        fi

        if [ -f "config.mak" ]; then
            make distclean
        fi

        if [[ $bits = "32bit" ]]; then
            arch='x86'
        else
            arch='x86_64'
        fi

        do_wget "https://raw.github.com/jb-alvarado/media-autobuild_suite/master/patches/ffmpeg-use-pkg-config-for-more-external-libs.patch"
        patch -N -i ffmpeg-use-pkg-config-for-more-external-libs.patch

        if [[ $ffmpeg = "s" ]]; then
            if [ -f "$LOCALDESTDIR/bin-video/ffmpegSHARED/bin/ffmpeg.exe" ]; then
                rm -rf $LOCALDESTDIR/bin-video/ffmpegSHARED
            fi
            CPPFLAGS='-DFRIBIDI_ENTRY=""' LDFLAGS="$LDFLAGS -static-libgcc" ./configure \
            --arch=$arch --target-os=mingw32 --prefix=$LOCALDESTDIR/bin-video/ffmpegSHARED \
            --disable-debug --disable-doc --disable-w32threads --enable-gpl --enable-version3 \
            --disable-static --enable-shared \
            --enable-librtmp --enable-gnutls --enable-avisynth --enable-frei0r --enable-filter=frei0r \
            --enable-libbluray --enable-libcaca --enable-libopenjpeg --enable-fontconfig --enable-libfreetype \
            --enable-libass --enable-libgsm --enable-libilbc --enable-libmodplug --enable-libmp3lame \
            --enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libvo-amrwbenc --enable-libschroedinger \
            --enable-libsoxr --enable-libtwolame --enable-libspeex --enable-libtheora --enable-libvorbis \
            --enable-libvo-aacenc --enable-libopus --enable-libvidstab --enable-libxavs \
            --enable-libxvid --enable-libzvbi --enable-libdcadec --enable-libbs2b \
            $builtvpx $builtx264 $builtx265 $extras \
            --extra-cflags='-DPTW32_STATIC_LIB -DCACA_STATIC -DMODPLUG_STATIC' \
            --extra-libs='-lpng -lpthread -lwsock32' \
            --extra-ldflags='-mconsole -Wl,--allow-multiple-definition'

            sed -i "s|--target-os=mingw32 --prefix=$LOCALDESTDIR/bin-video/ffmpegSHARED ||g" config.h
        else
            CPPFLAGS='-DFRIBIDI_ENTRY=""' ./configure \
            --arch=$arch --target-os=mingw32 --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-video \
            --disable-debug --disable-doc --disable-w32threads --enable-gpl --enable-version3 \
            --enable-static --disable-shared \
            --enable-decklink --enable-libutvideo --enable-libgme \
            --enable-librtmp --enable-gnutls --enable-avisynth --enable-frei0r --enable-filter=frei0r \
            --enable-libbluray --enable-libcaca --enable-libopenjpeg --enable-fontconfig --enable-libfreetype \
            --enable-libass --enable-libgsm --enable-libilbc --enable-libmodplug --enable-libmp3lame \
            --enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libvo-amrwbenc --enable-libschroedinger \
            --enable-libsoxr --enable-libtwolame --enable-libspeex --enable-libtheora --enable-libvorbis \
            --enable-libvo-aacenc --enable-libopus --enable-libvidstab --enable-libxavs \
            --enable-libxvid --enable-libzvbi --enable-libdcadec --enable-libbs2b \
            $builtvpx $builtx264 $builtx265 $extras \
            --extra-cflags='-DPTW32_STATIC_LIB -DCACA_STATIC -DMODPLUG_STATIC' \
            --extra-libs='-lpng -lpthread -lwsock32' \
            --extra-ldflags='-mconsole -Wl,--allow-multiple-definition'

            newFfmpeg="yes"

            sed -i "s|--target-os=mingw32 --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-video ||g" config.h
        fi

        sed -i "s/ --extra-cflags='-DPTW32_STATIC_LIB -DCACA_STATIC -DMODPLUG_STATIC' --extra-libs='-lpng -lpthread -lwsock32' --extra-ldflags='-mconsole -Wl,--allow-multiple-definition'//g" config.h

        make -j $cpuCount
        make install

        if [[ ! $ffmpeg = "s" ]]; then
            sed -i "s/Libs: -L\${libdir}  -lswresample -lm/Libs: -L\${libdir}  -lswresample -lm -lsoxr/g" $LOCALDESTDIR/lib/pkgconfig/libswresample.pc

            do_checkIfExist ffmpeg-git libavcodec.a
        else
            do_checkIfExist ffmpeg-git bin-video/ffmpegSHARED/bin/ffmpeg.exe
        fi
    fi
fi

if [[ $bits = "64bit" && $other265 = "y" && $ffmpeg = "y" ]]; then
    cd $LOCALBUILDDIR

    do_git "http://f265.org/repos/f265/" f265 noDepth master bin-video/f265cli.exe
    if [[ $compile = "true" ]] || [[ $newFfmpeg = "yes" ]]; then
        if [ -d "build" ] || [[ -f "$LOCALDESTDIR/bin-video/f265cli.exe" ]]; then
            rm -rf build
            rm -rf .sconf_temp
            rm -f .sconsign.dblite
            rm -f config.log
            rm -f options.py
            rm -f $LOCALDESTDIR/bin-video/f265cli.exe
        fi

        scons

        if [ -f build/f265cli.exe ]; then
            cp build/f265cli.exe $LOCALDESTDIR/bin-video/f265cli.exe
        fi

        do_checkIfExist f265-git bin-video/f265cli.exe
    fi
fi

cd $LOCALBUILDDIR

if [[ $nonfree = "y" ]]; then
    faac=""
  elif [[ $nonfree = "n" ]]; then
      faac="--disable-faac --disable-faac-lavc"
fi

if [[ $mplayer = "y" ]]; then
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
            elif ! git clone --depth 1 git://source.ffmpeg.org/ffmpeg.git ffmpeg ; then
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

        CPPFLAGS='-DFRIBIDI_ENTRY=""' ./configure --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-video --cc=gcc --extra-cflags='-DPTW32_STATIC_LIB -O3 -std=gnu99 -DMODPLUG_STATIC' --extra-libs='-lxml2 -llzma -lfreetype -lz -lbz2 -liconv -lws2_32 -lpthread -lwinpthread -lpng -lwinmm' --extra-ldflags='-Wl,--allow-multiple-definition' --enable-static --enable-runtime-cpudetection --enable-ass-internal --enable-bluray --disable-gif --enable-freetype $faac

        make -j $cpuCount
        make install

        do_checkIfExist mplayer-svn bin-video/mplayer.exe
    fi
fi

cd $LOCALBUILDDIR

if [[ $mpv = "y" && $ffmpeg = "y" ]]; then

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
        make BUILDMODE=static PREFIX=$LOCALDESTDIR INSTALL_BIN=$LOCALDESTDIR/bin-global FILE_T=luajit.exe INSTALL_TNAME='luajit-$(VERSION).exe' INSTALL_TSYMNAME=luajit.exe install

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

    do_git "https://github.com/mpv-player/mpv.git" mpv shallow master bin-video/mpv.exe

    if [[ $compile = "true" ]] || [[ $newFfmpeg = "yes" ]]; then
        if [ ! -f waf ]; then
            ./bootstrap.py
        else
            ./waf distclean
            rm waf
            rm -rf .waf-*
            rm -rf $LOCALDESTDIR/bin-video/mpv.exe
            ./bootstrap.py
        fi

        CFLAGS="$CFLAGS -DCACA_STATIC" ./waf configure --prefix=$LOCALDESTDIR --bindir=$LOCALDESTDIR/bin-video --disable-debug-build --enable-static-build --disable-manpage-build --disable-pdf-build --lua=luajit

        sed -r -i "s/LIBPATH_lib(ass|av(|device|filter)) = \[.*local(32|64).*mingw(32|64).*\]/LIBPATH_lib\1 = ['\/local\3\/lib', '\/mingw\4\/lib']/g" ./build/c4che/_cache.py

        ./waf build -j $cpuCount
        ./waf install

        if [[ ! -f fonts.conf ]]; then
            do_wget "https://raw.githubusercontent.com/lachs0r/mingw-w64-cmake/master/packages/mpv/mpv/fonts.conf"
            do_wget "http://srsfckn.biz/noto-mpv.7z"
            7z x -ofonts noto-mpv.7z
            rm -f noto-mpv.7z
        fi

        if [ ! -d $LOCALDESTDIR/bin-video/fonts ]; then
            mkdir -p $LOCALDESTDIR/bin-video/mpv
            cp fonts.conf $LOCALDESTDIR/bin-video/mpv/
            cp -R fonts $LOCALDESTDIR/bin-video/
        fi

        do_checkIfExist mpv-git bin-video/mpv.exe
    fi
fi

cd $LOCALBUILDDIR

if [[ $mkv = "y" ]]; then
    do_git "https://github.com/mbunkus/mkvtoolnix.git" mkvtoolnix shallow master bin-video/mkvtoolnix/bin/mkvmerge.exe

    if [[ $compile = "true" ]]; then
        if [[ ! -f ./configure ]]; then
            ./autogen.sh
            git submodule init
            git submodule update
        else
            rake clean
            rm -rf $LOCALDESTDIR/bin-video/mkvtoolnix
        fi

        if [[ ! -f ./mkvinfo.patch ]]; then
            do_wget "https://raw.github.com/jb-alvarado/media-autobuild_suite/master/patches/mkvinfo.patch"
        fi

        patch -N -p0 < mkvinfo.patch

        ./configure --build=$targetBuild --host=$targetHost --prefix=$LOCALDESTDIR/bin-video/mkvtoolnix --without-curl --with-boost-libdir=$MINGW_PREFIX/lib

        sed -i "s/EXTRA_CFLAGS = *$/EXTRA_CFLAGS = -static-libgcc -static-libstdc++ -static/g" build-config
        sed -i "s/EXTRA_LDFLAGS = *$/EXTRA_LDFLAGS = -static-libgcc -static-libstdc++ -static/g" build-config
        sed -i "s/LIBINTL_LIBS = -lintl*$/LIBINTL_LIBS = -lintl -liconv/g" build-config
		sed -i "s/@\(.*\)@//" build-config

        export DRAKETHREADS=$cpuCount

        drake
        rake install

        mkdir -p $LOCALDESTDIR/bin-video/mkvtoolnix/bin/doc
        mv $LOCALDESTDIR/bin-video/mkvtoolnix/share/locale $LOCALDESTDIR/bin-video/mkvtoolnix/bin/locale
        mv $LOCALDESTDIR/bin-video/mkvtoolnix/share/doc/mkvtoolnix/guide $LOCALDESTDIR/bin-video/mkvtoolnix/bin/doc/guide
        cp -r examples $LOCALDESTDIR/bin-video/mkvtoolnix/bin/examples
        unset DRAKETHREADS

        do_checkIfExist mkvtoolnix-git bin-video/mkvtoolnix/bin/mkvmerge.exe
    fi
fi

if [[ $stripping = "y" ]]; then
    cd $LOCALDESTDIR

    echo -ne "\033]0;strip $bits binaries\007"
    echo
    echo "-------------------------------------------------------------------------------"
    echo
    FILES=`find ./bin* ./lib -regex ".*\.\(exe\|dll\|com\)" -mmin -600`

    for f in $FILES; do
        strip --strip-all $f
        echo "strip $f done..."
    done

fi

if [[ $packing = "y" ]]; then
    if [ ! -f "$LOCALBUILDDIR/upx391w/upx.exe" ]; then
        echo -ne "\033]0;Download UPX\007"
        cd $LOCALBUILDDIR
        rm -rf upx391w
        do_wget "http://upx.sourceforge.net/download/upx391w.zip"
        unzip upx391w.zip
        rm upx391w.zip
    fi
    echo -ne "\033]0;pack $bits binaries\007"
    echo
    echo "-------------------------------------------------------------------------------"
    echo
    cd $LOCALDESTDIR
    FILES=`find ./bin-*  -regex ".*\.\(exe\|dll\|com\)" -mmin -600`

    for f in $FILES; do
        if [[ $stripping = "y" ]]; then
            $LOCALBUILDDIR/upx391w/upx.exe -9 -q $f
        else
            $LOCALBUILDDIR/upx391w/upx.exe -9 -q --strip-relocs=0 $f
        fi
        echo "pack $f done..."
    done
fi

echo "-------------------------------------------------------------------------------"
echo
echo "compile video tools $bits done..."
echo
echo "-------------------------------------------------------------------------------"
}

if [[ $build32 = "yes" ]]; then
    source /local32/etc/profile.local
    buildProcess
    echo "-------------------------------------------------------------------------------"
    echo "compile all tools 32bit done..."
    echo "-------------------------------------------------------------------------------"
    sleep 3
fi

if [[ $build64 = "yes" ]]; then
    source /local64/etc/profile.local
    buildProcess
    echo "-------------------------------------------------------------------------------"
    echo "compile all tools 64bit done..."
    echo "-------------------------------------------------------------------------------"
    sleep 3
fi

find $LOCALBUILDDIR -maxdepth 2 -name recently_updated -delete
find $LOCALBUILDDIR -maxdepth 2 -name build_successful* -delete

if [[ $deleteSource = "y" ]]; then
    echo -ne "\033]0;delete source folders\007"
    echo
    echo "delete source folders..."
    echo
    find $LOCALBUILDDIR -mindepth 1 -maxdepth 1 -type d ! -regex ".*\(-\(git\|hg\|svn\)\|upx.*\)\$" -exec rm -rf {} \;
fi

echo -ne "\033]0;compiling done...\007"
echo
echo "Window close in 15"
echo
sleep 5
echo
echo "Window close in 10"
echo
sleep 5
echo
echo "Window close in 5"
sleep 5
