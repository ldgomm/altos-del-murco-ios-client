//
//  LoyaltyRewardEngine.swift
//  Altos del Murco
//
//  Created by José Ruiz on 21/4/26.
//

import Foundation

enum LoyaltyRewardEngine {
    static func evaluateRestaurant(
        templates: [LoyaltyRewardTemplate],
        wallet: RewardWalletSnapshot,
        menuLines: [RewardMenuLine]
    ) -> RewardComputationResult {
        let eligible = templates.filter {
            $0.isActive &&
            $0.triggerMode == .automatic &&
            $0.scope.matchesRestaurant() &&
            $0.isEligible(for: wallet.currentLevel)
        }

        let stackableTemplates = eligible.filter(\.canStack).sorted { lhs, rhs in
            if lhs.priority != rhs.priority { return lhs.priority < rhs.priority }
            return lhs.title < rhs.title
        }

        let exclusiveTemplates = eligible.filter { !$0.canStack }.sorted { lhs, rhs in
            if lhs.priority != rhs.priority { return lhs.priority < rhs.priority }
            return lhs.title < rhs.title
        }

        let stackableResult = applyRestaurantTemplates(stackableTemplates, menuLines: menuLines)
        let bestExclusive = exclusiveTemplates
            .map { applyRestaurantTemplates([$0], menuLines: menuLines) }
            .max { lhs, rhs in lhs.totalDiscount < rhs.totalDiscount }

        let winner = (bestExclusive?.totalDiscount ?? 0) > stackableResult.totalDiscount
            ? bestExclusive!
            : stackableResult

        return RewardComputationResult(
            appliedRewards: winner.appliedRewards,
            totalDiscount: winner.totalDiscount,
            walletSnapshot: wallet
        )
    }

    static func evaluateAdventure(
        templates: [LoyaltyRewardTemplate],
        wallet: RewardWalletSnapshot,
        activityLines: [RewardActivityLine],
        foodLines: [RewardMenuLine]
    ) -> RewardComputationResult {
        let eligible = templates.filter {
            $0.isActive &&
            $0.triggerMode == .automatic &&
            $0.scope.matchesAdventure() &&
            $0.isEligible(for: wallet.currentLevel)
        }

        let stackableTemplates = eligible.filter(\.canStack).sorted { lhs, rhs in
            if lhs.priority != rhs.priority { return lhs.priority < rhs.priority }
            return lhs.title < rhs.title
        }

        let exclusiveTemplates = eligible.filter { !$0.canStack }.sorted { lhs, rhs in
            if lhs.priority != rhs.priority { return lhs.priority < rhs.priority }
            return lhs.title < rhs.title
        }

        let stackableResult = applyAdventureTemplates(
            stackableTemplates,
            activityLines: activityLines,
            foodLines: foodLines
        )

        let bestExclusive = exclusiveTemplates
            .map { applyAdventureTemplates([$0], activityLines: activityLines, foodLines: foodLines) }
            .max { lhs, rhs in lhs.totalDiscount < rhs.totalDiscount }

        let winner = (bestExclusive?.totalDiscount ?? 0) > stackableResult.totalDiscount
            ? bestExclusive!
            : stackableResult

        return RewardComputationResult(
            appliedRewards: winner.appliedRewards,
            totalDiscount: winner.totalDiscount,
            walletSnapshot: wallet
        )
    }

    private struct InternalRewardResult {
        var appliedRewards: [AppliedReward]
        var totalDiscount: Double
    }

    private struct MutableMenuLine {
        let menuItemId: String
        let name: String
        let unitPrice: Double
        var remainingRewardableUnits: Int
    }

    private struct MutableActivityLine {
        let activityId: String
        let title: String
        var remainingRewardableAmount: Double
    }

    private static func applyRestaurantTemplates(
        _ templates: [LoyaltyRewardTemplate],
        menuLines: [RewardMenuLine]
    ) -> InternalRewardResult {
        var workingLines = menuLines.map {
            MutableMenuLine(
                menuItemId: $0.menuItemId,
                name: $0.name,
                unitPrice: $0.unitPrice,
                remainingRewardableUnits: max(0, $0.quantity)
            )
        }

        var appliedRewards: [AppliedReward] = []
        var totalDiscount = 0.0

        for template in templates {
            guard let reward = applyRestaurantTemplate(template, lines: &workingLines) else { continue }
            appliedRewards.append(reward)
            totalDiscount += reward.amount
        }

        return InternalRewardResult(
            appliedRewards: appliedRewards,
            totalDiscount: totalDiscount
        )
    }

    private static func applyAdventureTemplates(
        _ templates: [LoyaltyRewardTemplate],
        activityLines: [RewardActivityLine],
        foodLines: [RewardMenuLine]
    ) -> InternalRewardResult {
        var workingActivities = activityLines.map {
            MutableActivityLine(
                activityId: $0.activityId,
                title: $0.title,
                remainingRewardableAmount: max(0, $0.linePrice)
            )
        }

        var workingFood = foodLines.map {
            MutableMenuLine(
                menuItemId: $0.menuItemId,
                name: $0.name,
                unitPrice: $0.unitPrice,
                remainingRewardableUnits: max(0, $0.quantity)
            )
        }

        var appliedRewards: [AppliedReward] = []
        var totalDiscount = 0.0

        for template in templates {
            switch template.rule.type {
            case .activityPercentage:
                guard let reward = applyActivityTemplate(template, lines: &workingActivities) else { continue }
                appliedRewards.append(reward)
                totalDiscount += reward.amount

            default:
                guard let reward = applyRestaurantTemplate(template, lines: &workingFood) else { continue }
                appliedRewards.append(reward)
                totalDiscount += reward.amount
            }
        }

        return InternalRewardResult(
            appliedRewards: appliedRewards,
            totalDiscount: totalDiscount
        )
    }

