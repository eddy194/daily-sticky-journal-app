import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct HistoryView: View {
    @StateObject private var viewModel: HistoryViewModel

    @State private var exportErrorMessage: String?
    @State private var showingExportError = false

    init(noteStore: NoteStore) {
        _viewModel = StateObject(wrappedValue: HistoryViewModel(noteStore: noteStore))
    }

    var body: some View {
        NavigationSplitView {
            List(viewModel.notes, selection: $viewModel.selection) { note in
                VStack(alignment: .leading, spacing: 4) {
                    Text(Self.localizedTitle(dateKey: note.dateKey))
                        .font(.headline)
                    if !note.preview.isEmpty {
                        Text(note.preview)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .padding(.vertical, 4)
                .tag(note.id)
            }
            .searchable(text: $viewModel.searchText, prompt: "Search notes")
            .onChange(of: viewModel.searchText) { _, _ in
                viewModel.scheduleSearchRefresh()
            }
            .onAppear {
                viewModel.refresh()
            }
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button("Export Selected…") { exportSelected() }
                        .disabled(viewModel.selection == nil)
                    Button("Export All…") { exportAll() }
                        .disabled(viewModel.notes.isEmpty)
                }
            }
        } detail: {
            if let dateKey = viewModel.selection {
                NoteEditorContainer(noteStore: viewModel.noteStore, dateKey: dateKey)
                    .id(dateKey)
            } else {
                ContentUnavailableView("No note selected", systemImage: "note")
            }
        }
        .alert("Export failed", isPresented: $showingExportError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportErrorMessage ?? "Unknown error")
        }
    }

    private func exportSelected() {
        guard let dateKey = viewModel.selection else { return }
        do {
            let content = try viewModel.noteStore.fetchNote(dateKey: dateKey)?.content ?? ""
            let panel = NSSavePanel()
            panel.nameFieldStringValue = "\(dateKey).txt"
            panel.allowedContentTypes = [.plainText]
            panel.canCreateDirectories = true
            panel.isExtensionHidden = false
            panel.begin { response in
                guard response == .OK, let url = panel.url else { return }
                do {
                    try content.write(to: url, atomically: true, encoding: .utf8)
                } catch {
                    showExportError(error)
                }
            }
        } catch {
            showExportError(error)
        }
    }

    private func exportAll() {
        do {
            let payloads: [(dateKey: String, content: String)] = try viewModel.noteStore.fetchAllNotes().map {
                (dateKey: $0.dateKey, content: $0.content)
            }
            let panel = NSOpenPanel()
            panel.canChooseFiles = false
            panel.canChooseDirectories = true
            panel.allowsMultipleSelection = false
            panel.prompt = "Choose Folder"
            panel.begin { response in
                guard response == .OK, let folder = panel.url else { return }
                do {
                    for payload in payloads {
                        let fileURL = folder.appendingPathComponent("\(payload.dateKey).txt")
                        try payload.content.write(to: fileURL, atomically: true, encoding: .utf8)
                    }
                } catch {
                    showExportError(error)
                }
            }
        } catch {
            showExportError(error)
        }
    }

    private func showExportError(_ error: Error) {
        exportErrorMessage = error.localizedDescription
        showingExportError = true
    }

    private static func localizedTitle(dateKey: String) -> String {
        let date = DateKey.date(from: dateKey) ?? Date()
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.timeZone = .current
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

private struct NoteEditorContainer: View {
    let noteStore: NoteStore
    let dateKey: String

    @StateObject private var viewModel: NoteEditorViewModel

    init(noteStore: NoteStore, dateKey: String) {
        self.noteStore = noteStore
        self.dateKey = dateKey
        _viewModel = StateObject(wrappedValue: NoteEditorViewModel(noteStore: noteStore, dateKey: dateKey))
    }

    var body: some View {
        NoteEditorView(viewModel: viewModel)
    }
}
