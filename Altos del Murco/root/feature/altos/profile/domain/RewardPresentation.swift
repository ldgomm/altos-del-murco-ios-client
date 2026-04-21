//
//  RewardPresentationModels.swift
//  Altos del Murco
//
//  Created by José Ruiz on 21/4/26.
//

import Foundation

struct RewardPresentation: Identifiable, Hashable {
    let id: String
    let badge: String
    let title: String
    let message: String
    let amountText: String?

    init(
        id: String = UUID().uuidString,
        badge: String,
        title: String,
        message: String,
        amountText: String? = nil
    ) {
        self.id = id
        self.badge = badge
        self.title = title
        self.message = message
        self.amountText = amountText
    }

    static func from(appliedReward reward: AppliedReward) -> RewardPresentation {
        let lowercasedNote = reward.note.lowercased()
        let badge: String

        if lowercasedNote.contains("gratis") {
            badge = "Gratis"
        } else if lowercasedNote.contains("%") {
            badge = "Descuento"
        } else {
            badge = "Premio"
        }

        return RewardPresentation(
            id: reward.id,
            badge: badge,
            title: reward.title,
            message: reward.note,
            amountText: reward.amount.priceText
        )
    }
}

enum RewardPresentationFactory {
    static func menuPresentation(
        for item: MenuItem,
        wallet: RewardWalletSnapshot
    ) -> RewardPresentation? {
        for template in wallet.availableTemplates where template.scope.matchesRestaurant() {
            switch template.rule.type {
            case .freeMenuItem:
                let targetId = template.rule.menuItemId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                guard targetId == item.id else { continue }

                return RewardPresentation(
                    id: template.id,
                    badge: "Gratis",
                    title: template.title,
                    message: "\(item.name) puede salirte gratis por tu nivel \(wallet.currentLevel.title)."
                )

            case .specificMenuItemPercentage:
                let targetId = template.rule.menuItemId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                guard targetId == item.id else { continue }

                let percentage = Int((template.rule.percentage ?? 0).rounded())
                guard percentage > 0 else { continue }

                return RewardPresentation(
                    id: template.id,
                    badge: "\(percentage)% OFF",
                    title: template.title,
                    message: "\(item.name) tiene \(percentage)% de descuento automático por tu nivel \(wallet.currentLevel.title)."
                )

            case .buyXGetYFree:
                let targetId = template.rule.menuItemId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                guard targetId == item.id else { continue }

                let buyQuantity = max(1, template.rule.buyQuantity ?? 1)
                let freeQuantity = max(1, template.rule.freeQuantity ?? 1)

                return RewardPresentation(
                    id: template.id,
                    badge: "Promo",
                    title: template.title,
                    message: "Compra \(buyQuantity) y recibe \(freeQuantity) gratis."
                )

            case .mostExpensiveMenuItemPercentage:
                let percentage = Int((template.rule.percentage ?? 0).rounded())
                guard percentage > 0 else { continue }

                return RewardPresentation(
                    id: template.id,
                    badge: "\(percentage)% OFF",
                    title: template.title,
                    message: "Puede aplicar \(percentage)% si este plato es el elegible más caro del pedido."
                )

            case .activityPercentage:
                continue
            }
        }

        return nil
    }

    static func activityPresentation(
        for activity: AdventureActivityCatalogItem,
        wallet: RewardWalletSnapshot
    ) -> RewardPresentation? {
        for template in wallet.availableTemplates where template.scope.matchesAdventure() {
            switch template.rule.type {
            case .activityPercentage:
                let targetId = template.rule.activityId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                guard targetId == activity.id else { continue }

                let percentage = Int((template.rule.percentage ?? 0).rounded())
                guard percentage > 0 else { continue }

                return RewardPresentation(
                    id: template.id,
                    badge: "\(percentage)% OFF",
                    title: template.title,
                    message: "\(activity.title) tiene \(percentage)% de descuento automático por tu nivel \(wallet.currentLevel.title)."
                )

            default:
                continue
            }
        }

        return nil
    }

    static func packagePresentation(
        for package: AdventureFeaturedPackage,
        catalog: AdventureCatalogSnapshot,
        menuItemsById: [String: MenuItem],
        wallet: RewardWalletSnapshot
    ) -> RewardPresentation? {
        for item in package.items {
            guard let activity = catalog.activity(for: item.activity) else { continue }
            if let presentation = activityPresentation(for: activity, wallet: wallet) {
                return presentation
            }
        }

        for item in package.foodItems {
            guard let menuItem = menuItemsById[item.menuItemId] else { continue }
            if let presentation = menuPresentation(for: menuItem, wallet: wallet) {
                return presentation
            }
        }

        return nil
    }
}
