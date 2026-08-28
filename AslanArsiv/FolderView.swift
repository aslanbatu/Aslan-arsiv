import SwiftUI
import UniformTypeIdentifiers

struct FolderView: View {
    @EnvironmentObject var store: ArchiveStore
    let folder: ArchiveFolder
    @Environment(\.dismiss) private var dismiss
    @State private var showRename = false
    @State private var showAddFolder = false
    @State private var showScanner = false
    @State private var showFileImporter = false
    @State private var selectedDocument: ArchiveDocument?
    @State private var name = ""
    @State private var importError: String?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Color.aslanBackground.ignoresSafeArea()
                List {
                    let children = store.folders(parentID: folder.id)
                    if !children.isEmpty {
                        Section("Alt klasörler") {
                            ForEach(children) { child in
                                NavigationLink { FolderView(folder: child) } label: {
                                    Label(child.name, systemImage: child.icon).foregroundStyle(.white)
                                }
                            }
                        }
                    }
                    Section("Belgeler") {
                        let docs = store.documents(in: folder.id)
                        if docs.isEmpty { Text("Bu klasörde henüz belge yok.").foregroundStyle(.secondary) }
                        ForEach(docs) { doc in
                            DocumentRow(document: doc) { selectedDocument = doc }
                                .listRowBackground(Color.clear)
                                .contextMenu {
                                    Button("Favoriye ekle") { store.toggleFavorite(doc) }
                                    Button("Sil", role: .destructive) { store.deleteDocument(doc) }
                                }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(folder.name)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Yeniden adlandır") { name = folder.name; showRename = true }
                        Button("Alt klasör ekle") { showAddFolder = true }
                        Button("Dosya ekle") { showFileImporter = true }
                        Button("Klasörü sil", role: .destructive) { store.deleteFolder(folder.id); dismiss() }
                    } label: { Image(systemName: "ellipsis.circle").foregroundStyle(Color.aslanGold) }
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Spacer()
                    Menu {
                        Button { showScanner = true } label: { Label("Kamera ile Tara", systemImage: "camera.viewfinder") }
                        Button { showFileImporter = true } label: { Label("Dosyalardan Ekle", systemImage: "folder.badge.plus") }
                    } label: {
                        Image(systemName: "plus").font(.title2.bold()).foregroundStyle(.black).frame(width: 58, height: 58).background(Color.aslanGold).clipShape(Circle())
                    }.padding()
                }.background(.ultraThinMaterial)
            }
            .sheet(isPresented: $showRename) { RenameView(title: "Klasör adını değiştir", name: $name) { store.renameFolder(folder.id, to: name) } }
            .sheet(isPresented: $showAddFolder) { NewFolderView(parentID: folder.id) }
            .sheet(isPresented: $showScanner) { ScannerView() }
            .sheet(item: $selectedDocument) { DocumentDetailView(document: $0) }
            .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.pdf, .image], allowsMultipleSelection: true) { result in
                switch result {
                case .failure(let error): importError = error.localizedDescription
                case .success(let urls):
                    do { for url in urls { _ = try store.importFile(from: url, folderID: folder.id) } }
                    catch { importError = error.localizedDescription }
                }
            }
            .alert("Dosya Eklenemedi", isPresented: Binding(get: { importError != nil }, set: { if !$0 { importError = nil } })) {
                Button("Tamam", role: .cancel) {}
            } message: { Text(importError ?? "Bilinmeyen hata") }
        }
        .preferredColorScheme(.dark)
    }
}

struct NewFolderView: View {
    @EnvironmentObject var store: ArchiveStore
    @Environment(\.dismiss) var dismiss
    let parentID: UUID?
    @State private var name = ""
    @State private var icon = "folder.fill"
    private let icons = ["folder.fill", "person.crop.circle.fill", "house.fill", "car.fill", "shield.fill", "creditcard.fill", "doc.text.fill", "airplane", "heart.fill", "star.fill"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Klasör adı") { TextField("Örn. Özel Belgeler", text: $name) }
                Section("Simge") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5)) {
                        ForEach(icons, id: \.self) { item in
                            Button { icon = item } label: {
                                Image(systemName: item).font(.title3).foregroundStyle(icon == item ? Color.aslanGold : .secondary).frame(maxWidth: .infinity).padding(.vertical, 10)
                            }
                        }
                    }
                }
            }
            .navigationTitle(parentID == nil ? "Yeni Klasör" : "Alt Klasör")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("İptal") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Oluştur") { store.addFolder(name: name, parentID: parentID, icon: icon); dismiss() }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
            }
        }.presentationDetents([.medium, .large]).preferredColorScheme(.dark)
    }
}

struct RenameView: View {
    let title: String
    @Binding var name: String
    let action: () -> Void
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            Form { TextField("Ad", text: $name) }
                .navigationTitle(title)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("İptal") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) { Button("Kaydet") { action(); dismiss() }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
                }
        }.presentationDetents([.medium]).preferredColorScheme(.dark)
    }
}
