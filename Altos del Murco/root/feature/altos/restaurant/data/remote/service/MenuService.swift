//
//  MenuService.swift
//  Altos del Murco
//
//  Created by José Ruiz on 16/4/26.
//

import Foundation
import FirebaseFirestore

final class MenuService: MenuServiceable {
    private let db: Firestore

    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

    func observeMenu(
        onChange: @escaping (Result<[MenuSection], Error>) -> Void
    ) -> MenuListenerTokenable {
        let registration = db
            .collection(FirestoreConstants.restaurant_menu_items)
            .order(by: "categoryTitle")
            .order(by: "sortOrder")
            .addSnapshotListener { snapshot, error in
                if let error {
                    onChange(.failure(error))
                    return
                }

                guard let documents = snapshot?.documents else {
                    onChange(.success([]))
                    return
                }

                do {
                    let items = try documents.map { document in
                        try document.data(as: MenuItemDto.self).toDomain()
                    }

                    let sections = Self.groupIntoSections(items: items)
                    onChange(.success(sections))
                } catch {
                    onChange(.failure(error))
                }
            }

        return MenuListenerToken(registration: registration)
    }

    private static func groupIntoSections(items: [MenuItem]) -> [MenuSection] {
        let grouped = Dictionary(grouping: items, by: \.categoryId)

        let sections = grouped.compactMap { categoryId, items -> MenuSection? in
            guard let first = items.first else { return nil }

            return MenuSection(
                id: categoryId,
                category: MenuCategory(
                    id: categoryId,
                    title: first.categoryTitle
                ),
                items: items.sorted { $0.sortOrder < $1.sortOrder }
            )
        }

        return sections.sorted { $0.category.title < $1.category.title }
    }
}
