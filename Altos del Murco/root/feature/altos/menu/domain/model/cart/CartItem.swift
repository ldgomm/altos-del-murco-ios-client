//
//  CartItem.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation

struct CartItem: Identifiable, Hashable {
    let id: UUID = UUID()
    let menuItem: MenuItem
    var quantity: Int
    var notes: String?
    
    var unitPrice: Double {
        menuItem.finalPrice
    }
    
    var totalPrice: Double {
        Double(quantity) * unitPrice
    }
    
    init(menuItem: MenuItem, quantity: Int, notes: String? = nil) {
        self.menuItem = menuItem
        self.quantity = quantity
        self.notes = notes
        
        printDebugging()
    }
    
    func printDebugging() {
        print("CartItem: \(String(describing: notes))")
    }
}
