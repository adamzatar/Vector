//
//  Spacing.swift
//  Vector
//
//  Created by Adam Zaatar on 8/21/25.
//  File: UI/Design/Spacing.swift
//

import Foundation
import SwiftUI

/// Spacing scale and layout metrics for Vector.
/// Centralizes paddings, corner radii, and component dimensions so UI stays consistent.
/// - Usage:
///   VStack(spacing: Spacing.m) { … }
///   .padding(.horizontal, Spacing.l)
///   Card { … }.cornerRadius(Layout.cardCorner)
public enum Spacing {
    // MARK: - Core scale (8pt base with useful half steps)
    public static let xxs: CGFloat = 4
    public static let xs:  CGFloat = 8
    public static let s:   CGFloat = 12
    public static let m:   CGFloat = 16
    public static let l:   CGFloat = 24
    public static let xl:  CGFloat = 32
    public static let xxl: CGFloat = 40

    /// Returns a multiple of the base unit (8pt) to avoid ad-hoc numbers.
    /// Example: `Spacing.mul(3)` → 24pt.
    public static func mul(_ n: CGFloat) -> CGFloat { n * 8 }
}

/// Layout constants for common elements (cards, rows, buttons).
public enum Layout {
    // Corner radii
    public static let smallCorner: CGFloat = 10
    public static let cardCorner:  CGFloat = 14
    public static let bigCorner:   CGFloat = 20

    // Component sizing
    public static let rowMinHeight: CGFloat = 56
    public static let tapTargetMin: CGFloat = 44 // Apple HIG

    // Shadows
    public static let shadowRadiusSmall: CGFloat = 6
    public static let shadowRadiusMedium: CGFloat = 10

    // Grid spacing
    public static let gridH: CGFloat = Spacing.m
    public static let gridV: CGFloat = Spacing.m
}

// MARK: - EdgeInsets helpers

public extension EdgeInsets {
    /// Uniform insets.
    static func all(_ v: CGFloat) -> EdgeInsets { .init(top: v, leading: v, bottom: v, trailing: v) }

    /// Symmetric horizontal/vertical insets.
    static func hv(_ h: CGFloat, _ v: CGFloat) -> EdgeInsets { .init(top: v, leading: h, bottom: v, trailing: h) }

    /// Common presets for cards/sections.
    static var card: EdgeInsets { .hv(Spacing.m, Spacing.m) }
    static var section: EdgeInsets { .hv(Spacing.l, Spacing.m) }
}

// MARK: - View convenience

public extension View {
    /// Applies uniform brand padding.
    func brandPadding(_ value: CGFloat = Spacing.m) -> some View {
        padding(value)
    }
    
    /// Applies symmetric brand padding.
    func brandPadding(horizontal h: CGFloat = Spacing.m, vertical v: CGFloat = Spacing.m) -> some View {
        padding(.init(top: v, leading: h, bottom: v, trailing: h))
    }
    
}
