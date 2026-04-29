//
//  RouteNavigationManager.swift
//  Altos del Murco
//
//  Created by José Ruiz on 28/4/26.
//

import Combine
import CoreLocation
import Foundation
import MapKit
import SwiftUI

@MainActor
final class RouteNavigationManager: NSObject, ObservableObject {
    enum RouteState: Equatable {
        case idle
        case permissionNeeded
        case locating
        case calculating
        case previewReady
        case navigating
        case arrived
        case failed(String)

        var isVisibleGlobally: Bool {
            switch self {
            case .idle, .permissionNeeded:
                return false
            case .locating, .calculating, .previewReady, .navigating, .arrived, .failed:
                return true
            }
        }

        var isActivelyNavigating: Bool {
            if case .navigating = self { return true }
            return false
        }

        var title: String {
            switch self {
            case .idle: return "Ruta inactiva"
            case .permissionNeeded: return "Permiso requerido"
            case .locating: return "Buscando tu ubicación"
            case .calculating: return "Calculando ruta"
            case .previewReady: return "Ruta lista!"
            case .navigating: return "En camino"
            case .arrived: return "Llegaste"
            case .failed: return "Ruta no disponible"
            }
        }
    }

    @Published private(set) var state: RouteState = .idle
    @Published private(set) var userLocation: CLLocation?
    @Published private(set) var route: MKRoute?
    @Published private(set) var lastUpdatedAt: Date?
    @Published var cameraPosition: MapCameraPosition = .region(Destination.cameraRegion)
    @Published var showsRouteSheet = false

    private let manager = CLLocationManager()
    private let liveActivityService = RouteLiveActivityService()

