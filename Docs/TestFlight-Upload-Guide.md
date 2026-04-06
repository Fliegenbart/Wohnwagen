# CamperReady TestFlight Upload Guide

Stand: 4. April 2026

## Worum es hier geht

Diese Datei ist die einfache Schritt-fuer-Schritt-Anleitung, wenn du `CamperReady` als echte iPhone-App archivieren und nach TestFlight hochladen willst.

## Was im Projekt jetzt vorbereitet ist

- Die App laesst sich als echtes iPhone-Archiv bauen.
- Version und Build-Nummer kommen sauber aus den Xcode-Konfigurationen.
- Es gibt zwei Helfer-Skripte:
  - `Scripts/release_preflight.sh`
  - `Scripts/archive_for_testflight.sh`
- Die App hat jetzt auch den Export-Compliance-Eintrag `ITSAppUsesNonExemptEncryption = false`, damit dieser Punkt beim Upload nicht extra offen bleibt.

## Einmalig vor dem ersten Upload

1. Oeffne [CamperReady.xcodeproj](/Users/davidwegener/Desktop/WohnWagenApp/CamperReady.xcodeproj) in Xcode.
2. Waehle das Projekt `CamperReady` aus.
3. Gehe zu `Signing & Capabilities`.
4. Waehle dein Apple-Developer-Team.
5. Pruefe, dass die Bundle ID `com.camperready.app` fuer deine App Store Connect App passt.
6. Lege die App in App Store Connect an, falls das noch nicht passiert ist.
7. Stelle sicher, dass Datenschutz- und Support-URL in App Store Connect eingetragen werden.

## Vor jedem neuen TestFlight-Build

1. Erhoehe die `Build`-Nummer in Xcode oder nutze spaeter einen Override im Archiv-Skript.
2. Fuehre den Vorab-Check aus:

```bash
bash Scripts/release_preflight.sh
```

Das Skript prueft:
- Simulator-Build
- Tests
- Release-Archiv ohne Signierung

Wenn das gruen ist, ist der technische Unterbau okay.

## Signed Archive fuer TestFlight erstellen

Wenn dein Team in Xcode eingeloggt ist, kannst du das Archiv-Skript mit deiner Team-ID starten:

```bash
DEVELOPMENT_TEAM=DEINTEAMID bash Scripts/archive_for_testflight.sh
```

Optional kannst du Version oder Build fuer diesen Lauf ueberschreiben:

```bash
DEVELOPMENT_TEAM=DEINTEAMID \
MARKETING_VERSION_OVERRIDE=1.0 \
CURRENT_PROJECT_VERSION_OVERRIDE=2 \
bash Scripts/archive_for_testflight.sh
```

Das Skript legt das Archiv im normalen Xcode-Archivordner ab:

`~/Library/Developer/Xcode/Archives/<Datum>/...`

## Upload in TestFlight

Nach dem Archiv:

1. Oeffne Xcode
2. `Window > Organizer`
3. Waehle dein neues Archiv
4. `Distribute App`
5. `App Store Connect`
6. `Upload`
7. Standardoptionen bestaetigen, falls du nichts Besonderes brauchst

Danach erscheint der Build in App Store Connect unter `TestFlight`.

## Danach in App Store Connect

### Fuer interne Tester

- App auswaehlen
- `TestFlight` oeffnen
- Build waehlen
- interner Gruppe zuordnen

### Fuer externe Tester

Apple verlangt fuer den ersten externen TestFlight-Build eine Beta-Pruefung.

Kurz gesagt:
- interne Gruppe anlegen
- externe Gruppe anlegen
- Build zur Gruppe hinzufuegen
- `What to Test` ausfuellen
- `Submit Review`

## Hauefige Probleme

### Kein Team gesetzt

Dann kann Xcode kein signiertes Archiv fuer TestFlight erstellen.

Loesung:
- In Xcode unter `Signing & Capabilities` ein Team auswaehlen
- oder `DEVELOPMENT_TEAM=...` beim Skript setzen

### Build schon vorhanden

App Store Connect nimmt dieselbe `Version + Build` nicht noch einmal.

Loesung:
- `Build` erhoehen

### App taucht nicht in TestFlight auf

Oft braucht App Store Connect nach dem Upload ein paar Minuten.

Wenn nach laengerer Zeit nichts erscheint:
- Upload-Log in Xcode pruefen
- Bundle ID vergleichen
- App-Record in App Store Connect pruefen

## Offizielle Apple-Hilfen

- [Upload a build](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/)
- [Distribute an app using TestFlight](https://developer.apple.com/testflight/)
- [Invite external testers](https://developer.apple.com/help/app-store-connect/test-a-beta-version/invite-external-testers/)
- [Add a new app](https://developer.apple.com/help/app-store-connect/create-an-app-record/add-a-new-app/)
