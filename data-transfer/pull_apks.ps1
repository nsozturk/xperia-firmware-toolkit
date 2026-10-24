# Huawei'deki tum 3rd-party uygulamalarin APK'larini ceker (split'ler dahil).
# Her paket -> C:\huawei_dump\apks\<paket>\*.apk  (split varsa install-multiple icin hepsi)
param(
  [string]$Adb = "C:\Users\<user>\Documents\root\xperia1_iv_root\platform-tools\adb.exe",
  [string]$Serial = "<HUAWEI_SERIAL>",
  [string]$Dst = "C:\huawei_dump\apks"
)
New-Item -ItemType Directory -Force -Path $Dst | Out-Null
$log = "C:\huawei_dump\apks_pull.log"
function Log($m){ $l="[{0}] {1}" -f (Get-Date -Format HH:mm:ss),$m; Add-Content $log $l; Write-Output $l }

$pkgs = (& $Adb -s $Serial shell "pm list packages -3") -replace 'package:','' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
Log "Toplam paket: $($pkgs.Count)"
$ok=0; $fail=0
foreach($p in $pkgs){
  try{
    $paths = (& $Adb -s $Serial shell "pm path $p") -replace 'package:','' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    if(-not $paths){ Log "YOL YOK: $p"; $fail++; continue }
    $pdir = Join-Path $Dst $p
    New-Item -ItemType Directory -Force -Path $pdir | Out-Null
    foreach($ap in $paths){
      $name = ($ap -split '/')[-1]
      & $Adb -s $Serial pull "$ap" (Join-Path $pdir $name) *>$null
    }
    $cnt = (Get-ChildItem $pdir -Filter *.apk -EA SilentlyContinue).Count
    Log "OK  $p  ($cnt apk)"
    $ok++
  } catch { Log "HATA $p : $($_.Exception.Message)"; $fail++ }
}
Log "BITTI. basarili=$ok hata=$fail  -> $Dst"
