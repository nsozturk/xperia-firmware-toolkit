# Huawei dump medyasini Sony'ye push eder (Android/data cop haric).
param(
  [string]$Adb = "C:\Users\<user>\Documents\root\xperia1_iv_root\platform-tools\adb.exe",
  [string]$Sony = "<SONY_SERIAL>",
  [string]$Src = "C:\huawei_dump\sdcard"
)
$log = "C:\huawei_dump\push_media.log"
function Log($m){ $l="[{0}] {1}" -f (Get-Date -Format HH:mm:ss),$m; Add-Content $log $l; Write-Output $l }

Log "=== Sony'ye medya push basliyor ==="
# Normal kullanici klasorleri -> /sdcard/
$folders = 'DCIM','Download','Pictures','Documents','Music','Movies','Books','Recordings'
foreach($f in $folders){
  $p = Join-Path $Src $f
  if(Test-Path $p){
    Log "push $f ..."
    & $Adb -s $Sony push $p /sdcard/ *>> $log
    Log "  $f bitti"
  }
}
# WhatsApp medya -> /sdcard/Android/media/
$wa = Join-Path $Src "Android\media\com.whatsapp"
if(Test-Path $wa){
  Log "push WhatsApp medya ..."
  & $Adb -s $Sony shell "mkdir -p /sdcard/Android/media" *>$null
  & $Adb -s $Sony push $wa /sdcard/Android/media/ *>> $log
  Log "  WhatsApp bitti"
}
Log "=== MEDYA PUSH TAMAM ==="
