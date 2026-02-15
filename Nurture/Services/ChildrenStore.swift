//
//  ChildrenStore.swift
//  Nurture
//
//  Single source of truth for children and selected child. Observed by Home, History, Settings.
//

import Foundation
import Combine

/// Holds all child profiles and the currently selected child. Persists via ChildProfileStore.
final class ChildrenStore: ObservableObject {
    @Published private(set) var children: [Child] = []
    @Published private(set) var selectedChildID: UUID?

    var selectedChild: Child? {
        guard let id = selectedChildID else { return children.first }
        return children.first { $0.id == id } ?? children.first
    }

    init() {
        load()
    }

    func load() {
        children = ChildProfileStore.loadAll()
        selectedChildID = ChildProfileStore.loadSelectedID()
        if selectedChildID == nil, let first = children.first {
            selectChild(first.id)
        }
    }

    func addChild(_ child: Child) {
        ChildProfileStore.add(child)
        if children.isEmpty {
            ChildProfileStore.saveSelectedID(child.id)
        }
        load()
    }

    func updateChild(_ child: Child) {
        ChildProfileStore.update(child)
        load()
    }

    func removeChild(id: UUID) {
        ChildProfileStore.remove(childID: id)
        load()
    }

    func selectChild(_ id: UUID) {
        guard children.contains(where: { $0.id == id }) else { return }
        ChildProfileStore.saveSelectedID(id)
        selectedChildID = id
    }
}
