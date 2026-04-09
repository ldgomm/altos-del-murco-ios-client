//
//  AdventureCatalogView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 1/4/26.
//

import SwiftUI

@MainActor
struct AdventureCatalogView: View {
    @ObservedObject var comboBuilderViewModel: AdventureComboBuilderViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    private let singles = AdventureActivityType.allCases.map(AdventureActivityType.defaultDraft(for:))
    
    private var palette: ThemePalette {
        AppTheme.palette(for: .adventure, scheme: colorScheme)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 24) {
                    heroSection
                    featuredSection
                    singlesSection
                    customComboSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .navigationTitle("Aventura en Los Altos")
            .navigationBarTitleDisplayMode(.large)
        }
        .appScreenStyle(.adventure)
    }
    
    private var heroSection: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: AppTheme.Radius.xLarge, style: .continuous)
                .fill(palette.heroGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.xLarge, style: .continuous)
                        .stroke(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.18), lineWidth: 1)
                )
                .shadow(
                    color: palette.shadow.opacity(colorScheme == .dark ? 0.30 : 0.14),
                    radius: 22,
                    x: 0,
                    y: 12
                )
            
            Circle()
                .fill(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.18))
                .frame(width: 160, height: 160)
                .blur(radius: 10)
                .offset(x: 40, y: -30)
            
            Circle()
                .fill(palette.accent.opacity(colorScheme == .dark ? 0.26 : 0.20))
                .frame(width: 120, height: 120)
                .blur(radius: 18)
                .offset(x: 10, y: 55)
            
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    BrandIconBubble(theme: .adventure, systemImage: "mountain.2.fill", size: 56)
                    
                    Spacer()
                    
                    BrandBadge(theme: .adventure, title: "Outdoor", selected: true)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Construye tu combo perfecto")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white)
                    
                    Text("Mezcla off-road, paintball, go karts, campo de tiro, camping y columpio extremo con una experiencia con identidad propia.")
                        .font(.subheadline)
                        .foregroundStyle(Color.white.opacity(0.92))
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        heroChip("Off-road")
                        heroChip("Paintball")
                        heroChip("Go karts")
                        heroChip("Camping")
                    }
                }
                
                NavigationLink {
                    AdventureComboBuilderView(viewModel: comboBuilderViewModel)
                        .onAppear {
                            comboBuilderViewModel.reset()
                        }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                        Text("Iniciar combo personalizado")
                    }
                }
                .buttonStyle(BrandPrimaryButtonStyle(theme: .adventure))
            }
            .padding(22)
        }
    }
    
    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            BrandSectionHeader(
                theme: .adventure,
                title: "Paquetes destacados",
                subtitle: "Combos sugeridos para reservar más rápido."
            )
            
            ForEach(AdventureCatalogTemplates.featured) { template in
                NavigationLink {
                    AdventureComboBuilderView(viewModel: comboBuilderViewModel)
                        .onAppear {
                            comboBuilderViewModel.replaceItems(with: template.items)
                        }
                } label: {
                    TemplateCard(template: template)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var singlesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            BrandSectionHeader(
                theme: .adventure,
                title: "Actividades individuales",
                subtitle: "Reserva una sola experiencia de forma directa."
            )
            
            ForEach(singles, id: \.id) { item in
                NavigationLink {
                    AdventureComboBuilderView(viewModel: comboBuilderViewModel)
                        .onAppear {
                            comboBuilderViewModel.replaceItems(with: [item])
                        }
                } label: {
                    SingleActivityCard(item: item)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var customComboSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            BrandSectionHeader(
                theme: .adventure,
                title: "¿Necesitas algo diferente?",
                subtitle: "Crea una combinación a medida con tiempos y cantidades personalizadas."
            )
            
            VStack(alignment: .leading, spacing: 14) {
                Text("Puedes arrastrar para reordenar las actividades y establecer diferentes duraciones y número de personas por actividad.")
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
                
                NavigationLink {
                    AdventureComboBuilderView(viewModel: comboBuilderViewModel)
                        .onAppear {
                            comboBuilderViewModel.reset()
                        }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                        Text("Abrir creador de aventuras")
                    }
                }
                .buttonStyle(BrandSecondaryButtonStyle(theme: .adventure))
            }
            .appCardStyle(.adventure)
        }
    }
    
    private func heroChip(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.white.opacity(0.95))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(colorScheme == .dark ? 0.12 : 0.16))
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            )
            .clipShape(Capsule())
    }
}

private struct TemplateCard: View {
    let template: AdventureTemplate
    @Environment(\.colorScheme) private var colorScheme
    
    private var palette: ThemePalette {
        AppTheme.palette(for: .adventure, scheme: colorScheme)
    }
    
    private var priceText: String {
        String(format: "%.2f", AdventurePricingEngine.estimatedDiscountedSubtotal(items: template.items))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                BrandIconBubble(
                    theme: .adventure,
                    systemImage: "figure.hiking",
                    size: 50
                )
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(template.title)
                        .font(.headline)
                        .foregroundStyle(palette.textPrimary)
                    
                    Text(template.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if let badge = template.badge {
                    BrandBadge(theme: .adventure, title: badge)
                }
            }
            
            HStack {
                Label("Desde $\(priceText)", systemImage: "dollarsign.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.primary)
                
                Spacer()
                
                Label("Ver combo", systemImage: "arrow.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(palette.textSecondary)
            }
        }
        .appCardStyle(.adventure, emphasized: false)
    }
}

private struct SingleActivityCard: View {
    let item: AdventureReservationItemDraft
    @Environment(\.colorScheme) private var colorScheme
    
    private var palette: ThemePalette {
        AppTheme.palette(for: .adventure, scheme: colorScheme)
    }
    
    private var basePrice: Double {
        AdventurePricingEngine.subtotal(for: item)
    }
    
    var body: some View {
        HStack(spacing: 14) {
            BrandIconBubble(
                theme: .adventure,
                systemImage: item.activity.systemImage,
                size: 56
            )
            
            VStack(alignment: .leading, spacing: 6) {
                Text(item.activity.title)
                    .font(.headline)
                    .foregroundStyle(palette.textPrimary)
                
                Text(item.summaryText)
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
                    .lineLimit(2)
                
                Text("Desde $\(basePrice, specifier: "%.2f")")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.primary)
            }
            
            Spacer(minLength: 8)
            
            VStack(alignment: .trailing, spacing: 8) {
                Image(systemName: "arrow.up.right.circle.fill")
                    .font(.title3)
                    .foregroundStyle(palette.primary)
                
                Text("Reservar")
                    .font(.caption.bold())
                    .foregroundStyle(palette.textSecondary)
            }
        }
        .appCardStyle(.adventure)
    }
}
