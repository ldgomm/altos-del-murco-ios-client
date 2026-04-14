//
//  FeaturedMediaViewer.swift
//  Altos del Murco
//
//  Created by José Ruiz on 14/4/26.
//

import SwiftUI

struct FeaturedMediaViewer: View {
    let media: [FeaturedPostMedia]
    let selectedIndex: Int

    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int
    @State private var verticalDismissOffset: CGFloat = 0

    private var backgroundOpacity: Double {
        let progress = min(abs(verticalDismissOffset) / 260, 1)
        return 1 - (progress * 0.5)
    }


    init(media: [FeaturedPostMedia], selectedIndex: Int) {
        self.media = media
        self.selectedIndex = selectedIndex
        _currentIndex = State(initialValue: selectedIndex)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentIndex) {
                ForEach(Array(media.enumerated()), id: \.element.id) { index, item in
                    ZoomableRemoteImageView(url: item.downloadURL) { _ in }
                    .tag(index)
                    .ignoresSafeArea()
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            VStack(spacing: 12) {
                HStack {
                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(.black.opacity(0.45), in: Circle())
                    }
                }

                HStack {
                    Spacer()

                    Text("\(currentIndex + 1) / \(media.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.black.opacity(0.45), in: Capsule())
                }
            }
            .padding()
        }
        .statusBarHidden()
    }
}
