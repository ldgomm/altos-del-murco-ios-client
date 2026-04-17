//
//  MenuViewModel.swift
//  Altos del Murco
//
//  Created by José Ruiz on 16/4/26.
//

import Combine
import Foundation

struct RestaurantMenuState {
    var sections: [MenuSection] = []
    var isLoading = false
    var errorMessage: String?
}

@MainActor
final class MenuViewModel: ObservableObject {
    @Published private(set) var state = RestaurantMenuState()

    private let service: MenuServiceable
    private var listenerToken: MenuListenerTokenable?

    init(service: MenuServiceable) {
        self.service = service
    }

    func onAppear() {
        guard listenerToken == nil else { return }

        state.isLoading = true
        state.errorMessage = nil

        listenerToken = service.observeMenu { [weak self] result in
            Task { @MainActor in
                guard let self else { return }

                switch result {
                case .success(let sections):
                    self.state.sections = sections
                    self.state.isLoading = false

                case .failure(let error):
                    self.state.sections = []
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
}
