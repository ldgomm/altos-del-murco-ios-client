//
//  MenuItemDto.swift
//  Altos del Murco
//
//  Created by José Ruiz on 16/4/26.
//

import Foundation
import FirebaseFirestore

struct MenuItemDto: Codable {
    let id: String
    let categoryId: String
    let categoryTitle: String
    let name: String
    let description: String
    let notes: String?
    let ingredients: [String]
    let price: Double
    let offerPrice: Double?
    let imageURL: String?
    let isAvailable: Bool
    let remainingQuantity: Int
    let isFeatured: Bool
    let sortOrder: Int
    let createdAt: Timestamp?
    let updatedAt: Timestamp?

    func toDomain() -> MenuItem {
        MenuItem(
            id: id,
            categoryId: categoryId,
            categoryTitle: categoryTitle,
            name: name,
            description: description,
            notes: notes,
            ingredients: ingredients,
            price: price,
            offerPrice: offerPrice,
            imageURL: imageURL,
            isAvailable: isAvailable,
            remainingQuantity: max(0, remainingQuantity),
            isFeatured: isFeatured,
            sortOrder: sortOrder
        )
    }
}
