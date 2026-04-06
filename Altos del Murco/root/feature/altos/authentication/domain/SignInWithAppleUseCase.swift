//
//  SignInWithAppleUseCase.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import Foundation

final class SignInWithAppleUseCase {
    private let repository: AuthenticationRepositoriable

    init(repository: AuthenticationRepositoriable) {
        self.repository = repository
    }

    func execute(
        idToken: String,
        rawNonce: String,
        fullName: String?,
        email: String?,
        appleUserIdentifier: String
    ) async throws -> AuthenticatedUser {
        try await repository.signInWithApple(
            idToken: idToken,
            rawNonce: rawNonce,
            fullName: fullName,
            email: email,
            appleUserIdentifier: appleUserIdentifier
        )
    }
}
