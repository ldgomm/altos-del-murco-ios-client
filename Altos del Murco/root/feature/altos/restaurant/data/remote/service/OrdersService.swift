//
//  OrdersService.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation
import FirebaseFirestore

final class FirebaseOrdersService: OrdersServiceable {
    private lazy var db = Firestore.firestore()
    
    func submit(order: Order) async throws {
        let dto = OrderDto(from: order)
        let data = try Firestore.Encoder().encode(dto)
        
        print("OrdersService, notes: \(order.items.map { $0.notes ?? "" })")
        try await db
            .collection(FirestoreConstants.restaurant_orders)
            .document(order.id)
            .setData(data)
    }
    
    func observeOrders(for nationalId: String) -> AsyncThrowingStream<[Order], Error> {
        let nationalId = nationalId.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return AsyncThrowingStream { continuation in
            guard !nationalId.isEmpty else {
                continuation.yield([])
                continuation.finish()
                return
            }
            
            let listener = db
                .collection(FirestoreConstants.restaurant_orders)
                .whereField("nationalId", isEqualTo: nationalId)
                .order(by: "createdAt", descending: true)
                .addSnapshotListener { snapshot, error in
                    if let error {
                        continuation.finish(throwing: error)
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        continuation.yield([])
                        return
                    }
                    
                    let orders: [Order] = documents.compactMap { document in
                        do {
                            let dto = try document.data(as: OrderDto.self)
                            return dto.toDomain()
                        } catch {
                            return nil
                        }
                    }
                    
                    continuation.yield(orders)
                }
            
            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }
}

