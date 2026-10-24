<#
  watch_firmware_win.ps1
  Xperia Companion "Software repair / update" sirasinda indirilen firmware
  parcalarini captured_stock_firmware klasorune anlik kopyalar.

  Companion'in KENDI binary'lerini (jre, plugins, configuration ...) atlar;
  yalnizca indirmenin dustugu degisken klasorleri (temp, localstorage,
  workspace, downloads vb.) ve sistem %TEMP%'ini izler.

  Companion dosyayi silmeden/flaslamadan ONCE calistir, indirme bittikten
  sonra da birkac dakika acik birak.

  Kullanim:
      powershell -ExecutionPolicy Bypass -File "C:\Users\<user>\Documents\root\xperia1_iv_root\watch_firmware_win.ps1"
#>

$ErrorActionPreference = 'SilentlyContinue'

$TargetDir  = "C:\Users\<user>\Documents\root\xperia1_iv_root\captured_stock_firmware"
$Companion  = "$env:LOCALAPPDATA\Sony\Xperia Companion"
New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null

# Companion icindeki statik kurulum klasorleri - firmware BURAYA dusmez, atla.
$SkipDirRegex = '\\(jre|plugins|configuration|licenses|setup|p2|features)\\'
# Kod/ikili uzantilar - firmware degil, atla.
$SkipExt = @('.dll','.jar','.lib','.exe','.so','.dylib','.pdb','.ini','.html','.txt','.xml','.properties','.class')

# Firmware isareti: bu uzantilar HER ZAMAN alinir (boyut farketmez)
$FirmwareExt = @('.sin','.sinb','.img','.ta','.lta','.ftf','.tar','.zip','.bin','.gz','.xz')
$MinBytes    = 2MB   # bilinmeyen/uzantisiz dosyalar icin esik

$LogFile = Join-Path $TargetDir ("_capture_{0}.log" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
function Log($msg) {
    $line = "[{0}] {1}" -f (Get-Date -Format 'HH:mm:ss'), $msg
    Write-Host $line
    Add-Content -Path $LogFile -Value $line
}

$FwNameRegex = 'boot|firmware|fw[_-]|partition|\.sin|super|vbmeta|userdata|system|vendor|dtbo|fota|swup|persist|elabel|modem|amss|\.ta\b'

Log "=== Xperia Companion firmware watcher (v3) ==="
Log ("Hedef    : {0}" -f $TargetDir)
Log ("Companion: {0}  (jre/plugins/configuration haric, boyut+isim)" -f $Companion)
Log ("Sistem TEMP: yalnizca adi/uzantisi firmware'e benzeyenler")
Log "Companion'da Software repair / guncellemeyi simdi baslat. Durdurmak: Ctrl+C"

$seen = @{}

while ($true) {
    # 1) Companion veri agaci: statik klasorler haric, boyut VEYA isim esli
    $cFiles = Get-ChildItem -Path $Companion -Recurse -File -Force -EA SilentlyContinue |
                Where-Object { $_.FullName -notmatch $SkipDirRegex }
    # 2) Sistem TEMP: SADECE firmware uzantisi/adi (wct*.tmp, AT_hist gurultusu haric)
    $tFiles = Get-ChildItem -Path $env:TEMP -Recurse -File -Force -EA SilentlyContinue |
                Where-Object { ($FirmwareExt -contains $_.Extension.ToLower()) -or ($_.Name -match $FwNameRegex) }

    foreach ($entry in @(@{f=$cFiles;sys=$false}, @{f=$tFiles;sys=$true})) {
      $fromSys = $entry.sys
      foreach ($f in $entry.f) {
        if ($null -eq $f) { continue }
        $ext = $f.Extension.ToLower()
        if ($f.Name -match '\.(lck|lock|log)$') { continue }
        if ($SkipExt -contains $ext) { continue }

        if ($fromSys) {
            $isFw = $true   # sistem TEMP zaten on-filtreli
        } else {
            $isFw = ($FirmwareExt -contains $ext) -or ($f.Name -match $FwNameRegex) -or ($f.Length -ge $MinBytes)
        }
        if (-not $isFw -or $f.Length -le 0) { continue }

        $last = if ($seen.ContainsKey($f.FullName)) { $seen[$f.FullName] } else { -1 }
        if ($f.Length -eq $last) { continue }

        $rel  = $f.FullName -replace '^[A-Za-z]:\\', '' -replace '[\\/:]', '_'
        $dest = Join-Path $TargetDir $rel
        try {
            Copy-Item -LiteralPath $f.FullName -Destination ($dest + '.tmp') -Force
            Move-Item -LiteralPath ($dest + '.tmp') -Destination $dest -Force
            $seen[$f.FullName] = $f.Length
            Log ("KOPYALANDI {0,8:N1} MB  <-  {1}" -f ($f.Length/1MB), $f.FullName)
        } catch {
            Log ("devam ({0:N1} MB): {1}" -f ($f.Length/1MB), $f.Name)
        }
      }
    }
    Start-Sleep -Milliseconds 800
}
