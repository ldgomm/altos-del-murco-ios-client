//
//  MenuItem.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation

struct MenuItem: Identifiable, Hashable {
    let id: String
    let categoryId: String
    let categoryTitle: String
    let name: String
    let description: String
    var notes: String?
    let ingredients: [String]
    let price: Double
    let offerPrice: Double?
    let imageURL: String?
    let isAvailable: Bool
    let remainingQuantity: Int
    let isFeatured: Bool
    let sortOrder: Int

    init(
        id: String,
        categoryId: String,
        categoryTitle: String = "",
        name: String,
        description: String,
        notes: String? = nil,
        ingredients: [String],
        price: Double,
        offerPrice: Double? = nil,
        imageURL: String? = nil,
        isAvailable: Bool = true,
        remainingQuantity: Int = 20,
        isFeatured: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.categoryId = categoryId
        self.categoryTitle = categoryTitle
        self.name = name
        self.description = description
        self.notes = notes
        self.ingredients = ingredients
        self.price = price
        self.offerPrice = offerPrice
        self.imageURL = imageURL
        self.isAvailable = isAvailable
        self.remainingQuantity = max(0, remainingQuantity)
        self.isFeatured = isFeatured
        self.sortOrder = sortOrder
    }

    var hasOffer: Bool {
        guard let offerPrice else { return false }
        return offerPrice < price
    }

    var finalPrice: Double {
        offerPrice ?? price
    }

    var isSoldOut: Bool {
        remainingQuantity <= 0
    }

    var canBeOrdered: Bool {
        isAvailable && remainingQuantity > 0
    }

    var stockLabel: String {
        if !isAvailable { return "No disponible" }
        if remainingQuantity <= 0 { return "Agotado" }
        if remainingQuantity == 1 { return "Último plato" }
        if remainingQuantity <= 5 { return "Quedan \(remainingQuantity)" }
        return "\(remainingQuantity) disponibles"
    }
}
