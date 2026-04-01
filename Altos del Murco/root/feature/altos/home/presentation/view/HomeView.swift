//
//  HomeView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import SwiftUI

struct HomeView: View {
    @Binding var selectedTab: MainTab
    let adventureModuleFactory: AdventureModuleFactory

    private let featuredServices = AdventureService.mockServices
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    heroSection
                    quickAccessSection
                    featuredSection
                }
                .padding()
            }
            .navigationTitle("Altos del Murco")
        }
    }
    
    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Welcome to Altos del Murco")
                .font(.largeTitle.bold())
            
            Text("Food, adventure, and unforgettable experiences in one place.")
                .font(.body)
                .foregroundStyle(.secondary)
            
            Button {
                selectedTab = .restaurant
            } label: {
                Text("Explore Restaurant")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primary)
                    .foregroundStyle(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemGray6))
        )
    }
    
    private var quickAccessSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Access")
                .font(.title3.bold())
            
            HStack(spacing: 12) {
                quickAccessCard(
                    title: "Restaurant",
                    systemImage: "fork.knife",
                    action: { selectedTab = .restaurant }
                )
                
                quickAccessCard(
                    title: "Experiences",
                    systemImage: "figure.off.and.run",
                    action: { selectedTab = .experiences }
                )
            }
            
            HStack(spacing: 12) {
                quickAccessCard(
                    title: "Bookings",
                    systemImage: "calendar",
                    action: { selectedTab = .bookings }
                )
                
                quickAccessCard(
                    title: "Profile",
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
            Text("Featured Experiences")
                .font(.title3.bold())
            
            ForEach(featuredServices) { service in
                NavigationLink {
                    ServiceDetailView(service: service, adventureModuleFactory: adventureModuleFactory)
                } label: {
                    ServiceCardView(service: service)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
