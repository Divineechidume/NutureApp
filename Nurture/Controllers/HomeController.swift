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

    @Published var isAsleep: Bool = false
    @Published var sleepStartDate: Date?
    /// When non-nil, a nap is in progress (monitor-based or started via Start Nap).
    @Published var napStartDate: Date?
    @Published var lastNightTotalDuration: TimeInterval = 0
    @Published var todaysNapsDuration: TimeInterval = 0
    @Published var todaysNapCount: Int = 0
    @Published var sleepRecommendation: SleepRecommendation?
    @Published var child: Child?

    private let childrenStore: ChildrenStore?
    private let aiSleepRecService = AISleepRecommendationService()
    private let napRecommendationEngine = NapRecommendationEngine()
    private var cancellable: AnyCancellable?
    private var manualStoreCancellable: AnyCancellable?
    /// Fires every minute while a nap is in progress to refresh live duration.
    private var napLiveTimer: Timer?
    /// Fires every minute when awake so "Awake for Xh Ym" updates from history.
    private var awakeLiveTimer: Timer?
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
        manualStoreCancellable = ManualSleepStore.shared.objectWillChange.sink { [weak self] _ in
            self?.syncTodaysNapsFromStore()
            self?.objectWillChange.send()
        }
        syncTodaysNapsFromStore()
        startAwakeLiveTimerIfNeeded()

        if useDemoMode {
            // Demo: fully mocked data for UI previews and simulator
            loadMockData()
            // TEST MODE: Keep child awake for nap prediction visibility
            seedMockPredictionIfNeeded()
        } else {
            // Non‑demo: until Bluetooth / sleep detection are wired,
            // seed lightweight mock data so Home still shows nap prediction
            // and a sleep recommendation based only on simple durations.
            seedMockPredictionIfNeeded()
        }
    }

    // MARK: - Computed (for View)

    /// Duration for status: night sleep elapsed, or when awake = time since last sleep/nap end (from history).
    var durationString: String {
        if isAsleep, let start = sleepStartDate {
            return Date().timeIntervalSince(start).durationString
        }
        if napStartDate != nil { return "" } // Napping uses napDurationString
        if let end = lastSleepEndTime, end <= Date() {
            return Date().timeIntervalSince(end).durationString
        }
        return "2h 15m" // Fallback when no history or lastSleepEndTime in future
    }

    /// Most recent completed sleep or nap end time (source of truth: ManualSleepStore).
    var lastSleepEndTime: Date? {
        ManualSleepStore.shared.lastSleepEndDate(childId: currentChildId)
    }

    /// Awake duration in seconds. Derived only (no stored state). 0 when napping; otherwise max(0, currentTime - lastSleepEndTime). Recalculates when nap added/deleted/edited via lastSleepEndTime from store.
    var awakeDuration: TimeInterval {
        if napStartDate != nil { return 0 }
        guard let end = lastSleepEndTime else { return 0 }
        return max(0, Date().timeIntervalSince(end))
    }

    /// State-based nap recommendation (no fixed nextNapTime). Recomputed when sleep history changes or timer fires.
    var napRecommendation: NapRecommendation {
        napRecommendationEngine.recommend(lastSleepEndTime: lastSleepEndTime, currentTime: Date())
    }

    /// Live nap duration (updates every minute via napLiveTimer). Use when napStartDate != nil.
    var napDurationString: String {
        guard let start = napStartDate else { return "" }
        return Date().timeIntervalSince(start).durationString
    }

    var sleepStartTimeString: String? {
        guard isAsleep, let start = sleepStartDate else { return nil }
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: start)
    }

    /// Start time of current nap (for status card when napping).
    var napStartTimeString: String? {
        guard let start = napStartDate else { return nil }
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
        }
        // TEST MODE: Keep child awake for nap prediction visibility
        seedMockPredictionIfNeeded()
        // Integration point: Pull latest from BluetoothService / cache when not in demo mode.
        // TODO: Pull latest from BluetoothService / cache. PRD Section 2 - pull-to-refresh.
    }

    func setDemoAwake(_ awake: Bool) {
        demoShowAwake = awake
        isAsleep = !awake
    }

    // MARK: - Manual / monitor-based sleep tracking (mock)

    private var currentChildId: UUID { childrenStore?.selectedChild?.id ?? UUID() }

    /// Start Sleep: record start timestamp (mock), update status to sleeping.
    func startSleep() {
        isAsleep = true
        sleepStartDate = Date()
    }

    /// End Sleep: compute duration, add to manual history (mock), update status.
    func endSleep() {
        guard let start = sleepStartDate else { return }
        let end = Date()
        ManualSleepStore.shared.add(startDate: start, endDate: end, isNighttime: true, childId: currentChildId)
        isAsleep = false
        sleepStartDate = nil
        lastNightTotalDuration = end.timeIntervalSince(start)
        refresh()
    }

    /// Start Nap: record nap start (mock), show status as sleeping, begin live duration timer.
    func startNap() {
        napLiveTimer?.invalidate()
        napLiveTimer = nil
        napStartDate = Date()
        napLiveTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.objectWillChange.send()
        }
        RunLoop.main.add(napLiveTimer!, forMode: .common)
    }

    /// End Nap: compute duration, add to today's nap history, update card, clear status.
    func endNap() {
        napLiveTimer?.invalidate()
        napLiveTimer = nil
        guard let start = napStartDate else { return }
        let end = Date()
        ManualSleepStore.shared.add(startDate: start, endDate: end, isNighttime: false, childId: currentChildId)
        napStartDate = nil
        syncTodaysNapsFromStore()
        refresh()
    }

    /// Log Nap (manual): save nap with given start and duration to history. End time is clamped to now if in the future.
    func logNap(startDate: Date, durationSeconds: TimeInterval) {
        let endDate = startDate.addingTimeInterval(durationSeconds)
        let clampedEnd = endDate > Date() ? Date() : endDate
        ManualSleepStore.shared.add(startDate: startDate, endDate: clampedEnd, isNighttime: false, childId: currentChildId)
        syncTodaysNapsFromStore()
        refresh()
    }

    /// Sync Today's Naps from ManualSleepStore (called when store changes, e.g. add/delete).
    /// Falls back to 187 minutes across 2 naps when no manual naps are logged today.
    private func syncTodaysNapsFromStore() {
        let today = Calendar.current.startOfDay(for: Date())
        let manualEntries = ManualSleepStore.shared.napEntries(for: today)
        if manualEntries.isEmpty {
            todaysNapsDuration = 187 * 60  // 187 min fallback
            todaysNapCount = 2
        } else {
            todaysNapsDuration = ManualSleepStore.shared.napDuration(for: today)
            todaysNapCount = manualEntries.count
        }
    }

    /// Start a 60s timer when awake so "Awake for Xh Ym" updates every minute from lastSleepEndTime.
    /// Weekday → mock night sleep hours. 1=Sun … 7=Sat. Matches HistoryView.
    private let mockHoursByWeekday: [Int: Double] = [
        1: 11.0, 2: 11.5, 3: 10.0, 4: 12.0, 5: 11.0, 6: 10.0, 7: 11.5
    ]

    /// Last night's mock duration derived from yesterday's weekday.
    private var lastNightMockDuration: TimeInterval {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let weekday = Calendar.current.component(.weekday, from: yesterday)
        return (mockHoursByWeekday[weekday] ?? 10.0) * 3600
    }

    private func startAwakeLiveTimerIfNeeded() {
        awakeLiveTimer?.invalidate()
        awakeLiveTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.objectWillChange.send()
        }
        RunLoop.main.add(awakeLiveTimer!, forMode: .common)
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
        var components = DateComponents()
        components.hour = -2
        components.minute = -15
        sleepStartDate = Calendar.current.date(byAdding: components, to: Date())
        lastNightTotalDuration = lastNightMockDuration
        todaysNapsDuration = 187 * 60  // 187 min in 2 naps
        todaysNapCount = 2
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
        // TEST MODE: Keep child awake for nap prediction visibility (don’t override in-progress sleep/nap)
        if sleepStartDate == nil {
            isAsleep = false
        }

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
            lastNightTotalDuration = lastNightMockDuration
            todaysNapsDuration = 187 * 60  // 187 min in 2 naps
            todaysNapCount = 2
        }

        sleepRecommendation = aiSleepRecService.recommendation(
            for: child,
            lastNightTotalSeconds: lastNightTotalDuration,
            todaysNapsSeconds: todaysNapsDuration,
            isCurrentlyAsleep: isAsleep
        )
    }
}
