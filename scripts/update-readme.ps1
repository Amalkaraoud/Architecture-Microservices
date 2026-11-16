# Régénère les blocs automatiques du README principal (index + arborescence) à partir de scripts/tps.json.
# Usage : powershell -ExecutionPolicy Bypass -File .\scripts\update-readme.ps1
$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path $PSScriptRoot -Parent
$Utf8 = New-Object System.Text.UTF8Encoding($false)
$Dash = [string][char]0x2014

function Set-Block([string]$Text, [string]$Name, [string]$Content) {
  $s = "<!-- ${Name}:START -->"
  $e = "<!-- ${Name}:END -->"
  $i = $Text.IndexOf($s)
  $j = $Text.IndexOf($e)
  if ($i -lt 0 -or $j -lt $i) { throw "Marqueurs ${Name} introuvables dans README.md" }
  return $Text.Substring(0, $i + $s.Length) + "`n" + $Content + "`n" + $Text.Substring($j)
}

$raw = Get-Content (Join-Path $PSScriptRoot 'tps.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$tps = @(@($raw) | Sort-Object { [int]$_.numero })

$rows = @()
$known = @()
foreach ($t in $tps) {
  $folder = 'TP' + $t.numero + '-MS'
  $known += $folder
  if (-not (Test-Path (Join-Path $RepoRoot $folder))) { throw "Dossier manquant : $folder (référencé dans tps.json)" }
  if (-not (Test-Path (Join-Path $RepoRoot "$folder\README.md"))) { Write-Warning "$folder n'a pas de README.md" }
  if ($t.depot_origine) { $orig = '[' + ($t.depot_origine -replace '^https://github\.com/', '') + '](' + $t.depot_origine + ')' } else { $orig = $Dash }
  $rows += "| [$folder](./$folder) | $($t.titre) | $($t.tech) | $orig |"
}
Get-ChildItem $RepoRoot -Directory -Filter 'TP*-MS' | Where-Object { $known -notcontains $_.Name } |
  ForEach-Object { Write-Warning "Dossier $($_.Name) non référencé dans scripts/tps.json : absent de l'index." }

$table = "| TP | Thème | Technologies | Dépôt d'origine |`n|----|-------|--------------|-----------------|`n" + ($rows -join "`n")

$tree = @('    Architecture-Microservices/', '    ├── README.md')
foreach ($f in $known) { $tree += "    ├── $f/" }
$tree += '    ├── docs/'
$tree += '    ├── scripts/'
$tree += '    └── templates/'

$readmePath = Join-Path $RepoRoot 'README.md'
$text = [IO.File]::ReadAllText($readmePath, [Text.Encoding]::UTF8) -replace "`r`n", "`n"
$text = Set-Block $text 'TP-INDEX' $table
$text = Set-Block $text 'TP-TREE' ($tree -join "`n")
[IO.File]::WriteAllText($readmePath, $text, $Utf8)
Write-Host "README.md mis à jour : $($tps.Count) TP référencés."