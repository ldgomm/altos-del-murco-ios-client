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

    private let fetchNextPageUseCase: FetchFeaturedPostsPageUseCase
    private let observeLatestUseCase: ObserveLatestFeaturedPostsUseCase

    private var latestListener: ListenerRegistration?
    private var lastSnapshot: DocumentSnapshot?
    private let pageSize = 5

    init(
        fetchNextPageUseCase: FetchFeaturedPostsPageUseCase,
        observeLatestUseCase: ObserveLatestFeaturedPostsUseCase
    ) {
        self.fetchNextPageUseCase = fetchNextPageUseCase
        self.observeLatestUseCase = observeLatestUseCase
    }

    deinit {
        latestListener?.remove()
    }

    func start() {
        guard latestListener == nil else { return }
        isLoadingInitial = true
        observeLatest()
    }

    func refresh() {
        latestListener?.remove()
        latestListener = nil
        posts = []
        lastSnapshot = nil
        hasMore = true
        errorMessage = nil
        start()
    }

    func loadMoreIfNeeded(currentPost post: FeaturedPost?) {
        guard let post else { return }
        guard let last = posts.last, last.id == post.id else { return }
        guard !isLoadingInitial, !isLoadingMore, hasMore else { return }

        Task {
            await loadMore()
        }
    }

    private func observeLatest() {
        latestListener = observeLatestUseCase.execute(limit: pageSize) { [weak self] result in
            guard let self else { return }

            Task { @MainActor in
                switch result {
                case .success(let page):
                    self.posts = self.mergeKeepingNewest(current: self.posts, incomingTopPage: page.posts)
                    self.lastSnapshot = page.lastSnapshot
                    self.hasMore = page.hasMore || self.posts.count > page.posts.count
                    self.isLoadingInitial = false

                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.isLoadingInitial = false
                }
            }
        }
    }

    private func loadMore() async {
        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let page = try await fetchNextPageUseCase.execute(limit: pageSize, after: lastSnapshot)
            lastSnapshot = page.lastSnapshot
            hasMore = page.hasMore
            posts = mergeAppendingOlder(current: posts, incomingOlderPage: page.posts)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func mergeKeepingNewest(current: [FeaturedPost], incomingTopPage: [FeaturedPost]) -> [FeaturedPost] {
        var map = Dictionary(uniqueKeysWithValues: current.map { ($0.id, $0) })
        incomingTopPage.forEach { map[$0.id] = $0 }

        let result = Array(map.values)
            .filter { !$0.isExpired && $0.isVisible }
            .sorted { lhs, rhs in
                if lhs.expiresAt != rhs.expiresAt { return lhs.expiresAt > rhs.expiresAt }
                return lhs.createdAt > rhs.createdAt
            }

        return result
    }

    private func mergeAppendingOlder(current: [FeaturedPost], incomingOlderPage: [FeaturedPost]) -> [FeaturedPost] {
        var seen = Set(current.map(\.id))
        var merged = current

        for post in incomingOlderPage where !seen.contains(post.id) && !post.isExpired && post.isVisible {
            merged.append(post)
            seen.insert(post.id)
        }

        return merged.sorted { lhs, rhs in
            if lhs.expiresAt != rhs.expiresAt { return lhs.expiresAt > rhs.expiresAt }
            return lhs.createdAt > rhs.createdAt
        }
    }
}
