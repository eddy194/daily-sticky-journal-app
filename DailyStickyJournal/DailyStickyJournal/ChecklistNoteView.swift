import AppKit
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

                    PlaceholderTextEditor(text: $viewModel.document.notes, placeholder: "Write anything…") {
                        viewModel.scheduleAutosave()
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
        HStack(alignment: .center, spacing: 10) {
            Toggle("", isOn: $isDone)
                .toggleStyle(.checkbox)
                .labelsHidden()
                .controlSize(.regular)

            ZStack(alignment: .leading) {
                TextField("New task", text: $text)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .foregroundStyle(isDone ? .secondary : .primary)

                if isDone {
                    GeometryReader { geo in
                        Rectangle()
                            .fill(Color.secondary.opacity(0.85))
                            .frame(height: 1)
                            .offset(y: geo.size.height * 0.60)
                    }
                    .allowsHitTesting(false)
                }
            }
            .frame(maxWidth: .infinity)

            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "minus.circle.fill")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .help("Delete task")
            .opacity(isHovering ? 1 : 0)
            .animation(.easeOut(duration: 0.12), value: isHovering)
            .allowsHitTesting(isHovering)
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

private struct PlaceholderTextEditor: NSViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let onTextChange: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onTextChange: onTextChange)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let textView = PlaceholderNSTextView()
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.isAutomaticTextReplacementEnabled = true
        textView.isAutomaticSpellingCorrectionEnabled = true
        textView.isContinuousSpellCheckingEnabled = false
        textView.smartInsertDeleteEnabled = true
        textView.usesFindPanel = true
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 5, height: 6)
        textView.insertionPointColor = .white
        textView.font = .systemFont(ofSize: 14)
        textView.placeholderString = placeholder
        textView.placeholderColor = NSColor.secondaryLabelColor.withAlphaComponent(0.7)

        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.minSize = NSSize(width: 0, height: 0)
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.lineFragmentPadding = 0

        textView.string = text

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.documentView = textView

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? PlaceholderNSTextView else { return }
        context.coordinator.onTextChange = onTextChange
        if textView.string != text {
            textView.string = text
        }
        textView.placeholderString = placeholder
        textView.needsDisplay = true
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        @Binding var text: String
        var onTextChange: () -> Void

        init(text: Binding<String>, onTextChange: @escaping () -> Void) {
            _text = text
            self.onTextChange = onTextChange
        }

        func textDidChange(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            text = tv.string
            onTextChange()
            tv.needsDisplay = true
        }
    }

    final class PlaceholderNSTextView: NSTextView {
        var placeholderString: String = ""
        var placeholderColor: NSColor = .secondaryLabelColor

        override func draw(_ dirtyRect: NSRect) {
            super.draw(dirtyRect)

            guard string.isEmpty, !placeholderString.isEmpty else { return }

            let origin = textContainerOrigin
            let fontToUse = font ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)
            let padding = textContainer?.lineFragmentPadding ?? 0
            let caretX: CGFloat? = {
                guard let window else { return nil }
                let screen = firstRect(forCharacterRange: NSRange(location: 0, length: 0), actualRange: nil)
                guard !screen.isEmpty else { return nil }
                let windowRect = window.convertFromScreen(screen)
                let local = convert(windowRect, from: nil)
                return local.minX
            }()

            let point = CGPoint(x: caretX ?? (origin.x + padding), y: origin.y)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: fontToUse,
                .foregroundColor: placeholderColor
            ]
            (placeholderString as NSString).draw(at: point, withAttributes: attributes)
        }
    }
}
