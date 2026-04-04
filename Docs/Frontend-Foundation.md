# CamperReady Frontend Foundation

Dieses Dokument legt die gestalterische Richtung fuer CamperReady fest, bevor weitere UI-Flaechen gebaut oder umgebaut werden. Ziel ist nicht "schick um jeden Preis", sondern eine klare, vertrauenswuerdige App, die vor jeder Fahrt in wenigen Sekunden Orientierung gibt.

## Skill Snapshot

Bevor weitere starke UI-Flaechen gebaut werden, gelten fuer CamperReady diese 3 Leitfragen:

- `Visual thesis`: Wie fuehlt sich die App an?
- `Content plan`: Was sieht der Nutzer zuerst, dann danach, dann zuletzt?
- `Interaction thesis`: Welche 2 bis 3 Bewegungen geben der App Praesenz, ohne zu stoeren?

## 1. Visual Thesis

CamperReady soll sich anfuehlen wie ein ruhiges, hochwertiges Werkzeug fuer verantwortungsvolle Besitzer:innen.

Ein-Satz-These:

`CamperReady wirkt wie ein praezises Reise-Werkzeug aus Asphalt, Metall und Morgenlicht: ruhig, sicher, konzentriert und sofort einsatzbereit.`

Die visuelle Leitidee ist:

- nicht Camping-Romantik
- nicht Reise-Blog
- nicht Technik-Spielerei
- sondern: klare Abfahrtskontrolle fuer den Alltag

Die App wirkt am staerksten, wenn jede wichtige Flaeche diese 4 Signale sendet:

- Ich weiss sofort, worum es geht.
- Ich sehe sofort, ob etwas offen ist.
- Ich kann sofort den naechsten sinnvollen Schritt machen.
- Die App uebertreibt nicht und verspricht keine falsche Genauigkeit.

### Visuelle Richtung

- `Road utility`: Asphalt, Metall, Himmel, Morgengrauen statt bunter Camping-Deko
- `Calm authority`: ruhig, aufgeraeumt, sicher, nicht verspielt
- `Brand as signal`: `CamperReady` ist eine klare Marke, nicht nur ein Tab-Titel
- `One composition first`: die erste sichtbare Flaeche pro Kernscreen hat genau eine Aufgabe

### Was wir vermeiden

- Pitch-Deck-Sprache
- "Cockpit", "Engine", "Readiness-Logik" als Nutzertext
- zu viele Boxen, Chips und Karten auf einmal
- austauschbare Dashboard-Gitter ohne klare Hauptaussage
- ueberschmueckte Camping-Optik

## 2. Content Plan

Frontend-Skill-Reihenfolge fuer CamperReady:

1. `Hero / First viewport`
2. `Support`
3. `Detail`
4. `Final CTA`

### Content Plan fuer die Startflaeche

#### Hero / First viewport

- Marke `CamperReady`
- eine klare Aussage zum Zustand
- eine kurze Erklaerung
- genau eine Hauptaktion
- ein dominanter visueller Anker

#### Support

- die 5 Kernbereiche mit je einer klaren Statuszeile
- kein Gitter aus gleich wichtigen Kacheln
- keine Erklaerungen zur Produktidee

#### Detail

- offene Punkte
- naechste Schritte
- dazu passende Tiefe in den Fachbereichen

#### Final CTA

- `Vor Abfahrt pruefen`
- oder im leeren Zustand: `Fahrzeug anlegen`

Die App braucht auf jedem Kernscreen eine einfache Inhaltsreihenfolge:

1. Was ist mein aktueller Zustand?
2. Was ist das Wichtigste, das ich jetzt wissen muss?
3. Was sollte ich als Naechstes tun?
4. Welche Details helfen mir dabei?

### Home

Job:

- beantwortet: "Kann ich losfahren?"

Inhalt:

- Fahrzeugname
- klare Hauptaussage: `Abfahrbereit`, `Nicht bereit` oder `X Punkte offen`
- kurze Erklaerung in Alltagssprache
- eine klare Hauptaktion: `Vor Abfahrt pruefen`
- danach die 5 Bereiche mit kurzen, konkreten Statuszeilen
- danach offene Punkte und Schnellzugriffe

### Gewicht

Job:

- beantwortet: "Bin ich plausibel beladen oder sollte ich noch etwas aendern?"

Inhalt:

- klare Gewichtsaussage
- Reserve, Wasser, Achslast-Risiko
- groesste Gewichtstreiber
- Packliste
- Mitfahrende
- Hinweise nur dann, wenn sie dem Nutzer wirklich helfen

### Checklisten

Job:

- beantwortet: "Was muss ich fuer diese Situation noch erledigen?"

Inhalt:

- ausgewaehlte Checkliste
- Fortschritt
- Pflichtpunkte
- Aufgabenliste
- weitere Checklisten erst danach

### Logbuch

Job:

- beantwortet: "Wo finde ich Wartung, Dokumente und meine Platznotizen?"

Inhalt:

- kurzer Ueberblick
- klar getrennte Bereiche fuer Wartung, Dokumente, Orte
- Fristen und Hinweise einfach und sachlich formuliert

