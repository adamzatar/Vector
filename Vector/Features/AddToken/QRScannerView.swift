//
//  QRScannerView.swift
//  Vector
//
//  Created by Adam Zaatar on 8/21/25.
//  File: Features/AddToken/QRScannerView.swift
//


import AVFoundation
import Foundation
import SwiftUI
import Combine

/// Production-ready QR scanner tailored for `otpauth://` URIs.
/// - Pass `onScanned` to receive the first debounced code (main thread).
/// - `autoDismiss` closes the sheet automatically after a successful scan.
/// - Composed from scanner components (toolbar, reticle, tips, instruction banner).
struct QRScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = QRScannerViewModel()

    let autoDismiss: Bool
    let onScanned: (String) -> Void

    init(autoDismiss: Bool = true, onScanned: @escaping (String) -> Void) {
        self.autoDismiss = autoDismiss
        self.onScanned = onScanned
    }

    var body: some View {
        ZStack {
            // Camera preview
            ScannerPreviewLayer(session: vm.session)
                .ignoresSafeArea()

            // Dim with cut-out reticle
            ReticleOverlay()
                .allowsHitTesting(false)

            // Top toolbar (Close + Torch)
            ScannerToolbar(
                isTorchAvailable: vm.isTorchAvailable,
                isTorchOn: vm.isTorchOn,
                onClose: { dismiss() },
                onToggleTorch: { vm.toggleTorch() }
            )
            .padding(Edge.Set.horizontal, 16)
            .padding(Edge.Set.top, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            // Bottom: branded tips
            VStack(spacing: 10) {
                ScanTroubleshootTips()
                    .padding(.bottom, 6)
            }
            .padding(Edge.Set.horizontal, 16)
            .padding(.bottom, 90) // leave room for the instruction pill
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)

            if vm.permissionDenied {
                PermissionOverlay()
            }
        }
        .task { await vm.start() }
        .onReceive(vm.$scannedCode.compactMap { $0 }.removeDuplicates()) { code in
            onScanned(code)
            if autoDismiss { dismiss() }
        }
        .onDisappear { vm.stop() }
        .statusBarHidden(true)
        // Branded, accessible instruction pill overlay
        .scannerInstruction(
            "Point your camera at a QR code",         // Localize
            subtitle: "We’ll auto-detect otpauth://", // Localize
            systemImage: "qrcode.viewfinder",
            emphasis: .prominent,
            bottomPadding: 28
        )
        // Subtle animated logo at top center
        .appHeaderLogoOverlay(size: 44, topPadding: 8)
    }
}

#if DEBUG
struct QRScannerView_Previews: PreviewProvider {
    static var previews: some View {
        QRScannerView { _ in }
            .preferredColorScheme(.dark)
    }
}
#endif
