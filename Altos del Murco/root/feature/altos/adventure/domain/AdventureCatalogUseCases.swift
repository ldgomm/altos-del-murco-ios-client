//
//  AdventureCatalogUseCases.swift
//  Altos del Murco
//
//  Created by José Ruiz on 19/4/26.
//

import Foundation

struct FetchAdventureCatalogUseCase {
    let service: AdventureCatalogServiceable

    func execute() async throws -> AdventureCatalogSnapshot {
        try await service.fetchCatalog()
    }
}

struct ObserveAdventureCatalogUseCase {
    let service: AdventureCatalogServiceable

    func execute(
        onChange: @escaping (Result<AdventureCatalogSnapshot, Error>) -> Void
    ) -> AdventureListenerToken {
        service.observeCatalog(onChange: onChange)
    }
}
