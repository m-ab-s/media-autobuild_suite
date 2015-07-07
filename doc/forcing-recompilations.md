How to force compilation of libs/apps
====

## Libraries using pkg-config
Most libs use pkg-config files to check if they exist, so for most libs in this list all you have to do is delete the corresponding `<libname>.pc` file in `/local32/lib/pkgconfig/` or `/local64/lib/pkgconfig`:
```
caca
dcadec
dvdnav
dvdread
fdk-aac (fdk-aac library only)
fontconfig
freetype2
frei0r
fribidi
gnutls
harfbuzz
l-smash
libass
libbluray
libbs2b
libcdio_paranoia
libgme (game music emu)
libilbc
libmfx (intel quick sync hw accelerator)
libopenjpeg1 (openjpeg)
libutvideo
luajit
nettle
ogg
opencore-amrnb
opencore-amrwb
opus
opusfile
Qt5Core
rubberband
sdl
sndfile
soxr (sox resampling library only)
speex
theora
twolame
vidstab
vo-aacenc
vo-amrwbenc
vorbis
vpx
x264
x265
zvbi-0.2 (libzvbi)
```
## Libraries not using pkg-config
To recompile these libs, delete `<libname>.a` with the same name in `/local32/lib` or `/local64/lib`:
```
libgnurx
libmad
libwaio
libxavs
```

## Apps
To recompile these, delete `<appname>.exe` in corresponding binary directories:

#### /bin-audio
```
faac
fdkaac (fdk-aac encoder)
flac
opusenc (Opus encoder)
sox
```

#### /bin-global
```
file
libgcrypt-config
ragel
wx-config
```

#### /bin-video
```
f265cli
ffmbc
ffmpeg (for static and both)
ffmpegSHARED/ffmpeg (for shared only)
kvazaar
mediainfo
mkvtoolnix/bin/mkvmerge
MP4Box
mplayer
mpv
rtmpdump
x264
x265
vpxenc
```
