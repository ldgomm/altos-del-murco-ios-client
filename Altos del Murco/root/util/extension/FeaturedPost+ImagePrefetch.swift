//
//  FeaturedPost+ImagePrefetch.swift
//  Altos del Murco
//
//  Created by José Ruiz on 28/4/26.
//

import Foundation

extension FeaturedPost {
    var imageURLs: [URL] {
        orderedMedia.compactMap(\.downloadURL)
    }
}

extension Array where Element == FeaturedPost {
    var featuredPostImageURLs: [URL] {
        flatMap(\.imageURLs)
    }
}
