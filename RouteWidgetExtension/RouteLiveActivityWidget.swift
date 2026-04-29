//
//  AltosRouteLiveActivityWidget.swift
//  AltosRouteWidgetExtension
//
//  Created by José Ruiz on 28/4/26.
//

import ActivityKit
import SwiftUI
import WidgetKit

@available(iOS 16.2, *)
struct RouteLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RouteActivityAttributes.self) { context in
            RouteLockScreenView(state: context.state)
                .padding(16)
                .activityBackgroundTint(Color.black.opacity(0.88))
                .activitySystemActionForegroundColor(.green)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Altos")
                            .font(.caption.bold())
                        Text(context.state.distanceText)
                            .font(.caption2)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 3) {
                        Text(context.state.etaText)
                            .font(.caption.bold())
                        Text(context.state.statusText)
                            .font(.caption2)
                            .lineLimit(1)
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Ruta a \(context.state.destinationName)")
                                .font(.caption.bold())
                            Spacer()
                            Text("\(Int(context.state.progress * 100))%")
                                .font(.caption2.bold())
                        }

                        ProgressView(value: context.state.progress)
                            .tint(.green)
                    }
                }
            } compactLeading: {
                Image(systemName: "location.north.fill")
                    .foregroundStyle(.green)
            } compactTrailing: {
                Text(context.state.etaText)
                    .font(.caption2.bold())
                    .foregroundStyle(.green)
            } minimal: {
                Image(systemName: "mountain.2.fill")
                    .foregroundStyle(.green)
            }
        }
    }
}

@available(iOS 16.2, *)
private struct RouteLockScreenView: View {
    let state: RouteActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "mountain.2.fill")
                    .font(.title3)
                    .foregroundStyle(.green)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Camino a \(state.destinationName)")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(state.statusText)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))
                }

                Spacer()
            }

            ProgressView(value: state.progress)
                .tint(.green)

            HStack {
                Label(state.distanceText, systemImage: "road.lanes")
                Spacer()
                Label(state.etaText, systemImage: "clock.fill")
            }
            .font(.caption.bold())
            .foregroundStyle(.white.opacity(0.9))
        }
    }
}
