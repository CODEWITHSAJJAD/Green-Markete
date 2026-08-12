$enc = New-Object System.Text.UTF8Encoding($false)
$changed = @()
$files = Get-ChildItem lib -Recurse -Filter *.dart
foreach ($f in $files) {
  $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
  $s = [System.Text.Encoding]::UTF8.GetString($bytes)
  $orig = $s
  $bad1 = [string][char]0x00C3 + [string][char]0x2014
  $s = $s.Replace($bad1, [string][char]0x00D7)
  $s = $s.Replace([string][char]0x00E2 + [string][char]0x20AC + [string][char]0x00A2, [string][char]0x2022)
  $s = $s.Replace([string][char]0x00E2 + [string][char]0x20AC + [string][char]0x0099, [string][char]0x2019)
  $s = $s.Replace([string][char]0x00E2 + [string][char]0x20AC + [string][char]0x009C, [string][char]0x201C)
  $s = $s.Replace([string][char]0x00E2 + [string][char]0x20AC + [string][char]0x009D, [string][char]0x201D)
  $hasBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
  if ($s -ne $orig -or $hasBom) {
    [System.IO.File]::WriteAllText($f.FullName, $s, $enc)
    $changed += $f.FullName
  }
}
Write-Output "Changed files:"
$changed | ForEach-Object { Write-Output $_ }