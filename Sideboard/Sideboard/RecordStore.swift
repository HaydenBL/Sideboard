//
//  RecordStore.swift
//  Sideboard
//
//  Created by Hayden Lueck on 2026-10-31.
//

import Observation
import SideloadKit

@Observable
final class RecordStore {
    private(set) var records: [AppRecord] = []

    func reload() {
        records = SideloadStore.loadAll()
        Task { await ExpiryNotifications.reschedule(for: records) }
    }

    /// For apps that were deleted from the phone and shouldn't be tracked anymore.
    func remove(_ record: AppRecord) {
        try? SideloadStore.remove(bundleID: record.bundleID)
        reload()
    }
}
