import Foundation
import Testing
@testable import SideloadKit

struct ProvisioningInfoTests {
    @Test func parsesPlistInsideEnvelope() throws {
        let plist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0"><dict>
            <key>Name</key><string>iOS Team Provisioning Profile: *</string>
            <key>TeamIdentifier</key><array><string>ABCDE12345</string></array>
            <key>CreationDate</key><date>2026-07-20T13:03:37Z</date>
            <key>ExpirationDate</key><date>2027-07-20T13:03:37Z</date>
        </dict></plist>
        """
        // Surround the plist with junk bytes, as the CMS signature does.
        let data = Data([0x30, 0x80, 0x06, 0x09]) + Data(plist.utf8) + Data([0xA0, 0x82, 0x00, 0x00])

        let info = try #require(ProvisioningInfo.parse(data))
        #expect(info.name == "iOS Team Provisioning Profile: *")
        #expect(info.teamID == "ABCDE12345")
        #expect(info.created == ISO8601DateFormatter().date(from: "2026-07-20T13:03:37Z"))
        #expect(info.expires == ISO8601DateFormatter().date(from: "2027-07-20T13:03:37Z"))
    }

    @Test func rejectsDataWithoutPlist() {
        #expect(ProvisioningInfo.parse(Data("not a profile".utf8)) == nil)
    }

    /// Runs against the real profiles Xcode has downloaded, when there are any.
    @Test func parsesInstalledProfiles() throws {
        let directory = FileManager.default.homeDirectoryForCurrentUser
            .appending(path: "Library/Developer/Xcode/UserData/Provisioning Profiles")
        let urls = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []

        for url in urls where url.pathExtension == "mobileprovision" {
            let info = try #require(ProvisioningInfo.parse(Data(contentsOf: url)), "\(url.lastPathComponent)")
            #expect(info.expires > info.created)
        }
    }

    @Test func daysLeftCountsCalendarDays() {
        let calendar = Calendar(identifier: .gregorian)
        let now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 31, hour: 23))!
        let expiry = calendar.date(from: DateComponents(year: 2026, month: 11, day: 7, hour: 1))!
        let record = AppRecord(
            bundleID: "x", name: "X", version: "1", build: "1",
            installDate: now, bundlePath: nil, profileCreated: now, expiryDate: expiry, lastLaunched: now
        )
        #expect(record.daysLeft(from: now, calendar: calendar) == 7)
    }

    @Test func keepsInstallDateUntilBundleMoves() {
        let installed = Date(timeIntervalSince1970: 1_800_000_000)
        let now = installed.addingTimeInterval(86_400)
        let previous = AppRecord(
            bundleID: "x", name: "X", version: "1", build: "1",
            installDate: installed, bundlePath: "/Bundle/Application/A/X.app", profileCreated: installed,
            expiryDate: installed, lastLaunched: installed
        )

        #expect(SideloadReporter.installDate(bundlePath: "/Bundle/Application/A/X.app", previous: previous, now: now) == installed)
        #expect(SideloadReporter.installDate(bundlePath: "/Bundle/Application/B/X.app", previous: previous, now: now) == now)
        #expect(SideloadReporter.installDate(bundlePath: "/Bundle/Application/A/X.app", previous: nil, now: now) == now)
    }
}
