<#
.SYNOPSIS
  Windows-Health-Check: prueft den Zustand eines Windows-Systems und erstellt einen HTML-Bericht.
.DESCRIPTION
  Prueft Updates, Laufzeit, Speicherplatz, Arbeitsspeicher, Microsoft Defender, Firewall,
  BitLocker, Dienste, lokale Administratoren und Fehler im Ereignisprotokoll.
  Jede Pruefung bekommt einen Status: OK, WARNUNG, KRITISCH oder INFO.
.EXAMPLE
  .\Invoke-HealthCheck.ps1 -OutputPath .\reports
#>
[CmdletBinding()]
param(
    [string] $OutputPath = (Join-Path $PSScriptRoot '..\reports')
)

$ErrorActionPreference = 'Stop'
$results = New-Object System.Collections.Generic.List[object]

# Fuegt ein Pruefergebnis zur Ergebnisliste hinzu
function Add-Result {
    param(
        [string] $Bereich,
        [string] $Pruefung,
        [ValidateSet('OK', 'WARNUNG', 'KRITISCH', 'INFO')] [string] $Status,
        [string] $Detail
    )
    $results.Add([pscustomobject]@{
        Bereich  = $Bereich
        Pruefung = $Pruefung
        Status   = $Status
        Detail   = $Detail
    })
}

# ---------------------------------------------------------------------------
# 1. System: Betriebssystem und Laufzeit seit dem letzten Neustart
# ---------------------------------------------------------------------------
try {
    $os = Get-CimInstance Win32_OperatingSystem
    Add-Result 'System' 'Betriebssystem' 'INFO' "$($os.Caption) (Build $($os.BuildNumber))"

    $tage = [math]::Round(((Get-Date) - $os.LastBootUpTime).TotalDays, 1)
    $status = if ($tage -gt 30) { 'WARNUNG' } else { 'OK' }
    Add-Result 'System' 'Laufzeit seit Neustart' $status "$tage Tage"
} catch {
    Add-Result 'System' 'Betriebssystem' 'INFO' "Nicht verfuegbar: $($_.Exception.Message)"
}

# ---------------------------------------------------------------------------
# 2. Updates: letztes Windows-Update und ausstehender Neustart
# ---------------------------------------------------------------------------
try {
    $letztes = Get-HotFix | Where-Object InstalledOn | Sort-Object InstalledOn -Descending | Select-Object -First 1
    if ($letztes) {
        $alter = ((Get-Date) - $letztes.InstalledOn).Days
        $status = if ($alter -gt 60) { 'KRITISCH' } elseif ($alter -gt 30) { 'WARNUNG' } else { 'OK' }
        Add-Result 'Updates' 'Letztes Windows-Update' $status "$($letztes.HotFixID) vor $alter Tagen installiert"
    } else {
        Add-Result 'Updates' 'Letztes Windows-Update' 'WARNUNG' 'Keine installierten Updates gefunden'
    }
} catch {
    Add-Result 'Updates' 'Letztes Windows-Update' 'INFO' "Nicht verfuegbar: $($_.Exception.Message)"
}

try {
    # Wartet das System auf einen Neustart, um Updates abzuschliessen?
    $gruende = @()
    if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') { $gruende += 'Windows-Komponenten' }
    if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired') { $gruende += 'Windows Update' }
    if ($gruende.Count -gt 0) {
        Add-Result 'Updates' 'Ausstehender Neustart' 'WARNUNG' "Neustart erforderlich: $($gruende -join ', ')"
    } else {
        Add-Result 'Updates' 'Ausstehender Neustart' 'OK' 'Kein Neustart ausstehend'
    }
} catch {
    Add-Result 'Updates' 'Ausstehender Neustart' 'INFO' "Nicht verfuegbar: $($_.Exception.Message)"
}

# ---------------------------------------------------------------------------
# 3. Speicher: freier Platz pro Laufwerk und freier Arbeitsspeicher
# ---------------------------------------------------------------------------
try {
    foreach ($disk in Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3') {
        $frei   = [math]::Round($disk.FreeSpace / $disk.Size * 100, 1)
        $freiGB = [math]::Round($disk.FreeSpace / 1GB, 1)
        $status = if ($frei -lt 5) { 'KRITISCH' } elseif ($frei -lt 15) { 'WARNUNG' } else { 'OK' }
        Add-Result 'Speicher' "Laufwerk $($disk.DeviceID)" $status "$frei % frei ($freiGB GB)"
    }

    $ramFrei = [math]::Round($os.FreePhysicalMemory / $os.TotalVisibleMemorySize * 100, 1)
    $ramGB   = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
    $status  = if ($ramFrei -lt 10) { 'WARNUNG' } else { 'OK' }
    Add-Result 'Speicher' 'Arbeitsspeicher' $status "$ramFrei % frei von $ramGB GB"
} catch {
    Add-Result 'Speicher' 'Speicherplatz' 'INFO' "Nicht verfuegbar: $($_.Exception.Message)"
}

