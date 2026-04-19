//
//  AdventureCatalogViewModel.swift
//  Altos del Murco
//
//  Created by José Ruiz on 19/4/26.
//

import Combine
import Foundation

struct AdventureCatalogState {
    var catalog: AdventureCatalogSnapshot = .empty
    var isLoading = false
    var errorMessage: String?
}

@MainActor
final class AdventureCatalogViewModel: ObservableObject {
    @Published private(set) var state = AdventureCatalogState()

    private let fetchAdventureCatalogUseCase: FetchAdventureCatalogUseCase
    private var hasLoadedOnce = false

    init(fetchAdventureCatalogUseCase: FetchAdventureCatalogUseCase) {
        self.fetchAdventureCatalogUseCase = fetchAdventureCatalogUseCase
    }

    func onAppear() {
        guard !hasLoadedOnce else { return }
        hasLoadedOnce = true
        Task { await load() }
    }

    func refresh() {
        Task { await load() }
    }

    private func load() async {
        state.isLoading = true
        state.errorMessage = nil

        do {
            let catalog = try await fetchAdventureCatalogUseCase.execute()
            state.catalog = catalog
        } catch {
            state.errorMessage = error.localizedDescription
        }

        state.isLoading = false
    }
}
