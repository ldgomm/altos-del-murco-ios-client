//
//  ServiceDetailView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import SwiftUI

struct ServiceDetailView: View {
    let service: AdventureService
    @ObservedObject var adventureComboBuilderViewModel: AdventureComboBuilderViewModel
    @ObservedObject var menuViewModel: MenuViewModel
    
    @Environment(\.colorScheme) private var colorScheme
    
    private let theme: AppSectionTheme = .adventure
    
    private var palette: ThemePalette {
        AppTheme.palette(for: theme, scheme: colorScheme)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                descriptionSection
                infoSection
                includesSection
                actionSection
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .appScreenStyle(theme)
        .navigationTitle(service.title)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 10) {
                    BrandBadge(theme: theme, title: "Aventura", selected: true)
                    
                    Text(service.title)
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(palette.textPrimary)
                    
                    Text(service.shortDescription)
                        .font(.body)
                        .foregroundStyle(palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer(minLength: 12)
                
                BrandIconBubble(
                    theme: theme,
                    systemImage: service.systemImage,
                    size: 64
                )
            }
            
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.Radius.xLarge, style: .continuous)
                    .fill(palette.heroGradient)
                    .frame(height: 190)
                
                RoundedRectangle(cornerRadius: AppTheme.Radius.xLarge, style: .continuous)
                    .fill(.white.opacity(colorScheme == .dark ? 0.05 : 0.12))
                
                Circle()
                    .fill(palette.glow.opacity(colorScheme == .dark ? 0.22 : 0.18))
                    .frame(width: 150, height: 150)
                    .blur(radius: 20)
                    .offset(x: 85, y: -35)
                
                VStack(spacing: 12) {
                    Image(systemName: service.systemImage)
                        .font(.system(size: 58, weight: .medium))
                        .foregroundStyle(.white)
                    
                    Text("Experiencia destacada")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.95))
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.xLarge, style: .continuous)
                    .stroke(.white.opacity(colorScheme == .dark ? 0.10 : 0.20), lineWidth: 1)
            )
            .shadow(
                color: palette.shadow.opacity(colorScheme == .dark ? 0.26 : 0.12),
                radius: 18,
                x: 0,
                y: 10
            )
        }
        .appCardStyle(theme, emphasized: false)
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            BrandSectionHeader(
                theme: theme,
                title: "Sobre la experiencia",
                subtitle: "Detalles generales de la actividad."
            )
            
            Text(service.fullDescription)
                .font(.body)
                .foregroundStyle(palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .appCardStyle(theme)
    }
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            BrandSectionHeader(
                theme: theme,
                title: "Información rápida"
            )
            
            HStack(spacing: 14) {
                infoCard(
                    title: "Precio",
                    value: service.priceText,
                    systemImage: "dollarsign.circle.fill"
                )
                
                infoCard(
                    title: "Duración",
                    value: service.durationText,
                    systemImage: "clock.fill"
                )
            }
        }
    }
    
    private func infoCard(title: String, value: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            BrandIconBubble(
                theme: theme,
                systemImage: systemImage,
                size: 42
            )
            
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(palette.textSecondary)
            
            Text(value)
                .font(.headline)
                .foregroundStyle(palette.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCardStyle(theme)
    }
    
    private var includesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            BrandSectionHeader(
                theme: theme,
                title: "Incluye",
                subtitle: "Lo que forma parte de esta experiencia."
            )
            
            VStack(spacing: 12) {
                ForEach(service.includes, id: \.self) { item in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.body)
                            .foregroundStyle(palette.primary)
                            .padding(.top, 1)
                        
                        Text(item)
                            .font(.body)
                            .foregroundStyle(palette.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous)
                            .fill(palette.elevatedCard)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous)
                            .stroke(palette.stroke, lineWidth: 1)
                    )
                }
            }
        }
        .appCardStyle(theme)
    }
    
    private var actionSection: some View {
        VStack(spacing: 12) {
            NavigationLink {
                AdventureComboBuilderView(adventureComboBuilderViewModel: adventureComboBuilderViewModel, menuViewModel: menuViewModel)
                    .onAppear {
                        adventureComboBuilderViewModel.replaceItems(with: [service.defaultDraft])
                    }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "calendar.badge.plus")
                    Text("Reservar ahora")
                }
            }
            .buttonStyle(BrandPrimaryButtonStyle(theme: theme))
            
            Text("Podrás elegir fecha, horario y completar tus datos antes de confirmar.")
                .font(.footnote)
                .foregroundStyle(palette.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(.top, 4)
    }
}
