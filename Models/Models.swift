import Foundation
import SwiftData
import SwiftUI

// MARK: - Child Model
@Model
final class Child {
    @Attribute(.unique) var id: UUID
    var name: String
    var emojiAvatar: String
    var isArchived: Bool
    var goalPoints: Int
    var goalReward: String
    
    @Relationship(deleteRule: .cascade, inverse: \PointEvent.child)
    var pointEvents: [PointEvent]? = []
    
    init(id: UUID = UUID(),
         name: String,
         emojiAvatar: String,
         isArchived: Bool = false,
         goalPoints: Int = 0,
         goalReward: String = "") {
        self.id = id
        self.name = name
        self.emojiAvatar = emojiAvatar
        self.isArchived = isArchived
        self.goalPoints = goalPoints
        self.goalReward = goalReward
    }
}

// MARK: - Behavior Category
enum BehaviorCategory: String, Codable, CaseIterable, Identifiable, Comparable {
    case listening = "Listening"
    case chores = "Chores"
    case hygiene = "Hygiene"
    case eating = "Eating"
    case selfCare = "SelfCare"
    case learning = "Learning"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .listening: return "Listening & Manners"
        case .chores: return "Chores"
        case .hygiene: return "Hygiene"
        case .eating: return "Eating"
        case .selfCare: return "Self-Care"
        case .learning: return "Learning"
        }
    }
    
    var color: Color {
        switch self {
        case .listening: return .blue
        case .chores: return .green
        case .hygiene: return .cyan
        case .eating: return .orange
        case .selfCare: return .purple
        case .learning: return .pink
        }
    }
    
    // Comparable conformance
    static func < (lhs: BehaviorCategory, rhs: BehaviorCategory) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Behavior Model
@Model
final class Behavior {
    @Attribute(.unique) var id: UUID
    var name: String
    var category: BehaviorCategory
    var emoji: String
    var points: Int
    var isBuiltin: Bool
    
    @Relationship(deleteRule: .cascade, inverse: \PointEvent.behavior)
    var pointEvents: [PointEvent]? = []
    
    init(id: UUID = UUID(),
         name: String,
         category: BehaviorCategory,
         emoji: String,
         points: Int,
         isBuiltin: Bool = false) {
        self.id = id
        self.name = name
        self.category = category
        self.emoji = emoji
        self.points = points
        self.isBuiltin = isBuiltin
    }
}

// MARK: - Point Event Model
@Model
final class PointEvent {
    @Attribute(.unique) var id: UUID
    var child: Child?
    var behavior: Behavior?
    var points: Int
    var timestamp: Date
    
    init(id: UUID = UUID(),
         child: Child,
         behavior: Behavior,
         points: Int,
         timestamp: Date = Date()) {
        self.id = id
        self.child = child
        self.behavior = behavior
        self.points = points
        self.timestamp = timestamp
    }
}

// MARK: - Family Goal Model
@Model
final class FamilyGoal {
    var goalPoints: Int
    var goalReward: String
    
    init(goalPoints: Int = 0, goalReward: String = "") {
        self.goalPoints = goalPoints
        self.goalReward = goalReward
    }
}
