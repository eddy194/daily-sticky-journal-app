import AppKit
import SwiftUI

struct HighlightingTextView: NSViewRepresentable {
    @Binding var text: String
    var font: NSFont = .systemFont(ofSize: 15)
    var onTextChange: (() -> Void)? = nil

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, font: font, onTextChange: onTextChange)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let textView = NSTextView()
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
        textView.textContainerInset = NSSize(width: 2, height: 10)
        textView.insertionPointColor = .white
        textView.font = font

        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.minSize = NSSize(width: 0, height: 0)
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)

        textView.string = text
        context.coordinator.applyHighlighting(to: textView)
        textView.typingAttributes = context.coordinator.baseTypingAttributes()

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
        guard let textView = nsView.documentView as? NSTextView else { return }

        context.coordinator.onTextChange = onTextChange
        context.coordinator.font = font

        if textView.string != text {
            let selection = textView.selectedRange()
            context.coordinator.isProgrammaticUpdate = true
            textView.string = text
            context.coordinator.applyHighlighting(to: textView)
            textView.typingAttributes = context.coordinator.baseTypingAttributes()
            textView.setSelectedRange(selection)
            context.coordinator.isProgrammaticUpdate = false
        } else {
            context.coordinator.applyHighlighting(to: textView)
            textView.typingAttributes = context.coordinator.baseTypingAttributes()
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        @Binding var text: String
        var font: NSFont
        var onTextChange: (() -> Void)?
        var isProgrammaticUpdate = false

        init(text: Binding<String>, font: NSFont, onTextChange: (() -> Void)?) {
            _text = text
            self.font = font
            self.onTextChange = onTextChange
        }

        func textDidChange(_ notification: Notification) {
            guard !isProgrammaticUpdate else { return }
            guard let textView = notification.object as? NSTextView else { return }

            text = textView.string
            applyHighlighting(to: textView)
            textView.typingAttributes = baseTypingAttributes()
            onTextChange?()
        }

        func baseTypingAttributes() -> [NSAttributedString.Key: Any] {
            [
                .font: font,
                .foregroundColor: NSColor.labelColor
            ]
        }

        func applyHighlighting(to textView: NSTextView) {
            guard let storage = textView.textStorage else { return }

            let fullRange = NSRange(location: 0, length: (textView.string as NSString).length)
            if fullRange.length == 0 { return }

            let baseAttributes = baseTypingAttributes()

            let selection = textView.selectedRange()
            storage.beginEditing()
            storage.setAttributes(baseAttributes, range: fullRange)

            let ns = textView.string as NSString
            ns.enumerateSubstrings(in: fullRange, options: [.byLines, .substringNotRequired]) { _, lineRange, _, _ in
                let line = ns.substring(with: lineRange).trimmingCharacters(in: .whitespacesAndNewlines)
                guard let style = Self.sectionStyle(for: line) else { return }

                storage.addAttributes(
                    [
                        .foregroundColor: style.color,
                        .font: style.font
                    ],
                    range: lineRange
                )
            }

            storage.endEditing()
            textView.setSelectedRange(selection)
        }

        private struct SectionStyle {
            let color: NSColor
            let font: NSFont
        }

        private static func sectionStyle(for trimmedLine: String) -> SectionStyle? {
            // Exact hex can be adjusted here if you want to match a reference UI pixel-perfect.
            func color(_ hex: UInt32) -> NSColor {
                let r = CGFloat((hex >> 16) & 0xFF) / 255.0
                let g = CGFloat((hex >> 8) & 0xFF) / 255.0
                let b = CGFloat(hex & 0xFF) / 255.0
                return NSColor(calibratedRed: r, green: g, blue: b, alpha: 1.0)
            }

            switch trimmedLine.uppercased() {
            case "LSEG:":
                return SectionStyle(color: color(0x21C7D8), font: .systemFont(ofSize: 13, weight: .bold))
            case "KA:":
                return SectionStyle(color: color(0xB7F52A), font: .systemFont(ofSize: 13, weight: .bold))
            case "METRO:":
                return SectionStyle(color: color(0x2AA2FF), font: .systemFont(ofSize: 13, weight: .bold))
            case "SMARTX:":
                return SectionStyle(color: color(0xFF2D5C), font: .systemFont(ofSize: 13, weight: .bold))
            default:
                return nil
            }
        }
    }
}
