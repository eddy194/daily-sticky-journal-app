import AppKit
import Combine
import SwiftUI

@MainActor
final class PanelController: NSObject, ObservableObject, NSWindowDelegate {
    @Published private(set) var isVisible: Bool = false

    private let settings: SettingsStore
    private let viewModel: ChecklistNoteViewModel
    private var panel: NSPanel?
    private var cancellables: Set<AnyCancellable> = []

    init(settings: SettingsStore, viewModel: ChecklistNoteViewModel) {
        self.settings = settings
        self.viewModel = viewModel
        super.init()

        settings.$alwaysOnTop
            .sink { [weak self] _ in self?.applyWindowToggles() }
            .store(in: &cancellables)
        settings.$showOnAllSpaces
            .sink { [weak self] _ in self?.applyWindowToggles() }
            .store(in: &cancellables)
        settings.$lockPanelPosition
            .sink { [weak self] _ in self?.applyWindowToggles() }
            .store(in: &cancellables)
    }

    func toggle() {
        isVisible ? hide() : show()
    }

    func show() {
        let panel = makePanelIfNeeded()
        // Reload on show so we pick up any template normalization/migrations.
        viewModel.loadToday()
        applyWindowToggles()

        // If a tiny frame was persisted before, expand it on show.
        let minSize = panel.minSize
        var frame = panel.frame
        if frame.size.width < minSize.width || frame.size.height < minSize.height {
            frame.size.width = max(frame.size.width, minSize.width)
            frame.size.height = max(frame.size.height, minSize.height)
            panel.setFrame(frame, display: true, animate: true)
        }

        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        isVisible = true
    }

    func hide() {
        panel?.orderOut(nil)
        isVisible = false
    }

    private func makePanelIfNeeded() -> NSPanel {
        if let panel { return panel }

        let style: NSWindow.StyleMask = [.titled, .closable, .resizable, .fullSizeContentView]
        let initialFrame = initialWindowFrame()
        let panel = NSPanel(contentRect: initialFrame, styleMask: style, backing: .buffered, defer: true)
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.minSize = NSSize(width: 420, height: 520)
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true

        panel.delegate = self
        panel.collectionBehavior.insert(.fullScreenAuxiliary)

        let host = NSHostingController(rootView: StickyPanelView(viewModel: viewModel))
        panel.contentViewController = host

        self.panel = panel
        return panel
    }

    private func initialWindowFrame() -> NSRect {
        let minSize = CGSize(width: 420, height: 520)
        if let stored = settings.loadWindowFrame(), stored.width > 100, stored.height > 100 {
            if stored.width >= minSize.width, stored.height >= minSize.height {
                return stored
            }
            let clamped = NSRect(
                x: stored.origin.x,
                y: stored.origin.y,
                width: max(stored.size.width, minSize.width),
                height: max(stored.size.height, minSize.height)
            )
            return clamped
        }

        let margin: CGFloat = 18
        let size = CGSize(width: 560, height: 740)
        let visible = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1200, height: 800)
        let origin = CGPoint(
            x: max(visible.minX + margin, visible.maxX - size.width - margin),
            y: max(visible.minY + margin, visible.maxY - size.height - margin)
        )
        return NSRect(origin: origin, size: size)
    }

    private func applyWindowToggles() {
        guard let panel else { return }

        // Always-on-top is implemented via the window level.
        panel.level = settings.alwaysOnTop ? .floating : .normal

        // "All Spaces" is implemented via collection behavior.
        if settings.showOnAllSpaces {
            panel.collectionBehavior.insert(.canJoinAllSpaces)
        } else {
            panel.collectionBehavior.remove(.canJoinAllSpaces)
        }

        panel.isMovable = !settings.lockPanelPosition
        panel.isMovableByWindowBackground = !settings.lockPanelPosition

        if settings.lockPanelPosition {
            panel.styleMask.remove(.resizable)
        } else {
            panel.styleMask.insert(.resizable)
        }
    }

    func windowDidMove(_ notification: Notification) {
        persistFrame()
    }

    func windowDidEndLiveResize(_ notification: Notification) {
        persistFrame()
    }

    func windowWillClose(_ notification: Notification) {
        isVisible = false
        persistFrame()
    }

    private func persistFrame() {
        guard let frame = panel?.frame else { return }
        settings.saveWindowFrame(frame)
    }
}
