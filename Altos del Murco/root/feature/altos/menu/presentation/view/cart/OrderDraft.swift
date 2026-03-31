//
//  OrderDraft.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation

struct OrderDraft: Identifiable, Hashable {
    let id: UUID
    var clientId: String?
    var clientName: String
    var tableNumber: String
    var createdAt: Date
    var updatedAt: Date
    var items: [CartItem]
    var revision: Int?
    var lastConfirmedRevision: Int?
    
    init(
        id: UUID = UUID(),
        clientId: String = "",
        clientName: String = "",
        tableNumber: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        items: [CartItem] = []
    ) {
        self.id = id
        self.clientId = clientId
        self.clientName = clientName
        self.tableNumber = tableNumber
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.items = items
    }
    
    var totalItems: Int {
        items.reduce(0) { $0 + $1.quantity }
    }
    
    var subtotal: Double {
        items.reduce(0) { $0 + $1.totalPrice }
    }
    
    var totalAmount: Double {
        subtotal
    }
    
    var isEmpty: Bool {
        items.isEmpty
    }
}
