//
//  OrderStatusBadge.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import SwiftUI

struct OrderStatusBadge: View {
    let status: OrderStatus

    var body: some View {
        Text(status.title)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(backgroundColor.opacity(0.15), in: Capsule())
            .foregroundStyle(backgroundColor)
    }

    private var backgroundColor: Color {
        switch status {
        case .pending: return .orange
        case .confirmed: return .blue
        case .preparing: return .purple
        case .completed: return .green
        case .canceled: return .red
        }
    }
}

struct ItemStatusBadge: View {
    let isCompleted: Bool
    let isStarted: Bool

    var body: some View {
        Text(title)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }

    private var title: String {
        if isCompleted { return "Ready" }
        if isStarted { return "In progress" }
        return "Waiting"
    }

    private var color: Color {
        if isCompleted { return .green }
        if isStarted { return .orange }
        return .secondary
    }
}

struct InfoChip: View {
    let text: String
    let systemImage: String

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color(.tertiarySystemGroupedBackground), in: Capsule())
            .foregroundStyle(.secondary)
    }
}

struct DetailMetricView: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.headline)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}
