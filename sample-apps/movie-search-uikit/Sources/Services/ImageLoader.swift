// ImageLoader.swift
// Services layer — actor-isolated image loading with an NSCache and
// in-flight request coalescing. Zero third-party dependencies.

import UIKit

// MARK: - ImageLoaderError

/// Failures specific to image loading.
enum ImageLoaderError: Error {

    /// The downloaded bytes were not a decodable image.
    case invalidImageData
}

// MARK: - ImageLoading

/// Abstraction so cells and screens can be previewed/tested without hitting
/// the network.
protocol ImageLoading: Sendable {

    /// Returns the image at `url`, from cache when possible.
    func image(from url: URL) async throws -> UIImage
}

// MARK: - ImageLoader

/// Downloads and caches images.
///
/// An `actor` because it owns two pieces of mutable state — the cache and
/// the in-flight task table — that would otherwise race when a fast scroll
/// requests the same poster from ten cells at once.
actor ImageLoader: ImageLoading {

    // MARK: Properties

    /// Decoded-image cache; NSCache evicts automatically under pressure.
    private let cache = NSCache<NSURL, UIImage>()

    /// Coalesces concurrent requests for the same URL into one download.
    private var inFlight: [URL: Task<UIImage, Error>] = [:]

    private let session: URLSession

    // MARK: Initialisation

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: ImageLoading

    func image(from url: URL) async throws -> UIImage {
        if let cached = cache.object(forKey: url as NSURL) {
            return cached
        }

        if let existing = inFlight[url] {
            return try await existing.value
        }

        let task = Task<UIImage, Error> { [session] in
            let (data, _) = try await session.data(from: url)
            guard let image = UIImage(data: data) else {
                throw ImageLoaderError.invalidImageData
            }
            return image
        }
        inFlight[url] = task
        defer { inFlight[url] = nil }

        let image = try await task.value
        cache.setObject(image, forKey: url as NSURL)
        return image
    }
}
