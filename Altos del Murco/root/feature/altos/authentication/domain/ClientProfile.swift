//
//  ClientProfile.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import Foundation

struct ClientProfile: Identifiable, Codable, Equatable {
    let id: String
    let email: String
    let appleUserIdentifier: String
    let fullName: String
    let nationalId: String
    let phoneNumber: String
    let birthday: Date
    let address: String
    let emergencyContactName: String
    let emergencyContactPhone: String
    let isProfileComplete: Bool
    let createdAt: Date
    let updatedAt: Date
    let profileCompletedAt: Date?
    let profileImageURL: String?
    let profileImagePath: String?

    /// This is intentionally light now. Apple does not allow blocking public browsing
    /// because optional profile data is missing.
    var isComplete: Bool {
        isProfileComplete && !fullName.trimmed.isEmpty
    }

    var hasRequiredOrderIdentity: Bool {
        !fullName.trimmed.isEmpty &&
        nationalId.digitsOnly.count >= 8
    }

    var hasRequiredServiceIdentity: Bool {
        hasRequiredOrderIdentity &&
        phoneNumber.digitsOnly.count >= 8
    }

    var displayName: String {
        let cleanName = fullName.trimmed
        return cleanName.isEmpty ? "Cliente" : cleanName
    }

    var hasProfileImage: Bool {
        let url = profileImageURL?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return !url.isEmpty
    }

    static func starter(from user: AuthenticatedUser, existingProfile: ClientProfile? = nil) -> ClientProfile {
        let now = Date()
        let defaultBirthday = Calendar.current.date(byAdding: .year, value: -18, to: now) ?? now

        return ClientProfile(
            id: user.uid,
            email: existingProfile?.email ?? user.email,
            appleUserIdentifier: existingProfile?.appleUserIdentifier ?? user.appleUserIdentifier,
            fullName: existingProfile?.fullName.nilIfBlank ?? user.displayName,
            nationalId: existingProfile?.nationalId ?? "",
            phoneNumber: existingProfile?.phoneNumber ?? "",
            birthday: existingProfile?.birthday ?? defaultBirthday,
            address: existingProfile?.address ?? "",
            emergencyContactName: existingProfile?.emergencyContactName ?? "",
            emergencyContactPhone: existingProfile?.emergencyContactPhone ?? "",
            isProfileComplete: existingProfile?.isProfileComplete ?? false,
            createdAt: existingProfile?.createdAt ?? now,
            updatedAt: existingProfile?.updatedAt ?? now,
            profileCompletedAt: existingProfile?.profileCompletedAt,
            profileImageURL: existingProfile?.profileImageURL,
            profileImagePath: existingProfile?.profileImagePath
        )
    }

    func withUpdatedRequiredServiceFields(
        fullName: String,
        nationalId: String,
        phoneNumber: String
    ) -> ClientProfile {
        ClientProfile(
            id: id,
            email: email,
            appleUserIdentifier: appleUserIdentifier,
            fullName: fullName.trimmed,
            nationalId: nationalId.digitsOnly,
            phoneNumber: phoneNumber.digitsOnly,
            birthday: birthday,
            address: address,
            emergencyContactName: emergencyContactName,
            emergencyContactPhone: emergencyContactPhone,
            isProfileComplete: !fullName.trimmed.isEmpty,
            createdAt: createdAt,
            updatedAt: Date(),
            profileCompletedAt: profileCompletedAt ?? Date(),
            profileImageURL: profileImageURL,
            profileImagePath: profileImagePath
        )
    }
}

private extension String {
    var nilIfBlank: String? {
        let value = trimmed
        return value.isEmpty ? nil : value
    }
}
