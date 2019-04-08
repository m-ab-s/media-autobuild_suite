#! C:\WINDOWS\System32\WindowsPowerShell\v1.0\powershell.exe
if (Test-Path -Path $env:ini) {
    $prevINIOpt = @{ }
    Get-Content -Path $env:ini | Where-Object { $_ -match '=' } | ForEach-Object { $prevINIOpt.Add($_.split('=')[0], $_.split('=')[1]) }
    $prevINIOpt.Keys | ForEach-Object { New-Item -Path env: -Name $_ -Value $prevINIOpt.$_ -ErrorAction Ignore -InformationAction Ignore }
} else {
    New-Item -Path $env:ini -ItemType File -Value "[compiler list]`r`n"
}
$INIOpt = @{ msys2Arch = $env:msys2Arch; arch = $env:arch; license2 = $env:license2; standalone = $env:standalone; vpx2 = $env:vpx2; aom = $env:aom; rav1e = $env:rav1e; dav1d = $env:dav1d; x2643 = $env:x2643; x2652 = $env:x2652; other265 = $env:other265; vvc = $env:vvc; flac = $env:flac; fdkaac = $env:fdkaac; faac = $env:faac; mediainfo = $env:mediainfo; soxB = $env:soxB; ffmpegB2 = $env:ffmpegB2; ffmpegUpdate = $env:ffmpegUpdate; ffmpegChoice = $env:ffmpegChoice; mp4box = $env:mp4box; rtmpdump = $env:rtmpdump; mplayer2 = $env:mplayer2; mpv = $env:mpv; bmx = $env:bmx; curl = $env:curl; ffmbc = $env:ffmbc; cyanrip2 = $env:cyanrip2; redshift = $env:redshift; ripgrep = $env:ripgrep; jq = $env:jq; dssim = $env:dssim; avs2 = $env:avs2; cores = $env:cores; deleteSource = $env:deleteSource; strip = $env:strip; pack = $env:pack; logging = $env:logging; updateSuite = $env:updateSuite; timeStamp = $env:timeStamp; noMintty = $env:noMintty; }
foreach ($a in 1..$($INIOpt.Count)) { Write-Output "$($INIOpt.Keys.split("`n")[$a-1])=$($INIOpt.Values.split("`n")[$a-1])" | Out-File -FilePath $env:ini -Encoding utf8 -Append }