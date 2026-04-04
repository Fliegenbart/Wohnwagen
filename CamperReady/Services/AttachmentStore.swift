import Foundation

enum AttachmentStoreError: LocalizedError {
    case invalidPath
    case couldNotReadImportedFile

    var errorDescription: String? {
        switch self {
        case .invalidPath:
            "Der gespeicherte Dateipfad ist ungültig."
        case .couldNotReadImportedFile:
            "Die ausgewählte Datei konnte nicht gelesen werden."
        }
    }
}

struct AttachmentDescriptor: Equatable {
    let storedPath: String
    let fileName: String
}

final class AttachmentStore {
    let rootDirectory: URL

    init(rootDirectory: URL = AttachmentStore.defaultRootDirectory()) {
        self.rootDirectory = rootDirectory
    }

    func importFile(from sourceURL: URL, preferredFileName: String? = nil) throws -> String {
        try ensureRootDirectory()

        let didAccess = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        guard FileManager.default.fileExists(atPath: sourceURL.path) else {
            throw AttachmentStoreError.couldNotReadImportedFile
        }

        let destination = uniqueDestinationURL(preferredFileName: preferredFileName ?? sourceURL.lastPathComponent)
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.copyItem(at: sourceURL, to: destination)
        try applyProtection(to: destination)
        return destination.lastPathComponent
    }

    func importData(_ data: Data, fileName: String) throws -> String {
        try ensureRootDirectory()
        let destination = uniqueDestinationURL(preferredFileName: fileName)
        try data.write(to: destination, options: .atomic)
        try applyProtection(to: destination)
        return destination.lastPathComponent
    }

    func replaceAttachment(currentPath: String?, withFileAt sourceURL: URL, preferredFileName: String? = nil) throws -> String {
        let imported = try importFile(from: sourceURL, preferredFileName: preferredFileName)
        if let currentPath {
            try deleteAttachment(at: currentPath)
        }
        return imported
    }

    func replaceAttachment(currentPath: String?, with data: Data, fileName: String) throws -> String {
        let imported = try importData(data, fileName: fileName)
        if let currentPath {
            try deleteAttachment(at: currentPath)
        }
        return imported
    }

    func url(for storedPath: String?) -> URL? {
        guard let storedPath, storedPath.isEmpty == false else { return nil }
        return rootDirectory.appendingPathComponent(storedPath)
    }

    func descriptor(for storedPath: String?) -> AttachmentDescriptor? {
        guard let storedPath, let url = url(for: storedPath) else { return nil }
        return AttachmentDescriptor(storedPath: storedPath, fileName: url.lastPathComponent)
    }

    func deleteAttachment(at storedPath: String?) throws {
        guard let url = url(for: storedPath) else { return }
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }

    private func ensureRootDirectory() throws {
        try FileManager.default.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
    }

    private func uniqueDestinationURL(preferredFileName: String) -> URL {
        let safeName = sanitizedFileName(preferredFileName)
        let stem = URL(fileURLWithPath: safeName).deletingPathExtension().lastPathComponent
        let ext = URL(fileURLWithPath: safeName).pathExtension
        let suffix = UUID().uuidString.prefix(8)
        let fileName = ext.isEmpty ? "\(stem)-\(suffix)" : "\(stem)-\(suffix).\(ext)"
        return rootDirectory.appendingPathComponent(fileName)
    }

    private func sanitizedFileName(_ input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleaned = trimmed
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        return cleaned.isEmpty ? "anhang" : cleaned
    }

    private func applyProtection(to url: URL) throws {
        try FileManager.default.setAttributes(
            [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
            ofItemAtPath: url.path
        )
    }

    static func defaultRootDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("CamperReady/Attachments", isDirectory: true)
    }
}
