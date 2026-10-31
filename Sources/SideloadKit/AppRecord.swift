import Foundation

/// What each app writes about its own install for the Sideboard dashboard.
public struct AppRecord: Codable, Sendable, Identifiable, Equatable {
    public var bundleID: String
    public var name: String
    public var version: String
    public var build: String
    /// When this install was first launched. See `SideloadReporter.installDate`.
    public var installDate: Date
    /// Where the app bundle lives. It changes on every install, which is how we spot a new one.
    public var bundlePath: String?
    public var profileCreated: Date
    public var expiryDate: Date
    public var lastLaunched: Date

    public var id: String { bundleID }

    public func daysLeft(from now: Date = .now, calendar: Calendar = .current) -> Int {
        calendar.dateComponents(
            [.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: expiryDate)
        ).day ?? 0
    }

    public func isExpired(at now: Date = .now) -> Bool { expiryDate <= now }
}
