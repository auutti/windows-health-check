# Windows-Health-Check

PowerShell-Skript, das den Zustand eines Windows-Systems prüft und einen Bericht erstellt. Es läuft automatisch jede Woche auf einem Windows Server in der Cloud (GitHub Actions).

## Was geprüft wird

- **Updates:** Wann wurde das letzte Windows-Update installiert? Wartet ein Neustart?
- **Backup:** Wann lief die letzte erfolgreiche Sicherung?
- **Sicherheit:** Microsoft Defender, Firewall, BitLocker, lokale Administratoren
- **Speicher:** freier Platz pro Laufwerk, freier Arbeitsspeicher
- **Betrieb:** Laufzeit seit Neustart, gestoppte Dienste, Systemfehler der letzten 24 Stunden

Jede Prüfung erhält den Status **OK**, **WARNUNG**, **KRITISCH** oder **INFO**.

## Ergebnis

Der aktuelle Bericht: [`reports/health-report.md`](reports/health-report.md) (direkt auf GitHub lesbar), zusätzlich als HTML und JSON in [`reports/`](reports/).

## Aufbau

```
src/Invoke-HealthCheck.ps1           das Skript
.github/workflows/health-check.yml   automatischer Lauf (montags + per Klick)
reports/                             aktueller Bericht (Markdown, HTML, JSON)
docs/ERKLAERUNG.md                   Erklärung aller Prüfungen
```

## Selbst ausführen

Auf einem Windows-PC in PowerShell:

```powershell
.\src\Invoke-HealthCheck.ps1 -OutputPath .\reports
```

Oder auf GitHub: **Actions → Windows-Health-Check → Run workflow**.

---

Lernprojekt von Jan Schamberger in Zusammenarbeit mit Claude Code.
