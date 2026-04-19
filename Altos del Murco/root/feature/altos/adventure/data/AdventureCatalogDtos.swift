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

struct AdventureFeaturedPackageDto: Codable {
    let id: String
    let title: String
    let subtitle: String
    let badge: String?
    let isActive: Bool
    let sortOrder: Int
    let packageDiscountAmount: Double
    let items: [AdventureFeaturedPackageItemDto]
    let updatedAt: Timestamp
}
