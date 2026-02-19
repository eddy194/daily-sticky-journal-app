import SwiftUI

struct StickyPanelView: View {
    @ObservedObject var viewModel: DailyNoteEditorViewModel

    var body: some View {
        ZStack {
            VisualEffectView(material: .hudWindow, blendingMode: .withinWindow)
                .ignoresSafeArea()

            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.35))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
                .padding(10)

            VStack(alignment: .leading, spacing: 12) {
                header
                Divider().opacity(0.25)

                HighlightingTextView(text: $viewModel.content) {
                    viewModel.scheduleAutosave()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(22)
            .padding(.top, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Tasks -")
                    .font(.system(size: 22, weight: .bold))

                Label("Today", systemImage: "calendar")
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.cyan.opacity(0.18))
                    )
                    .foregroundStyle(Color.cyan)

                Spacer(minLength: 0)
            }

            Text(viewModel.titleText)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
    }
}
