//
//  AdventureReservationView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import SwiftUI

struct AdventureReservationView: View {
    @StateObject private var viewModel: AdventureReservationViewModel
    
    init(viewModel: AdventureReservationViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        Form {
            reservationSection
            clientSection
            availabilitySection
            summarySection
            actionSection
        }
        .navigationTitle("Reserve")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.onEvent(.onAppear)
        }
        .alert(
            "Message",
            isPresented: Binding(
                get: { viewModel.state.errorMessage != nil || viewModel.state.successMessage != nil },
                set: { if !$0 { viewModel.onEvent(.dismissMessage) } }
            )
        ) {
            Button("OK") {
                viewModel.onEvent(.dismissMessage)
            }
        } message: {
            Text(viewModel.state.errorMessage ?? viewModel.state.successMessage ?? "")
        }
    }
    
    private var reservationSection: some View {
        Section("Reservation") {
            DatePicker(
                "Date",
                selection: Binding(
                    get: { viewModel.state.selectedDate },
                    set: { viewModel.onEvent(.selectedDateChanged($0)) }
                ),
                in: Date()...,
                displayedComponents: .date
            )
            
            Picker(
                "Package",
                selection: Binding(
                    get: { viewModel.state.selectedPackage },
                    set: { viewModel.onEvent(.selectedPackageChanged($0)) }
                )
            ) {
                ForEach(AdventurePackageType.allCases) { package in
                    VStack(alignment: .leading) {
                        Text(package.title).tag(package)
                    }
                    .tag(package)
                }
            }
            
            if viewModel.state.selectedPackage.includesOffRoad {
                Picker(
                    "Off-Road Duration",
                    selection: Binding(
                        get: { viewModel.state.offRoadHours },
                        set: { viewModel.onEvent(.offRoadHoursChanged($0)) }
                    )
                ) {
                    Text("1 hour").tag(1)
                    Text("2 hours").tag(2)
                    Text("3 hours").tag(3)
                }
                .pickerStyle(.segmented)
            }
            
            Stepper(
                "People: \(viewModel.state.peopleCount)",
                value: Binding(
                    get: { viewModel.state.peopleCount },
                    set: { viewModel.onEvent(.peopleCountChanged($0)) }
                ),
                in: 1...20
            )
        }
    }
    
    private var clientSection: some View {
        Section("Client") {
            TextField(
                "Client name",
                text: Binding(
                    get: { viewModel.state.clientName },
                    set: { viewModel.onEvent(.clientNameChanged($0)) }
                )
            )
            
            TextField(
                "Notes (optional)",
                text: Binding(
                    get: { viewModel.state.notes },
                    set: { viewModel.onEvent(.notesChanged($0)) }
                ),
                axis: .vertical
            )
            .lineLimit(3...5)
        }
    }
    
    private var availabilitySection: some View {
        Section("Available Times") {
            if viewModel.state.isLoadingAvailability {
                ProgressView("Checking availability...")
            } else if viewModel.state.availableSlots.isEmpty {
                ContentUnavailableView(
                    "No time slots",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text("Try another day, package, duration, or people count.")
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.state.availableSlots) { slot in
                            Button {
                                viewModel.onEvent(.slotSelected(slot))
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(AdventureDateHelper.timeText(for: slot.startAt))
                                        .font(.headline)
                                    Text("to \(AdventureDateHelper.timeText(for: slot.endAt))")
                                        .font(.subheadline)
                                    Text("$\(slot.totalAmount, specifier: "%.2f")")
                                        .font(.caption)
                                }
                                .padding()
                                .frame(width: 150, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            viewModel.state.selectedSlot?.id == slot.id
                                            ? Color.primary.opacity(0.15)
                                            : Color(.systemGray6)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
    
    private var summarySection: some View {
        Section("Summary") {
            LabeledContent("Package", value: viewModel.state.selectedPackage.title)
            LabeledContent("People", value: "\(viewModel.state.peopleCount)")
            
            if viewModel.state.selectedPackage.includesOffRoad {
                LabeledContent("Off-Road", value: "\(viewModel.state.offRoadHours) hour(s)")
            }
            
            if let slot = viewModel.state.selectedSlot {
                LabeledContent("Start", value: AdventureDateHelper.timeText(for: slot.startAt))
                LabeledContent("End", value: AdventureDateHelper.timeText(for: slot.endAt))
                LabeledContent("Total", value: "$\(slot.totalAmount, default: "%.2f")")
            }
        }
    }
    
    private var actionSection: some View {
        Section {
            Button {
                viewModel.onEvent(.submit(clientId: nil))
            } label: {
                if viewModel.state.isSubmitting {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Confirm Reservation")
                        .frame(maxWidth: .infinity)
                }
            }
            .disabled(viewModel.state.isSubmitting || viewModel.state.selectedSlot == nil)
        }
    }
}
