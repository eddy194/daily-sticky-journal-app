import SwiftUI

struct NoteEditorView: View {
    @ObservedObject var viewModel: NoteEditorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.titleText)
                .font(.title3.weight(.semibold))
                .textSelection(.enabled)

            HighlightingTextView(text: $viewModel.content) {
                viewModel.scheduleAutosave()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
