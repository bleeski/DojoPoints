import SwiftUI
import SwiftData

@main
struct DojoPointsApp: App {
    let container: ModelContainer
    
    init() {
        do {
            let schema = Schema([
                Child.self,
                Behavior.self,
                PointEvent.self,
                FamilyGoal.self
            ])
            
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            
            container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            // Seed built-in behaviors on first launch
            let context = ModelContext(container)
            SeedData.seedBuiltinBehaviorsIfNeeded(context: context)
            
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            FamilyDashboardView()
                .modelContainer(container)
                .preferredColorScheme(.light)
        }
    }
}
