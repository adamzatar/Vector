//
//  CaptureShield1.1.swift
//  Vector
//
//  Created by Adam Zaatar on 8/21/25.
//  File: UI/Modifiers/CaptureShield.swift
//

import Foundation
import SwiftUI
import Combine

/// A modifier that overlays a blur/shield when screen capture (screenshot or recording)
/// is detected. Helps protect sensitive vault content.
/// - Default: enabled for release builds. In dev builds you can toggle off via FeatureFlags.
public struct CaptureShield: ViewModifier {
    @State private var isCaptured: Bool = UIScreen.main.isCaptured
    private let allowScreenshots: Bool

    public init(allowScreenshots: Bool = false) {
        self.allowScreenshots = allowScreenshots
    }

    public func body(content: Content) -> some View {
        ZStack {
            content
            if isCaptured && !allowScreenshots {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "eye.slash.fill")
                                .font(.title2)
                            Text("Screen recording detected") // Localize
                                .font(Typography.caption)
                        }
                        .foregroundStyle(.secondary)
                    )
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIScreen.capturedDidChangeNotification)) { _ in
            isCaptured = UIScreen.main.isCaptured
        }
    }
}

// MARK: - Convenience

public extension View {
    /// Applies a capture shield to the current view hierarchy.
    /// - Parameter allowScreenshots: pass true to disable shielding (e.g. dev/debug builds).
    func captureShielded(allowScreenshots: Bool = false) -> some View {
        modifier(CaptureShield(allowScreenshots: allowScreenshots))
    }
}

// MARK: - Preview

#if DEBUG
struct CaptureShield_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            Text("Vault Token").brandTitle(.m)
            Text("Sensitive OTP").font(Typography.body)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BrandColor.surface)
        .captureShielded()
        .preferredColorScheme(.dark)
    }
}
#endif
