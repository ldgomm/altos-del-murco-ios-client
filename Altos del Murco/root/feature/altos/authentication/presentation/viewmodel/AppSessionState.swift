//
//  AppSessionState.swift
//  Altos del Murco
//
//  Created by José Ruiz on 29/4/26.
//

import Foundation

enum AppSessionState {
    case loading

    /// No Firebase user is signed in.
    /// Public browsing is allowed.
    case signedOut

    /// Firebase user is signed in, but clients/{uid} is missing or incomplete.
    /// This must block the app with CompleteProfileView.
    case needsProfile(AuthenticatedUser, ClientProfile?)

    /// Firebase user is signed in and profile is complete.
    case authenticated(ClientProfile)

    case error(String)
}
