//
//  CheckoutViewModel.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Combine
import Foundation

@MainActor
final class CheckoutViewModel: ObservableObject {
    @Published private(set) var state = CheckoutState()
    
    private let submitOrderUseCase: SubmitOrderUseCase
    private let cartManager: CartManager
    
    init(
        submitOrderUseCase: SubmitOrderUseCase,
        cartManager: CartManager
    ) {
        self.submitOrderUseCase = submitOrderUseCase
        self.cartManager = cartManager
    }
    
    func onEvent(_ event: CheckoutEvent) {
        switch event {
        case .confirmTapped:
            submitOrder()
        }
    }
    
    private func submitOrder() {
        guard let order = cartManager.createOrder() else {
            state.errorMessage = "Please complete client name, table number, and cart items."
            return
        }
        
        state.isSubmitting = true
        state.errorMessage = nil
        
        Task {
            do {
                try await submitOrderUseCase.execute(order: order)
                cartManager.clear()
                state.createdOrder = order
                state.isSubmitting = false
            } catch {
                state.isSubmitting = false
                state.errorMessage = error.localizedDescription
            }
        }
    }
    
    func clearError() {
        state.errorMessage = nil
    }
}
