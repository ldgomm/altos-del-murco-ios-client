//
//  FeaturedFeedRepositoriable.swift
//  Altos del Murco
//
//  Created by José Ruiz on 14/4/26.
//

import Foundation
import FirebaseFirestore

struct FeaturedFeedPage {
    let posts: [FeaturedPost]
    let lastSnapshot: DocumentSnapshot?
    let hasMore: Bool
}

protocol FeaturedFeedRepositoriable {
    func observeLatest(limit: Int, onChange: @escaping (Result<FeaturedFeedPage, Error>) -> Void) -> ListenerRegistration
    func fetchNextPage(limit: Int, after lastSnapshot: DocumentSnapshot?) async throws -> FeaturedFeedPage
}
