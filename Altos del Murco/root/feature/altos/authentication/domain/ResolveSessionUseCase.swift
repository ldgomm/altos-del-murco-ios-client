//
//  ResolveSessionUseCase.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import Foundation

enum SessionDestination {
    case signedOut

    case needsProfile(AuthenticatedUser, ClientProfile?)

    case authenticated(ClientProfile)
}

final class ResolveSessionUseCase {
    private let authRepository: AuthenticationRepositoriable
    private let clientProfileRepository: ClientProfileRepositoriable

    init(
        authRepository: AuthenticationRepositoriable,
        clientProfileRepository: ClientProfileRepositoriable
    ) {
        self.authRepository = authRepository
        self.clientProfileRepository = clientProfileRepository
    }

    func execute() async throws -> SessionDestination {
        guard let user = authRepository.currentUser() else {
            return .signedOut
        }

        return try await execute(for: user)
    }

    func execute(for user: AuthenticatedUser) async throws -> SessionDestination {
        let profile = try await clientProfileRepository.fetchProfile(uid: user.uid)

        if let profile {
            return .authenticated(profile)
        }

        return .authenticated(ClientProfile.starter(from: user))
    }
}
