//
//  AdventureReservationsView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import SwiftUI

struct AdventureReservationsView: View {
    @EnvironmentObject private var sessionViewModel: AppSessionViewModel
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: AdventureBookingsViewModel

    init(viewModelFactory: @escaping () -> AdventureBookingsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModelFactory())
    }
    
    private var palette: ThemePalette {
        AppTheme.palette(for: .adventure, scheme: colorScheme)
    }

    private var authenticatedProfile: ClientProfile? {
        sessionViewModel.authenticatedProfile
    }
    
    var body: some View {
        Group {
            if viewModel.state.isLoading && viewModel.state.bookings.isEmpty {
                VStack(spacing: 16) {
                    ProgressView()
                        .controlSize(.large)
                        .tint(palette.primary)
                    
                    Text("Cargando reservas...")
                        .font(.headline)
                        .foregroundStyle(palette.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .appScreenStyle(.adventure)
            } else {
                List {
                    headerSection
                    dateSection
                    contentSection
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .appScreenStyle(.adventure)
            }
        }
        .navigationTitle("Reservas y eventos")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            syncNationalIdFromSession()
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
        
    }
    private func syncNationalIdFromSession() {
        guard let nationalId = authenticatedProfile?.nationalId else { return }
        viewModel.setNationalId(nationalId)
    }
    
    private var headerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    BrandIconBubble(theme: .adventure, systemImage: "calendar.badge.clock", size: 52)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Gestiona tus reservas")
                            .font(.title3.bold())
                            .foregroundStyle(palette.textPrimary)
                        
                        Text("Consulta reservas de aventura, comida, cumpleaños y otros eventos.")
                            .font(.subheadline)
                            .foregroundStyle(palette.textSecondary)
                    }
                }
            }
            .appCardStyle(.adventure, emphasized: false)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }
    
    private var dateSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 14) {
                Text("Fecha")
                    .font(.headline)
                    .foregroundStyle(palette.textPrimary)
                
                DatePicker(
                    "Fecha seleccionada",
                    selection: Binding(
                        get: { viewModel.state.selectedDate },
                        set: { viewModel.setDate($0) }
                    ),
                    in: Date()...,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(palette.primary)
            }
            .padding(.vertical, 4)
            .appCardStyle(.adventure)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }
    
    @ViewBuilder
    private var contentSection: some View {
        if viewModel.state.bookings.isEmpty {
            Section {
                ContentUnavailableView(
                    "Sin reservas",
                    systemImage: "calendar",
                    description: Text("Las reservas para la fecha seleccionada aparecerán aquí.")
                )
                .foregroundStyle(palette.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .appCardStyle(.adventure)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        } else {
            Section {
                ForEach(viewModel.state.bookings) { booking in
                    AdventureReservationRow(booking: booking)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing) {
                            if booking.status != .canceled {
                                Button(role: .destructive) {
                                    viewModel.cancelBooking(booking.id)
                                } label: {
                                    Label("Cancelar", systemImage: "xmark")
                                }
                            }
                        }
                }
            } header: {
                Text("Reservas")
                    .font(.headline)
                    .foregroundStyle(palette.textSecondary)
                    .textCase(nil)
                    .padding(.horizontal, 20)
            }
        }
    }
}

private struct AdventureReservationRow: View {
    let booking: AdventureBooking
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var palette: ThemePalette {
        AppTheme.palette(for: .adventure, scheme: colorScheme)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                BrandIconBubble(theme: .adventure, systemImage: "figure.hiking", size: 46)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(booking.clientName)
                        .font(.headline)
                        .foregroundStyle(palette.textPrimary)
                    
                    Text("\(AdventureDateHelper.timeText(booking.startAt)) • \(booking.whatsappNumber)")
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)
                    
                    Text("Cédula \(booking.nationalId)")
                        .font(.caption)
                        .foregroundStyle(palette.textTertiary)
                }
                
                Spacer()
                
                statusBadge
            }
            
            HStack(spacing: 8) {
                BrandBadge(theme: .adventure, title: booking.visitTypeTitle)
                BrandBadge(theme: .adventure, title: booking.eventDisplayTitle, selected: booking.eventType != .regularVisit)
            }
            
            Text("Invitados: \(booking.guestCount)")
                .font(.subheadline)
                .foregroundStyle(palette.textSecondary)
            
            if booking.hasActivities {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Actividades")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.textPrimary)
                    
                    ForEach(booking.items, id: \.id) { item in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(palette.primary)
                                .frame(width: 6, height: 6)
                                .padding(.top, 6)
                            
                            Text("\(item.title) — \(item.summaryText)")
                                .font(.caption)
                                .foregroundStyle(palette.textSecondary)
                        }
                    }
                }
            }
            
            if let food = booking.foodReservation, !food.items.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Comida reservada")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.textPrimary)
                    
                    ForEach(food.items, id: \.id) { item in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(palette.accent)
                                .frame(width: 6, height: 6)
                                .padding(.top, 6)
                            
                            Text("\(item.quantity)x \(item.name)")
                                .font(.caption)
                                .foregroundStyle(palette.textSecondary)
                        }
                    }
                }
            }
            
            Divider()
                .overlay(palette.stroke)
            
            VStack(spacing: 8) {
                amountRow("Aventura", booking.adventureSubtotal)
                amountRow("Comida", booking.foodSubtotal)
                amountRow("Descuento", -booking.discountAmount)
//                amountRow("Recargo nocturno", booking.nightPremium)
                amountRow("Total", booking.totalAmount, isPrimary: true)
            }
        }
        .appCardStyle(.adventure)
    }
    
    private func amountRow(_ title: String, _ amount: Double, isPrimary: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(isPrimary ? .headline : .subheadline)
                .foregroundStyle(isPrimary ? palette.textPrimary : palette.textSecondary)
            Spacer()
            Text(amount.priceText)
                .font(isPrimary ? .headline.bold() : .subheadline.weight(.semibold))
                .foregroundStyle(isPrimary ? palette.primary : palette.textPrimary)
        }
    }
    
    private var statusBadge: some View {
        Text(booking.status.title)
            .font(.caption.bold())
            .foregroundStyle(statusTextColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(statusBackgroundColor)
            )
            .overlay(
                Capsule()
                    .stroke(statusBorderColor, lineWidth: 1)
            )
    }
    
    private var statusBackgroundColor: Color {
        switch booking.status {
        case .pending:
            return palette.warning.opacity(colorScheme == .dark ? 0.22 : 0.14)
        case .confirmed:
            return palette.success.opacity(colorScheme == .dark ? 0.22 : 0.14)
        case .canceled:
            return palette.destructive.opacity(colorScheme == .dark ? 0.22 : 0.14)
        }
    }
    
    private var statusBorderColor: Color {
        switch booking.status {
        case .pending:
            return palette.warning.opacity(0.45)
        case .confirmed:
            return palette.success.opacity(0.45)
        case .canceled:
            return palette.destructive.opacity(0.45)
        }
    }
    
    private var statusTextColor: Color {
        switch booking.status {
        case .pending:
            return palette.warning
        case .confirmed:
            return palette.success
        case .canceled:
            return palette.destructive
        }
    }
}
