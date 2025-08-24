//
//  TagEditorRow.swift
//  Vector
//
//  Created by Adam Zaatar on 8/23/25.
//  File: Features/AddToken/Components/TagEditorRow.swift
//

import SwiftUI

/// A polished tag editor row used by AddTokenView to collect user labels.
/// - Displays existing tags as removable chips.
/// - Provides a single-line text field that accepts comma/space separated entries.
/// - Prevents duplicates; trims whitespace; lowercases for compare but preserves original case.
/// - Respects Dynamic Type and Reduce Motion.
/// - Uses Vector design system (Typography, Spacing, BrandColor).
struct TagEditorRow: View {
    // MARK: - Inputs
    let title: String?
    let placeholder: String
    @Binding var tags: [String]

    /// Optional validation for new tags (e.g., length caps). Return nil to accept.
    var validate: ((String) -> String?)? = nil

    // MARK: - State
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var draft: String = ""
    @State private var errorText: String?

    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                Text(title)
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityAddTraits(.isHeader)
            }

            // Input field
            HStack(spacing: 8) {
                TextField(placeholder, text: $draft, onCommit: commitDraft)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(Typography.body)
                    .submitLabel(.done)
                    .onChange(of: draft) { _, newValue in
                        // If user typed delimiter, split immediately
                        if newValue.contains(",") || newValue.contains(" ") {
                            commitDraft()
                        }
                    }

                Button {
                    commitDraft()
                } label: {
                    Image(systemName: "plus")
                        .imageScale(.medium)
                        .padding(8)
                        .background(Circle().fill(BrandColor.surfaceSecondary))
                }
                .buttonStyle(.plain)
                .minTapTarget()
                .accessibilityLabel("Add tag") // Localize
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(BrandColor.surfaceSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(BrandColor.divider.opacity(0.7), lineWidth: 1)
            )

            // Chips
            if !tags.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: Spacing.s)], alignment: .leading, spacing: Spacing.s) {
                    ForEach(tags, id: \.self) { tag in
                        TagChip(text: tag) {
                            withSmallAnim { remove(tag) }
                        }
                    }
                }
                .transition(.opacity)
                .padding(.top, 2)
            }

            if let errorText, !errorText.isEmpty {
                Text(errorText)
                    .font(Typography.caption)
                    .foregroundStyle(.red)
                    .transition(.opacity)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.12), value: tags)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.12), value: errorText)
        .accessibilityElement(children: .contain)
    }

    // MARK: - Actions

    private func commitDraft() {
        let separators = CharacterSet(charactersIn: ", ")
        let parts = draft
            .split(whereSeparator: { $0.unicodeScalars.contains { separators.contains($0) } })
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !parts.isEmpty else {
            validateAndMaybeShowError("")
            return
        }

        var addedAny = false
        for p in parts {
            if validateAndMaybeShowError(p) == false { continue }
            if insertUnique(p) { addedAny = true }
        }

        if addedAny { hapticLight() }
        draft.removeAll()
    }

    @discardableResult
    private func insertUnique(_ raw: String) -> Bool {
        let key = raw.lowercased()
        let existing = Set(tags.map { $0.lowercased() })
        guard !existing.contains(key) else { return false }
        withSmallAnim { tags.append(raw) }
        return true
    }

    private func remove(_ tag: String) {
        if let idx = tags.firstIndex(of: tag) {
            tags.remove(at: idx)
            hapticLight()
        }
    }

    /// Returns true if valid (no error shown), false if error displayed.
    @discardableResult
    private func validateAndMaybeShowError(_ s: String) -> Bool {
        if let validate, let msg = validate(s) {
            errorText = msg
            return false
        } else {
            errorText = nil
            return true
        }
    }

    // MARK: - Helpers

    private func withSmallAnim(_ changes: () -> Void) {
        if reduceMotion { changes(); return }
        withAnimation(.easeInOut(duration: 0.12), changes)
    }

    private func hapticLight() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}

// MARK: - Chip

private struct TagChip: View {
    let text: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(text)
                .font(Typography.caption)
                .foregroundStyle(BrandColor.primaryText)
                .lineLimit(1)

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .padding(6)
                    .background(Circle().fill(BrandColor.surfaceSecondary.opacity(0.8)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(text)") // Localize
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
                .stroke(BrandColor.divider.opacity(0.7), lineWidth: 1)
        )
    }
}

// MARK: - Previews

#if DEBUG
struct TagEditorRow_Previews: PreviewProvider {
    struct Demo: View {
        @State var tags = ["Security", "Work", "AWS"]
        var body: some View {
            VStack(spacing: 16) {
                TagEditorRow(
                    title: "Tags",
                    placeholder: "Add tags (comma/space separated)",
                    tags: $tags,
                    validate: { value in
                        if value.count > 20 { return "Keep tags under 20 characters." }
                        return nil
                    }
                )
            }
            .padding()
            .background(BrandGradient.primary().ignoresSafeArea())
            .preferredColorScheme(.dark)
        }
    }
    static var previews: some View { Demo().previewLayout(.sizeThatFits) }
}
#endif
