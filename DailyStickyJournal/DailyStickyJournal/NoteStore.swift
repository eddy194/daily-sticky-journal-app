import CoreData
import Foundation

@MainActor
final class NoteStore {
    private let persistence: PersistenceController
    private let settings: SettingsStore

    init(persistence: PersistenceController, settings: SettingsStore) {
        self.persistence = persistence
        self.settings = settings
    }

    var viewContext: NSManagedObjectContext { persistence.container.viewContext }

    func getOrCreateNote(dateKey: String) throws -> Note {
        if let existing = try fetchNote(dateKey: dateKey) {
            try normalizeContentIfNeeded(existing)
            try prefillIfEmpty(existing)
            return existing
        }

        let note = Note(context: viewContext)
        note.id = UUID().uuidString
        note.dateKey = dateKey

        let now = Date()
        note.createdAt = now
        note.updatedAt = now

        let noteDate = DateKey.date(from: dateKey) ?? now
        note.content = TemplateRenderer.render(template: settings.templateText, for: noteDate)

        try viewContext.save()
        return note
    }

    func getOrCreateTodayNote() throws -> Note {
        try getOrCreateNote(dateKey: DateKey.today())
    }

    func fetchNote(dateKey: String) throws -> Note? {
        let req = NSFetchRequest<Note>(entityName: "Note")
        req.fetchLimit = 1
        req.predicate = NSPredicate(format: "dateKey == %@", dateKey)
        return try viewContext.fetch(req).first
    }

    func fetchAllNotes(searchText: String? = nil) throws -> [Note] {
        let req = NSFetchRequest<Note>(entityName: "Note")
        req.sortDescriptors = [NSSortDescriptor(key: "dateKey", ascending: false)]
        if let searchText, !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            req.predicate = NSPredicate(format: "content CONTAINS[cd] %@", searchText)
        }
        return try viewContext.fetch(req)
    }

    func updateContent(dateKey: String, content: String) throws {
        let note = try getOrCreateNote(dateKey: dateKey)
        note.content = content
        note.updatedAt = Date()
        try viewContext.save()
    }

    private func normalizeContentIfNeeded(_ note: Note) throws {
        let current = note.content
        guard current.contains("\\n"), !current.contains("\n") else { return }

        let normalized = current
            .replacingOccurrences(of: "\\r\\n", with: "\n")
            .replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\\t", with: "\t")

        guard normalized != current else { return }
        note.content = normalized
        note.updatedAt = Date()
        try viewContext.save()
    }

    private func prefillIfEmpty(_ note: Note) throws {
        if !note.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return }

        let noteDate = DateKey.date(from: note.dateKey) ?? Date()
        let rendered = TemplateRenderer.render(template: settings.templateText, for: noteDate)
        guard !rendered.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        note.content = rendered
        note.updatedAt = Date()
        try viewContext.save()
    }
}