    private static func applyRestaurantTemplate(
        _ template: LoyaltyRewardTemplate,
        lines: inout [MutableMenuLine]
    ) -> AppliedReward? {
        switch template.rule.type {
        case .mostExpensiveMenuItemPercentage:
            guard let percentage = template.rule.percentage else { return nil }
            guard let index = lines.indices
                .filter({ lines[$0].remainingRewardableUnits > 0 })
                .max(by: { lines[$0].unitPrice < lines[$1].unitPrice }) else { return nil }

            let line = lines[index]
            let amount = roundMoney(line.unitPrice * (percentage / 100))
            guard amount > 0 else { return nil }

            lines[index].remainingRewardableUnits -= 1

            return AppliedReward(
                id: UUID().uuidString,
                templateId: template.id,
                title: template.title,
                amount: amount,
                note: "\(Int(percentage))% en \(line.name)",
                affectedMenuItemIds: [line.menuItemId],
                affectedActivityIds: []
            )

        case .specificMenuItemPercentage:
            let percentage = template.rule.percentage ?? 0
            let quantity = max(1, template.rule.quantity ?? 1)
            let targetId = template.rule.menuItemId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            guard !targetId.isEmpty else { return nil }
            guard let index = lines.firstIndex(where: {
                $0.menuItemId == targetId && $0.remainingRewardableUnits > 0
            }) else { return nil }

            let applicableUnits = min(quantity, lines[index].remainingRewardableUnits)
            guard applicableUnits > 0 else { return nil }

            let amount = roundMoney(Double(applicableUnits) * lines[index].unitPrice * (percentage / 100))
            guard amount > 0 else { return nil }

            lines[index].remainingRewardableUnits -= applicableUnits

            return AppliedReward(
                id: UUID().uuidString,
                templateId: template.id,
                title: template.title,
                amount: amount,
                note: "\(Int(percentage))% en \(lines[index].name)",
                affectedMenuItemIds: [targetId],
                affectedActivityIds: []
            )

        case .freeMenuItem:
            let quantity = max(1, template.rule.quantity ?? 1)
            let targetId = template.rule.menuItemId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            guard !targetId.isEmpty else { return nil }
            guard let index = lines.firstIndex(where: {
                $0.menuItemId == targetId && $0.remainingRewardableUnits > 0
            }) else { return nil }

            let applicableUnits = min(quantity, lines[index].remainingRewardableUnits)
            guard applicableUnits > 0 else { return nil }

            let amount = roundMoney(Double(applicableUnits) * lines[index].unitPrice)
            guard amount > 0 else { return nil }

            lines[index].remainingRewardableUnits -= applicableUnits

            return AppliedReward(
                id: UUID().uuidString,
                templateId: template.id,
                title: template.title,
                amount: amount,
                note: "\(applicableUnits)x \(lines[index].name) gratis",
                affectedMenuItemIds: [targetId],
                affectedActivityIds: []
            )

        case .buyXGetYFree:
            let targetId = template.rule.menuItemId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let buyQuantity = max(1, template.rule.buyQuantity ?? 1)
            let freeQuantity = max(1, template.rule.freeQuantity ?? 1)
            let repeatable = template.rule.repeatable ?? true

            guard !targetId.isEmpty else { return nil }
            guard let index = lines.firstIndex(where: { $0.menuItemId == targetId }) else { return nil }

            let line = lines[index]
            let totalUnits = line.remainingRewardableUnits
            guard totalUnits >= buyQuantity else { return nil }

            let freeUnits: Int = {
                if repeatable {
                    return min(totalUnits, (totalUnits / buyQuantity) * freeQuantity)
                }
                return totalUnits >= buyQuantity ? min(totalUnits, freeQuantity) : 0
            }()

            guard freeUnits > 0 else { return nil }

            let amount = roundMoney(Double(freeUnits) * line.unitPrice)
            guard amount > 0 else { return nil }

            lines[index].remainingRewardableUnits -= freeUnits

            return AppliedReward(
                id: UUID().uuidString,
                templateId: template.id,
                title: template.title,
                amount: amount,
                note: "Compra \(buyQuantity) y recibe \(freeUnits) gratis en \(line.name)",
                affectedMenuItemIds: [targetId],
                affectedActivityIds: []
            )

        case .activityPercentage:
            return nil
        }
    }

    private static func applyActivityTemplate(
        _ template: LoyaltyRewardTemplate,
        lines: inout [MutableActivityLine]
    ) -> AppliedReward? {
        guard template.rule.type == .activityPercentage else { return nil }

        let percentage = template.rule.percentage ?? 0
        let targetId = template.rule.activityId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !targetId.isEmpty else { return nil }
        guard let index = lines.firstIndex(where: {
            $0.activityId == targetId && $0.remainingRewardableAmount > 0
        }) else { return nil }

        let amount = roundMoney(lines[index].remainingRewardableAmount * (percentage / 100))
        guard amount > 0 else { return nil }

        lines[index].remainingRewardableAmount = 0

        return AppliedReward(
            id: UUID().uuidString,
            templateId: template.id,
            title: template.title,
            amount: amount,
            note: "\(Int(percentage))% en \(lines[index].title)",
            affectedMenuItemIds: [],
            affectedActivityIds: [targetId]
        )
    }

    private static func roundMoney(_ value: Double) -> Double {
        (value * 100).rounded() / 100
    }
}
