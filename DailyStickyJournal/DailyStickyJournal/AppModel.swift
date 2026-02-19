import Foundation

@MainActor
final class AppModel: ObservableObject {
    let settings: SettingsStore
    let launchAtLogin: LaunchAtLoginService
    let persistence: PersistenceController
    let noteStore: NoteStore

    let todayViewModel: ChecklistNoteViewModel
    let panelController: PanelController
    let rolloverScheduler: RolloverScheduler

    init() {
        let settings = SettingsStore()
        self.settings = settings
        self.launchAtLogin = .shared

        let persistence = PersistenceController.shared
        self.persistence = persistence

        let noteStore = NoteStore(persistence: persistence, settings: settings)
        self.noteStore = noteStore

        self.todayViewModel = ChecklistNoteViewModel(noteStore: noteStore, initialDateKey: DateKey.today())
        self.panelController = PanelController(settings: settings, viewModel: todayViewModel)
        self.rolloverScheduler = RolloverScheduler(noteStore: noteStore)

        rolloverScheduler.start()
    }
}
