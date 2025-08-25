import Foundation
import SwiftData

struct SeedData {
    static func seedBuiltinBehaviorsIfNeeded(context: ModelContext) {
        // Check if we already have behaviors
        let descriptor = FetchDescriptor<Behavior>()
        let existingBehaviors = try? context.fetch(descriptor)
        
        if existingBehaviors?.isEmpty == false {
            return // Already seeded
        }
        
        // Seed built-in behaviors
        let builtinBehaviors = [
            // Listening & Manners
            Behavior(name: "First-time listening", category: .listening, emoji: "⭐️", points: 3, isBuiltin: true),
            Behavior(name: "No whining", category: .listening, emoji: "🤫", points: 5, isBuiltin: true),
            Behavior(name: "2+ asks without listening", category: .listening, emoji: "⚠️", points: -1, isBuiltin: true),
            Behavior(name: "Meltdown", category: .listening, emoji: "💥", points: -5, isBuiltin: true),
            
            // Chores
            Behavior(name: "Making bed", category: .chores, emoji: "🛏️", points: 1, isBuiltin: true),
            Behavior(name: "Clearing dishes", category: .chores, emoji: "🍽️", points: 1, isBuiltin: true),
            
            // Hygiene
            Behavior(name: "Getting clean", category: .hygiene, emoji: "🧼", points: 1, isBuiltin: true),
            Behavior(name: "Brushing teeth", category: .hygiene, emoji: "🪥", points: 1, isBuiltin: true),
            
            // Eating
            Behavior(name: "Eating veggies", category: .eating, emoji: "🥦", points: 4, isBuiltin: true),
            
            // Self-Care
            Behavior(name: "Getting dressed by self", category: .selfCare, emoji: "👕", points: 2, isBuiltin: true),
            
            // Learning
            Behavior(name: "Doing reading", category: .learning, emoji: "📚", points: 1, isBuiltin: true)
        ]
        
        for behavior in builtinBehaviors {
            context.insert(behavior)
        }
        
        // Also create a default family goal if none exists
        let goalDescriptor = FetchDescriptor<FamilyGoal>()
        let existingGoals = try? context.fetch(goalDescriptor)
        
        if existingGoals?.isEmpty != false {
            let defaultGoal = FamilyGoal(goalPoints: 100, goalReward: "Family Movie Night! 🎬")
            context.insert(defaultGoal)
        }
        
        try? context.save()
    }
    
    // Developer helper to generate test data
    static func generateTestData(context: ModelContext, daysBack: Int = 30) {
        // Create test children if none exist
        let childDescriptor = FetchDescriptor<Child>()
        let existingChildren = try? context.fetch(childDescriptor)
        
        var testChildren: [Child] = []
        if existingChildren?.isEmpty != false {
            let child1 = Child(name: "Emma", emojiAvatar: "👧", goalPoints: 50, goalReward: "Ice cream 🍦")
            let child2 = Child(name: "Noah", emojiAvatar: "👦", goalPoints: 75, goalReward: "New toy 🧸")
            context.insert(child1)
            context.insert(child2)
            testChildren = [child1, child2]
        } else {
            testChildren = existingChildren ?? []
        }
        
        // Get all behaviors
        let behaviorDescriptor = FetchDescriptor<Behavior>()
        let behaviors = (try? context.fetch(behaviorDescriptor)) ?? []
        
        guard !behaviors.isEmpty else { return }
        
        // Generate random events for past days
        let calendar = Calendar.current
        let now = Date()
        
        for dayOffset in 0..<daysBack {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            
            // Generate 2-8 events per day
            let eventCount = Int.random(in: 2...8)
            
            for _ in 0..<eventCount {
                let randomChild = testChildren.randomElement()!
                let randomBehavior = behaviors.randomElement()!
                
                // Create event with randomized time during that day
                let hour = Int.random(in: 7...21)
                let minute = Int.random(in: 0...59)
                
                var components = calendar.dateComponents([.year, .month, .day], from: date)
                components.hour = hour
                components.minute = minute
                
                if let eventDate = calendar.date(from: components) {
                    let event = PointEvent(
                        child: randomChild,
                        behavior: randomBehavior,
                        points: randomBehavior.points,
                        timestamp: eventDate
                    )
                    context.insert(event)
                }
            }
        }
        
        try? context.save()
    }
}
