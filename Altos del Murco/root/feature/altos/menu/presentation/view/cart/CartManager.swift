//
//  CartManager.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation
import Combine

final class CartManager: ObservableObject {
    @Published private(set) var draft: OrderDraft = OrderDraft()
    
    var items: [CartItem] { draft.items }
    
    var clientId: String? {
        get { draft.clientId }
        set { draft.clientId = newValue }
    }
    
    var clientName: String {
        get { draft.clientName }
        set { draft.clientName = newValue }
    }
    
    var tableNumber: String {
        get { draft.tableNumber }
        set { draft.tableNumber = newValue }
    }
    
    var orderCreatedAt: Date { draft.createdAt }
    var totalItems: Int { draft.totalItems }
    var subtotal: Double { draft.subtotal }
    var totalAmount: Double { draft.totalAmount }
    var isEmpty: Bool { draft.isEmpty }
    
    func add(item: MenuItem, quantity: Int = 1, notes: String? = nil) {
        guard item.isAvailable else { return }
        guard quantity > 0 else { return }

        let cleanNotes = notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalNotes = (cleanNotes?.isEmpty == true) ? nil : cleanNotes

        print("CartManager: \(finalNotes ?? "empty")")
        if draft.items.isEmpty { draft.createdAt = Date() }

        if let index = draft.items.firstIndex(where: { $0.menuItem.id == item.id && $0.notes == finalNotes }) {
            draft.items[index].quantity += quantity
        } else {
            print("CartManager: \(finalNotes ?? "empty")")
            draft.items.append(CartItem(menuItem: item, quantity: quantity, notes: finalNotes))
        }
    }
    
    func increaseQuantity(for itemId: String, by amount: Int = 1) {
        guard amount > 0 else { return }
        guard let index = draft.items.firstIndex(where: { $0.menuItem.id == itemId }) else { return }
        guard draft.items[index].menuItem.isAvailable else { return }
        
        draft.items[index].quantity += amount
    }
    
    func decreaseQuantity(for itemId: String, by amount: Int = 1) {
        guard amount > 0 else { return }
        guard let index = draft.items.firstIndex(where: { $0.menuItem.id == itemId }) else { return }
        
        let newQuantity = draft.items[index].quantity - amount
        
        if newQuantity > 0 {
            draft.items[index].quantity = newQuantity
        } else {
            draft.items.remove(at: index)
            
            if draft.items.isEmpty {
                resetDraftMetadata()
            }
        }
    }
    
    func updateQuantity(for itemId: String, quantity: Int) {
        guard let index = draft.items.firstIndex(where: { $0.menuItem.id == itemId }) else { return }
        
        if quantity <= 0 {
            draft.items.remove(at: index)
            
            if draft.items.isEmpty {
                resetDraftMetadata()
            }
            return
        }
        
        guard draft.items[index].menuItem.isAvailable else { return }
        draft.items[index].quantity = quantity
    }
    
    func remove(itemId: String) {
        draft.items.removeAll { $0.menuItem.id == itemId }
        
        if draft.items.isEmpty {
            resetDraftMetadata()
        }
    }
    
    func updateClientId(_ id: String) {
        draft.clientId = id
    }
    
    func updateClientName(_ name: String) {
        draft.clientName = name
    }
    
    func updateTableNumber(_ table: String) {
        draft.tableNumber = table
    }
    
    func contains(itemId: String) -> Bool {
        draft.items.contains { $0.menuItem.id == itemId }
    }
    
    func quantity(for itemId: String) -> Int {
        draft.items.first(where: { $0.menuItem.id == itemId })?.quantity ?? 0
    }
    
    func cartItem(for itemId: String) -> CartItem? {
        draft.items.first(where: { $0.menuItem.id == itemId })
    }
    
    func clear() {
        draft = OrderDraft()
    }
    
    func resetDraftMetadata() {
        draft.clientName = ""
        draft.tableNumber = ""
        draft.createdAt = Date()
    }
    
    func resetDraftKeepingIdentity() {
        draft = OrderDraft(id: draft.id)
    }
    
    func replaceDraft(with newDraft: OrderDraft) {
        draft = newDraft
    }
    
    func createOrder() -> Order? {
        guard draft.canSubmit else { return nil }
        return draft.toOrder()
    }
    
    func submitOrder() -> Order? {
        guard let order = createOrder() else { return nil }
        clear()
        return order
    }
}
