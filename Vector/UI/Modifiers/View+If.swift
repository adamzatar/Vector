//
//  View+If.swift
//  Vector
//
//  Created by Adam Zaatar on 8/21/25.
//  File: UI/Modifiers/View+If.swift
//


import Foundation
import SwiftUI

/// Common lightweight view utilities used across Vector.
/// Keep access control consistent so these can be used from anywhere in the module.
public extension View {
    /// Conditionally applies a transform when `condition` is true.
    @ViewBuilder
    func `if`<Content: View>(
        _ condition: Bool,
        transform: (Self) -> Content
    ) -> some View {
        if condition { transform(self) } else { self }
    }

    /// Conditionally applies a transform when an optional value is non-nil.
    @ViewBuilder
    func ifLet<T, Content: View>(
        _ value: T?,
        transform: (Self, T) -> Content
    ) -> some View {
        if let value { transform(self, value) } else { self }
    }

    /// Ensures the tappable area is at least `size`×`size` (defaults to 44pt).
    func minTapTarget(_ size: CGFloat = 44) -> some View {
        modifier(MinimumTapTarget(size: size))
    }

    /// Applies a branded title style using our `Typography` scale.
    func brandTitle(_ size: BrandTitleSize) -> some View {
        modifier(BrandTitle(size: size))
    }
}

// MARK: - Backing modifiers (intentionally internal, not private)

struct MinimumTapTarget: ViewModifier {
    let size: CGFloat
    func body(content: Content) -> some View {
        content
            .frame(minWidth: size, minHeight: size, alignment: .center)
            .contentShape(Rectangle())
    }
}

public enum BrandTitleSize { case s, m, l, xl }

struct BrandTitle: ViewModifier {
    let size: BrandTitleSize
    func body(content: Content) -> some View {
        switch size {
        case .s:
            content.font(Typography.titleS).foregroundStyle(.primary)
        case .m:
            content.font(Typography.titleM).foregroundStyle(.primary)
        case .l:
            content.font(Typography.titleL).foregroundStyle(.primary)
        case .xl:
            content.font(Typography.titleXL).foregroundStyle(.primary)
        }
    }
}

// MARK: - Previews

#if DEBUG
struct ViewIf_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Vector").brandTitle(BrandTitleSize.xl)
            Text("Subtitle").brandTitle(BrandTitleSize.m)
            HStack {
                Image(systemName: "hand.tap")
                Text("Tap Target Demo")
            }
            .padding(8)
            .background(Color.gray.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
            .minTapTarget()
        }
        .padding()
        .background(BrandColor.surface)
        .previewLayout(.sizeThatFits)
        .preferredColorScheme(.dark)
    }
}
#endif
