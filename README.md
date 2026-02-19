# DailyStickyJournal (macOS menubar app)

“Daily Sticky Journal” is a Sonoma+ (macOS 14+) menu bar app with an always-on-top sticky panel that shows **today’s note**, automatically rolls over at local midnight, and keeps a searchable, exportable history.

## Requirements
- macOS 14 (Sonoma) or later
- Xcode 15+ (SwiftUI)

## Build & Run
1. Open `DailyStickyJournal/DailyStickyJournal.xcodeproj` in Xcode.
2. Select the `DailyStickyJournal` scheme.
3. Set your Signing Team (Project → Target → Signing & Capabilities).
4. Run.

The app appears in the macOS menu bar (it does not show a Dock icon by default).

### Optional: command-line build
If you want to build from Terminal:
- Ensure Xcode is the active developer directory: `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`
- Build: `xcodebuild -project DailyStickyJournal/DailyStickyJournal.xcodeproj -scheme DailyStickyJournal -destination 'platform=macOS' build`

## Distribute (Archive + Signed .app)
To install the app into `/Applications` the “proper” way, create an Archive and export a signed `.app`:

1. In Xcode, select the `DailyStickyJournal` target.
2. Target → **Signing & Capabilities**:
   - Set a unique **Bundle Identifier** (e.g. `com.yourname.DailyStickyJournal`).
   - Select your **Team**.
3. In the toolbar, set the run destination to **Any Mac (Apple Silicon, Intel)** (or **My Mac**).
4. Menu: **Product → Archive**.
5. In **Organizer**, select the new archive → **Distribute App**:
   - For sharing outside your Mac: choose **Developer ID** (requires a Developer ID certificate).
   - For local use: **Copy App** is typically fine.
6. Export, then move `DailyStickyJournal.app` into `/Applications`.

Note: “Launch at login” works best once the app is installed in `/Applications` and signed.

## Using the app
- Menu bar → **Open Panel** shows the sticky panel (resizable).
- Menu bar → **Open History** opens the daily history window.
- Menu bar → **Settings…** lets you edit the template and toggles.

### Panel behavior
- **Always on top** uses a floating window level.
- **Show on all spaces** makes the panel join all Spaces (and appear over fullscreen apps).
- **Lock panel position** prevents moving/resizing.

### Template tokens
In Settings → Template, these tokens are replaced when a new day’s note is created:
- `{{date}}` → localized full date (current locale)
- `{{iso_date}}` → `YYYY-MM-DD`
- `{{weekday}}` → localized weekday name

### Export
History window:
- **Export Selected…** saves the selected day’s note as a `.txt` file.
- **Export All…** chooses a folder and writes `YYYY-MM-DD.txt` for every note.

## Notes (implementation)
- Persistence uses **Core Data** (local SQLite store in Application Support).
- Midnight rollover uses a timer scheduled for **local midnight + 2 seconds**, and also checks on **wake from sleep**.
- **Launch at login** uses `SMAppService.mainApp` (the system may prompt you to confirm).
