//
//  AdventureCatalogService.swift
//  Altos del Murco
//
//  Created by José Ruiz on 19/4/26.
//

import Foundation
import FirebaseFirestore

final class AdventureCatalogService: AdventureCatalogServiceable {
    private let db: Firestore
    private let activitiesCollection = "adventure_activities"
    private let packagesCollection = "adventure_featured_packages"

    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

    func fetchCatalog() async throws -> AdventureCatalogSnapshot {
        async let activitiesTask = db.collection(activitiesCollection).getDocuments()
        async let packagesTask = db.collection(packagesCollection).getDocuments()

        let activitiesSnapshot = try await activitiesTask
        let packagesSnapshot = try await packagesTask

        let activities = try activitiesSnapshot.documents.compactMap { document -> AdventureActivityCatalogItem? in
            let dto = try document.data(as: AdventureActivityCatalogDto.self)
            return dto.toDomain()
        }

        let activitiesByType = Dictionary(uniqueKeysWithValues: activities.map { ($0.activityType, $0) })

        let packages: [AdventureFeaturedPackage] = try packagesSnapshot.documents.compactMap { document in
            let dto = try document.data(as: AdventureFeaturedPackageDto.self)

            guard dto.isActive else { return nil }

            let items = dto.items.compactMap { $0.toDomain() }

            // Safe behavior:
            // Hide the full package if any item references an unknown activity
            // or an inactive activity, so package semantics stay predictable.
            guard items.count == dto.items.count else { return nil }

            let allItemsActive = items.allSatisfy { item in
                activitiesByType[item.activity]?.isActive == true
            }
            guard allItemsActive else { return nil }

            return AdventureFeaturedPackage(
                id: dto.id,
                title: dto.title,
                subtitle: dto.subtitle,
                badge: dto.badge,
                isActive: dto.isActive,
                sortOrder: dto.sortOrder,
                packageDiscountAmount: dto.packageDiscountAmount,
                items: items,
                updatedAt: dto.updatedAt.dateValue()
            )
        }

        return AdventureCatalogSnapshot(
            activities: activities.sorted {
                if $0.sortOrder != $1.sortOrder { return $0.sortOrder < $1.sortOrder }
                return $0.title < $1.title
            },
            featuredPackages: packages.sorted {
                if $0.sortOrder != $1.sortOrder { return $0.sortOrder < $1.sortOrder }
                return $0.title < $1.title
            }
        )
    }
}
