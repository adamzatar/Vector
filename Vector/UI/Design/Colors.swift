//
//  Colors.swift
//  Vector
//
//  Created by Adam Zaatar on 8/21/25.
//  File: UI/Design/Colors.swift
//

import SwiftUI

/// Centralized brand palette + helpers. Monochrome-first with subtle depth.
/// Keep names semantic so we can retune without touching call‑sites.
public enum BrandColor {
    // Core surfaces
    public static let surface         = Color("Surface", bundle: .main).fallback(light: .white, dark: .black)
    public static let surfaceSecondary = Color("SurfaceSecondary", bundle: .main).fallback(light: Color(white: 0.96), dark: Color(white: 0.12))
    public static let divider         = Color("Divider", bundle: .main).fallback(light: Color.black.opacity(0.08), dark: Color.white.opacity(0.14))
    public static let background: Color = BrandColor.surface
    // Foreground
    public static let primaryText     = Color("PrimaryText", bundle: .main).fallback(light: .black, dark: .white)
    public static let secondaryText   = Color("SecondaryText", bundle: .main).fallback(light: .gray,  dark: .gray)

    // Accents (used sparingly)
    public static let accent          = Color("Accent", bundle: .main).fallback(light: .black, dark: .white)

    // Tokens for TimeRing gradient (monochrome sweep)
    public static let ringStart = Color.white
    public static let ringMid1  = Color(white: 0.85)
    public static let ringMid2  = Color(white: 0.55)
    public static let ringEnd   = Color(white: 0.20)

    // Static monochrome values used in some places
    public static let white: Color    = .white
    public static let black: Color    = .black
    public static let silver: Color   = Color(white: 0.80)
    public static let gray: Color     = Color(white: 0.50)
    public static let charcoal: Color = Color(white: 0.15)
}

// MARK: - Gradients

/// Centralized gradient palette for brand backgrounds & accents.
public enum BrandGradient {
    /// The main gradient for onboarding/splash backgrounds.
    public static func primary() -> LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.blue.opacity(0.85),
                Color.purple.opacity(0.85)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Secondary gradient (optional, for cards or accent backgrounds).
    public static func secondary() -> LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.orange.opacity(0.85),
                Color.red.opacity(0.85)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// A subtle neutral gradient if you want variety in future themes.
    public static func neutral() -> LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.gray.opacity(0.5),
                Color.black.opacity(0.7)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }


        public static func wash() -> LinearGradient {
            LinearGradient(
                colors: [BrandColor.surface, BrandColor.background],
                startPoint: .top,
                endPoint: .bottom
            )
        }
}

// MARK: - Token color mapping

public extension BrandColor {
    /// Maps optional `TokenColor` to a visible label color.
    /// Kept as a single implementation to avoid duplicate symbol errors.
    static func tag(_ color: TokenColor?) -> Color {
        guard let color else { return BrandColor.silver }
        switch color {
        case .blue:   return Color.blue
        case .orange: return Color.orange
        case .green:  return Color.green
        case .purple: return Color.purple
        case .gray:   return Color.gray
        }
    }
}

// MARK: - Typography helpers

public extension Text {
    /// Applies a branded title weight/size.
    func brandTitle(_ size: TitleSize) -> some View {
        switch size {
        case .s: return self.font(Typography.titleS)
        case .m: return self.font(Typography.titleM)
        case .l: return self.font(Typography.titleL)
        }
    }

    enum TitleSize { case s, m, l }
}

// MARK: - Fallback loader

private extension Color {
    /// If named color asset is missing, fall back to provided light/dark colors.
    func fallback(light: Color, dark: Color) -> Color {
        #if canImport(UIKit)
        return Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
        #else
        return self
        #endif
    }
}
