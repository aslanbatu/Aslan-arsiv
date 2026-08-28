import Foundation
import SwiftUI
import UIKit

@MainActor
final class ArchiveStore: ObservableObject {
    @Published private(set) var data: ArchiveData
    private let fm = FileManager.default
    private let dataURL: URL
    private let filesURL: URL

    init() {
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        dataURL = base.appendingPathComponent("archive.json")
        filesURL = base.appendingPathComponent("Belgeler", isDirectory: true)
        try? fm.createDirectory(at: base, withIntermediateDirectories: true)
        try? fm.createDirectory(at: filesURL, withIntermediateDirectories: true)

        if let raw = try? Data(contentsOf: dataURL), let decoded = try? JSONDecoder().decode(ArchiveData.self, from: raw) {
            data = decoded
        } else {
            data = ArchiveData(folders: Self.defaultFolders(), documents: [])
            save()
        }
    }

    static func defaultFolders() -> [ArchiveFolder] {
        [
            ArchiveFolder(name: "Kişisel", parentID: nil, icon: "person.crop.circle.fill"),
            ArchiveFolder(name: "Kimlik Belgeleri", parentID: nil, icon: "person.text.rectangle.fill"),
            ArchiveFolder(name: "Ev", parentID: nil, icon: "house.fill"),
            ArchiveFolder(name: "Araba", parentID: nil, icon: "car.fill"),
            ArchiveFolder(name: "Sigorta", parentID: nil, icon: "shield.fill"),
            ArchiveFolder(name: "Finans", parentID: nil, icon: "creditcard.fill"),
            ArchiveFolder(name: "Sözleşmeler", parentID: nil, icon: "doc.text.fill"),
            ArchiveFolder(name: "Garanti", parentID: nil, icon: "shippingbox.fill"),
            ArchiveFolder(name: "Seyahat", parentID: nil, icon: "airplane"),
            ArchiveFolder(name: "Diğer", parentID: nil, icon: "folder.fill")
        ]
    }

    var allFolders: [FolderPickerItem] {
        func build(_ parent: UUID?, prefix: String) -> [FolderPickerItem] {
            storeFolders(parentID: parent).flatMap { folder in
                let path = prefix.isEmpty ? folder.name : "\(prefix) › \(folder.name)"
                return [FolderPickerItem(id: folder.id, path: path)] + build(folder.id, prefix: path)
            }
        }
        return build(nil, prefix: "")
    }

