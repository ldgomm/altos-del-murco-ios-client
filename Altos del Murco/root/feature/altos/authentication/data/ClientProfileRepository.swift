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
        let cleanId = profile.id.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanId.isEmpty else {
            throw NSError(
                domain: "ClientProfileRepository",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "No se pudo guardar el perfil porque el usuario no tiene UID válido."]
            )
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                let document = ClientProfileDocument(profile: profile)

                print("🧾 Saving client profile document:", cleanId)
                print("🧾 userId:", document.id)
                print("🧾 id:", document.id)

                try collection.document(cleanId).setData(from: document, merge: true) { error in
                    if let error {
                        print("❌ Client profile save failed:", error.localizedDescription)
                        continuation.resume(throwing: error)
                    } else {
                        print("✅ Client profile saved:", cleanId)
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
