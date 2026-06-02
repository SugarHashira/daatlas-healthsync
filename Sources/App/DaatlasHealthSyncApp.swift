import SwiftUI
import BackgroundTasks

@main
struct DaatlasHealthSyncApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var syncViewModel = SyncViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(syncViewModel)
                .onAppear {
                    syncViewModel.appDelegate = appDelegate
                }
        }
    }
}
