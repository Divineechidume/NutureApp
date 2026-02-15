//
//  HomeController.swift
//  Nurture
//
//  Holds current sleep state, last night total, today's naps, nap prediction. PRD Section 2 (Home).
//  In demo mode uses mock values; TODOs for BluetoothService, SleepDetectionService, MLPredictionService.
//

import Foundation
import Combine

/// Coordinates home screen state: asleep/awake, duration, secondary cards, nap prediction.
final class HomeController: ObservableObject {
    // MARK: - Published State

    @Published var isAsleep: Bool = true
    @Published var sleepStartDate: Date?
    @Published var lastNightTotalDuration: TimeInterval = 0
    @Published var todaysNapsDuration: TimeInterval = 0
    @Published var todaysNapCount: Int = 0
    @Published var napPrediction: NapPrediction?
    @Published var child: Child?

    private let childrenStore: ChildrenStore?
    private var cancellable: AnyCancellable?
    @Published var lastUpdated: Date = Date()
    @Published var demoShowAwake: Bool = false

    // MARK: - Dependencies

    // TODO: Inject BluetoothService for real-time sync
    // Purpose: Get current sleep state and sync on pull-to-refresh
    // PRD Reference: Section 2 - Home Screen, real-time Bluetooth sync
    // Dependencies: BluetoothService, SleepDetectionService
    // Estimated complexity: Medium

    // TODO: Inject SleepDetectionService for sleep/wake transitions
    // PRD Reference: Section 2
    // Estimated complexity: High

    // TODO: Inject MLPredictionService for nap prediction when awake
    // PRD Reference: Section 5
    // Estimated complexity: Medium

    init(childrenStore: ChildrenStore? = nil) {
        self.childrenStore = childrenStore
        if let store = childrenStore {
            child = store.selectedChild
            cancellable = store.objectWillChange.sink { [weak self] _ in
                self?.child = store.selectedChild
                self?.objectWillChange.send()
            }
        }
        if useDemoMode {
            loadMockData()
        }
    }

    // MARK: - Computed (for View)

    var durationString: String {
        if isAsleep, let start = sleepStartDate {
            return Date().timeIntervalSince(start).durationString
        }
        return "2h 15m" // Mock when awake
    }

    var sleepStartTimeString: String? {
        guard isAsleep, let start = sleepStartDate else { return nil }
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: start)
    }

    var lastNightTotalString: String {
        lastNightTotalDuration.durationString
    }

    var todaysNapsString: String {
        "\(todaysNapsDuration.durationString) across \(todaysNapCount) nap\(todaysNapCount == 1 ? "" : "s")"
    }

    // MARK: - Actions

    func refresh() {
        lastUpdated = Date()
        if let store = childrenStore {
            child = store.selectedChild
        }
        if useDemoMode {
            loadMockData()
        }
        // Integration point: Pull latest from BluetoothService / cache when not in demo mode.
        // TODO: Pull latest from BluetoothService / cache. PRD Section 2 - pull-to-refresh.
    }

    func setDemoAwake(_ awake: Bool) {
        demoShowAwake = awake
        isAsleep = !awake
    }

    private func loadMockData() {
        if let store = childrenStore {
            child = store.selectedChild
        } else if let savedChild = ChildProfileStore.load() {
            child = savedChild
        } else {
            let birthdate = Calendar.current.date(byAdding: .month, value: -8, to: Date()) ?? Date()
            child = Child(name: mockChildName, birthdate: birthdate, ageRange: AgeRange.from(birthdate: birthdate))
        }
        isAsleep = !demoShowAwake
        var components = DateComponents()
        components.hour = -2
        components.minute = -15
        sleepStartDate = Calendar.current.date(byAdding: components, to: Date())
        lastNightTotalDuration = 9 * 3600 + 15 * 60 // 9h 15m
        todaysNapsDuration = 1 * 3600 + 30 * 60
        todaysNapCount = 1
        napPrediction = NapPrediction(
            suggestedTime: Calendar.current.date(byAdding: .hour, value: 2, to: Date()) ?? Date(),
            confidence: .high,
            message: "Likely ready for a nap around 2:00 PM"
        )
    }
}
