//
//  MenuSection.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation

struct MenuSection: Identifiable, Hashable {
    let id: String
    let category: MenuCategory
    let items: [MenuItem]
}
