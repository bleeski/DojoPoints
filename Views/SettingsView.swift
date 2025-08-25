import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var children: [Child]
    @Query private var familyGoals: [FamilyGoal]
    @Query private var allEvents: [PointEvent]
    
    @State private var familyGoalPoints = 100
    @State private var familyGoalReward = ""
    @State private var showingResetAlert = false
    @State private var showingTestDataAlert = false
    
    private var familyGoal: FamilyGoal? {
        familyGoals.first
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Family Goal") {
                    HStack {
                        Text("Points Needed")
                        Spacer()
                        TextField("100", value: $familyGoalPoints, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    TextField("Reward (e.g., Family Movie Night 🎬)", text: $familyGoalReward)
                    
                    Button("Update Family Goal") {
                        updateFamilyGoal()
                    }
                }
                
                Section("Children") {
                    ForEach(children.filter { !$0.isArchived }) { child in
                        ChildSettingsRow(child: child)
                    }
                    
                    if children.contains(where: { $0.isArchived }) {
                        DisclosureGroup("Archived Children") {
                            ForEach(children.filter { $0.isArchived }) { child in
                                HStack {
                                    Text(child.emojiAvatar)
                                    Text(child.name)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Button("Restore") {
                                        child.isArchived = false
                                        try? modelContext.save()
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                        }
                    }
                }
                
                Section("Developer Tools") {
                    Button("Generate 30 Days Test Data") {
                        showingTestDataAlert = true
                    }
                    .foregroundColor(.blue)
                    
                    Button("Reset All Data") {
                        showingResetAlert = true
                    }
                    .foregroundColor(.red)
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Week Start")
                        Spacer()
                        Text("Sunday")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                if let goal = familyGoal {
                    familyGoalPoints = goal.goalPoints
                    familyGoalReward = goal.goalReward
                }
            }
            .alert("Generate Test Data", isPresented: $showingTestDataAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Generate") {
                    SeedData.generateTestData(context: modelContext, daysBack: 30)
                }
            } message: {
                Text("This will create test children and random point events for the past 30 days. Use this for testing charts and features.")
            }
            .alert("Reset All Data", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetAllData()
                }
            } message: {
                Text("This will permanently delete all children, behaviors, and point history. This cannot be undone.")
            }
        }
    }
    
    private func updateFamilyGoal() {
        if let goal = familyGoal {
            goal.goalPoints = familyGoalPoints
            goal.goalReward = familyGoalReward
        } else {
            let newGoal = FamilyGoal(goalPoints: familyGoalPoints, goalReward: familyGoalReward)
            modelContext.insert(newGoal)
        }
        try? modelContext.save()
        dismiss()
    }
    
    private func resetAllData() {
        // Delete all data
        children.forEach { modelContext.delete($0) }
        allEvents.forEach { modelContext.delete($0) }
        
        // Keep built-in behaviors but delete custom ones
        let behaviors = try? modelContext.fetch(FetchDescriptor<Behavior>())
        behaviors?.filter { !$0.isBuiltin }.forEach { modelContext.delete($0) }
        
        try? modelContext.save()
        
        // Re-seed built-in behaviors
        SeedData.seedBuiltinBehaviorsIfNeeded(context: modelContext)
        
        dismiss()
    }
}

struct ChildSettingsRow: View {
    let child: Child
    @Environment(\.modelContext) private var modelContext
    @State private var isEditing = false
    @State private var editedName: String = ""
    @State private var editedGoalPoints: Int = 0
    @State private var editedGoalReward: String = ""
    
    var body: some View {
        HStack {
            Text(child.emojiAvatar)
                .font(.title2)
            
            if isEditing {
                VStack(alignment: .leading) {
                    TextField("Name", text: $editedName)
                        .textFieldStyle(.roundedBorder)
                    
                    HStack {
                        TextField("Goal", value: $editedGoalPoints, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                        
                        TextField("Reward", text: $editedGoalReward)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            } else {
                VStack(alignment: .leading) {
                    Text(child.name)
                        .font(Theme.headline())
                    
                    if child.goalPoints > 0 {
                        Text("\(child.goalPoints) pts → \(child.goalReward)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                if isEditing {
                    Button("Save") {
                        child.name = editedName
                        child.goalPoints = editedGoalPoints
                        child.goalReward = editedGoalReward
                        try? modelContext.save()
                        isEditing = false
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Cancel") {
                        isEditing = false
                    }
                    .buttonStyle(.plain)
                } else {
                    Button("Edit") {
                        editedName = child.name
                        editedGoalPoints = child.goalPoints
                        editedGoalReward = child.goalReward
                        isEditing = true
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Archive") {
                        child.isArchived = true
                        try? modelContext.save()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.orange)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
