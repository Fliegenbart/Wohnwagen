# CamperReady Startsceen Spec

## Ziel
CamperReady bekommt einen kurzen, schönen Startsceen, der bei jedem App-Start kurz aufleuchtet und dann automatisch in den normalen Startfluss uebergeht.

Der Screen soll die App sofort als CamperReady erkennbar machen, ruhig und hochwertig wirken und dem Nutzer einen kleinen Moment Orientierung geben. Er ist kein neuer Arbeitsbereich und keine neue Navigation, sondern ein eleganter Einstieg vor dem eigentlichen Cockpit.

## Design North Star
Der Startsceen ist `kurz, ruhig und markant`.

Das bedeutet:
- klare Markenwahrnehmung ohne viele Elemente
- ein einzelner ruhiger Fokus statt vieler Daten oder Kacheln
- kein Button-Friedhof, keine Auswahl, keine Erklaertexte
- minimale Bewegung mit sauberem Ausstieg
- iPhone-first, lesbar und unaufgeregt

## Einordnung im App-Start
Der Startsceen erscheint als in-app Uebergang direkt nach dem nativen iOS-Launchscreen.

Danach laeuft die bestehende Startlogik weiter:
- wenn kein Fahrzeug existiert und Onboarding offen ist, erscheint das Onboarding
- wenn mehrere Fahrzeuge ohne gueltige Auswahl vorhanden sind, erscheint die Fahrzeugauswahl
- sonst geht die App direkt mit dem zuletzt genutzten Fahrzeug ins Cockpit

Der Startsceen veraendert diese Logik nicht. Er sitzt nur davor und macht den Einstieg schoener.

## Visual Thesis
CamperReady startet wie ein hochwertiges Arbeitsgeraet: ruhig, sicher, modern und minimal.

Die Brand muss sofort sichtbar sein. Der Screen darf bewusst wenig sagen, aber das, was er sagt, muss klar und vertrauenerweckend sein.

## Content Plan
Der Startsceen besteht nur aus drei Ebenen:

1. Marke
`CamperReady` steht gross und klar im Zentrum.

2. Kurzer Satz
Eine knappe Zeile wie `Bereit fuer die Abfahrt.` gibt dem Start einen ruhigen Ton.

3. Leichte Bewegung
Eine kleine Lade- oder Uebergangsbewegung signalisiert, dass die App im Hintergrund den naechsten Bildschirm vorbereitet.

Es gibt keine weiteren Informationen, keine Kacheln, keine Buttons und keine Ablenkung.

## Interaction Thesis
Die Bewegung ist absichtlich klein:
- Fade-in des Brand-Stacks beim Oeffnen
- sanftes Ausblenden beim Uebergang in Onboarding, Fahrzeugauswahl oder Cockpit
- reduzierte Bewegung respektieren, ohne die Logik zu aendern

Der Screen darf nicht wie ein Splash-Video wirken. Er soll sich eher wie ein kurzer, hochwertiger Atemzug anfuehlen.

## Screen Rules
- Keine Benutzereingabe
- Keine Auswahl
- Keine Liste
- Kein Formular
- Keine zweite Marke oder Werbebotschaft
- Kein Karten-Look
- Keine grossen Erklaertexte

## Layout
Die erste Ansicht ist sehr ruhig aufgebaut:
- gross gesetztes `CamperReady`
- darunter ein kurzer Satz
- unten eine kleine, dezente Fortschrittsanzeige oder Linie

Der Hintergrund bleibt hell und weich. Ein einzelner Petrol-Akzent darf vorhanden sein, aber nur dezent.

## Accessibility
- Dynamic Type muss die kleine Unterzeile nicht zerreissen
- VoiceOver soll den Brand-Stack in sinnvoller Reihenfolge lesen
- Reduced Motion muss den gleichen Ablauf ohne auffaellige Animationen zeigen
- Kontrast muss auch auf kleinen iPhones stabil bleiben

## Nicht-Ziele
- kein neuer Onboarding-Schritt
- kein Login-Screen
- kein Auswahl-Screen
- keine lang laufende Animation
- kein Marketing-Bildschirm
- keine extra Produkt-Erklaerung

## Umsetzungsreihenfolge
1. Einen klaren Startsceen als eigene View anlegen
2. Die Startansicht fuer eine kurze Zeit einblenden
3. Danach automatisch in die bestehende Startlogik weitergehen
4. Mit Previews und Simulator pruefen, dass der Uebergang ruhig bleibt

## Akzeptanzkriterien
- Beim Start sieht man CamperReady sofort als Marke
- Der Screen ist sehr kurz und blockiert die App nicht
- Die App landet danach korrekt im bestehenden Flow
- Der Screen wirkt premium, ruhig und iPhone-first
- Keine neuen Kacheln, keine Buttons, keine unnötige Information

## Risiken und Gegenmassnahmen
- Risiko: Der Screen fuehlt sich wie ein leerer Splash an.
  Gegenmassnahme: Brand, Satz und Uebergang muessen sauber komponiert sein.

- Risiko: Der Startsceen bremst den Zugang zur App.
  Gegenmassnahme: Die Einblendung bleibt bewusst kurz und respektiert Reduced Motion.

- Risiko: Er kollidiert mit Onboarding oder Fahrzeugauswahl.
  Gegenmassnahme: Die bestehende Startlogik bleibt unveraendert und wird nur vorgelagert.
