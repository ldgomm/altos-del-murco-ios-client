//
//  RemoteImageLoader.swift
//  Altos del Murco
//
//  Created by José Ruiz on 28/4/26.
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
    private var currentMemoryKey: NSString?
    private var listenerTask: Task<Void, Never>?

    private struct ImageDownloadResult {
        let data: Data
        let response: URLResponse
    }

    private static let memoryCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 250
        cache.totalCostLimit = 120 * 1024 * 1024
        return cache
    }()

    private static let diskCache: URLCache = {
        URLCache(
            memoryCapacity: 80 * 1024 * 1024,
            diskCapacity: 800 * 1024 * 1024,
            diskPath: "altos-remote-images"
        )
    }()

    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = diskCache
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.timeoutIntervalForRequest = 45
        configuration.timeoutIntervalForResource = 180
        configuration.waitsForConnectivity = true
        return URLSession(configuration: configuration)
    }()

    private static var inFlightDownloads: [URL: Task<ImageDownloadResult, Error>] = [:]

    func load(
        from url: URL?,
        targetPixelSize: CGSize? = nil,
        forceRefresh: Bool = false
    ) {
        let key = url.map {
            Self.memoryKey(for: $0, targetPixelSize: targetPixelSize)
        }

        let sameRequest = currentURL == url && currentMemoryKey == key

        if sameRequest, image != nil, !forceRefresh {
            return
        }

        if sameRequest, isLoading, !forceRefresh {
            return
        }

        if !sameRequest || forceRefresh {
            listenerTask?.cancel()
            listenerTask = nil
            currentURL = url
            currentMemoryKey = key
            image = nil
            didFail = false
            isLoading = false
        }

        guard let url, let key else {
            didFail = true
            return
        }

        if !forceRefresh, let cached = Self.memoryCache.object(forKey: key) {
            image = cached
            didFail = false
            isLoading = false
            return
        }

        let request = Self.makeRequest(url: url, forceRefresh: forceRefresh)

        if !forceRefresh,
           let cachedResponse = Self.diskCache.cachedResponse(for: request),
           let decoded = Self.decodeImage(
                data: cachedResponse.data,
                targetPixelSize: targetPixelSize
           ) {
            Self.memoryCache.setObject(
                decoded,
                forKey: key,
                cost: Self.cacheCost(for: decoded)
            )
            image = decoded
            didFail = false
            isLoading = false
            return
        }

        isLoading = true
        didFail = false

        listenerTask = Task { [weak self] in
            do {
                let result = try await Self.fetchData(
                    for: request,
                    url: url,
                    forceRefresh: forceRefresh
                )

                guard !Task.isCancelled else { return }

                guard let decoded = Self.decodeImage(
                    data: result.data,
                    targetPixelSize: targetPixelSize
                ) else {
                    await MainActor.run {
                        guard self?.currentURL == url else { return }
                        self?.isLoading = false
                        self?.didFail = true
                    }
                    return
                }

                Self.memoryCache.setObject(
                    decoded,
                    forKey: key,
                    cost: Self.cacheCost(for: decoded)
                )

                await MainActor.run {
                    guard self?.currentURL == url else { return }
                    self?.image = decoded
                    self?.isLoading = false
                    self?.didFail = false
                }
            } catch is CancellationError {
                await MainActor.run {
                    guard self?.currentURL == url else { return }
                    self?.isLoading = false
                }
            } catch {
                await MainActor.run {
                    guard self?.currentURL == url else { return }
                    self?.isLoading = false
                    self?.didFail = true
                }
            }
        }
    }

    func retry(targetPixelSize: CGSize? = nil) {
        load(
            from: currentURL,
            targetPixelSize: targetPixelSize,
            forceRefresh: false
        )
    }

    func reloadIgnoringCache(targetPixelSize: CGSize? = nil) {
        load(
            from: currentURL,
            targetPixelSize: targetPixelSize,
            forceRefresh: true
        )
    }

    func cancelListenerOnly() {
        listenerTask?.cancel()
        listenerTask = nil
        isLoading = false
    }

    static func prefetch(urls: [URL]) {
        let uniqueURLs = Array(Set(urls))

        for url in uniqueURLs {
            let request = makeRequest(url: url, forceRefresh: false)

            if diskCache.cachedResponse(for: request) != nil {
                continue
            }

            Task {
                _ = try? await fetchData(
                    for: request,
                    url: url,
                    forceRefresh: false
                )
            }
        }
    }

    static func removeCachedImage(for url: URL) {
        let request = makeRequest(url: url, forceRefresh: false)
        diskCache.removeCachedResponse(for: request)

        let prefix = "\(url.absoluteString)#"
        for maxPixelSize in [160, 220, 320, 600, 900, 1200, 1600, 2000] {
            let key = "\(prefix)\(maxPixelSize)" as NSString
            memoryCache.removeObject(forKey: key)
        }
    }

    static func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }

    private static func fetchData(
        for request: URLRequest,
        url: URL,
        forceRefresh: Bool
    ) async throws -> ImageDownloadResult {
        if !forceRefresh,
           let cachedResponse = diskCache.cachedResponse(for: request) {
            return ImageDownloadResult(
                data: cachedResponse.data,
                response: cachedResponse.response
            )
        }

        if !forceRefresh, let existingTask = inFlightDownloads[url] {
            return try await existingTask.value
        }

        let downloadTask = Task<ImageDownloadResult, Error> {
            let (data, response) = try await session.data(for: request)

            let cachedResponse = CachedURLResponse(
                response: response,
                data: data,
                storagePolicy: .allowed
            )

            diskCache.storeCachedResponse(cachedResponse, for: request)

            return ImageDownloadResult(
                data: data,
                response: response
            )
        }

        inFlightDownloads[url] = downloadTask

        do {
            let result = try await downloadTask.value
            inFlightDownloads[url] = nil
            return result
        } catch {
            inFlightDownloads[url] = nil
            throw error
        }
    }

    private static func makeRequest(
        url: URL,
        forceRefresh: Bool
    ) -> URLRequest {
        URLRequest(
            url: url,
            cachePolicy: forceRefresh ? .reloadIgnoringLocalCacheData : .returnCacheDataElseLoad,
            timeoutInterval: 45
        )
    }

    private static func memoryKey(
        for url: URL,
        targetPixelSize: CGSize?
    ) -> NSString {
        let maxPixelSize: Int

        if let targetPixelSize {
            maxPixelSize = Int(
                max(targetPixelSize.width, targetPixelSize.height) * UIScreen.main.scale
            )
        } else {
            maxPixelSize = 2000
        }

        return "\(url.absoluteString)#\(maxPixelSize)" as NSString
    }

    private static func decodeImage(
        data: Data,
        targetPixelSize: CGSize?
    ) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return UIImage(data: data)
        }

        let maxDimension: CGFloat

        if let targetPixelSize {
            maxDimension = max(
                targetPixelSize.width,
                targetPixelSize.height
            ) * UIScreen.main.scale
        } else {
            maxDimension = 2000
        }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension
        ]

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(
            source,
            0,
            options as CFDictionary
        ) else {
            return UIImage(data: data)
        }

        return UIImage(cgImage: cgImage)
    }

    private static func cacheCost(for image: UIImage) -> Int {
        guard let cgImage = image.cgImage else {
            return 1
        }

        return cgImage.bytesPerRow * cgImage.height
    }
}
