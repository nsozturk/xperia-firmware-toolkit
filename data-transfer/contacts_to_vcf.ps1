# contacts_raw.txt (adb content query ciktisi) -> contacts.vcf (vCard 3.0)
param(
  [string]$In  = "C:\huawei_dump\contacts_raw.txt",
  [string]$Out = "C:\huawei_dump\contacts.vcf"
)
$contacts = @{}   # id -> @{ name; phones=@(); emails=@() }
foreach($line in Get-Content $In -Encoding UTF8){
  if($line -notmatch '^Row:\s'){ continue }
  if($line -notmatch 'contact_id=(\d+),'){ continue }
  $id = $Matches[1]
  $mime = if($line -match 'mimetype=(\S+?),\s*data1='){ $Matches[1] } else { '' }
  $data = if($line -match ',\s*data1=(.*)$'){ $Matches[1].Trim() } else { '' }
  $dname = if($line -match 'display_name=(.*?),\s*mimetype='){ $Matches[1].Trim() } else { '' }
  if(-not $contacts.ContainsKey($id)){ $contacts[$id] = @{ name=''; dname=$dname; phones=New-Object System.Collections.ArrayList; emails=New-Object System.Collections.ArrayList } }
  $c = $contacts[$id]
  if($dname -and -not $c.dname){ $c.dname = $dname }
  switch -Wildcard ($mime){
    '*/name'     { if($data){ $c.name = $data } }
    '*/phone_v2' { if($data -and -not $c.phones.Contains($data)){ [void]$c.phones.Add($data) } }
    '*/email_v2' { if($data -and -not $c.emails.Contains($data)){ [void]$c.emails.Add($data) } }
  }
}
$sb = New-Object System.Text.StringBuilder
$n = 0
foreach($id in $contacts.Keys){
  $c = $contacts[$id]
  $fn = if($c.name){ $c.name } elseif($c.dname){ $c.dname } elseif($c.phones.Count){ $c.phones[0] } else { continue }
  if($c.phones.Count -eq 0 -and $c.emails.Count -eq 0){ continue }   # bos kayit atla
  [void]$sb.AppendLine("BEGIN:VCARD")
  [void]$sb.AppendLine("VERSION:3.0")
  [void]$sb.AppendLine("FN:$fn")
  [void]$sb.AppendLine("N:$fn;;;;")
  foreach($p in $c.phones){ [void]$sb.AppendLine("TEL;TYPE=CELL:$p") }
  foreach($e in $c.emails){ [void]$sb.AppendLine("EMAIL;TYPE=INTERNET:$e") }
  [void]$sb.AppendLine("END:VCARD")
  $n++
}
[System.IO.File]::WriteAllText($Out, $sb.ToString(), (New-Object System.Text.UTF8Encoding $false))
Write-Output "vCard yazildi: $Out"
Write-Output "kisi sayisi: $n"
