//
//  ExpiryNotifications.swift
//  Sideboard
//
//  Created by Hayden Lueck on 2026-10-31.
//

import Foundation
import SideloadKit
import UserNotifications

enum ExpiryNotifications {
    /// How many days before expiry to send a reminder.
    static let daysBefore = [14, 7, 1]
    static let hour = 9

    static func requestAuthorization() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    }

    /// Replaces every pending reminder, so ones for apps that have since been rebuilt go away.
    static func reschedule(for records: [AppRecord]) async {
        let center = UNUserNotificationCenter.current()
        let stale = await center.pendingNotificationRequests().map(\.identifier).filter { $0 != testID }
        center.removePendingNotificationRequests(withIdentifiers: stale)

        let calendar = Calendar.current
        for record in records {
            for days in daysBefore {
                guard let day = calendar.date(byAdding: .day, value: -days, to: calendar.startOfDay(for: record.expiryDate)),
                      let fireDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day),
                      fireDate > .now
                else { continue }

                let content = UNMutableNotificationContent()
                content.title = "Rebuild \(record.name)"
                content.body = days == 1
                    ? "\(record.name) expires tomorrow. Install it from Xcode again to keep it working."
                    : "\(record.name) expires in \(days) days. Install it from Xcode again to keep it working."
                content.sound = .default

                let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
                let request = UNNotificationRequest(
                    identifier: "\(record.bundleID).\(days)",
                    content: content,
                    trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                )
                try? await center.add(request)
            }
        }
    }

    private static let testID = "test"

    #if DEBUG
    static func sendTest(for record: AppRecord?) async {
        let content = UNMutableNotificationContent()
        content.title = "Rebuild \(record?.name ?? "Test")"
        content.body = "This is what an expiry reminder looks like."
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: testID,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        )
        try? await UNUserNotificationCenter.current().add(request)
    }
    #endif
}

/// iOS hides an app's notifications while it's in the foreground unless its delegate asks to show them.
final class NotificationPresenter: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationPresenter()

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}
