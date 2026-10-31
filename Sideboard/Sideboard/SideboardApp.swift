//
//  SideboardApp.swift
//  Sideboard
//
//  Created by Hayden Lueck on 2026-10-31.
//

import SideloadKit
import SwiftUI
import UserNotifications

@main
struct SideboardApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var store = RecordStore()

    init() {
        // Sideboard is sideloaded too, so it tracks its own expiry.
        SideloadReporter.report()
        UNUserNotificationCenter.current().delegate = NotificationPresenter.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
                .task { await ExpiryNotifications.requestAuthorization() }
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
            // Other apps may have reported since we last looked, so reload and reschedule on every open.
            if phase == .active {
                store.reload()
            }
        }
    }
}
