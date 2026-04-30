import UIKit
import BackgroundTasks

class AppDelegate: NSObject, UIApplicationDelegate {
    static let backgroundTaskIdentifier = "com.diyDiabetes.nightscout-healthsync.refresh"

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        registerBackgroundTasks()
        return true
    }

    // Schedule when app moves to background (not just on task fire)
    func applicationDidEnterBackground(_ application: UIApplication) {
        Task {
            let enabled = await UserSettings.shared.autoSyncEnabled
            if enabled {
                await scheduleBackgroundRefresh()
            }
        }
    }

    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.backgroundTaskIdentifier,
            using: nil
        ) { task in
            self.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
        }
    }

    func scheduleBackgroundRefresh() async {
        let settings = UserSettings.shared
        let enabled = await settings.autoSyncEnabled
        guard enabled else {
            BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.backgroundTaskIdentifier)
            return
        }
        let interval = await settings.backgroundSyncInterval
        let request = BGAppRefreshTaskRequest(identifier: Self.backgroundTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: Double(interval) * 60)
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background refresh scheduled in \(interval) minutes")
        } catch {
            print("Failed to schedule background refresh: \(error)")
        }
    }

    private func handleBackgroundRefresh(task: BGAppRefreshTask) {
        // Reschedule next run before doing work
        Task { await scheduleBackgroundRefresh() }

        let syncTask = Task {
            do {
                _ = try await SyncService.shared.syncAll()
                task.setTaskCompleted(success: true)
            } catch {
                print("Background sync failed: \(error)")
                task.setTaskCompleted(success: false)
            }
        }

        task.expirationHandler = {
            syncTask.cancel()
        }
    }
}
