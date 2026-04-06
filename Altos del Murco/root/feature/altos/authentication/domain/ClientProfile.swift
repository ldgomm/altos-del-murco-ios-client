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

    var isComplete: Bool {
        isProfileComplete &&
        !fullName.trimmed.isEmpty &&
        !nationalId.trimmed.isEmpty &&
        !phoneNumber.trimmed.isEmpty &&
        !address.trimmed.isEmpty &&
        !emergencyContactName.trimmed.isEmpty &&
        !emergencyContactPhone.trimmed.isEmpty
    }
}
