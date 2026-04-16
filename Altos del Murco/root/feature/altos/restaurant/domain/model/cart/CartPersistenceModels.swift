//
//  CartPersistenceModels.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import Foundation
import SwiftData

@Model
final class CartDraftEntity {
    @Attribute(.unique) var id: UUID
    var nationalId: String?
    var clientName: String
    var tableNumber: String
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \CartItemEntity.draft)
    var items: [CartItemEntity]

    init(
        id: UUID = UUID(),
        nationalId: String? = nil,
        clientName: String = "",
        tableNumber: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        items: [CartItemEntity] = []
    ) {
        self.id = id
        self.nationalId = nationalId
        self.clientName = clientName
        self.tableNumber = tableNumber
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.items = items
    }
}

@Model
final class CartItemEntity {
    var id: UUID
    var menuItemId: String
    var categoryId: String
    var name: String
    var itemDescription: String
    var quantity: Int
    var notes: String?
    var ingredientsData: Data
    var price: Double
    var offerPrice: Double?
    var imageURL: String?
    var isAvailable: Bool
    var isFeatured: Bool

    var draft: CartDraftEntity?

    init(
        id: UUID = UUID(),
        menuItemId: String,
        categoryId: String,
        name: String,
        itemDescription: String,
        quantity: Int,
        notes: String?,
        ingredientsData: Data,
        price: Double,
        offerPrice: Double?,
        imageURL: String?,
        isAvailable: Bool,
        isFeatured: Bool,
        draft: CartDraftEntity? = nil
    ) {
        self.id = id
        self.menuItemId = menuItemId
        self.categoryId = categoryId
        self.name = name
        self.itemDescription = itemDescription
        self.quantity = quantity
        self.notes = notes
        self.ingredientsData = ingredientsData
        self.price = price
        self.offerPrice = offerPrice
        self.imageURL = imageURL
        self.isAvailable = isAvailable
        self.isFeatured = isFeatured
        self.draft = draft
    }
}
