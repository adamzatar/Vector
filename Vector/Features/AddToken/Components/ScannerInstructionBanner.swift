//
//  ScannerInstructionBanner.swift
//  Vector
//
//  Created by Adam Zaatar on 8/23/25.
//
//  File: Features/AddToken/Components/ScannerInstructionBanner.swift
//  A polished, accessible instruction pill for the QR scanner (or any camera flow).
//  - Dynamic Type ready
//  - Respects Reduce Motion
//  - Works on light/dark with branded styling
//

import SwiftUI
import Foundation

public struct ScannerInstructionBanner: View {
    public enum Emphasis { case standard, prominent }

    private let text: String
    private let subtitle: String?
    private let systemImage: String?
    private let emphasis: Emphasis

    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bounce = false

    public init(_ text: String,
                subtitle: String? = nil,
                systemImage: String? = "viewfinder",
                emphasis: Emphasis = .standard) {
        self.text = text
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.emphasis = emphasis
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
            if let systemImage {
                Image(systemName: systemImage)
                    .imageScale(.medium)
                    .font(.system(size: 16, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .accessibilityHidden(true)
                    .padding(.leading, 2)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                    .font(Typography.bodyS.weight(.semibold))
                    .foregroundStyle(fg)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(Typography.caption)
                        .foregroundStyle(fg.opacity(0.9))
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 0)

            // Gentle “hint” chevron bounce
            Image(systemName: "chevron.right")
                .imageScale(.small)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(fg.opacity(0.9))
                .offset(x: reduceMotion ? 0 : (bounce ? 2 : -2))
                .animation(reduceMotion ? nil :
                           .easeInOut(duration: 0.9).repeatForever(autoreverses: true),
                           value: bounce)
                .accessibilityHidden(true)
                .padding(.trailing, 2)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(background)
        .overlay(border)
        .clipShape(Capsule(style: .continuous))
        .shadow(color: .black.opacity(scheme == .dark ? 0.25 : 0.15),
                radius: 10, x: 0, y: 6)
        .onAppear { bounce = true }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Styling

    private var fg: Color {
        switch emphasis {
        case .standard:  return Color.white
        case .prominent: return Color.white
        }
    }

    private var background: some ShapeStyle {
        switch emphasis {
        case .standard:
            return AnyShapeStyle(
                LinearGradient(colors: [
                    .black.opacity(0.42),
                    .black.opacity(0.28)
                ], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
        case .prominent:
            return AnyShapeStyle(
                LinearGradient(colors: [
                    Color.black.opacity(0.55),
                    BrandColor.black.opacity(0.30)
                ], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
        }
    }

    private var border: some View {
        Capsule(style: .continuous)
            .stroke(BrandColor.white.opacity(0.16), lineWidth: 1)
    }
}

// MARK: - Convenience modifier

public extension View {
    /// Places a branded scanner instruction at the bottom safely above the home indicator.
    func scannerInstruction(_ text: String,
                            subtitle: String? = nil,
                            systemImage: String? = "viewfinder",
                            emphasis: ScannerInstructionBanner.Emphasis = .standard,
                            bottomPadding: CGFloat = 28) -> some View {
        self.overlay(
            ScannerInstructionBanner(text, subtitle: subtitle, systemImage: systemImage, emphasis: emphasis)
                .padding(.horizontal, Spacing.m)
                .padding(.bottom, bottomPadding),
            alignment: .bottom
        )
    }
}

// MARK: - Previews

#if DEBUG
struct ScannerInstructionBanner_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ZStack {
                Color.black.ignoresSafeArea()
                Rectangle()
                    .fill(LinearGradient(colors: [.black, .gray.opacity(0.6)], startPoint: .top, endPoint: .bottom))
                    .ignoresSafeArea()
            }
            .scannerInstruction("Point your camera at a QR code",
                                subtitle: "We’ll auto-detect otpauth://",
                                systemImage: "qrcode.viewfinder",
                                emphasis: .prominent)

            VStack { Spacer() }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(BrandColor.surface)
                .scannerInstruction("Hold steady", subtitle: "It only takes a second", systemImage: "hand.raised")
        }
        .preferredColorScheme(.dark)
        .previewLayout(.sizeThatFits)
    }
}
#endif
