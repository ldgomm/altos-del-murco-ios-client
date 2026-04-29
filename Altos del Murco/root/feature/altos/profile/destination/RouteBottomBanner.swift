//
//  AltosRouteBottomBanner.swift
//  Altos del Murco
//
//  Created by José Ruiz on 28/4/26.
//

import SwiftUI

struct RouteBottomBanner: View {
    @EnvironmentObject private var routeNavigator: RouteNavigationManager
    @Environment(\.colorScheme) private var colorScheme

    private let theme: AppSectionTheme = .adventure

    private var palette: ThemePalette {
        AppTheme.palette(for: theme, scheme: colorScheme)
    }

    var body: some View {
        Button {
            routeNavigator.openRouteSheet()
        } label: {
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    BrandIconBubble(theme: theme, systemImage: iconName, size: 42)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(routeNavigator.state.title)
                            .font(.subheadline.bold())
                            .foregroundStyle(palette.textPrimary)

                        Text("\(routeNavigator.distanceText) • \(routeNavigator.etaText) • \(Destination.name)")
                            .font(.caption)
                            .foregroundStyle(palette.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    if routeNavigator.state.isActivelyNavigating {
                        Button(role: .destructive) {
                            routeNavigator.stopNavigation()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Image(systemName: "chevron.up")
                            .font(.caption.bold())
                            .foregroundStyle(palette.textTertiary)
                    }
                }

                ProgressView(value: routeNavigator.progress)
                    .tint(palette.primary)
            }
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(palette.stroke, lineWidth: 1)
            )
            .shadow(color: palette.shadow.opacity(colorScheme == .dark ? 0.28 : 0.16), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $routeNavigator.showsRouteSheet) {
            NavigationStack {
                DirectionsView()
            }
            .environmentObject(routeNavigator)
        }
    }

    private var iconName: String {
        switch routeNavigator.state {
        case .arrived: return "checkmark.seal.fill"
        case .failed: return "exclamationmark.triangle.fill"
        case .navigating: return "location.north.line.fill"
        default: return "map.fill"
        }
    }
}
