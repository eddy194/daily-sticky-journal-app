import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsStore
    let launchService: LaunchAtLoginService

    @State private var launchErrorMessage: String?
    @State private var showingLaunchError = false

    var body: some View {
        Form {
            Section("Template") {
                HighlightingTextView(text: $settings.templateText, font: .monospacedSystemFont(ofSize: 14, weight: .regular))
                    .frame(minHeight: 220)
                Text("Tokens: {{date}}, {{iso_date}}, {{weekday}}")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Panel") {
                Toggle("Always on top", isOn: $settings.alwaysOnTop)
                Toggle("Show on all spaces", isOn: $settings.showOnAllSpaces)
                Toggle("Lock panel position", isOn: $settings.lockPanelPosition)
            }

            Section("Startup") {
                Toggle("Launch at login", isOn: $settings.launchAtLogin)
                    .onChange(of: settings.launchAtLogin) { _, newValue in
                        setLaunchAtLogin(newValue)
                    }
            }
        }
        .padding(20)
        .frame(width: 560, height: 520)
        .onAppear {
            settings.launchAtLogin = launchService.isEnabled
        }
        .alert("Launch at login failed", isPresented: $showingLaunchError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(launchErrorMessage ?? "Unknown error")
        }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try launchService.setEnabled(enabled)
        } catch {
            launchErrorMessage = error.localizedDescription
            showingLaunchError = true
            settings.launchAtLogin = launchService.isEnabled
        }
    }
}
