# CamperReady MVP

CamperReady is an iPhone-first, offline-first readiness cockpit for private camper owners in Germany, Austria, and Switzerland. The MVP answers one operational question fast: can I leave now?

## MVP in 10 bullets

- German-first 5-tab app shell: Home, Gewicht, Checklisten, Logbuch, Kosten
- Readiness cockpit with explainable traffic-light logic instead of a black-box score
- Vehicle profile that still works with incomplete setup data
- Honest weight calculator focused on reserve, risk patterns, and weighing recommendations
- Operational checklist modes for departure, storage, winterize, and more
- Maintenance ledger with next due dates and kilometer-based follow-ups
- Editable document and gas inspection tracking with reminder scaffolding
- Private place notes with MapKit visualization only for the owner's saved places
- Cost transparency for trips, nights, 100 km, and recurring fixed costs
- Local-only SwiftData persistence, local notifications scaffold, and PDF/CSV export scaffold

## Architecture

- SwiftUI + SwiftData, no backend, no account system
- Feature folders for UI flows, small service layer for seeding/export/notifications, and a pure readiness engine in the domain layer
- Views stay mostly declarative; cross-feature computations live in `AppDataLocator` and `ReadinessEngine`
- The readiness engine is intentionally explainable: each dimension returns status, summary, reasons, and a recommended next action

## SwiftData schema

The app stores:

- `VehicleProfile`
- `Trip`
- `PackingItem`
- `PassengerLoad`
- `TripLoadSettings`
- `ChecklistRun`
- `ChecklistItemRecord`
- `MaintenanceEntry`
- `DocumentRecord`
- `PlaceNote`
- `CostEntry`

The models use UUID links instead of complex object graphs to keep the starter implementation simple, local-first, and easy to evolve.

## Feature folders

- `CamperReady/App`: app entry point, tabs, bootstrap
- `CamperReady/Domain/Models`: enums and SwiftData models
- `CamperReady/Domain/Readiness`: pure readiness logic
- `CamperReady/Services`: seeding, export, notifications, checklist templates, data lookup helpers
- `CamperReady/Shared/UI`: reusable status and metric components
- `CamperReady/Features/Home`
- `CamperReady/Features/Vehicle`
- `CamperReady/Features/Weight`
- `CamperReady/Features/Checklists`
- `CamperReady/Features/Logbook`
- `CamperReady/Features/Costs`
- `CamperReadyTests`: unit-testable readiness checks

## Assumptions

- iOS 17+ is acceptable and portrait-first on iPhone is enough for the starter MVP
- One primary vehicle is the MVP default even though the schema could later support multiple vehicles
- A simple form-based vehicle editor is sufficient for V1 onboarding depth
- Attachments are modeled as local file path placeholders for now; a full picker/import flow can be added next
- Document presets remain editable data records rather than fixed legal truth
- Weight results stay conservative whenever essential values are missing
- Cost exports and dashboard PDF are starter scaffolds, not finalized report templates

## Build

1. Run `ruby Scripts/generate_xcodeproj.rb`
2. Open `CamperReady.xcodeproj` in Xcode
3. Build the `CamperReady` scheme for an iPhone simulator running iOS 17 or later

In `DEBUG` builds the app seeds realistic German sample data on first launch so the dashboard is useful immediately.

For a production-ready rollout, sample data should stay disabled by default. See:

- `Docs/App-Store-Launch-Checklist.md`
- `Docs/App-Store-Metadata.md`
