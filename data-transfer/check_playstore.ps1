# app_list.txt'teki paketleri Play Store'da var mi diye kontrol eder.
# Cikti: playstore_apps.txt (var) + sideload_only.txt (yok/belirsiz)
param(
  [string]$In = "C:\huawei_dump\app_list.txt",
  [string]$OutDir = "C:\huawei_dump"
)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$pkgs = (Get-Content $In) -replace 'package:','' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
$avail = @(); $missing = @(); $unknown = @()
$i=0
foreach($p in $pkgs){
  $i++
  $url = "https://play.google.com/store/apps/details?id=$p&hl=en&gl=US"
  try{
    $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 12 -MaximumRedirection 2 -ErrorAction Stop
    if($r.StatusCode -eq 200 -and $r.Content -match [regex]::Escape($p)){ $avail += $p; $tag='PLAY' }
    else { $missing += $p; $tag='YOK' }
  } catch {
    $code = 0; try{ $code = [int]$_.Exception.Response.StatusCode }catch{}
    if($code -eq 404){ $missing += $p; $tag='YOK(404)' }
    elseif($code -eq 429){ $unknown += $p; $tag='RATELIMIT' ; Start-Sleep -Milliseconds 1500 }
    else { $unknown += $p; $tag="HATA($code)" }
  }
  Write-Output ("[{0}/{1}] {2}  {3}" -f $i,$pkgs.Count,$tag,$p)
  Start-Sleep -Milliseconds 250
}
$avail   | Sort-Object | Out-File "$OutDir\playstore_apps.txt" -Encoding UTF8
$missing | Sort-Object | Out-File "$OutDir\sideload_only.txt" -Encoding UTF8
$unknown | Sort-Object | Out-File "$OutDir\playstore_unknown.txt" -Encoding UTF8
Write-Output ""
Write-Output ("=== SONUC: PlayStore'da={0}  Yok(sideload)={1}  Belirsiz={2} ===" -f $avail.Count,$missing.Count,$unknown.Count)
