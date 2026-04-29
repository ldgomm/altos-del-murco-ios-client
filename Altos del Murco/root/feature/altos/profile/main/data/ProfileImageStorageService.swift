//
//  ProfileImageStorageService.swift
//  Altos del Murco
//
//  Created by José Ruiz on 19/4/26.
//

import Foundation
import FirebaseStorage
import UIKit

struct UploadedProfileImage {
    let downloadURL: String
    let storagePath: String
}

final class ProfileImageStorageService {
    private let storage: Storage

    init(storage: Storage = Storage.storage()) {
        self.storage = storage
    }

    func uploadProfileImage(
        data: Data,
        userId: String,
        replacing existingPath: String?
    ) async throws -> UploadedProfileImage {
        if let existingPath, !existingPath.isEmpty {
            try? await deleteProfileImage(path: existingPath)
        }

        let jpegData = UIImage(data: data)?.jpegData(compressionQuality: 0.82) ?? data
        let path = "clients/profile_images/\(userId)/avatar_\(Int(Date().timeIntervalSince1970)).jpg"
        let ref = storage.reference(withPath: path)

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            ref.putData(jpegData, metadata: metadata) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }

        let url = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
            ref.downloadURL { url, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let url {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: NSError(
                        domain: "ProfileImageStorageService",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Missing profile image download URL."]
                    ))
                }
            }
        }

        return UploadedProfileImage(
            downloadURL: url.absoluteString,
            storagePath: path
        )
    }

    func deleteProfileImage(path: String?) async throws {
        guard let path = path, !path.isEmpty else { return }

        let ref = storage.reference(withPath: path)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            ref.delete { error in
                if let nsError = error as NSError?,
                   nsError.code == StorageErrorCode.objectNotFound.rawValue {
                    continuation.resume(returning: ())
                } else if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}

