# Vastaanottoraportti tapauskansioon: kone, levyt, BitLocker-palautusavaimet, virheet ja ohjelmat.
# Aja ensimmäisenä, ennen mitään muutoksia.
$case = if ($env:DIAGSTICK_CASE) { $env:DIAGSTICK_CASE } else { $PWD.Path }
$report = Join-Path $case "intake_$(Get-Date -Format yyyyMMdd_HHmm).txt"
$stick = 'VENTOY', 'VTOYEFI', 'TOOLS', 'CASES', 'LINUX'

function Section($title, [scriptblock]$body) {
    "`n=== $title ==="
    try { & $body | Out-String -Width 220 } catch { "VIRHE: $_" }
}

& {
    Section 'Kone' {
        $cs = Get-CimInstance Win32_ComputerSystem; $bios = Get-CimInstance Win32_BIOS; $os = Get-CimInstance Win32_OperatingSystem
        [pscustomobject]@{
            Valmistaja = $cs.Manufacturer; Malli = $cs.Model; Sarjanumero = $bios.SerialNumber
            BIOS = "$($bios.SMBIOSBIOSVersion) ($($bios.ReleaseDate))"
            Windows = "$($os.Caption) $($os.Version)"; Asennettu = $os.InstallDate; Käynnistetty = $os.LastBootUpTime
            CPU = (Get-CimInstance Win32_Processor).Name; RAM_GB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
        } | Format-List
    }
    Section 'Muistikammat' {
        Get-CimInstance Win32_PhysicalMemory | Format-Table DeviceLocator, @{n = 'GB'; e = { $_.Capacity / 1GB } }, Speed, Manufacturer, PartNumber -AutoSize
    }
    Section 'Levyt' {
        Get-PhysicalDisk | Format-Table DeviceId, FriendlyName, MediaType, BusType, @{n = 'GB'; e = { [int]($_.Size / 1GB) } }, HealthStatus -AutoSize
        Get-PhysicalDisk | Get-StorageReliabilityCounter |
            Format-Table DeviceId, Wear, Temperature, PowerOnHours, ReadErrorsUncorrected, WriteErrorsUncorrected -AutoSize
    }
    Section 'Osiot' {
        Get-Volume | Where-Object DriveLetter |
            Format-Table DriveLetter, FileSystemLabel, FileSystem, @{n = 'GB'; e = { [int]($_.Size / 1GB) } }, @{n = 'Vapaa GB'; e = { [int]($_.SizeRemaining / 1GB) } } -AutoSize
    }
    # Palautusavaimet tallentuvat raporttiin, joka on salatulla CASES-osiolla: tämä on samalla avainten varmuuskopio.
    Section 'BitLocker-palautusavaimet' {
        Get-Volume | Where-Object { $_.DriveLetter -and $_.DriveType -eq 'Fixed' -and $_.FileSystemLabel -notin $stick } |
            ForEach-Object { manage-bde -protectors -get "$($_.DriveLetter):" }
    }
    Section 'Secure Boot' { try { Confirm-SecureBootUEFI } catch { 'Ei UEFI-tilaa tai ei tuettu' } }
    Section 'Aktivointi' {
        $s = (Get-CimInstance SoftwareLicensingProduct -Filter "PartialProductKey IS NOT NULL AND Name LIKE 'Windows%'").LicenseStatus
        if ($s -contains 1) { 'Aktivoitu' } else { "EI aktivoitu (tila: $s)" }
    }
    Section 'Laitteet, joissa on virhe' {
        Get-CimInstance Win32_PnPEntity | Where-Object ConfigManagerErrorCode | Format-Table Name, ConfigManagerErrorCode -AutoSize
    }
    Section 'Järjestelmälokin virheet, 14 vrk (yleisimmät)' {
        Get-WinEvent -FilterHashtable @{ LogName = 'System'; Level = 1, 2; StartTime = (Get-Date).AddDays(-14) } -ErrorAction SilentlyContinue |
            Group-Object ProviderName, Id | Sort-Object Count -Descending | Select-Object -First 20 |
            Format-Table Count, Name, @{n = 'Viimeisin'; e = { $_.Group[0].TimeCreated } }, @{n = 'Viesti'; e = { ($_.Group[0].Message -split "`n")[0] } } -AutoSize
    }
    Section 'Akku' {
        if (Get-CimInstance Win32_Battery) { powercfg /batteryreport /output (Join-Path $case 'battery.html') | Out-Null; 'Tallennettu: battery.html' }
        else { 'Ei akkua' }
    }
    Section 'Asennetut ohjelmat' {
        Get-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
                         'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
                         'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue |
            Where-Object DisplayName | Sort-Object DisplayName -Unique | Format-Table DisplayName, DisplayVersion, InstallDate -AutoSize
    }
} | Out-File $report -Encoding UTF8

"Raportti: $report"
notepad $report
