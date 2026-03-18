import AVFoundation
import Photos
import SwiftUI

final class CameraService: NSObject, ObservableObject {
    let session = AVCaptureSession()

    @Published var lastError: String?
    @Published private(set) var usingFrontCamera = false
    @Published private(set) var flashMode: AVCaptureDevice.FlashMode = .off

    private let output = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private var currentInput: AVCaptureDeviceInput?
    private var isConfigured = false

    var flashModeText: String {
        switch flashMode {
        case .off: return "闪光灯关"
        case .on: return "闪光灯开"
        case .auto: return "闪光灯自动"
        @unknown default: return "闪光灯"
        }
    }

    var flashIcon: String {
        switch flashMode {
        case .off: return "bolt.slash"
        case .on: return "bolt"
        case .auto: return "bolt.badge.a"
        @unknown default: return "bolt"
        }
    }

    func configureSession() {
        guard !isConfigured else { return }

        checkCameraPermission { [weak self] granted in
            guard let self, granted else {
                self?.publishError("未获得相机权限")
                return
            }

            self.sessionQueue.async {
                self.session.beginConfiguration()
                defer { self.session.commitConfiguration() }
                self.session.sessionPreset = .photo

                do {
                    let camera = try self.makeCamera(position: .back)
                    self.currentInput = camera
                    if self.session.canAddInput(camera) {
                        self.session.addInput(camera)
                    }

                    if self.session.canAddOutput(self.output) {
                        self.session.addOutput(self.output)
                    }

                    self.output.maxPhotoQualityPrioritization = .quality
                } catch {
                    self.publishError("初始化相机失败：\(error.localizedDescription)")
                }

                self.isConfigured = true
            }
        }
    }

    func startSession() {
        sessionQueue.async {
            guard !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    func stopSession() {
        sessionQueue.async {
            guard self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    func switchCamera() {
        sessionQueue.async {
            guard let currentInput = self.currentInput else { return }
            let newPosition: AVCaptureDevice.Position = currentInput.device.position == .back ? .front : .back

            do {
                let newInput = try self.makeCamera(position: newPosition)
                self.session.beginConfiguration()
                defer { self.session.commitConfiguration() }
                self.session.removeInput(currentInput)

                if self.session.canAddInput(newInput) {
                    self.session.addInput(newInput)
                    self.currentInput = newInput
                    DispatchQueue.main.async {
                        self.usingFrontCamera = (newPosition == .front)
                    }
                } else {
                    self.session.addInput(currentInput)
                }

            } catch {
                self.publishError("切换摄像头失败：\(error.localizedDescription)")
            }
        }
    }

    func toggleFlashMode() {
        let nextMode: AVCaptureDevice.FlashMode
        switch flashMode {
        case .off: nextMode = .on
        case .on: nextMode = .auto
        case .auto: nextMode = .off
        @unknown default: nextMode = .off
        }

        DispatchQueue.main.async {
            self.flashMode = nextMode
        }
    }

    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = flashMode
        output.capturePhoto(with: settings, delegate: self)
    }

    private func makeCamera(position: AVCaptureDevice.Position) throws -> AVCaptureDeviceInput {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) else {
            throw CameraError.cameraUnavailable
        }
        return try AVCaptureDeviceInput(device: device)
    }

    private func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video, completionHandler: completion)
        default:
            completion(false)
        }
    }

    private func savePhoto(_ data: Data) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                self.publishError("未获得相册权限，无法保存")
                return
            }

            PHPhotoLibrary.shared().performChanges {
                let request = PHAssetCreationRequest.forAsset()
                let options = PHAssetResourceCreationOptions()
                request.addResource(with: .photo, data: data, options: options)
            } completionHandler: { success, error in
                if !success {
                    self.publishError("保存照片失败：\(error?.localizedDescription ?? "未知错误")")
                }
            }
        }
    }

    private func publishError(_ message: String) {
        DispatchQueue.main.async {
            self.lastError = message
        }
    }
}

extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        if let error {
            publishError("拍照失败：\(error.localizedDescription)")
            return
        }

        guard let data = photo.fileDataRepresentation() else {
            publishError("图片数据为空")
            return
        }

        savePhoto(data)
    }
}

enum CameraError: Error {
    case cameraUnavailable
}
