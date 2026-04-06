//
//  AutheticatedUser.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import Foundation

struct AuthenticatedUser: Equatable {
    let uid: String
    let email: String
    let displayName: String
    let appleUserIdentifier: String
}
