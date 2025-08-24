//
//  QRScanSheetTrigger.swift
//  Vector
//
//  Created by Adam Zaatar on 8/23/25.
//  File: Features/AddToken/Components/QRScanSheetTrigger.swift
//

import Foundation
import SwiftUI

/// A reusable scan CTA that presents the production QRScannerView as a sheet.
/// - Shows a branded primary button with a QR icon.
/// - Presents the full-screen scanner with torch + reticle + permission overlay.
/// - Forwards the scanned `otpauth://` URI (raw string) to the caller.
/// - Use this in AddTokenView (Scan / Import section), Settings, or elsewhere.
struct QRScanSheetTrigger: View {
    // MARK: - Inputs
    let title: String
    let autoDismiss: Bool
    let onParsedURI: (String) -> Void

    // MARK: - State
    @State private var showScanner = false

    // MARK: - Init
    init(
        title: String = "Scan QR",
        autoDismiss: Bool = true,
        onParsedURI: @escaping (String) -> Void
    ) {
        self.title = title
        self.autoDismiss = autoDismiss
        self.onParsedURI = onParsedURI
    }

    // MARK: - Body
    var body: some View {
        VStack(spacing: Spacing.s) {
            PrimaryButton(title, systemImage: "qrcode.viewfinder") {
                hapticLight()
                showScanner = true
            }
            .accessibilityHint("Opens the camera to scan an otpauth QR code.") // Localize

            Text("Scan secure otpauth:// codes from your accounts.")
                .font(Typography.caption)
                .foregroundStyle(.secondary)
        }
        .sheet(isPresented: $showScanner) {
            QRScannerView(autoDismiss: autoDismiss) { code in
                onParsedURI(code)
                hapticLight()
            }
            .preferredColorScheme(.dark)
        }
    }

    // MARK: - Helpers
    private func hapticLight() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}

#if DEBUG
struct QRScanSheetTrigger_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            QRScanSheetTrigger { _ in }
            QRScanSheetTrigger(title: "Rescan", autoDismiss: false) { _ in }
        }
        .padding()
        .background(BrandGradient.primary().ignoresSafeArea())
        .preferredColorScheme(.dark)
        .previewLayout(.sizeThatFits)
    }
}
#endif
