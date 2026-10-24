# sms_raw.txt (adb content query) -> SMS Backup & Restore uyumlu XML
# Cok satirli govdeleri dogru parse eder (bir sonraki "Row:"e kadar).
param(
  [string]$In  = "C:\huawei_dump\sms_raw.txt",
  [string]$Out = "C:\huawei_dump\sms_backup_restore.xml"
)
$text = Get-Content $In -Raw -Encoding UTF8

function Esc($s){
  if($null -eq $s){ return "" }
  $s = $s -replace '&','&amp;' -replace '<','&lt;' -replace '>','&gt;' -replace '"','&quot;' -replace "'",'&apos;'
  # XML'de gecersiz kontrol karakterlerini temizle (tab/nl/cr haric)
  return ($s -replace "[\x00-\x08\x0B\x0C\x0E-\x1F]", '')
}

$epoch = [datetime]'1970-01-01T00:00:00Z'
$rx = [regex]"(?s)Row:\s*\d+\s+_id=\d+,\s*address=(.*?),\s*date=(\d+),\s*type=(\d+),\s*body=(.*?)(?=\r?\nRow:\s*\d+\s+_id=|\z)"
$ms = $rx.Matches($text)

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("<?xml version='1.0' encoding='UTF-8' standalone='yes' ?>")
[void]$sb.AppendLine("<smses count=""$($ms.Count)"" backup_set=""huawei-lmu"" backup_date=""$([DateTimeOffset]::Now.ToUnixTimeMilliseconds())"">")
$n=0
foreach($m in $ms){
  $addr = $m.Groups[1].Value.Trim()
  $date = $m.Groups[2].Value.Trim()
  $type = $m.Groups[3].Value.Trim()
  $body = $m.Groups[4].Value.TrimEnd("`r","`n")
  if($type -ne '1' -and $type -ne '2'){ continue }   # sadece inbox/sent restore edilir
  $rd = ""
  try{ $rd = $epoch.AddMilliseconds([double]$date).ToLocalTime().ToString('dd.MM.yyyy HH:mm:ss') }catch{}
  [void]$sb.Append("  <sms protocol=""0"" address=""$(Esc $addr)"" date=""$date"" type=""$type"" ")
  [void]$sb.Append("subject=""null"" body=""$(Esc $body)"" toa=""null"" sc_toa=""null"" service_center=""null"" ")
  [void]$sb.AppendLine("read=""1"" status=""-1"" locked=""0"" date_sent=""0"" readable_date=""$rd"" contact_name=""(Unknown)"" />")
  $n++
}
[void]$sb.AppendLine("</smses>")
[System.IO.File]::WriteAllText($Out, $sb.ToString(), (New-Object System.Text.UTF8Encoding $false))
Write-Output "XML yazildi: $Out"
Write-Output "restore edilecek SMS (inbox+sent): $n / toplam yakalanan: $($ms.Count)"
