//
//  ReserveViewDetail.swift
//  Altos del Murco
//
//  Created by José Ruiz on 18/4/26.
//

import SwiftUI

struct ReserveViewDetail: View {
    let booking: AdventureBooking
    let onCancel: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var showCancelConfirmation = false

    private var palette: ThemePalette {
        AppTheme.palette(for: .adventure, scheme: colorScheme)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                heroSection
                scheduleSection
                contactSection

                if booking.hasActivities {
                    activitiesSection
                    timelineSection
                }

                if let food = booking.foodReservation, !food.items.isEmpty {
                    foodSection(food)
                }

                if hasAnyNotes {
                    notesSection
                }

                totalsSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 120)
        }
        .navigationTitle("Detalle de reserva")
        .navigationBarTitleDisplayMode(.inline)
        .appScreenStyle(.adventure)
        .safeAreaInset(edge: .bottom) {
            if let onCancel, booking.status != .canceled {
                bottomBar(onCancel: onCancel)
            }
        }
        .alert("Cancelar reserva", isPresented: $showCancelConfirmation) {
            Button("No", role: .cancel) { }
            Button("Sí, cancelar", role: .destructive) {
                onCancel?()
                dismiss()
            }
        } message: {
            Text("Esta acción marcará la reserva como cancelada.")
        }
    }

    private var heroSection: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: AppTheme.Radius.xLarge, style: .continuous)
                .fill(palette.heroGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.xLarge, style: .continuous)
                        .stroke(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.18), lineWidth: 1)
                )

            Circle()
                .fill(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.18))
                .frame(width: 150, height: 150)
                .blur(radius: 12)
                .offset(x: 36, y: -24)

            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    BrandIconBubble(
                        theme: .adventure,
                        systemImage: iconName,
                        size: 58
                    )

                    Spacer()

                    statusBadge
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(booking.eventDisplayTitle)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(booking.visitTypeTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.92))

                    Text(
                        "\(booking.startAt.formatted(date: .abbreviated, time: .shortened)) • \(booking.endAt.formatted(date: .omitted, time: .shortened))"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.88))
                }

                HStack(spacing: 8) {
                    infoChip("\(booking.guestCount) invitado(s)")
                    infoChip(booking.status.title)
                }
            }
            .padding(22)
        }
        .shadow(
            color: palette.shadow.opacity(colorScheme == .dark ? 0.30 : 0.14),
            radius: 22,
            x: 0,
            y: 12
        )
    }

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            BrandSectionHeader(
                theme: .adventure,
                title: "Horario",
                subtitle: "Resumen de fecha y duración de la reserva."
            )

            detailRow("Inicio", booking.startAt.formatted(date: .complete, time: .shortened))
            detailRow("Fin", booking.endAt.formatted(date: .complete, time: .shortened))
            detailRow("Creada", booking.createdAt.formatted(date: .abbreviated, time: .shortened))
            detailRow("Tipo", booking.visitTypeTitle)
            detailRow("Evento", booking.eventDisplayTitle)
        }
        .appCardStyle(.adventure)
    }

    private var contactSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            BrandSectionHeader(
                theme: .adventure,
                title: "Cliente",
                subtitle: "Datos asociados a la reserva."
            )

            detailRow("Nombre", booking.clientName)
            detailRow("WhatsApp", booking.whatsappNumber)
            detailRow("Cédula", booking.nationalId)

            if let clientId = booking.clientId, !clientId.isEmpty {
                detailRow("Client ID", clientId)
            }
        }
        .appCardStyle(.adventure, emphasized: false)
    }

    private var activitiesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            BrandSectionHeader(
                theme: .adventure,
                title: "Actividades reservadas",
                subtitle: "Configuración principal del combo."
            )

            VStack(spacing: 12) {
                ForEach(booking.items) { item in
                    HStack(alignment: .top, spacing: 12) {
                        BrandIconBubble(
                            theme: .adventure,
                            systemImage: item.activity.legacySystemImage,
                            size: 42
                        )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(.headline)
                                .foregroundStyle(palette.textPrimary)

                            Text(item.summaryText)
                                .font(.subheadline)
                                .foregroundStyle(palette.textSecondary)

                            let priceText = itemPriceText(item)
                            if !priceText.isEmpty {
                                Text(priceText)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(palette.primary)
                            }
                        }

                        Spacer()
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(palette.elevatedCard)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(palette.stroke, lineWidth: 1)
                    )
                }
            }
        }
        .appCardStyle(.adventure)
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            BrandSectionHeader(
                theme: .adventure,
                title: "Itinerario",
                subtitle: "Bloques reales programados dentro de la reserva."
            )

            VStack(spacing: 12) {
                ForEach(booking.blocks) { block in
                    HStack(alignment: .top, spacing: 12) {
                        VStack(spacing: 0) {
                            Circle()
                                .fill(palette.primary)
                                .frame(width: 10, height: 10)

                            Rectangle()
                                .fill(palette.stroke)
                                .frame(width: 2, height: 42)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text(block.title)
                                .font(.headline)
                                .foregroundStyle(palette.textPrimary)

                            Text(
                                "\(block.startAt.formatted(date: .omitted, time: .shortened)) - \(block.endAt.formatted(date: .omitted, time: .shortened))"
                            )
                            .font(.subheadline)
                            .foregroundStyle(palette.textSecondary)

                            Text(unitsText(for: block))
                                .font(.caption)
                                .foregroundStyle(palette.textTertiary)

                            if block.subtotal > 0 {
                                Text(block.subtotal.priceText)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(palette.primary)
                            }
                        }

                        Spacer()
                    }
                }
            }
        }
        .appCardStyle(.adventure, emphasized: false)
    }

    private func foodSection(_ food: ReservationFoodDraft) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            BrandSectionHeader(
                theme: .adventure,
                title: "Comida reservada",
                subtitle: "Platos agregados a esta reserva."
            )

            VStack(spacing: 12) {
                ForEach(food.items) { item in
                    HStack(alignment: .top, spacing: 12) {
                        BrandIconBubble(theme: .adventure, systemImage: "fork.knife", size: 40)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(item.quantity)x \(item.name)")
                                .font(.headline)

                            Text("Unitario: \(item.unitPrice.priceText)")
                                .font(.caption)
                                .foregroundStyle(palette.textSecondary)

                            Text("Subtotal: \(item.subtotal.priceText)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(palette.primary)

                            if let notes = item.notes, !notes.isEmpty {
                                Text(notes)
                                    .font(.caption)
                                    .foregroundStyle(palette.textTertiary)
                            }
                        }

                        Spacer()
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(palette.elevatedCard)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(palette.stroke, lineWidth: 1)
                    )
                }
            }

            Divider()

            detailRow("Servicio", servingMomentText(food))
            if let notes = food.notes, !notes.isEmpty {
                detailRow("Notas cocina", notes)
            }
        }
        .appCardStyle(.adventure)
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            BrandSectionHeader(
                theme: .adventure,
                title: "Notas",
                subtitle: "Indicaciones adicionales asociadas a la reserva."
            )

            if let eventNotes = booking.eventNotes, !eventNotes.isEmpty {
                noteCard(title: "Notas del evento", text: eventNotes)
            }

            if let notes = booking.notes, !notes.isEmpty {
                noteCard(title: "Notas generales", text: notes)
            }
        }
        .appCardStyle(.adventure, emphasized: false)
    }

    private var totalsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            BrandSectionHeader(
                theme: .adventure,
                title: "Totales",
                subtitle: "Resumen económico de la reserva."
            )

            amountRow("Aventura", booking.adventureSubtotal)
            amountRow("Comida", booking.foodSubtotal)
            amountRow("Subtotal", booking.subtotal)
            amountRow("Descuento", -booking.discountAmount)

            if booking.loyaltyDiscountAmount > 0 {
                amountRow("Murco Loyalty", -booking.loyaltyDiscountAmount)
            }

            amountRow(
                "Total",
                booking.totalAmount,
                isPrimary: true
            )

            if !booking.appliedRewards.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    Text("Premios aplicados")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.textPrimary)

                    ForEach(booking.appliedRewards) { reward in
                        HStack(alignment: .top, spacing: 10) {
                            BrandBadge(theme: .adventure, title: "Premio", selected: true)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(reward.title)
                                    .font(.caption.bold())
                                    .foregroundStyle(palette.textPrimary)

                                Text(reward.note)
                                    .font(.caption)
                                    .foregroundStyle(palette.textSecondary)
                            }

                            Spacer()

                            Text("-\(reward.amount.priceText)")
                                .font(.caption.bold())
                                .foregroundStyle(palette.success)
                        }
                    }
                }
            }
        }
        .appCardStyle(.adventure)
    }

    private func bottomBar(onCancel: @escaping () -> Void) -> some View {
        VStack(spacing: 10) {
            Button(role: .destructive) {
                showCancelConfirmation = true
            } label: {
                Label("Cancelar reserva", systemImage: "xmark.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(BrandPrimaryButtonStyle(theme: .adventure))
            .padding(.horizontal, 16)
            .padding(.top, 10)
        }
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
    }

    private func detailRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(palette.textSecondary)
                .frame(width: 90, alignment: .leading)

            Text(value)
                .font(.subheadline)
                .foregroundStyle(palette.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
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

    private func noteCard(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(palette.textPrimary)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(palette.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(palette.elevatedCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(palette.stroke, lineWidth: 1)
        )
    }

    private func infoChip(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white.opacity(0.95))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.16))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
            )
    }

    private func unitsText(for block: AdventureBookingBlock) -> String {
        switch block.resourceType {
        case .offRoadVehicles:
            return "\(block.reservedUnits) vehículo(s)"
        case .paintballPeople, .goKartPeople, .shootingPeople, .campingPeople, .extremeSlidePeople:
            return "\(block.reservedUnits) persona(s)"
        }
    }

    private func itemPriceText(_ item: AdventureReservationItemDraft) -> String {
        if let block = booking.blocks.first(where: { $0.activity == item.activity && $0.subtotal > 0 }) {
            return block.subtotal.priceText
        }
        return ""
    }

    private func servingMomentText(_ food: ReservationFoodDraft) -> String {
        switch food.servingMoment {
        case .onArrival:
            return "Al llegar"
        case .afterActivities:
            return "Después de actividades"
        case .specificTime:
            if let time = food.servingTime {
                return "Hora específica • \(time.formatted(date: .omitted, time: .shortened))"
            }
            return "Hora específica"
        }
    }

    private var hasAnyNotes: Bool {
        let eventNotes = booking.eventNotes?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let notes = booking.notes?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return !eventNotes.isEmpty || !notes.isEmpty
    }

    private var iconName: String {
        if booking.hasActivities { return "figure.hiking" }
        if booking.hasFoodReservation { return "fork.knife" }
        return "calendar"
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
            return Color.orange.opacity(colorScheme == .dark ? 0.25 : 0.16)
        case .confirmed:
            return Color.green.opacity(colorScheme == .dark ? 0.25 : 0.16)
        case .completed:
            return Color.blue.opacity(colorScheme == .dark ? 0.25 : 0.16)
        case .canceled:
            return Color.red.opacity(colorScheme == .dark ? 0.25 : 0.16)
        }
    }

    private var statusBorderColor: Color {
        switch booking.status {
        case .pending:
            return Color.orange.opacity(0.45)
        case .confirmed:
            return Color.green.opacity(0.45)
        case .completed:
            return Color.blue.opacity(0.45)
        case .canceled:
            return Color.red.opacity(0.45)
        }
    }

    private var statusTextColor: Color {
        switch booking.status {
        case .pending:
            return .orange
        case .confirmed:
            return .green
        case .completed:
            return .blue
        case .canceled:
            return .red
        }
    }
}
