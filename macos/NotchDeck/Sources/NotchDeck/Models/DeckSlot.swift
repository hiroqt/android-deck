import Foundation

public struct DeckSlot: Codable, Identifiable, Equatable {
    public var id: UUID
    public var index: Int
    public var title: String
    public var actionType: ActionType
    public var target: String
    public var iconName: String?
    public var customColorHex: String?

    public init(
        id: UUID = UUID(),
        index: Int,
        title: String,
        actionType: ActionType,
        target: String,
        iconName: String? = nil,
        customColorHex: String? = nil
    ) {
        self.id = id
        self.index = index
        self.title = title
        self.actionType = actionType
        self.target = target
        self.iconName = iconName
        self.customColorHex = customColorHex
    }
}
