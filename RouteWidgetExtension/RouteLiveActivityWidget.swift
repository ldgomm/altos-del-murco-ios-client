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
                .activityBackgroundTint(RouteWidgetPalette.background)
                .activitySystemActionForegroundColor(RouteWidgetPalette.green)
                .widgetURL(RouteDeepLink.directionsURL)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    RouteIslandBrandBlock(state: context.state)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    RouteIslandTimeBlock(state: context.state)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    RouteIslandExpandedBottom(state: context.state)
                }
            } compactLeading: {
                HStack(spacing: 3) {
                    Image(systemName: "location.north.fill")
                        .font(.caption2.bold())

                    Text(context.state.distanceText)
                        .font(.caption2.bold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .foregroundStyle(RouteWidgetPalette.green)
            } compactTrailing: {
                Text(context.state.etaText)
                    .font(.caption2.bold())
                    .monospacedDigit()
                    .foregroundStyle(RouteWidgetPalette.green)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            } minimal: {
                Image(systemName: "mountain.2.fill")
                    .foregroundStyle(RouteWidgetPalette.green)
            }
            .widgetURL(RouteDeepLink.directionsURL)
            .keylineTint(RouteWidgetPalette.green)
        }
    }
}

@available(iOS 16.2, *)
private struct RouteLockScreenView: View {
    let state: RouteActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(RouteWidgetPalette.green.opacity(0.18))
                        .frame(width: 44, height: 44)

                    Image(systemName: "mountain.2.fill")
                        .font(.headline.bold())
                        .foregroundStyle(RouteWidgetPalette.green)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Camino a \(state.destinationName)")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(state.statusText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(state.etaText)
                        .font(.title3.bold())
                        .monospacedDigit()
                        .foregroundStyle(RouteWidgetPalette.green)

                    Text("Llegas \(state.arrivalText)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.65))
                        .lineLimit(1)
                }
            }

            Text(state.instructionText)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.92))
                .lineLimit(2)

            VStack(alignment: .leading, spacing: 8) {
                ProgressView(value: state.progress)
                    .tint(RouteWidgetPalette.green)

                HStack(spacing: 10) {
                    RouteMetricPill(
                        title: "Faltan",
                        value: state.distanceText,
                        systemImage: "road.lanes"
                    )

                    RouteMetricPill(
                        title: "Tiempo",
                        value: state.etaText,
                        systemImage: "clock.fill"
                    )

                    RouteMetricPill(
                        title: "Avance",
                        value: "\(Int(state.progress * 100))%",
                        systemImage: "gauge.with.dots.needle.67percent"
                    )
                }
            }
        }
    }
}

@available(iOS 16.2, *)
private struct RouteIslandBrandBlock: View {
    let state: RouteActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: "mountain.2.fill")
                    .font(.caption.bold())
                    .foregroundStyle(RouteWidgetPalette.green)

                Text("Altos")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }

            Text(state.distanceText)
                .font(.title3.bold())
                .monospacedDigit()
                .foregroundStyle(.white)

            Text("faltan")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.62))
        }
    }
}

@available(iOS 16.2, *)
private struct RouteIslandTimeBlock: View {
    let state: RouteActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(state.etaText)
                .font(.title3.bold())
                .monospacedDigit()
                .foregroundStyle(RouteWidgetPalette.green)

            Text("Llegas")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.62))

            Text(state.arrivalText)
                .font(.caption.bold())
                .monospacedDigit()
                .foregroundStyle(.white)
                .lineLimit(1)
        }
    }
}

@available(iOS 16.2, *)
private struct RouteIslandExpandedBottom: View {
    let state: RouteActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "location.north.line.fill")
                    .font(.caption.bold())
                    .foregroundStyle(RouteWidgetPalette.green)
                    .frame(width: 18)

                Text(state.instructionText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.92))
                    .lineLimit(2)

                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Ruta a \(state.destinationName)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.65))
                        .lineLimit(1)

                    Spacer()

                    Text("\(Int(state.progress * 100))%")
                        .font(.caption2.bold())
                        .monospacedDigit()
                        .foregroundStyle(RouteWidgetPalette.green)
                }

                ProgressView(value: state.progress)
                    .tint(RouteWidgetPalette.green)
            }

            HStack(spacing: 8) {
                CompactRoutePill(
                    value: state.distanceText,
                    systemImage: "road.lanes"
                )

                CompactRoutePill(
                    value: state.etaText,
                    systemImage: "clock.fill"
                )

                CompactRoutePill(
                    value: state.statusText,
                    systemImage: "point.topleft.down.curvedto.point.bottomright.up"
                )
            }
        }
        .padding(.top, 2)
    }
}

private struct RouteMetricPill: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: systemImage)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.55))
                .lineLimit(1)

            Text(value)
                .font(.caption.bold())
                .monospacedDigit()
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.white.opacity(0.08))
        )
    }
}

private struct CompactRoutePill: View {
    let value: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.caption2.bold())

            Text(value)
                .font(.caption2.bold())
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(.white.opacity(0.86))
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(.white.opacity(0.08))
        )
    }
}

private enum RouteWidgetPalette {
    static let background = Color.black.opacity(0.88)
    static let green = Color(red: 0.22, green: 0.78, blue: 0.42)
}