# ---------------------------------------------------------------------------
# 4. Backup: letzte erfolgreiche Sicherung (Windows Server-Sicherung)
# ---------------------------------------------------------------------------
try {
    if (Get-Command Get-WBSummary -ErrorAction SilentlyContinue) {
        $wb = Get-WBSummary
        if ($wb.LastSuccessfulBackupTime -and $wb.LastSuccessfulBackupTime -gt [datetime]'2000-01-01') {
            $alter = ((Get-Date) - $wb.LastSuccessfulBackupTime).Days
            $status = if ($alter -gt 2) { 'KRITISCH' } elseif ($alter -gt 1) { 'WARNUNG' } else { 'OK' }
            Add-Result 'Backup' 'Letzte Sicherung' $status "Vor $alter Tagen erfolgreich"
        } else {
            Add-Result 'Backup' 'Letzte Sicherung' 'KRITISCH' 'Noch keine erfolgreiche Sicherung'
        }
    } else {
        Add-Result 'Backup' 'Letzte Sicherung' 'WARNUNG' 'Windows Server-Sicherung nicht installiert, andere Sicherungsloesung pruefen'
    }
} catch {
    Add-Result 'Backup' 'Letzte Sicherung' 'INFO' "Nicht verfuegbar: $($_.Exception.Message)"
}

# ---------------------------------------------------------------------------
# 5. Sicherheit: Microsoft Defender
# ---------------------------------------------------------------------------
try {
    $mp = Get-MpComputerStatus
    $echtzeit = if ($mp.RealTimeProtectionEnabled) { 'an' } else { 'aus' }
    $status = if (-not $mp.AntivirusEnabled -or -not $mp.RealTimeProtectionEnabled) { 'KRITISCH' } elseif ($mp.AntivirusSignatureAge -gt 3) { 'WARNUNG' } else { 'OK' }
    Add-Result 'Sicherheit' 'Microsoft Defender' $status "Echtzeitschutz $echtzeit, Signaturen $($mp.AntivirusSignatureAge) Tage alt"
} catch {
    Add-Result 'Sicherheit' 'Microsoft Defender' 'WARNUNG' "Status nicht abrufbar: $($_.Exception.Message)"
}

# ---------------------------------------------------------------------------
# 6. Sicherheit: Windows-Firewall pro Profil (Domain, Private, Public)
# ---------------------------------------------------------------------------
try {
    foreach ($profil in Get-NetFirewallProfile) {
        $status = if ($profil.Enabled) { 'OK' } else { 'KRITISCH' }
        $text   = if ($profil.Enabled) { 'aktiv' } else { 'deaktiviert' }
        Add-Result 'Sicherheit' "Firewall ($($profil.Name))" $status $text
    }
} catch {
    Add-Result 'Sicherheit' 'Firewall' 'INFO' "Nicht verfuegbar: $($_.Exception.Message)"
}

# ---------------------------------------------------------------------------
# 7. Sicherheit: BitLocker-Verschluesselung des Systemlaufwerks
# ---------------------------------------------------------------------------
try {
    $bl = Get-BitLockerVolume -MountPoint $env:SystemDrive
    $status = if ($bl.ProtectionStatus -eq 'On') { 'OK' } else { 'WARNUNG' }
    Add-Result 'Sicherheit' "BitLocker ($env:SystemDrive)" $status "Schutz: $($bl.ProtectionStatus)"
} catch {
    Add-Result 'Sicherheit' "BitLocker ($env:SystemDrive)" 'INFO' 'BitLocker auf diesem System nicht verfuegbar'
}

# ---------------------------------------------------------------------------
# 8. Sicherheit: Mitglieder der lokalen Administratorgruppe
# ---------------------------------------------------------------------------
try {
    # SID S-1-5-32-544 = Administratoren (funktioniert in jeder Sprache)
    $admins = @(Get-LocalGroupMember -SID 'S-1-5-32-544' | ForEach-Object { $_.Name })
    $status = if ($admins.Count -gt 3) { 'WARNUNG' } else { 'INFO' }
    Add-Result 'Sicherheit' 'Lokale Administratoren' $status "$($admins.Count): $($admins -join ', ')"
} catch {
    Add-Result 'Sicherheit' 'Lokale Administratoren' 'INFO' "Nicht verfuegbar: $($_.Exception.Message)"
}

# ---------------------------------------------------------------------------
# 9. Dienste: automatisch startende Dienste, die nicht laufen
# ---------------------------------------------------------------------------
try {
    # Diese Dienste beenden sich planmaessig von selbst und werden ignoriert
    $ignorieren = 'gupdate|edgeupdate|sppsvc|RemoteRegistry|MapsBroker|TrustedInstaller|tiledatamodelsvc|CDPSvc'
    $gestoppt = @(Get-CimInstance Win32_Service -Filter "StartMode='Auto' AND State<>'Running'" |
                  Where-Object { $_.Name -notmatch $ignorieren })
    if ($gestoppt.Count -eq 0) {
        Add-Result 'Dienste' 'Automatische Dienste' 'OK' 'Alle automatischen Dienste laufen'
    } else {
        Add-Result 'Dienste' 'Automatische Dienste' 'WARNUNG' "$($gestoppt.Count) gestoppt: $(($gestoppt.Name | Select-Object -First 5) -join ', ')"
    }
} catch {
    Add-Result 'Dienste' 'Automatische Dienste' 'INFO' "Nicht verfuegbar: $($_.Exception.Message)"
}

