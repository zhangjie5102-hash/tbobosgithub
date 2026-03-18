import Foundation
import SwiftUI

final class UserAccountStore: ObservableObject {
    @Published var profile = UserProfile.demo

    func markSubscribed(planID: String?) {
        profile.membershipTag = planID == nil ? "游客" : "Pro"
        profile.seatsAvailable = planID == "com.graduationcamera.pro.yearly" ? 6 : 1
    }
}

struct UserProfile {
    var nickname: String
    var schoolName: String
    var membershipTag: String
    var seatsAvailable: Int
    var cloudProjects: Int

    static let demo = UserProfile(
        nickname: "夏野同学",
        schoolName: "毕业季摄影社",
        membershipTag: "游客",
        seatsAvailable: 1,
        cloudProjects: 3
    )
}
