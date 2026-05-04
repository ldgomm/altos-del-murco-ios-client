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

    var isComplete: Bool {
        isProfileComplete &&
        !fullName.trimmed.isEmpty &&
        birthday <= Date()
    }

    var hasProfileImage: Bool {
        let url = profileImageURL?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return !url.isEmpty
    }
}

extension ClientProfile {
    static func starter(
        from user: AuthenticatedUser,
        existingProfile: ClientProfile?
    ) -> ClientProfile {
        let now = Date()
        let defaultBirthday = Calendar.current.date(byAdding: .year, value: -18, to: now) ?? now

        return ClientProfile(
            id: user.uid,
            email: existingProfile?.email.nilIfBlank ?? user.email,
            appleUserIdentifier: existingProfile?.appleUserIdentifier.nilIfBlank ?? user.appleUserIdentifier,
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
}

private extension String {
    var nilIfBlank: String? {
        let value = trimmed
        return value.isEmpty ? nil : value
    }
}
