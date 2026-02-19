import AppKit
import SwiftUI

struct HighlightingTextView: NSViewRepresentable {
    @Binding var text: String
    var font: NSFont = .systemFont(ofSize: 15)
    var onTextChange: (() -> Void)? = nil

    private final class CheckboxTextView: NSTextView {
        weak var checkboxDelegate: CheckboxTextViewDelegate?

        override func mouseDown(with event: NSEvent) {
            let point = convert(event.locationInWindow, from: nil)
            let index = characterIndexForClick(at: point)
            if checkboxDelegate?.toggleCheckbox(at: index, in: self) == true {
                return
            }
            super.mouseDown(with: event)
        }

        override func resetCursorRects() {
            super.resetCursorRects()
            addCheckboxCursorRects()
        }

        private func addCheckboxCursorRects() {
            guard let layoutManager, let textContainer else { return }

            let ns = string as NSString
            let full = NSRange(location: 0, length: ns.length)
            if full.length == 0 { return }

            var lineStart = 0
            while lineStart < ns.length {
                var start = 0
                var end = 0
                var contentsEnd = 0
                ns.getLineStart(&start, end: &end, contentsEnd: &contentsEnd, for: NSRange(location: lineStart, length: 0))
                let lineRange = NSRange(location: start, length: end - start)
                let line = ns.substring(with: lineRange)
                if line.hasPrefix("☐") || line.hasPrefix("☑") || line.hasPrefix("- [ ]") || line.hasPrefix("- [x]") || line.hasPrefix("- [X]") {
                    let charRange = NSRange(location: start, length: 1)
                    let glyphRange = layoutManager.glyphRange(forCharacterRange: charRange, actualCharacterRange: nil)
                    var rect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
                    let origin = textContainerOrigin
                    rect.origin.x += origin.x
                    rect.origin.y += origin.y
                    // Expand slightly to include the trailing space.
                    rect.size.width = max(rect.size.width + 10, 16)
                    addCursorRect(rect, cursor: .pointingHand)
                }
                lineStart = end
            }
        }

        private func characterIndexForClick(at point: NSPoint) -> Int {
            guard let layoutManager, let textContainer else { return 0 }

            let containerOrigin = textContainerOrigin
            let adjustedPoint = NSPoint(x: point.x - containerOrigin.x, y: point.y - containerOrigin.y)
            let glyphIndex = layoutManager.glyphIndex(for: adjustedPoint, in: textContainer)
            return layoutManager.characterIndexForGlyph(at: glyphIndex)
        }
    }

    private protocol CheckboxTextViewDelegate: AnyObject {
        func toggleCheckbox(at characterIndex: Int, in textView: NSTextView) -> Bool
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, font: font, onTextChange: onTextChange)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let textView = CheckboxTextView()
        textView.delegate = context.coordinator
        textView.checkboxDelegate = context.coordinator
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
                let lineRaw = ns.substring(with: lineRange)
                let lineTrimmed = lineRaw.trimmingCharacters(in: .whitespacesAndNewlines)

                if let style = Self.sectionStyle(for: lineTrimmed) {
                    storage.addAttributes(
                        [
                            .foregroundColor: style.color,
                            .font: style.font,
                            .kern: 0.6
                        ],
                        range: lineRange
                    )
                }

                if Self.isBulletLine(lineTrimmed) || Self.isCheckboxLine(lineTrimmed) {
                    let p = Self.listParagraphStyle()
                    storage.addAttribute(.paragraphStyle, value: p, range: lineRange)
                }

                // Dim the leading "- [ ] " part to make tasks feel cleaner.
                if let prefixRange = Self.checkboxPrefixRange(in: lineRaw, lineRange: lineRange) {
                    storage.addAttributes(
                        [
                            .foregroundColor: NSColor.secondaryLabelColor,
                            .font: NSFont.systemFont(ofSize: max(12, self.font.pointSize - 1), weight: .semibold)
                        ],
                        range: prefixRange
                    )
                }

