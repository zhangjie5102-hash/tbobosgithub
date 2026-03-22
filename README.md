# 毕业合影相机（iOS 轻量版）方案

这是一款面向毕业季场景的 **轻量化 iOS 相机 App** 方案，重点满足：

- 主流相机能力（拍照、倒计时、前后摄切换、闪光灯、网格线）
- 常用滤镜（清新、人像、胶片、黑白、暖调）
- 多人合影优化（人脸检测、构图辅助、表情稳定抓拍）
- 多款毕业照模板（一键套版、校名/届别文案、比例导出）

## 1. 产品定位

- **目标用户**：毕业生、班级摄影组织者、校园社团运营。
- **核心价值**：不用复杂后期，现场快速拍出“可直接发圈”的毕业合影。
- **平台**：iOS 16+
- **设计原则**：启动快、操作少、模板直出。

## 2. MVP 功能清单

### 2.1 相机（主流能力）

- 拍照（后摄默认）
- 前后摄切换
- 闪光灯开/关/自动
- 3 秒/10 秒倒计时
- 4:3 与 1:1 取景比例
- 九宫格辅助线
- 连拍（多人合影场景）

### 2.2 滤镜

- 内置 8~12 款滤镜（基于 Core Image）
- 实时预览强度调节（0~100）
- 最近使用滤镜记忆

推荐默认滤镜分组：
- 毕业清新（肤色提亮）
- 青春胶片（轻颗粒、低饱和）
- 校园暖阳（暖色调）
- 经典黑白（高对比）

### 2.3 多人合影优化

- 最多识别 10 张人脸并提示是否有人被遮挡
- 人脸都看镜头时触发“智能抓拍建议”
- 边缘留白提示（避免裁切到头顶）
- 语音提示（“请再靠近一点”）

### 2.4 模板系统

- 提供 20+ 毕业照模板（横版、竖版、九宫格）
- 模板元素：校名、学院、届别、班级、日期
- 可替换主题色（校色）
- 一键导出到相册 / 微信分享

## 3. 信息架构（IA）

- **首页**：拍摄入口 / 模板入口 / 最近作品
- **相机页**：拍摄 + 滤镜 + 合影辅助
- **模板页**：模板选择、文字编辑、导出
- **作品页**：本地历史、二次编辑、分享
- **设置页**：清晰度、默认滤镜、隐私与权限

## 4. 技术实现建议（iOS）

- **UI**：SwiftUI（轻量、开发快）
- **相机**：AVFoundation（AVCaptureSession + Photo Output）
- **滤镜**：Core Image（CIFilter）
- **人脸检测**：Vision（VNDetectFaceRectanglesRequest）
- **本地存储**：PhotoKit + 本地 metadata（SQLite/CoreData）
- **性能目标**：
  - 冷启动 < 1.2s
  - 相机预览首帧 < 800ms
  - 滤镜切换延迟 < 120ms

## 5. 轻量化策略

- 首包控制在 **< 80MB**（模板资源分层加载）
- 模板素材 WebP / HEIF 压缩
- 按需下载高级模板包
- 预览图缓存 + LRU 回收机制
- 低端机自动降级滤镜实时强度

## 6. 推荐开发节奏（8 周）

- **第 1-2 周**：相机基础能力 + 拍照链路
- **第 3-4 周**：滤镜系统 + 实时预览
- **第 5-6 周**：多人合影辅助 + 模板引擎
- **第 7 周**：性能优化 + 崩溃监控 + 埋点
- **第 8 周**：TestFlight 灰度与修复

## 7. 首版埋点指标

- 相机页打开率
- 滤镜使用率 / Top3 滤镜
- 模板使用率 / 导出率
- 合影辅助开启率
- 次日留存、7 日留存

## 8. 可扩展方向（V2）

- AI 换天/去路人（可选云端）
- 班级协作相册
- 毕业院系专属模板商城
- 打印服务对接（冲印下单）

## 9. SwiftUI + AVFoundation 最小可运行代码骨架

代码位置：`GraduationCameraApp/`

包含以下核心文件：

- `GraduationCameraApp.swift`：应用入口
- `ContentView.swift`：相机 UI（预览、拍照按钮、闪光灯、前后摄切换）
- `CameraPreviewView.swift`：`AVCaptureVideoPreviewLayer` 包装
- `CameraService.swift`：相机配置、拍照、切摄像头、保存相册

### 9.1 在 Xcode 中快速运行

1. 新建 iOS App（SwiftUI，iOS 16+）项目。
2. 将 `GraduationCameraApp/` 下 4 个文件拖入项目并替换默认模板文件。
3. 在 `Info.plist` 增加权限文案：
   - `Privacy - Camera Usage Description`
   - `Privacy - Photo Library Additions Usage Description`
4. 使用真机运行（模拟器不支持真实摄像头拍摄流程）。

### 9.2 首版已具备能力

