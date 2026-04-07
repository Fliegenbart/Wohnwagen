# CamperReady Stitch Redesign Spec

## Ziel
CamperReady bekommt ein neues, durchgaengiges Erscheinungsbild auf Basis der gelieferten Stitch-Vorlagen aus `/Users/davidwegener/Downloads/stitch-2.zip`.

Die App soll sich danach wie ein ruhiges, hochwertiges Werkzeug anfuehlen: weniger klassische App-Kacheln, mehr Flaechenruhe, klarere Hierarchie, mehr Materialitaet und deutlich weniger visuelle Unruhe. Das Ergebnis soll nicht wie ein Camping-Portal wirken, sondern wie ein praezises privates Cockpit fuer die Einsatzbereitschaft eines Campers.

## Design North Star
Die visuelle Leitidee ist `Alpine Utility Zen`.

Das bedeutet:
- helles, warmes Grundbild statt kalter Standard-iOS-Weissflaechen
- Petrol als zentrale Marken- und Aktionsfarbe
- sehr wenig sichtbare Linien und kaum harte Rahmen
- grosse, ruhige Typografie fuer Orientierung
- dunkle Fokusflaechen nur dort, wo echte Prioritaet oder Aktion liegt
- viel Leerraum und klare Gruppierung statt vieler gleich lauter Karten

## Stitch als Vorlage
Die Stitch-Dateien werden nicht 1:1 kopiert, sondern als verbindliche visuelle Referenz genutzt.

Verwendete Vorlagen:
- `readiness_cockpit`: Vorlage fuer Home und die generelle Hierarchie von Status, Fokusblock und Utility-Reihen
- `weight_analysis`: Vorlage fuer Gewicht, besonders fuer den dunklen Analyseblock, die technische Flaechenlogik und die reduzierte Lastenliste
- `your_fleet`: Vorlage fuer Garage, Fahrzeugwahl und den Umgang mit grossen, ruhigen Fahrzeugflaechen
- `logbook_cost_history`: Vorlage fuer Logbuch und spaeter auch fuer Kosten, besonders fuer grosse Headline-Systeme und Listen mit klarer Verdichtung
- `alpine_utility_zen/DESIGN.md`: verbindliche Systemregeln fuer Farbe, Typografie, Flaechen, Abstaende und Materialwirkung

Was wir nicht uebernehmen:
- Platzhalter-Bildwelten, die nicht zu CamperReady passen
- illustrative Motive wie Ritter oder Yacht
- generische Marketing-Optik

Was wir uebernehmen:
- Komposition
- Typografische Hierarchie
- Flaechenlogik
- Farbklima
- Dichte und Rhythmus
- ruhige, hochwertige Interaktionssprache

## Visual Thesis
CamperReady wirkt wie ein praezises Reiseinstrument aus der DACH-Welt: technisch, ruhig, edel, klar und vertrauenswuerdig.

Die App soll sich anfuehlen wie ein hochwertiger Gegenstand mit echter Funktion. Nicht verspielt im Sinne von bunt-chaotisch, sondern souveraen, reduziert und klar gesteuert. Farbe dient Orientierung und Schwerpunkt, nicht Dekoration.

## Content Plan
Jeder Hauptscreen folgt kuenftig derselben inhaltlichen Ordnung:

1. Orientierung
Der obere Bereich sagt sofort, wo man ist und was gerade wichtig ist.

2. Fokus
Ein dominanter Block zeigt die wichtigste Aussage oder Handlung des Screens.

3. Arbeitsbereich
Darunter folgen die eigentlichen Eintraege, Listen, Formulare oder Aktionen in einer ruhigen und reduzierten Struktur.

4. Sekundaere Details
Hinweise, Kontext, Export und seltene Aktionen werden visuell zurueckgenommen.

## Interaction Thesis
Die App nutzt wenige, gezielte Bewegungen:
- sanftes Einblenden beim ersten Oeffnen eines Screens
- klare Zustandswechsel bei Status, Auswahl und Segmentwechseln
- subtile Betonung fuer primaere Aktionen

Es gibt keine dekorativen Animationen ohne Nutzen. Bewegung soll Orientierung verbessern und den hochwertigen Eindruck unterstuetzen.

## App-weite Systemregeln

### Farbe
- Hintergrund wird auf warmes Off-White umgestellt
- Primaerfarbe ist Petrol
- Gruen, Gelb und Rot bleiben fuer Bereitschaft erhalten, aber gedeckter und sparsamer
- Dunkle Flaechen kommen nur fuer Fokusmodule und starke CTAs zum Einsatz

### Flaechen
- Keine harten 1px-Rahmen als Standard
- Gruppierung erfolgt ueber Hintergrundwechsel, Radius, Abstand und Flaechentiefe
- Karten sind nur erlaubt, wenn sie eine echte Interaktion oder eine klare Fokusbox bilden
- Listen, Zeilen und Sektionen sollen haeufiger ohne klassische Kartengrenzen funktionieren

### Typografie
- Sans-Serif bleibt, aber mit staerkerer Hierarchie
- grosse Headlines fuer Orientierung
- kleinere Utility-Labels fuer Status und Werte
- weniger All Caps, nur dort wo ein technischer Label-Charakter sinnvoll ist

### Icons
- duenne, klare SF Symbols
- keine ornamental gefuellten Icon-Kompositionen

