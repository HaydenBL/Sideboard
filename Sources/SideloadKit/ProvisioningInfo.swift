import Foundation

/// The signing details from an app's `embedded.mobileprovision`.
public struct ProvisioningInfo: Sendable, Equatable {
    public let name: String
    public let teamID: String?
    public let created: Date
    public let expires: Date

    /// Reads the profile bundled with the running app. Returns nil for App Store and TestFlight installs, which have none.
    public static func current(bundle: Bundle = .main) -> ProvisioningInfo? {
        guard let url = bundle.url(forResource: "embedded", withExtension: "mobileprovision"),
              let data = try? Data(contentsOf: url) else { return nil }
        return parse(data)
    }

    /// The file is a signed CMS envelope with the plist stored as plain XML inside, so we cut the plist out directly.
    public static func parse(_ data: Data) -> ProvisioningInfo? {
        guard let start = data.range(of: Data("<?xml".utf8)),
              let end = data.range(of: Data("</plist>".utf8), in: start.lowerBound..<data.endIndex),
              let plist = try? PropertyListSerialization.propertyList(
                  from: data[start.lowerBound..<end.upperBound], format: nil
              ) as? [String: Any],
              let created = plist["CreationDate"] as? Date,
              let expires = plist["ExpirationDate"] as? Date
        else { return nil }

        return ProvisioningInfo(
            name: plist["Name"] as? String ?? "",
            teamID: (plist["TeamIdentifier"] as? [String])?.first,
            created: created,
            expires: expires
        )
    }
}
