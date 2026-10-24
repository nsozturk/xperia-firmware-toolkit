<#
  capture.ps1 — Xperia Companion trafigini SEFFAF yakalar (ayri app/JVM-proxy YOK).
  mitmproxy --mode local: WinDivert ile sadece "Xperia Companion.exe" surecinin
  TCP trafigini proxy'ye yonlendirir. CA zaten JRE truststore'a eklendi.

  Kullanim: bu scripti calistir, sonra Companion'da bir islem yap (update kontrol
  / Software repair baslat). URL'ler mitm\urls.txt, firmware/CDN ipuclari
  mitm\flagged.txt dosyasina dusser. Durdurmak: bu pencerede Ctrl+C.

  NOT: Companion flash ("Repairing device") yaparken BASLATMA — once Finish'i bekle.
#>
$ErrorActionPreference = 'Stop'
$mitm = "C:\Users\<user>\Documents\root\xperia1_iv_root\mitm"
$md   = "$mitm\venv\Scripts\mitmdump.exe"
$conf = "$mitm\conf"

# eski loglari arsivle
foreach($f in 'urls.txt','responses.txt','flagged.txt'){
  $p = Join-Path $mitm $f
  if(Test-Path $p){ Move-Item $p "$p.$(Get-Date -Format yyyyMMdd_HHmmss).old" -Force }
}

Write-Host "=== mitmdump local-mode baslıyor (hedef: Xperia Companion.exe) ==="
Write-Host "URL log : $mitm\urls.txt"
Write-Host "Flagged : $mitm\flagged.txt (sony/cdn/firmware)"
Write-Host "Flow dump: $mitm\flows.mitm"
Write-Host "Companion'da update kontrol / repair baslat. Durdur: Ctrl+C`n"

& $md `
  --set confdir=$conf `
  --mode "local:Xperia Companion.exe" `
  -s "$mitm\log_urls.py" `
  -w "$mitm\flows.mitm" `
  --set console_eventlog_verbosity=info
