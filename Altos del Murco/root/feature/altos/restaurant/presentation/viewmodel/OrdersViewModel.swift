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

    func setNationalId(_ nationalId: String) {
        let clean = nationalId.filter(\.isNumber)
        guard state.nationalId != clean else { return }
        state.nationalId = clean
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

        let nationalId = state.nationalId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !nationalId.isEmpty else {
            state.orders = []
            state.errorMessage = nil
            state.isLoading = false
            return
        }

        state.isLoading = true
        state.errorMessage = nil

        observeTask = Task {
            do {
                for try await orders in observeOrdersUseCase.execute(nationalId: nationalId) {
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
