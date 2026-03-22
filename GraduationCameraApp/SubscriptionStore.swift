import StoreKit
import SwiftUI

@MainActor
final class SubscriptionStore: ObservableObject {
    @Published private(set) var plans: [MembershipPlan] = MembershipPlan.defaultPlans
    @Published private(set) var activePlanID: String?
    @Published private(set) var purchaseState: PurchaseState = .idle
    @Published var lastError: String?

    func loadProducts() async {
        purchaseState = .loading

        do {
            let fetchedProducts = try await Product.products(for: MembershipPlan.defaultPlans.map(\.productID))
            let mappedPlans = MembershipPlan.defaultPlans.map { fallback in
                if let product = fetchedProducts.first(where: { $0.id == fallback.productID }) {
                    return MembershipPlan(
                        id: fallback.id,
                        productID: product.id,
                        title: fallback.title,
                        subtitle: fallback.subtitle,
                        priceText: product.displayPrice,
                        periodText: fallback.periodText,
                        highlight: fallback.highlight,
                        features: fallback.features
                    )
                }
                return fallback
            }

            plans = mappedPlans.sorted { $0.sortOrder < $1.sortOrder }
            await refreshEntitlements()
            purchaseState = .idle
        } catch {
            purchaseState = .failed
            lastError = "订阅商品加载失败：\(error.localizedDescription)"
        }
    }

    func purchase(plan: MembershipPlan) async {
        purchaseState = .purchasing(plan.id)

        do {
            let products = try await Product.products(for: [plan.productID])
            guard let product = products.first else {
                purchaseState = .failed
                lastError = "未找到对应的订阅商品：\(plan.productID)"
                return
            }

            let result = try await product.purchase()
            switch result {
            case let .success(verification):
                let transaction = try verify(verification)
                activePlanID = transaction.productID
                await transaction.finish()
                purchaseState = .success(plan.id)
            case .userCancelled:
                purchaseState = .idle
            case .pending:
                purchaseState = .pending(plan.id)
            @unknown default:
                purchaseState = .failed
            }
        } catch {
            purchaseState = .failed
            lastError = "订阅购买失败：\(error.localizedDescription)"
        }
    }

    func restorePurchases() async {
        purchaseState = .loading
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            purchaseState = .idle
        } catch {
            purchaseState = .failed
            lastError = "恢复购买失败：\(error.localizedDescription)"
        }
    }

    func refreshEntitlements() async {
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try verify(result)
                activePlanID = transaction.productID
            } catch {
                lastError = "订阅状态校验失败：\(error.localizedDescription)"
            }
        }
    }

    private func verify<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case let .verified(value):
            return value
        case .unverified:
            throw StoreError.verificationFailed
        }
    }
}

struct MembershipPlan: Identifiable, Hashable {
    let id: String
    let productID: String
    let title: String
    let subtitle: String
    let priceText: String
    let periodText: String
    let highlight: String
    let features: [String]

    var sortOrder: Int {
        switch id {
        case "monthly": return 0
        case "yearly": return 1
        default: return 99
        }
    }

    static let defaultPlans: [MembershipPlan] = [
        MembershipPlan(
            id: "monthly",
            productID: "com.graduationcamera.pro.monthly",
            title: "校园月卡",
            subtitle: "适合毕业季短期冲刺使用",
            priceText: "¥28",
            periodText: "/月",
            highlight: "7 天免费试用",
            features: ["双机位同录", "高级模板", "4K 导出", "云端作品管理"]
        ),
        MembershipPlan(
            id: "yearly",
            productID: "com.graduationcamera.pro.yearly",
            title: "校园年卡",
            subtitle: "适合校园摄影团队与社团持续运营",
            priceText: "¥198",
            periodText: "/年",
            highlight: "立省 41%",
            features: ["月卡全部权益", "团队席位管理", "活动专属模板", "优先客服"]
        )
    ]
}

enum PurchaseState: Equatable {
    case idle
    case loading
    case purchasing(String)
    case pending(String)
    case success(String)
    case failed
}

enum StoreError: Error {
    case verificationFailed
}
