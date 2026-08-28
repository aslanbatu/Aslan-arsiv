import SwiftUI
import UniformTypeIdentifiers
import PhotosUI

struct RootView: View {
    @EnvironmentObject private var store: ArchiveStore
    @State private var search = ""
    @State private var showScanner = false
    @State private var showImporter = false
    @State private var showPhotoPicker = false
    @State private var showNewFolder = false
    @State private var selectedFolder: ArchiveFolder?
    @State private var selectedDocument: ArchiveDocument?
    @State private var showSettings = false
    @State private var showAddMenu = false
    @State private var selectedTab = 0
    @State private var importURL: URL?

    var body: some View {
        TabView(selection: $selectedTab) {
            home.tabItem { Label("Ana Sayfa", systemImage: "house.fill") }.tag(0)
            searchPage.tabItem { Label("Ara", systemImage: "magnifyingglass") }.tag(1)
            favoritesPage.tabItem { Label("Favoriler", systemImage: "star.fill") }.tag(2)
            SettingsView().tabItem { Label("Ayarlar", systemImage: "gearshape.fill") }.tag(3)
        }
        .tint(.aslanGold)
        .preferredColorScheme(.dark)
        .sheet(item: $selectedFolder) { FolderView(folder: $0) }
        .sheet(item: $selectedDocument) { DocumentDetailView(document: $0) }
        .sheet(isPresented: $showScanner) { ScannerView() }
        .sheet(isPresented: $showNewFolder) { NewFolderView(parentID: nil) }
        .sheet(isPresented: $showPhotoPicker) { PhotoImportView() }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.pdf, .image], allowsMultipleSelection: false) { result in
            if case .success(let urls) = result { importURL = urls.first }
        }
        .sheet(item: Binding(get: { importURL.map(ImportURLBox.init) }, set: { importURL = $0?.url })) { box in
            ImportDocumentView(sourceURL: box.url)
        }
        .onAppear { store.cleanupMissingFiles() }
    }

    private var home: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Color.aslanBackground.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        header
                        quickSearch
                        overview
                        folderGrid
                        recentSection
                    }
                    .padding(.horizontal, 18).padding(.top, 10).padding(.bottom, 105)
                }
                addButton
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var searchPage: some View {
        NavigationStack {
            ZStack { Color.aslanBackground.ignoresSafeArea();
                VStack(alignment: .leading, spacing: 14) {
                    Text("Arama").font(.largeTitle.bold()).padding(.horizontal, 18)
                    searchField
                    if search.isEmpty {
                        ContentUnavailableView("Belge ara", systemImage: "magnifyingglass", description: Text("Belge adını yazarak tüm arşivde arayın."))
                    } else {
                        let results = store.search(search)
                        if results.isEmpty { ContentUnavailableView("Belge bulunamadı", systemImage: "doc.text.magnifyingglass", description: Text("Farklı bir belge adı deneyin.")) }
                        else { ScrollView { LazyVStack(spacing: 10) { ForEach(results) { doc in DocumentRow(document: doc) { selectedDocument = doc } } }.padding(18) } }
                    }
                }.padding(.top, 12)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var favoritesPage: some View {
        NavigationStack {
            ZStack { Color.aslanBackground.ignoresSafeArea();
                ScrollView { LazyVStack(spacing: 10) {
                    if store.favoriteDocuments.isEmpty { ContentUnavailableView("Favori yok", systemImage: "star", description: Text("Belgeleri favorilere eklediğinizde burada görünür.")) }
                    else { ForEach(store.favoriteDocuments) { doc in DocumentRow(document: doc) { selectedDocument = doc } } }
                }.padding(18) }
            }.navigationTitle("Favoriler")
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image("LionLogo").resizable().scaledToFill().frame(width: 48, height: 48).clipShape(RoundedRectangle(cornerRadius: 15))
            VStack(alignment: .leading, spacing: 2) { Text("ASLAN ARŞİV").font(.system(size: 22, weight: .bold, design: .rounded)); Text("Kişisel belge arşivin").font(.caption).foregroundStyle(.secondary) }
            Spacer()
        }
    }

    private var quickSearch: some View { Button { selectedTab = 1 } label: { searchField }.buttonStyle(.plain) }
    private var searchField: some View { HStack(spacing: 10) { Image(systemName: "magnifyingglass"); TextField("Belgelerde ara...", text: $search).textInputAutocapitalization(.never).autocorrectionDisabled(); if !search.isEmpty { Button { search = "" } label: { Image(systemName: "xmark.circle.fill") }.buttonStyle(.plain) } }.padding(14).background(Color.aslanCard).clipShape(RoundedRectangle(cornerRadius: 16)).foregroundStyle(.secondary) }

    private var overview: some View {
        HStack(spacing: 12) {
            StatCard(title: "Belge", value: "\(store.data.documents.count)", icon: "doc.fill")
            StatCard(title: "Klasör", value: "\(store.data.folders.count)", icon: "folder.fill")
        }
    }

    private var folderGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack { Text("Klasörlerim").font(.headline); Spacer(); Button("Yeni klasör") { showNewFolder = true }.foregroundStyle(.aslanGold).font(.subheadline.weight(.semibold)) }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) { ForEach(store.folders()) { folder in FolderCard(folder: folder) { selectedFolder = folder } } }
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Son eklenenler").font(.headline)
            ForEach(store.recentDocuments.prefix(5)) { doc in DocumentRow(document: doc) { selectedDocument = doc } }
        }
    }

    private var addButton: some View {
        Menu {
            Button { showScanner = true } label: { Label("Kamera ile Tara", systemImage: "camera.viewfinder") }
            Button { showPhotoPicker = true } label: { Label("Fotoğraflardan Ekle", systemImage: "photo") }
            Button { showImporter = true } label: { Label("Dosyalardan Ekle", systemImage: "folder.badge.plus") }
            Divider()
            Button { showNewFolder = true } label: { Label("Yeni Klasör", systemImage: "folder.badge.plus") }
        } label: { Image(systemName: "plus").font(.title2.weight(.bold)).foregroundStyle(.black).frame(width: 62, height: 62).background(LinearGradient(colors: [.aslanGold, Color(red: 0.98, green: 0.82, blue: 0.48)], startPoint: .topLeading, endPoint: .bottomTrailing)).clipShape(Circle()).shadow(color: .black.opacity(0.5), radius: 14, y: 8) }.padding(.trailing, 22).padding(.bottom, 24)
    }
}

