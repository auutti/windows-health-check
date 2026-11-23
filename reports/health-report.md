# Windows-Health-Check: runnervmbpeip

Erstellt am 23.11.2026 17:30 (UTC) | Gesamtstatus: **Handlungsbedarf** | OK: 10 | Warnungen: 3 | Kritisch: 1

| Bereich | Pruefung | Status | Detail |
|---|---|---|---|
| System | Betriebssystem | **INFO** | Microsoft Windows Server 2025 Datacenter (Build 26100) |
| System | Laufzeit seit Neustart | **OK** | 0 Tage |
| Updates | Letztes Windows-Update | **OK** | KB5131079 vor 11 Tagen installiert |
| Updates | Ausstehender Neustart | **OK** | Kein Neustart ausstehend |
| Speicher | Laufwerk C: | **OK** | 20 % frei (30 GB) |
| Speicher | Laufwerk D: | **OK** | 98 % frei (147 GB) |
| Speicher | Arbeitsspeicher | **OK** | 83.7 % frei von 16 GB |
| Backup | Letzte Sicherung | **WARNUNG** | Windows Server-Sicherung nicht installiert, andere Sicherungsloesung pruefen |
| Sicherheit | Microsoft Defender | **KRITISCH** | Echtzeitschutz aus, Signaturen 6 Tage alt |
| Sicherheit | Firewall (Domain) | **OK** | aktiv |
| Sicherheit | Firewall (Private) | **OK** | aktiv |
| Sicherheit | Firewall (Public) | **OK** | aktiv |
| Sicherheit | BitLocker (C:) | **WARNUNG** | Schutz: Off |
| Sicherheit | Lokale Administratoren | **INFO** | 1: runnervmbpeip\runneradmin |
| Dienste | Automatische Dienste | **WARNUNG** | 6 gestoppt: DPS, MSDTC, StorSvc, UALSVC, UsoSvc |
| Ereignisse | Systemfehler (24 h) | **OK** | 3 Fehler, haeufigste Quelle: Microsoft-Windows-Hyper-V-Netvsc (2x) |
