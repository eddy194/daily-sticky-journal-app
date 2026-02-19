import Foundation

struct ChecklistDocument: Equatable {
    struct Task: Identifiable, Equatable {
        var id = UUID()
        var isDone: Bool
        var text: String
    }

    struct Section: Identifiable, Equatable {
        var id = UUID()
        var title: String
        var tasks: [Task]
    }

    var sections: [Section]
    var notes: String

    static func parse(_ content: String) -> ChecklistDocument {
        let rawLines = content.replacingOccurrences(of: "\r\n", with: "\n").split(separator: "\n", omittingEmptySubsequences: false).map(String.init)

        var sections: [Section] = []
        var currentTitle: String?
        var currentTasks: [Task] = []
        var notesLines: [String] = []

        func flushSectionIfNeeded() {
            guard let title = currentTitle else { return }
            sections.append(Section(title: title, tasks: currentTasks))
            currentTitle = nil
            currentTasks = []
        }

        for line in rawLines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                if currentTitle == nil {
                    if !notesLines.isEmpty, notesLines.last != "" { notesLines.append("") }
                }
                continue
            }

            if isSectionHeader(trimmed) {
                flushSectionIfNeeded()
                currentTitle = trimmed
                continue
            }

            if let task = parseTaskLine(trimmed) {
                if currentTitle == nil {
                    currentTitle = "Notes:"
                }
                currentTasks.append(task)
                continue
            }

            notesLines.append(line)
        }

        flushSectionIfNeeded()

        return ChecklistDocument(sections: sections, notes: notesLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines))
    }

    func render() -> String {
        var lines: [String] = []

        for section in sections {
            let title = section.title.trimmingCharacters(in: .whitespacesAndNewlines)
            if !title.isEmpty { lines.append(title) }

            for task in section.tasks {
                let prefix = task.isDone ? "☑" : "☐"
                let t = task.text.trimmingCharacters(in: .whitespacesAndNewlines)
                lines.append(t.isEmpty ? "\(prefix) " : "\(prefix) \(t)")
            }

            lines.append("")
        }

        let notesTrimmed = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if !notesTrimmed.isEmpty {
            lines.append(notesTrimmed)
            lines.append("")
        }

        while lines.last == "" { lines.removeLast() }
        return lines.joined(separator: "\n")
    }

    private static func isSectionHeader(_ trimmedLine: String) -> Bool {
        trimmedLine.hasSuffix(":") && !trimmedLine.hasPrefix("☐") && !trimmedLine.hasPrefix("☑")
    }

    private static func parseTaskLine(_ trimmedLine: String) -> Task? {
        if trimmedLine.hasPrefix("☐") {
            return Task(isDone: false, text: trimTaskText(String(trimmedLine.dropFirst()).trimmingCharacters(in: .whitespaces)))
        }
        if trimmedLine.hasPrefix("☑") {
            return Task(isDone: true, text: trimTaskText(String(trimmedLine.dropFirst()).trimmingCharacters(in: .whitespaces)))
        }

        if trimmedLine.hasPrefix("- [ ]") {
            let rest = trimmedLine.replacingOccurrences(of: "- [ ]", with: "", options: [.anchored])
            return Task(isDone: false, text: trimTaskText(rest.trimmingCharacters(in: .whitespaces)))
        }
        if trimmedLine.lowercased().hasPrefix("- [x]") {
            let rest = trimmedLine.dropFirst(5)
            return Task(isDone: true, text: trimTaskText(String(rest).trimmingCharacters(in: .whitespaces)))
        }
        if trimmedLine.hasPrefix("•") {
            let rest = trimmedLine.dropFirst()
            return Task(isDone: false, text: trimTaskText(String(rest).trimmingCharacters(in: .whitespaces)))
        }
        return nil
    }

    private static func trimTaskText(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

