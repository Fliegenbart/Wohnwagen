# CamperReady Release-Status

Stand: 4. April 2026

## Was jetzt fertig ist

- Die App ist jetzt deutlich mehr als ein MVP.
- `Home` zeigt nicht nur Probleme, sondern führt direkt zum richtigen Bereich.
- `Gewicht` ist ein echter Arbeitsbereich mit Anlegen, Bearbeiten und Löschen.
- `Checklisten` lassen sich starten, pflegen, sortieren, zurücksetzen und abschließen.
- `Logbuch` und `Kosten` sind als Alltagswerkzeuge benutzbar.
- Dokumente, Wartung und Orte können echte Anhänge wie Bilder oder PDFs bekommen.
- Erinnerungen decken jetzt Dokumente, Wartung, Kilometer-Themen, Saison-Themen und Abfahrtsvorbereitung ab.
- Exporte sind robuster und es gibt zusätzlich ein Datenarchiv als JSON.
- Die App zeigt jetzt sichtbar an, wenn der lokale Datenspeicher nur im Notfallmodus läuft.
- Build und Tests laufen erfolgreich.

## Was weiterhin bewusst nicht drin ist

- Kein Benutzerkonto
- Kein Backend
- Kein iCloud-Backup
- Kein Face-ID-App-Lock
- Keine öffentliche Platzdatenbank
- Keine Buchung, Navigation oder Community-Funktionen

## Was vor dem echten App-Store-Release noch außerhalb des Codes erledigt werden muss

- echte Datenschutz-Seite veröffentlichen
- echte Support-Seite veröffentlichen
- TestFlight auf echten iPhones durchführen
- App-Store-Screenshots final erstellen
- App-Store-Connect-Eintrag und Apple-Developer-Themen fertig machen

## Technischer Stand

- Architektur: SwiftUI + SwiftData + lokale Services
- Plattform: iPhone, iOS 17+
- Datenhaltung: lokal auf dem Gerät
- Benachrichtigungen: lokal
- Export: CSV, PDF und JSON-Datenarchiv

## Kurzfazit

`CamperReady` ist jetzt in einem Zustand, in dem man die Kernidee wirklich benutzen kann:

Vor einer Fahrt sehen, was offen ist, direkt zum Problem springen, Dinge erfassen, Fristen im Blick behalten und die wichtigsten Camper-Daten lokal verwalten.
