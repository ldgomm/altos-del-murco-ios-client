//
//  AdventureReservationsView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import SwiftUI

struct AdventureReservationsView: View {
    @StateObject private var viewModel: AdventureBookingsViewModel
    
    init(viewModel: AdventureBookingsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        Group {
            if viewModel.state.isLoading && viewModel.state.bookings.isEmpty {
                ProgressView("Loading reservations...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    Section("Date") {
                        DatePicker(
                            "Selected date",
                            selection: Binding(
                                get: { viewModel.state.selectedDate },
                                set: { viewModel.setDate($0) }
                            ),
                            in: Date()...,
                            displayedComponents: .date
                        )
                    }
                    
                    if viewModel.state.bookings.isEmpty {
                        Section {
                            ContentUnavailableView(
                                "No reservations",
                                systemImage: "calendar",
                                description: Text("Reservations for the selected date will appear here.")
                            )
                        }
                    } else {
                        Section("Reservations") {
                            ForEach(viewModel.state.bookings) { booking in
                                AdventureReservationRow(booking: booking)
                                    .swipeActions(edge: .trailing) {
                                        if booking.status != .canceled {
                                            Button(role: .destructive) {
                                                viewModel.cancelBooking(booking.id)
                                            } label: {
                                                Label("Cancel", systemImage: "xmark")
                                            }
                                        }
                                    }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Adventure Reservations")
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
    }
}

private struct AdventureReservationRow: View {
    let booking: AdventureBooking
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(booking.clientName)
                    .font(.headline)
                Spacer()
                Text(booking.status.title)
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.15))
                    .clipShape(Capsule())
            }
            
            Text("\(AdventureDateHelper.timeText(booking.startAt)) • \(booking.whatsappNumber) • ID \(booking.nationalId)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text("Total: $\(booking.totalAmount, specifier: "%.2f")")
                .font(.subheadline.weight(.semibold))
            
            ForEach(booking.items, id: \.id) { item in
                Text("• \(item.title) — \(item.summaryText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
    
    private var statusColor: Color {
        switch booking.status {
        case .pending: return .orange
        case .confirmed: return .green
        case .canceled: return .red
        }
    }
}
