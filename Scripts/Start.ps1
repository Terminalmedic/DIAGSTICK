# DIAGSTICK-päävalikko. Käynnistä TOOLS:\Start.cmd:llä.
$tools = Split-Path $PSScriptRoot
$cases = (Get-Volume -FileSystemLabel CASES -ErrorAction SilentlyContinue | Select-Object -First 1).DriveLetter
if (-not $cases) { Write-Warning 'CASES-osiota ei löydy. Avaa sen BitLocker-lukitus ja käynnistä uudelleen.'; pause; return }

$ticket = (Read-Host 'Tiketti tai asiakkaan nimi') -replace '[\\/:*?"<>|]', '_'
$env:DIAGSTICK_CASE = "${cases}:\$(Get-Date -Format yyyy-MM-dd)_$ticket"
New-Item -ItemType Directory -Force $env:DIAGSTICK_CASE | Out-Null

$scripts = @(Get-ChildItem "$PSScriptRoot\*.ps1" -Exclude Start.ps1, Build-Stick.ps1)
while ($true) {
    Clear-Host
    "DIAGSTICK  |  tapaus: $env:DIAGSTICK_CASE`n"
    for ($i = 0; $i -lt $scripts.Count; $i++) { "  $($i + 1)  $($scripts[$i].BaseName)" }
    "`n  O  Toimintaohjeet oireittain`n  T  Työkalut (Portable)`n  K  Tapauskansio`n  Q  Lopeta`n"
    $c = Read-Host 'Valinta'
    switch ($c) {
        'O' { notepad "$tools\Docs\Playbooks.md" }
        'T' { explorer "$tools\Portable" }
        'K' { explorer $env:DIAGSTICK_CASE }
        'Q' { return }
        default {
            $n = $c -as [int]
            if ($n -ge 1 -and $n -le $scripts.Count) { & $scripts[$n - 1].FullName; pause }
        }
    }
}
