//
//  ProfileViewModel.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import Combine
import AuthenticationServices

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published private(set) var profile: ClientProfile
    @Published private(set) var stats: ProfileStats = .empty

    @Published var isShowingEditProfile = false
    @Published var isShowingDeleteAccountSheet = false
    @Published var alertItem: ProfileAlertItem?
    @Published private(set) var isDeletingAccount = false

    private let appPreferences: AppPreferences
    private let completeClientProfileUseCase: CompleteClientProfileUseCase
    private let deleteCurrentAccountUseCase: DeleteCurrentAccountUseCase
    private let onProfileUpdated: @MainActor (ClientProfile) -> Void
    private let onSignOut: @MainActor () -> Void
    private let onAccountDeleted: @MainActor () -> Void

    private var deleteNonce: String?

    init(
        initialProfile: ClientProfile,
        appPreferences: AppPreferences,
        completeClientProfileUseCase: CompleteClientProfileUseCase,
        deleteCurrentAccountUseCase: DeleteCurrentAccountUseCase,
        onProfileUpdated: @escaping @MainActor (ClientProfile) -> Void,
        onSignOut: @escaping @MainActor () -> Void,
        onAccountDeleted: @escaping @MainActor () -> Void
    ) {
        self.profile = initialProfile
        self.appPreferences = appPreferences
        self.completeClientProfileUseCase = completeClientProfileUseCase
        self.deleteCurrentAccountUseCase = deleteCurrentAccountUseCase
        self.onProfileUpdated = onProfileUpdated
        self.onSignOut = onSignOut
        self.onAccountDeleted = onAccountDeleted
    }

    var displayName: String {
        profile.fullName.isEmpty ? "Guest User" : profile.fullName
    }

    var emailText: String {
        profile.email.isEmpty ? "Hidden by Apple" : profile.email
    }

    var phoneText: String {
        profile.phoneNumber.isEmpty ? "Not provided" : profile.phoneNumber
    }

    var birthdayText: String {
        profile.birthday.formatted(date: .long, time: .omitted)
    }

    var addressText: String {
        profile.address.isEmpty ? "Not provided" : profile.address
    }

    var memberSinceText: String {
        profile.createdAt.formatted(date: .abbreviated, time: .omitted)
    }

    var appearanceTitle: String {
        appPreferences.appearance.title
    }

    var currentAppearance: AppAppearance {
        appPreferences.appearance
    }

    func updateAppearance(_ appearance: AppAppearance) {
        appPreferences.appearance = appearance
        objectWillChange.send()
    }

    func openEditProfile() {
        isShowingEditProfile = true
    }

    func signOutTapped() {
        onSignOut()
    }

    func askForDeleteAccount() {
        isShowingDeleteAccountSheet = true
    }

    func handleProfileSaved(_ updatedProfile: ClientProfile) {
        profile = updatedProfile
        onProfileUpdated(updatedProfile)
    }

    func makeEditProfileViewModel() -> EditProfileViewModel {
        EditProfileViewModel(
            profile: profile,
            completeClientProfileUseCase: completeClientProfileUseCase,
            onSaved: { [weak self] updatedProfile in
                self?.handleProfileSaved(updatedProfile)
            }
        )
    }

    func onDeleteRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = []

        let nonce = AppleNonce.randomNonceString()
        deleteNonce = nonce
        request.nonce = AppleNonce.sha256(nonce)
    }

    func onDeleteCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            Task {
                await handleDeleteAuthorization(authorization)
            }

        case .failure(let error):
            if let authorizationError = error as? ASAuthorizationError,
               authorizationError.code == .canceled {
                return
            }

            alertItem = ProfileAlertItem(
                title: "Deletion cancelled",
                message: error.localizedDescription
            )
        }
    }

    private func handleDeleteAuthorization(_ authorization: ASAuthorization) async {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            alertItem = ProfileAlertItem(
                title: "Unable to continue",
                message: "Could not read your Apple credential."
            )
            return
        }

        guard let nonce = deleteNonce else {
            alertItem = ProfileAlertItem(
                title: "Invalid state",
                message: "Please try deleting the account again."
            )
            return
        }

        guard let identityToken = credential.identityToken,
              let idToken = String(data: identityToken, encoding: .utf8) else {
            alertItem = ProfileAlertItem(
                title: "Unable to continue",
                message: "Could not read the Apple identity token."
            )
            return
        }

        isDeletingAccount = true

        do {
            try await deleteCurrentAccountUseCase.execute(
                currentUserId: profile.id,
                idToken: idToken,
                rawNonce: nonce
            )
            isDeletingAccount = false
            onAccountDeleted()
        } catch {
            isDeletingAccount = false
            alertItem = ProfileAlertItem(
                title: "Could not delete account",
                message: error.localizedDescription
            )
        }
    }
}
