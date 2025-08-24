//
//  AddTokenTagCloud.swift
//  Vector
//
//  Created by Adam Zaatar on 8/23/25.
//  File: Features/AddToken/Components/AddTokenTagCloud.swift
//

import SwiftUI
import Foundation

/// Responsive, accessible tag cloud used to render parsed tags in Add Token (and elsewhere).
/// - Uses adaptive grid so chips wrap naturally.
/// - High-contrast pills aligned with Vector's surface/divider tokens.
/// - Non-interactive by default; opt-in tap callback for future edit flows.
/// - Safe for long tag lists; truncates gracefully.
///
/// Usage:
/// ```swift
/// AddTokenTagCloud(tags: vm.tags)
/// // or interactive:
/// AddTokenTagCloud(tags: vm.tags) { tapped in /* handle */ }
/// ```
public struct AddTokenTagCloud: View {
    public var tags: [String]
    public var onTap: ((String) -> Void)?

    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    public init(tags: [String], onTap: ((String) -> Void)? = nil) {
        self.tags = tags
        self.onTap = onTap
    }

    // Adaptive grid keeps the layout tidy across sizes & languages
    private var columns: [GridItem] {
        // Slightly larger min width when Dynamic Type is huge
        let min = typeSize.isAccessibilitySize ? 120.0 : 88.0
        return [GridItem(.adaptive(minimum: min), spacing: Spacing.s)]
    }

    public var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: Spacing.s) {
            ForEach(tags, id: \.self) { tag in
                TagChip(
                    title: tag,
                    onTap: onTap.map { cb in { cb(tag) } }
                )
            }
        }
        .accessibilityElement(children: .contain)
        .scaleEffect(reduceMotion ? 1.0 : (appeared ? 1.0 : 0.98))
        .opacity(appeared ? 1.0 : 0.0)
        .animation(reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.9), value: appeared)
        .onAppear { appeared = true }
    }
}

// MARK: - Tag Chip

private struct TagChip: View {
    let title: String
    let onTap: (() -> Void)?

    var body: some View {
        Group {
            if let onTap {
                Button(action: onTap) {
                    chipContent
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Tag \(title)"))
            } else {
                chipContent
                    .accessibilityLabel(Text("Tag \(title)"))
            }
        }
    }

    private var chipContent: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(Typography.caption)
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundStyle(BrandColor.primaryText)
            // Optional glyph for visual balance
            Image(systemName: "number")
                .imageScale(.small)
                .foregroundStyle(.secondary)
                .opacity(0.6)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, Spacing.s)
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
    }
}

// MARK: - Preview

#if DEBUG
struct AddTokenTagCloud_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text("Tags")
                .font(Typography.body)
                .foregroundStyle(BrandColor.primaryText)
            AddTokenTagCloud(tags: ["personal", "work", "prod", "staging", "infra", "apple", "cloud", "security"])
            AddTokenTagCloud(tags: ["very-long-tag-name-that-wraps"], onTap: { _ in })
        }
        .padding()
        .background(BrandColor.surface)
        .preferredColorScheme(.dark)
    }
}
#endif
