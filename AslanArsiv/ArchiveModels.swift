import Foundation

struct ArchiveFolder: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
    var parentID: UUID?
    var icon: String
    var createdAt: Date = .now
}

struct ArchiveDocument: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
    var folderID: UUID
    var fileName: String
    var createdAt: Date = .now
    var isFavorite: Bool = false
}

struct ArchiveData: Codable {
    var folders: [ArchiveFolder] = []
    var documents: [ArchiveDocument] = []
}
