import SwiftUI

@main
struct DailyStickyJournalApp: App {
    @StateObject private var appModel = AppModel()

    var body: some Scene {
        MenuBarExtra("Daily Sticky Journal", systemImage: "note.text") {
            MenuBarContent()
                .environmentObject(appModel.panelController)
        }

        Window("History", id: AppWindows.historyID) {
            HistoryView(noteStore: appModel.noteStore)
        }
        .defaultSize(width: 980, height: 640)

        Settings {
            SettingsView(settings: appModel.settings, launchService: appModel.launchAtLogin)
        }
    }
}

private struct MenuBarContent: View {
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject private var panelController: PanelController

    var body: some View {
        Button(panelController.isVisible ? "Hide Panel" : "Open Panel") {
            panelController.toggle()
        }
        Button("Open History") {
            openWindow(id: AppWindows.historyID)
        }
        SettingsLink { Text("Settings…") }
        Divider()
        Button("Quit") {
            NSApp.terminate(nil)
        }
    }
}
