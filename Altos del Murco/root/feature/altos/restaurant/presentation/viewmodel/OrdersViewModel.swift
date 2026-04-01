//
//  OrdersViewModel.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Combine
import Foundation

@MainActor
final class OrdersViewModel: ObservableObject {
    @Published private(set) var state = OrdersState()

    private let observeOrdersUseCase: ObserveOrdersUseCase
    private var observeTask: Task<Void, Never>?

    init(observeOrdersUseCase: ObserveOrdersUseCase) {
        self.observeOrdersUseCase = observeOrdersUseCase
    }

    func onEvent(_ event: OrdersEvent) {
        switch event {
        case .onAppear:
            if state.orders.isEmpty && !state.isLoading {
                startObservingOrders()
            }
        case .refresh:
            startObservingOrders()
        }
    }

    private func startObservingOrders() {
        observeTask?.cancel()

        state.isLoading = true
        state.errorMessage = nil

        observeTask = Task {
            do {
                for try await orders in observeOrdersUseCase.execute() {
                    guard !Task.isCancelled else { return }
                    state.orders = orders
                    state.isLoading = false
                }
            } catch {
                guard !Task.isCancelled else { return }
                state.isLoading = false
                state.errorMessage = error.localizedDescription
            }
        }
    }

    deinit {
        observeTask?.cancel()
    }
}
