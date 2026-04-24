//
//  ExperienceComboPricingPolicy.swift
//  Altos del Murco
//
//  Created by José Ruiz on 24/4/26.
//

import Foundation

struct ExperienceComboPricingBreakdown: Hashable {
    let matchedPackageId: String?
    let matchedPackageTitle: String?
    let packageMatchedItems: [AdventureReservationItemDraft]
    let extraItems: [AdventureReservationItemDraft]
    let activityBaseSubtotal: Double
    let activityDiscountAmount: Double
    let activitySubtotalAfterIndividualDiscounts: Double
    let foodSubtotal: Double
    let comboDiscountAmount: Double
    let loyaltyDiscountAmount: Double
    let finalTotal: Double

    var hasValidCombo: Bool {
        matchedPackageId != nil && comboDiscountAmount > 0 && packageMatchedItems.count > 1
    }

    var subtotalBeforeComboAndLoyalty: Double {
        activitySubtotalAfterIndividualDiscounts + foodSubtotal
    }

    var totalSavings: Double {
        activityDiscountAmount + comboDiscountAmount + loyaltyDiscountAmount
    }
}

enum ExperienceComboPricingPolicy {
    static func calculate(
        items: [AdventureReservationItemDraft],
        foodReservation: ReservationFoodDraft?,
        catalog: AdventureCatalogSnapshot,
        featuredPackages: [AdventureFeaturedPackage]? = nil,
        preferredPackageId: String? = nil,
        loyaltyDiscountAmount: Double = 0
    ) -> ExperienceComboPricingBreakdown {
        let normalizedItems = items.filter { item in
            catalog.activity(for: item.activity)?.isActive == true
        }
        let packages = featuredPackages ?? catalog.activePackagesSorted
        let foodSubtotal = AdventurePricingEngine.foodSubtotal(for: foodReservation).roundedMoney
        let activityBaseSubtotal = normalizedItems.reduce(0) { partial, item in
            guard let config = catalog.activity(for: item.activity) else { return partial }
            return partial + AdventurePricingEngine.lineBaseSubtotal(for: item, config: config)
        }.roundedMoney
        let activitySubtotalAfterIndividualDiscounts = AdventurePricingEngine
            .estimatedSubtotal(items: normalizedItems, catalog: catalog)
            .roundedMoney
        let activityDiscountAmount = max(0, activityBaseSubtotal - activitySubtotalAfterIndividualDiscounts).roundedMoney

        let match = bestPackageMatch(
            selectedItems: normalizedItems,
            packages: packages,
            preferredPackageId: preferredPackageId
        )

        let comboDiscount: Double
        if normalizedItems.count <= 1 {
            comboDiscount = 0
        } else {
            comboDiscount = max(0, match?.package.packageDiscountAmount ?? 0).roundedMoney
        }

        let subtotalBeforeLoyalty = max(
            0,
            activitySubtotalAfterIndividualDiscounts + foodSubtotal - comboDiscount
        ).roundedMoney
        let safeLoyalty = min(max(0, loyaltyDiscountAmount), subtotalBeforeLoyalty).roundedMoney
        let finalTotal = max(0, subtotalBeforeLoyalty - safeLoyalty).roundedMoney

        return ExperienceComboPricingBreakdown(
            matchedPackageId: comboDiscount > 0 ? match?.package.id : nil,
            matchedPackageTitle: comboDiscount > 0 ? match?.package.title : nil,
            packageMatchedItems: match?.matchedItems ?? [],
            extraItems: match?.extraItems ?? normalizedItems,
            activityBaseSubtotal: activityBaseSubtotal,
            activityDiscountAmount: activityDiscountAmount,
            activitySubtotalAfterIndividualDiscounts: activitySubtotalAfterIndividualDiscounts,
            foodSubtotal: foodSubtotal,
            comboDiscountAmount: comboDiscount,
            loyaltyDiscountAmount: safeLoyalty,
            finalTotal: finalTotal
        )
    }

    private struct PackageMatch {
        let package: AdventureFeaturedPackage
        let matchedItems: [AdventureReservationItemDraft]
        let extraItems: [AdventureReservationItemDraft]
        let score: Int
    }

    private static func bestPackageMatch(
        selectedItems: [AdventureReservationItemDraft],
        packages: [AdventureFeaturedPackage],
        preferredPackageId: String?
    ) -> PackageMatch? {
        guard selectedItems.count > 1 else { return nil }

        let matches = packages
            .filter { $0.isActive && $0.items.count > 1 }
            .compactMap { package in matchPackage(selectedItems: selectedItems, package: package) }
            .filter { $0.matchedItems.count == $0.package.items.count }

        guard !matches.isEmpty else { return nil }

        if let preferredPackageId,
           let preferred = matches.first(where: { $0.package.id == preferredPackageId }) {
            return preferred
        }

        return matches.sorted {
            if $0.score != $1.score { return $0.score > $1.score }
            if $0.extraItems.count != $1.extraItems.count { return $0.extraItems.count < $1.extraItems.count }
            return $0.package.packageDiscountAmount > $1.package.packageDiscountAmount
        }.first
    }

    private static func matchPackage(
        selectedItems: [AdventureReservationItemDraft],
        package: AdventureFeaturedPackage
    ) -> PackageMatch? {
        var remaining = selectedItems
        var matched: [AdventureReservationItemDraft] = []
        var score = 0

        for packageItem in package.items {
            guard let index = remaining.firstIndex(where: { sameActivitySignature(selected: $0, packageItem: packageItem) }) else {
                return nil
            }

            let selected = remaining.remove(at: index)
            matched.append(selected)
            score += 10
            score += max(0, 5 - durationDistance(selected: selected, packageItem: packageItem))
        }

        return PackageMatch(
            package: package,
            matchedItems: matched,
            extraItems: remaining,
            score: score
        )
    }

    private static func sameActivitySignature(
        selected: AdventureReservationItemDraft,
        packageItem: AdventureReservationItemDraft
    ) -> Bool {
        guard selected.activity == packageItem.activity else { return false }

        switch selected.activity {
        case .offRoad:
            return selected.durationMinutes == packageItem.durationMinutes
                && selected.vehicleCount >= packageItem.vehicleCount
                && selected.offRoadRiderCount >= packageItem.offRoadRiderCount

        case .camping:
            return selected.nights >= packageItem.nights
                && selected.peopleCount >= packageItem.peopleCount

        case .paintball, .goKarts, .shootingRange, .extremeSlide:
            return selected.durationMinutes == packageItem.durationMinutes
                && selected.peopleCount >= packageItem.peopleCount
        }
    }

    private static func durationDistance(
        selected: AdventureReservationItemDraft,
        packageItem: AdventureReservationItemDraft
    ) -> Int {
        abs(selected.durationMinutes - packageItem.durationMinutes) / 30
    }
}

private extension Double {
    var roundedMoney: Double {
        (self * 100).rounded() / 100
    }
}