                if Self.isCheckedCheckboxLine(lineTrimmed),
                   let contentRange = Self.checkboxContentRange(in: lineRaw, lineRange: lineRange) {
                    storage.addAttributes(
                        [
                            .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                            .foregroundColor: NSColor.secondaryLabelColor
                        ],
                        range: contentRange
                    )
                }
            }

            Self.highlightTemplateTokens(in: storage, string: textView.string, baseFont: font)

            storage.endEditing()
            textView.setSelectedRange(selection)
        }

        private struct SectionStyle {
            let color: NSColor
            let font: NSFont
        }

        private static func isBulletLine(_ trimmedLine: String) -> Bool {
            trimmedLine.hasPrefix("•") || trimmedLine.hasPrefix("- ")
        }

        private static func isCheckboxLine(_ trimmedLine: String) -> Bool {
            trimmedLine.hasPrefix("☐") || trimmedLine.hasPrefix("☑") || trimmedLine.hasPrefix("- [ ]") || trimmedLine.hasPrefix("- [x]") || trimmedLine.hasPrefix("- [X]")
        }

        private static func isCheckedCheckboxLine(_ trimmedLine: String) -> Bool {
            trimmedLine.hasPrefix("☑") || trimmedLine.hasPrefix("- [x]") || trimmedLine.hasPrefix("- [X]")
        }

        private static func checkboxPrefixRange(in rawLine: String, lineRange: NSRange) -> NSRange? {
            // Apply styling only to the prefix if present.
            let glyphPrefixes = ["☐", "☑"]
            for g in glyphPrefixes where rawLine.hasPrefix(g) {
                return NSRange(location: lineRange.location, length: min(2, lineRange.length))
            }

            let prefix = "- [ ] "
            if rawLine.hasPrefix(prefix) {
                return NSRange(location: lineRange.location, length: min(prefix.count, lineRange.length))
            }
            let prefix2 = "- [x] "
            if rawLine.hasPrefix(prefix2) {
                return NSRange(location: lineRange.location, length: min(prefix2.count, lineRange.length))
            }
            let prefix3 = "- [X] "
            if rawLine.hasPrefix(prefix3) {
                return NSRange(location: lineRange.location, length: min(prefix3.count, lineRange.length))
            }
            return nil
        }

        private static func checkboxContentRange(in rawLine: String, lineRange: NSRange) -> NSRange? {
            let prefixes = ["☐ ", "☑ ", "- [ ] ", "- [x] ", "- [X] "]
            for p in prefixes where rawLine.hasPrefix(p) {
                let start = lineRange.location + p.count
                let length = max(0, lineRange.length - p.count)
                return NSRange(location: start, length: length)
            }
            return nil
        }

        private static func listParagraphStyle() -> NSParagraphStyle {
            let style = NSMutableParagraphStyle()
            style.lineSpacing = 5
            style.paragraphSpacing = 3
            style.firstLineHeadIndent = 0
            style.headIndent = 18
            style.tabStops = []
            return style
        }

        private static func highlightTemplateTokens(in storage: NSTextStorage, string: String, baseFont: NSFont) {
            // Style {{tokens}} so templates are visually distinct.
            let ns = string as NSString
            let range = NSRange(location: 0, length: ns.length)
            guard let re = try? NSRegularExpression(pattern: "\\\\{\\\\{[^}]+\\\\}\\\\}", options: []) else { return }

            let tokenFont = NSFont.monospacedSystemFont(ofSize: max(12, baseFont.pointSize - 1), weight: .medium)
            re.enumerateMatches(in: string, options: [], range: range) { match, _, _ in
                guard let match else { return }
                storage.addAttributes(
                    [
                        .foregroundColor: NSColor.tertiaryLabelColor,
                        .font: tokenFont
                    ],
                    range: match.range
                )
            }
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

extension HighlightingTextView.Coordinator: HighlightingTextView.CheckboxTextViewDelegate {
	    func toggleCheckbox(at characterIndex: Int, in textView: NSTextView) -> Bool {
	        let ns = textView.string as NSString
	        let length = ns.length
	        guard characterIndex >= 0, characterIndex <= length else { return false }
	        var lineStart = 0
	        var lineEnd = 0
	        var contentsEnd = 0
	        ns.getLineStart(&lineStart, end: &lineEnd, contentsEnd: &contentsEnd, for: NSRange(location: min(characterIndex, max(0, length - 1)), length: 0))
        let lineRange = NSRange(location: lineStart, length: lineEnd - lineStart)
        let lineRaw = ns.substring(with: lineRange)

        // Only toggle when clicking inside the checkbox prefix.
        let matchedPrefix: String?
        if lineRaw.hasPrefix("☐ ") { matchedPrefix = "☐ " }
        else if lineRaw.hasPrefix("☑ ") { matchedPrefix = "☑ " }
        else if lineRaw.hasPrefix("- [ ] ") { matchedPrefix = "- [ ] " }
        else if lineRaw.hasPrefix("- [x] ") { matchedPrefix = "- [x] " }
        else if lineRaw.hasPrefix("- [X] ") { matchedPrefix = "- [X] " }
        else { matchedPrefix = nil }
        guard let matchedPrefix else { return false }

        let prefixClickRange = NSRange(location: lineRange.location, length: 2)
        guard NSLocationInRange(characterIndex, prefixClickRange) else { return false }

        let replacementPrefix: String
        if matchedPrefix == "☐ " || matchedPrefix == "- [ ] " {
            replacementPrefix = "☑ "
        } else {
            replacementPrefix = "☐ "
        }

        let selection = textView.selectedRange()
        isProgrammaticUpdate = true

        let newLineRaw = replacementPrefix + String(lineRaw.dropFirst(matchedPrefix.count))
        guard let storage = textView.textStorage else {
            isProgrammaticUpdate = false
            return false
        }

        textView.shouldChangeText(in: lineRange, replacementString: newLineRaw)
        storage.replaceCharacters(in: lineRange, with: newLineRaw)
        textView.didChangeText()

        text = textView.string
        applyHighlighting(to: textView)
        textView.typingAttributes = baseTypingAttributes()
        textView.setSelectedRange(selection)

        isProgrammaticUpdate = false
        onTextChange?()
        return true
    }
}
