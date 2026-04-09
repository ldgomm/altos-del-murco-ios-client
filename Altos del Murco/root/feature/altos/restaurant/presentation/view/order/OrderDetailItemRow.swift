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

    private var statusText: String {
        if item.isCompleted { return "Ready" }
        if item.isStarted { return "In progress" }
        return "Waiting"
    }

    private var progressValue: Double {
        guard item.quantity > 0 else { return 0 }
        return Double(item.preparedQuantity) / Double(item.quantity)
    }
    
    private var progressColor: Color {
        if item.isCompleted { return palette.success }
        if item.isStarted { return palette.warning }
        return palette.textTertiary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                BrandIconBubble(
                    theme: theme,
                    systemImage: "fork.knife",
                    size: 42
                )

                VStack(alignment: .leading, spacing: 6) {
                    Text(item.name)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(palette.textPrimary)

                    Text("\(item.quantity) × \(item.unitPrice.priceText)")
                        .font(.caption)
                        .foregroundStyle(palette.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text(item.totalPrice.priceText)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(palette.textPrimary)

                    ItemStatusBadge(
                        isCompleted: item.isCompleted,
                        isStarted: item.isStarted
                    )
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Prepared: \(item.preparedQuantity)/\(item.quantity)")
                        .font(.caption)
                        .foregroundStyle(palette.textSecondary)

                    Spacer()

                    Text(statusText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(progressColor)
                }

                ProgressView(value: progressValue)
                    .tint(progressColor)
            }

            if let notes = item.notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "note.text")
                        .font(.subheadline)
                        .foregroundStyle(palette.accent)
                        .padding(.top, 1)

                    Text(notes)
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)
                        .multilineTextAlignment(.leading)
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
        }
        .appCardStyle(.restaurant)
    }
}
