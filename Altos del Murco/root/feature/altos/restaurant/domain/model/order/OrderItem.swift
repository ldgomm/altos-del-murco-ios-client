//
//  OrderItem.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation

struct OrderItem: Identifiable, Hashable, Codable {
    let id: UUID
    let menuItemId: String
    let name: String
    let unitPrice: Double
    let quantity: Int
    let preparedQuantity: Int
    let totalPrice: Double
    let notes: String?

    init(
        id: UUID = UUID(),
        menuItemId: String,
        name: String,
        unitPrice: Double,
        quantity: Int,
        preparedQuantity: Int = 0,
        notes: String? = nil
    ) {
        self.id = id
        self.menuItemId = menuItemId
        self.name = name
        self.unitPrice = unitPrice
        self.quantity = quantity
        self.preparedQuantity = min(max(preparedQuantity, 0), quantity)
        self.totalPrice = Double(quantity) * unitPrice
        self.notes = notes
        
        printDebugging()
    }

    var remainingQuantity: Int {
        quantity - preparedQuantity
    }

    var isStarted: Bool {
        preparedQuantity > 0
    }

    var isCompleted: Bool {
        preparedQuantity == quantity
    }

    func updatingPreparedQuantity(_ newValue: Int) -> OrderItem {
        OrderItem(
            id: id,
            menuItemId: menuItemId,
            name: name,
            unitPrice: unitPrice,
            quantity: quantity,
            preparedQuantity: min(max(newValue, 0), quantity),
            notes: notes
        )
    }
    
    func printDebugging() {
        print("OrderItem: \(String(describing: notes))")
    }
}
