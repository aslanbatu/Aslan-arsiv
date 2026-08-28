import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Güvenlik") {
                    Label("Face ID", systemImage: "faceid")
                    Label("Uygulama kilidi", systemImage: "lock.fill")
                }
                Section("Arşiv") {
                    Label("Yedekleme", systemImage: "icloud")
                    Label("Çöp Kutusu", systemImage: "trash")
                }
                Section("Hakkında") {
                    VStack(alignment: .leading, spacing: 8) {
                        Image("LionLogo").resizable().scaledToFit().frame(width: 70, height: 70).clipShape(RoundedRectangle(cornerRadius: 18))
                        Text("ASLAN ARŞİV").font(.headline).foregroundStyle(Color.aslanGold)
                        Text("Bu uygulama Batuhan Aslan tarafından oluşturulup geliştirilmiştir.").font(.subheadline).foregroundStyle(.secondary)
                        Text("Sürüm 1.1").font(.caption).foregroundStyle(.secondary)
                    }.padding(.vertical, 6)
                }
            }
            .navigationTitle("Ayarlar")
        }
        .preferredColorScheme(.dark)
    }
}
