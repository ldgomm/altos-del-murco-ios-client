//
//  CancelOrderUseCase.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/5/26.
//

import Foundation

struct CancelOrderUseCase {
    let service: OrdersServiceable

    func execute(orderId: String, reason: String? = nil) async throws {
        try await service.cancelOrder(orderId: orderId, reason: reason)
    }
}
