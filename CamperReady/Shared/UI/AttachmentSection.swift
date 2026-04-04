import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct AttachmentSection: View {
    @Binding var storedPath: String?

    let title: String
    let helperText: String

    @State private var isImportingFile = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var errorMessage: String?

    private let attachmentStore = AttachmentStore()

    init(storedPath: Binding<String?>, title: String = "Anhang", helperText: String) {
        self._storedPath = storedPath
        self.title = title
        self.helperText = helperText
    }

    var body: some View {
        Section {
            if let descriptor = attachmentStore.descriptor(for: storedPath) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(descriptor.fileName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.ink)
                        .lineLimit(2)

                    HStack(spacing: 12) {
                        if let url = attachmentStore.url(for: descriptor.storedPath) {
                            ShareLink(item: url) {
                                Label("Teilen", systemImage: "square.and.arrow.up")
                            }
                        }

                        Button(role: .destructive) {
                            removeAttachment()
                        } label: {
                            Label("Entfernen", systemImage: "trash")
                        }
                    }
                }
            }

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Label(storedPath == nil ? "Foto auswählen" : "Foto ersetzen", systemImage: "photo")
            }

            Button {
                isImportingFile = true
            } label: {
                Label(storedPath == nil ? "Datei auswählen" : "Datei ersetzen", systemImage: "paperclip")
            }
        } header: {
            Text(title)
        } footer: {
            Text(helperText)
        }
        .fileImporter(isPresented: $isImportingFile, allowedContentTypes: [.item]) { result in
            switch result {
            case .success(let url):
                importFile(from: url)
            case .failure:
                errorMessage = "Die Datei konnte nicht importiert werden."
            }
        }
        .onChange(of: selectedPhoto) { _, newValue in
            guard let newValue else { return }
            Task {
                await importPhoto(from: newValue)
            }
        }
        .alert("Anhang konnte nicht gespeichert werden", isPresented: errorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Bitte versuche es noch einmal.")
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func importFile(from url: URL) {
        do {
            storedPath = try attachmentStore.replaceAttachment(currentPath: storedPath, withFileAt: url)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func importPhoto(from item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                errorMessage = "Das Foto konnte nicht gelesen werden."
                return
            }
            storedPath = try attachmentStore.replaceAttachment(currentPath: storedPath, with: data, fileName: "foto.jpg")
            selectedPhoto = nil
        } catch {
            errorMessage = "Das Foto konnte nicht gespeichert werden."
        }
    }

    private func removeAttachment() {
        do {
            try attachmentStore.deleteAttachment(at: storedPath)
            storedPath = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
