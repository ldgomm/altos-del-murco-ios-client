//
//  LoyaltyRewardTemplateDto.swift
//  Altos del Murco
//
//  Created by José Ruiz on 21/4/26.
//

import FirebaseFirestore
import Foundation

struct LoyaltyRewardTemplateDto: Codable {
    let id: String
    let title: String
    let subtitle: String
    let scope: String
    let minimumLevel: String
    let triggerMode: String
    let isActive: Bool
    let canStack: Bool
    let priority: Int
    let maxUsesPerClient: Int
    let expiresInDays: Int?
    let rule: LoyaltyRewardRule
    let createdAt: Timestamp
    let updatedAt: Timestamp

    init(domain: LoyaltyRewardTemplate) {
        self.id = domain.id
        self.title = domain.title
        self.subtitle = domain.subtitle
        self.scope = domain.scope.rawValue
        self.minimumLevel = domain.minimumLevel.rawValue
        self.triggerMode = domain.triggerMode.rawValue
        self.isActive = domain.isActive
        self.canStack = domain.canStack
        self.priority = domain.priority
        self.maxUsesPerClient = max(1, domain.maxUsesPerClient)
        self.expiresInDays = domain.expiresInDays
        self.rule = domain.rule
        self.createdAt = Timestamp(date: domain.createdAt)
        self.updatedAt = Timestamp(date: domain.updatedAt)
    }

    func toDomain() -> LoyaltyRewardTemplate {
        LoyaltyRewardTemplate(
            id: id,
            title: title,
            subtitle: subtitle,
            scope: LoyaltyRewardScope(rawValue: scope) ?? .both,
            minimumLevel: LoyaltyLevel(rawValue: minimumLevel) ?? .bronze,
            triggerMode: LoyaltyRewardTriggerMode(rawValue: triggerMode) ?? .automatic,
            isActive: isActive,
            canStack: canStack,
            priority: priority,
            maxUsesPerClient: max(1, maxUsesPerClient),
            expiresInDays: expiresInDays,
            rule: rule,
            createdAt: createdAt.dateValue(),
            updatedAt: updatedAt.dateValue()
        )
    }
}

struct LoyaltyWalletEventDto: Codable {
    let id: String
    let templateId: String
    let templateTitle: String
    let referenceType: String
    let referenceId: String
    let status: String
    let amount: Double
    let createdAt: Timestamp
    let updatedAt: Timestamp

    init(domain: LoyaltyWalletEvent) {
        self.id = domain.id
        self.templateId = domain.templateId
        self.templateTitle = domain.templateTitle
        self.referenceType = domain.referenceType.rawValue
        self.referenceId = domain.referenceId
        self.status = domain.status.rawValue
        self.amount = domain.amount
        self.createdAt = Timestamp(date: domain.createdAt)
        self.updatedAt = Timestamp(date: domain.updatedAt)
    }

    func toDomain() -> LoyaltyWalletEvent {
        LoyaltyWalletEvent(
            id: id,
            templateId: templateId,
            templateTitle: templateTitle,
            referenceType: LoyaltyRewardReferenceType(rawValue: referenceType) ?? .order,
            referenceId: referenceId,
            status: LoyaltyWalletEventStatus(rawValue: status) ?? .reserved,
            amount: amount,
            createdAt: createdAt.dateValue(),
            updatedAt: updatedAt.dateValue()
        )
    }
}

struct LoyaltyWalletDocument: Codable {
    /// Firebase Auth UID. This must match the document ID in client_loyalty_wallets/{uid}.
    let userId: String

    let updatedAt: Date
    let events: [LoyaltyWalletEvent]

    init(
        userId: String,
        updatedAt: Date,
        events: [LoyaltyWalletEvent]
    ) {
        self.userId = userId.trimmingCharacters(in: .whitespacesAndNewlines)
        self.updatedAt = updatedAt
        self.events = events
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedUserId = try container.decodeIfPresent(String.self, forKey: .userId)

        userId = (decodedUserId ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let updatedAtTimestamp = try container.decode(Timestamp.self, forKey: .updatedAt)
        let eventDtos = try container.decodeIfPresent([LoyaltyWalletEventDto].self, forKey: .events) ?? []
        updatedAt = updatedAtTimestamp.dateValue()
        events = eventDtos.map { $0.toDomain() }
    }

    enum CodingKeys: String, CodingKey {
        case userId
        case updatedAt
        case events
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userId, forKey: .userId)
        try container.encode(Timestamp(date: updatedAt), forKey: .updatedAt)
        try container.encode(events.map(LoyaltyWalletEventDto.init(domain:)), forKey: .events)
    }
}
