//
//  AdventureCatalogService.swift
//  Altos del Murco
//
//  Created by José Ruiz on 19/4/26.
//

import Foundation
import FirebaseFirestore

private final class CompositeAdventureListenerToken: AdventureListenerToken {
    private var registrations: [ListenerRegistration]

    init(registrations: [ListenerRegistration]) {
        self.registrations = registrations
    }

    func remove() {
        registrations.forEach { $0.remove() }
        registrations.removeAll()
    }
}

private final class AdventureCatalogObservationCoordinator {
    private let makeSnapshot: (QuerySnapshot, QuerySnapshot) throws -> AdventureCatalogSnapshot
    private let onChange: (Result<AdventureCatalogSnapshot, Error>) -> Void

    private var activitiesSnapshot: QuerySnapshot?
    private var packagesSnapshot: QuerySnapshot?

    init(
        makeSnapshot: @escaping (QuerySnapshot, QuerySnapshot) throws -> AdventureCatalogSnapshot,
        onChange: @escaping (Result<AdventureCatalogSnapshot, Error>) -> Void
    ) {
        self.makeSnapshot = makeSnapshot
        self.onChange = onChange
    }

    func receiveActivities(snapshot: QuerySnapshot?, error: Error?) {
        if let error {
            onChange(.failure(error))
            return
        }

        guard let snapshot else { return }
        activitiesSnapshot = snapshot
        emitIfReady()
    }

    func receivePackages(snapshot: QuerySnapshot?, error: Error?) {
        if let error {
            onChange(.failure(error))
            return
        }

        guard let snapshot else { return }
        packagesSnapshot = snapshot
        emitIfReady()
    }

    private func emitIfReady() {
        guard let activitiesSnapshot, let packagesSnapshot else { return }

        do {
            let snapshot = try makeSnapshot(activitiesSnapshot, packagesSnapshot)
            onChange(.success(snapshot))
        } catch {
            onChange(.failure(error))
        }
    }
}

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

        return try makeCatalogSnapshot(
            activitiesSnapshot: activitiesSnapshot,
            packagesSnapshot: packagesSnapshot
        )
    }

    func observeCatalog(
        onChange: @escaping (Result<AdventureCatalogSnapshot, Error>) -> Void
    ) -> AdventureListenerToken {
        let coordinator = AdventureCatalogObservationCoordinator(
            makeSnapshot: { [weak self] activitiesSnapshot, packagesSnapshot in
                guard let self else {
                    throw NSError(
                        domain: "AdventureCatalogService",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "AdventureCatalogService is no longer available."]
                    )
                }

                return try self.makeCatalogSnapshot(
                    activitiesSnapshot: activitiesSnapshot,
                    packagesSnapshot: packagesSnapshot
                )
            },
            onChange: onChange
        )

        let activitiesRegistration = db.collection(activitiesCollection)
            .addSnapshotListener { snapshot, error in
                coordinator.receiveActivities(snapshot: snapshot, error: error)
            }

        let packagesRegistration = db.collection(packagesCollection)
            .addSnapshotListener { snapshot, error in
                coordinator.receivePackages(snapshot: snapshot, error: error)
            }

        return CompositeAdventureListenerToken(
            registrations: [activitiesRegistration, packagesRegistration]
        )
    }

    private func makeCatalogSnapshot(
        activitiesSnapshot: QuerySnapshot,
        packagesSnapshot: QuerySnapshot
    ) throws -> AdventureCatalogSnapshot {
        let activities = try activitiesSnapshot.documents.compactMap { document -> AdventureActivityCatalogItem? in
            let dto = try document.data(as: AdventureActivityCatalogDto.self)
            return dto.toDomain()
        }

        let activitiesByType = Dictionary(uniqueKeysWithValues: activities.map { ($0.activityType, $0) })

        let packages: [AdventureFeaturedPackage] = try packagesSnapshot.documents.compactMap { document in
            let dto = try document.data(as: AdventureFeaturedPackageDto.self)

            guard dto.isActive else { return nil }

            let items = dto.items.compactMap { $0.toDomain() }
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
