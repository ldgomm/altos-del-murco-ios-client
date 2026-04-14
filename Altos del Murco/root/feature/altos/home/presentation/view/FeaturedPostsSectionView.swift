//
//  FeaturedPostsSectionView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 14/4/26.
//

import SwiftUI

struct FeaturedPostsSectionView: View {
    @StateObject private var viewModel = FeaturedFeedModule.makeViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            BrandSectionHeader(
                theme: .neutral,
                title: "Destacados",
                subtitle: "Fotos recientes del restaurante, aventura y momentos de nuestros clientes."
            )

            content
        }
        .task {
            viewModel.start()
        }
        .alert("No se pudo cargar destacados", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("Aceptar") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoadingInitial && viewModel.posts.isEmpty {
            VStack(spacing: 12) {
                ForEach(0..<2, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.secondary.opacity(0.12))
                        .frame(height: 320)
                        .redacted(reason: .placeholder)
                }
            }
        } else if viewModel.posts.isEmpty {
            VStack(spacing: 10) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 34))
                    .foregroundStyle(.secondary)

                Text("Aún no hay publicaciones activas.")
                    .font(.headline)

                Text("Cuando ADM publique nuevas fotos aparecerán aquí automáticamente.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .appCardStyle(.neutral)
        } else {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.posts) { post in
                    FeaturedPostCardView(post: post)
                        .onAppear {
                            viewModel.loadMoreIfNeeded(currentPost: post)
                        }
                }

                if viewModel.isLoadingMore {
                    ProgressView("Cargando más")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
            }
        }
    }
}
