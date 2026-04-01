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
        content
            .navigationTitle("Adventure Reservations")
            .onAppear {
                viewModel.onEvent(.onAppear)
            }
            .onDisappear {
                viewModel.onEvent(.onDisappear)
            }
    }
    
    @ViewBuilder
    private var content: some View {
        if viewModel.state.isLoading && viewModel.state.bookings.isEmpty {
            ProgressView("Loading reservations...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = viewModel.state.errorMessage, viewModel.state.bookings.isEmpty {
            ContentUnavailableView(
                "Something went wrong",
                systemImage: "exclamationmark.triangle",
                description: Text(error)
            )
        } else if viewModel.state.bookings.isEmpty {
            emptyState
        } else {
            reservationsList
        }
    }
    
    private var emptyState: some View {
        VStack {
            Form {
                Section("Date") {
                    DatePicker(
                        "Selected date",
                        selection: Binding(
                            get: { viewModel.state.selectedDate },
                            set: { viewModel.onEvent(.selectedDateChanged($0)) }
                        ),
                        in: Date()...,
                        displayedComponents: .date
                    )
                }
            }
            
            ContentUnavailableView(
                "No reservations",
                systemImage: "calendar",
                description: Text("Reservations for the selected date will appear here.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private var reservationsList: some View {
        List {
            Section("Date") {
                DatePicker(
                    "Selected date",
                    selection: Binding(
                        get: { viewModel.state.selectedDate },
                        set: { viewModel.onEvent(.selectedDateChanged($0)) }
                    ),
                    in: Date()...,
                    displayedComponents: .date
                )
            }
            
            Section("Reservations") {
                ForEach(viewModel.state.bookings) { booking in
                    AdventureBookingRowView(booking: booking)
                        .swipeActions(edge: .trailing) {
                            if booking.status != .canceled {
                                Button(role: .destructive) {
                                    viewModel.onEvent(.cancelBooking(booking.id))
                                } label: {
                                    Label("Cancel", systemImage: "xmark")
                                }
                            }
                        }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

private struct AdventureBookingRowView: View {
    let booking: AdventureBooking
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(booking.packageType.title)
                    .font(.headline)
                Spacer()
                Text(booking.status.title)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(statusBackground)
                    .clipShape(Capsule())
            }
            
            Text(booking.clientName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 12) {
                Label(AdventureDateHelper.timeText(for: booking.startAt), systemImage: "clock")
                Label("\(booking.peopleCount)", systemImage: "person.2")
                Label("$\(booking.totalAmount, specifier: "%.2f")", systemImage: "dollarsign.circle")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            
            ForEach(booking.blocks) { block in
                Text("• \(block.activity.title): \(AdventureDateHelper.timeText(for: block.startAt)) - \(AdventureDateHelper.timeText(for: block.endAt))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
    
    private var statusBackground: Color {
        switch booking.status {
        case .pending:
            return .orange.opacity(0.2)
        case .confirmed:
            return .green.opacity(0.2)
        case .canceled:
            return .red.opacity(0.2)
        }
    }
}
