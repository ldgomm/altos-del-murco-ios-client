//
//  RemoreImageView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 14/4/26.
//

import SwiftUI

struct RemoteImageView<Placeholder: View>: View {
    let url: URL?
    let contentMode: ContentMode
    let targetPixelSize: CGSize?
    let placeholder: () -> Placeholder

    @StateObject private var loader = RemoteImageLoader()

    init(
        url: URL?,
        contentMode: ContentMode = .fill,
        targetPixelSize: CGSize? = nil,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.contentMode = contentMode
        self.targetPixelSize = targetPixelSize
        self.placeholder = placeholder
    }

    var body: some View {
        ZStack {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .transition(.opacity)
            } else {
                placeholder()
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            loader.load(from: url, targetPixelSize: targetPixelSize)
        }
        .onChange(of: url) { _, newURL in
            loader.load(from: newURL, targetPixelSize: targetPixelSize)
        }
    }
}
