//
//  AdventureCatalogDtos.swift
//  Altos del Murco
//
//  Created by José Ruiz on 19/4/26.
//

import Foundation
import FirebaseFirestore

struct AdventureActivityDefaultsDto: Codable {
    let durationMinutes: Int
    let peopleCount: Int
    let vehicleCount: Int
    let offRoadRiderCount: Int
    let nights: Int

    func toDomain() -> AdventureActivityDefaults {
        AdventureActivityDefaults(
            durationMinutes: durationMinutes,
            peopleCount: peopleCount,
            vehicleCount: vehicleCount,
            offRoadRiderCount: offRoadRiderCount,
            nights: nights
        )
    }
}

struct AdventureActivityCatalogDto: Codable {
    let id: String
    let title: String
    let systemImage: String
    let shortDescription: String
    let fullDescription: String
    let includes: [String]
    let durationOptions: [Int]
    let pricingMode: String
    let basePrice: Double
    let discountAmount: Double
    let currency: String
    let defaults: AdventureActivityDefaultsDto
    let isActive: Bool
    let sortOrder: Int
    let updatedAt: Timestamp

    func toDomain() -> AdventureActivityCatalogItem? {
        guard let activityType = AdventureActivityType(rawValue: id),
              let pricingMode = AdventurePricingMode(rawValue: pricingMode) else {
            return nil
        }

        return AdventureActivityCatalogItem(
            id: id,
            activityType: activityType,
            title: title,
            systemImage: systemImage,
            shortDescription: shortDescription,
            fullDescription: fullDescription,
            includes: includes,
            durationOptions: durationOptions,
            pricingMode: pricingMode,
            basePrice: basePrice,
            discountAmount: discountAmount,
            currency: currency,
            defaults: defaults.toDomain(),
            isActive: isActive,
            sortOrder: sortOrder,
            updatedAt: updatedAt.dateValue()
        )
    }
}

struct AdventureFeaturedPackageItemDto: Codable {
    let activity: String
    let durationMinutes: Int
    let peopleCount: Int
    let vehicleCount: Int
    let offRoadRiderCount: Int
    let nights: Int

    func toDomain() -> AdventureReservationItemDraft? {
        guard let activity = AdventureActivityType(rawValue: activity) else {
            return nil
        }

        return AdventureReservationItemDraft(
            activity: activity,
            durationMinutes: durationMinutes,
            peopleCount: peopleCount,
            vehicleCount: vehicleCount,
            offRoadRiderCount: offRoadRiderCount,
            nights: nights
        )
    }
}

struct AdventureFeaturedPackageFoodItemDto: Codable {
    let menuItemId: String
    let quantity: Int

    func toDomain() -> AdventureFeaturedPackageFoodItem? {
        let cleanId = menuItemId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanId.isEmpty else { return nil }

        return AdventureFeaturedPackageFoodItem(
            menuItemId: cleanId,
            quantity: max(1, quantity)
        )
    }
}

struct AdventureFeaturedPackageDto: Codable {
    let id: String
    let title: String
    let subtitle: String
    let badge: String?
    let isActive: Bool
    let sortOrder: Int
    let packageDiscountAmount: Double
    let items: [AdventureFeaturedPackageItemDto]
    let foodItems: [AdventureFeaturedPackageFoodItemDto]
    let updatedAt: Timestamp

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case subtitle
        case badge
        case isActive
        case sortOrder
        case packageDiscountAmount
        case items
        case foodItems
        case updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        subtitle = try container.decode(String.self, forKey: .subtitle)
        badge = try container.decodeIfPresent(String.self, forKey: .badge)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        sortOrder = try container.decode(Int.self, forKey: .sortOrder)
        packageDiscountAmount = try container.decode(Double.self, forKey: .packageDiscountAmount)
        items = try container.decode([AdventureFeaturedPackageItemDto].self, forKey: .items)
        foodItems = try container.decodeIfPresent([AdventureFeaturedPackageFoodItemDto].self, forKey: .foodItems) ?? []
        updatedAt = try container.decode(Timestamp.self, forKey: .updatedAt)
    }

    func toDomain() -> AdventureFeaturedPackage? {
        let mappedItems = items.compactMap { $0.toDomain() }
        guard mappedItems.count == items.count else { return nil }

        let mappedFoodItems = foodItems.compactMap { $0.toDomain() }
        guard mappedFoodItems.count == foodItems.count else { return nil }

        return AdventureFeaturedPackage(
            id: id,
            title: title,
            subtitle: subtitle,
            badge: badge,
            isActive: isActive,
            sortOrder: sortOrder,
            packageDiscountAmount: packageDiscountAmount,
            items: mappedItems,
            foodItems: mappedFoodItems,
            updatedAt: updatedAt.dateValue()
        )
    }
}
