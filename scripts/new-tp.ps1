# Crée un nouveau TP (dossier + README depuis le gabarit), le référence dans tps.json et met à jour le README principal.
# Usage : powershell -ExecutionPolicy Bypass -File .\scripts\new-tp.ps1 -Numero 5 -Titre "Titre du TP" -Tech "Java, Spring Boot"
param(
  [Parameter(Mandatory = $true)][int]$Numero,
  [Parameter(Mandatory = $true)][string]$Titre,
  [Parameter(Mandatory = $true)][string]$Tech
)
$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path $PSScriptRoot -Parent
$Utf8 = New-Object System.Text.UTF8Encoding($false)
$Folder = "TP$Numero-MS"
$Dir = Join-Path $RepoRoot $Folder
$JsonPath = Join-Path $PSScriptRoot 'tps.json'
$TplPath = Join-Path $RepoRoot 'templates\TP-README.md'

if ($Numero -lt 1) { throw 'Le numéro doit être supérieur ou égal à 1.' }
if (Test-Path $Dir) { throw "$Folder existe déjà : rien n'a été modifié." }
$raw = Get-Content $JsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
$tps = @($raw)
if ($tps | Where-Object { [int]$_.numero -eq $Numero }) { throw "TP$Numero est déjà référencé dans tps.json." }

$techList = (($Tech -split ',\s*') | ForEach-Object { "- $_" }) -join "`n"
$tpl = [IO.File]::ReadAllText($TplPath, [Text.Encoding]::UTF8)
$readme = $tpl.Replace('{{TP}}', $Folder).Replace('{{NUMERO}}', "$Numero").Replace('{{TITRE}}', $Titre).Replace('{{TECH}}', $techList)
New-Item -ItemType Directory -Path $Dir | Out-Null
[IO.File]::WriteAllText((Join-Path $Dir 'README.md'), ($readme -replace "`r`n", "`n"), $Utf8)

$tps += [pscustomobject]@{ numero = $Numero; titre = $Titre; tech = $Tech; depot_origine = '' }
$sorted = @($tps | Sort-Object { [int]$_.numero })
$json = (ConvertTo-Json -InputObject $sorted -Depth 3) -replace '\\u0027', "'"
[IO.File]::WriteAllText($JsonPath, $json, $Utf8)

& (Join-Path $PSScriptRoot 'update-readme.ps1')
Write-Host ""
Write-Host "$Folder créé. Étapes suivantes :"
Write-Host "  1. Copier le projet dans $Folder et compléter $Folder\README.md"
Write-Host "  2. git add -A ; git commit -m `"feat($Folder): ajout du TP$Numero`" ; git push"