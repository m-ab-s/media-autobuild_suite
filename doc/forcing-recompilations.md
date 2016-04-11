How to force compilation of libs/apps
====

## Libraries using pkg-config
Most libs use pkg-config files to check if they exist, so for most libs in this list all you have to do is delete the corresponding `<libname>.pc` file in `/local32/lib/pkgconfig/` or `/local64/lib/pkgconfig`:
```
chromaprint
dvdnav
dvdread
fdk-aac (fdk-aac library only)
flac
frei0r
gnutls
lept (leptonica)
libass
libbluray
libMXF-1.0
libMXF++-1.0
libbs2b
libgme (game music emu)
libilbc
libmediainfo
libmfx (intel quick sync hw accelerator)
libopenjp2 (openjpeg 2)
librtmp
libwebp
libzen
lsmash
luajit
rubberband
sndfile
speex
tesseract
vidstab
vo-amrwbenc
vpx
x264
x265
zimg
zvbi-0.2 (libzvbi)
```

## Libraries not using pkg-config
To recompile these libs, delete `<libname>.a` with the same name in `/local32/lib` or `/local64/lib`:
```
libxavs
libsoxr (sox resampling library only)
```

## Apps
To recompile these, delete `<appname>.exe` in corresponding binary directories:

```
/bin-audio
    faac
    fdkaac (fdk-aac encoder)
    flac
    lame (MP3 encoder)
    oggenc (Vorbis encoder)
    opusenc (Opus encoder)
    sox

/bin-global
    file

/bin-video
    bmxtranswrap
    ffmpeg (for static and both)
    ffmpegSHARED/ffmpeg (for shared only)
    kvazaar
    mediainfo
    MP4Box
    mplayer
    mpv
    rtmpdump (if rtmpdump=y)
    x264
    x265
    vpxenc
```
