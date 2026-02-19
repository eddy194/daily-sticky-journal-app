import Foundation

@MainActor
final class ChecklistNoteViewModel: ObservableObject {
    @Published private(set) var dateKey: String
    @Published private(set) var titleText: String = ""
    @Published var document: ChecklistDocument = ChecklistDocument(sections: [], notes: "")

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
        self.titleText = DailyNoteEditorViewModel.makeTitle(dateKey: dateKey)

        do {
            let note = try noteStore.getOrCreateNote(dateKey: dateKey)
            self.document = ChecklistDocument.parse(note.content)
        } catch {
            NSLog("Failed to load note \(dateKey): \(error)")
            self.document = ChecklistDocument(sections: [], notes: "")
        }
    }

    func scheduleAutosave(debounceMilliseconds: UInt64 = 500) {
        let snapshot = document.render()
        let dateKeySnapshot = dateKey

        saveTask?.cancel()
        saveTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: debounceMilliseconds * 1_000_000)
            guard !Task.isCancelled else { return }
            do {
                try self?.noteStore.updateContent(dateKey: dateKeySnapshot, content: snapshot)
            } catch {
                NSLog("Autosave failed: \(error)")
            }
        }
    }

    func addTask(to sectionID: ChecklistDocument.Section.ID) {
        guard let idx = document.sections.firstIndex(where: { $0.id == sectionID }) else { return }
        document.sections[idx].tasks.append(.init(isDone: false, text: ""))
        scheduleAutosave()
    }

    func deleteTask(sectionID: ChecklistDocument.Section.ID, taskID: ChecklistDocument.Task.ID) {
        guard let sidx = document.sections.firstIndex(where: { $0.id == sectionID }) else { return }
        document.sections[sidx].tasks.removeAll { $0.id == taskID }
        scheduleAutosave()
    }
}

