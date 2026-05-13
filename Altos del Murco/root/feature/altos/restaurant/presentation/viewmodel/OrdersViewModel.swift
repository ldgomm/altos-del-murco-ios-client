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
    private let cancelOrderUseCase: CancelOrderUseCase?
    private var observeTask: Task<Void, Never>?

    init(
        observeOrdersUseCase: ObserveOrdersUseCase,
        cancelOrderUseCase: CancelOrderUseCase? = nil
    ) {
        self.observeOrdersUseCase = observeOrdersUseCase
        self.cancelOrderUseCase = cancelOrderUseCase
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

    func cancel(_ order: Order, reason: String? = nil) {
        guard order.canClientCancel else {
            state.errorMessage = order.clientCancellationBlockedMessage
            return
        }

        guard let cancelOrderUseCase else {
            state.errorMessage = "No pude cancelar el pedido en este momento."
            return
        }

        Task {
            do {
                try await cancelOrderUseCase.execute(orderId: order.id, reason: reason)
            } catch {
                state.errorMessage = error.localizedDescription
            }
        }
    }

    func dismissError() {
        state.errorMessage = nil
    }

    private func startObservingOrders() {
        observeTask?.cancel()

        state.isLoading = true
        state.errorMessage = nil

        observeTask = Task {
            do {
                for try await orders in observeOrdersUseCase.execute() {
                    guard !Task.isCancelled else { return }
                    state.orders = orders.sorted { lhs, rhs in
                        lhs.scheduledAt > rhs.scheduledAt
                    }
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
 
