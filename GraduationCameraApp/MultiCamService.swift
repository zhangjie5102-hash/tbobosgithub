import AVFoundation
import Foundation
import SwiftUI

final class MultiCamService: ObservableObject {
    @Published var isDualCameraEnabled = false
    @Published var isRecording = false
    @Published var frontLensScale: Double = 0.35
    @Published var backLensScale: Double = 1.0
    @Published var isSupported = AVCaptureMultiCamSession.isMultiCamSupported
    @Published var statusText = "主镜头优先"

    let multiCamSession = AVCaptureMultiCamSession()

    func configureIfNeeded() {
        guard isSupported else {
            statusText = "当前设备不支持双机位同录"
            return
        }

        statusText = isDualCameraEnabled ? "双机位预览已启用" : "主镜头优先"
    }

    func toggleDualCamera() {
        guard isSupported else {
            statusText = "需要支持 MultiCam 的机型"
            return
        }

        isDualCameraEnabled.toggle()
        statusText = isDualCameraEnabled ? "双机位预览已启用" : "已切回单镜头模式"
    }

    func startRecording() {
        guard isDualCameraEnabled else {
            statusText = "请先开启双机位模式"
            return
        }

        isRecording = true
        statusText = "前后镜头正在同时录制"
    }

    func stopRecording() {
        isRecording = false
        statusText = "双机位录制已结束"
    }

    func updateFrontLensScale(_ value: Double) {
        frontLensScale = min(max(value, 0.2), 0.65)
    }

    func updateBackLensScale(_ value: Double) {
        backLensScale = min(max(value, 0.75), 1.2)
    }
}
