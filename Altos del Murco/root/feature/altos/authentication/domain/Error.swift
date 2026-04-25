//
//  Error.swift
//  Altos del Murco
//
//  Created by José Ruiz on 24/4/26.
//

import Foundation
import FirebaseAuth

extension Error {
    var isFirebaseSessionInvalidOrDisabled: Bool {
        let nsError = self as NSError

        guard nsError.domain == AuthErrorDomain,
              let code = AuthErrorCode(rawValue: nsError.code) else {
            return false
        }

        switch code {
        case .userDisabled,
             .userNotFound,
             .invalidUserToken,
             .userTokenExpired:
            return true

        default:
            return false
        }
    }
}
