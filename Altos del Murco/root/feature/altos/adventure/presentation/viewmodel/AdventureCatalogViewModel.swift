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
    private let observeAdventureCatalogUseCase: ObserveAdventureCatalogUseCase
    private var listenerToken: AdventureListenerToken?

    init(service: AdventureCatalogServiceable) {
        self.fetchAdventureCatalogUseCase = FetchAdventureCatalogUseCase(service: service)
        self.observeAdventureCatalogUseCase = ObserveAdventureCatalogUseCase(service: service)
    }

    init(
        fetchAdventureCatalogUseCase: FetchAdventureCatalogUseCase,
        observeAdventureCatalogUseCase: ObserveAdventureCatalogUseCase
    ) {
        self.fetchAdventureCatalogUseCase = fetchAdventureCatalogUseCase
        self.observeAdventureCatalogUseCase = observeAdventureCatalogUseCase
    }

    func onAppear() {
        guard listenerToken == nil else { return }

        state.isLoading = true
        state.errorMessage = nil

        listenerToken = observeAdventureCatalogUseCase.execute { [weak self] result in
            Task { @MainActor in
                guard let self else { return }

                switch result {
                case .success(let catalog):
                    self.state.catalog = catalog
                    self.state.isLoading = false

                case .failure(let error):
                    self.state.errorMessage = error.localizedDescription
                    self.state.isLoading = false
                }
            }
        }
    }

    func onDisappear() {
        listenerToken?.remove()
        listenerToken = nil
    }

    func refresh() {
        Task { await load() }
    }

    private func load() async {
        state.isLoading = true
        state.errorMessage = nil

        do {
            state.catalog = try await fetchAdventureCatalogUseCase.execute()
        } catch {
            state.errorMessage = error.localizedDescription
        }

        state.isLoading = false
    }
}