struct StatCard: View { let title: String; let value: String; let icon: String; var body: some View { HStack { Image(systemName: icon).foregroundStyle(.aslanGold); VStack(alignment: .leading) { Text(value).font(.title3.bold()); Text(title).font(.caption).foregroundStyle(.secondary) }; Spacer() }.padding(14).background(Color.aslanCard).clipShape(RoundedRectangle(cornerRadius: 16)) } }

struct FolderCard: View {
    @EnvironmentObject var store: ArchiveStore; let folder: ArchiveFolder; let action: () -> Void
    @State private var showRename = false; @State private var name = ""; @State private var showDelete = false
    var body: some View { Button(action: action) { VStack(alignment: .leading, spacing: 8) { Image(systemName: folder.icon).font(.title2).foregroundStyle(.aslanGold); Text(folder.name).font(.subheadline.weight(.semibold)).foregroundStyle(.white).lineLimit(1); Text("\(store.totalDocuments(in: folder.id)) belge").font(.caption).foregroundStyle(.secondary) }.frame(maxWidth: .infinity, minHeight: 104, alignment: .leading).padding(15).background(Color.aslanCard).clipShape(RoundedRectangle(cornerRadius: 18)).overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.aslanGold.opacity(0.08))) }.contextMenu { Button("Yeniden adlandır") { name = folder.name; showRename = true }; Button("Sil", role: .destructive) { showDelete = true } }.sheet(isPresented: $showRename) { RenameView(title: "Klasör adını değiştir", name: $name) { store.renameFolder(folder.id, to: name) } }.alert("Klasörü sil?", isPresented: $showDelete) { Button("Sil", role: .destructive) { store.deleteFolder(folder.id) }; Button("İptal", role: .cancel) {} } message: { Text("Bu klasördeki alt klasörler ve belgeler de silinecek.") } }
}

