//
//  SubmitOrderUseCase.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation

struct SubmitOrderUseCase {
    let service: OrdersServiceable
    
    func execute(order: Order) async throws {
        try await service.submit(order: order)
    }
}
