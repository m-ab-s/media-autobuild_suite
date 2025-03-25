# How to force compilation of libs/apps

## Libraries using pkg-config

Most libs use pkg-config files to check if they exist, so for most libs in this list all you have to do is delete the corresponding `<libname>.pc` file in `/local[32|64]/lib/pkgconfig/`:

    aom
    aribb24
    chromaprint
    codec2
    dav1d
    davs2
    dovi
    dvdnav
    dvdread
    fdk-aac (fdk-aac library only)
    ffms2
    ffnvcodec
    flac
    fontconfig
    freetype
    frei0r
    gflags
    gnutls
    harfbuzz
    kvazaar
    lensfun
    lept (leptonica)
    libaacs
    libass
    libavif
    libbluray
    libbdplus
    libbs2b
    libcurl
    libglut
    libgme (game music emu)
    libidn2
    libilbc
    libjxl
    libmediainfo
    libmfx (intel quick sync hw accelerator)
    libmusicbrainz5
    libMXF-1.0
    libMXF++-1.0
    libmysofa
    libopenmpt
    libopusenc (opusenc library only)
    libplacebo
    libpng
    libpsl
    librav1e
    librtmp
    libtiff-4
    liburiparser
    libvmaf
    libvvdec
    libvvenc
    libxml-2.0
    libwebp
    libzen
    lsmash
    luajit
    mujs
    neon
    ogg
    openal
    opencl
    openssl
    opus
    opusfile
    rubberband
    sdl2
    shine
    sndfile
    speex
    spirv-cross
    srt
    SvtAv1Dec
    SvtAv1Enc
    SvtHevcEnc
    SvtVp9Enc
    tesseract
    uavs3d
    uvg266
    vapoursynth
    vidstab
    vo-amrwbenc
    vorbis
    vpx
    vulkan
    x264
    x265
    xavs
    xavs2
    xvc
    zimg
    zlib
    zvbi-0.2 (libzvbi)

## Libraries not using pkg-config

To recompile these libs, delete `<libname>.a` with the same name in `/local[32|64]/lib`:

    libdl
    libflite
    libglslang
    libgpac_static
    libmujs
    libpython311
    libshaderc_combined
    libsoxr (sox resampling library only)
    libxavs
    libxvidcore

## Apps

To recompile these, delete `<appname>.exe` in corresponding binary directories:

    /bin-audio
        cyanrip
        exhale
        faac
        fdkaac (fdk-aac encoder)
        flac
        lame (MP3 encoder)
        metaflac
        oggdec
        oggenc
        opusdec
        opusenc
        opusinfo
        sox
        shineenc
        speexdec
        speexenc

    /bin-global
        cjpegl
        cjxl
        curl
        cwebp
        djpegli
        djxl
        dssim
        dwebp
        gifski
        idn2
        img2webp
        jxlinfo
        jo
        jq
        luajit
        minigzip
        miniunzip
        minizip
        mujs
        openssl
        psl
        rg
        rist
            2rist
            receiver
            sender
            srppasswd
        tesseract
        tiff
            cp
            dump
            info
            set
            split
        uriparse
        webpmux

    /bin-video
        aomdec
        aomenc
        av1an
        avifdec
        avifenc
        bmxtranswrap
        dav1d
        davs2
        dovi_tool
        ffmbc
        ffmpeg (for static and both)
        ffmpegSHARED/ffmpeg (for shared only)
        ffmsindex
        gpac
        hdr10plus_tool
        h264dump
        kvazaar
        libaacs.dll
        libass-9.dll
        libbdplus.dll
        libEGL.dll
        libfreetype-6.dll
        libfribidi-0.dll
        libharfbuzz-0.dll
        libharfbuzz-subset-0.dll
        mediainfo
        MP4Box
        mencoder
        movdump
        mplayer
        mpv
        MXFDump
        mxf2raw
        rav1e
        raw2mxf
        rtmpdump (if rtmpdump=y)
        srt-live-transmit
        SvtAv1DecApp
        SvtAv1EncApp
        SvtHevcEncApp
        SvtVp9EncApp
        uavs3dec
        uvg266
        vc2dump
        vvdecapp
        vvencapp
        vvencFFapp
        vvc
            EncoderApp
            DecoderApp
        vpxenc
        x264
        x265
        xavs2
        xvcenc
        xvcdec
        xvid_encraw