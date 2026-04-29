//
//  DirectionsView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 28/4/26.
//

import CoreLocation
import MapKit
import SwiftUI

struct DirectionsView: View {
    @EnvironmentObject private var routeNavigator: RouteNavigationManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var isDetailsExpanded = false
    @State private var isStepsExpanded = false

    private let theme: AppSectionTheme = .adventure

    private var palette: ThemePalette {
        AppTheme.palette(for: theme, scheme: colorScheme)
    }

    var body: some View {
        ZStack(alignment: .top) {
            routeMap
                .ignoresSafeArea()

            VStack(spacing: 0) {
                compactDestinationPill
                    .padding(.horizontal, 16)
                    .padding(.top, 10)

                Spacer()
            }

            floatingMapControls
                .padding(.trailing, 16)
                .padding(.top, 84)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
        .navigationTitle("Cómo llegar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        routeNavigator.showDestination()
                    } label: {
                        Label("Ver destino", systemImage: "mappin.and.ellipse")
                    }

                    Button {
                        routeNavigator.followUser()
                    } label: {
                        Label("Seguir mi ubicación", systemImage: "location.fill")
                    }

                    Divider()

                    Button {
                        routeNavigator.openInAppleMaps()
                    } label: {
                        Label("Abrir en Apple Maps", systemImage: "map.fill")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.title3)
                        .foregroundStyle(palette.primary)
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 40) {
            bottomRouteCard
        }
        .onAppear {
            if case .idle = routeNavigator.state {
                routeNavigator.preparePreview()
            }
        }
    }

