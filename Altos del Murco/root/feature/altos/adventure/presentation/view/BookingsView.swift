//
//  BookingsView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import SwiftUI

struct BookingsView: View {
    @ObservedObject var ordersViewModel: OrdersViewModel
    let adventureModuleFactory: AdventureModuleFactory
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    NavigationLink {
                        OrdersView(viewModel: ordersViewModel)
                    } label: {
                        bookingCard(
                            title: "Restaurant Orders",
                            subtitle: "Review your current and past food orders.",
                            systemImage: "fork.knife"
                        )
                    }
                    .buttonStyle(.plain)
                    
                    NavigationLink {
                        AdventureReservationsView(
                            viewModel: adventureModuleFactory.makeBookingsViewModel()
                        )
                    } label: {
                        bookingCard(
                            title: "Adventure Reservations",
                            subtitle: "Manage off-road, paintball, go kart, and shooting reservations.",
                            systemImage: "calendar.badge.clock"
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
            .navigationTitle("Bookings")
        }
    }
    
    private func bookingCard(
        title: String,
        subtitle: String,
        systemImage: String
    ) -> some View {
        HStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}
