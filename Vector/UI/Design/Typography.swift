//
//  Typography.swift
//  Vector
//
//  Created by Adam Zaatar on 8/21/25.
//  File: UI/Design/Typography.swift
//

import Foundation
import SwiftUI

/// Typography scale for Vector with Dynamic Type and accessibility in mind.
/// Use these helpers instead of hard-coded fonts to keep consistency across the app.
///
/// Example:
/// ```swift
/// Text("Vector").font(Typography.titleXL.bold())
/// Text("Section").font(Typography.titleM)
/// Text("Body text").font(Typography.body)
/// Text("Code 123456").font(Typography.monoM)
/// ```
public enum Typography {
    // MARK: - Display / Titles

    /// Extra‑large, prominent title (marketing/hero headers).
    public static var titleXL: Font {
        // Maps to .largeTitle with slight size bump for emphasis.
        .system(size: 34, weight: .bold, design: .rounded) // scales with Dynamic Type
    }

    /// Large section/page titles.
    public static var titleL: Font {
        .system(.title, design: .rounded).weight(.semibold)
    }

    /// Medium section titles / card headers.
    public static var titleM: Font {
        .system(.title2, design: .rounded).weight(.semibold)
    }

    /// Small section titles / list headers.
    public static var titleS: Font {
        .system(.title3, design: .rounded).weight(.semibold)
    }

    // MARK: - Body / Supporting

    /// Primary body text for paragraphs and labels.
    public static var body: Font {
        .system(.body, design: .rounded)
    }

    /// Secondary body text; slightly smaller than body.
    public static var bodyS: Font {
        .system(.callout, design: .rounded)
    }

    /// Caption text for metadata, timestamps, hints.
    public static var caption: Font {
        .system(.caption, design: .rounded)
    }

    /// Tiny caption for footers / legalese (use sparingly).
    public static var caption2: Font {
        .system(.caption2, design: .rounded)
    }

    // MARK: - Monospaced (OTP / codes)

    /// Monospaced font for OTP codes (prominent).
    public static var monoL: Font {
        // Slightly larger for readability; monospaced ensures stable layout per digit tick.
        .system(size: 22, weight: .semibold, design: .monospaced)
    }

    /// Monospaced for inline code/technical labels.
    public static var monoM: Font {
        .system(size: 17, weight: .medium, design: .monospaced)
    }

    /// Small monospaced for metadata badges.
    public static var monoS: Font {
        .system(size: 14, weight: .regular, design: .monospaced)
    }
}

// MARK: - Semantic Modifiers

/// A lightweight title style that applies consistent font and accessibility traits.
public struct BrandTitleStyle: ViewModifier {
    private let level: Level

    public enum Level {
        case xl, l, m, s
    }

    public init(_ level: Level) { self.level = level }

    public func body(content: Content) -> some View {
        content
            .font({
                switch level {
                case .xl: return Typography.titleXL
                case .l:  return Typography.titleL
                case .m:  return Typography.titleM
                case .s:  return Typography.titleS
                }
            }())
            .accessibilityAddTraits(.isHeader)
    }
}

public extension View {
    /// Apply a brand title style with Dynamic Type support and header traits.
    func brandTitle(_ level: BrandTitleStyle.Level = .l) -> some View {
        modifier(BrandTitleStyle(level))
    }
}
