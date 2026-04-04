import SwiftData
import SwiftUI

private struct VehicleDraft {
    var name = ""
    var vehicleKind: VehicleKind = .motorhome
    var brand = ""
    var model = ""
    var licensePlate = ""
    var country: CountryPreset = .de
    var gvwrKg: Double = 3500
    var measuredEmptyWeightKg: Double = 0
    var freshWaterCapacityL: Double = 100
    var greyWaterCapacityL: Double = 110
    var gasBottleCount: Int = 0
    var gasBottleSizeKg: Double = 11
    var serviceIntervalMonths: Int = 12
    var serviceIntervalKm: Int = 20000
    var notes = ""

    init() {}

    init(vehicle: VehicleProfile) {
        name = vehicle.name
        vehicleKind = vehicle.vehicleKind
        brand = vehicle.brand
        model = vehicle.model
        licensePlate = vehicle.licensePlate
        country = vehicle.country
        gvwrKg = vehicle.gvwrKg ?? 3500
        measuredEmptyWeightKg = vehicle.measuredEmptyWeightKg ?? 0
        freshWaterCapacityL = vehicle.freshWaterCapacityL ?? 100
        greyWaterCapacityL = vehicle.greyWaterCapacityL ?? 110
        gasBottleCount = vehicle.gasBottleCount ?? 0
        gasBottleSizeKg = vehicle.gasBottleSizeKg ?? 11
        serviceIntervalMonths = vehicle.serviceIntervalMonths ?? 12
        serviceIntervalKm = vehicle.serviceIntervalKm ?? 20000
        notes = vehicle.notes
    }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct VehicleProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let vehicle: VehicleProfile?

    @State private var draft: VehicleDraft

    init(vehicle: VehicleProfile?) {
        self.vehicle = vehicle
        _draft = State(initialValue: vehicle.map(VehicleDraft.init) ?? VehicleDraft())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Für den Start reicht ein Fahrzeugname. Alles andere kannst du auch später ergänzen.")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.mutedInk)
                }

                Section {
                    TextField("z. B. Unser Kastenwagen", text: nameBinding)
                    Picker("Typ", selection: vehicleKindBinding) {
                        ForEach(VehicleKind.allCases) { kind in
                            Text(kind.title).tag(kind)
                        }
                    }
                    TextField("z. B. Pössl", text: brandBinding)
                    TextField("z. B. Summit 600", text: modelBinding)
                    TextField("z. B. M-AB 1234", text: licensePlateBinding)
                    Picker("Land", selection: countryBinding) {
                        ForEach(CountryPreset.allCases) { country in
                            Text(country.title).tag(country)
                        }
                    }
                } header: {
                    Text("Für den Start")
                } footer: {
                    Text("Wenn du etwas noch nicht weißt, ist das kein Problem. Du kannst es später ergänzen.")
                }

                Section {
                    TextField("zGG (kg)", value: gvwrBinding, format: .number)
                        .keyboardType(.decimalPad)
                    TextField("Leergewicht, gemessen (kg)", value: measuredWeightBinding, format: .number)
                        .keyboardType(.decimalPad)
                    TextField("Frischwasser (l)", value: freshWaterBinding, format: .number)
                        .keyboardType(.decimalPad)
                    TextField("Grauwasser (l)", value: greyWaterBinding, format: .number)
                        .keyboardType(.decimalPad)
                    Stepper("Gasflaschen: \(gasBottleCountBinding.wrappedValue)", value: gasBottleCountBinding, in: 0...4)
                    TextField("Flaschengröße (kg)", value: gasBottleSizeBinding, format: .number)
                        .keyboardType(.decimalPad)
                } header: {
                    Text("Gewicht, Wasser und Gas")
                } footer: {
                    Text("Trag nur die Werte ein, die du sicher kennst. Die App funktioniert auch mit unvollständigen Angaben.")
                }

                Section {
                    Stepper("Service alle \(serviceMonthsBinding.wrappedValue) Monate", value: serviceMonthsBinding, in: 0...36)
                    Stepper("Service alle \(serviceKmBinding.wrappedValue) km", value: serviceKmBinding, in: 0...60000, step: 1000)
                } header: {
                    Text("Service")
                } footer: {
                    Text("Wenn du keine festen Intervalle nutzt, kannst du diese Werte auch später anpassen.")
                }

