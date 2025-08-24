//
//  ScannerPreviewLayer.swift
//  Vector
//
//  Created by Adam Zaatar on 8/22/25.
//

import Foundation
import SwiftUI
@preconcurrency import AVFoundation

/// Thin UIKit bridge to display an `AVCaptureSession` in SwiftUI.
struct ScannerPreviewLayer: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let view = uiView as? PreviewView else { return }
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        view.videoPreviewLayer.frame = uiView.bounds
    }

    private final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}
