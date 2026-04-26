//
//  CartPersistenceService.swift
//  Altos del Murco
//
//  Created by José Ruiz on 25/4/26.
//

import Foundation
import SwiftData

@MainActor
final class CartPersistenceService {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func loadDraft() -> OrderDraft {
        let descriptor = FetchDescriptor<CartDraftEntity>()

        do {
            let drafts = try context.fetch(descriptor)
            return drafts.first?.toDomain() ?? OrderDraft()
        } catch {
            print("Failed to load cart draft: \(error)")
            return OrderDraft()
        }
    }

    func save(draft: OrderDraft) {
        do {
            let existing = try context.fetch(FetchDescriptor<CartDraftEntity>())
            for entity in existing {
                context.delete(entity)
            }

            let newEntity = CartDraftEntity(from: draft)
            context.insert(newEntity)

            try context.save()
        } catch {
            print("Failed to save cart draft: \(error)")
        }
    }

    func clear() {
        do {
            let existing = try context.fetch(FetchDescriptor<CartDraftEntity>())
            for entity in existing {
                context.delete(entity)
            }
            try context.save()
        } catch {
            print("Failed to clear cart draft: \(error)")
        }
    }
}
