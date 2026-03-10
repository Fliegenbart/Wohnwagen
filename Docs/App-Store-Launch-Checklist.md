# CamperReady App Store Launch Checklist

Diese Checkliste ist auf den aktuellen Stand von `CamperReady` zugeschnitten:

- SwiftUI + SwiftData
- iPhone-first
- offline-first
- keine Accounts
- keine Backend-Abhaengigkeit
- lokale Notifications, PDF/CSV-Export, private Ortsnotizen

Ziel:

- aus dem aktuellen MVP einen echten, review-faehigen App-Store-Release machen

## Statusbild heute

Schon vorhanden:

- lauffaehiges iOS-Projekt
- App-Shell mit 5 Tabs
- lokale Persistenz
- Sample Data
- Readiness-Engine
- Export- und Notification-Scaffold
- deutscher Kern-UX-Fluss

Offensichtlich noch offen:

- Release-Signing finalisieren
- App-Icon / Branding-Assets
- Privacy Policy und Support-URL
- App Store Connect Record
- App Privacy Angaben
- echter Device-Test
- Release-Haertung fuer Seed-Daten und Debug-Verhalten
- Store-Screenshots und Marketing-Texte
- Review-sichere Produkttexte fuer rechtlich sensible Bereiche

## Must

Diese Punkte muessen vor dem ersten echten Store-Release erledigt sein.

### 1. Apple- und Vertriebs-Setup

- Apple Developer Program aktiv
- aktuelle Agreements in App Store Connect akzeptiert
- final entscheiden: Individual oder Organization
- EU Trader Status in App Store Connect setzen, wenn die App im EU-Raum vertrieben wird

### 2. Produktidentitaet festziehen

- finalen App-Namen festlegen
- finalen Bundle Identifier festlegen
- Copyright-Angabe vorbereiten
- Support-E-Mail oder Support-Seite bereitstellen
- Privacy-Policy-Seite veroeffentlichen

Empfohlene Werte:

- App Name: `CamperReady`
- Bundle ID: `com.<deine-marke>.camperready`

### 3. Xcode-Release-Setup

- Signing-Team im Projekt final setzen
- automatische oder manuelle Signierung verbindlich konfigurieren
- Version und Build-Nummer sauber pflegen
- Release-Konfiguration auf echtem Geraet pruefen
- Archivierung in Xcode erfolgreich durchlaufen

Konkrete To-dos fuer dieses Repo:

- Projekt in Xcode oeffnen
- `Team` setzen
- `Bundle Identifier` final setzen
- `Version` auf `1.0.0`
- `Build` auf `1`

### 4. App-Icon und visuelle Release-Assets

- vollstaendigen App-Icon-Satz anlegen
- Launch-Darstellung auf echtem Geraet pruefen
- App-Store-Screenshots fuer mindestens ein iPhone-Format erzeugen

Empfehlung fuer V1:

- zuerst nur iPhone-Screenshots fuer DE-DE
- Screens zeigen:
  - Home
  - Gewicht
  - Checklisten
  - Logbuch
  - Kosten

### 5. Datenschutz und Review-Compliance

- Privacy Policy URL hinterlegen
- App Privacy in App Store Connect vollstaendig beantworten
- pruefen, ob `Data Not Collected` wirklich stimmt
- pruefen, ob Tracking = `No` bleibt
- pruefen, ob Required Reason APIs / Privacy Manifest noetig sind
- Produkttexte so formulieren, dass die App als Organisationshilfe erscheint, nicht als Rechtsberatung

Fuer den aktuellen Code-Stand ist die wahrscheinlichste Position:

- keine Account-Daten
- keine Tracking-SDKs
- keine Cloud-Sync
- keine externe Analytics

Das spricht voraussichtlich fuer:

- kein Tracking
- moeglicherweise `No, we do not collect data from this app`

Wichtig:

- das gilt nur, solange keine Analytics-, Crash-, Werbe- oder Backend-SDKs dazukommen

### 6. Rechtlich sensible Copy absichern

Besonders pruefen:

- Gaspruefung
- Dokumente / Fristen
- Winterisierung
- Bereitschaftsstatus

Produktregel fuer Store und App:

- niemals so formulieren, als waere `CamperReady` eine verbindliche Rechts- oder Sicherheitsfreigabe

Empfohlene Formulierung:

- `Persoenliche Erinnerung und Organisationshilfe`
- `Regeln koennen sich aendern`
- `Angaben ohne Rechtsberatung`

### 7. Seed-Daten und Demo-Verhalten fuer Release absichern

Aktuell seeded die App Beispieldaten beim ersten Start.

Vor Store-Release klaeren:

- sollen neue Nutzer mit Demo-Daten starten
- oder soll die Produktion leer starten

Empfehlung:

- fuer echten Store-Release lieber leerer Erststart mit optionalem Demo-Modus

Wenn Demo-Daten bleiben:

- klar als Beispiel markieren
- keine missverstaendlichen Fake-Inspektionsdaten anzeigen

### 8. Echte iPhone-Qualitaet pruefen

Vor Review mindestens testen auf:

- ein kleines iPhone-Layout
- ein aktuelles groesseres iPhone
- Light Mode
- Dynamic Type Standard
- Offline-Betrieb
- App-Neustart
- Erststart ohne vorhandene Daten

Manuelle Kernfluesse:

- Fahrzeug anlegen
- Gewicht berechnen
- Checkliste starten und abschliessen
- Dokument mit Frist pruefen
- Kosten erfassen
- Export ausloesen

### 9. Crash- und Fail-Safety im MVP