### Kosten

Job:

- beantwortet: "Was kostet mich diese Reise und was kostet mich mein Fahrzeug insgesamt?"

Inhalt:

- Kosten dieser Reise
- pro Nacht / pro 100 km
- regelmaessige Kosten
- Eintraege in klaren, alltagstauglichen Kategorien

### Onboarding

Job:

- beantwortet: "Warum soll ich die App jetzt einrichten?"

Inhalt:

- ein klares Nutzenversprechen
- 3 kurze Gruende
- direkte Aktion: Fahrzeug anlegen

## 3. Interaction Thesis

CamperReady ist kein Produkt zum Stoebern. Es ist ein Werkzeug zum schnellen Entscheiden.

Ein-Satz-These:

`Interaktionen sollen Orientierung geben, Reihenfolge spuerbar machen und Entscheidungen erleichtern, aber nie wie Show-Effekte wirken.`

Darum gelten fuer Interaktionen diese Regeln:

- `1 klare Hauptaktion pro Screen`
- `schnell lesbar vor tief klickbar`
- `offene Punkte zuerst, Details spaeter`
- `Bewegung nur fuer Orientierung, nie fuer Show`

### Interaktionsprinzipien

- Hauptaktionen stehen klar sichtbar oben
- Sekundaere Aktionen folgen darunter
- Listen helfen bei Arbeitsschritten, nicht bei Deko
- Farben bedeuten immer Zustand, nicht Stimmung
- Gelb heisst: bitte pruefen
- Rot heisst: jetzt nicht einfach losfahren
- Gruen heisst: aktuell unkritisch

### Motion

Bewegung soll nur 3 Dinge tun:

- Reihenfolge zeigen
- Fokus setzen
- Rueckmeldung geben

Das bedeutet konkret:

- sanfter Hero-Einstieg beim ersten Oeffnen
- leichte Staffelung bei wichtigen Inhaltsbereichen
- subtile Betonung fuer Hauptaktionen

Diese 3 Bewegungen sind der Standard fuer kuenftige starke UI-Flaechen:

1. `Hero entrance`: ruhiges Einblenden und leichtes Hochziehen der ersten Hauptflaeche
2. `Section reveal`: gestaffeltes Erscheinen der wichtigsten Bereiche beim Scrollen oder Oeffnen
3. `Action emphasis`: dezente Bewegung bei der primaeren Aktion oder beim Zustandswechsel

Keine dauernd springenden oder dekorativen Animationen.

## 4. Copy Thesis

Alle Texte muessen aus Nutzersicht geschrieben sein.

Die App soll dem Nutzer sagen:

- was gerade passt
- was fehlt
- was er als Naechstes tun sollte

Nicht sagen:

- warum das UI so aufgebaut ist
- wie die interne Logik funktioniert
- wie "ehrlich", "operativ" oder "strategisch" das Produkt ist

### Gute Textmuster

- `Noch 2 Punkte offen`
- `Gaspruefung laeuft im August ab`
- `Wiegen empfohlen`
- `Tankbeleg fehlt noch`
- `Diese Reise kostet bisher 186 EUR`

### Schlechte Textmuster

- `Der Modus wirkt direkt auf deine Bereitschaft`
- `Die Kernbereiche ruecken hinter die Abfahrtsentscheidung`
- `Ein lesbares Eigentuemer-Logbuch statt verstreuter Einzelnotizen`

## 5. Screen Rules

Diese Regeln gelten fuer kuenftige UI-Arbeit:

- Erste Flaeche eines Kernscreens: nur eine Hauptaussage
- Die Marke bleibt auf starken, gebrandeten Flaechen klar sichtbar
- Ueberschriften immer nutzerbezogen, nicht konzeptbezogen
- Karten nur, wenn sie fuer Bedienung wirklich helfen
- Leere Zustaende sagen klar, was als Naechstes zu tun ist
- Jeder Status braucht wenn moeglich eine naechste Aktion
- Keine Fachsprache ohne direkten Nutzen
- Wenn eine Flaeche auch ohne Schatten oder Box gut funktioniert, braucht sie keine Karte
- Wenn eine Ueberschrift wie Werbung klingt, wird sie vereinfacht

## 6. Definition Of Done For Future UI Work

Ein neuer oder ueberarbeiteter Screen ist erst dann "fertig", wenn:

- man in 3 Sekunden versteht, worum es geht
- die erste sichtbare Flaeche nur eine Hauptaufgabe hat
- die Texte wie Alltagshilfe klingen
- Farben konsistent Status bedeuten
- es eine klare naechste Aktion gibt
- der Screen auch auf kleinen iPhones ruhig und lesbar bleibt

## 7. Next Design Passes

Die naechsten sinnvollen UI-Schritte fuer CamperReady sind:

1. Dieselbe Text- und Fokus-Regel auf Nebenflaechen anwenden
2. `Kosten` visuell auf das neue System angleichen
3. Formulare fuer Fahrzeug, Dokumente und Eintraege sprachlich vereinfachen
4. Empty States und CTA-Texte in allen Tabs vereinheitlichen
5. Danach erst Feinschliff fuer Animationen und Detailpolish
