//
//  RemoteImageLoader.swift
//  Altos del Murco
//
//  Created by José Ruiz on 14/4/26.
//

import Combine
import SwiftUI
import ImageIO

@MainActor
final class RemoteImageLoader: ObservableObject {
    @Published private(set) var image: UIImage?
    @Published private(set) var isLoading = false
    @Published private(set) var didFail = false

    private var currentURL: URL?
    private var task: Task<Void, Never>?

    private static let memoryCache = NSCache<NSURL, UIImage>()

    private static let cache: URLCache = {
        URLCache(
            memoryCapacity: 80 * 1024 * 1024,
            diskCapacity: 500 * 1024 * 1024,
            diskPath: "featured-posts-images"
        )
    }()

    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = cache
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 120
        return URLSession(configuration: configuration)
    }()

    @MainActor
    func load(from url: URL?, targetPixelSize: CGSize? = nil) {
        let sameURL = currentURL == url

        if sameURL, image != nil {
            return
        }

        if sameURL, isLoading {
            return
        }

        if !sameURL {
            cancel()
            currentURL = url
            image = nil
            didFail = false
        } else {
            didFail = false
        }

        guard let url else {
            didFail = true
            return
        }

        let nsURL = url as NSURL

        if let cached = Self.memoryCache.object(forKey: nsURL) {
            image = cached
            return
        }

        let request = URLRequest(
            url: url,
            cachePolicy: .returnCacheDataElseLoad,
            timeoutInterval: 60
        )

        if let cachedResponse = Self.cache.cachedResponse(for: request),
           let decoded = Self.decodeImage(data: cachedResponse.data, targetPixelSize: targetPixelSize) {
            Self.memoryCache.setObject(decoded, forKey: nsURL)
            image = decoded
            return
        }

        isLoading = true
        didFail = false

        task = Task {
            do {
                let (data, response) = try await Self.session.data(for: request)

                if Task.isCancelled { return }

                guard let decoded = Self.decodeImage(data: data, targetPixelSize: targetPixelSize) else {
                    await MainActor.run {
                        guard self.currentURL == url else { return }
                        self.isLoading = false
                        self.didFail = true
                    }
                    return
                }

                let cachedResponse = CachedURLResponse(response: response, data: data)
                Self.cache.storeCachedResponse(cachedResponse, for: request)
                Self.memoryCache.setObject(decoded, forKey: nsURL)

                await MainActor.run {
                    guard self.currentURL == url else { return }
                    self.image = decoded
                    self.isLoading = false
                    self.didFail = false
                }
            } catch is CancellationError {
                await MainActor.run {
                    guard self.currentURL == url else { return }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    guard self.currentURL == url else { return }
                    self.isLoading = false
                    self.didFail = true
                }
            }
        }
    }

    func retry(targetPixelSize: CGSize? = nil) {
        load(from: currentURL, targetPixelSize: targetPixelSize)
    }

    func cancel() {
        task?.cancel()
        task = nil
        isLoading = false
    }

    private static func decodeImage(data: Data, targetPixelSize: CGSize?) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return UIImage(data: data)
        }

        let maxDimension: CGFloat
        if let targetPixelSize {
            maxDimension = max(targetPixelSize.width, targetPixelSize.height) * UIScreen.main.scale
        } else {
            maxDimension = 2000
        }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension
        ]

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return UIImage(data: data)
        }

        return UIImage(cgImage: cgImage)
    }
}
