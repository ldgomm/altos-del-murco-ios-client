//
//  ObserveLatestFeaturedPostsUseCase.swift
//  Altos del Murco
//
//  Created by José Ruiz on 14/4/26.
//

import Foundation
import FirebaseFirestore

struct ObserveLatestFeaturedPostsUseCase {
    private let repository: FeaturedFeedRepositoriable

    init(repository: FeaturedFeedRepositoriable) {
        self.repository = repository
    }

    func execute(
        limit: Int,
        onChange: @escaping (Result<FeaturedFeedPage, Error>) -> Void
    ) -> ListenerRegistration {
        repository.observeLatest(limit: limit, onChange: onChange)
    }
}
