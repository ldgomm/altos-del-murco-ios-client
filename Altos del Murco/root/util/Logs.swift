//
//  Logs.swift
//  Altos del Murco
//
//  Created by José Ruiz on 22/4/26.
//

import Foundation
import OSLog

//enum RewardDebugLog {
//    static let isEnabled = true
//
//    private static let logger = Logger(
//        subsystem: Bundle.main.bundleIdentifier ?? "AltosDelMurco",
//        category: "RewardsAdventure"
//    )
//
//    static func info(_ message: String) {
//        guard isEnabled else { return }
//        logger.info("\(message, privacy: .public)")
//    }
//
//    static func error(_ message: String) {
//        guard isEnabled else { return }
//        logger.error("\(message, privacy: .public)")
//    }
//
//    static func dumpAppliedRewards(_ rewards: [AppliedReward], prefix: String) {
//        guard isEnabled else { return }
//
//        if rewards.isEmpty {
//            info("\(prefix) appliedRewards=[]")
//            return
//        }
//
//        for reward in rewards {
//            info(
//                "\(prefix) reward id=\(reward.id) templateId=\(reward.templateId) title=\(reward.title) amount=\(formatMoney(reward.amount)) menuItemIds=\(reward.affectedMenuItemIds.joined(separator: ",")) activityIds=\(reward.affectedActivityIds.joined(separator: ",")) note=\(reward.note)"
//            )
//        }
//    }
//
//    static func formatMoney(_ value: Double) -> String {
//        String(format: "%.2f", value)
//    }
//}
