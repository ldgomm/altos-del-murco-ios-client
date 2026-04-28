//
//  FeaturedFeedViewModel.swift
//  Altos del Murco
//
//  Created by José Ruiz on 14/4/26.
//

import Combine
import FirebaseFirestore

@MainActor
final class FeaturedFeedViewModel: ObservableObject {
    @Published private(set) var posts: [FeaturedPost] = []
    @Published private(set) var isLoadingInitial = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var hasMore = true
    @Published var errorMessage: String?

    private let observeLatestUseCase: ObserveLatestFeaturedPostsUseCase

    private var latestListener: ListenerRegistration?
    private let pageSize = 5
    private var observedLimit = 5

    init(
        fetchNextPageUseCase: FetchFeaturedPostsPageUseCase,
        observeLatestUseCase: ObserveLatestFeaturedPostsUseCase
    ) {
        // Kept in the initializer so FeaturedFeedModule does not need changes.
        // Pagination is now handled by increasing the live listener limit.
        _ = fetchNextPageUseCase
        self.observeLatestUseCase = observeLatestUseCase
    }

    deinit {
        latestListener?.remove()
    }

    func start() {
        guard latestListener == nil else { return }

        observedLimit = max(pageSize, posts.count)
        isLoadingInitial = posts.isEmpty
        errorMessage = nil

        observeCurrentWindow()
    }

    func refresh() {
        latestListener?.remove()
        latestListener = nil

        posts = []
        observedLimit = pageSize
        hasMore = true
        errorMessage = nil
        isLoadingInitial = true
        isLoadingMore = false

        observeCurrentWindow()
    }

    func loadMoreIfNeeded(currentPost post: FeaturedPost?) {
        guard let post else { return }
        guard let last = posts.last, last.id == post.id else { return }
        guard !isLoadingInitial, !isLoadingMore, hasMore else { return }

        observedLimit += pageSize
        isLoadingMore = true

        restartObservationKeepingCurrentPosts()
    }

    private func restartObservationKeepingCurrentPosts() {
        latestListener?.remove()
        latestListener = nil
        observeCurrentWindow()
    }

    private func observeCurrentWindow() {
        latestListener = observeLatestUseCase.execute(limit: observedLimit) { [weak self] result in
            guard let self else { return }

            Task { @MainActor in
                switch result {
                case .success(let page):
                    // Important:
                    // The observed Firestore page is now the source of truth.
                    // Do NOT merge with the previous local posts.
                    // If Firebase deletes/hides/expires a post, it disappears here immediately.
                    self.posts = self.normalizedPosts(page.posts)
                    self.hasMore = page.hasMore
                    self.isLoadingInitial = false
                    self.isLoadingMore = false

                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.isLoadingInitial = false
                    self.isLoadingMore = false
                }
            }
        }
    }

    private func normalizedPosts(_ incoming: [FeaturedPost]) -> [FeaturedPost] {
        var seen = Set<String>()

        return incoming
            .filter { post in
                post.isVisible && !post.isExpired
            }
            .filter { post in
                guard !seen.contains(post.id) else { return false }
                seen.insert(post.id)
                return true
            }
            .sorted { lhs, rhs in
                if lhs.expiresAt != rhs.expiresAt {
                    return lhs.expiresAt > rhs.expiresAt
                }

                return lhs.createdAt > rhs.createdAt
            }
    }
}
