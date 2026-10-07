# Lataa stick.csv:n sisällön TOOLS- ja VENTOY-osioille ja kirjoittaa SHA256SUMS.csv:n.
# Uudelleenajo = päivitys. -Verify vertaa osioita SHA256SUMS.csv:hen (aja saastuneen koneen jälkeen).
param([switch]$Verify)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'   # PS 5.1:n edistymispalkki hidastaa latauksia moninkertaisesti

function Get-Root($label) {
    $v = Get-Volume -FileSystemLabel $label -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $v.DriveLetter) { throw "Osiota '$label' ei löydy tai sillä ei ole kirjainta." }
    "$($v.DriveLetter):\"
}
$roots = @{ TOOLS = Get-Root TOOLS; VENTOY = Get-Root VENTOY }
$sums = Join-Path $roots.TOOLS 'SHA256SUMS.csv'

if ($Verify) {
    $bad = Import-Csv $sums | Where-Object {
        $p = Join-Path $roots[$_.Target] $_.Path
        -not (Test-Path -LiteralPath $p) -or (Get-FileHash -LiteralPath $p).Hash -ne $_.Hash
    }
    $bad | ForEach-Object { Write-Warning "MUUTTUNUT TAI PUUTTUU: $($_.Target):\$($_.Path)" }
    if (-not $bad) { 'Kaikki tiedostot ennallaan.' }
    return
}

foreach ($row in Import-Csv (Join-Path $PSScriptRoot '..\stick.csv')) {
    $dest = Join-Path $roots[$row.Target] $row.Dest
    if ($row.Url -like 'manual:*') { Write-Host "KÄSIN  $($row.Dest)  <-  $($row.Url.Substring(7))"; continue }
    try {
        $url = $row.Url
        if ($url -like 'github:*') {
            $repo, $pattern = $url.Substring(7) -split ' ', 2
            $url = ((Invoke-RestMethod "https://api.github.com/repos/$repo/releases/latest").assets |
                Where-Object name -match $pattern | Select-Object -First 1).browser_download_url
            if (-not $url) { throw "julkaisusta ei löytynyt tiedostoa: $pattern" }
        }
        New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
        # Ladataan ensin .part-tiedostoon, jotta keskeytynyt lataus ei tuhoa vanhaa toimivaa versiota.
        Invoke-WebRequest $url -OutFile "$dest.part" -UseBasicParsing
        if ([IO.Path]::GetExtension($dest)) {
            Move-Item -Force "$dest.part" $dest
        } else {
            Move-Item -Force "$dest.part" "$dest.zip"
            Remove-Item -Recurse -Force $dest -ErrorAction SilentlyContinue
            Expand-Archive "$dest.zip" $dest
            Remove-Item "$dest.zip"
        }
        Write-Host "OK     $($row.Dest)"
    } catch {
        Remove-Item "$dest.part", "$dest.zip" -ErrorAction SilentlyContinue
        Write-Warning "VIRHE  $($row.Dest): $_"
    }
}

Write-Host 'Lasketaan tiivisteet...'
$(foreach ($t in 'TOOLS', 'VENTOY') {
    # Ilman -Force piilotetut järjestelmäkansiot ($RECYCLE.BIN, System Volume Information, .git) ohitetaan.
    Get-ChildItem $roots[$t] -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object FullName -ne $sums |
        ForEach-Object {
            [pscustomobject]@{ Target = $t; Path = $_.FullName.Substring($roots[$t].Length); Hash = (Get-FileHash -LiteralPath $_.FullName).Hash }
        }
}) | Export-Csv $sums -NoTypeInformation -Encoding UTF8
Write-Host "Valmis: $sums"
