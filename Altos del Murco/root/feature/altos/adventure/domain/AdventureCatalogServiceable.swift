//
//  AdventureCatalogServiceable.swift
//  Altos del Murco
//
//  Created by José Ruiz on 19/4/26.
//

import Foundation

protocol AdventureCatalogServiceable {
    func fetchCatalog() async throws -> AdventureCatalogSnapshot
}
