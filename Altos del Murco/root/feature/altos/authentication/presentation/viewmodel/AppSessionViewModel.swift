//
//  AppSessionViewModel.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import Combine
import AuthenticationServices

@MainActor
final class AppSessionViewModel: ObservableObject {
    @Published private(set) var state: AppSessionState = .loading

    private let signInWithAppleUseCase: SignInWithAppleUseCase
    private let resolveSessionUseCase: ResolveSessionUseCase
    private let completeClientProfileUseCase: CompleteClientProfileUseCase
    private let deleteCurrentAccountUseCase: DeleteCurrentAccountUseCase
    private let signOutUseCase: SignOutUseCase

    private var currentNonce: String?

    init(
        signInWithAppleUseCase: SignInWithAppleUseCase,
        resolveSessionUseCase: ResolveSessionUseCase,
        completeClientProfileUseCase: CompleteClientProfileUseCase,
        deleteCurrentAccountUseCase: DeleteCurrentAccountUseCase,
        signOutUseCase: SignOutUseCase
    ) {
        self.signInWithAppleUseCase = signInWithAppleUseCase
        self.resolveSessionUseCase = resolveSessionUseCase
        self.completeClientProfileUseCase = completeClientProfileUseCase
        self.deleteCurrentAccountUseCase = deleteCurrentAccountUseCase
        self.signOutUseCase = signOutUseCase

        Task { await bootstrap() }
    }

    var screenKey: String {
        switch state {
        case .loading:
            return "loading"
        case .signedOut:
            return "signedOut"
        case .needsProfile:
            return "needsProfile"
        case .authenticated:
            return "authenticated"
        case .error:
            return "error"
        }
    }

    var authenticatedProfile: ClientProfile? {
        guard case .authenticated(let profile) = state else { return nil }
        return profile
    }

    func bootstrap() async {
        state = .loading

        do {
            let destination = try await resolveSessionUseCase.execute()
            state = map(destination)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func onRequestSignIn(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]

        let nonce = AppleNonce.randomNonceString()
        currentNonce = nonce
        request.nonce = AppleNonce.sha256(nonce)
    }

    func onCompletionSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            Task {
                await handleAuthorization(authorization)
            }

        case .failure(let error):
            if let authorizationError = error as? ASAuthorizationError,
               authorizationError.code == .canceled {
                return
            }

            state = .error(error.localizedDescription)
        }
    }

    func signOut() {
        Task {
            do {
                try signOutUseCase.execute()
                state = .signedOut
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }

    func makeCompleteProfileViewModel(
        user: AuthenticatedUser,
        existingProfile: ClientProfile?
    ) -> CompleteProfileViewModel {
        CompleteProfileViewModel(
            authenticatedUser: user,
            existingProfile: existingProfile,
            completeClientProfileUseCase: completeClientProfileUseCase,
            onCompleted: { [weak self] profile in
                self?.state = .authenticated(profile)
            }
        )
    }

    func makeProfileViewModelFactory(appPreferences: AppPreferences) -> (() -> ProfileViewModel)? {
        guard let profile = authenticatedProfile else { return nil }

        let saveUseCase = completeClientProfileUseCase
        let deleteUseCase = deleteCurrentAccountUseCase
        let imageStorageService = ProfileImageStorageService()
        let statsService = ProfileStatsService()

        return { [weak self] in
            ProfileViewModel(
                initialProfile: profile,
                appPreferences: appPreferences,
                completeClientProfileUseCase: saveUseCase,
                deleteCurrentAccountUseCase: deleteUseCase,
                profileImageStorageService: imageStorageService,
                profileStatsService: statsService,
                onProfileUpdated: { [weak self] updatedProfile in
                    self?.state = .authenticated(updatedProfile)
                },
                onSignOut: { [weak self] in
                    self?.signOut()
                },
                onAccountDeleted: { [weak self] in
                    self?.state = .signedOut
                }
            )
        }
    }

    private func handleAuthorization(_ authorization: ASAuthorization) async {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            state = .error("Could not read the Apple credential.")
            return
        }

        guard let nonce = currentNonce else {
            state = .error("Invalid sign in state. Please try again.")
            return
        }

        guard let identityToken = credential.identityToken,
              let idToken = String(data: identityToken, encoding: .utf8) else {
            state = .error("Unable to read the Apple identity token.")
            return
        }

        let formatter = PersonNameComponentsFormatter()
        let formattedName = credential.fullName
            .map { formatter.string(from: $0).trimmingCharacters(in: .whitespacesAndNewlines) }
        let finalName = (formattedName?.isEmpty == false) ? formattedName : nil

        state = .loading

        do {
            let user = try await signInWithAppleUseCase.execute(
                idToken: idToken,
                rawNonce: nonce,
                fullName: finalName,
                email: credential.email,
                appleUserIdentifier: credential.user
            )

            let destination = try await resolveSessionUseCase.execute(for: user)
            state = map(destination)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    private func map(_ destination: SessionDestination) -> AppSessionState {
        switch destination {
        case .signedOut:
            return .signedOut
        case .needsProfile(let user, let existingProfile):
            return .needsProfile(user, existingProfile)
        case .authenticated(let profile):
            return .authenticated(profile)
        }
    }
}

enum AppSessionState {
    case loading
    case signedOut
    case needsProfile(AuthenticatedUser, ClientProfile?)
    case authenticated(ClientProfile)
    case error(String)
}
