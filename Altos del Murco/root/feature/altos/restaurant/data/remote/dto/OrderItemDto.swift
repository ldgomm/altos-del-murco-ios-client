//
//  OrderitemDto.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation

struct OrderItemDto: Codable {
    let id: String
    let menuItemId: String
    let name: String
    let unitPrice: Double
    let quantity: Int
    let preparedQuantity: Int?
    let totalPrice: Double?
    let notes: String?
}

extension OrderItemDto {
    init(from domain: OrderItem) {
        self.id = domain.id.uuidString
        self.menuItemId = domain.menuItemId
        self.name = domain.name
        self.unitPrice = domain.unitPrice
        self.quantity = domain.quantity
        self.preparedQuantity = domain.preparedQuantity
        self.totalPrice = domain.totalPrice
        self.notes = domain.notes
    }
    
    func toDomain() -> OrderItem? {
        guard let uuid = UUID(uuidString: id) else { return nil }
        
        return OrderItem(
            id: uuid,
            menuItemId: menuItemId,
            name: name,
            unitPrice: unitPrice,
            quantity: quantity,
            preparedQuantity: preparedQuantity ?? 0,
            notes: notes
        )
        
    }
}
