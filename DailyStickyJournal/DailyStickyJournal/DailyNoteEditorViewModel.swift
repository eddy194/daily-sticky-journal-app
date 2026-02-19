import Foundation

@MainActor
final class DailyNoteEditorViewModel: ObservableObject {
    @Published private(set) var dateKey: String
    @Published private(set) var titleText: String = ""
    @Published var content: String = ""

    private let noteStore: NoteStore
    private var saveTask: Task<Void, Never>?

    init(noteStore: NoteStore, initialDateKey: String) {
        self.noteStore = noteStore
        self.dateKey = initialDateKey
        load(dateKey: initialDateKey)

        NotificationCenter.default.addObserver(
            forName: .dailyStickyJournalDidRollover,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.loadToday()
            }
        }
    }

    func loadToday() {
        load(dateKey: DateKey.today())
    }

    func load(dateKey: String) {
        saveTask?.cancel()

        self.dateKey = dateKey
        self.titleText = Self.makeTitle(dateKey: dateKey)

        do {
            let note = try noteStore.getOrCreateNote(dateKey: dateKey)
            self.content = note.content
        } catch {
            NSLog("Failed to load note \(dateKey): \(error)")
            self.content = ""
        }
    }

    func scheduleAutosave(debounceMilliseconds: UInt64 = 500) {
        let contentSnapshot = content
        let dateKeySnapshot = dateKey

        saveTask?.cancel()
        saveTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: debounceMilliseconds * 1_000_000)
            guard !Task.isCancelled else { return }
            do {
                try self?.noteStore.updateContent(dateKey: dateKeySnapshot, content: contentSnapshot)
            } catch {
                NSLog("Autosave failed: \(error)")
            }
        }
    }

    static func makeTitle(dateKey: String) -> String {
        let date = DateKey.date(from: dateKey) ?? Date()
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.timeZone = .current
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
