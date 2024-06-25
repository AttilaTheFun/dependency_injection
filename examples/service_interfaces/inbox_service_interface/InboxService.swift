
public struct InboxItem: Hashable, Identifiable {
    public let id: String
    public let title: String
    public let subtitle: String

    public init(id: String, title: String, subtitle: String) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
    }
}

public protocol InboxService {
    func getInboxItems() async -> [InboxItem]
}
