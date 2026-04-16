//
//  FirestoreClientProfileRepository.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import Foundation
import FirebaseFirestore

final class ClientProfileRepository: ClientProfileRepositoriable {
    private let collection = Firestore.firestore().collection("clients")

    func fetchProfile(uid: String) async throws -> ClientProfile? {
        try await withCheckedThrowingContinuation { continuation in
            collection.document(uid).getDocument { snapshot, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let snapshot, snapshot.exists else {
                    continuation.resume(returning: nil)
                    return
                }

                do {
                    let document = try snapshot.data(as: ClientProfileDocument.self)
                    continuation.resume(returning: document.toDomain())
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func saveProfile(_ profile: ClientProfile) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                let document = ClientProfileDocument(profile: profile)

                try collection.document(profile.id).setData(from: document, merge: true) { error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    func deleteProfile(uid: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            collection.document(uid).delete { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}
