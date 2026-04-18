//
//  FeaturedPostModels.swift
//  Altos del Murco
//
//  Created by José Ruiz on 14/4/26.
//

import Foundation
import FirebaseFirestore

enum FeaturedPostCategory: String, Codable, CaseIterable, Identifiable {
    case restaurant
    case adventure
    case clients

    var id: String { rawValue }

    var title: String {
        switch self {
        case .restaurant: return "Restaurante"
        case .adventure: return "Aventura"
        case .clients: return "Clientes"
        }
    }
}

struct FeaturedPostMediaDto: Codable, Hashable, Identifiable {
    let id: String
    let downloadURL: String
    let storagePath: String
    let width: CGFloat
    let height: CGFloat
    let position: Int
}

struct FeaturedPostDto: Codable {
    @DocumentID var id: String?
    let category: String
    let description: String?
    let media: [FeaturedPostMediaDto]
    let createdAt: Date
    let updatedAt: Date
    let expiresAt: Date
    let isVisible: Bool
}

struct FeaturedPostMedia: Identifiable, Hashable {
    let id: String
    let downloadURL: URL?
    let storagePath: String
    let width: CGFloat
    let height: CGFloat
    let position: Int

    var aspectRatio: CGFloat {
        guard height > 0 else { return 1 }
        return width / height
    }
}

struct FeaturedPost: Identifiable, Hashable {
    let id: String
    let category: FeaturedPostCategory
    let description: String?
    let media: [FeaturedPostMedia]
    let createdAt: Date
    let updatedAt: Date
    let expiresAt: Date
    let isVisible: Bool

    var isExpired: Bool {
        expiresAt <= Date()
    }

    var orderedMedia: [FeaturedPostMedia] {
        media.sorted { $0.position < $1.position }
    }
}

extension FeaturedPostDto {
    func toDomain() -> FeaturedPost? {
        guard let id else { return nil }
        guard let category = FeaturedPostCategory(rawValue: category) else { return nil }

        return FeaturedPost(
            id: id,
            category: category,
            description: description?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            media: media
                .sorted(by: { $0.position < $1.position })
                .map {
                    FeaturedPostMedia(
                        id: $0.id,
                        downloadURL: URL(string: $0.downloadURL),
                        storagePath: $0.storagePath,
                        width: $0.width,
                        height: $0.height,
                        position: $0.position
                    )
                },
            createdAt: createdAt,
            updatedAt: updatedAt,
            expiresAt: expiresAt,
            isVisible: isVisible
        )
    }
}

extension FeaturedPost {
    func toDto() -> FeaturedPostDto {
        FeaturedPostDto(
            id: id,
            category: category.rawValue,
            description: description,
            media: orderedMedia.map {
                FeaturedPostMediaDto(
                    id: $0.id,
                    downloadURL: $0.downloadURL?.absoluteString ?? "",
                    storagePath: $0.storagePath,
                    width: $0.width,
                    height: $0.height,
                    position: $0.position
                )
            },
            createdAt: createdAt,
            updatedAt: updatedAt,
            expiresAt: expiresAt,
            isVisible: isVisible
        )
    }
}

extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
