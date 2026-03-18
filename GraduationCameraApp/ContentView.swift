import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var cameraService = CameraService()

    @State private var selectedMode: CaptureMode = .group
    @State private var selectedFilter: FilterPreset = .natural
    @State private var shutterPressed = false

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        GeometryReader { proxy in
            let isLargePhone = proxy.size.width >= 430
            let shutterSize: CGFloat = isLargePhone ? 94 : 82

            ZStack {
                CameraPreviewView(session: cameraService.session)
                    .ignoresSafeArea()
                    .overlay {
                        LinearGradient(
                            colors: [.black.opacity(0.62), .clear, .black.opacity(0.76)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea()
                    }

                VStack(spacing: isLargePhone ? 16 : 12) {
                    topPanel
                    Spacer()
                    filterBar
                    modeSwitcher
                    shutterBar(shutterSize: shutterSize)
                }
                .padding(.horizontal, isLargePhone ? 20 : 14)
                .padding(.top, 12)
                .padding(.bottom, isLargePhone ? 20 : 12)
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
    }

    private var topPanel: some View {
        HStack(spacing: 12) {
            glassButton(title: cameraService.flashModeText, systemImage: cameraService.flashIcon) {
                cameraService.toggleFlashMode()
                Haptic.impact()
            }

            Spacer()

            Text(selectedMode.badgeText)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())

            Spacer()

            glassButton(title: "翻转", systemImage: "arrow.triangle.2.circlepath.camera") {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                    cameraService.switchCamera()
                }
                Haptic.impact()
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(FilterPreset.allCases) { item in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFilter = item
                        }
                        Haptic.selection()
                    } label: {
                        VStack(spacing: 6) {
                            Circle()
                                .fill(item.previewColor)
                                .frame(width: 34, height: 34)
                                .overlay {
                                    if selectedFilter == item {
                                        Circle().stroke(Color.white, lineWidth: 2)
                                    }
                                }

                            Text(item.title)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .frame(width: 58)
                        .padding(.vertical, 6)
                        .background(selectedFilter == item ? Color.white.opacity(0.2) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 6)
        }
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: selectedFilter)
    }

    private var modeSwitcher: some View {
        HStack(spacing: 8) {
            ForEach(CaptureMode.allCases) { mode in
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                        selectedMode = mode
                    }
                    Haptic.selection()
                } label: {
                    Text(mode.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(selectedMode == mode ? .black : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            Group {
                                if selectedMode == mode {
                                    Color.white
                                } else {
                                    Color.white.opacity(0.12)
                                }
                            },
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .animation(.spring(response: 0.32, dampingFraction: 0.86), value: selectedMode)
    }

    private func shutterBar(shutterSize: CGFloat) -> some View {
        HStack {
            Spacer()

            Button {
                shutterPressed = true
                cameraService.capturePhoto()
                Haptic.heavy()

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    shutterPressed = false
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.25))
                        .frame(width: shutterSize + 16, height: shutterSize + 16)
                    Circle()
                        .fill(.white)
                        .frame(width: shutterSize, height: shutterSize)
                }
            }
            .scaleEffect(shutterPressed ? 0.93 : 1)
            .animation(.easeInOut(duration: 0.12), value: shutterPressed)

            Spacer()
        }
        .padding(.top, horizontalSizeClass == .regular ? 8 : 0)
    }

    private func glassButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(.ultraThinMaterial, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

enum CaptureMode: String, CaseIterable, Identifiable {
    case group
    case portrait
    case template

    var id: String { rawValue }

    var title: String {
        switch self {
        case .group: return "合影"
        case .portrait: return "人像"
        case .template: return "模板"
        }
    }

    var badgeText: String {
        switch self {
        case .group: return "多人合影优化"
        case .portrait: return "肤色优化预览"
        case .template: return "套版直出"
        }
    }
}

enum FilterPreset: String, CaseIterable, Identifiable {
    case natural
    case glow
    case film
    case warm
    case bw

    var id: String { rawValue }

    var title: String {
        switch self {
        case .natural: return "原生"
        case .glow: return "清透"
        case .film: return "胶片"
        case .warm: return "暖阳"
        case .bw: return "黑白"
        }
    }

    var previewColor: Color {
        switch self {
        case .natural: return Color.gray
        case .glow: return Color.mint
        case .film: return Color.brown
        case .warm: return Color.orange
        case .bw: return Color.black
        }
    }
}

enum Haptic {
    static func impact() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func heavy() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}

#Preview {
    ContentView()
}