                Section {
                    TextEditor(text: notesBinding)
                        .frame(minHeight: 120)
                } header: {
                    Text("Notizen")
                } footer: {
                    Text("Zum Beispiel Besonderheiten zu Gewicht, Gas oder wiederkehrenden Aufgaben.")
                }
            }
            .navigationTitle(vehicle == nil ? "Fahrzeug anlegen" : "Fahrzeugprofil")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(vehicle == nil ? "Anlegen" : "Fertig") {
                        saveVehicle()
                    }
                    .disabled(!draft.canSave)
                }
            }
        }
    }

    private var nameBinding: Binding<String> {
        binding(
            get: { draft.name },
            set: { draft.name = $0 }
        )
    }

    private var vehicleKindBinding: Binding<VehicleKind> {
        binding(
            get: { draft.vehicleKind },
            set: { draft.vehicleKind = $0 }
        )
    }

    private var brandBinding: Binding<String> {
        binding(
            get: { draft.brand },
            set: { draft.brand = $0 }
        )
    }

    private var modelBinding: Binding<String> {
        binding(
            get: { draft.model },
            set: { draft.model = $0 }
        )
    }

    private var licensePlateBinding: Binding<String> {
        binding(
            get: { draft.licensePlate },
            set: { draft.licensePlate = $0 }
        )
    }

    private var countryBinding: Binding<CountryPreset> {
        binding(
            get: { draft.country },
            set: { draft.country = $0 }
        )
    }

    private var gvwrBinding: Binding<Double> {
        binding(
            get: { draft.gvwrKg },
            set: { draft.gvwrKg = $0 }
        )
    }

    private var measuredWeightBinding: Binding<Double> {
        binding(
            get: { draft.measuredEmptyWeightKg },
            set: { draft.measuredEmptyWeightKg = $0 }
        )
    }

    private var freshWaterBinding: Binding<Double> {
        binding(
            get: { draft.freshWaterCapacityL },
            set: { draft.freshWaterCapacityL = $0 }
        )
    }

    private var greyWaterBinding: Binding<Double> {
        binding(
            get: { draft.greyWaterCapacityL },
            set: { draft.greyWaterCapacityL = $0 }
        )
    }

    private var gasBottleCountBinding: Binding<Int> {
        binding(
            get: { draft.gasBottleCount },
            set: { draft.gasBottleCount = $0 }
        )
    }

    private var gasBottleSizeBinding: Binding<Double> {
        binding(
            get: { draft.gasBottleSizeKg },
            set: { draft.gasBottleSizeKg = $0 }
        )
    }

    private var serviceMonthsBinding: Binding<Int> {
        binding(
            get: { draft.serviceIntervalMonths },
            set: { draft.serviceIntervalMonths = $0 }
        )
    }

    private var serviceKmBinding: Binding<Int> {
        binding(
            get: { draft.serviceIntervalKm },
            set: { draft.serviceIntervalKm = $0 }
        )
    }

    private var notesBinding: Binding<String> {
        binding(
            get: { draft.notes },
            set: { draft.notes = $0 }
        )
    }

    private func binding<T>(get: @escaping () -> T, set: @escaping (T) -> Void) -> Binding<T> {
        Binding(get: get, set: set)
    }

    private func saveVehicle() {
        guard draft.canSave else { return }

        if let vehicle {
            vehicle.name = draft.name
            vehicle.vehicleKind = draft.vehicleKind
            vehicle.brand = draft.brand
            vehicle.model = draft.model
            vehicle.licensePlate = draft.licensePlate
            vehicle.country = draft.country
            vehicle.gvwrKg = positiveOrNil(draft.gvwrKg)
            vehicle.measuredEmptyWeightKg = positiveOrNil(draft.measuredEmptyWeightKg)
            vehicle.freshWaterCapacityL = positiveOrNil(draft.freshWaterCapacityL)
            vehicle.greyWaterCapacityL = positiveOrNil(draft.greyWaterCapacityL)
            vehicle.gasBottleCount = draft.gasBottleCount == 0 ? nil : draft.gasBottleCount
            vehicle.gasBottleSizeKg = positiveOrNil(draft.gasBottleSizeKg)
            vehicle.serviceIntervalMonths = draft.serviceIntervalMonths == 0 ? nil : draft.serviceIntervalMonths
            vehicle.serviceIntervalKm = draft.serviceIntervalKm == 0 ? nil : draft.serviceIntervalKm
            vehicle.notes = draft.notes
            vehicle.updatedAt = .now
        } else {
            let newVehicle = VehicleProfile(
                name: draft.name,
                vehicleKind: draft.vehicleKind,
                brand: draft.brand,
                model: draft.model,
                licensePlate: draft.licensePlate,
                country: draft.country,
                gvwrKg: positiveOrNil(draft.gvwrKg),
                measuredEmptyWeightKg: positiveOrNil(draft.measuredEmptyWeightKg),
                freshWaterCapacityL: positiveOrNil(draft.freshWaterCapacityL),
                greyWaterCapacityL: positiveOrNil(draft.greyWaterCapacityL),
                gasBottleCount: draft.gasBottleCount == 0 ? nil : draft.gasBottleCount,
                gasBottleSizeKg: positiveOrNil(draft.gasBottleSizeKg),
                serviceIntervalMonths: draft.serviceIntervalMonths == 0 ? nil : draft.serviceIntervalMonths,
                serviceIntervalKm: draft.serviceIntervalKm == 0 ? nil : draft.serviceIntervalKm,
                notes: draft.notes
            )
            modelContext.insert(newVehicle)
        }

        try? modelContext.save()
        dismiss()
    }

    private func positiveOrNil(_ value: Double) -> Double? {
        value > 0 ? value : nil
    }
}
