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
    let name: String
    let description: String
    var notes: String?
    let ingredients: [String]
    let price: Double
    let offerPrice: Double?
    let imageURL: String?
    let isAvailable: Bool
    let isFeatured: Bool
    
    var hasOffer: Bool {
        guard let offerPrice else { return false }
        return offerPrice < price
    }
    
    var finalPrice: Double {
        offerPrice ?? price
    }
}

