//
//  VerifyCurrentUserSessionUseCase.swift
//  Altos del Murco
//
//  Created by José Ruiz on 24/4/26.
//

import Foundation

import Foundation

final class VerifyCurrentUserSessionUseCase {
    private let repository: AuthenticationRepositoriable

    init(repository: AuthenticationRepositoriable) {
        self.repository = repository
    }

    func execute() async throws {
        try await repository.verifyCurrentUserIsStillValid()
    }
}