# ---------------------------------------------------------------------------
# 10. Ereignisprotokoll: kritische Fehler und Fehler der letzten 24 Stunden
# ---------------------------------------------------------------------------
try {
    $fehler = @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; Level = 1, 2; StartTime = (Get-Date).AddHours(-24) } -ErrorAction SilentlyContinue)
    if ($fehler.Count -eq 0) {
        Add-Result 'Ereignisse' 'Systemfehler (24 h)' 'OK' 'Keine Fehler'
    } else {
        $top = $fehler | Group-Object ProviderName | Sort-Object Count -Descending | Select-Object -First 1
        $status = if ($fehler.Count -gt 20) { 'WARNUNG' } else { 'OK' }
        Add-Result 'Ereignisse' 'Systemfehler (24 h)' $status "$($fehler.Count) Fehler, haeufigste Quelle: $($top.Name) ($($top.Count)x)"
    }
} catch {
    Add-Result 'Ereignisse' 'Systemfehler (24 h)' 'INFO' "Nicht verfuegbar: $($_.Exception.Message)"
}

# ---------------------------------------------------------------------------
# Auswertung und Bericht
# ---------------------------------------------------------------------------
$ok   = @($results | Where-Object Status -eq 'OK').Count
$warn = @($results | Where-Object Status -eq 'WARNUNG').Count
$krit = @($results | Where-Object Status -eq 'KRITISCH').Count
$gesamt = if ($krit -gt 0) { 'Handlungsbedarf' } elseif ($warn -gt 0) { 'Bitte pruefen' } else { 'Alles in Ordnung' }

$css = @'
<style>
  body { font-family: "Segoe UI", Arial, sans-serif; margin: 24px; color: #222; }
  h1 { font-size: 22px; margin-bottom: 4px; }
  p.meta { color: #555; margin-top: 0; }
  table { border-collapse: collapse; width: 100%; font-size: 14px; }
  th, td { border: 1px solid #ddd; padding: 6px 10px; text-align: left; }
  th { background: #f3f3f3; }
  td.OK { background: #e6f4ea; color: #1e7b34; font-weight: 600; }
  td.WARNUNG { background: #fff4e5; color: #a35c00; font-weight: 600; }
  td.KRITISCH { background: #fdecea; color: #b3261e; font-weight: 600; }
  td.INFO { background: #eef3fb; color: #1a4d8f; font-weight: 600; }
</style>
'@

$tabelle = $results | ConvertTo-Html -Fragment -Property Bereich, Pruefung, Status, Detail | Out-String
foreach ($s in 'OK', 'WARNUNG', 'KRITISCH', 'INFO') {
    $tabelle = $tabelle.Replace("<td>$s</td>", "<td class=""$s"">$s</td>")
}

$zeit = Get-Date -Format 'dd.MM.yyyy HH:mm'
$html = @"
<!DOCTYPE html>
<html lang="de">
<head><meta charset="utf-8"><title>Windows-Health-Check $env:COMPUTERNAME</title>$css</head>
<body>
<h1>Windows-Health-Check: $env:COMPUTERNAME</h1>
<p class="meta">Erstellt am $zeit (UTC) &middot; Gesamtstatus: <b>$gesamt</b> &middot; OK: $ok &middot; Warnungen: $warn &middot; Kritisch: $krit</p>
$tabelle
</body>
</html>
"@

New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
$html | Out-File -FilePath (Join-Path $OutputPath 'health-report.html') -Encoding utf8
$results | ConvertTo-Json | Out-File -FilePath (Join-Path $OutputPath 'health-report.json') -Encoding utf8

# Markdown-Version: wird auf GitHub direkt als Tabelle angezeigt
$md = @(
    "# Windows-Health-Check: $env:COMPUTERNAME", '',
    "Erstellt am $zeit (UTC) | Gesamtstatus: **$gesamt** | OK: $ok | Warnungen: $warn | Kritisch: $krit", '',
    '| Bereich | Pruefung | Status | Detail |',
    '|---|---|---|---|'
)
$md += $results | ForEach-Object { "| $($_.Bereich) | $($_.Pruefung) | **$($_.Status)** | $($_.Detail.Replace('|', '/')) |" }
$md -join "`n" | Out-File -FilePath (Join-Path $OutputPath 'health-report.md') -Encoding utf8

$results | Format-Table -AutoSize | Out-String -Width 250 | Write-Host
Write-Host "Gesamtstatus: $gesamt (OK: $ok, Warnungen: $warn, Kritisch: $krit)"
Write-Host "Bericht gespeichert in: $(Resolve-Path $OutputPath)"
