import SwiftUI
import SwiftData
import Charts

struct FamilyDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Child> { !$0.isArchived }, sort: \Child.name) private var children: [Child]
    @Query private var allEvents: [PointEvent]
    @Query private var familyGoals: [FamilyGoal]
    @Query private var behaviors: [Behavior]
    
    @State private var selectedBucket: TimeBucket = .daily
    @State private var showingSettings = false
    @State private var showingBehaviors = false
    @State private var showingAddChild = false
    @State private var lastPointEvent: PointEvent?
    @State private var showingUndo = false
    
    private var familyGoal: FamilyGoal? {
        familyGoals.first
    }
    
    private var familyTotal: Int {
        PersistenceHelper.getFamilyTotalPoints(in: selectedBucket, from: allEvents)
    }
    
    private var familyProgress: Double {
        guard let goal = familyGoal, goal.goalPoints > 0 else { return 0 }
        return Double(familyTotal) / Double(goal.goalPoints)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Theme.padding) {
                        // Family Goal Card
                        if let goal = familyGoal, goal.goalPoints > 0 {
                            familyGoalCard(goal: goal)
                        }
                        
                        // Time Bucket Picker
                        SegmentedBucketPicker(selectedBucket: $selectedBucket)
                            .padding(.top, 8)
                        
                        // Today's Total
                        HStack {
                            VStack(alignment: .leading) {
                                Text(selectedBucket.displayName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(familyTotal) points")
                                    .font(Theme.largeTitle())
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        // Charts
                        if !allEvents.isEmpty {
                            chartsSection
                        }
                        
                        // Children List
                        childrenSection
                    }
                    .padding(.bottom, 100)
                }
                
                // Undo Snackbar
                SnackbarUndo(lastEvent: $lastPointEvent, isShowing: $showingUndo)
            }
            .navigationTitle("Dojo Points")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingAddChild = true }) {
                            Label("Add Child", systemImage: "person.badge.plus")
                        }
                        Button(action: { showingBehaviors = true }) {
                            Label("Manage Behaviors", systemImage: "star.circle")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingBehaviors) {
                BehaviorsView()
            }
            .sheet(isPresented: $showingAddChild) {
                AddChildSheet()
            }
        }
    }
    
    @ViewBuilder
    private func familyGoalCard(goal: FamilyGoal) -> some View {
        VStack(spacing: Theme.padding) {
            Text("Family Goal")
                .font(Theme.headline())
                .foregroundColor(.secondary)
            
            BeltProgressRing(progress: familyProgress, size: 120)
            
            Text(goal.goalReward)
                .font(Theme.title())
                .multilineTextAlignment(.center)
            
            Text("\(familyTotal) / \(goal.goalPoints) points")
                .font(Theme.body())
                .foregroundColor(.secondary)
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
            if familyProgress >= 1.0 {
                Theme.successHaptic()
                showConfetti()
            }
        }
    }
    
    @ViewBuilder
    private var chartsSection: some View {
        VStack(spacing: Theme.padding) {
            // Line Chart - Points Over Time
            VStack(alignment: .leading) {
                Text("Points Over Time")
                    .font(Theme.headline())
                    .padding(.horizontal)
                
                let chartData = PersistenceHelper.getPointsOverTime(for: nil, in: selectedBucket, from: allEvents)
                
                if !chartData.isEmpty {
                    Chart(chartData, id: \.0) { item in
                        LineMark(
                            x: .value("Date", item.0),
                            y: .value("Points", item.1)
                        )
                        .foregroundStyle(Theme.primaryGradient)
                        
                        AreaMark(
                            x: .value("Date", item.0),
                            y: .value("Points", item.1)
                        )
                        .foregroundStyle(Theme.primaryGradient.opacity(0.1))
                    }
                    .frame(height: 200)
                    .padding()
                    .background(Theme.cardBackground)
                    .cornerRadius(Theme.cornerRadius)
                    .padding(.horizontal)
                }
            }
            
            // Pie Chart - Points by Category
            VStack(alignment: .leading) {
                Text("Points by Category")
                    .font(Theme.headline())
                    .padding(.horizontal)
                
                let categoryData = PersistenceHelper.getPointsByCategory(for: nil, in: selectedBucket, from: allEvents)
                
                if !categoryData.isEmpty {
                    Chart(categoryData, id: \.0) { item in
                        SectorMark(
                            angle: .value("Points", item.1),
                            innerRadius: .ratio(0.6)
                        )
                        .foregroundStyle(item.0.color)
                        .annotation(position: .overlay) {
                            if item.1 > 0 {
                                Text("\(item.1)")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .frame(height: 200)
                    .padding()
                    .background(Theme.cardBackground)
                    .cornerRadius(Theme.cornerRadius)
                    .padding(.horizontal)
                    
                    // Legend
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 8) {
                        ForEach(categoryData, id: \.0) { item in
                            HStack {
                                Circle()
                                    .fill(item.0.color)
                                    .frame(width: 12, height: 12)
                                Text(item.0.displayName)
                                    .font(.caption)
                                Spacer()
                                Text("\(item.1)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    @ViewBuilder
    private var childrenSection: some View {
        VStack(alignment: .leading, spacing: Theme.smallPadding) {
            Text("Children")
                .font(Theme.title())
                .padding(.horizontal)
            
            ForEach(children) { child in
                NavigationLink(destination: ChildDetailView(child: child, lastPointEvent: $lastPointEvent, showingUndo: $showingUndo)) {
                    HStack {
                        Text(child.emojiAvatar)
                            .font(.system(size: 40))
                        
                        VStack(alignment: .leading) {
                            Text(child.name)
                                .font(Theme.headline())
                                .foregroundColor(.primary)
                            
                            let childTotal = PersistenceHelper.getTotalPoints(for: child, in: selectedBucket, from: allEvents)
                            Text("\(childTotal) points \(selectedBucket.displayName.lowercased())")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if child.goalPoints > 0 {
                            let childTotal = PersistenceHelper.getTotalPoints(for: child, in: .lifetime, from: allEvents)
                            let progress = Double(childTotal) / Double(child.goalPoints)
                            BeltProgressRing(progress: progress, lineWidth: 4, size: 40)
                        }
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: Theme.cornerRadius)
                            .fill(Theme.cardBackground)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal)
            
            if children.isEmpty {
                VStack(spacing: Theme.padding) {
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    
                    Text("No children added yet")
                        .font(Theme.headline())
                        .foregroundColor(.secondary)
                    
                    Button(action: { showingAddChild = true }) {
                        Label("Add Your First Child", systemImage: "plus.circle.fill")
                            .font(Theme.headline())
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
        }
    }
    
    private func showConfetti() {
        // Simple confetti effect - would need more complex implementation for production
        Theme.heavyImpact()
    }
}

// MARK: - Add Child Sheet
struct AddChildSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name = ""
    @State private var selectedEmoji = "👧"
    @State private var goalPoints = 50
    @State private var goalReward = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Child Info") {
                    TextField("Name", text: $name)
                    
                    HStack {
                        Text("Avatar")
                        Spacer()
                        EmojiTextField(text: $selectedEmoji)
                            .frame(width: 60, height: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.blue.opacity(0.1))
                            )
                    }
                }
                
                Section("Goal (Optional)") {
                    HStack {
                        Text("Points Needed")
                        Spacer()
                        TextField("50", value: $goalPoints, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    TextField("Reward (e.g., Ice cream 🍦)", text: $goalReward)
                }
            }
            .navigationTitle("Add Child")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addChild()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.isEmpty || selectedEmoji.isEmpty)
                }
            }
        }
    }
    
    private func addChild() {
        let child = Child(
            name: name,
            emojiAvatar: String(selectedEmoji.prefix(1)), // Ensure only one emoji
            goalPoints: goalPoints,
            goalReward: goalReward
        )
        modelContext.insert(child)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Emoji Text Field
struct EmojiTextField: View {
    @Binding var text: String
    @State private var isEditing = false
    
    var body: some View {
        TextField("", text: $text)
            .font(.system(size: 40))
            .multilineTextAlignment(.center)
            .onChange(of: text) { oldValue, newValue in
                // Keep only the first emoji
                if newValue.count > 1 {
                    text = String(newValue.prefix(1))
                }
                // Ensure it's an emoji
                if !newValue.isEmpty && !newValue.unicodeScalars.first!.properties.isEmoji {
                    text = oldValue
                }
            }
    }
}
