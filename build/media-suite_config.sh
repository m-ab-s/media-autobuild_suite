#!/bin/bash
# shellcheck disable=SC2034,SC1090,SC1117,SC1091,SC2119
shopt -s extglob

if [[ x"$LOCALBUILDDIR" = "x" ]]; then
    printf '%s\n' \
        "Something went wrong." \
        "MSYSTEM: $MSYSTEM" \
        "pwd: $(cygpath -w "$(pwd)")" \
        "fstab: " \
        "$(cat /etc/fstab)" \
        "Create a new issue and upload all logs you can find, especially compile.log"
    read -r -p "Enter to continue" ret
    exit 1
fi

while true; do
  case $1 in
    --ffmpegVersion=* ) ffmpegVersion="${1#*=}"; shift ;;
    -- ) shift; break ;;
    -* ) echo "Error, unknown option: '$1'."; exit 1 ;;
    * ) break ;;
  esac
done

[ "$ffmpegVersion" == '' ] &&  ffmpegVersion='latest'
sed -ri '/readme.txt/{s/(ffmpeg-).*(-win)/\1'$ffmpegVersion'\2/g}' "$LOCALBUILDDIR"/media-suite_helper.sh

[ "$ffmpegVersion" == 'latest' ] && ffmpeg_tag='' || ffmpeg_tag='#tag=n'$ffmpegVersion
sed -ri '/do_vcs/{s/(ffmpeg\.git).*(["'"'"'])/\1'$ffmpeg_tag'\2/g}' "$LOCALBUILDDIR"/media-suite_compile.sh