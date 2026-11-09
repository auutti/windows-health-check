# Erklärung: So funktioniert der Health-Check

## Die Idee

IT-Techniker prüfen regelmäßig, ob Server und PCs gesund sind: Sind Updates installiert, läuft der Virenschutz, ist genug Platz frei? Das Skript macht diese Routineprüfung automatisch und schreibt das Ergebnis in einen übersichtlichen Bericht.

## Ablauf

1. **GitHub Actions** startet jeden Montag (oder per Klick) einen frischen Windows Server in der Cloud.
2. Dort läuft `src/Invoke-HealthCheck.ps1` mit Windows PowerShell.
3. Das Skript führt 10 Prüfungen aus und vergibt pro Prüfung einen Status:
   - **OK**: alles gut
   - **WARNUNG**: bald handeln
   - **KRITISCH**: sofort handeln
   - **INFO**: nur zur Information
4. Das Ergebnis landet als `reports/health-report.md` (direkt auf GitHub lesbar), `reports/health-report.html` (zum Ansehen im Browser) und `reports/health-report.json` (für andere Programme) im Repository.

## Die 10 Prüfungen

| Nr. | Prüfung | Befehl | Warum wichtig |
|---|---|---|---|
| 1 | Betriebssystem, Laufzeit | `Get-CimInstance Win32_OperatingSystem` | Lange ohne Neustart heißt oft: Updates warten auf Installation |
| 2 | Letztes Update, ausstehender Neustart | `Get-HotFix`, Registry | Fehlende Updates sind das häufigste Einfallstor für Angriffe |
| 3 | Speicherplatz, RAM | `Get-CimInstance Win32_LogicalDisk` | Volle Platten bringen Server und Anwendungen zum Absturz |
| 4 | Backup | `Get-WBSummary` | Ohne aktuelle Sicherung sind Daten bei einem Ausfall verloren |
| 5 | Microsoft Defender | `Get-MpComputerStatus` | Ist der Virenschutz aktiv und sind die Signaturen aktuell? |
| 6 | Firewall | `Get-NetFirewallProfile` | Eine deaktivierte Firewall öffnet das System für das Netzwerk |
| 7 | BitLocker | `Get-BitLockerVolume` | Ohne Verschlüsselung sind Daten bei Diebstahl lesbar |
| 8 | Lokale Admins | `Get-LocalGroupMember` | Zu viele Admins bedeuten ein Sicherheitsrisiko |
| 9 | Dienste | `Get-CimInstance Win32_Service` | Gestoppte automatische Dienste deuten auf Fehler hin |
| 10 | Ereignisprotokoll | `Get-WinEvent` | Häufige Systemfehler zeigen Probleme, bevor Nutzer sie merken |

## Wichtige Begriffe

| Begriff | Bedeutung |
|---|---|
| PowerShell | Die Skriptsprache von Windows zur Automatisierung von Verwaltungsaufgaben |
| Cmdlet | Ein PowerShell-Befehl im Format Verb-Nomen, z. B. `Get-HotFix` |
| CIM / WMI | Schnittstelle, über die Windows Systeminformationen bereitstellt |
| GitHub Actions | Automatisierung von GitHub: führt Skripte auf Servern in der Cloud aus |
| Workflow | Datei `.github/workflows/health-check.yml`, legt fest, wann und wie das Skript läuft |
| try / catch | Fängt Fehler ab: Schlägt eine Prüfung fehl, laufen die anderen trotzdem weiter |