    private func storeFolders(parentID: UUID?) -> [ArchiveFolder] { data.folders.filter { $0.parentID == parentID }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending } }

    func folders(parentID: UUID? = nil) -> [ArchiveFolder] {
        data.folders
            .filter { $0.parentID == parentID }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func folder(_ id: UUID) -> ArchiveFolder? { data.folders.first { $0.id == id } }

    var recentDocuments: [ArchiveDocument] { data.documents.sorted { $0.createdAt > $1.createdAt } }

    var favoriteDocuments: [ArchiveDocument] { data.documents.filter(\.isFavorite).sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending } }

    func totalDocuments(in folderID: UUID) -> Int {
        let ids = descendantIDs(of: folderID) + [folderID]
        return data.documents.filter { ids.contains($0.folderID) }.count
    }

    func cleanupMissingFiles() {
        data.documents.removeAll { !fm.fileExists(atPath: documentURL($0).path) }
        save()
    }

    func documents(in folderID: UUID) -> [ArchiveDocument] {
        data.documents
            .filter { $0.folderID == folderID }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func search(_ query: String) -> [ArchiveDocument] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }
        return data.documents.filter { document in
            document.name.localizedCaseInsensitiveContains(q) ||
            document.fileName.localizedCaseInsensitiveContains(q) ||
            folderPath(for: document.folderID).localizedCaseInsensitiveContains(q)
        }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func addFolder(name: String, parentID: UUID? = nil, icon: String = "folder.fill") {
        let clean = cleanName(name)
        guard !clean.isEmpty else { return }
        data.folders.append(ArchiveFolder(name: clean, parentID: parentID, icon: icon))
        save()
    }

    func renameFolder(_ id: UUID, to name: String) {
        guard let i = data.folders.firstIndex(where: { $0.id == id }) else { return }
        let clean = cleanName(name)
        guard !clean.isEmpty else { return }
        data.folders[i].name = clean
        save()
    }

    func deleteFolder(_ id: UUID) {
        let ids = descendantIDs(of: id) + [id]
        let docs = data.documents.filter { ids.contains($0.folderID) }
        for doc in docs { try? fm.removeItem(at: documentURL(doc)) }
        data.documents.removeAll { ids.contains($0.folderID) }
        data.folders.removeAll { ids.contains($0.id) }
        save()
    }

    @discardableResult
    func importPDF(data incoming: Data, name: String, folderID: UUID) throws -> ArchiveDocument {
        let clean = cleanName(name.isEmpty ? "Yeni Belge" : name)
        let fileName = uniqueFileName(base: clean, ext: "pdf")
        let destination = filesURL.appendingPathComponent(fileName)
        try incoming.write(to: destination, options: .atomic)
        let document = ArchiveDocument(name: clean, folderID: folderID, fileName: fileName)
        data.documents.append(document)
        save()
        return document
    }

    @discardableResult
    func importFile(from sourceURL: URL, name: String? = nil, folderID: UUID) throws -> ArchiveDocument {
        let accessed = sourceURL.startAccessingSecurityScopedResource()
        defer { if accessed { sourceURL.stopAccessingSecurityScopedResource() } }

        let ext = sourceURL.pathExtension.lowercased()
        let originalName = sourceURL.deletingPathExtension().lastPathComponent
        let clean = cleanName((name?.isEmpty == false ? name! : originalName).isEmpty ? "Yeni Belge" : (name?.isEmpty == false ? name! : originalName))

        if ext == "pdf" {
            let incoming = try Data(contentsOf: sourceURL)
            return try importPDF(data: incoming, name: clean, folderID: folderID)
        }

        guard let image = UIImage(contentsOfFile: sourceURL.path), let pdfData = PDFBuilder.pdfData(images: [image]) else {
            throw ArchiveError.unsupportedFile
        }
        return try importPDF(data: pdfData, name: clean, folderID: folderID)
    }

    @discardableResult
    func importImages(_ images: [UIImage], name: String, folderID: UUID) throws -> ArchiveDocument {
        guard !images.isEmpty, let pdfData = PDFBuilder.pdfData(images: images) else { throw ArchiveError.pdfCreationFailed }
        return try importPDF(data: pdfData, name: name, folderID: folderID)
    }

    func documentURL(_ document: ArchiveDocument) -> URL { filesURL.appendingPathComponent(document.fileName) }

    func toggleFavorite(_ document: ArchiveDocument) {
        guard let i = data.documents.firstIndex(where: { $0.id == document.id }) else { return }
        data.documents[i].isFavorite.toggle()
        save()
    }

    func renameDocument(_ document: ArchiveDocument, to name: String) {
        guard let i = data.documents.firstIndex(where: { $0.id == document.id }) else { return }
        let clean = cleanName(name)
        guard !clean.isEmpty else { return }
        data.documents[i].name = clean
        save()
    }

    func moveDocument(_ document: ArchiveDocument, to folderID: UUID) {
        guard let i = data.documents.firstIndex(where: { $0.id == document.id }), folder(folderID) != nil else { return }
        data.documents[i].folderID = folderID
        save()
    }

    func deleteDocument(_ document: ArchiveDocument) {
        try? fm.removeItem(at: documentURL(document))
        data.documents.removeAll { $0.id == document.id }
        save()
    }

    func folderPath(for folderID: UUID) -> String {
        var names: [String] = []
        var current = folderID
        var safety = 0
        while safety < 100, let f = folder(current) {
            names.append(f.name)
            guard let parent = f.parentID else { break }
            current = parent
            safety += 1
        }
        return names.reversed().joined(separator: " → ")
    }

    private func descendantIDs(of id: UUID) -> [UUID] {
        let children = data.folders.filter { $0.parentID == id }.map(\.id)
        return children + children.flatMap(descendantIDs)
    }

    private func uniqueFileName(base: String, ext: String) -> String {
        var candidate = "\(base).\(ext)"
        var n = 2
        while fm.fileExists(atPath: filesURL.appendingPathComponent(candidate).path) {
            candidate = "\(base) (\(n)).\(ext)"
            n += 1
        }
        return candidate
    }

    private func cleanName(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: "\\", with: "-")
    }

    private func save() {
        if let encoded = try? JSONEncoder().encode(data) {
            try? encoded.write(to: dataURL, options: .atomic)
        }
        objectWillChange.send()
    }
}

struct FolderPickerItem: Identifiable { let id: UUID; let path: String }

enum ArchiveError: LocalizedError {
    case unsupportedFile
    case pdfCreationFailed
    var errorDescription: String? {
        switch self {
        case .unsupportedFile: return "Bu dosya türü desteklenmiyor."
        case .pdfCreationFailed: return "PDF oluşturulamadı."
        }
    }
}

