# escape=`
ARG WindowsTag=1709
FROM mcr.microsoft.com/windows/servercore:${WindowsTag} AS builder

WORKDIR C:/
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]
RUN Set-ExecutionPolicy Bypass -Scope Process -Force; `
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/chocolatey/chocolatey.org/master/chocolatey/Website/Install.ps1'))
RUN choco install -y 7zip
RUN Invoke-WebRequest 'http://repo.msys2.org/distrib/msys2-x86_64-latest.tar.xz' -OutFile 'msys2-x86_64-latest.tar.xz'; `
    7z x msys2-x86_64-latest.tar.xz; rm msys2-x86_64-latest.tar.xz; `
    7z x msys2-x86_64-latest.tar; rm msys2-x86_64-latest.tar
ENV PATH="C:/msys64/opt/bin;C:/msys64/mingw64/bin;C:/msys64/usr/bin;C:/msys64/bin;C:/Windows/system32;C:/Windows;C:/Windows/System32/Wbem;C:/Windows/System32/WindowsPowerShell/v1.0/;C:/Windows/System32/OpenSSH/;C:/Users/ContainerAdministrator/AppData/Local/Microsoft/WindowsApps" `
    MSYSTEM=MINGW64 `
    TERM=xterm-256color `
    Bash="C:/msys64/usr/bin/bash.exe"

SHELL ["C:\\msys64\\usr\\bin\\bash.exe", "-lc"]
RUN 'exit'
RUN 'pacman -Syyuu --noconfirm --asdeps --ask=20 --noprogressbar'
RUN 'pacman -Su --noconfirm --asdeps --ask=20 --noprogressbar; pacman -Su --noconfirm --asdeps --ask=20 --noprogressbar'

# license=nonfree,gplv3,gpl,lgplv3,lgpl
ARG license=gplv3
ARG standalone=n
ARG vpx=y
ARG aom=y
ARG rav1e=n
ARG dav1d=y
ARG x264=y
ARG x265=y
ARG kvazaar=y
ARG vvc=n
ARG flac=y
ARG fdkaac=n
ARG faac=n
ARG mediainfo=n
ARG sox=y
ARG ffmpeg=static
# ffmpegChoice=light,zeranoe,all
ARG ffmpegChoice=all
ARG mp4box=n
ARG rtmpdump=n
ARG mplayer2=n
ARG mpv=n
ARG bmx=y
ARG curl=y
ARG avs2=y
ARG cores=4
ARG strip=y
ARG pack=y
ARG logging=y
ARG timeStamp=y
ENV noMintty=y

COPY build C:/build/

FROM mcr.microsoft.com/windows/servercore:${WindowsTag} AS Release
LABEL maintainer="Christopher Degawa (ccom@randomderp.com)" `
    version="0.1" description="MinGW-w64-GCC compiler enviroment for building media related tools under Windows. 64-bit Full Version"
CMD [ "cmd.exe","C:/MAS/media-autobuild_suite.bat" ]