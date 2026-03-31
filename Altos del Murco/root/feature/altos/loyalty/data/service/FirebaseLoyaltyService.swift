//
//  FirebaseLoyaltyService.swift
//  Altos del Murco
//
//  Created by José Ruiz on 13/3/26.
//

import Foundation
import FirebaseFirestore
import FirebaseFunctions

final class FirebaseLoyaltyService: LoyaltyServiceable {
    private let db: Firestore
    private let functions: Functions
    
    init(
        db: Firestore = Firestore.firestore(),
        functions: Functions = Functions.functions()
    ) {
        self.db = db
        self.functions = functions
    }
    
    func observeWallet(clientId: String) -> AsyncThrowingStream<LoyaltyWallet, Error> {
        AsyncThrowingStream { continuation in
            let listener = db.collection("client_wallets")
                .document(clientId)
                .addSnapshotListener { snapshot, error in
                    if let error {
                        continuation.finish(throwing: error)
                        return
                    }
                    
                    guard let snapshot, snapshot.exists else {
                        continuation.yield(
                            LoyaltyWallet(
                                clientId: clientId,
                                totalAvailablePoints: 0,
                                providerBalances: [],
                                updatedAt: .now
                            )
                        )
                        return
                    }
                    
                    do {
                        let dto = try snapshot.data(as: FirestoreWalletDTO.self)
                        continuation.yield(dto.toDomain())
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }
            
            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }
    
    func fetchRewards() async throws -> [Reward] {
        let snapshot = try await db.collection("rewards")
            .whereField("isActive", isEqualTo: true)
            .getDocuments()
        
        return try snapshot.documents
            .map { try $0.data(as: FirestoreRewardDTO.self).toDomain() }
            .sorted { $0.pointsRequired < $1.pointsRequired }
    }
    
    func fetchTransactions(clientId: String) async throws -> [LoyaltyTransaction] {
        let snapshot = try await db.collection("clients")
            .document(clientId)
            .collection("wallet_transactions")
            .order(by: "createdAt", descending: true)
            .limit(to: 30)
            .getDocuments()
        
        return try snapshot.documents.map {
            try $0.data(as: FirestoreTransactionDTO.self).toDomain()
        }
    }
    
    func previewRedemption(clientId: String, rewardId: String) async throws -> RedemptionPreview {
        let payload: [String: Any] = [
            "clientId": clientId,
            "rewardId": rewardId
        ]
        
        let result = try await functions
            .httpsCallable("previewRewardRedemption")
            .call(payload)
        
        let dto = try CallablePayloadDecoder.decode(CallablePreviewDTO.self, from: result.data)
        return dto.toDomain()
    }
    
    func redeemReward(clientId: String, rewardId: String) async throws -> RedemptionResult {
        let payload: [String: Any] = [
            "clientId": clientId,
            "rewardId": rewardId
        ]
        
        let result = try await functions
            .httpsCallable("redeemReward")
            .call(payload)
        
        let dto = try CallablePayloadDecoder.decode(CallableRedemptionResultDTO.self, from: result.data)
        return dto.toDomain()
    }
}
