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
        let safeLimit = max(1, limit)

        return baseActiveQuery()
            // Fetch one extra document so hasMore is accurate.
            .limit(to: safeLimit + 1)
            .addSnapshotListener { snapshot, error in
                if let error {
                    onChange(.failure(error))
                    return
                }

                guard let snapshot else {
                    onChange(
                        .success(
                            FeaturedFeedPage(
                                posts: [],
                                lastSnapshot: nil,
                                hasMore: false
                            )
                        )
                    )
                    return
                }

                do {
                    let visibleDocuments = Array(snapshot.documents.prefix(safeLimit))

                    let posts = try visibleDocuments.compactMap { document in
                        try document.data(as: FeaturedPostDto.self).toDomain()
                    }

                    onChange(
                        .success(
                            FeaturedFeedPage(
                                posts: posts,
                                lastSnapshot: visibleDocuments.last,
                                hasMore: snapshot.documents.count > safeLimit
                            )
                        )
                    )
                } catch {
                    onChange(.failure(error))
                }
            }
    }

    func fetchNextPage(
        limit: Int,
        after lastSnapshot: DocumentSnapshot?
    ) async throws -> FeaturedFeedPage {
        let safeLimit = max(1, limit)

        var query: Query = baseActiveQuery()
            .limit(to: safeLimit + 1)

        if let lastSnapshot {
            query = query.start(afterDocument: lastSnapshot)
        }

        let snapshot = try await query.getDocuments()
        let visibleDocuments = Array(snapshot.documents.prefix(safeLimit))

        let posts = try visibleDocuments.compactMap { document in
            try document.data(as: FeaturedPostDto.self).toDomain()
        }

        return FeaturedFeedPage(
            posts: posts,
            lastSnapshot: visibleDocuments.last ?? lastSnapshot,
            hasMore: snapshot.documents.count > safeLimit
        )
    }

    private func baseActiveQuery() -> Query {
        db.collection(collectionName)
            .whereField("isVisible", isEqualTo: true)
            .whereField("expiresAt", isGreaterThan: Date())
            .order(by: "expiresAt", descending: true)
    }
}
