import AVFoundation
import SwiftUI

/// Manages the AVFoundation capture session for scanning a card and taking a photo.
/// Gracefully reports when no camera is available (e.g. the simulator), so the UI
/// can fall back to the photo library.
@MainActor
final class CameraController: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "ca.estab.Pokedesk.camera")

    /// True once a camera input is wired up and the session is running.
    @Published var isConfigured = false
    /// True if the user denied camera access or no camera exists.
    @Published var isUnavailable = false

    private var captureContinuation: CheckedContinuation<UIImage?, Never>?

    /// Request permission and configure the session. Sets `isUnavailable` on failure.
    func prepare() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if !granted { isUnavailable = true; return }
        default:
            isUnavailable = true
            return
        }
        configureSession()
    }

    private func configureSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.session.beginConfiguration()
            self.session.sessionPreset = .photo

            guard
                let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
                    ?? AVCaptureDevice.default(for: .video),
                let input = try? AVCaptureDeviceInput(device: device),
                self.session.canAddInput(input)
            else {
                self.session.commitConfiguration()
                Task { @MainActor in self.isUnavailable = true }
                return
            }
            self.session.addInput(input)
            if self.session.canAddOutput(self.output) { self.session.addOutput(self.output) }
            self.session.commitConfiguration()
            self.session.startRunning()
            Task { @MainActor in self.isConfigured = true }
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    /// Capture a still photo. Returns nil if capture failed.
    func capturePhoto() async -> UIImage? {
        guard isConfigured else { return nil }
        return await withCheckedContinuation { continuation in
            self.captureContinuation = continuation
            let settings = AVCapturePhotoSettings()
            sessionQueue.async { [weak self] in
                self?.output.capturePhoto(with: settings, delegate: self!)
            }
        }
    }
}

extension CameraController: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        let image = photo.fileDataRepresentation().flatMap(UIImage.init(data:))
        Task { @MainActor in
            self.captureContinuation?.resume(returning: image)
            self.captureContinuation = nil
        }
    }
}

/// SwiftUI wrapper around `AVCaptureVideoPreviewLayer`.
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}

extension UIImage {
    /// CoreGraphics orientation matching this image's `imageOrientation`, for Vision.
    var cgImagePropertyOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
