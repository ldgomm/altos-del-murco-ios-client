//
//  HomeView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import SwiftUI

struct HomeView: View {
    @Binding var selectedTab: MainTab
    @ObservedObject var comboBuilderViewModel: AdventureComboBuilderViewModel
    
    private let featuredServices = AdventureService.mockServices
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    heroSection
                    quickAccessSection
                    featuredSection
                }
                .padding()
            }
            .navigationTitle("Altos del Murco")
            .navigationBarTitleDisplayMode(.large)
        }
        .appScreenStyle(.neutral)
    }
    
    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Bienvenido")
                .font(.title2.bold())
            
            Text("Restaurante y aventura en un solo lugar. Explora experiencias, revisa tus reservas y accede rápido a cada sección.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .appCardStyle(.neutral, emphasized: false)
    }
    
    private var quickAccessSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            BrandSectionHeader(
                theme: .neutral,
                title: "Acceso rápido",
                subtitle: "Tus secciones principales, con identidad visual propia."
            )
            
            HStack(spacing: 12) {
                quickAccessCard(
                    title: "Restaurante",
                    systemImage: "fork.knife",
                    theme: .restaurant,
                    action: { selectedTab = .restaurant }
                )
                
                quickAccessCard(
                    title: "Experiencias",
                    systemImage: "figure",
                    theme: .adventure,
                    action: { selectedTab = .experiences }
                )
            }
            
            HStack(spacing: 12) {
                quickAccessCard(
                    title: "Reservas",
                    systemImage: "calendar",
                    theme: .adventure,
                    action: { selectedTab = .bookings }
                )
                
                quickAccessCard(
                    title: "Perfil",
                    systemImage: "person.crop.circle",
                    theme: .neutral,
                    action: { selectedTab = .profile }
                )
            }
        }
    }
    
    private func quickAccessCard(
        title: String,
        systemImage: String,
        theme: AppSectionTheme,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                BrandIconBubble(theme: theme, systemImage: systemImage, size: 50)
                
                Spacer(minLength: 0)
                
                Text(title)
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                
                HStack(spacing: 6) {
                    Text("Abrir")
                        .font(.caption.weight(.semibold))
                    
                    Image(systemName: "arrow.right")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 138, alignment: .topLeading)
            .appCardStyle(theme)
        }
        .buttonStyle(.plain)
    }
    
    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            BrandSectionHeader(
                theme: .adventure,
                title: "Experiencias destacadas",
                subtitle: "Descubre actividades para reservar rápidamente."
            )
            
            ForEach(featuredServices) { service in
                NavigationLink {
                    ServiceDetailView(
                        service: service,
                        comboBuilderViewModel: comboBuilderViewModel
                    )
                } label: {
                    ServiceCardView(service: service)
                        .appCardStyle(.adventure)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
