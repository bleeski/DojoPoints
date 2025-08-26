import SwiftUI
import SwiftData

struct BehaviorsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Behavior.name) private var behaviors: [Behavior]
    
    @State private var showingAddBehavior = false
    
    private var groupedBehaviors: [(BehaviorCategory, [Behavior])] {
        Dictionary(grouping: behaviors, by: { $0.category })
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .map { ($0.key, $0.value) }
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
    
    let availableEmojis = ["⭐", "🎯", "🏆", "💎", "🎨", "🎭", "🎪", "🎸", "🎹", "🎮", "🧩", "🎲", "🏀", "⚽", "🏈", "🎾", "🥋", "🏹", "🎣", "🛹"]
    
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
                        }
                        
                        TextField("1", value: $points, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section("Icon") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 12) {
                        ForEach(availableEmojis, id: \.self) { icon in
                            Button(action: { emoji = icon }) {
                                Text(icon)
                                    .font(.system(size: 30))
                                    .frame(width: 50, height: 50)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(emoji == icon ? category.color.opacity(0.2) : Color.gray.opacity(0.1))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(emoji == icon ? category.color : Color.clear, lineWidth: 2)
                                            )
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
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
                    .disabled(name.isEmpty || points == 0)
                }
            }
        }
    }
    
    private func addBehavior() {
        let behavior = Behavior(
            name: name,
            category: category,
            emoji: emoji,
            points: isNegative ? -points : points,
            isBuiltin: false
        )
        modelContext.insert(behavior)
        try? modelContext.save()
        dismiss()
    }
}
