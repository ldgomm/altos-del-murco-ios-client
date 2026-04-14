//
//  FetchFeaturedPostsPageUseCase.swift
//  Altos del Murco
//
//  Created by José Ruiz on 14/4/26.
//

import Foundation
import FirebaseFirestore

struct FetchFeaturedPostsPageUseCase {
    private let repository: FeaturedFeedRepositoriable

    init(repository: FeaturedFeedRepositoriable) {
        self.repository = repository
    }

    func execute(limit: Int, after lastSnapshot: DocumentSnapshot?) async throws -> FeaturedFeedPage {
        try await repository.fetchNextPage(limit: limit, after: lastSnapshot)
    }
}
