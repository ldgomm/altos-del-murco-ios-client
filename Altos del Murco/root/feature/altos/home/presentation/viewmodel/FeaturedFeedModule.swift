//
//  FeaturedFeedModule.swift
//  Altos del Murco
//
//  Created by José Ruiz on 14/4/26.
//

import Foundation

enum FeaturedFeedModule {
    @MainActor
    static func makeViewModel() -> FeaturedFeedViewModel {
        let repository = FeaturedFeedRepository()
        return FeaturedFeedViewModel(
            fetchNextPageUseCase: FetchFeaturedPostsPageUseCase(repository: repository),
            observeLatestUseCase: ObserveLatestFeaturedPostsUseCase(repository: repository)
        )
    }
}