    private var routeMap: some View {
        Map(position: $routeNavigator.cameraPosition) {
            Marker(
                Destination.name,
                systemImage: "mountain.2.fill",
                coordinate: Destination.coordinate
            )
            .tint(palette.primary)

            UserAnnotation()

            if let route = routeNavigator.route {
                MapPolyline(route.polyline)
                    .stroke(
                        palette.primary,
                        style: StrokeStyle(
                            lineWidth: 7,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
            }
        }
        .mapStyle(
            .standard(
                elevation: .flat,
                pointsOfInterest: .excludingAll,
                showsTraffic: false
            )
        )
        .mapControls {
            MapCompass()
        }
    }

    private var compactDestinationPill: some View {
        HStack(spacing: 10) {
            Image(systemName: "mountain.2.fill")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(Circle().fill(palette.primary))

            VStack(alignment: .leading, spacing: 2) {
                Text(Destination.name)
                    .font(.subheadline.bold())
                    .foregroundStyle(palette.textPrimary)
                    .lineLimit(1)

                Text(Destination.subtitle)
                    .font(.caption)
                    .foregroundStyle(palette.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            statusMiniBadge
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(colorScheme == .dark ? 0.12 : 0.22), lineWidth: 1)
        )
        .shadow(
            color: palette.shadow.opacity(colorScheme == .dark ? 0.25 : 0.12),
            radius: 14,
            x: 0,
            y: 8
        )
    }

    private var statusMiniBadge: some View {
        Text(routeNavigator.state.title)
            .font(.caption2.bold())
            .foregroundStyle(palette.primary)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(palette.primary.opacity(colorScheme == .dark ? 0.22 : 0.13))
            )
            .lineLimit(1)
    }

    private var floatingMapControls: some View {
        VStack(spacing: 10) {
            mapControlButton(
                systemImage: "location.fill",
                accessibilityLabel: "Seguir mi ubicación"
            ) {
                routeNavigator.followUser()
            }

            mapControlButton(
                systemImage: "mappin.and.ellipse",
                accessibilityLabel: "Ver destino"
            ) {
                routeNavigator.showDestination()
            }
        }
    }

    private func mapControlButton(
        systemImage: String,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.headline.weight(.semibold))
                .foregroundStyle(palette.textPrimary)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(colorScheme == .dark ? 0.12 : 0.22), lineWidth: 1)
                )
                .shadow(
                    color: palette.shadow.opacity(colorScheme == .dark ? 0.24 : 0.12),
                    radius: 10,
                    x: 0,
                    y: 6
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    private var bottomRouteCard: some View {
        VStack(spacing: 12) {
            Capsule()
                .fill(palette.stroke)
                .frame(width: 42, height: 5)
                .padding(.top, 8)

            routeSummaryRow

            ProgressView(value: routeNavigator.progress)
                .tint(palette.primary)

            contextualBanner

            primaryActionRow

            if isDetailsExpanded {
                expandedDetails
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity
                        )
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        )
        .overlay(alignment: .top) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.18), lineWidth: 1)
        }
        .shadow(
            color: palette.shadow.opacity(colorScheme == .dark ? 0.30 : 0.14),
            radius: 22,
            x: 0,
            y: -8
        )
    }

    private var routeSummaryRow: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(routeNavigator.state.title)
                    .font(.headline.bold())
                    .foregroundStyle(palette.textPrimary)
                    .lineLimit(1)

                Text(summaryText)
                    .font(.caption)
                    .foregroundStyle(palette.textSecondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 10)

            VStack(alignment: .trailing, spacing: 2) {
                Text(routeNavigator.etaText)
                    .font(.title2.bold())
                    .foregroundStyle(palette.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(routeNavigator.distanceText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.textSecondary)
                    .lineLimit(1)
            }
        }
    }

    private var summaryText: String {
        switch routeNavigator.state {
        case .idle:
            return "Preparamos una ruta limpia hasta \(Destination.name)."
        case .permissionNeeded:
            return "Permite ubicación para calcular la ruta desde tu posición."
        case .locating:
            return "Buscando tu ubicación actual."
        case .calculating:
            return "Calculando la mejor ruta disponible."
        case .previewReady:
            return "Ruta lista. Puedes iniciar sin salir de la app."
        case .navigating:
            return routeNavigator.primaryInstruction
        case .arrived:
            return "Has llegado a \(Destination.name)."
        case .failed(let message):
            return message
        }
    }

    @ViewBuilder
    private var contextualBanner: some View {
        switch routeNavigator.state {
        case .permissionNeeded:
            compactInfoBanner(
                systemImage: "location.slash.fill",
                title: "Ubicación requerida",
                message: "Activa el permiso de ubicación para ver la ruta desde tu posición."
            )

        case .failed(let message):
            compactInfoBanner(
                systemImage: "exclamationmark.triangle.fill",
                title: "No pudimos calcular la ruta",
                message: message
            )

        case .arrived:
            compactInfoBanner(
                systemImage: "checkmark.seal.fill",
                title: "Llegaste",
                message: "Bienvenido a Altos del Murco."
            )

        default:
            EmptyView()
        }
    }

    private func compactInfoBanner(
        systemImage: String,
        title: String,
        message: String
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(palette.primary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.bold())
                    .foregroundStyle(palette.textPrimary)

                Text(message)
                    .font(.caption)
                    .foregroundStyle(palette.textSecondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(palette.elevatedCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(palette.stroke, lineWidth: 1)
        )
    }

    private var primaryActionRow: some View {
        HStack(spacing: 10) {
            Button {
                if routeNavigator.state.isActivelyNavigating {
                    routeNavigator.stopNavigation()
                    dismiss()
                } else {
                    routeNavigator.startNavigation()
                }
            } label: {
                Label(primaryButtonTitle, systemImage: primaryButtonIcon)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(BrandPrimaryButtonStyle(theme: theme))
            .disabled(!routeNavigator.canStartRoute && !routeNavigator.state.isActivelyNavigating)

            Button {
                withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                    isDetailsExpanded.toggle()
                }
            } label: {
                Image(systemName: isDetailsExpanded ? "chevron.down" : "list.bullet")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(palette.primary)
                    .frame(width: 50, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(palette.elevatedCard)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(palette.stroke, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isDetailsExpanded ? "Ocultar detalles" : "Ver detalles")
        }
    }

    private var primaryButtonTitle: String {
        switch routeNavigator.state {
        case .navigating:
            return "Detener"
        case .locating, .calculating:
            return "Calculando..."
        case .arrived:
            return "Ruta finalizada"
        default:
            return "Iniciar ruta"
        }
    }

    private var primaryButtonIcon: String {
        switch routeNavigator.state {
        case .navigating:
            return "xmark.circle.fill"
        case .locating, .calculating:
            return "clock.fill"
        case .arrived:
            return "checkmark.circle.fill"
        default:
            return "location.north.circle.fill"
        }
    }

    private var expandedDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            nextInstructionCard

            if !routeNavigator.routeSteps.isEmpty {
                routeStepsCard
            }

            Button {
                routeNavigator.openInAppleMaps()
            } label: {
                Label("Abrir en Apple Maps", systemImage: "map.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(BrandSecondaryButtonStyle(theme: theme))
        }
    }

    private var nextInstructionCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "arrow.turn.up.right")
                .font(.headline)
                .foregroundStyle(palette.primary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text("Siguiente indicación")
                    .font(.caption.bold())
                    .foregroundStyle(palette.textSecondary)

                Text(routeNavigator.primaryInstruction)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(palette.elevatedCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(palette.stroke, lineWidth: 1)
        )
    }

    private var routeStepsCard: some View {
        DisclosureGroup(isExpanded: $isStepsExpanded) {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(routeNavigator.routeSteps.prefix(6).enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1)")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(palette.primary))

                        VStack(alignment: .leading, spacing: 3) {
                            Text(step.instructions)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(palette.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(Self.stepDistanceText(step.distance))
                                .font(.caption2)
                                .foregroundStyle(palette.textSecondary)
                        }

                        Spacer(minLength: 0)
                    }
                }

                if routeNavigator.routeSteps.count > 6 {
                    Text("+\(routeNavigator.routeSteps.count - 6) indicación(es) más en Apple Maps")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(palette.textTertiary)
                }
            }
            .padding(.top, 8)
        } label: {
            Label("Indicaciones", systemImage: "list.bullet.rectangle")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(palette.primary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(palette.elevatedCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(palette.stroke, lineWidth: 1)
        )
    }

    private static func stepDistanceText(_ meters: CLLocationDistance) -> String {
        let formatter = MKDistanceFormatter()
        formatter.units = .metric
        formatter.unitStyle = .abbreviated
        return formatter.string(fromDistance: meters)
    }
}
