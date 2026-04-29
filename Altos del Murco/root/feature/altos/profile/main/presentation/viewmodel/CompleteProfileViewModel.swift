//
//  CompleteProfileViewModel.swift
//  Altos del Murco
//
//  Created by José Ruiz on 19/4/26.
//

import Combine
import Foundation

@MainActor
final class CompleteProfileViewModel: ObservableObject {
    @Published var fullName: String
    @Published var nationalId: String
    @Published var phoneNumber: String
    @Published var birthday: Date
    @Published var address: String
    @Published var emergencyContactName: String
    @Published var emergencyContactPhone: String

    @Published private(set) var isSaving = false
    @Published var errorMessage: String?

    let validBirthdayRange: ClosedRange<Date>

    private let authenticatedUser: AuthenticatedUser
    private let existingProfile: ClientProfile?
    private let completeClientProfileUseCase: CompleteClientProfileUseCase
    private let onCompleted: @MainActor (ClientProfile) -> Void

    init(
        authenticatedUser: AuthenticatedUser,
        existingProfile: ClientProfile?,
        completeClientProfileUseCase: CompleteClientProfileUseCase,
        onCompleted: @escaping @MainActor (ClientProfile) -> Void
    ) {
        self.authenticatedUser = authenticatedUser
        self.existingProfile = existingProfile
        self.completeClientProfileUseCase = completeClientProfileUseCase
        self.onCompleted = onCompleted

        let now = Date()
        let minimumDate = Calendar.current.date(byAdding: .year, value: -100, to: now) ?? now
        self.validBirthdayRange = minimumDate...now

        self.fullName = existingProfile?.fullName ?? authenticatedUser.displayName
        self.nationalId = existingProfile?.nationalId ?? ""
        self.phoneNumber = existingProfile?.phoneNumber ?? ""
        self.birthday = existingProfile?.birthday ?? Calendar.current.date(byAdding: .year, value: -18, to: now) ?? now
        self.address = existingProfile?.address ?? ""
        self.emergencyContactName = existingProfile?.emergencyContactName ?? ""
        self.emergencyContactPhone = existingProfile?.emergencyContactPhone ?? ""
    }

    var canSubmit: Bool {
        !fullName.trimmed.isEmpty &&
        nationalId.digitsOnly.count >= 8 &&
        phoneNumber.digitsOnly.count >= 8 &&
        !address.trimmed.isEmpty &&
        !emergencyContactName.trimmed.isEmpty &&
        emergencyContactPhone.digitsOnly.count >= 8 &&
        birthday <= Date()
    }

    func saveProfile() {
        guard canSubmit else {
            errorMessage = "Please complete all required fields correctly."
            return
        }

        errorMessage = nil
        isSaving = true

        let now = Date()
        let profile = ClientProfile(
            id: authenticatedUser.uid,
            email: authenticatedUser.email,
            appleUserIdentifier: authenticatedUser.appleUserIdentifier,
            fullName: fullName.trimmed,
            nationalId: nationalId.digitsOnly,
            phoneNumber: phoneNumber.digitsOnly,
            birthday: birthday,
            address: address.trimmed,
            emergencyContactName: emergencyContactName.trimmed,
            emergencyContactPhone: emergencyContactPhone.digitsOnly,
            isProfileComplete: true,
            createdAt: existingProfile?.createdAt ?? now,
            updatedAt: now,
            profileCompletedAt: existingProfile?.profileCompletedAt ?? now,
            profileImageURL: existingProfile?.profileImageURL,
            profileImagePath: existingProfile?.profileImagePath
        )

        Task {
            do {
                try await completeClientProfileUseCase.execute(profile: profile)
                isSaving = false
                onCompleted(profile)
            } catch {
                isSaving = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
