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
}
