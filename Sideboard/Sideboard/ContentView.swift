//
//  ContentView.swift
//  Sideboard
//
//  Created by Hayden Lueck on 2026-10-31.
//

import SideloadKit
import SwiftUI

struct ContentView: View {
    let store: RecordStore

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.records) { record in
                    AppRow(record: record)
                        .swipeActions {
                            Button("Remove", systemImage: "trash", role: .destructive) {
                                store.remove(record)
                            }
                        }
                }
            }
            .overlay {
                if store.records.isEmpty {
                    ContentUnavailableView(
                        "No Apps Yet",
                        systemImage: "hammer",
                        description: Text("Open each sideloaded app once so it can report when it expires.")
                    )
                }
            }
            .refreshable { store.reload() }
            .navigationTitle("Sideboard")
            #if DEBUG
            .toolbar {
                Button("Test Notification", systemImage: "bell") {
                    Task { await ExpiryNotifications.sendTest(for: store.records.first) }
                }
            }
            #endif
        }
    }
}

private struct AppRow: View {
    let record: AppRecord

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.name)
                    .font(.headline)
                Group {
                    Text("Installed \(record.installDate.formatted(date: .abbreviated, time: .omitted))")
                    Text("Expires \(record.expiryDate.formatted(date: .abbreviated, time: .omitted))")
                    Text("Version \(record.version) (\(record.build))")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            Spacer()
            DaysLeftBadge(days: record.daysLeft())
        }
        .padding(.vertical, 2)
    }
}

private struct DaysLeftBadge: View {
    let days: Int

    var body: some View {
        Text(days <= 0 ? "Expired" : "\(days)d")
            .font(.subheadline.monospacedDigit().bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .foregroundStyle(.white)
            .background(color, in: .capsule)
    }

    private var color: Color {
        switch days {
        case ...7: .red
        case ...30: .orange
        default: .green
        }
    }
}

#Preview {
    ContentView(store: RecordStore())
}
