# Erklärung: So funktioniert der Health-Check

## Die Idee

IT-Techniker prüfen regelmäßig, ob Server und PCs gesund sind: Sind Updates installiert, läuft der Virenschutz, ist genug Platz frei? Das Skript macht diese Routineprüfung automatisch und schreibt das Ergebnis in einen übersichtlichen Bericht.

## Ablauf

1. **GitHub Actions** startet jeden Montag (oder per Klick) einen frischen Windows Server in der Cloud.
2. Dort läuft `src/Invoke-HealthCheck.ps1` mit Windows PowerShell.
3. Das Skript führt 9 Prüfungen aus und vergibt pro Prüfung einen Status:
   - **OK**: alles gut
   - **WARNUNG**: bald handeln
   - **KRITISCH**: sofort handeln
   - **INFO**: nur zur Information
4. Das Ergebnis landet als `reports/health-report.html` (zum Ansehen) und `reports/health-report.json` (für andere Programme) im Repository.

## Die 9 Prüfungen

| Nr. | Prüfung | Befehl | Warum wichtig |
|---|---|---|---|
| 1 | Betriebssystem, Laufzeit | `Get-CimInstance Win32_OperatingSystem` | Lange ohne Neustart heißt oft: Updates warten auf Installation |
| 2 | Letztes Update | `Get-HotFix` | Fehlende Updates sind das häufigste Einfallstor für Angriffe |
| 3 | Speicherplatz, RAM | `Get-CimInstance Win32_LogicalDisk` | Volle Platten bringen Server und Anwendungen zum Absturz |
| 4 | Microsoft Defender | `Get-MpComputerStatus` | Ist der Virenschutz aktiv und sind die Signaturen aktuell? |
| 5 | Firewall | `Get-NetFirewallProfile` | Eine deaktivierte Firewall öffnet das System für das Netzwerk |
| 6 | BitLocker | `Get-BitLockerVolume` | Ohne Verschlüsselung sind Daten bei Diebstahl lesbar |
| 7 | Lokale Admins | `Get-LocalGroupMember` | Zu viele Admins bedeuten ein Sicherheitsrisiko |
| 8 | Dienste | `Get-CimInstance Win32_Service` | Gestoppte automatische Dienste deuten auf Fehler hin |
| 9 | Ereignisprotokoll | `Get-WinEvent` | Häufige Systemfehler zeigen Probleme, bevor Nutzer sie merken |

## Wichtige Begriffe

| Begriff | Bedeutung |
|---|---|
| PowerShell | Die Skriptsprache von Windows zur Automatisierung von Verwaltungsaufgaben |
| Cmdlet | Ein PowerShell-Befehl im Format Verb-Nomen, z. B. `Get-HotFix` |
| CIM / WMI | Schnittstelle, über die Windows Systeminformationen bereitstellt |
| GitHub Actions | Automatisierung von GitHub: führt Skripte auf Servern in der Cloud aus |
| Workflow | Datei `.github/workflows/health-check.yml`, legt fest, wann und wie das Skript läuft |
| try / catch | Fängt Fehler ab: Schlägt eine Prüfung fehl, laufen die anderen trotzdem weiter |

## So lernst du das Projekt (ca. 3–4 Stunden)

1. Den aktuellen Bericht in `reports/` öffnen und jede Zeile verstehen.
2. Das Skript Abschnitt für Abschnitt lesen. Jeden Befehl, den du nicht kennst, die KI erklären lassen.
3. Selbst etwas ändern, z. B. die Warngrenze für Speicherplatz von 15 % auf 20 %. Danach im Tab **Actions** → **Windows-Health-Check** → **Run workflow** starten und den neuen Bericht ansehen.
4. Eine eigene Prüfung ergänzen, z. B. die Uhrzeit-Synchronisation (`w32tm /query /status`).
5. Den Ablauf in eigenen Worten erklären können: Was prüft das Skript, warum ist das wichtig, wie läuft es automatisch?