- 相机预览
- 拍照并保存到相册
- 前后摄切换
- 闪光灯模式切换（关/开/自动）
- 基础错误提示（权限/保存失败）

---

如果你愿意，我下一步可以继续补上：
1) 实时滤镜（Core Image）与滑杆强度；
2) 倒计时与连拍；
3) 多人合影辅助（Vision 人脸框 + 构图提示）;
4) 模板引擎（文字占位 + 一键导出）。


## 10. 最新 iOS 运营环境与 iPhone 17 Pro Max 适配基线（2026）

> 建议以 2026 年 App Store 提审要求为准：
>
> - App 提交需使用 **Xcode 26+**，并基于 **iOS 26 SDK+** 构建。
> - 生效时间：**2026-04-28**（见 Apple Developer Upcoming Requirements）。

### 10.1 工程与部署建议

- Deployment Target：建议 `iOS 26`（若需兼容老机型可降至 `iOS 18+`，但提审构建仍需 iOS 26 SDK）。
- 编译器：Swift 6.x（随 Xcode 26）。
- UI 框架：SwiftUI + AVFoundation + Vision。
- 分发：TestFlight（外部测试）→ App Store 上线。

### 10.2 iPhone 17 Pro Max 关键适配点

- 屏幕：**6.9 英寸**，分辨率 **2868 × 1320 @ 460 ppi**。
- 刷新率：最高 **120Hz ProMotion**。
- 设计策略：
  - 顶部/底部控件使用安全区与动态间距；
  - 主按钮与模式切换在大屏上放大 8%~14%；
  - 动效控制在 180~350ms，优先使用 spring 以提升“丝滑感”；
  - 保证深色背景下文本对比度（建议 >= 4.5:1）。

### 10.3 当前骨架已做的“年轻化 UI + 丝滑切换”

- 毛玻璃层（`ultraThinMaterial`）+ 渐变蒙层，视觉更接近社交相机。
- 模式切换（合影/人像/模板）增加弹簧动效。
- 滤镜条横向滚动 + 选中高亮动画。
- 快门按钮增加按压缩放反馈 + 触觉反馈。
- 按 `width >= 430` 自动切换为“大屏布局参数”，适配 iPhone 17 Pro Max。


## 11. 双镜头导演模式（适配 iPhone 17 Pro Max）

新增代码骨架：

- `MultiCamService.swift`：封装双机位状态、前后画面比例调节、同录状态。
- `ContentView.swift`：新增“导演模式 / 双机位”交互区，支持前置画面占比与后置画面缩放滑杆。

### 11.1 目标体验

- 在 iPhone 17 Pro Max 上启用前后摄同时取景/同录。
- 支持用户手动调节：
  - 前置画面占比（PIP 大小）
  - 后置主画面缩放比例
- 适合毕业照场景下的“导演视角 + 被拍者表情同步记录”。

### 11.2 当前代码骨架已覆盖

- `AVCaptureMultiCamSession.isMultiCamSupported` 能力判断。
- 双机位开关状态管理。
- 同录开始/停止按钮状态。
- 前后镜头画面比例滑杆。
- 右上角 PIP 预览卡片 UI。

> 说明：当前仓库仍是“可落地代码骨架”，若要真正完成前后摄同时写文件，需要在 Xcode 工程中继续接入 `AVCaptureMultiCamSession` 的 video/audio input、两个 output 与 file writer 流程。

## 12. 用户管理与付费模块（App Store 包月 / 包年）

新增代码骨架：

- `SubscriptionStore.swift`：基于 **StoreKit 2** 的自动续订订阅管理。
- `UserAccountStore.swift`：本地用户资料与席位状态管理骨架。
- `ContentView.swift`：新增会员入口、订阅弹层、恢复购买、权益态展示。

### 12.1 推荐订阅商品设计

- `com.graduationcamera.pro.monthly`：月卡
- `com.graduationcamera.pro.yearly`：年卡

### 12.2 月卡 / 年卡建议权益

- **月卡**：双机位同录、高级模板、4K 导出、云端作品管理
- **年卡**：月卡全部权益 + 团队席位管理、活动模板、优先客服

### 12.3 对接 App Store 的实现要点

- 使用 **StoreKit 2** 的 `Product.products(for:)` 拉取商品。
- 通过 `purchase()` 发起购买。
- 通过 `Transaction.currentEntitlements` 刷新当前有效权益。
- 提供 `AppStore.sync()` 恢复购买能力。
- 在 App Store Connect 中将月卡/年卡都配置为 **Auto-Renewable Subscriptions**。

### 12.4 用户管理建议

- 首版可采用：
  - Apple ID 购买身份 + 本地用户资料页
  - 服务端保存会员态快照、作品数、团队席位数
- 若后续上云协作：
  - 使用 Sign in with Apple 作为默认登录方案
  - 会员态由服务端二次校验，避免仅依赖本地缓存
