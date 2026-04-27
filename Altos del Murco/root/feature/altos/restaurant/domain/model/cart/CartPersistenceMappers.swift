//
//  CartPersistenceMappers.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import Foundation

extension CartItemEntity {
    convenience init(from item: CartItem, draft: CartDraftEntity? = nil) {
        let ingredientsData = (try? JSONEncoder().encode(item.menuItem.ingredients)) ?? Data()

        self.init(
            id: item.id,
            menuItemId: item.menuItem.id,
            categoryId: item.menuItem.categoryId,
            name: item.menuItem.name,
            itemDescription: item.menuItem.description,
            quantity: item.quantity,
            notes: item.notes,
            ingredientsData: ingredientsData,
            price: item.menuItem.price,
            offerPrice: item.menuItem.offerPrice,
            imageURL: item.menuItem.imageURL,
            isAvailable: item.menuItem.isAvailable,
            isFeatured: item.menuItem.isFeatured,
            draft: draft
        )
    }

    func toDomain() -> CartItem {
        let ingredients = (try? JSONDecoder().decode([String].self, from: ingredientsData)) ?? []

        let menuItem = MenuItem(
            id: menuItemId,
            categoryId: categoryId,
            name: name,
            description: itemDescription,
            notes: nil,
            ingredients: ingredients,
            price: price,
            offerPrice: offerPrice,
            imageURL: imageURL,
            isAvailable: isAvailable,
            isFeatured: isFeatured
        )

        return CartItem(
            menuItem: menuItem,
            quantity: quantity,
            notes: notes
        )
    }
}

extension CartDraftEntity {
    convenience init(from draft: OrderDraft) {
        self.init(
            id: draft.id,
            clientId: draft.clientId,
            nationalId: draft.nationalId,
            clientName: draft.clientName,
            tableNumber: draft.tableNumber,
            scheduledAt: draft.scheduledAt,
            createdAt: draft.createdAt,
            updatedAt: draft.updatedAt,
            items: []
        )

        self.items = draft.items.map { CartItemEntity(from: $0, draft: self) }
    }

    func toDomain() -> OrderDraft {
        OrderDraft(
            id: id,
            clientId: clientId,
            nationalId: nationalId,
            clientName: clientName,
            tableNumber: tableNumber,
            scheduledAt: scheduledAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            items: items.map { $0.toDomain() }
        )
    }
}
