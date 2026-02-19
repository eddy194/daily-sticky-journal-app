import AppKit
import Foundation

@MainActor
final class RolloverScheduler: NSObject {
    private let noteStore: NoteStore
    private var timer: Timer?
    private var lastDateKey: String?

    init(noteStore: NoteStore) {
        self.noteStore = noteStore
        super.init()
    }

    func start() {
        lastDateKey = DateKey.today()
        ensureTodayNoteExists()
        scheduleNextRollover()

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCalendarDayChanged),
            name: .NSCalendarDayChanged,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTimeZoneChanged),
            name: NSNotification.Name.NSSystemTimeZoneDidChange,
            object: nil
        )
    }

    private func ensureTodayNoteExists() {
        do {
            _ = try noteStore.getOrCreateTodayNote()
        } catch {
            NSLog("Failed to ensure today note exists: \(error)")
        }
    }

    private func scheduleNextRollover() {
        timer?.invalidate()

        let calendar = Calendar.current
        let now = Date()
        // Schedule for local midnight + a small buffer so we don't race clock changes at exactly 00:00:00.
        let next = calendar.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 0, second: 2),
            matchingPolicy: .nextTime
        ) ?? now.addingTimeInterval(24 * 60 * 60)

        let t = Timer(fireAt: next, interval: 0, target: self, selector: #selector(handleTimerFired), userInfo: nil, repeats: false)
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func checkForRollover(reason: String) {
        let today = DateKey.today()
        guard today != lastDateKey else {
            scheduleNextRollover()
            return
        }

        lastDateKey = today
        ensureTodayNoteExists()
        NotificationCenter.default.post(name: .dailyStickyJournalDidRollover, object: reason)
        scheduleNextRollover()
    }

    @objc private func handleTimerFired() {
        checkForRollover(reason: "timer")
    }

    @objc private func handleWake() {
        // Timers won't fire while asleep; on wake, verify whether the local day changed.
        checkForRollover(reason: "wake")
    }

    @objc private func handleCalendarDayChanged() {
        checkForRollover(reason: "calendarDayChanged")
    }

    @objc private func handleTimeZoneChanged() {
        checkForRollover(reason: "timeZoneChanged")
    }
}
