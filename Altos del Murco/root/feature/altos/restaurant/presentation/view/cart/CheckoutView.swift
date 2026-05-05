//
//  CheckoutView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import SwiftUI

private enum RestaurantCheckoutContactField: Hashable {
    case name
    case table
    case whatsapp
}

struct CheckoutView: View {
    @ObservedObject var viewModel: CheckoutViewModel
    @EnvironmentObject private var cartManager: CartManager
    @EnvironmentObject private var sessionViewModel: AppSessionViewModel
    @Binding var path: NavigationPath
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL

    @State private var showMissingWhatsAppConfirmation = false
    @FocusState private var focusedContactField: RestaurantCheckoutContactField?

    private var palette: ThemePalette {
        AppTheme.palette(for: .restaurant, scheme: colorScheme)
    }

    private var authenticatedProfile: ClientProfile? {
        sessionViewModel.authenticatedProfile
    }

    private var effectiveTotal: Double {
        viewModel.effectiveTotal(for: cartManager.subtotal)
    }

    private var rowDiscounts: [UUID: Double] {
        viewModel.allocatedDiscountByCartItemId(for: cartManager.items)
    }

    private var clientNameIsMissing: Bool {
        cartManager.clientName.trimmed.isEmpty
    }

    private var tableIsMissingForImmediateOrder: Bool {
        !cartManager.isScheduledForLater && cartManager.tableNumber.trimmed.isEmpty
    }

    private var whatsappIsMissingForScheduledOrder: Bool {
        cartManager.isScheduledForLater && cartManager.whatsappNumber.digitsOnly.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                clientDetailsSection
                scheduleSection
                summarySection
                rewardsSection
                confirmSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .navigationTitle("Confirmación")
        .appScreenStyle(.restaurant)
        .alert(
            "Mensaje",
            isPresented: Binding(
                get: { viewModel.state.errorMessage != nil },
                set: { isPresented in
                    if !isPresented { viewModel.clearError() }
                }
            ),
            actions: {
                Button("Aceptar") { viewModel.clearError() }
            },
            message: { Text(viewModel.state.errorMessage ?? "") }
        )
        .confirmationDialog(
            "Confirmar por WhatsApp",
            isPresented: $showMissingWhatsAppConfirmation,
            titleVisibility: .visible
        ) {
            Button("Enviar y escribir por WhatsApp") {
                submitOrder(openWhatsAppAfterSubmit: true)
            }

            Button("Agregar WhatsApp aquí") {
                focusContact(.whatsapp)
            }

            Button("Cancelar", role: .cancel) { }
        } message: {
            Text("Puedes enviar la reserva sin número. Al finalizar abriremos WhatsApp para que nos escribas y podamos confirmar la comida programada.")
        }
        .onAppear {
            syncProfileFieldsFromSession()
            cartManager.refreshDefaultScheduleIfNeeded()
            viewModel.onAppear()
        }
        .onChange(of: authenticatedProfile?.id) { _, _ in
            syncProfileFieldsFromSession()
            viewModel.onAppear()
        }
        .onChange(of: authenticatedProfile?.fullName) { _, _ in
            syncProfileFieldsFromSession()
        }
        .onChange(of: authenticatedProfile?.phoneNumber) { _, _ in
            syncProfileFieldsFromSession()
        }
        .onChange(of: cartManager.isScheduledForLater) { _, _ in
            syncProfileFieldsFromSession()
        }
        .onChange(of: viewModel.state.createdOrder) { _, order in
            guard let order else { return }
            path.append(Route.orderSuccess(order))
        }
    }

    private var clientDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            BrandSectionHeader(
                theme: .restaurant,
                title: "Contacto",
                subtitle: cartManager.isScheduledForLater
                    ? "Para reservas de comida, solo el nombre es obligatorio. WhatsApp ayuda a confirmar."
                    : "Para pedidos inmediatos, solo necesitamos nombre y mesa."
            )

