//
//  Array.swift
//  Altos del Murco
//
//  Created by José Ruiz on 28/4/26.
//

import Foundation

extension Array where Element == MenuSection {
    var menuImageURLs: [URL] {
        flatMap(\.items)
            .compactMap(\.imageURL)
            .compactMap(URL.init(string:))
    }
}
