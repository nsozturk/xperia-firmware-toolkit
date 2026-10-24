# Huawei APK'larini Sony'ye kurar. Zaten kurulu + sistem/Google paketlerini atlar.
param(
  [string]$Adb = "C:\Users\<user>\Documents\root\xperia1_iv_root\platform-tools\adb.exe",
  [string]$Sony = "<SONY_SERIAL>",
  [string]$ApkRoot = "C:\huawei_dump\apks"
)
$log = "C:\huawei_dump\install_apks.log"
function Log($m){ $l="[{0}] {1}" -f (Get-Date -Format HH:mm:ss),$m; Add-Content $log $l; Write-Output $l }

# Sony'de kurulu paketler
$existing = @{}
(& $Adb -s $Sony shell "pm list packages") -replace 'package:','' | ForEach-Object { $p=$_.Trim(); if($p){ $existing[$p]=$true } }
Log "Sony'de kurulu paket: $($existing.Count)"

# Atlanacak sistem/Google on ekleri (Play Store / sistemden gelir)
$skipPrefix = @('com.google.','com.android.','com.qualcomm.','android.')

$dirs = Get-ChildItem $ApkRoot -Directory -EA SilentlyContinue
Log "Huawei APK paketi: $($dirs.Count)"
$ins=0; $skip=0; $fail=0; $failed=@()
foreach($dir in $dirs){
  $pkg = $dir.Name
  if($existing.ContainsKey($pkg)){ $skip++; continue }
  if($skipPrefix | Where-Object { $pkg.StartsWith($_) }){ Log "ATLA (sistem/google): $pkg"; $skip++; continue }
  $apks = Get-ChildItem $dir.FullName -Filter *.apk -EA SilentlyContinue
  if($apks.Count -eq 0){ continue }
  try{
    if($apks.Count -eq 1){
      $r = & $Adb -s $Sony install -r $apks[0].FullName 2>&1
    } else {
      $r = & $Adb -s $Sony install-multiple -r @($apks.FullName) 2>&1
    }
    if($r -match 'Success'){ Log "OK  $pkg"; $ins++ }
    else { Log "HATA $pkg : $($r | Select-Object -Last 1)"; $fail++; $failed += $pkg }
  } catch { Log "HATA $pkg : $($_.Exception.Message)"; $fail++; $failed += $pkg }
}
Log "=== BITTI. kuruldu=$ins  atlandi=$skip  basarisiz=$fail ==="
if($failed){ Log "Basarisiz paketler: $($failed -join ', ')" }
