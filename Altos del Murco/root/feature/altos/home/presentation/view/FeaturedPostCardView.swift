//
//  FeaturedPostCardView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 14/4/26.
//

import SwiftUI

struct FeaturedPostCardView: View {
    let post: FeaturedPost

    @State private var selectedMediaIndex = 0
    @State private var isViewerPresented = false

    private var theme: AppSectionTheme {
        switch post.category {
        case .restaurant: return .restaurant
        case .adventure: return .adventure
        case .clients: return .neutral
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                BrandIconBubble(
                    theme: theme,
                    systemImage: iconName(for: post.category),
                    size: 42
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(post.category.title)
                        .font(.headline)

                    Text(post.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                BrandBadge(theme: theme, title: "Nuevo", selected: true)
            }

            FeaturedMediaCollageView(
                media: post.orderedMedia,
                onTap: { index in
                    selectedMediaIndex = index
                    isViewerPresented = true
                }
            )

            if let description = post.description, !description.isEmpty {
                Text(description)
                    .font(.body)
                    .foregroundStyle(.primary)
            }
        }
        .appCardStyle(theme, emphasized: false)
        .fullScreenCover(isPresented: $isViewerPresented) {
            FeaturedMediaViewer(
                media: post.orderedMedia,
                selectedIndex: selectedMediaIndex
            )
        }
    }

    private func iconName(for category: FeaturedPostCategory) -> String {
        switch category {
        case .restaurant: return "fork.knife"
        case .adventure: return "figure.hiking"
        case .clients: return "person.3.fill"
        }
    }
}
