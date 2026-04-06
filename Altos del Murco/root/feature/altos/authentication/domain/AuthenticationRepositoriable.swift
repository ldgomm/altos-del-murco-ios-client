//
//  AuthenticationRepositoriable.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import Foundation

protocol AuthenticationRepositoriable {
    func currentUser() -> AuthenticatedUser?
    func signInWithApple(
        idToken: String,
        rawNonce: String,
        fullName: String?,
        email: String?,
        appleUserIdentifier: String
    ) async throws -> AuthenticatedUser

    func reauthenticateCurrentUser(
        idToken: String,
        rawNonce: String
    ) async throws

    func deleteCurrentUser() async throws
    func signOut() throws
}
