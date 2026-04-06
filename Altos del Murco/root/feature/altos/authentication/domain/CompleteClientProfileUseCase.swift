//
//  CompleteClientProfileUseCase.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import Foundation

final class CompleteClientProfileUseCase {
    private let repository: ClientProfileRepositoriable

    init(repository: ClientProfileRepositoriable) {
        self.repository = repository
    }

    func execute(profile: ClientProfile) async throws {
        try await repository.saveProfile(profile)
    }
}
