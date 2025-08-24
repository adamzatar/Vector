//
//  ScannerChrome.swift
//  Vector
//
//  Created by Adam Zaatar on 8/23/25.
//
//  ScannerChrome.swift
//  Vector
//
//  Created by Vector Team on 8/23/25.
//  File: Features/AddToken/Components/ScannerChrome.swift
//

import SwiftUI

// MARK: - Header (Close ◀︎  •  Brand Logo  •  Torch ▶︎)

public struct ScannerHeaderBar: View {
    let isTorchAvailable: Bool
    let isTorchOn: Bool
    let onClose: () -> Void
    let onToggleTorch: () -> Void

    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathe = false

    public init(
        isTorchAvailable: Bool,
        isTorchOn: Bool,
        onClose: @escaping () -> Void,
        onToggleTorch: @escaping () -> Void
    ) {
        self.isTorchAvailable = isTorchAvailable
        self.isTorchOn = isTorchOn
        self.onClose = onClose
        self.onToggleTorch = onToggleTorch
    }

    public var body: some View {
        ZStack(alignment: .top) {
            HStack {
                RoundedIconButton(system: "xmark") { onClose() }
                    .accessibilityLabel("Close") // Localize

                Spacer()

                if isTorchAvailable {
                    RoundedIconButton(system: isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill") {
                        onToggleTorch()
                    }
                    .accessibilityLabel(isTorchOn ? "Turn torch off" : "Turn torch on") // Localize
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            // Centered brand mark
            HStack {
                Spacer()
                BrandHeaderLogo()
                    .scaleEffect(breathe ? 1.0 : 0.96)
                    .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 6)
                    .onAppear {
                        guard !reduceMotion else { return }
                        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                            breathe = true
                        }
                    }
                    .accessibilityHidden(true)
                Spacer()
            }
            .padding(.top, 8)
            .allowsHitTesting(false)
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

// MARK: - Bottom hint / permissions CTA

public struct ScannerBottomBar: View {
    let permissionDenied: Bool
    let onOpenSettings: () -> Void

    public init(permissionDenied: Bool, onOpenSettings: @escaping () -> Void) {
        self.permissionDenied = permissionDenied
        self.onOpenSettings = onOpenSettings
    }

    public var body: some View {
        VStack(spacing: 10) {
            Text("Point your camera at a QR code") // Localize
                .font(Typography.body)
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.45), in: Capsule())

            if permissionDenied {
                Button {
                    onOpenSettings()
                } label: {
                    Text("Enable Camera in Settings") // Localize
                        .font(Typography.bodyS)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.45), in: Capsule())
                }
                .buttonStyle(.plain)
                .minTapTarget()
            }
        }
        .padding(.bottom, 28)
        .frame(maxHeight: .infinity, alignment: .bottom)
    }
}

// MARK: - Small building blocks

public struct RoundedIconButton: View {
    let system: String
    let action: () -> Void

    public init(system: String, action: @escaping () -> Void) {
        self.system = system
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: system)
                .foregroundStyle(.white)
                .padding(10)
                .background(Color.black.opacity(0.35), in: Circle())
        }
        .buttonStyle(.plain)
        .minTapTarget()
    }
}

public struct BrandHeaderLogo: View {
    @Environment(\.colorScheme) private var scheme

    public init() {}

    public var body: some View {
        // Prefer light asset over camera background; fall back to SF Symbol if missing.
        Group {
            if UIImage(named: scheme == .dark ? "VectorLight" : "VectorDark") != nil {
                Image(scheme == .dark ? "VectorLight" : "VectorDark")
                    .resizable()
                    .renderingMode(.original)
            } else {
                Image(systemName: "shield.lefthalf.fill")
                    .symbolRenderingMode(.hierarchical)
            }
        }
        .scaledToFit()
        .frame(width: 42, height: 42)
        .opacity(0.96)
    }
}

#if DEBUG
struct ScannerChrome_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack {
                ScannerHeaderBar(
                    isTorchAvailable: true,
                    isTorchOn: true,
                    onClose: {},
                    onToggleTorch: {}
                )
                Spacer()
                ScannerBottomBar(permissionDenied: false, onOpenSettings: {})
            }
        }
        .preferredColorScheme(.dark)
    }
}
#endif
