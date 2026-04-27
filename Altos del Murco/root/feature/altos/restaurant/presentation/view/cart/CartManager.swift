//
//  CartManager.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation
import Combine
import SwiftData

@MainActor
final class CartManager: ObservableObject {
    @Published private(set) var draft: OrderDraft

    private let persistence: CartPersistenceService

    init(persistence: CartPersistenceService) {
        self.persistence = persistence
        self.draft = persistence.loadDraft()
    }

    var items: [CartItem] { draft.items }

    // Backward-compatible name used by existing views. This is the national ID, not Firebase uid.
    var clientId: String? {
        get { draft.nationalId }
        set {
            draft.nationalId = newValue?.filter(\.isNumber)
            persist()
        }
    }

    var nationalId: String? {
        get { draft.nationalId }
        set {
            draft.nationalId = newValue?.filter(\.isNumber)
            persist()
        }
    }

    var clientName: String {
        get { draft.clientName }
        set {
            draft.clientName = newValue
            persist()
        }
    }

    var tableNumber: String {
        get { draft.tableNumber }
        set {
            draft.tableNumber = newValue
            persist()
        }
    }

    var scheduledAt: Date { draft.scheduledAt }
    var isScheduledForLater: Bool { draft.isScheduledForLater }
    var canSubmit: Bool { draft.canSubmit }
    var orderCreatedAt: Date { draft.createdAt }
    var totalItems: Int { draft.totalItems }
    var subtotal: Double { draft.subtotal }
    var totalAmount: Double { draft.totalAmount }
    var isEmpty: Bool { draft.isEmpty }

    @discardableResult
    func add(item: MenuItem, quantity: Int = 1, notes: String? = nil) -> Bool {
        guard item.canBeOrdered || isScheduledForLater else { return false }
        guard quantity > 0 else { return false }

        let cleanNotes = notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalNotes = (cleanNotes?.isEmpty == true) ? nil : cleanNotes

        if draft.items.isEmpty {
            let now = Date()
            draft.createdAt = now
            if draft.scheduledAt < now.addingTimeInterval(-120) {
                draft.scheduledAt = now
            }
        }

        if let index = draft.items.firstIndex(where: { $0.menuItem.id == item.id && $0.notes == finalNotes }) {
            let current = draft.items[index].quantity
            let next = isScheduledForLater
                ? current + quantity
                : min(current + quantity, item.remainingQuantity)
            draft.items[index].quantity = max(1, next)
        } else {
            let safeQuantity = isScheduledForLater ? max(1, quantity) : min(quantity, item.remainingQuantity)
            guard safeQuantity > 0 else { return false }
            draft.items.append(CartItem(menuItem: item, quantity: safeQuantity, notes: finalNotes))
        }

        draft.updatedAt = Date()
        persist()
        return true
    }

    func increaseQuantity(for itemId: String, by amount: Int = 1) {
        guard amount > 0 else { return }
        guard let index = draft.items.firstIndex(where: { $0.menuItem.id == itemId }) else { return }

        let menuItem = draft.items[index].menuItem
        guard menuItem.canBeOrdered || isScheduledForLater else { return }

        let current = draft.items[index].quantity
        let next = isScheduledForLater
            ? current + amount
            : min(current + amount, menuItem.remainingQuantity)
        guard next > current else { return }

        draft.items[index].quantity = next
        draft.updatedAt = Date()
        persist()
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

        draft.updatedAt = Date()
        persist()
    }

    func updateQuantity(for itemId: String, quantity: Int) {
        guard let index = draft.items.firstIndex(where: { $0.menuItem.id == itemId }) else { return }

        if quantity <= 0 {
            draft.items.remove(at: index)

            if draft.items.isEmpty {
                resetDraftMetadata()
            }

            draft.updatedAt = Date()
            persist()
            return
        }

        guard draft.items[index].menuItem.isAvailable || isScheduledForLater else { return }
        draft.items[index].quantity = isScheduledForLater
            ? max(1, quantity)
            : min(quantity, draft.items[index].menuItem.remainingQuantity)
        draft.updatedAt = Date()
        persist()
    }

    func remove(itemId: String) {
        draft.items.removeAll { $0.menuItem.id == itemId }

        if draft.items.isEmpty {
            resetDraftMetadata()
        }

        draft.updatedAt = Date()
        persist()
    }

    func updateClientId(_ id: String) {
        draft.nationalId = id.filter(\.isNumber)
        persist()
    }

    func updateClientName(_ name: String) {
        draft.clientName = name
        persist()
    }

    func updateTableNumber(_ table: String) {
        draft.tableNumber = table
        persist()
    }

    func updateScheduledAt(_ date: Date) {
        draft.scheduledAt = OrderScheduleResolver.sanitizedScheduledAt(date)
        draft.updatedAt = Date()
        persist()
    }

    func scheduleForNow() {
        draft.scheduledAt = Date()
        draft.updatedAt = Date()
        persist()
    }

    func refreshDefaultScheduleIfNeeded() {
        let now = Date()
        guard !draft.isScheduledForLater, draft.scheduledAt < now.addingTimeInterval(-120) else { return }
        draft.scheduledAt = now
        draft.updatedAt = now
        persist()
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
        persistence.clear()
    }

    func resetDraftMetadata() {
        draft.clientName = ""
        draft.tableNumber = ""
        draft.scheduledAt = Date()
        draft.createdAt = Date()
    }

    func resetDraftKeepingIdentity() {
        draft = OrderDraft(id: draft.id)
        persist()
    }

    func replaceDraft(with newDraft: OrderDraft) {
        draft = newDraft
        persist()
    }

    func createOrder(firebaseClientId: String? = nil) -> Order? {
        refreshDefaultScheduleIfNeeded()
        guard draft.canSubmit else { return nil }
        return draft.toOrder(clientId: firebaseClientId)
    }

    func submitOrder(firebaseClientId: String? = nil) -> Order? {
        guard let order = createOrder(firebaseClientId: firebaseClientId) else { return nil }
        clear()
        return order
    }

    private func persist() {
        persistence.save(draft: draft)
    }
}
