import AVFoundation
import Photos
import SwiftUI
import UIKit

struct ImageLook {
    var style: NativeStyle
    var film: FilmPreset?
    var point: CGPoint
    var intensity: Double
    var exposure: Double
}

final class CameraModel: NSObject, ObservableObject {
    let session = AVCaptureSession()
    @Published var flashEnabled = false
    @Published var isRecording = false
    @Published var showPermissionAlert = false
    var look = ImageLook(style: .standard, film: nil, point: CGPoint(x: 0.5, y: 0.5), intensity: 0.75, exposure: 0)
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let photoOutput = AVCapturePhotoOutput()
    private var videoInput: AVCaptureDeviceInput?
    private var photoCompletion: ((Bool) -> Void)?

    @MainActor
    func requestAndStart() async {
        let cameraGranted = await AVCaptureDevice.requestAccess(for: .video)
        let micGranted = await AVCaptureDevice.requestAccess(for: .audio)
        let photoGranted = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard cameraGranted, micGranted, photoGranted == .authorized || photoGranted == .limited else {
            showPermissionAlert = true
            return
        }
        sessionQueue.async { self.configureSession() }
    }

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        if let input = try? AVCaptureDeviceInput(device: AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)!) {
            if session.canAddInput(input) {
                session.addInput(input)
                videoInput = input
            }
        }
        if session.canAddOutput(photoOutput) { session.addOutput(photoOutput) }
        session.commitConfiguration()
        session.startRunning()
    }

    func toggleFlash() {
        flashEnabled.toggle()
    }

    func flipCamera() {
        sessionQueue.async {
            guard let current = self.videoInput else { return }
            self.session.beginConfiguration()
            self.session.removeInput(current)
            let position: AVCaptureDevice.Position = current.device.position == .back ? .front : .back
            if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
               let next = try? AVCaptureDeviceInput(device: device), self.session.canAddInput(next) {
                self.session.addInput(next)
                self.videoInput = next
            } else {
                self.session.addInput(current)
            }
            self.session.commitConfiguration()
        }
    }

    func capture(look: ImageLook, completion: @escaping (Bool) -> Void) {
        self.look = look
        photoCompletion = completion
        let settings = AVCapturePhotoSettings()
        if flashEnabled, let device = videoInput?.device, device.hasFlash {
            settings.flashMode = .on
        }
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func stopRecording() {
        // Video recording is intentionally not represented as working until AVAssetWriter
        // output and synchronized filtered audio/video have been implemented and tested.
        DispatchQueue.main.async { self.isRecording = false }
    }

    func openLatestPhoto() {
        if let url = URL(string: "photos-redirect://") {
            UIApplication.shared.open(url)
        }
    }
}

extension CameraModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil, let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data), let cgImage = image.cgImage else {
            DispatchQueue.main.async { self.photoCompletion?(false); self.photoCompletion = nil }
            return
        }
        let ciImage = CIImage(cgImage: cgImage)
        let filtered = FilterEngine.apply(ciImage, look: look)
        let context = CIContext()
        guard let outputCG = context.createCGImage(filtered, from: filtered.extent) else {
            DispatchQueue.main.async { self.photoCompletion?(false); self.photoCompletion = nil }
            return
        }
        let finalImage = UIImage(cgImage: outputCG, scale: image.scale, orientation: image.imageOrientation)
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: finalImage)
        }) { success, _ in
            DispatchQueue.main.async { self.photoCompletion?(success); self.photoCompletion = nil }
        }
    }
}
