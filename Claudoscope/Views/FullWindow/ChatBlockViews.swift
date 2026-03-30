import SwiftUI

// MARK: - Thinking Block

struct ThinkingBlockView: View {
    let text: String
    var searchText: String = ""
    @State private var isExpanded = false

    private var hasSearchMatch: Bool {
        guard !searchText.isEmpty else { return false }
        return text.localizedCaseInsensitiveContains(searchText)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: Motion.quick)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.tertiary)
                        .frame(width: 10)
                    Image(systemName: "brain")
                        .font(.system(size: 11))
                    Text("Thinking")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(.secondary)
                .padding(8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                ScrollView {
                    Text(text)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                }
                .frame(maxHeight: 400)
            }
        }
        .background(hasSearchMatch ? Color.yellow.opacity(0.08) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(Color.purple.opacity(0.4))
                .frame(width: 3)
        }
        .overlay(
            hasSearchMatch
                ? RoundedRectangle(cornerRadius: 6).strokeBorder(Color.yellow.opacity(0.4), lineWidth: 1)
                : nil
        )
        .onChange(of: searchText) { _, _ in
            if hasSearchMatch { isExpanded = true }
        }
    }
}

// MARK: - Tool Call Block

struct ToolCallBlockView: View {
    let toolName: String
    let input: [String: AnyCodableValue]
    let resultContent: String?
    let isError: Bool
    var searchText: String = ""
    @State private var isExpanded = false

    private var hasSearchMatch: Bool {
        guard !searchText.isEmpty else { return false }
        let query = searchText.lowercased()
        for (_, value) in input {
            if let str = value.stringValue, str.lowercased().contains(query) { return true }
        }
        if let result = resultContent, result.lowercased().contains(query) { return true }
        return false
    }

    private var toolCategoryColor: Color { categoryColor(for: toolName) }
    private var toolIconName: String { toolIcon(for: toolName) }
    private var primaryArg: String? { primaryArgument(from: input, toolName: toolName) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.tertiary)
                        .frame(width: 10)

                    Image(systemName: toolIconName)
                        .font(.system(size: 12))
                        .foregroundStyle(toolCategoryColor)

                    Text(toolName)
                        .font(Typography.bodyMedium)

                    if let arg = primaryArg {
                        Text(arg)
                            .font(Typography.code)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }

                    Spacer()

                    if isError {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.red)
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded, let result = resultContent {
                Divider()
                    .opacity(0.5)
                ScrollView {
                    Text(result)
                        .font(Typography.code)
                        .foregroundStyle(isError ? .red : .secondary)
                        .textSelection(.enabled)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 300)
                .background(Color.primary.opacity(0.03))
            }
        }
        .background(hasSearchMatch ? AnyShapeStyle(Color.yellow.opacity(0.08)) : AnyShapeStyle(.bar.opacity(0.5)))
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg)
                .strokeBorder(hasSearchMatch ? AnyShapeStyle(Color.yellow.opacity(0.4)) : AnyShapeStyle(.quaternary), lineWidth: hasSearchMatch ? 1.5 : 1)
        )
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(toolCategoryColor)
                .frame(width: 3)
                .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
        }
        .onChange(of: searchText) { _, _ in
            if hasSearchMatch { isExpanded = true }
        }
    }
}
