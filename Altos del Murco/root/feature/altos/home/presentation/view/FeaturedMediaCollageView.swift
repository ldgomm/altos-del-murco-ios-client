//
//  FeaturedMediaCollageView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 14/4/26.
//

import SwiftUI

struct FeaturedMediaCollageView: View {
    let media: [FeaturedPostMedia]
    let onTap: (Int) -> Void

    var body: some View {
        Group {
            switch media.count {
            case 0:
                EmptyView()

            case 1:
                itemView(media[0], index: 0)
                    .frame(height: 300)

            case 2:
                HStack(spacing: 8) {
                    itemView(media[0], index: 0)
                    itemView(media[1], index: 1)
                }
                .frame(height: 250)

            case 3:
                HStack(spacing: 8) {
                    itemView(media[0], index: 0)

                    VStack(spacing: 8) {
                        itemView(media[1], index: 1)
                        itemView(media[2], index: 2)
                    }
                }
                .frame(height: 280)

            default:
                let displayed = Array(media.prefix(4))
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 8),
                        GridItem(.flexible(), spacing: 8)
                    ],
                    spacing: 8
                ) {
                    ForEach(Array(displayed.enumerated()), id: \.element.id) { index, item in
                        ZStack {
                            itemView(item, index: index)

                            if index == 3 && media.count > 4 {
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(.black.opacity(0.38))

                                Text("+\(media.count - 4)")
                                    .font(.title2.bold())
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(height: 150)
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func itemView(_ item: FeaturedPostMedia, index: Int) -> some View {
        Button {
            onTap(index)
        } label: {
            GeometryReader { proxy in
                RemoteImageView(
                    url: item.downloadURL,
                    contentMode: .fill,
                    targetPixelSize: CGSize(width: 420, height: 420)
                ) {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.secondary.opacity(0.12))
                        .overlay(ProgressView())
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
            }
        }
        .buttonStyle(.plain)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
