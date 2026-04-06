//
//  ClientProfileRepositoriable.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import Foundation

protocol ClientProfileRepositoriable {
    func fetchProfile(uid: String) async throws -> ClientProfile?
    func saveProfile(_ profile: ClientProfile) async throws
    func deleteProfile(uid: String) async throws
}
