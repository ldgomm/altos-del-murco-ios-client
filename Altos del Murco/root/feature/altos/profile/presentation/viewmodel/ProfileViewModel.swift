//
//  ProfileViewModel.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import Combine
import AuthenticationServices
import Foundation
import UIKit

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published private(set) var profile: ClientProfile
    @Published private(set) var stats: ProfileStats = .empty
    @Published var avatarImage: UIImage?
    @Published private(set) var isLoadingStats = false
    @Published private(set) var isUploadingProfileImage = false

    @Published var isShowingEditProfile = false
    @Published var isShowingDeleteAccountSheet = false
    @Published var alertItem: ProfileAlertItem?
    @Published private(set) var isDeletingAccount = false

    private let appPreferences: AppPreferences
    private let completeClientProfileUseCase: CompleteClientProfileUseCase
    private let deleteCurrentAccountUseCase: DeleteCurrentAccountUseCase
    private let profileImageStorageService: ProfileImageStorageService
    private let profileStatsService: ProfileStatsService
    private let onProfileUpdated: @MainActor (ClientProfile) -> Void
    private let onSignOut: @MainActor () -> Void
    private let onAccountDeleted: @MainActor () -> Void

    private var deleteNonce: String?
    private var statsListenerToken: ProfileStatsListenerToken?

    init(
        initialProfile: ClientProfile,
        appPreferences: AppPreferences,
        completeClientProfileUseCase: CompleteClientProfileUseCase,
        deleteCurrentAccountUseCase: DeleteCurrentAccountUseCase,
        profileImageStorageService: ProfileImageStorageService,
        profileStatsService: ProfileStatsService,
        onProfileUpdated: @escaping @MainActor (ClientProfile) -> Void,
        onSignOut: @escaping @MainActor () -> Void,
        onAccountDeleted: @escaping @MainActor () -> Void
    ) {
        self.profile = initialProfile
        self.appPreferences = appPreferences
        self.completeClientProfileUseCase = completeClientProfileUseCase
        self.deleteCurrentAccountUseCase = deleteCurrentAccountUseCase
        self.profileImageStorageService = profileImageStorageService
        self.profileStatsService = profileStatsService
        self.onProfileUpdated = onProfileUpdated
        self.onSignOut = onSignOut
        self.onAccountDeleted = onAccountDeleted

        Task {
            await loadAvatar()
            startObservingStats()
        }
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

    var hasProfileImage: Bool {
        profile.hasProfileImage || avatarImage != nil
    }

    func onAppear() {
        startObservingStats()
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

        Task {
            await loadAvatar()
            startObservingStats()
        }
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


    private func startObservingStats() {
        statsListenerToken?.remove()
        statsListenerToken = nil

        let userId = profile.id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userId.isEmpty else {
            stats = .empty
            isLoadingStats = false
            return
        }

        isLoadingStats = true

        statsListenerToken = profileStatsService.observeStats() { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let stats):
                self.stats = stats
                self.isLoadingStats = false

            case .failure(let error):
                self.isLoadingStats = false
                self.alertItem = ProfileAlertItem(
                    title: "Could not load profile stats",
                    message: error.localizedDescription
                )
            }
        }
    }

    func refreshStats() async {
        let userId = profile.id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userId.isEmpty else {
            stats = .empty
            return
        }

        isLoadingStats = true
        defer { isLoadingStats = false }

        do {
            stats = try await profileStatsService.loadStats()
        } catch {
            alertItem = ProfileAlertItem(
                title: "Could not load profile stats",
                message: error.localizedDescription
            )
        }
    }

    func uploadProfileImage(data: Data) {
        isUploadingProfileImage = true
        alertItem = nil

        Task {
            do {
                let uploaded = try await profileImageStorageService.uploadProfileImage(
                    data: data,
                    userId: profile.id,
                    replacing: profile.profileImagePath
                )

                _ = try ProfileImageCache.shared.saveImageData(
                    UIImage(data: data)?.jpegData(compressionQuality: 0.82) ?? data,
                    for: profile.id
                )

                let updatedProfile = ClientProfile(
                    id: profile.id,
                    email: profile.email,
                    appleUserIdentifier: profile.appleUserIdentifier,
                    fullName: profile.fullName,
                    phoneNumber: profile.phoneNumber,
                    birthday: profile.birthday,
                    address: profile.address,
                    emergencyContactName: profile.emergencyContactName,
                    emergencyContactPhone: profile.emergencyContactPhone,
                    isProfileComplete: profile.isProfileComplete,
                    createdAt: profile.createdAt,
                    updatedAt: Date(),
                    profileCompletedAt: profile.profileCompletedAt,
                    profileImageURL: uploaded.downloadURL,
                    profileImagePath: uploaded.storagePath
                )

                try await completeClientProfileUseCase.execute(profile: updatedProfile)
                avatarImage = ProfileImageCache.shared.loadImage(for: profile.id)
                handleProfileSaved(updatedProfile)
            } catch {
                alertItem = ProfileAlertItem(
                    title: "Could not update profile photo",
                    message: error.localizedDescription
                )
            }

            isUploadingProfileImage = false
        }
    }

    func removeProfileImage() {
        isUploadingProfileImage = true
        alertItem = nil

        Task {
            do {
                try await profileImageStorageService.deleteProfileImage(path: profile.profileImagePath)
                ProfileImageCache.shared.removeImage(for: profile.id)

                let updatedProfile = ClientProfile(
                    id: profile.id,
                    email: profile.email,
                    appleUserIdentifier: profile.appleUserIdentifier,
                    fullName: profile.fullName,
                    phoneNumber: profile.phoneNumber,
                    birthday: profile.birthday,
                    address: profile.address,
                    emergencyContactName: profile.emergencyContactName,
                    emergencyContactPhone: profile.emergencyContactPhone,
                    isProfileComplete: profile.isProfileComplete,
                    createdAt: profile.createdAt,
                    updatedAt: Date(),
                    profileCompletedAt: profile.profileCompletedAt,
                    profileImageURL: nil,
                    profileImagePath: nil
                )

                try await completeClientProfileUseCase.execute(profile: updatedProfile)
                avatarImage = nil
                handleProfileSaved(updatedProfile)
            } catch {
                alertItem = ProfileAlertItem(
                    title: "Could not delete profile photo",
                    message: error.localizedDescription
                )
            }

            isUploadingProfileImage = false
        }
    }

    private func loadAvatar() async {
        if let cached = ProfileImageCache.shared.loadImage(for: profile.id) {
            avatarImage = cached
            return
        }

        guard let urlString = profile.profileImageURL,
              let url = URL(string: urlString) else {
            avatarImage = nil
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = try ProfileImageCache.shared.saveImageData(data, for: profile.id) {
                avatarImage = image
            }
        } catch {
            avatarImage = nil
        }
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
            try await profileImageStorageService.deleteProfileImage(path: profile.profileImagePath)
            ProfileImageCache.shared.removeImage(for: profile.id)

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
