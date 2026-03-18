import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var cameraService = CameraService()
    @StateObject private var multiCamService = MultiCamService()
    @StateObject private var subscriptionStore = SubscriptionStore()
    @StateObject private var userAccountStore = UserAccountStore()

    @State private var selectedMode: CaptureMode = .group
    @State private var selectedFilter: FilterPreset = .natural
    @State private var shutterPressed = false
    @State private var showMembershipSheet = false

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        GeometryReader { proxy in
            let isLargePhone = proxy.size.width >= 430
            let shutterSize: CGFloat = isLargePhone ? 94 : 82
            let previewScale = CGFloat(multiCamService.backLensScale)
            let pipScale = CGFloat(multiCamService.frontLensScale)

            ZStack {
                CameraPreviewView(session: cameraService.session)
                    .scaleEffect(previewScale)
                    .ignoresSafeArea()
                    .overlay(alignment: .topTrailing) {
                        if multiCamService.isDualCameraEnabled {
                            DualCameraPIPCard(scale: pipScale, statusText: multiCamService.statusText)
                                .padding(.top, isLargePhone ? 28 : 20)
                                .padding(.trailing, isLargePhone ? 18 : 12)
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                    }
                    .overlay {
                        LinearGradient(
                            colors: [.black.opacity(0.64), .clear, .black.opacity(0.82)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea()
                    }

                VStack(spacing: isLargePhone ? 14 : 10) {
                    topPanel
                    accountBanner
                    dualCameraPanel
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
                multiCamService.configureIfNeeded()
            }
            .task {
                await subscriptionStore.loadProducts()
                userAccountStore.markSubscribed(planID: subscriptionStore.activePlanID)
            }
            .onChange(of: subscriptionStore.activePlanID) { _, newValue in
                userAccountStore.markSubscribed(planID: newValue)
            }
            .onDisappear {
                cameraService.stopSession()
            }
            .sheet(isPresented: $showMembershipSheet) {
                MembershipSheet(store: subscriptionStore)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
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

    private var accountBanner: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(userAccountStore.profile.nickname) · \(userAccountStore.profile.membershipTag)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                Text("\(userAccountStore.profile.schoolName) · 云项目 \(userAccountStore.profile.cloudProjects) 个 · 可用席位 \(userAccountStore.profile.seatsAvailable)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.72))
            }

            Spacer()

            Button {
                showMembershipSheet = true
                Haptic.selection()
            } label: {
                Text(subscriptionStore.activePlanID == nil ? "开通会员" : "管理订阅")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.white, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var dualCameraPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("iPhone 17 Pro Max 双镜头导演模式")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                    Text(multiCamService.statusText)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.72))
                }

                Spacer()

                Toggle(isOn: Binding(
                    get: { multiCamService.isDualCameraEnabled },
                    set: { _ in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            multiCamService.toggleDualCamera()
                            selectedMode = multiCamService.isDualCameraEnabled ? .director : .group
                        }
                    }
                )) {
                    Text("双机位")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .toggleStyle(SwitchToggleStyle(tint: .white))
                .disabled(subscriptionStore.activePlanID == nil)
            }

            VStack(spacing: 10) {
                ratioRow(title: "前置画面占比", value: multiCamService.frontLensScale, range: 0.2...0.65) {
                    multiCamService.updateFrontLensScale($0)
                }

                ratioRow(title: "后置画面缩放", value: multiCamService.backLensScale, range: 0.75...1.2) {
                    multiCamService.updateBackLensScale($0)
                }
            }
            .opacity(subscriptionStore.activePlanID == nil ? 0.45 : 1)

            HStack(spacing: 10) {
                actionChip(
                    title: multiCamService.isRecording ? "停止同录" : "开始同录",
                    systemImage: multiCamService.isRecording ? "stop.circle.fill" : "record.circle"
                ) {
                    if multiCamService.isRecording {
                        multiCamService.stopRecording()
                    } else {
                        multiCamService.startRecording()
                    }
                    Haptic.heavy()
                }
                .disabled(subscriptionStore.activePlanID == nil)

                actionChip(title: "会员权益", systemImage: "crown.fill") {
                    showMembershipSheet = true
                }
            }
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .animation(.spring(response: 0.35, dampingFraction: 0.88), value: multiCamService.isDualCameraEnabled)
        .animation(.spring(response: 0.35, dampingFraction: 0.88), value: multiCamService.isRecording)
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

    private func ratioRow(title: String, value: Double, range: ClosedRange<Double>, onChanged: @escaping (Double) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(Int(value * 100))%")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.75))
            }

            Slider(value: Binding(get: { value }, set: { onChanged($0) }), in: range)
                .tint(.white)
        }
    }

    private func actionChip(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
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

private struct DualCameraPIPCard: View {
    let scale: CGFloat
    let statusText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.pink.opacity(0.9), Color.purple.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("前置画面")
                            .font(.system(size: 12, weight: .bold))
                        Text(statusText)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.72))
                    }
                    .foregroundStyle(.white)
                    .padding(12)
                }
                .frame(width: 104 + (scale * 70), height: 148 + (scale * 76))
                .shadow(color: .black.opacity(0.24), radius: 16, y: 12)
        }
        .padding(6)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct MembershipSheet: View {
    @ObservedObject var store: SubscriptionStore

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.black, Color.indigo.opacity(0.9)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("毕业照 Pro 会员")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    Text("适配 App Store 包月 / 包年自动续订，解锁双机位同录、模板商城与用户管理权益。")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.76))

                    ForEach(store.plans) { plan in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(plan.title)
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(.white)
                                    Text(plan.subtitle)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(.white.opacity(0.75))
                                }
                                Spacer()
                                Text(plan.highlight)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.white, in: Capsule())
                            }

                            HStack(alignment: .lastTextBaseline, spacing: 4) {
                                Text(plan.priceText)
                                    .font(.system(size: 28, weight: .heavy))
                                Text(plan.periodText)
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundStyle(.white)

                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(plan.features, id: \.self) { feature in
                                    Label(feature, systemImage: "checkmark.circle.fill")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(.white)
                                }
                            }

                            Button {
                                Task { await store.purchase(plan: plan) }
                            } label: {
                                Text(buttonTitle(for: plan))
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(18)
                        .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    }

                    Button("恢复购买") {
                        Task { await store.restorePurchases() }
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)

                    if let lastError = store.lastError {
                        Text(lastError)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.pink)
                    }
                }
                .padding(20)
            }
        }
    }

    private func buttonTitle(for plan: MembershipPlan) -> String {
        if store.activePlanID == plan.productID {
            return "当前生效中"
        }

        switch store.purchaseState {
        case .purchasing(let id) where id == plan.id:
            return "购买处理中..."
        case .pending(let id) where id == plan.id:
            return "等待确认中"
        case .success(let id) where id == plan.id:
            return "购买成功"
        default:
            return "立即开通"
        }
    }
}

enum CaptureMode: String, CaseIterable, Identifiable {
    case group
    case portrait
    case template
    case director

    var id: String { rawValue }

    var title: String {
        switch self {
        case .group: return "合影"
        case .portrait: return "人像"
        case .template: return "模板"
        case .director: return "双机位"
        }
    }

    var badgeText: String {
        switch self {
        case .group: return "多人合影优化"
        case .portrait: return "肤色优化预览"
        case .template: return "套版直出"
        case .director: return "前后镜头同录"
        }
    }
}

enum FilterPreset: String, CaseIterable, Identifiable {
    case natural
    case glow
    case film
    case warm
    case bw
    case neon

    var id: String { rawValue }

    var title: String {
        switch self {
        case .natural: return "原生"
        case .glow: return "清透"
        case .film: return "胶片"
        case .warm: return "暖阳"
        case .bw: return "黑白"
        case .neon: return "霓虹"
        }
    }

    var previewColor: Color {
        switch self {
        case .natural: return Color.gray
        case .glow: return Color.mint
        case .film: return Color.brown
        case .warm: return Color.orange
        case .bw: return Color.black
        case .neon: return Color.purple
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
