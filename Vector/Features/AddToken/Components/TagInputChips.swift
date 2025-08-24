//
//  TagInputChips.swift
//  Vector
//
//  Created by Adam Zaatar on 8/23/25.
//  File: Features/AddToken/Components/TagInputChips.swift
//

import Foundation
import SwiftUI

/// Compact tag editor with chips + text field.
/// - Binds directly to `[String]` so `AddTokenView` can store tags without extra glue.
/// - “Commit” delimiters: return, comma, or space. Deduplicates & trims.
/// - Uses adaptive grid so chips naturally wrap across lines.
public struct TagInputChips: View {
    public init(tags: Binding<[String]>,
                placeholder: String = "Add a tag and press return",
                minChipWidth: CGFloat = 72) {
        self._tags = tags
        self.placeholder = placeholder
        self.minChipWidth = minChipWidth
    }

    @Binding private var tags: [String]
    private let placeholder: String
    private let minChipWidth: CGFloat

    @State private var draft: String = ""
    @FocusState private var focused: Bool

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            if !tags.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: minChipWidth), spacing: Spacing.s)],
                          alignment: .leading, spacing: Spacing.s) {
                    ForEach(tags, id: \.self) { tag in
                        TagChip(label: tag) {
                            remove(tag)
                        }
                    }
                }
                .transition(.opacity.combined(with: .scale))
            }

            HStack(spacing: Spacing.s) {
                Image(systemName: "number")
                    .imageScale(.medium)
                    .foregroundStyle(.secondary)
                TextField(placeholder, text: $draft, axis: .vertical)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.default)
                    .focused($focused)
                    .onChange(of: draft) { _, new in
                        // Commit if user types a delimiter (comma/space/newline)
                        if let last = new.last, Self.commitDelimiters.contains(last) {
                            commitDraft()
                        }
                    }
                    .onSubmit { commitDraft() }
            }
            .padding(.horizontal, Spacing.s)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: Layout.smallCorner, style: .continuous)
                    .fill(BrandColor.surfaceSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Layout.smallCorner, style: .continuous)
                    .stroke(BrandColor.divider.opacity(0.6), lineWidth: 1)
            )
        }
        .animation(.easeInOut(duration: 0.15), value: tags)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Tags") // Localize
    }

    private static let commitDelimiters: Set<Character> = [",", " ", "\n"]

    private func commitDraft() {
        let cleaned = draft
            .replacingOccurrences(of: ",", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        draft = ""

        let parts = cleaned
            .components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        for p in parts {
            add(p)
        }
    }

    private func add(_ tag: String) {
        let normalized = tag.prefix(32) // keep tags short
        if !tags.contains(where: { $0.caseInsensitiveCompare(normalized) == .orderedSame }) {
            tags.append(String(normalized))
        }
    }

    private func remove(_ tag: String) {
        tags.removeAll { $0.caseInsensitiveCompare(tag) == .orderedSame }
    }
}

// MARK: - Chip

private struct TagChip: View {
    let label: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .font(Typography.caption)
                .lineLimit(1)
                .foregroundStyle(BrandColor.primaryText)
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .padding(6)
                    .background(.ultraThinMaterial, in: Circle())
                    .accessibilityLabel("Remove \(label)") // Localize
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, Spacing.s)
        .padding(.trailing, 4)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(BrandColor.surfaceSecondary)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(BrandColor.divider.opacity(0.6), lineWidth: 1)
        )
        .contentShape(Capsule())
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Preview

#if DEBUG
struct TagInputChips_Previews: PreviewProvider {
    struct Demo: View {
        @State var tags = ["prod", "infra", "urgent"]
        var body: some View {
            VStack(alignment: .leading, spacing: Spacing.m) {
                Text("Tags").font(Typography.titleS)
                TagInputChips(tags: $tags, placeholder: "Add tags…")
            }
            .padding()
            .background(BrandColor.surface)
            .preferredColorScheme(.dark)
        }
    }
    static var previews: some View { Demo() }
}
#endif
