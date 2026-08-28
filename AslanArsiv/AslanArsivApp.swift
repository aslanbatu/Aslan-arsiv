import SwiftUI

@main
struct AslanArsivApp: App {
    @StateObject private var store = ArchiveStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
        }
    }
}
