//
//  SignOutUseCase.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import Foundation

final class SignOutUseCase {
    private let repository: AuthenticationRepositoriable

    init(repository: AuthenticationRepositoriable) {
        self.repository = repository
    }

    func execute() throws {
        try repository.signOut()
    }
}
