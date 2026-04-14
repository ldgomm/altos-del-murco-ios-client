//
//  ZoomableRemoteImageView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 14/4/26.
//

import SwiftUI

struct ZoomableRemoteImageView: View {
    let url: URL?
    let onScaleChanged: (CGFloat) -> Void

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1

    @State private var imageOffset: CGSize = .zero
    @State private var lastImageOffset: CGSize = .zero

    private var isZoomed: Bool {
        scale > 1.01
    }

    var body: some View {
        GeometryReader { proxy in
            RemoteImageView(
                url: url,
                contentMode: .fit,
                targetPixelSize: CGSize(
                    width: proxy.size.width,
                    height: proxy.size.height
                )
            ) {
                ZStack {
                    Color.black
                    ProgressView()
                        .tint(.white)
                }
            }
            .scaleEffect(scale)
            .offset(imageOffset)
            .frame(width: proxy.size.width, height: proxy.size.height)
            .contentShape(Rectangle())
            .background(Color.black)
            .gesture(magnificationGesture)
            .simultaneousGesture(isZoomed ? imagePanGesture : nil)
            .onTapGesture(count: 2) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.82)) {
                    if isZoomed {
                        resetZoom()
                    } else {
                        scale = 2
                        lastScale = 2
                        onScaleChanged(scale)
                    }
                }
            }
        }
        .background(Color.black)
    }

    private var magnificationGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let next = lastScale * value.magnification
                scale = min(max(next, 1), 4)
                onScaleChanged(scale)
            }
            .onEnded { _ in
                if scale <= 1 {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.82)) {
                        resetZoom()
                    }
                } else {
                    lastScale = scale
                    onScaleChanged(scale)
                }
            }
    }

    private var imagePanGesture: some Gesture {
        DragGesture(minimumDistance: 8, coordinateSpace: .local)
            .onChanged { value in
                guard isZoomed else { return }

                imageOffset = CGSize(
                    width: lastImageOffset.width + value.translation.width,
                    height: lastImageOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                guard isZoomed else { return }
                lastImageOffset = imageOffset
            }
    }

    private func resetZoom() {
        scale = 1
        lastScale = 1
        imageOffset = .zero
        lastImageOffset = .zero
        onScaleChanged(1)
    }
}
