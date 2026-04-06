//
//  FirebaseAutheticationRepository.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import Foundation
import FirebaseAuth

final class FirebaseAuthenticationRepository: AuthenticationRepositoriable {
    func currentUser() -> AuthenticatedUser? {
        guard let user = Auth.auth().currentUser else {
            return nil
        }

        let appleProviderUID = user.providerData.first(where: { $0.providerID == "apple.com" })?.uid ?? ""

        return AuthenticatedUser(
            uid: user.uid,
            email: user.email ?? "",
            displayName: user.displayName ?? "",
            appleUserIdentifier: appleProviderUID
        )
    }

    func signInWithApple(
        idToken: String,
        rawNonce: String,
        fullName: String?,
        email: String?,
        appleUserIdentifier: String
    ) async throws -> AuthenticatedUser {
        let credential = OAuthProvider.credential(
            providerID: .apple,
            idToken: idToken,
            rawNonce: rawNonce
        )

        let authResult: AuthDataResult = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<AuthDataResult, Error>) in
            Auth.auth().signIn(with: credential) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let result {
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(throwing: NSError(
                        domain: "FirebaseAuthenticationRepository",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Unknown authentication error."]
                    ))
                }
            }
        }

        let firebaseUser = authResult.user
        let finalDisplayName = fullName?.trimmed.nilIfEmpty ?? firebaseUser.displayName ?? ""
        let finalEmail = email?.trimmed.nilIfEmpty ?? firebaseUser.email ?? ""
        let providerUID = firebaseUser.providerData.first(where: { $0.providerID == "apple.com" })?.uid
        let finalAppleIdentifier = providerUID?.nilIfEmpty ?? appleUserIdentifier

        return AuthenticatedUser(
            uid: firebaseUser.uid,
            email: finalEmail,
            displayName: finalDisplayName,
            appleUserIdentifier: finalAppleIdentifier
        )
    }

    func reauthenticateCurrentUser(
        idToken: String,
        rawNonce: String
    ) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(
                domain: "FirebaseAuthenticationRepository",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "No authenticated user found."]
            )
        }

        let credential = OAuthProvider.credential(
            providerID: .apple,
            idToken: idToken,
            rawNonce: rawNonce
        )

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            currentUser.reauthenticate(with: credential) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    func deleteCurrentUser() async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(
                domain: "FirebaseAuthenticationRepository",
                code: -3,
                userInfo: [NSLocalizedDescriptionKey: "No authenticated user to delete."]
            )
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            currentUser.delete { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }
}
