# CamperReady Figma Blueprint

## Ziel

Diese Vorlage beschreibt die Figma-Datei fuer `CamperReady` so, dass sie spaeter 1:1 als produktnahes iPhone-first MVP umgesetzt oder per Figma MCP weiterverarbeitet werden kann.

Produktkern:

- Kein Camping-Marktplatz
- Kein Booking
- Kein Community-Feed
- Ein persoenliches Bereitschafts- und Betriebs-Cockpit fuer Camper-Besitz
- Die Startfrage lautet immer: `Kann ich jetzt losfahren?`

## Datei-Aufbau

Empfohlener Figma-Dateiname:

- `CamperReady MVP v1`

Empfohlene Seiten:

1. `00 Cover`
2. `01 Foundations`
3. `02 Components`
4. `03 App Shell`
5. `04 Home`
6. `05 Weight`
7. `06 Checklists`
8. `07 Logbook`
9. `08 Costs`
10. `09 Vehicle Setup`
11. `10 Empty + Edge States`
12. `11 Prototype`

## Device-Frames

Primary base:

- `iPhone 15 Pro / 393 x 852`

Secondary checks:

- `iPhone SE / 375 x 667`
- `iPhone 15 Pro Max / 430 x 932`

Grid:

- 4 columns
- margins `16`
- gutter `12`
- safe top spacing for hero sections

Main vertical rhythm:

- `8 / 12 / 16 / 18 / 22 / 24 / 30`

Corner radii:

- cards `22`
- hero cards `30`
- pills `16`
- buttons `999`

## Foundations

### Brand Direction

Keywords:

- praktisch
- klar
- vertrauenswuerdig
- konzentriert
- ruhig
- operativ

Das Interface soll sich anfuehlen wie:

- ein Fahrzeug-Cockpit
- ein persoenliches Kontrollzentrum
- ein nuetzliches Werkzeug

Nicht wie:

- Reise-Inspiration
- Social App
- Kartenportal
- verspielte Camping-Romantik

### Color Tokens

Canvas:

- `Canvas / Top` `#F2F5FA`
- `Canvas / Bottom` `#E3EBF5`

Ink:

- `Ink / Primary` `#141C29`
- `Ink / Secondary` `#596371`

Accent:

- `Accent / Blue` `#1278F0`

Status:

- `Status / Green` `#2B9C5C`
- `Status / Yellow` `#DB9417`
- `Status / Red` `#D94540`

Surface:

- `Surface / Card` `#FFFFFF` at ~78% opacity
- `Surface / Stroke` `#FFFFFF` at ~72% opacity

Hero gradients:

- `Hero / Green` `#2B9C5C -> #66BF82`
- `Hero / Yellow` `#DB9417 -> #F2C254`
- `Hero / Red` `#D94540 -> #F07C69`
- `Hero / Blue` `#1278F0 -> #2E9EE0`
- `Hero / Costs` `#197350 -> #39B584`

### Typography

Use iOS-native SF Pro / SF Pro Rounded.

Styles:

- `Display / Hero` 30-34 Bold Rounded
- `Title / Card` 22-24 Bold
- `Headline / Section` 17 Semibold
- `Body / Strong` 16 Semibold
- `Body / Default` 16 Regular
- `Caption / Label` 12 Bold uppercase with slight tracking
- `Caption / Meta` 12 Medium
- `Footnote` 13-14 Medium

Rules:

- Hero vehicle names may wrap to 2 lines
- Status text should stay compact
- Tile titles should never be longer than 2 lines

### Effects

- soft glass card fill
- thin white stroke
- subtle downward shadow
- restrained blur only on background shapes, not content

## Components

### Navigation

Bottom tab bar with 5 tabs:

- `Home`
- `Gewicht`
- `Checklisten`
- `Logbuch`
- `Kosten`

Visual rules:

- translucent material bar
- selected icon in blue
- no decorative badges unless readiness-critical

### Status Badge

Variants:

- `Bereit`
- `Pruefen`
- `Blockiert`

Structure:

- small dot
- compact label
- capsule background tinted by status

### Hero Card

Used on:

- Home
- Gewicht
- Checklisten
- Logbuch
- Kosten

Structure:

- eyebrow label
- large title
- subline
- top-right status badge or icon block
- 3 compact metric pills
- primary CTA on Home and Weight where relevant

### Readiness Tile

Structure:

- leading icon chip
- small status dot
- title
- summary
- one top reason
- optional next action

Tiles on Home:

- `Gewicht`
- `Gas & Dokumente`
- `Wartung`
- `Wasser / Winter`
- `Kosten`

### Section Card

Base content block for:

- lists
- grouped rows
- notes
- export actions

### Metric Card

Used for fast scanning of:

- reserve
- annual costs
- due dates
- trip values

### Action Row

Structure:

- left icon chip
- title
- chevron

Use for:

- quick actions
- logbook exports
- profile actions

## Screen Blueprints

## Home

Goal:

- answer departure readiness in under 60 seconds

Content order:

1. nav title `CamperReady`
2. export icon top right
3. hero card
4. 5 readiness tiles in 2-column grid
5. blocker card if needed
6. quick actions

