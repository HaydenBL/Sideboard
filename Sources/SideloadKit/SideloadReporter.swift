import Foundation

/// Call `SideloadReporter.report()` once at launch so the Sideboard dashboard knows when this install expires.
public enum SideloadReporter {
    /// Does nothing for installs without an embedded profile (App Store, TestFlight, Simulator).
    public static func report(bundle: Bundle = .main) {
        guard let bundleID = bundle.bundleIdentifier,
              let record = makeRecord(bundle: bundle, previous: SideloadStore.load(bundleID: bundleID))
        else { return }
        do {
            try SideloadStore.save(record)
        } catch {
            print("SideloadKit: couldn't save record for \(record.bundleID): \(error)")
        }
    }

    static func makeRecord(bundle: Bundle, previous: AppRecord?, now: Date = .now) -> AppRecord? {
        guard let profile = ProvisioningInfo.current(bundle: bundle),
              let bundleID = bundle.bundleIdentifier else { return nil }

        let info = bundle.infoDictionary ?? [:]
        let name = info["CFBundleDisplayName"] as? String ?? info["CFBundleName"] as? String ?? bundleID
        let bundlePath = bundle.bundleURL.path(percentEncoded: false)

        return AppRecord(
            bundleID: bundleID,
            name: name,
            version: info["CFBundleShortVersionString"] as? String ?? "",
            build: info["CFBundleVersion"] as? String ?? "",
            installDate: installDate(bundlePath: bundlePath, previous: previous, now: now),
            bundlePath: bundlePath,
            profileCreated: profile.created,
            expiryDate: profile.expires,
            lastLaunched: now
        )
    }

    /// iOS gives installed bundles a zero creation date, so file dates can't tell us when an install happened.
    /// Instead we rely on every install moving the app to a new `Bundle/Application/<UUID>/` folder:
    /// if the path changed since the last report, this is the first launch of a new install.
    static func installDate(bundlePath: String, previous: AppRecord?, now: Date) -> Date {
        guard let previous, previous.bundlePath == bundlePath else { return now }
        return previous.installDate
    }
}
