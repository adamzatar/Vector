//
//  FlowRow.swift
//  Vector
//
//  Created by Adam Zaatar on 8/21/25.
//  File: UI/Components/FlowRow.swift
//

// File: UI/Components/FlowRow.swift
import SwiftUI

/// A simple flow (wrap) layout that places subviews horizontally and wraps to the next line
/// when the current row would overflow the available width (like tag chips).
/// - Parameters:
///   - spacing: horizontal spacing between items
///   - rowSpacing: vertical spacing between rows
///   - alignment: horizontal alignment for each row (leading/center/trailing)
///
/// Usage:
/// ```swift
/// FlowRow(spacing: Spacing.s, rowSpacing: Spacing.s) {
///     ForEach(tags, id: \.self) { TagPill($0) }
/// }
/// .padding(.horizontal, Spacing.m)
/// ```
public struct FlowRow: SwiftUI.Layout {
    public var spacing: CGFloat
    public var rowSpacing: CGFloat
    public var alignment: HorizontalAlignment

    public init(spacing: CGFloat = Spacing.s,
                rowSpacing: CGFloat = Spacing.s,
                alignment: HorizontalAlignment = .leading) {
        self.spacing = spacing
        self.rowSpacing = rowSpacing
        self.alignment = alignment
    }

    // MARK: - Cache

    public struct Cache {
        var sizes: [CGSize] = []
    }

    public func makeCache(subviews: Subviews) -> Cache {
        Cache(sizes: Array(repeating: .zero, count: subviews.count))
    }

    public func updateCache(_ cache: inout Cache, subviews: Subviews) {
        // keep cache sized correctly
        if cache.sizes.count != subviews.count {
            cache.sizes = Array(repeating: .zero, count: subviews.count)
        }
    }

    // MARK: - Measuring

    public func sizeThatFits(proposal: ProposedViewSize,
                             subviews: Subviews,
                             cache: inout Cache) -> CGSize {
        let maxWidth = resolvedMaxWidth(from: proposal)

        // Measure each subview with an unconstrained height and up to maxWidth width.
        for (i, subview) in subviews.enumerated() {
            // Limit proposed width to maxWidth so very long items will measure reasonably.
            let proposed = ProposedViewSize(width: min(maxWidth, proposal.width ?? maxWidth),
                                            height: nil)
            cache.sizes[i] = subview.sizeThatFits(proposed)
        }

        // Compute rows
        var currentX: CGFloat = 0
        var currentRowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var isFirstInRow = true

        for size in cache.sizes {
            if isFirstInRow == false, currentX + spacing + size.width > maxWidth {
                // wrap
                totalHeight += currentRowHeight
                totalHeight += rowSpacing
                currentX = 0
                currentRowHeight = 0
                isFirstInRow = true
            }

            if !isFirstInRow { currentX += spacing }
            currentX += size.width
            currentRowHeight = max(currentRowHeight, size.height)
            isFirstInRow = false
        }

        // Add last row
        totalHeight += currentRowHeight

        // Width is constrained by container width if provided; otherwise natural width.
        let naturalWidth = min(maxWidth, max(currentX, cache.sizes.map(\.width).max() ?? 0))
        return CGSize(width: proposal.width ?? naturalWidth, height: totalHeight)
    }

    // MARK: - Placement

    public func placeSubviews(in bounds: CGRect,
                              proposal: ProposedViewSize,
                              subviews: Subviews,
                              cache: inout Cache) {
        let maxWidth = bounds.width
        var rows: [[(index: Int, size: CGSize)]] = [[]]
        var rowWidths: [CGFloat] = [0]
        var rowHeights: [CGFloat] = [0]

        // Build rows
        for (i, size) in cache.sizes.enumerated() {
            let wouldWrap = !rows.last!.isEmpty && (rowWidths.last! + spacing + size.width) > maxWidth
            if wouldWrap {
                rows.append([])
                rowWidths.append(0)
                rowHeights.append(0)
            }

            if !rows.last!.isEmpty { rowWidths[rowWidths.count - 1] += spacing }
            rows[rows.count - 1].append((i, size))
            rowWidths[rowWidths.count - 1] += size.width
            rowHeights[rowHeights.count - 1] = max(rowHeights.last ?? 0, size.height)
        }

        // Vertical cursor
        var y: CGFloat = bounds.minY

        for (rowIdx, row) in rows.enumerated() {
            guard !row.isEmpty else { continue }
            let rowHeight = rowHeights[rowIdx]
            let contentWidth = rowWidths[rowIdx]

            // Horizontal start based on alignment
            let startX: CGFloat
            switch alignment {
            case .leading:
                startX = bounds.minX
            case .trailing:
                startX = bounds.minX + (maxWidth - contentWidth)
            case .center:
                fallthrough
            default:
                startX = bounds.minX + (maxWidth - contentWidth) / 2
            }

            var x = startX
            for (index, size) in row {
                let point = CGPoint(x: x, y: y + (rowHeight - size.height) / 2)
                subviews[index].place(
                    at: point,
                    anchor: .topLeading,
                    proposal: ProposedViewSize(width: size.width, height: size.height)
                )
                x += size.width + spacing
            }

            y += rowHeight + rowSpacing
        }
    }

    // MARK: - Helpers

    private func resolvedMaxWidth(from proposal: ProposedViewSize) -> CGFloat {
        // If the parent supplies a width, use it. Otherwise assume a reasonable max width
        // so measurement is stable (use 800 as a sensible default for tags).
        proposal.width ?? 800
    }
}

// MARK: - Convenience View wrapper

public extension FlowRow {
    /// A convenience wrapper so you can use FlowRow like a container view.
    struct Container<Content: View>: View {
        let spacing: CGFloat
        let rowSpacing: CGFloat
        let alignment: HorizontalAlignment
        @ViewBuilder var content: Content

        public init(spacing: CGFloat = Spacing.s,
                    rowSpacing: CGFloat = Spacing.s,
                    alignment: HorizontalAlignment = .leading,
                    @ViewBuilder content: () -> Content) {
            self.spacing = spacing
            self.rowSpacing = rowSpacing
            self.alignment = alignment
            self.content = content()
        }

        public var body: some View {
            FlowRow(spacing: spacing, rowSpacing: rowSpacing, alignment: alignment) {
                content
            }
        }
    }
}
