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
                VStack(alignment: .leading, spacing: 24) {
                    quickAccessSection
                    featuredSection
                }
                .padding()
            }
            .navigationTitle("Altos del Murco")
        }
    }

    
    private var quickAccessSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Acceso rápido")
                .font(.title3.bold())
            
            HStack(spacing: 12) {
                quickAccessCard(
                    title: "Restaurante",
                    systemImage: "fork.knife",
                    action: { selectedTab = .restaurant }
                )
                
                quickAccessCard(
                    title: "Experiencias",
                    systemImage: "figure",
                    action: { selectedTab = .experiences }
                )
            }
            
            HStack(spacing: 12) {
                quickAccessCard(
                    title: "Reservas",
                    systemImage: "calendar",
                    action: { selectedTab = .bookings }
                )
                
                quickAccessCard(
                    title: "Perfil",
                    systemImage: "person.crop.circle",
                    action: { selectedTab = .profile }
                )
            }
        }
    }
    
    private func quickAccessCard(
        title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title2)
                
                Text(title)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 110)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemGray6))
            )
        }
        .buttonStyle(.plain)
    }
    
    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Experiencias destacadas")
                .font(.title3.bold())
            ForEach(featuredServices) { service in
                NavigationLink {
                    ServiceDetailView(
                        service: service,
                        comboBuilderViewModel: comboBuilderViewModel
                    )
                } label: {
                    ServiceCardView(service: service)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
