//
//  FeaturedFeedRepository.swift
//  Altos del Murco
//
//  Created by José Ruiz on 14/4/26.
//

import Foundation
import FirebaseFirestore

final class FeaturedFeedRepository: FeaturedFeedRepositoriable {
    private let db: Firestore
    private let collectionName = "featured_posts"

    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

    func observeLatest(
        limit: Int,
        onChange: @escaping (Result<FeaturedFeedPage, Error>) -> Void
    ) -> ListenerRegistration {
        baseActiveQuery()
            .limit(to: limit)
            .addSnapshotListener { snapshot, error in
                if let error {
                    onChange(.failure(error))
                    return
                }

                guard let snapshot else {
                    onChange(.success(FeaturedFeedPage(posts: [], lastSnapshot: nil, hasMore: false)))
                    return
                }

                do {
                    let posts = try snapshot.documents.compactMap { document in
                        try document.data(as: FeaturedPostDto.self).toDomain()
                    }

                    let page = FeaturedFeedPage(
                        posts: posts,
                        lastSnapshot: snapshot.documents.last,
                        hasMore: snapshot.documents.count == limit
                    )
                    onChange(.success(page))
                } catch {
                    onChange(.failure(error))
                }
            }
    }

    func fetchNextPage(limit: Int, after lastSnapshot: DocumentSnapshot?) async throws -> FeaturedFeedPage {
        var query: Query = baseActiveQuery().limit(to: limit)

        if let lastSnapshot {
            query = query.start(afterDocument: lastSnapshot)
        }

        let snapshot = try await query.getDocuments()
        let posts = try snapshot.documents.compactMap { document in
            try document.data(as: FeaturedPostDto.self).toDomain()
        }

        return FeaturedFeedPage(
            posts: posts,
            lastSnapshot: snapshot.documents.last ?? lastSnapshot,
            hasMore: snapshot.documents.count == limit
        )
    }

    private func baseActiveQuery() -> Query {
        db.collection(collectionName)
            .whereField("isVisible", isEqualTo: true)
            .whereField("expiresAt", isGreaterThan: Date())
            .order(by: "expiresAt", descending: true)
    }
}
