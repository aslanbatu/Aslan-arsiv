import SwiftUI
import PDFKit

struct DocumentDetailView: View {
    @EnvironmentObject var store: ArchiveStore
    @Environment(\.dismiss) private var dismiss
    let document: ArchiveDocument
    @State private var showRename = false
    @State private var showDelete = false
    @State private var name = ""
    @State private var showShare = false

    var body: some View {
        NavigationStack {
            PDFViewRepresentable(url: store.documentURL(document))
                .background(Color.black)
                .navigationTitle(document.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button { store.toggleFavorite(document) } label: {
                            Image(systemName: document.isFavorite ? "star.fill" : "star")
                                .foregroundStyle(Color.aslanGold)
                        }
                        ShareLink(item: store.documentURL(document)) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        Menu {
                            Button("Yeniden adlandır") { name = document.name; showRename = true }
                            Button("Sil", role: .destructive) { showDelete = true }
                        } label: { Image(systemName: "ellipsis.circle") }
                    }
                }
                .alert("Belgeyi Sil", isPresented: $showDelete) {
                    Button("Sil", role: .destructive) { store.deleteDocument(document); dismiss() }
                    Button("İptal", role: .cancel) {}
                } message: { Text("Bu belge arşivden kalıcı olarak silinecek.") }
                .sheet(isPresented: $showRename) {
                    RenameView(title: "Belge adını değiştir", name: $name) {
                        store.renameDocument(document, to: name)
                    }
                }
        }
        .preferredColorScheme(.dark)
    }
}

struct PDFViewRepresentable: UIViewRepresentable {
    let url: URL
    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.backgroundColor = .black
        view.document = PDFDocument(url: url)
        return view
    }
    func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document?.documentURL != url { uiView.document = PDFDocument(url: url) }
    }
}
