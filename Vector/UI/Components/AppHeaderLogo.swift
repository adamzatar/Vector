//
//  AppHeaderLogo.swift
//  Vector
//
//  Created by Adam Zaatar on 8/23/25.
//
// ===============================
// File: UI/Components/AppHeaderLogo.swift
// (Reusable animated logo header you can overlay on ANY screen.)
// ===============================


import Foundation
import SwiftUI

// MARK: - Core animated mark (keeps your existing behavior)

public struct AppHeaderLogo: View {
    public init(size: CGFloat = 56, showGlow: Bool = true) {
        self.size = size; self.showGlow = showGlow
    }

    private let size: CGFloat
    private let showGlow: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var scheme
    @State private var pulse = false
    @State private var spin = false

    public var body: some View {
        ZStack {
            if showGlow {
                Circle()
                    .strokeBorder(haloGradient, lineWidth: 2)
                    .frame(width: size * 2.0, height: size * 2.0)
                    .opacity(0.7)
                    .rotationEffect(.degrees(spin ? 360 : 0))
                    .animation(reduceMotion ? nil :
                               .linear(duration: 8.0).repeatForever(autoreverses: false),
                               value: spin)

                Circle()
                    .fill(BrandColor.white.opacity(scheme == .dark ? 0.10 : 0.18))
                    .frame(width: size * 1.35, height: size * 1.35)
                    .opacity(reduceMotion ? 0.34 : (pulse ? 0.52 : 0.34))
                    .scaleEffect(reduceMotion ? 1.0 : (pulse ? 1.06 : 0.96))
                    .animation(reduceMotion ? nil :
                               .easeInOut(duration: 1.6).repeatForever(autoreverses: true),
                               value: pulse)
            }

            if let uiImage = UIImage(named: "LaunchLogo") {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .accessibilityLabel("Vector") // Localize
            } else {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: size, weight: .bold))
                    .accessibilityLabel("Vector") // Localize
            }
        }
        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
        .onAppear { pulse = true; spin = true }
    }

    private var haloGradient: AngularGradient {
        AngularGradient(
            colors: [
                BrandColor.ringStart.opacity(0.9),
                BrandColor.ringMid1.opacity(0.8),
                BrandColor.ringMid2.opacity(0.7),
                BrandColor.ringEnd.opacity(0.8),
                BrandColor.ringStart.opacity(0.9)
            ],
            center: .center
        )
    }
}

// MARK: - Header section (logo + optional title/subtitle)

public struct AppHeader: View {
    public enum Size { case small, medium, large }
    public enum Layout { case centered, leading }

    private let size: Size
    private let layout: Layout
    private let title: String?
    private let subtitle: String?
    private let showGlow: Bool

    public init(size: Size = .medium,
                layout: Layout = .centered,
                title: String? = nil,
                subtitle: String? = nil,
                showGlow: Bool = true) {
        self.size = size
        self.layout = layout
        self.title = title
        self.subtitle = subtitle
        self.showGlow = showGlow
    }

    public var body: some View {
        Group {
            switch layout {
            case .centered:
                VStack(spacing: Spacing.s) {
                    AppHeaderLogo(size: px, showGlow: showGlow)
                    texts(alignment: .center)
                }
                .frame(maxWidth: .infinity)

            case .leading:
                HStack(spacing: Spacing.m) {
                    AppHeaderLogo(size: px, showGlow: showGlow)
                    texts(alignment: .leading)
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(.vertical, Spacing.m)
        .accessibilityElement(children: .combine)
    }

    private var px: CGFloat {
        switch size {
        case .small: 32
        case .medium: 44
        case .large: 56
        }
    }

    @ViewBuilder
    private func texts(alignment: TextAlignment) -> some View {
        VStack(spacing: 4) {
            if let title, !title.isEmpty {
                Text(title)
                    .font(Typography.titleM)
                    .foregroundStyle(BrandColor.primaryText)
                    .multilineTextAlignment(alignment)
                    .accessibilityAddTraits(.isHeader)
            }
            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(alignment)
            }
        }
    }
}

// MARK: - Convenience modifiers

public extension View {
    /// Overlay just the animated logo at the top center.
    func appHeaderLogoOverlay(size: CGFloat = 48, topPadding: CGFloat = 10) -> some View {
        overlay(
            AppHeaderLogo(size: size)
                .padding(.top, topPadding),
            alignment: .top
        )
    }

    /// Inserts a full header section (logo + optional copy) above your content.
    func vectorHeader(size: AppHeader.Size = .medium,
                      layout: AppHeader.Layout = .centered,
                      title: String? = nil,
                      subtitle: String? = nil,
                      showGlow: Bool = true) -> some View {
        VStack(spacing: 0) {
            AppHeader(size: size, layout: layout, title: title, subtitle: subtitle, showGlow: showGlow)
            self
        }
    }
}

// MARK: - Previews

#if DEBUG
struct AppHeaderLogo_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack(spacing: 24) {
                AppHeaderLogo(size: 56)
                AppHeader(size: .large, layout: .centered, title: "Vector", subtitle: "Privacy-first 2FA")
                AppHeader(size: .small, layout: .leading, title: "Add Token", subtitle: "Scan or enter manually")
            }
            .padding()
            .background(BrandGradient.primary().ignoresSafeArea())
            .preferredColorScheme(.dark)

            VStack {
                Text("Content below…")
                    .font(Typography.body)
                    .foregroundStyle(BrandColor.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .vectorHeader(size: .medium, layout: .centered, title: "Settings", subtitle: "Security & Backups")
            .background(BrandColor.surface)
            .preferredColorScheme(.light)
        }
        .previewLayout(.sizeThatFits)
    }
}
#endif
