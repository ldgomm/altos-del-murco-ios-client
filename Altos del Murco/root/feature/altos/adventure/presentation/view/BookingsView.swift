//
//  BookingsView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import SwiftUI

struct BookingsView: View {
    @ObservedObject var ordersViewModel: OrdersViewModel
    @ObservedObject var adventureBookingsViewModel: AdventureBookingsViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    NavigationLink {
                        OrdersView(viewModel: ordersViewModel)
                    } label: {
                        bookingCard(
                            title: "Pedidos del restaurante",
                            subtitle: "Revisa tus pedidos actuales y anteriores de comida.",
                            systemImage: "fork.knife"
                        )
                    }
                    .buttonStyle(.plain)
                    
                    NavigationLink {
                        AdventureReservationsView(
                            viewModel: adventureBookingsViewModel
                        )
                    } label: {
                        bookingCard(
                            title: "Reservas de aventura",
                            subtitle: "Mira combos, actividades individuales, camping y reservas nocturnas.",
                            systemImage: "calendar.badge.clock"
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
            .navigationTitle("Reservas")
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
