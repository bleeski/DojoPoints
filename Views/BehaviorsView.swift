import SwiftUI
import SwiftData

struct BehaviorsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Behavior.category), SortDescriptor(\Behavior.name)]) private var behaviors: [Behavior]
    
    @State private var showingAddBehavior = false
    
    private var groupedBehaviors: [(BehaviorCategory, [Behavior])] {
        Dictionary(grouping: behaviors, by: { $0.category })
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .map { ($0.key, $0.value.sorted { $0.name < $1.name }) }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedBehaviors, id: \.0) { category, categoryBehaviors in
                    Section(category.displayName) {
                        ForEach(categoryBehaviors) { behavior in
                            HStack {
                                Text(behavior.emoji)
                                    .font(.title2)
                                
                                VStack(alignment: .leading) {
                                    Text(behavior.name)
                                        .font(Theme.headline())
                                    
                                    HStack {
                                        Image(systemName: behavior.points >= 0 ? "plus.circle.fill" : "minus.circle.fill")
                                            .font(.caption)
                                        Text("\(abs(behavior.points)) points")
                                            .font(.caption)
                                    }
                                    .foregroundColor(behavior.points >= 0 ? .green : .red)
                                }
                                
                                Spacer()
                                
                                if behavior.isBuiltin {
                                    Text("Built-in")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(Color.gray.opacity(0.2)))
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete { indexSet in
                            deleteBehaviors(in: categoryBehaviors, at: indexSet)
                        }
                    }
                }
            }
            .navigationTitle("Behaviors")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddBehavior = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddBehavior) {
                AddBehaviorSheet()
            }
        }
    }
    
    private func deleteBehaviors(in behaviors: [Behavior], at offsets: IndexSet) {
        for index in offsets {
            let behavior = behaviors[index]
            // Only allow deletion of custom behaviors
            if !behavior.isBuiltin {
                modelContext.delete(behavior)
            }
        }
        try? modelContext.save()
    }
}

struct AddBehaviorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name = ""
    @State private var emoji = "⭐"
    @State private var points = 1
    @State private var isNegative = false
    @State private var category: BehaviorCategory = .listening
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Behavior Details") {
                    TextField("Name", text: $name)
                    
                    Picker("Category", selection: $category) {
                        ForEach(BehaviorCategory.allCases) { cat in
                            Text(cat.displayName).tag(cat)
                        }
                    }
                    
                    HStack {
                        Text("Points")
                        Spacer()
                        
                        Button(action: { isNegative.toggle() }) {
                            Image(systemName: isNegative ? "minus.circle.fill" : "plus.circle.fill")
                                .foregroundColor(isNegative ? .red : .green)
                                .font(.title2)
                        }
                        
                        TextField("1", value: $points, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                    }
                }
                
                Section("Icon") {
                    HStack {
                        Text("Emoji")
                        Spacer()
                        EmojiTextField(text: $emoji)
                            .frame(width: 60, height: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(category.color.opacity(0.1))
                            )
                    }
                }
                
                Section {
                    Text("Tip: Tap the emoji field to open the emoji keyboard and select any emoji you want!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Add Behavior")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addBehavior()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.isEmpty || points == 0 || emoji.isEmpty)
                }
            }
        }
    }
    
    private func addBehavior() {
        let behavior = Behavior(
            name: name,
            category: category,
            emoji: String(emoji.prefix(1)), // Ensure only one emoji
            points: isNegative ? -abs(points) : abs(points),
            isBuiltin: false
        )
        modelContext.insert(behavior)
        try? modelContext.save()
        dismiss()
    }
}
