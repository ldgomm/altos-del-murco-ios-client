//
//  OrderDetailItemRow.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import SwiftUI

struct OrderDetailItemRow: View {
    let item: OrderItem

    @Environment(\.colorScheme) private var colorScheme

    private let theme: AppSectionTheme = .restaurant

    private var palette: ThemePalette {
        AppTheme.palette(for: theme, scheme: colorScheme)
    }

    private var isCanceled: Bool {
        item.status == .canceled
    }

    private var lifecycleDate: Date? {
        switch item.status {
        case .pending:
            return item.createdAt
        case .preparing:
            return item.preparingAt
        case .readyForDelivery:
            return item.readyForDeliveryAt
        case .delivered:
            return item.deliveredAt
        case .canceled:
            return item.canceledAt
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            headerRow
            lifecycleCard

            if let notes = item.notes?.trimmingCharacters(in: .whitespacesAndNewlines),
               !notes.isEmpty {
                noteCard(
                    title: "Nota",
                    text: notes,
                    systemImage: "note.text",
                    tint: palette.accent
                )
            }

            if let reason = item.canceledReason?.trimmingCharacters(in: .whitespacesAndNewlines),
               !reason.isEmpty {
                noteCard(
                    title: "Motivo de cancelación",
                    text: reason,
                    systemImage: "xmark.octagon.fill",
                    tint: .red
                )
            }
        }
        .appCardStyle(.restaurant)
    }

    private var headerRow: some View {
        HStack(alignment: .top, spacing: 12) {
            BrandIconBubble(
                theme: theme,
                systemImage: statusSystemImage(for: item.status),
                size: 42
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(isCanceled ? palette.textSecondary : palette.textPrimary)
                    .strikethrough(isCanceled)

                if let description = item.itemDescription?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(palette.textSecondary)
                        .lineLimit(2)
                }

                Text("\(item.quantity) × \(item.unitPrice.priceText)")
                    .font(.caption)
                    .foregroundStyle(palette.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(item.totalPrice.priceText)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(isCanceled ? palette.textSecondary : palette.textPrimary)

                OrderDetailItemStatusBadge(
                    title: statusTitle(for: item.status),
                    systemImage: statusSystemImage(for: item.status),
                    tint: statusTint(for: item.status)
                )
            }
        }
    }

    private var lifecycleCard: some View {
        HStack(spacing: 8) {
            Image(systemName: statusSystemImage(for: item.status))
                .font(.caption)
                .foregroundStyle(statusTint(for: item.status))

            Text(statusTitle(for: item.status))
                .font(.caption.weight(.semibold))
                .foregroundStyle(statusTint(for: item.status))

            Spacer()

            if let lifecycleDate {
                Text(lifecycleDate.shortDateTimeString)
                    .font(.caption2)
                    .foregroundStyle(palette.textSecondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(statusTint(for: item.status).opacity(colorScheme == .dark ? 0.16 : 0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(statusTint(for: item.status).opacity(colorScheme == .dark ? 0.28 : 0.18), lineWidth: 1)
        )
    }

    private func noteCard(
        title: String,
        text: String,
        systemImage: String,
        tint: Color
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.subheadline)
                .foregroundStyle(tint)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(palette.textPrimary)

                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.leading)
            }

            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(palette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(palette.stroke, lineWidth: 1)
        )
    }

    private func statusTitle(for status: OrderItemStatus) -> String {
        switch status {
        case .pending:
            return "En espera"
        case .preparing:
            return "Preparando"
        case .readyForDelivery:
            return "Listo"
        case .delivered:
            return "Servido"
        case .canceled:
            return "Cancelado"
        }
    }

    private func statusSystemImage(for status: OrderItemStatus) -> String {
        switch status {
        case .pending:
            return "clock"
        case .preparing:
            return "flame.fill"
        case .readyForDelivery:
            return "bell.fill"
        case .delivered:
            return "checkmark.seal.fill"
        case .canceled:
            return "xmark.octagon.fill"
        }
    }

    private func statusTint(for status: OrderItemStatus) -> Color {
        switch status {
        case .pending:
            return palette.textTertiary
        case .preparing:
            return palette.warning
        case .readyForDelivery:
            return .blue
        case .delivered:
            return palette.success
        case .canceled:
            return .red
        }
    }
}

private struct OrderDetailItemStatusBadge: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.caption2.weight(.bold))

            Text(title)
                .font(.caption2.weight(.semibold))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(tint.opacity(0.12))
        )
        .overlay(
            Capsule()
                .stroke(tint.opacity(0.20), lineWidth: 1)
        )
    }
}
