//
//  OrdersServiceable.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation

protocol OrdersServiceable {
    func submit(order: Order) async throws
    func observeOrders() -> AsyncThrowingStream<[Order], Error>

    /// Client-side cancellation is intentionally limited by OrdersService.
    /// Current business rule: clients can cancel only pending orders.
    func cancelOrder(orderId: String, reason: String?) async throws
}

extension OrdersServiceable {
    func cancelOrder(orderId: String) async throws {
        try await cancelOrder(orderId: orderId, reason: nil)
    }
}
