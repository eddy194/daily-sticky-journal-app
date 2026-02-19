import Foundation

@MainActor
final class HistoryViewModel: ObservableObject {
    struct NoteSummary: Identifiable, Hashable {
        let dateKey: String
        let updatedAt: Date
        let preview: String
        var id: String { dateKey }
    }

    @Published var searchText: String = ""
    @Published private(set) var notes: [NoteSummary] = []
    @Published var selection: NoteSummary.ID?

    let noteStore: NoteStore
    private var searchTask: Task<Void, Never>?

    init(noteStore: NoteStore) {
        self.noteStore = noteStore
    }

    func refresh() {
        do {
            let fetched = try noteStore.fetchAllNotes(searchText: searchText)
            notes = fetched.map {
                NoteSummary(
                    dateKey: $0.dateKey,
                    updatedAt: $0.updatedAt,
                    preview: Self.makePreview($0.content)
                )
            }
            if let selection, notes.contains(where: { $0.id == selection }) {
                // keep selection
            } else {
                selection = notes.first?.id
            }
        } catch {
            NSLog("Failed to refresh history: \(error)")
            notes = []
        }
    }

    func scheduleSearchRefresh(debounceMilliseconds: UInt64 = 250) {
        searchTask?.cancel()
        searchTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: debounceMilliseconds * 1_000_000)
            guard !Task.isCancelled else { return }
            self?.refresh()
        }
    }

    private static func makePreview(_ content: String) -> String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        return trimmed.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: true).first.map(String.init) ?? ""
    }
}
