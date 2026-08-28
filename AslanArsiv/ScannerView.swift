import SwiftUI
import VisionKit
import UIKit

struct ScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: ArchiveStore
    @State private var scannedPDF: Data?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if let pdf = scannedPDF {
                    SaveScannedDocumentView(pdf: pdf) { dismiss() }
                } else if VNDocumentCameraViewController.isSupported {
                    DocumentScannerRepresentable { result in
                        switch result {
                        case .success(let data): scannedPDF = data
                        case .failure(let error): errorMessage = error.localizedDescription
                        }
                    }
                    .ignoresSafeArea()
                } else {
                    ContentUnavailableView("Tarayıcı kullanılamıyor", systemImage: "camera.metering.unknown", description: Text("Bu iPhone belge taramasını desteklemiyor."))
                }
            }
            .navigationTitle("Belge Tara")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Tarama Hatası", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("Tamam", role: .cancel) {}
            } message: { Text(errorMessage ?? "Bilinmeyen hata") }
        }
    }
}

struct SaveScannedDocumentView: View {
    @EnvironmentObject var store: ArchiveStore
    let pdf: Data
    let done: () -> Void
    @State private var name = "Yeni Belge"
    @State private var folderID: UUID?
    @State private var errorMessage: String?
    @State private var saving = false

    var body: some View {
        Form {
            Section("Belge") {
                Text("Tarama hazır. Belge adını ve klasörünü siz belirleyebilirsiniz.").font(.caption).foregroundStyle(.secondary)
                TextField("Belge adı", text: $name)
                    .textInputAutocapitalization(.sentences)
            }
            Section("Klasör") {
                Picker("Klasör seç", selection: $folderID) {
                    Text("Klasör seçin").tag(Optional<UUID>.none)
                    ForEach(store.allFolders) { folder in
                        Text(folder.path).tag(Optional(folder.id))
                    }
                }
            }
            Section {
                Button {
                    save()
                } label: {
                    HStack {
                        Spacer()
                        if saving { ProgressView() } else { Text("PDF'yi Kaydet").fontWeight(.semibold) }
                        Spacer()
                    }
                }
                .disabled(folderID == nil || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || saving)
            }
        }
        .navigationTitle("Belgeyi Kaydet")
        .onAppear { if folderID == nil { folderID = store.folders().first?.id } }
        .alert("Kaydetme Hatası", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("Tamam", role: .cancel) {}
        } message: { Text(errorMessage ?? "Bilinmeyen hata") }
    }

    private func save() {
        guard let folderID else { return }
        saving = true
        do {
            _ = try store.importPDF(data: pdf, name: name, folderID: folderID)
            done()
        } catch { errorMessage = error.localizedDescription }
        saving = false
    }
}

struct DocumentScannerRepresentable: UIViewControllerRepresentable {
    let completion: (Result<Data, Error>) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(completion: completion) }
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let vc = VNDocumentCameraViewController()
        vc.delegate = context.coordinator
        return vc
    }
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let completion: (Result<Data, Error>) -> Void
        init(completion: @escaping (Result<Data, Error>) -> Void) { self.completion = completion }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true)
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            controller.dismiss(animated: true) { self.completion(.failure(error)) }
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            var images: [UIImage] = []
            images.reserveCapacity(scan.pageCount)
            for index in 0..<scan.pageCount {
                images.append(scan.imageOfPage(at: index))
            }
            guard let pdf = PDFBuilder.pdfData(images: images) else {
                controller.dismiss(animated: true) { self.completion(.failure(ArchiveError.pdfCreationFailed)) }
                return
            }
            controller.dismiss(animated: true) { self.completion(.success(pdf)) }
        }
    }
}