- keine harten Abhaengigkeiten an Sample Data
- kein kaputter Start bei leerer Datenbank
- keine unerklaerten leeren Screens
- keine Blockade, wenn Notifications abgelehnt werden
- Export muss bei Fehlern sauber abbrechen

### 10. App Store Connect Einreichung

- App Record anlegen
- Kategorien waehlen
- Untertitel, Beschreibung, Keywords pflegen
- Privacy Policy URL eintragen
- Support URL eintragen
- Screenshots hochladen
- Build zuordnen
- fuer Review einreichen

## Should

Diese Punkte sind nicht immer harte Blocker, machen den Release aber deutlich besser.

### 1. Onboarding fuer echte Erstnutzer

- 60-90 Sekunden Quick Setup sauber machen
- leere Zustande mit klaren CTAs verbessern
- Demo-Daten optional statt automatisch

### 2. Settings / About Screen

- App-Version anzeigen
- Datenschutz-Link
- Support-Link
- Disclaimer zu Dokumenten / Gas / Regeln
- Export-Hinweis

### 3. Notification UX finalisieren

- saubere Reminder-Einstellungen
- Erklaerung, warum Erinnerungen nuetzlich sind
- Fallback, wenn Nutzer Notifications deaktiviert

### 4. Attachment-Flows komplett machen

- Foto/PDF-Import fuer Dokumente
- Belege fuer Wartung
- Fotos fuer Ortsnotizen

### 5. Release-Polish

- Haptik nur sehr sparsam
- bessere Fehlertexte
- konsistente Datums- und Euro-Formate
- eindeutige Empty States
- Accessibility Labels fuer Kernaktionen

### 6. Tests ausbauen

- mehr Unit-Tests fuer Readiness-Logik
- Smoke-Tests fuer leere Datenbank
- UI-Test fuer kritische Erststart-Fluesse

## Later

Diese Punkte sind fuer V1 nicht noetig, aber gute Kandidaten nach dem ersten Release.

- englische oder regionale Sprachvarianten
- iCloud-Sync oder Backup
- mehrere Fahrzeuge
- echte Attachment-Verwaltung
- bessere Reports
- wiederkehrende Wartungs-Templates
- erweiterte Auswertung pro Jahr / Saison
- Widget / Live Activity
- Siri Shortcuts / App Intents

## Konkrete Release-Reihenfolge

Empfohlene Reihenfolge fuer dieses Projekt:

1. Bundle ID, Team, Version, Build fixieren
2. App Icon und Release Branding erstellen
3. Demo-Daten-Strategie entscheiden
4. Privacy Policy und Support-Seite veroeffentlichen
5. App Privacy Antworten vorbereiten
6. rechtlich sensible Texte in App und Store copy schaerfen
7. auf echten iPhones testen
8. TestFlight intern starten
9. Store-Screenshots und Beschreibung fertigstellen
10. Review einreichen

## Repo-spezifische technische To-dos

Diese Punkte sind aus dem aktuellen Workspace direkt ableitbar.

### A. Release-Modus fuer Sample Data

Datei:

- `/Users/davidwegener/Desktop/WohnWagenApp/CamperReady/Services/SampleDataSeeder.swift`

Frage:

- sollen Seed-Daten in Production wirklich beim ersten Start erscheinen

### B. Notification Prompt UX

Datei:

- `/Users/davidwegener/Desktop/WohnWagenApp/CamperReady/App/RootTabView.swift`

Pruefen:

- Prompt-Timing fuer echte Nutzer
- Verhalten, wenn Berechtigung abgelehnt wurde

### C. Export-Funktionen

Datei:

- `/Users/davidwegener/Desktop/WohnWagenApp/CamperReady/Services/ExportService.swift`

Pruefen:

- Dateinamen
- Fehlerfall
- Qualitaet der PDF-/CSV-Ausgaben fuer Review und reale Nutzung

### D. Projektbereinigung

Im Workspace liegen auch Dateien mit Namensmustern wie:

- `WeightView 2.swift`
- `CostsView 2.swift`
- `LogbookView 2.swift`
- `ChecklistsView 2.swift`

Vor Release:

- bereinigen oder archivieren
- sicherstellen, dass keine versehentlichen Duplikate im Projekt landen

## Store-Text-Entwurf fuer V1

### Subtitle-Vorschlag

- `Bereit fuer die naechste Abfahrt`

### Kurzbeschreibung-Vorschlag

- `Das persoenliche Bereitschafts-Cockpit fuer Camper-Besitz: Gewicht, Checklisten, Fristen, Wartung und Kosten an einem Ort.`

### Kategorien-Vorschlag

- Primary: `Utilities`
- Secondary: `Travel`

## Review-Risiken, die ihr vermeiden solltet

- die App klingt wie eine amtliche Freigabe
- die App behauptet verbindliche rechtliche Gueltigkeit
- ueberladene oder irrefuehrende Beispielinhalte
- leere oder kaputte Erststart-Erfahrung
- Notification-Prompt ohne Kontext
- Screenshots zeigen Dinge, die in der App so nicht funktionieren

## Definition of Ready fuer Submission

Die App ist wirklich bereit fuer den Store, wenn:

- sie auf mindestens 2 echten iPhones sauber laeuft
- ein kompletter Erststart ohne Fehler funktioniert
- Privacy Policy und Support URL live sind
- App Privacy beantwortet ist
- Store-Screenshots und Beschreibung fertig sind
- Seed-Daten-Strategie bewusst entschieden ist
- TestFlight intern erfolgreich war
- alle rechtlich sensiblen Texte review-sicher sind
