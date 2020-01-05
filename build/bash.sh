#!/bin/bash
logFile=$(cygpath -u "$1" 2> /dev/null)
command=$2
shift 2
[[ -z $logFile || -z $command ]] && exit 1
script -eqf --command "/usr/bin/bash -o pipefail -lc '$command $*'" /dev/null | tee "$logFile"
exit "${PIPESTATUS[0]}"
