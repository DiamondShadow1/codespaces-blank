# bergischland_cctv

Ein vollständiges, modular aufgebautes CCTV-/Überwachungskamera-System für FiveM mit ESX Legacy, oxmysql und NUI.

## 1. Voraussetzungen

- FiveM Server
- ESX Legacy
- oxmysql
- Lua 5.4
- Optional: ox_inventory

## 2. Installation

1. Resource in deinen Server-Ordner kopieren:

   ```bash
   /resources/bergischland_cctv/
   ```

2. SQL-Datei importieren:

   ```sql
   source sql/install.sql
   ```

   oder über deine SQL-Verwaltung und den Inhalt aus `sql/install.sql` importieren.

3. `fxmanifest.lua` prüfen und bei Bedarf anpassen.

4. Im Server-Ordner `server.cfg` eintragen:

   ```cfg
   ensure es_extended
   ensure oxmysql
   ensure bergischland_cctv
   ```

5. `config.lua` anpassen.

## 3. Konfiguration

Die wichtigsten Einstellungen liegen in `config.lua`.

- `Config.AdminGroups` – Admin-Gruppen für `/bgcctvadmin`
- `Config.PoliceJobs` – Polizeijobs und Mindestgrade
- `Config.AdminGroups` nutzt die Form `{ admin = true, superadmin = true }`
- `Config.JobAccess` – Standard-Zugriff pro Job
- `Config.DefaultRecordingMinutes` – Standard-Aufnahmezeit
- `Config.MaxCameraDistance` – maximale Distanz zu einer Kamera
- `Config.EnableDiscordLogs` – Discord-Webhook-Logging
- `Config.Debug` – Debug-Ausgaben

## 4. Commands

- `/bgcctv` – CCTV-Menü öffnen
- `/bgcctvadmin` – Admin-Menü öffnen
- `/bgcctvcreate` – Admin-Shortcut zum Erstellen einer Kamera
- `/bgcctvdelete [id]` – Kamera löschen
- `/bgcctvterminal` – CCTV-Terminal platzieren
- `/bgcctvterminals` – Vorhandene Terminals anzeigen
- `/bgcctvterminaldelete [id]` – Terminal löschen
- `/bgcctvdebug` – Admin-Debug-Ausgabe

Alle Commands werden serverseitig validiert.

## 5. NUI

Die NUI liegt unter `nui/` und kann nach Bedarf weiterentwickelt werden. Standardmäßig enthält sie:

- Dashboard
- Kameraliste
- Live-Kameraansicht
- Admin-Bereiche

## 6. Beispiel-Workflow

1. Polizei- oder Adminrolle prüfen
2. `/cctv` ausführen
3. Kamera auswählen
4. Live-Ansicht öffnen
5. Aufnahmen / Beweismittel verwalten

## 7. Fehlerbehebung

### Resource startet nicht

- Prüfe, ob `es_extended` und `oxmysql` gestartet sind
- Prüfe `fxmanifest.lua`
- Prüfe die SQL-Tabelle in deiner Datenbank

### NUI öffnet nicht

- Stelle sicher, dass `ui_page` und `files` korrekt gesetzt sind
- Prüfe den Client-Event-Flow
- Nutze `Config.Debug = true` und prüfe die Server-Konsole

### Zugriff verweigert

- Prüfe `Config.PoliceJobs`
- Prüfe `Config.AdminGroups`
- Prüfe `xPlayer.getGroup()` und `xPlayer.job`

### Kamera nicht gespeichert

- Prüfe oxmysql-Verbindung
- Prüfe `cameras`-Tabelle
- Prüfe SQL-Fehler in der Server-Konsole

## 8. Erweiterungen

Das System ist so aufgebaut, dass spätere Funktionen wie:

- Kamera-Hacking
- Stromausfall
- PTZ-Kameras
- Zoom und Nachtmodus
- automatische Beweismittel
- Polizei-Akten-Integration

leicht ergänzt werden können.

## 9. Lizenz

Für deinen Server frei nutzbar, sofern die Konfiguration und der Framework-Stack korrekt umgesetzt werden.
