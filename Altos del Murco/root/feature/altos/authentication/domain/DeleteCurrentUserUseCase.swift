//
//  DeleteCurrentUserUseCase.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import Foundation

final class DeleteCurrentAccountUseCase {
    private let authRepository: AuthenticationRepositoriable
    private let clientProfileRepository: ClientProfileRepositoriable

    init(
        authRepository: AuthenticationRepositoriable,
        clientProfileRepository: ClientProfileRepositoriable
    ) {
        self.authRepository = authRepository
        self.clientProfileRepository = clientProfileRepository
    }

    func execute(
        currentUserId: String,
        idToken: String,
        rawNonce: String
    ) async throws {
        try await authRepository.reauthenticateCurrentUser(
            idToken: idToken,
            rawNonce: rawNonce
        )

        try await clientProfileRepository.deleteProfile(uid: currentUserId)
        try await authRepository.deleteCurrentUser()
    }
}