Hero card content:

- eyebrow `Bereitschaft heute`
- vehicle name
- next trip or `Keine Reise geplant`
- badge `Bereit / Pruefen / Blockiert`
- open item count
- pills:
  - `Status`
  - `Reise`
  - `Blocker`
- CTA `Vor Abfahrt pruefen`

Sample copy:

- `WohnWagen Atlas`
- `Naechste Reise: Bodensee Wochenendtour`
- `4 offen`

## Gewicht

Goal:

- trustworthy, not pseudo-scientific

Content order:

1. hero `Abfahrtsentscheidung`
2. load settings card
3. quick assessment metrics
4. top weight contributors
5. packing list
6. passengers
7. warnings / honesty note

Key messages:

- `+188 kg Reserve`
- `Achslast unbekannt bei riskanter Beladung`
- `Wiegen empfohlen`

## Checklisten

Goal:

- operational modes, not loose to-do lists

Content order:

1. hero with active mode
2. horizontal mode cards
3. selected checklist card
4. progress
5. item list

Modes:

- `Abfahrt`
- `Ankunft`
- `Kurzstopp`
- `Einlagerung`
- `Einwintern`
- `Auswintern`

## Logbuch

Goal:

- owner ledger for proofs and history

Top structure:

- hero
- segmented control
- content per section

Segments:

- `Wartung`
- `Dokumente`
- `Orte`

Places section:

- private map only
- no public POI look

## Kosten

Goal:

- cost transparency, not accounting

Content order:

1. hero
2. cost metrics grid
3. trip variable costs
4. recurring fixed costs

Key metrics:

- `Diese Reise`
- `Pro Nacht`
- `Pro 100 km`
- `Jahr gesamt`

## Vehicle Setup

Flow should include:

1. quick setup
2. detailed profile

Quick setup fields:

- Fahrzeugname
- Fahrzeugtyp
- Marke
- Modell
- Kennzeichen
- zGG
- Leergewicht oder gemessenes Leergewicht

Detailed setup groups:

- Fahrzeugdaten
- Gewichte
- Wasser
- Gas
- Serviceintervalle
- Notizen
- Dokumente

## Empty + Edge States

Create dedicated frames for:

- no vehicle
- no trip planned
- no documents
- no costs yet
- no checklist started
- incomplete weight data
- overdue document
- winter mode incomplete

Rules:

- empty states must still feel useful
- always explain next best action

## Component Variants

Create variants for:

- status badge x3
- hero card x5 themes
- tile x3 statuses
- metric card default / alert
- action row default / highlighted
- mode card selected / unselected / complete
- checklist item unchecked / checked

## Prototype Flow

Connect these prototype flows:

1. `Home -> Vor Abfahrt pruefen -> Checklisten`
2. `Home -> Gewicht anpassen -> Gewicht`
3. `Home -> Dokumente pruefen -> Logbuch / Dokumente`
4. `Home -> Kosten ansehen -> Kosten`
5. `Home -> Fahrzeugprofil bearbeiten -> Vehicle Setup`

Micro-interaction guidance:

- use Smart Animate only where it improves continuity
- avoid bouncy playful transitions
- prefer direct, quick, mechanical transitions

## Naming Conventions

Frames:

- `Home / Ready`
- `Home / Warning`
- `Home / Blocked`
- `Weight / Default`
- `Checklists / Active Departure`
- `Logbook / Documents`
- `Costs / Active Trip`

Components:

- `StatusBadge / Green`
- `HeroCard / Home / Red`
- `ReadinessTile / Weight / Yellow`
- `MetricCard / Default`

## Ready-to-Build Initial Frames

If you only build the essential first pass in Figma, start with these 8 frames:

1. `Home / Blocked`
2. `Home / Ready`
3. `Weight / Default`
4. `Checklists / Departure In Progress`
5. `Logbook / Documents`
6. `Logbook / Places`
7. `Costs / Active Trip`
8. `Vehicle Setup / Quick Setup`

## Source of Truth

Design should stay aligned with the current app implementation in:

- `/Users/davidwegener/Desktop/WohnWagenApp/CamperReady/Shared/UI/AppTheme.swift`
- `/Users/davidwegener/Desktop/WohnWagenApp/CamperReady/Features/Home/HomeDashboardView.swift`
- `/Users/davidwegener/Desktop/WohnWagenApp/CamperReady/Features/Weight/WeightView.swift`
- `/Users/davidwegener/Desktop/WohnWagenApp/CamperReady/Features/Checklists/ChecklistsView.swift`
- `/Users/davidwegener/Desktop/WohnWagenApp/CamperReady/Features/Logbook/LogbookView.swift`
- `/Users/davidwegener/Desktop/WohnWagenApp/CamperReady/Features/Costs/CostsView.swift`

## Next Step Once MCP Works

When Figma MCP is available again:

1. create file `CamperReady MVP v1`
2. create the pages listed above
3. create local variables from the token JSON
4. build the components page first
5. build `Home / Blocked` as the master visual direction
6. derive the remaining frames from components and variants
