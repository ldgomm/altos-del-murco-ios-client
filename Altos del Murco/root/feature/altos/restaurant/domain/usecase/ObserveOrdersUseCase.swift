//
//  ObserveOrdersUseCase.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation

struct ObserveOrdersUseCase {
    let service: OrdersServiceable
    
    func execute() -> AsyncThrowingStream<[Order], Error> {
        service.observeOrders()
    }
}
