//
//  QuantitySelectorView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import SwiftUI

struct QuantitySelectorView: View {
    @Binding var quantity: Int
    
    let isEnabled: Bool
    let theme: AppSectionTheme
    
    var minimum: Int = 1
    var maximum: Int? = nil
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var palette: ThemePalette {
        AppTheme.palette(for: theme, scheme: colorScheme)
    }
    
    private var canDecrease: Bool {
        isEnabled && quantity > minimum
    }
    
    private var canIncrease: Bool {
        guard isEnabled else { return false }
        guard let maximum else { return true }
        return quantity < maximum
    }
    
    var body: some View {
        HStack(spacing: 14) {
            controlButton(
                systemImage: "minus",
                enabled: canDecrease
            ) {
                quantity -= 1
            }
            
            Text("\(quantity)")
                .font(.title3.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(isEnabled ? palette.textPrimary : palette.textTertiary)
                .frame(minWidth: 44)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(palette.elevatedCard)
                )
                .overlay(
                    Capsule()
                        .stroke(palette.stroke, lineWidth: 1)
                )
            
            controlButton(
                systemImage: "plus",
                enabled: canIncrease
            ) {
                quantity += 1
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.xLarge, style: .continuous)
                .fill(palette.cardGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.xLarge, style: .continuous)
                .stroke(palette.stroke, lineWidth: 1)
        )
        .shadow(
            color: palette.shadow.opacity(colorScheme == .dark ? 0.16 : 0.06),
            radius: 10,
            x: 0,
            y: 4
        )
        .opacity(isEnabled ? 1 : 0.65)
        .animation(.easeOut(duration: 0.18), value: quantity)
        .animation(.easeOut(duration: 0.18), value: isEnabled)
    }
    
    private func controlButton(
        systemImage: String,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(enabled ? palette.onPrimary : palette.textTertiary)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(
                            enabled
                            ? AnyShapeStyle(palette.heroGradient)
                            : AnyShapeStyle(palette.card)
                        )
                )
                .overlay(
                    Circle()
                        .stroke(
                            enabled ? Color.white.opacity(0.12) : palette.stroke,
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: enabled
                    ? palette.shadow.opacity(colorScheme == .dark ? 0.22 : 0.10)
                    : .clear,
                    radius: 8,
                    x: 0,
                    y: 4
                )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .scaleEffect(enabled ? 1.0 : 0.96)
        .animation(.easeOut(duration: 0.18), value: enabled)
    }
}
