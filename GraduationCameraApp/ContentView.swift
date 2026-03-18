import SwiftUI

struct ContentView: View {
    @StateObject private var cameraService = CameraService()

    var body: some View {
        ZStack {
            CameraPreviewView(session: cameraService.session)
                .ignoresSafeArea()

            VStack {
                topBar
                Spacer()
                bottomBar
            }
            .padding()
        }
        .background(Color.black)
        .onAppear {
            cameraService.configureSession()
            cameraService.startSession()
        }
        .onDisappear {
            cameraService.stopSession()
        }
        .alert("相机错误", isPresented: Binding(
            get: { cameraService.lastError != nil },
            set: { if !$0 { cameraService.lastError = nil } }
        ), actions: {
            Button("确定") { cameraService.lastError = nil }
        }, message: {
            Text(cameraService.lastError ?? "未知错误")
        })
    }

    private var topBar: some View {
        HStack {
            Button {
                cameraService.toggleFlashMode()
            } label: {
                Label(cameraService.flashModeText, systemImage: cameraService.flashIcon)
                    .foregroundColor(.white)
            }

            Spacer()

            Button {
                cameraService.switchCamera()
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath.camera")
                    .font(.title2)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 8)
    }

    private var bottomBar: some View {
        HStack {
            Spacer()

            Button {
                cameraService.capturePhoto()
            } label: {
                ZStack {
                    Circle()
                        .stroke(Color.white, lineWidth: 5)
                        .frame(width: 80, height: 80)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 64, height: 64)
                }
            }

            Spacer()
        }
        .padding(.bottom, 12)
    }
}

#Preview {
    ContentView()
}
