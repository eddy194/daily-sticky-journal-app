import SwiftUI

struct ChecklistNoteView: View {
    @ObservedObject var viewModel: ChecklistNoteViewModel

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                ForEach($viewModel.document.sections) { $section in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(section.title)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(sectionColor(section.title))
                                .kerning(0.6)
                            Spacer(minLength: 0)
                            Button {
                                viewModel.addTask(to: section.id)
                            } label: {
                                Image(systemName: "plus.circle.fill")
                            }
                            .buttonStyle(.borderless)
                            .foregroundStyle(.secondary)
                            .help("Add task")
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            ForEach($section.tasks) { $task in
                                ChecklistTaskRow(isDone: $task.isDone, text: $task.text) {
                                    viewModel.deleteTask(sectionID: section.id, taskID: task.id)
                                }
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Notes")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)

                    ZStack(alignment: .topLeading) {
                        if viewModel.document.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("Write anything…")
                                .foregroundStyle(.secondary.opacity(0.7))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 8)
                                .allowsHitTesting(false)
                        }
                        TextEditor(text: $viewModel.document.notes)
                            .scrollContentBackground(.hidden)
                    }
                    .frame(minHeight: 140)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.white.opacity(0.04))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                            )
                    )
                }
            }
            .padding(.top, 2)
            .padding(.bottom, 10)
        }
        .scrollIndicators(.automatic)
        .onChange(of: viewModel.document) { _, _ in
            // Catch any structural changes.
            viewModel.scheduleAutosave()
        }
    }

    private func sectionColor(_ title: String) -> Color {
        let key = title.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        switch key {
        case "LSEG:":
            return Color(hex: 0x21C7D8)
        case "KA:":
            return Color(hex: 0xB7F52A)
        case "METRO:":
            return Color(hex: 0x2AA2FF)
        case "SMARTX:":
            return Color(hex: 0xFF2D5C)
        default:
            return .primary
        }
    }
}

private struct ChecklistTaskRow: View {
    @Binding var isDone: Bool
    @Binding var text: String
    let onDelete: () -> Void

    @State private var isHovering: Bool = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Toggle("", isOn: $isDone)
                .toggleStyle(.checkbox)
                .labelsHidden()
                .controlSize(.large)

            ZStack(alignment: .leading) {
                TextField("New task", text: $text)
                    .textFieldStyle(.plain)
                    .foregroundStyle(isDone ? .secondary : .primary)

                if isDone {
                    GeometryReader { geo in
                        Rectangle()
                            .fill(Color.secondary.opacity(0.85))
                            .frame(height: 1)
                            .offset(y: geo.size.height / 2)
                    }
                    .allowsHitTesting(false)
                }
            }
            .frame(maxWidth: .infinity)

            if isHovering {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "minus.circle.fill")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
                .help("Delete task")
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(isHovering ? 0.06 : 0.03))
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) {
                isHovering = hovering
            }
        }
    }
}

private extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1.0)
    }
}
