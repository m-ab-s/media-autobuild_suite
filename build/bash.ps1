param([string]$Bash, [string]$BashCommand, [string]$LogFile)
function Write-Transcript {
    try { Stop-Transcript | Out-Null } catch [System.InvalidOperationException] { }
    if (Select-String -Path $LogFile -SimpleMatch -Pattern '**********************' -Quiet) {
        $linenumber = (Select-String -Path $LogFile -SimpleMatch -Pattern '**********************').LineNumber
        $transcriptContent = Get-Content -Path $LogFile | Select-Object -Index ($linenumber[1]..($linenumber[$linenumber.Length - 2] - 2))
        Set-Content -Force -Path $LogFile -Value $transcriptContent
    }
}
try {
    $host.ui.RawUI.WindowTitle = switch -wildcard ($BashCommand) {
        *media-suite_update* { "update autobuild suite" }
        *media-suite_compile* { "media-autobuild_suite" }
        Default { $host.ui.RawUI.WindowTitle }
    }
    Start-Transcript -Force $LogFile | Out-Null
    $build = $PSScriptRoot
    Remove-Item -Force -Path "$build\compilation_failed", "$build\fail_comp" -ErrorAction Ignore
    &$bash "-l" $BashCommand.Split(' ')
    if (Test-Path "$build\compilation_failed") {
        Write-Transcript
        $compilefail = Get-Content -Path $build\compilation_failed
        $env:reason = $compilefail[1]
        $env:operation = $compilefail[2]
        New-Item -Force -ItemType File -Path "$build\fail_comp" -Value $(
            "while read line; do declare -x `"`$line`"; done < /build/fail.var`n" +
            "source /build/media-suite_helper.sh`n" +
            "cd `$(head -n 1 /build/compilation_failed)`n" +
            "if [[ `$logging = y ]]; then`n" +
            "echo `"Likely error:`"`n" +
            "tail `"ab-suite.`${operation}.log`"`n" +
            "echo `"`${red}`$reason failed. Check `$(pwd -W)/ab-suite.`$operation.log`${reset}`"`n" +
            "fi`n" +
            "echo `"`${red}This is required for other packages, so this script will exit.`${reset}`"`n" +
            "zip_logs`n" +
            "echo `"Make sure the suite is up-to-date before reporting an issue. It might've been fixed already.`"`n" +
            "do_prompt `"Try running the build again at a later time.`"") | Out-Null
        Start-Process -NoNewWindow -Wait -FilePath $bash -ArgumentList ("-l /build/fail_comp").Split(' ')
        Remove-Item -Force -Path $build\compilation_failed, $build\fail_comp
    }
} catch {
    Write-Output "Stopping log and exiting"
} finally {
    Write-Transcript
}
