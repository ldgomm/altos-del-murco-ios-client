//
//  ClientProfileDocument.swift
//  Altos del Murco
//
//  Created by José Ruiz on 19/4/26.
//

import Foundation

struct ClientProfileDocument: Codable {
    let id: String
    let userId: String
    let email: String
    let appleUserIdentifier: String
    let fullName: String
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

    init(profile: ClientProfile) {
        self.id = profile.id
        self.userId = profile.id
        self.email = profile.email
        self.appleUserIdentifier = profile.appleUserIdentifier
        self.fullName = profile.fullName
        self.phoneNumber = profile.phoneNumber
        self.birthday = profile.birthday
        self.address = profile.address
        self.emergencyContactName = profile.emergencyContactName
        self.emergencyContactPhone = profile.emergencyContactPhone
        self.isProfileComplete = profile.isProfileComplete
        self.createdAt = profile.createdAt
        self.updatedAt = profile.updatedAt
        self.profileCompletedAt = profile.profileCompletedAt
        self.profileImageURL = profile.profileImageURL
        self.profileImagePath = profile.profileImagePath
    }

    func toDomain() -> ClientProfile {
        ClientProfile(
            id: id.isEmpty ? userId : id,
            email: email,
            appleUserIdentifier: appleUserIdentifier,
            fullName: fullName,
            phoneNumber: phoneNumber,
            birthday: birthday,
            address: address,
            emergencyContactName: emergencyContactName,
            emergencyContactPhone: emergencyContactPhone,
            isProfileComplete: isProfileComplete,
            createdAt: createdAt,
            updatedAt: updatedAt,
            profileCompletedAt: profileCompletedAt,
            profileImageURL: profileImageURL,
            profileImagePath: profileImagePath
        )
    }
}

//1. As the same in bookings I want to include phone number in restaurant orders, also if the name or phone is empty, table must be obligatory when not schedule
//2. When creating an order or booking only name is mandatory. Display an alert as the same in cofirming booking when confirming an order
//3.