            VStack(spacing: 14) {
                themedField(
                    title: "Nombre",
                    text: Binding(
                        get: { cartManager.clientName },
                        set: { cartManager.updateClientName($0) }
                    )
                )
                .textInputAutocapitalization(.words)
                .focused($focusedContactField, equals: .name)

                themedField(
                    title: cartManager.isScheduledForLater ? "Mesa o referencia" : "Número de mesa",
                    text: Binding(
                        get: { cartManager.tableNumber },
                        set: { cartManager.updateTableNumber($0) }
                    )
                )
                .keyboardType(.default)
                .focused($focusedContactField, equals: .table)

                if cartManager.isScheduledForLater {
                    themedField(
                        title: "WhatsApp opcional",
                        text: Binding(
                            get: { cartManager.whatsappNumber },
                            set: { cartManager.updateWhatsappNumber($0) }
                        )
                    )
                    .keyboardType(.phonePad)
                    .focused($focusedContactField, equals: .whatsapp)
                }

                contactHelpCard
            }
        }
        .appCardStyle(.restaurant)
    }

    private var contactHelpCard: some View {
        HStack(alignment: .top, spacing: 12) {
            BrandIconBubble(
                theme: .restaurant,
                systemImage: contactHelpIcon,
                size: 38
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(contactHelpTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.textPrimary)

                Text(contactHelpMessage)
                    .font(.caption)
                    .foregroundStyle(palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .appCardStyle(.restaurant, emphasized: false)
    }

    private var contactHelpIcon: String {
        if clientNameIsMissing { return "exclamationmark.circle.fill" }
        if tableIsMissingForImmediateOrder { return "tablecells.badge.ellipsis" }
        if whatsappIsMissingForScheduledOrder { return "message.circle.fill" }
        return cartManager.isScheduledForLater ? "calendar.badge.clock" : "checkmark.circle.fill"
    }

    private var contactHelpTitle: String {
        if clientNameIsMissing { return "Falta el nombre" }
        if tableIsMissingForImmediateOrder { return "Falta la mesa" }
        if whatsappIsMissingForScheduledOrder { return "WhatsApp opcional" }
        return cartManager.isScheduledForLater ? "Reserva lista para enviar" : "Pedido listo para enviar"
    }

    private var contactHelpMessage: String {
        if clientNameIsMissing {
            return "Necesitamos un nombre para identificar el pedido."
        }

        if tableIsMissingForImmediateOrder {
            return "En pedidos inmediatos necesitamos la mesa para llevar la comida correctamente."
        }

        if whatsappIsMissingForScheduledOrder {
            return "Puedes dejarlo vacío y escribirnos por WhatsApp después de enviar la reserva."
        }

        return cartManager.isScheduledForLater
            ? "Usaremos estos datos para confirmar la comida programada."
            : "El pedido se enviará como inmediato y no guardará WhatsApp."
    }

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            BrandSectionHeader(
                theme: .restaurant,
                title: "¿Cuándo quieres tu comida?",
                subtitle: "Elige si el restaurante debe prepararla ahora o reservarla para más tarde."
            )

            VStack(spacing: 10) {
                scheduleModeOption(
                    mode: .asSoonAsPossible,
                    isSelected: !cartManager.isScheduledForLater
                ) {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                        viewModel.onEvent(.scheduleNowTapped)
                    }
                }

                scheduleModeOption(
                    mode: .scheduled,
                    isSelected: cartManager.isScheduledForLater
                ) {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                        activateScheduledMode()
                    }
                }
            }

            if cartManager.isScheduledForLater {
                scheduledOrderControls
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                immediateOrderInfoCard
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .appCardStyle(.restaurant)
    }

    private func scheduleModeOption(
        mode: RestaurantOrderFulfillmentMode,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? palette.primary.opacity(0.16) : palette.elevatedCard)
                        .frame(width: 46, height: 46)

                    Image(systemName: mode.icon)
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(isSelected ? palette.primary : palette.textSecondary)
                }

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text(mode.title)
                            .font(.headline)
                            .foregroundStyle(palette.textPrimary)

                        if isSelected {
                            Label("Seleccionado", systemImage: "checkmark.circle.fill")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(palette.primary)
                        }
                    }

                    Text(mode.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? palette.primary : palette.textTertiary)
                    .padding(.top, 2)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                    .fill(isSelected ? palette.primary.opacity(colorScheme == .dark ? 0.20 : 0.10) : palette.elevatedCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                    .stroke(isSelected ? palette.primary : palette.stroke, lineWidth: isSelected ? 1.6 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var immediateOrderInfoCard: some View {
        HStack(alignment: .top, spacing: 12) {
            BrandIconBubble(
                theme: .restaurant,
                systemImage: "bolt.fill",
                size: 42
            )

            VStack(alignment: .leading, spacing: 5) {
                Text("Se preparará lo antes posible")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.textPrimary)

                Text("Este pedido se enviará como inmediato. La mesa es obligatoria para que podamos llevar la comida correctamente. WhatsApp no se guardará en pedidos inmediatos.")
                    .font(.caption)
                    .foregroundStyle(palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Hora estimada: \(OrderScheduleResolver.displayText(for: cartManager.scheduledAt))")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.primary)
            }

            Spacer()
        }
        .appCardStyle(.restaurant, emphasized: false)
    }

    private var scheduledOrderControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                BrandIconBubble(
                    theme: .restaurant,
                    systemImage: "calendar.badge.clock",
                    size: 42
                )

                VStack(alignment: .leading, spacing: 5) {
                    Text("Comida programada")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.textPrimary)

                    Text("Prepararemos o confirmaremos tu comida para la fecha elegida. La mesa puede quedar por asignar y WhatsApp nos ayuda a confirmar disponibilidad.")
                        .font(.caption)
                        .foregroundStyle(palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(OrderScheduleResolver.displayText(for: cartManager.scheduledAt))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(palette.primary)
                }

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                        viewModel.onEvent(.scheduleNowTapped)
                    }
                } label: {
                    Label("Ahora", systemImage: "bolt.fill")
                        .font(.caption.weight(.bold))
                }
                .buttonStyle(.bordered)
            }

            Divider().overlay(palette.stroke)

            DatePicker(
                "Día y hora de llegada",
                selection: Binding(
                    get: { cartManager.scheduledAt },
                    set: {
                        viewModel.onEvent(
                            .scheduledAtChanged(
                                RestaurantOrderSchedulingRules.normalizedScheduledAt($0)
                            )
                        )
                    }
                ),
                in: RestaurantOrderSchedulingRules.minimumScheduledAt()...RestaurantOrderSchedulingRules.maximumScheduledAt(),
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.compact)

            if let scheduleValidationMessage {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(palette.destructive)

                    Text(scheduleValidationMessage)
                        .font(.caption)
                        .foregroundStyle(palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(palette.success)

                    Text("Esta reserva se guardará con scheduledAt en restaurant_orders para que ADM la vea como comida programada.")
                        .font(.caption)
                        .foregroundStyle(palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .appCardStyle(.restaurant, emphasized: false)
    }

    private var scheduleValidationMessage: String? {
        RestaurantOrderSchedulingRules.validate(
            mode: cartManager.isScheduledForLater ? .scheduled : .asSoonAsPossible,
            scheduledAt: cartManager.scheduledAt
        )
    }

    private func activateScheduledMode() {
        let minimum = RestaurantOrderSchedulingRules.minimumScheduledAt()
        let nextDate = cartManager.scheduledAt >= minimum
            ? cartManager.scheduledAt
            : RestaurantOrderSchedulingRules.defaultScheduledAt()

        viewModel.onEvent(
            .scheduledAtChanged(
                RestaurantOrderSchedulingRules.normalizedScheduledAt(nextDate)
            )
        )
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            BrandSectionHeader(
                theme: .restaurant,
                title: "Resumen",
                subtitle: "Revisa tu pedido antes de confirmarlo."
            )

            VStack(spacing: 12) {
                ForEach(cartManager.items) { cartItem in
                    let lineDiscount = rowDiscounts[cartItem.id, default: 0]
                    let discountedLine = max(0, cartItem.totalPrice - lineDiscount)

                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(cartItem.quantity)x \(cartItem.menuItem.name)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(palette.textPrimary)

                            if let reward = viewModel.appliedRewardPresentation(forMenuItemId: cartItem.menuItem.id) {
                                Text(reward.message)
                                    .font(.caption)
                                    .foregroundStyle(palette.success)
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            if lineDiscount > 0 {
                                Text(cartItem.totalPrice.priceText)
                                    .font(.caption)
                                    .foregroundStyle(palette.textSecondary)
                                    .strikethrough()

                                Text(discountedLine.priceText)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(palette.success)
                            } else {
                                Text(cartItem.totalPrice.priceText)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(palette.textPrimary)
                            }
                        }
                    }

                    if cartItem.id != cartManager.items.last?.id {
                        Divider().overlay(palette.stroke)
                    }
                }
            }

            Divider().overlay(palette.stroke)
            detailLine(title: "Subtotal", value: cartManager.subtotal.priceText)

            if viewModel.state.isLoadingRewards {
                detailLine(title: "Murco Loyalty", value: "Calculando...", secondary: true)
            } else if viewModel.state.rewardPreview.discountAmount > 0 {
                detailLine(title: "Murco Loyalty", value: "-\(viewModel.state.rewardPreview.discountAmount.priceText)", accent: true)
            }

            detailLine(
                title: cartManager.isScheduledForLater ? "Reserva" : "Hora",
                value: OrderScheduleResolver.displayText(for: cartManager.scheduledAt),
                secondary: true
            )

            if cartManager.isScheduledForLater {
                detailLine(
                    title: "WhatsApp",
                    value: cartManager.whatsappNumber.digitsOnly.isEmpty ? "Lo escribirá después" : cartManager.whatsappNumber,
                    secondary: true
                )
            }

            Divider().overlay(palette.stroke)
            detailLine(title: "Total", value: effectiveTotal.priceText, emphasized: true)
        }
        .appCardStyle(.restaurant)
    }

    private var rewardsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            BrandSectionHeader(
                theme: .restaurant,
                title: "Premios aplicados",
                subtitle: viewModel.state.rewardPreview.appliedRewards.isEmpty
                    ? "No hay premios activos para este pedido."
                    : "Estos descuentos ya se reflejan en el total."
            )

            if viewModel.state.isLoadingRewards {
                ProgressView("Calculando premios...")
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if viewModel.state.rewardPreview.appliedRewards.isEmpty {
                Text("No se aplicó ningún cupón o premio automático a este pedido.")
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.state.rewardPreview.appliedRewards) { reward in
                        HStack(alignment: .top, spacing: 10) {
                            BrandBadge(theme: .restaurant, title: "Aplicado", selected: true)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(reward.title)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(palette.textPrimary)

                                Text(reward.note)
                                    .font(.caption)
                                    .foregroundStyle(palette.textSecondary)
                            }

                            Spacer()

                            Text("-\(reward.amount.priceText)")
                                .font(.subheadline.bold())
                                .foregroundStyle(palette.success)
                        }
                    }
                }
            }
        }
        .appCardStyle(.restaurant)
    }

    private var confirmSection: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(cartManager.isScheduledForLater ? "Total de la reserva" : "Total a pagar")
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)

                    Text(effectiveTotal.priceText)
                        .font(.title2.bold())
                        .foregroundStyle(palette.textPrimary)
                }

                Spacer()
            }

            Button {
                handleConfirmTapped()
            } label: {
                if viewModel.state.isSubmitting {
                    ProgressView().frame(maxWidth: .infinity)
                } else {
                    Text(cartManager.isScheduledForLater ? "Confirmar reserva de comida" : "Confirmar pedido")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(BrandPrimaryButtonStyle(theme: .restaurant))
            .disabled(cartManager.isEmpty || viewModel.state.isSubmitting)
        }
        .appCardStyle(.restaurant, emphasized: false)
    }

    private func handleConfirmTapped() {
        syncProfileFieldsFromSession()

        if clientNameIsMissing {
            focusContact(.name)
            viewModel.presentError("Ingresa tu nombre para enviar el pedido.")
            return
        }

        if tableIsMissingForImmediateOrder {
            focusContact(.table)
            viewModel.presentError("Ingresa el número de mesa para pedidos inmediatos.")
            return
        }

        if whatsappIsMissingForScheduledOrder {
            focusContact(.whatsapp)
            showMissingWhatsAppConfirmation = true
            return
        }

        submitOrder(openWhatsAppAfterSubmit: false)
    }

    private func submitOrder(openWhatsAppAfterSubmit: Bool) {
        Task { @MainActor in
            let didSubmit = await viewModel.submitOrder()
            guard didSubmit else { return }

            if openWhatsAppAfterSubmit {
                openAltosWhatsAppForRestaurantOrder()
            }
        }
    }

    private func focusContact(_ field: RestaurantCheckoutContactField) {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000)
            focusedContactField = field
        }
    }

    private func syncProfileFieldsFromSession() {
        guard let profile = authenticatedProfile else { return }

        if cartManager.clientName.trimmed.isEmpty && !profile.fullName.trimmed.isEmpty {
            cartManager.clientName = profile.fullName
        }

        if cartManager.isScheduledForLater,
           cartManager.whatsappNumber.digitsOnly.isEmpty,
           !profile.phoneNumber.digitsOnly.isEmpty {
            cartManager.whatsappNumber = profile.phoneNumber
        }
    }

    private func openAltosWhatsAppForRestaurantOrder() {
        let message = """
        Hola Altos del Murco, acabo de enviar una reserva de comida desde la app y quiero confirmar disponibilidad lo antes posible.
        """

        guard let encodedMessage = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://wa.me/593967188093?text=\(encodedMessage)") else {
            return
        }

        openURL(url)
    }

    private func themedField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(palette.textSecondary)

            TextField(title, text: text)
                .textFieldStyle(.roundedBorder)
        }
    }

    private func detailLine(
        title: String,
        value: String,
        emphasized: Bool = false,
        secondary: Bool = false,
        accent: Bool = false
    ) -> some View {
        HStack {
            Text(title)
                .font(emphasized ? .headline : .subheadline)
                .foregroundStyle(accent ? palette.success : (secondary ? palette.textSecondary : palette.textPrimary))

            Spacer()

            Text(value)
                .font(emphasized ? .headline.bold() : .subheadline.weight(.semibold))
                .foregroundStyle(accent ? palette.success : (secondary ? palette.textSecondary : palette.textPrimary))
                .multilineTextAlignment(.trailing)
        }
    }
}
