import Foundation

/// Reads and writes app records in the shared App Group container, one JSON file per app.
public enum SideloadStore {
    public static let appGroupID = "group.se.haydenblai.sideload"

    static var directory: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appending(path: "Apps", directoryHint: .isDirectory)
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    public static func save(_ record: AppRecord) throws {
        guard let directory else { throw CocoaError(.fileNoSuchFile) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appending(path: "\(record.bundleID).json")
        try encoder.encode(record).write(to: url, options: .atomic)
    }

    public static func load(bundleID: String) -> AppRecord? {
        guard let url = directory?.appending(path: "\(bundleID).json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode(AppRecord.self, from: data)
    }

    /// All recorded apps, soonest expiry first.
    public static func loadAll() -> [AppRecord] {
        guard let directory,
              let urls = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        else { return [] }

        return urls
            .filter { $0.pathExtension == "json" }
            .compactMap { try? decoder.decode(AppRecord.self, from: Data(contentsOf: $0)) }
            .sorted { $0.expiryDate < $1.expiryDate }
    }

    public static func remove(bundleID: String) throws {
        guard let directory else { return }
        try FileManager.default.removeItem(at: directory.appending(path: "\(bundleID).json"))
    }
}
