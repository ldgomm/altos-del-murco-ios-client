//
//  RouteLiveActivityService.swift
//  Altos del Murco
//
//  Created by José Ruiz on 28/4/26.
//

import Foundation

#if canImport(ActivityKit)
import ActivityKit
#endif

@MainActor
final class RouteLiveActivityService {
    #if canImport(ActivityKit)
    @available(iOS 16.2, *)
    private var activity: Activity<RouteActivityAttributes>?
    #endif

    func start(
        distanceText: String,
        etaText: String,
        arrivalText: String,
        progress: Double,
        statusText: String,
        instructionText: String
    ) {
        #if canImport(ActivityKit)
        guard #available(iOS 16.2, *) else { return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        guard activity == nil else {
            Task {
                await update(
                    distanceText: distanceText,
                    etaText: etaText,
                    arrivalText: arrivalText,
                    progress: progress,
                    statusText: statusText,
                    instructionText: instructionText
                )
            }
            return
        }

        let attributes = RouteActivityAttributes(routeName: "Ruta a Altos")
        let content = ActivityContent(
            state: makeState(
                distanceText: distanceText,
                etaText: etaText,
                arrivalText: arrivalText,
                progress: progress,
                statusText: statusText,
                instructionText: instructionText
            ),
            staleDate: Date().addingTimeInterval(5 * 60)
        )

        do {
            activity = try Activity<RouteActivityAttributes>.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
        } catch {
            print("Could not start Altos route Live Activity: \(error.localizedDescription)")
        }
        #endif
    }

    func update(
        distanceText: String,
        etaText: String,
        arrivalText: String,
        progress: Double,
        statusText: String,
        instructionText: String
    ) async {
        #if canImport(ActivityKit)
        guard #available(iOS 16.2, *) else { return }
        guard let activity else { return }

        let content = ActivityContent(
            state: makeState(
                distanceText: distanceText,
                etaText: etaText,
                arrivalText: arrivalText,
                progress: progress,
                statusText: statusText,
                instructionText: instructionText
            ),
            staleDate: Date().addingTimeInterval(5 * 60)
        )

        await activity.update(content)
        #endif
    }

    func end(
        distanceText: String = "Llegaste",
        etaText: String = "0 min",
        arrivalText: String = "Ahora",
        progress: Double = 1,
        statusText: String = "Ruta finalizada",
        instructionText: String = "Bienvenido a Altos del Murco."
    ) async {
        #if canImport(ActivityKit)
        guard #available(iOS 16.2, *) else { return }
        guard let activity else { return }

        let content = ActivityContent(
            state: makeState(
                distanceText: distanceText,
                etaText: etaText,
                arrivalText: arrivalText,
                progress: progress,
                statusText: statusText,
                instructionText: instructionText
            ),
            staleDate: nil
        )

        await activity.end(
            content,
            dismissalPolicy: .after(Date().addingTimeInterval(10))
        )

        self.activity = nil
        #endif
    }

    #if canImport(ActivityKit)
    @available(iOS 16.2, *)
    private func makeState(
        distanceText: String,
        etaText: String,
        arrivalText: String,
        progress: Double,
        statusText: String,
        instructionText: String
    ) -> RouteActivityAttributes.ContentState {
        RouteActivityAttributes.ContentState(
            destinationName: Destination.name,
            distanceText: distanceText,
            etaText: etaText,
            arrivalText: arrivalText,
            progress: min(1, max(0, progress)),
            statusText: statusText,
            instructionText: instructionText,
            updatedAt: Date()
        )
    }
    #endif
}
