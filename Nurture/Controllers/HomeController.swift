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
    @Published var sleepRecommendation: SleepRecommendation?
    @Published var child: Child?

    private let childrenStore: ChildrenStore?
    private let aiSleepRecService = AISleepRecommendationService()
    private let mlPredictionService = MLPredictionService()
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
            // Demo: fully mocked data for UI previews and simulator
            loadMockData()
        } else {
            // Non‑demo: until Bluetooth / sleep detection are wired,
            // seed lightweight mock data so Home still shows nap prediction
            // and a sleep recommendation based only on simple durations.
            seedMockPredictionIfNeeded()
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
        } else {
            // Until real data is integrated, refresh keeps the mock-backed
            // prediction and recommendation up to date.
            seedMockPredictionIfNeeded()
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
        if let wakeTime = sleepStartDate {
            napPrediction = mlPredictionService.predictNextNap(
                wakeTime: wakeTime,
                ageRange: child?.ageRange ?? .sixToTwelveMonths
            )
        }
        sleepRecommendation = aiSleepRecService.recommendation(
            for: child,
            lastNightTotalSeconds: lastNightTotalDuration,
            todaysNapsSeconds: todaysNapsDuration,
            isCurrentlyAsleep: isAsleep
        )
    }

    /// Seeds minimal mock data for nap prediction and sleep recommendation
    /// when the real Bluetooth / sleep detection pipeline is not yet wired.
    /// Uses only simple duration-style inputs so the Home screen always shows
    /// a useful "next nap" and "tonight's suggestion" card.
    private func seedMockPredictionIfNeeded() {
        // Ensure we have a child profile to derive age range from.
        if child == nil {
            if let store = childrenStore {
                child = store.selectedChild
            } else if let savedChild = ChildProfileStore.load() {
                child = savedChild
            } else {
                let birthdate = Calendar.current.date(byAdding: .month, value: -8, to: Date()) ?? Date()
                child = Child(name: mockChildName, birthdate: birthdate, ageRange: AgeRange.from(birthdate: birthdate))
            }
        }

        // If we don't yet have any real sleep data, populate lightweight mock
        // durations so the AI services have something to work from.
        if lastNightTotalDuration == 0 && todaysNapsDuration == 0 {
            // Slightly more generic defaults than demo-specific values.
            lastNightTotalDuration = 8 * 3600 + 30 * 60  // 8h 30m
            todaysNapsDuration = 1 * 3600                // 1h across naps
            todaysNapCount = 2
        }

        // Use a simple "awake for about 2 hours" assumption for next‑nap timing.
        let assumedLastWakeTime = Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date()
        napPrediction = mlPredictionService.predictNextNap(
            wakeTime: assumedLastWakeTime,
            ageRange: child?.ageRange ?? .sixToTwelveMonths
        )

        sleepRecommendation = aiSleepRecService.recommendation(
            for: child,
            lastNightTotalSeconds: lastNightTotalDuration,
            todaysNapsSeconds: todaysNapsDuration,
            isCurrentlyAsleep: isAsleep
        )
    }
}