struct DocumentRow: View {
    @EnvironmentObject var store: ArchiveStore; let document: ArchiveDocument; let action: () -> Void
    var body: some View { Button(action: action) { HStack(spacing: 12) { Image(systemName: "doc.richtext.fill").foregroundStyle(.aslanGold).font(.title3); VStack(alignment: .leading, spacing: 4) { Text(document.name).foregroundStyle(.white).font(.subheadline.weight(.semibold)).lineLimit(2); Text(store.folderPath(for: document.folderID)).font(.caption).foregroundStyle(.secondary).lineLimit(1) }; Spacer(); if document.isFavorite { Image(systemName: "star.fill").foregroundStyle(.aslanGold) } }.padding(14).background(Color.aslanCard).clipShape(RoundedRectangle(cornerRadius: 15)) }.buttonStyle(.plain) }
}

struct ImportURLBox: Identifiable { let id = UUID(); let url: URL }

struct ImportDocumentView: View {
    @EnvironmentObject var store: ArchiveStore
    @Environment(\.dismiss) private var dismiss
    let sourceURL: URL
    @State private var name = ""
    @State private var folderID: UUID?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Belge") { TextField("Belge adı", text: $name) }
                Section("Klasör") {
                    Picker("Klasör seç", selection: $folderID) {
                        ForEach(store.allFolders) { folder in
                            Text(folder.path).tag(Optional(folder.id))
                        }
                    }
                }
                Section { Button("Arşive Kaydet") { save() }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || folderID == nil) }
            }
            .navigationTitle("Belgeyi Ekle")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("İptal") { dismiss() } } }
            .onAppear { name = sourceURL.deletingPathExtension().lastPathComponent; folderID = store.folders().first?.id }
            .alert("Hata", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) { Button("Tamam", role: .cancel) {} } message: { Text(errorMessage ?? "") }
        }
        .preferredColorScheme(.dark)
    }

    private func save() {
        guard let folderID else { return }
        do { _ = try store.importFile(from: sourceURL, name: name, folderID: folderID); dismiss() }
        catch { errorMessage = error.localizedDescription }
    }
}

struct PhotoImportView: View {
    @EnvironmentObject var store: ArchiveStore
    @Environment(\.dismiss) private var dismiss
    @State private var items: [PhotosPickerItem] = []
    @State private var name = "Yeni Belge"
    @State private var folderID: UUID?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Fotoğraflar") {
                    PhotosPicker(selection: $items, maxSelectionCount: 20, matching: .images) { Label("Fotoğraf seç", systemImage: "photo.on.rectangle") }
                    Text("Seçilen fotoğraflar tek bir PDF olarak kaydedilir.").font(.caption).foregroundStyle(.secondary)
                }
                Section("Belge adı") { TextField("Belge adı", text: $name) }
                Section("Klasör") { Picker("Klasör seç", selection: $folderID) { ForEach(store.allFolders) { Text($0.path).tag(Optional($0.id)) } } }
                Section { Button("PDF Oluştur ve Kaydet") { save() }.disabled(items.isEmpty || folderID == nil || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
            }
            .navigationTitle("Fotoğraflardan Ekle")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("İptal") { dismiss() } } }
            .onAppear { folderID = store.folders().first?.id }
            .alert("Hata", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) { Button("Tamam", role: .cancel) {} } message: { Text(errorMessage ?? "") }
        }.preferredColorScheme(.dark)
    }

    private func save() {
        guard let folderID else { return }
        Task {
            var images: [UIImage] = []
            for item in items { if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) { images.append(image) } }
            do { _ = try store.importImages(images, name: name, folderID: folderID); dismiss() } catch { errorMessage = error.localizedDescription }
        }
    }
}
