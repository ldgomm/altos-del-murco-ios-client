//
//  EditProfileViewModel.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import Combine
import Foundation

@MainActor
final class EditProfileViewModel: ObservableObject {
    @Published var fullName: String
    @Published var nationalId: String
    @Published var phoneNumber: String
    @Published var birthday: Date
    @Published var address: String
    @Published var emergencyContactName: String
    @Published var emergencyContactPhone: String

    @Published private(set) var isSaving = false
    @Published var errorMessage: String?

    private let originalProfile: ClientProfile
    private let completeClientProfileUseCase: CompleteClientProfileUseCase
    private let onSaved: @MainActor (ClientProfile) -> Void

    let validBirthdayRange: ClosedRange<Date>

    init(
        profile: ClientProfile,
        completeClientProfileUseCase: CompleteClientProfileUseCase,
        onSaved: @escaping @MainActor (ClientProfile) -> Void
    ) {
        self.originalProfile = profile
        self.completeClientProfileUseCase = completeClientProfileUseCase
        self.onSaved = onSaved

        let now = Date()
        let minimumDate = Calendar.current.date(byAdding: .year, value: -100, to: now) ?? now
        self.validBirthdayRange = minimumDate...now

        self.fullName = profile.fullName
        self.nationalId = profile.nationalId
        self.phoneNumber = profile.phoneNumber
        self.birthday = profile.birthday
        self.address = profile.address
        self.emergencyContactName = profile.emergencyContactName
        self.emergencyContactPhone = profile.emergencyContactPhone
    }

    var email: String {
        originalProfile.email
    }

    var canSave: Bool {
        !fullName.trimmed.isEmpty &&
        optionalNationalIdIsValid &&
        optionalPhoneIsValid(phoneNumber) &&
        optionalPhoneIsValid(emergencyContactPhone)
    }

    func saveChanges() {
        guard canSave else {
            errorMessage = "Solo el nombre es obligatorio. Si agregas cédula o teléfono, revisa que tengan un formato válido."
            return
        }

        errorMessage = nil
        isSaving = true

        let cleanName = fullName.trimmed
        let updatedProfile = ClientProfile(
            id: originalProfile.id,
            email: originalProfile.email,
            appleUserIdentifier: originalProfile.appleUserIdentifier,
            fullName: cleanName,
            nationalId: nationalId.digitsOnly,
            phoneNumber: phoneNumber.digitsOnly,
            birthday: birthday,
            address: address.trimmed,
            emergencyContactName: emergencyContactName.trimmed,
            emergencyContactPhone: emergencyContactPhone.digitsOnly,
            isProfileComplete: !cleanName.isEmpty,
            createdAt: originalProfile.createdAt,
            updatedAt: Date(),
            profileCompletedAt: originalProfile.profileCompletedAt ?? Date(),
            profileImageURL: originalProfile.profileImageURL,
            profileImagePath: originalProfile.profileImagePath
        )

        Task {
            do {
                try await completeClientProfileUseCase.execute(profile: updatedProfile)
                isSaving = false
                onSaved(updatedProfile)
            } catch {
                isSaving = false
                errorMessage = error.localizedDescription
            }
        }
    }

    private var optionalNationalIdIsValid: Bool {
        let count = nationalId.digitsOnly.count
        return count == 0 || count == 10 || count == 13
    }

    private func optionalPhoneIsValid(_ value: String) -> Bool {
        let count = value.digitsOnly.count
        return count == 0 || count >= 8
    }
}