    private var pendingStartAfterPermission = false
    private var initialDistanceMeters: CLLocationDistance?
    private var lastRouteOrigin: CLLocation?
    private var routeTask: Task<Void, Never>?
    private let arrivalThresholdMeters: CLLocationDistance = 80
    private let routeRefreshDistanceMeters: CLLocationDistance = 120

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = 8
        manager.activityType = .automotiveNavigation
    }

    var shouldShowGlobalBanner: Bool {
        state.isVisibleGlobally
    }

    var canStartRoute: Bool {
        switch state {
        case .locating, .calculating, .navigating:
            return false
        default:
            return true
        }
    }

    var progress: Double {
        guard let initialDistanceMeters, initialDistanceMeters > 0 else { return 0 }
        let remaining = remainingDistanceMeters
        return min(1, max(0, 1 - (remaining / initialDistanceMeters)))
    }

    var remainingDistanceMeters: CLLocationDistance {
        guard let userLocation else {
            return route?.distance ?? 0
        }

        return max(0, userLocation.distance(from: Destination.location))
    }

    var distanceText: String {
        Self.distanceFormatter.string(fromDistance: remainingDistanceMeters)
    }

    var etaText: String {
        let seconds: TimeInterval

        if let route {
            let remainingRatio = max(0.08, 1 - progress)
            seconds = max(60, route.expectedTravelTime * remainingRatio)
        } else {
            let estimatedMetersPerSecond: Double = 8.3 // ~30 km/h, safer for rural/local roads.
            seconds = max(60, remainingDistanceMeters / estimatedMetersPerSecond)
        }

        return Self.timeFormatter.string(from: seconds) ?? "—"
    }

    var statusText: String {
        switch state {
        case .failed(let message): return message
        case .arrived: return "Has llegado a Altos del Murco"
        default: return state.title
        }
    }

    var primaryInstruction: String {
        guard let route else {
            return "Marca la ruta para ver cómo llegar a Altos del Murco."
        }

        return route.steps
            .map { $0.instructions.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first(where: { !$0.isEmpty })
            ?? "Sigue la ruta hacia Altos del Murco."
    }

    var routeSteps: [MKRoute.Step] {
        route?.steps.filter { !$0.instructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } ?? []
    }

    func preparePreview() {
        guard canStartRoute else { return }
        requestLocationAndRoute(startNavigation: false)
    }

    func startNavigation() {
        requestLocationAndRoute(startNavigation: true)
    }

    func stopNavigation() {
        pendingStartAfterPermission = false
        routeTask?.cancel()
        routeTask = nil
        manager.stopUpdatingLocation()
        manager.allowsBackgroundLocationUpdates = false
        manager.showsBackgroundLocationIndicator = false
        route = nil
        userLocation = nil
        initialDistanceMeters = nil
        lastRouteOrigin = nil
        lastUpdatedAt = nil
        state = .idle

        Task { await liveActivityService.end(statusText: "Ruta detenida") }
    }

    func showDestination() {
        cameraPosition = .region(Destination.cameraRegion)
    }

    func followUser() {
        cameraPosition = .userLocation(
            followsHeading: true,
            fallback: .region(Destination.cameraRegion)
        )
    }

    func openRouteSheet() {
        showsRouteSheet = true
    }

    /// Optional fallback. Keep it secondary because your requirement is to avoid leaving the app.
    func openInAppleMaps() {
        Destination.mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }

    private func requestLocationAndRoute(startNavigation: Bool) {
        let status = manager.authorizationStatus

        switch status {
        case .notDetermined:
            pendingStartAfterPermission = startNavigation
            state = .permissionNeeded
            manager.requestWhenInUseAuthorization()

        case .authorizedAlways, .authorizedWhenInUse:
            pendingStartAfterPermission = false
            state = startNavigation ? .locating : .calculating
            configureBackgroundLocationIfAvailable(enabled: startNavigation)
            manager.startUpdatingLocation()

            if let userLocation {
                calculateRoute(from: userLocation, startNavigation: startNavigation)
            }

        case .denied, .restricted:
            state = .failed("Activa ubicación en Ajustes para calcular la ruta.")

        @unknown default:
            state = .failed("No se pudo leer el permiso de ubicación.")
        }
    }

    private func configureBackgroundLocationIfAvailable(enabled: Bool) {
        guard enabled else {
            manager.allowsBackgroundLocationUpdates = false
            manager.showsBackgroundLocationIndicator = false
            return
        }

        let backgroundModes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String]
        guard backgroundModes?.contains("location") == true else {
            // Avoid enabling background updates when the capability is missing.
            // The foreground route still works; add UIBackgroundModes/location for out-of-app progress.
            return
        }

        manager.allowsBackgroundLocationUpdates = true
        manager.showsBackgroundLocationIndicator = true
        manager.pausesLocationUpdatesAutomatically = false
    }

    private func handleLocation(_ location: CLLocation) {
        userLocation = location
        lastUpdatedAt = Date()

        if initialDistanceMeters == nil {
            initialDistanceMeters = max(location.distance(from: Destination.location), 1)
        }

        if location.distance(from: Destination.location) <= arrivalThresholdMeters {
            state = .arrived
            manager.stopUpdatingLocation()
            manager.allowsBackgroundLocationUpdates = false
            manager.showsBackgroundLocationIndicator = false
            Task { await liveActivityService.end(distanceText: "Llegaste", etaText: "0 min", progress: 1, statusText: "Llegaste") }
            return
        }

        if route == nil {
            calculateRoute(from: location, startNavigation: state.isActivelyNavigating)
        } else if shouldRefreshRoute(from: location) {
            calculateRoute(from: location, startNavigation: state.isActivelyNavigating)
        }

        if state.isActivelyNavigating {
            Task {
                await liveActivityService.update(
                    distanceText: distanceText,
                    etaText: etaText,
                    progress: progress,
                    statusText: statusText
                )
            }
        }
    }

    private func shouldRefreshRoute(from location: CLLocation) -> Bool {
        guard let lastRouteOrigin else { return true }
        return location.distance(from: lastRouteOrigin) >= routeRefreshDistanceMeters
    }

    private func calculateRoute(from origin: CLLocation, startNavigation: Bool) {
        routeTask?.cancel()
        state = startNavigation ? .calculating : .calculating

        routeTask = Task { [weak self] in
            guard let self else { return }

            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin.coordinate))
            request.destination = Destination.mapItem
            request.transportType = .automobile
            request.requestsAlternateRoutes = true

            do {
                let response = try await MKDirections(request: request).calculate()
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    guard let bestRoute = response.routes.sorted(by: { $0.expectedTravelTime < $1.expectedTravelTime }).first else {
                        self.state = .failed("No se encontró una ruta disponible.")
                        return
                    }

                    self.route = bestRoute
                    self.lastRouteOrigin = origin
                    self.cameraPosition = .rect(bestRoute.polyline.boundingMapRect.paddedForAltosRoute())
                    self.state = startNavigation ? .navigating : .previewReady

                    if startNavigation {
                        self.liveActivityService.start(
                            distanceText: self.distanceText,
                            etaText: self.etaText,
                            progress: self.progress,
                            statusText: self.statusText
                        )
                    }
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.state = .failed("No pudimos calcular la ruta. Revisa tu conexión o permisos.")
                }
            }
        }
    }

    private static let distanceFormatter: MKDistanceFormatter = {
        let formatter = MKDistanceFormatter()
        formatter.unitStyle = .abbreviated
        formatter.units = .metric
        return formatter
    }()

    private static let timeFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2
        return formatter
    }()
}

extension RouteNavigationManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor [weak self] in
            guard let self else { return }

            switch manager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                self.requestLocationAndRoute(startNavigation: self.pendingStartAfterPermission)
            case .denied, .restricted:
                self.state = .failed("Activa ubicación en Ajustes para calcular la ruta.")
            case .notDetermined:
                self.state = .permissionNeeded
            @unknown default:
                self.state = .failed("No se pudo leer el permiso de ubicación.")
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        Task { @MainActor [weak self] in
            self?.handleLocation(location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor [weak self] in
            self?.state = .failed("No pudimos actualizar tu ubicación: \(error.localizedDescription)")
        }
    }
}

private extension MKMapRect {
    func paddedForAltosRoute() -> MKMapRect {
        let padding = max(size.width, size.height) * 0.22
        return insetBy(dx: -padding, dy: -padding)
    }
}
