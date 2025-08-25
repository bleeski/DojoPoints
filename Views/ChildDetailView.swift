import SwiftUI
import SwiftData
import Charts

struct ChildDetailView: View {
    let child: Child
    @Binding var lastPointEvent: PointEvent?
    @Binding var showingUndo: Bool
    
    @Environment(\.modelContext) private var modelContext
    @Query private var allBehaviors: [Behavior]
    @Query private var allEvents: [PointEvent]
    
    @State private var selectedBucket: TimeBucket = .daily
    @State private var selectedCategory: BehaviorCategory? = nil
    
    private var childEvents: [PointEvent] {
        allEvents.filter { $0.child?.id == child.id }
    }
    
    private var childTotal: Int {
        PersistenceHelper.getTotalPoints(for: child, in: selectedBucket, from: allEvents)
    }
    
    private var childProgress: Double {
        guard child.goalPoints > 0 else { return 0 }
        let totalPoints = PersistenceHelper.getTotalPoints(for: child, in: .lifetime, from: allEvents)
        return Double(totalPoints) / Double(child.goalPoints)
    }
    
    private var filteredBehaviors: [Behavior] {
        if let category = selectedCategory {
            return allBehaviors.filter { $0.category == category }.sorted { $0.points > $1.points }
        }
        return allBehaviors.sorted { $0.points > $1.points }
    }
    
    var body: some View {
        ZStack {
            Theme.backgroundColor
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Theme.padding) {
                    // Child Header Card
                    childHeaderCard
                    
                    // Time Bucket Picker
                    SegmentedBucketPicker(selectedBucket: $selectedBucket)
                    
                    // Period Points
                    HStack {
                        VStack(alignment: .leading) {
                            Text(selectedBucket.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(childTotal) points")
                                .font(Theme.largeTitle())
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // Charts
                    if !childEvents.isEmpty {
                        chartsSection
                    }
                    
                    // Category Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            CategoryFilterChip(
                                title: "All",
                                isSelected: selectedCategory == nil,
                                color: .gray
                            ) {
                                selectedCategory = nil
                            }
                            
                            ForEach(BehaviorCategory.allCases) { category in
                                CategoryFilterChip(
                                    title: category.displayName,
                                    isSelected: selectedCategory == category,
                                    color: category.color
                                ) {
                                    selectedCategory = category
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Behavior Grid
                    behaviorGrid
                }
                .padding(.bottom, 100)
            }
        }
        .navigationTitle(child.name)
        .navigationBarTitleDisplayMode(.large)
    }
    
    @ViewBuilder
    private var childHeaderCard: some View {
        VStack(spacing: Theme.padding) {
            Text(child.emojiAvatar)
                .font(.system(size: 80))
            
            if child.goalPoints > 0 {
                BeltProgressRing(progress: childProgress, size: 100)
                
                Text(child.goalReward)
                    .font(Theme.title())
                    .multilineTextAlignment(.center)
                
                let totalPoints = PersistenceHelper.getTotalPoints(for: child, in: .lifetime, from: allEvents)
                Text("\(totalPoints) / \(child.goalPoints) points")
                    .font(Theme.body())
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .fill(Theme.cardBackground)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        )
        .padding(.horizontal)
        .onAppear {
            if childProgress >= 1.0 {
                Theme.successHaptic()
            }
        }
    }
    
    @ViewBuilder
    private var chartsSection: some View {
        VStack(spacing: Theme.padding) {
            // Line Chart
            VStack(alignment: .leading) {
                Text("Progress Over Time")
                    .font(Theme.headline())
                    .padding(.horizontal)
                
                let chartData = PersistenceHelper.getPointsOverTime(for: child, in: selectedBucket, from: allEvents)
                
                if !chartData.isEmpty {
                    Chart(chartData, id: \.0) { item in
                        LineMark(
                            x: .value("Date", item.0),
                            y: .value("Points", item.1)
                        )
                        .foregroundStyle(Color.blue)
                        
                        AreaMark(
                            x: .value("Date", item.0),
                            y: .value("Points", item.1)
                        )
                        .foregroundStyle(Color.blue.opacity(0.1))
                    }
                    .frame(height: 180)
                    .padding()
                    .background(Theme.cardBackground)
                    .cornerRadius(Theme.cornerRadius)
                    .padding(.horizontal)
                }
            }
            
            // Pie Chart
            VStack(alignment: .leading) {
                Text("Points by Category")
                    .font(Theme.headline())
                    .padding(.horizontal)
                
                let categoryData = PersistenceHelper.getPointsByCategory(for: child, in: selectedBucket, from: allEvents)
                
                if !categoryData.isEmpty {
                    Chart(categoryData, id: \.0) { item in
                        SectorMark(
                            angle: .value("Points", item.1),
                            innerRadius: .ratio(0.5)
                        )
                        .foregroundStyle(item.0.color)
                    }
                    .frame(height: 180)
                    .padding()
                    .background(Theme.cardBackground)
                    .cornerRadius(Theme.cornerRadius)
                    .padding(.horizontal)
                }
            }
        }
    }
    
    @ViewBuilder
    private var behaviorGrid: some View {
        VStack(alignment: .leading) {
            Text("Award Points")
                .font(Theme.title())
                .padding(.horizontal)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                ForEach(filteredBehaviors) { behavior in
                    AwardButton(behavior: behavior) {
                        awardPoints(behavior: behavior)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func awardPoints(behavior: Behavior) {
        let event = PointEvent(
            child: child,
            behavior: behavior,
            points: behavior.points
        )
        
        modelContext.insert(event)
        try? modelContext.save()
        
        lastPointEvent = event
        showingUndo = true
        
        // Check for goal achievement
        let newTotal = PersistenceHelper.getTotalPoints(for: child, in: .lifetime, from: allEvents + [event])
        if child.goalPoints > 0 && newTotal >= child.goalPoints {
            Theme.successHaptic()
        }
    }
}

struct CategoryFilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? color.opacity(0.2) : Color.gray.opacity(0.1))
                        .overlay(
                            Capsule()
                                .stroke(isSelected ? color : Color.clear, lineWidth: 2)
                        )
                )
                .foregroundColor(isSelected ? color : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
