//
//  QRScannerViewModel.swift
//  Vector
//
//  Created by Adam Zaatar on 8/22/25.
//  File: Features/AddToken/ViewModels/QRScannerViewModel.swift
//

import Foundation
@preconcurrency import AVFoundation
import Combine
import UIKit

/// ViewModel that owns the camera session and scanning logic.
/// - All session graph mutations occur on `sessionQueue`.
/// - Debounces duplicate scan events; emits first stable value via `@Published scannedCode`.
@MainActor
final class QRScannerViewModel: NSObject, ObservableObject {
    // MARK: - Published UI State
    @Published var permissionDenied = false
    @Published var isTorchOn = false
    @Published var isTorchAvailable = false
    @Published var scannedCode: String?

    /// Exposed to SwiftUI preview layer. We mutate it **only** on `sessionQueue`.
    nonisolated(unsafe) let session: AVCaptureSession = AVCaptureSession()

    // MARK: - Private
    nonisolated private let sessionQueue = DispatchQueue(label: "camera.qr.session.queue", qos: .userInitiated)
    nonisolated private let debounce = ScanDebounce(interval: 1.0) // actor-backed, thread-safe

    // MARK: - Lifecycle

    /// Request permission, configure session once, and start running on the capture queue.
    func start() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if !granted { permissionDenied = true; return }
        default:
            permissionDenied = true
            return
        }

        configureSessionIfNeeded()

        sessionQueue.async { [weak self] in
            guard let self else { return }
            if !self.session.isRunning { self.session.startRunning() }
            self.updateTorchAvailability() // nonisolated (queues internally)
        }
    }

    /// Stop the session and ensure torch is off.
    func stop() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning { self.session.stopRunning() }
            self.setTorchLocked(on: false) // nonisolated (queues internally)
        }
    }

    // MARK: - Permission

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Torch (nonisolated wrappers that hop to sessionQueue)

    /// Toggle torch by computing the target on the main actor, then enqueueing work.
    func toggleTorch() {
        let target = !isTorchOn // main-actor read
        setTorchLocked(on: target) // enqueue to sessionQueue
    }

    /// Check torch availability safely on the session queue; publish result on main.
    nonisolated func updateTorchAvailability() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            let available = (self.videoDevice()?.hasTorch ?? false)
            Task { @MainActor in
                self.isTorchAvailable = available
            }
        }
    }

    /// Lock and set the torch on the capture device on the session queue, publish state on main.
    nonisolated func setTorchLocked(on: Bool) {
        sessionQueue.async { [weak self] in
            guard let self,
                  let device = self.videoDevice(),
                  device.hasTorch else { return }
            do {
                try device.lockForConfiguration()
                device.torchMode = on ? .on : .off
                device.unlockForConfiguration()
                Task { @MainActor in
                    self.isTorchOn = on
                }
            } catch {
                // Ignore torch failures for now; we could log if we wire a logger here.
            }
        }
    }

    // MARK: - Session Graph

    nonisolated private func videoDevice() -> AVCaptureDevice? {
        session.inputs.compactMap { $0 as? AVCaptureDeviceInput }.first?.device
    }

    private func configureSessionIfNeeded() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard self.session.inputs.isEmpty else { return }

            self.session.beginConfiguration()
            self.session.sessionPreset = .high
            defer { self.session.commitConfiguration() }

            // Input
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: device),
                  self.session.canAddInput(input) else {
                Task { @MainActor in self.permissionDenied = true }
                return
            }
            self.session.addInput(input)

            // Output
            let output = AVCaptureMetadataOutput()
            guard self.session.canAddOutput(output) else { return }
            self.session.addOutput(output)
            output.metadataObjectTypes = [.qr]
            output.setMetadataObjectsDelegate(self, queue: self.sessionQueue)

            self.updateTorchAvailability() // safe, nonisolated wrapper
        }
    }

    // MARK: - Emit (debounced safely via actor)

    nonisolated private func emit(_ string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        Task { [weak self] in
            guard let self else { return }
            let now = CACurrentMediaTime()
            if await debounce.shouldEmit(now: now) {
                await MainActor.run {
                    let gen = UINotificationFeedbackGenerator()
                    gen.notificationOccurred(.success)
                    self.scannedCode = trimmed
                }
            }
        }
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension QRScannerViewModel: AVCaptureMetadataOutputObjectsDelegate {
    nonisolated func metadataOutput(_ output: AVCaptureMetadataOutput,
                                    didOutput metadataObjects: [AVMetadataObject],
                                    from connection: AVCaptureConnection) {
        guard let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let str = obj.stringValue else { return }
        emit(str)
    }
}

// MARK: - Debounce helper (actor)

private actor ScanDebounce {
    private let interval: CFTimeInterval
    private var last: CFTimeInterval = 0

    init(interval: CFTimeInterval) { self.interval = interval }

    func shouldEmit(now: CFTimeInterval) -> Bool {
        if now - last > interval {
            last = now
            return true
        }
        return false
    }
}
