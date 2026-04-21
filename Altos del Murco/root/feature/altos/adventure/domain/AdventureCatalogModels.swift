//
//  AdventureCatalogModels.swift
//  Altos del Murco
//
//  Created by José Ruiz on 19/4/26.
//

import Foundation

enum AdventurePricingMode: String, Codable, Hashable {
    case perHourPerVehicle
    case per30MinPerPerson
    case perNightPerPerson
    case fixedPerPerson
}

struct AdventureActivityDefaults: Codable, Hashable {
    let durationMinutes: Int
    let peopleCount: Int
    let vehicleCount: Int
    let offRoadRiderCount: Int
    let nights: Int
}

struct AdventureActivityCatalogItem: Identifiable, Codable, Hashable {
    let id: String
    let activityType: AdventureActivityType
    let title: String
    let systemImage: String
    let shortDescription: String
    let fullDescription: String
    let includes: [String]
    let durationOptions: [Int]
    let pricingMode: AdventurePricingMode
    let basePrice: Double
    let discountAmount: Double
    let currency: String
    let defaults: AdventureActivityDefaults
    let isActive: Bool
    let sortOrder: Int
    let updatedAt: Date

    var finalUnitPrice: Double {
        max(0, basePrice - discountAmount)
    }

    var hasDiscount: Bool {
        discountAmount > 0
    }

    var defaultDraft: AdventureReservationItemDraft {
        AdventureReservationItemDraft(
            activity: activityType,
            durationMinutes: defaults.durationMinutes,
            peopleCount: defaults.peopleCount,
            vehicleCount: defaults.vehicleCount,
            offRoadRiderCount: defaults.offRoadRiderCount,
            nights: defaults.nights
        )
    }
}

struct AdventureFeaturedPackageFoodItem: Identifiable, Codable, Hashable {
    let menuItemId: String
    let quantity: Int

    var id: String { menuItemId }

    init(menuItemId: String, quantity: Int) {
        self.menuItemId = menuItemId.trimmingCharacters(in: .whitespacesAndNewlines)
        self.quantity = max(1, quantity)
    }
}

struct AdventureFeaturedPackage: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let badge: String?
    let isActive: Bool
    let sortOrder: Int
    let packageDiscountAmount: Double
    let items: [AdventureReservationItemDraft]
    let foodItems: [AdventureFeaturedPackageFoodItem]
    let updatedAt: Date
}

struct AdventureCatalogSnapshot: Hashable {
    let activities: [AdventureActivityCatalogItem]
    let featuredPackages: [AdventureFeaturedPackage]

    var activitiesByType: [AdventureActivityType: AdventureActivityCatalogItem] {
        Dictionary(uniqueKeysWithValues: activities.map { ($0.activityType, $0) })
    }

    func activity(for activity: AdventureActivityType) -> AdventureActivityCatalogItem? {
        activitiesByType[activity]
    }

    var activeActivitiesSorted: [AdventureActivityCatalogItem] {
        activities
            .filter(\.isActive)
            .sorted {
                if $0.sortOrder != $1.sortOrder { return $0.sortOrder < $1.sortOrder }
                return $0.title < $1.title
            }
    }

    var activePackagesSorted: [AdventureFeaturedPackage] {
        featuredPackages
            .filter(\.isActive)
            .sorted {
                if $0.sortOrder != $1.sortOrder { return $0.sortOrder < $1.sortOrder }
                return $0.title < $1.title
            }
    }

    static let empty = AdventureCatalogSnapshot(
        activities: [],
        featuredPackages: []
    )
}
