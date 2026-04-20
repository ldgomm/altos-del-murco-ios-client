//
//  ProfileImageCache.swift
//  Altos del Murco
//
//  Created by José Ruiz on 19/4/26.
//

import Foundation
import UIKit

final class ProfileImageCache {
    static let shared = ProfileImageCache()

    private let fileManager = FileManager.default
    private let directoryURL: URL

    private init() {
        let root = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let directory = root.appendingPathComponent("ProfileImages", isDirectory: true)

        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        self.directoryURL = directory
    }

    private func fileURL(for userId: String) -> URL {
        directoryURL.appendingPathComponent("profile_\(userId).jpg")
    }

    func loadImage(for userId: String) -> UIImage? {
        guard let data = try? Data(contentsOf: fileURL(for: userId)) else { return nil }
        return UIImage(data: data)
    }

    @discardableResult
    func saveImageData(_ data: Data, for userId: String) throws -> UIImage? {
        let url = fileURL(for: userId)
        try data.write(to: url, options: .atomic)
        return UIImage(data: data)
    }

    func removeImage(for userId: String) {
        try? fileManager.removeItem(at: fileURL(for: userId))
    }
}
