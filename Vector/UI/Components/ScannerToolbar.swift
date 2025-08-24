//
//  ScannerToolbar.swift
//  Vector
//
//  Created by Adam Zaatar on 8/23/25.
//  File: UI/Components/ScannerToolbar.swift
//

import SwiftUI

/// Reusable top HUD for the scanner (Close + Torch).
public struct ScannerToolbar: View {
    public let isTorchAvailable: Bool
    public let isTorchOn: Bool
    public let onClose: () -> Void
    public let onToggleTorch: () -> Void

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
        HStack {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Color.black.opacity(0.35), in: Circle())
                    .accessibilityLabel("Close") // Localize
            }
            .buttonStyle(.plain)
            .minTapTarget()

            Spacer()

            if isTorchAvailable {
                Button(action: onToggleTorch) {
                    Image(systemName: isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(Color.black.opacity(0.35), in: Circle())
                        .accessibilityLabel(Text(isTorchOn ? "Turn torch off" : "Turn torch on")) // Localize
                }
                .buttonStyle(.plain)
                .minTapTarget()
            }
        }
    }
}

#if DEBUG
struct ScannerToolbar_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(colors: [.black, .gray], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            ScannerToolbar(
                isTorchAvailable: true,
                isTorchOn: true,
                onClose: {},
                onToggleTorch: {}
            )
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .preferredColorScheme(.dark)
    }
}
#endif
