//
//  AltosDirectionsView.swift
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

    private let theme: AppSectionTheme = .adventure

    private var palette: ThemePalette {
        AppTheme.palette(for: theme, scheme: colorScheme)
    }

    var body: some View {
        ZStack(alignment: .top) {
            routeMap
                .ignoresSafeArea(edges: .bottom)

            VStack(spacing: 12) {
                topGlassCard
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .navigationTitle("Cómo llegar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    routeNavigator.showDestination()
                } label: {
                    Image(systemName: "mappin.and.ellipse.circle.fill")
                        .foregroundStyle(palette.primary)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomRoutePanel
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
            .tint(.green)

            UserAnnotation()

            if let route = routeNavigator.route {
                MapPolyline(route.polyline)
                    .stroke(.blue, style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
            }
        }
        .mapStyle(.hybrid(elevation: .realistic))
        .mapControls {
            MapCompass()
            MapScaleView()
            MapUserLocationButton()
        }
    }

    private var topGlassCard: some View {
        HStack(spacing: 12) {
            BrandIconBubble(theme: theme, systemImage: "location.north.line.fill", size: 46)

            VStack(alignment: .leading, spacing: 4) {
                Text(Destination.name)
                    .font(.headline)
                    .foregroundStyle(palette.textPrimary)

                Text(Destination.address)
                    .font(.caption)
                    .foregroundStyle(palette.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            Button {
                routeNavigator.followUser()
            } label: {
                Image(systemName: "location.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(palette.primary))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(colorScheme == .dark ? 0.14 : 0.28), lineWidth: 1)
        )
        .shadow(color: palette.shadow.opacity(0.18), radius: 16, x: 0, y: 8)
    }

    private var bottomRoutePanel: some View {
        VStack(spacing: 12) {
            Capsule()
                .fill(palette.stroke)
                .frame(width: 44, height: 5)
                .padding(.top, 8)

            statusHeader

            ProgressView(value: routeNavigator.progress)
                .tint(palette.primary)

            HStack(spacing: 10) {
                metricPill(title: "Distancia", value: routeNavigator.distanceText, systemImage: "road.lanes")
                metricPill(title: "Tiempo", value: routeNavigator.etaText, systemImage: "clock.fill")
            }

            instructionCard

            if !routeNavigator.routeSteps.isEmpty {
                routeStepsDisclosure
            }

            actionButtons
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
        )
    }

    private var statusHeader: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(routeNavigator.state.title)
                    .font(.title3.bold())
                    .foregroundStyle(palette.textPrimary)

                Text(routeNavigator.statusText)
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            if routeNavigator.state.isActivelyNavigating {
                Button(role: .destructive) {
                    routeNavigator.stopNavigation()
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var instructionCard: some View {
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

    private var routeStepsDisclosure: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(routeNavigator.routeSteps.prefix(8).enumerated()), id: \.offset) { index, step in
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

                            Text(Self.stepDistanceText(step.distance))
                                .font(.caption2)
                                .foregroundStyle(palette.textSecondary)
                        }

                        Spacer(minLength: 0)
                    }
                }
            }
            .padding(.top, 8)
        } label: {
            Label("Ver indicaciones", systemImage: "list.bullet.rectangle")
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

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button {
                routeNavigator.startNavigation()
            } label: {
                Label(routeNavigator.state.isActivelyNavigating ? "Ruta en progreso" : "Iniciar ruta dentro de la app", systemImage: "location.north.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(BrandPrimaryButtonStyle(theme: theme))
            .disabled(!routeNavigator.canStartRoute)

            Button {
                routeNavigator.openInAppleMaps()
            } label: {
                Label("Abrir en Apple Maps solo si lo necesitas", systemImage: "map.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(BrandSecondaryButtonStyle(theme: theme))
        }
    }

    private func metricPill(title: String, value: String, systemImage: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(palette.primary)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(palette.textSecondary)
                Text(value)
                    .font(.caption.bold())
                    .foregroundStyle(palette.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(palette.elevatedCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
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