### Motion
- Bewegungen sind weich, kurz und konsistent
- reduzierte Bewegung muss korrekt respektiert werden

## Screen Mapping

### Home
Basis ist `readiness_cockpit`.

Ziel:
- ein ruhiger Bereitschafts-Screen statt vieler gleich lauter Bloecke
- klare Headline zur Abfahrtsbereitschaft
- ein dominanter Fokusblock fuer den wichtigsten Zustand
- darunter reduzierte Utility-Reihen fuer offene Punkte und naechste Schritte

Konkrete Uebersetzung fuer CamperReady:
- Fahrzeugname und Bereitschaft stehen oben
- die wichtigste Aussage steht gross und klar
- `Vor Abfahrt pruefen` bleibt die Hauptaktion
- die fuenf Bereitschaftsdimensionen werden von einer Tile-Logik in eine ruhigere Listen- oder Stapelstruktur ueberfuehrt
- Garage-Zugang wird klar integriert, aber nicht laut

### Gewicht
Basis ist `weight_analysis`.

Ziel:
- Gewicht fuehlt sich technischer und vertrauenswuerdiger an
- eine dominante Analyseflaeche zeigt Gesamtgewicht, Reserve und Risiko
- Lasten, Packstuecke und Mitfahrende folgen in einfachen Utility-Sektionen

Konkrete Uebersetzung:
- die obere Gewichtsflaeche wird dunkler und fokussierter
- Kennzahlen werden groesser und klarer
- die bisherigen vielen Teilkarten werden reduziert
- Zusatzlasten, Wasser, Gas und Personen wirken wie geordnete Eintraege statt wie verstreute UI-Bausteine

### Garage
Basis ist `your_fleet`.

Ziel:
- Fahrzeugwahl wird ein echter Premium-Bereich
- das aktive Fahrzeug ist klar sichtbar
- mehrere Fahrzeuge koennen ruhig und selbsterklaerend gewechselt werden

Konkrete Uebersetzung:
- jede Fahrzeugflaeche bekommt eine klarere visuelle Buehne
- Basisdaten erscheinen reduziert und hochwertig gruppiert
- `Neues Fahrzeug` wird als markante, aber ruhige Aktion gefuehrt

### Logbuch
Basis ist `logbook_cost_history`.

Ziel:
- Logbuch wird editorialer und ruhiger
- grosse Headline, klare Summen, danach eine saubere Chronologie

Konkrete Uebersetzung:
- Wartung, Dokumente und Orte behalten ihre Funktion, bekommen aber weniger UI-Rahmen
- Kennzahlen stehen freier auf der Flaeche
- Listen wirken reduzierter und strukturierter

### Checklisten
Ableitung aus `readiness_cockpit` und `weight_analysis`.

Ziel:
- Checklisten sind kein Kartenfriedhof mehr
- ein Modus steht im Fokus, Fortschritt und Pflichtpunkte werden klar und ruhig dargestellt

Konkrete Uebersetzung:
- der aktive Modus bekommt eine dominante Kopfzone
- Fortschritt und Pflichtstatus erscheinen als reduzierte Utility-Werte
- Punkte erscheinen als klare Arbeitsliste mit wenig visuellem Geraeusch

### Kosten
Ableitung aus `logbook_cost_history`.

Ziel:
- Kosten wirken wie ein sachlicher Rueckblick, nicht wie ein Finanztool
- Summen und Trends sind schnell erfassbar

Konkrete Uebersetzung:
- ruhige Kennzahlen oben
- Reisekosten und Jahreskosten als klare Listenlogik
- Export bleibt vorhanden, aber visuell nachgeordnet

## Nicht-Ziele
- kein komplettes Rebranding von CamperReady
- kein Umbau der Produktlogik
- keine illustrative oder laute Automotive-Showroom-Optik
- keine Uebernahme unpassender Stitch-Bildmotive

## Umsetzungsreihenfolge
1. Design-System und gemeinsame UI-Bausteine
2. Home
3. Gewicht
4. Checklisten
5. Garage
6. Logbuch
7. Kosten
8. Formulare und Sheets

## Akzeptanzkriterien
- Die App wirkt app-weit aus einem Guss und nicht mehr wie einzelne Screens aus verschiedenen Phasen.
- Home, Gewicht, Checklisten, Logbuch, Kosten und Garage teilen dieselbe Flaechen- und Typologik.
- Die Zahl klassischer Karten wird deutlich reduziert.
- Wichtige Aussagen stehen klarer im Vordergrund als sekundere Details.
- Die App bleibt iPhone-first, lokal, schnell und gut lesbar.
- Die Stitch-Vorlagen sind als Einfluss deutlich erkennbar, ohne dass CamperReady seine eigene Funktion oder Sprache verliert.

## Risiken und Gegenmassnahmen
- Risiko: Nur Farben werden uebernommen, aber nicht die neue Komposition.
  Gegenmassnahme: Erst die Layout-Logik anpassen, dann Feinschliff.

- Risiko: Die App verliert im Versuch, edler zu werden, ihre Alltagstauglichkeit.
  Gegenmassnahme: Utility Copy, klare Statuslogik und direkte Aktionen bleiben erhalten.

- Risiko: Zu viele Rest-Komponenten aus dem alten Kartensystem verwischen die neue Linie.
  Gegenmassnahme: Gemeinsame UI-Bausteine zuerst umbauen und alte Muster aktiv zurueckdrangen.
