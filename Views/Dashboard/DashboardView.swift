import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var dataManager = DataManager.shared
    @State private var todaysFoods: [Food] = []
    @State private var currentGoal: Goal?
    @State private var showGoalEditor = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: Spacing.lg) {
                    // Header with date
                    HStack {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Today")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text(DateFormatter.dashboardDateFormatter.string(from: Date()))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: { showGoalEditor = true }) {
                            Image(systemName: "target")
                                .font(.title2)
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                    
                    if let goal = currentGoal {
                        // Macro overview rings
                        MacroRingsView(
                            currentMacros: calculateTotalMacros(),
                            targetMacros: goal
                        )
                        .padding(.horizontal, Spacing.lg)
                        
                        // Quick macro stats
                        MacroStatsGridView(
                            currentMacros: calculateTotalMacros(),
                            targetMacros: goal
                        )
                        .padding(.horizontal, Spacing.lg)
                        
                        // Recent foods
                        RecentFoodsSection(foods: todaysFoods)
                        
                        // AI suggestions (if there are foods logged)
                        if !todaysFoods.isEmpty {
                            AISuggestionsCard(
                                currentMacros: calculateTotalMacros(),
                                targetMacros: goal,
                                foods: todaysFoods
                            )
                            .padding(.horizontal, Spacing.lg)
                        }
                    } else {
                        // No goals set
                        NoGoalsView()
                            .padding(.horizontal, Spacing.lg)
                    }
                }
                .padding(.vertical, Spacing.lg)
            }
            .navigationBarHidden(true)
            .refreshable {
                loadData()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            loadData()
        }
        .sheet(isPresented: $showGoalEditor) {
            GoalEditorView(currentGoal: currentGoal)
                .environmentObject(appState)
        }
    }
    
    private func loadData() {
        todaysFoods = dataManager.getFoodsForDate(Date())
        currentGoal = dataManager.loadGoal()
        
        if currentGoal == nil {
            currentGoal = appState.currentGoal
        }
    }
    
    private func calculateTotalMacros() -> (calories: Double, protein: Double, carbs: Double, fat: Double, fiber: Double) {
        let totalCalories = todaysFoods.reduce(0) { $0 + $1.kCals }
        let totalProtein = todaysFoods.reduce(0) { $0 + $1.proteinG }
        let totalCarbs = todaysFoods.reduce(0) { $0 + $1.carbsG }
        let totalFat = todaysFoods.reduce(0) { $0 + $1.fatG }
        let totalFiber = todaysFoods.reduce(0) { $0 + $1.fiberG }
        
        return (totalCalories, totalProtein, totalCarbs, totalFat, totalFiber)
    }
}

// MARK: - Macro Rings View
struct MacroRingsView: View {
    let currentMacros: (calories: Double, protein: Double, carbs: Double, fat: Double, fiber: Double)
    let targetMacros: Goal
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Main calorie ring
            ZStack {
                Circle()
                    .stroke(MacroColors.calories.opacity(0.2), lineWidth: Size.progressRingThickness)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .trim(from: 0, to: calorieProgress)
                    .stroke(MacroColors.calories, style: StrokeStyle(lineWidth: Size.progressRingThickness, lineCap: .round))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 1.0, dampingFraction: 0.8), value: calorieProgress)
                
                VStack(spacing: Spacing.xs) {
                    Text("\(Int(currentMacros.calories))")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(MacroColors.calories)
                    
                    Text("/ \(Int(targetMacros.kCals)) kcal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Smaller macro rings
            HStack(spacing: Spacing.lg) {
                SmallMacroRing(
                    title: "Protein",
                    current: currentMacros.protein,
                    target: targetMacros.proteinG,
                    color: MacroColors.protein,
                    unit: "g"
                )
                
                SmallMacroRing(
                    title: "Carbs", 
                    current: currentMacros.carbs,
                    target: targetMacros.carbsG,
                    color: MacroColors.carbs,
                    unit: "g"
                )
                
                SmallMacroRing(
                    title: "Fat",
                    current: currentMacros.fat,
                    target: targetMacros.fatG,
                    color: MacroColors.fat,
                    unit: "g"
                )
            }
        }
        .padding(Spacing.lg)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(CornerRadius.lg)
    }
    
    private var calorieProgress: CGFloat {
        guard targetMacros.kCals > 0 else { return 0 }
        return CGFloat(min(currentMacros.calories / targetMacros.kCals, 1.0))
    }
}

struct SmallMacroRing: View {
    let title: String
    let current: Double
    let target: Double
    let color: Color
    let unit: String
    
    var body: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.8, dampingFraction: 0.8), value: progress)
                
                Text("\(Int(current))")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private var progress: CGFloat {
        guard target > 0 else { return 0 }
        return CGFloat(min(current / target, 1.0))
    }
}

// MARK: - Macro Stats Grid
struct MacroStatsGridView: View {
    let currentMacros: (calories: Double, protein: Double, carbs: Double, fat: Double, fiber: Double)
    let targetMacros: Goal
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: Spacing.md) {
            MacroStatCard(
                title: "Calories",
                current: Int(currentMacros.calories),
                target: Int(targetMacros.kCals),
                unit: "kcal",
                color: MacroColors.calories
            )
            
            MacroStatCard(
                title: "Protein",
                current: Int(currentMacros.protein),
                target: Int(targetMacros.proteinG),
                unit: "g",
                color: MacroColors.protein
            )
            
            MacroStatCard(
                title: "Carbs",
                current: Int(currentMacros.carbs),
                target: Int(targetMacros.carbsG),
                unit: "g",
                color: MacroColors.carbs
            )
            
            MacroStatCard(
                title: "Fat",
                current: Int(currentMacros.fat),
                target: Int(targetMacros.fatG),
                unit: "g",
                color: MacroColors.fat
            )
        }
    }
}

struct MacroStatCard: View {
    let title: String
    let current: Int
    let target: Int
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(percentage))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(percentage > 100 ? .orange : color)
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(current)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text("/ \(target) \(unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: Double(current), total: Double(target))
                .progressViewStyle(LinearProgressViewStyle(tint: color))
        }
        .padding(Spacing.md)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(CornerRadius.md)
    }
    
    private var percentage: Double {
        guard target > 0 else { return 0 }
        return (Double(current) / Double(target)) * 100
    }
}

// MARK: - Recent Foods Section
struct RecentFoodsSection: View {
    let foods: [Food]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Today's Foods")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                if !foods.isEmpty {
                    Text("\(foods.count) items")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, Spacing.lg)
            
            if foods.isEmpty {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "camera.badge.ellipsis")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("No foods logged today")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Tap the camera tab to add your first meal")
                        .font(.body)
                        .foregroundColor(Color.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.xl)
            } else {
                LazyVStack(spacing: Spacing.sm) {
                    ForEach(foods.sorted(by: { $0.timestamp > $1.timestamp })) { food in
                        FoodRowView(food: food)
                            .padding(.horizontal, Spacing.lg)
                    }
                }
            }
        }
    }
}

struct FoodRowView: View {
    let food: Food
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Food image or placeholder
            Group {
                if let photoData = food.photoData,
                   let image = UIImage(data: photoData) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Image(systemName: "photo")
                        .foregroundColor(.secondary)
                        .font(.title2)
                }
            }
            .frame(width: Size.foodImageSize, height: Size.foodImageSize)
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(CornerRadius.md)
            .clipped()
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(food.foodName)
                    .font(.headline)
                    .lineLimit(1)
                
                Text("\(food.servings.formatted(.number.precision(.fractionLength(1)))) serving\(food.servings != 1 ? "s" : "")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: Spacing.sm) {
                    Text("\(Int(food.kCals)) kcal")
                        .font(.caption)
                        .padding(.horizontal, Spacing.xs)
                        .padding(.vertical, 2)
                        .background(MacroColors.calories.opacity(0.2))
                        .foregroundColor(MacroColors.calories)
                        .cornerRadius(4)
                    
                    Text("\(Int(food.proteinG))g P")
                        .font(.caption)
                        .padding(.horizontal, Spacing.xs)
                        .padding(.vertical, 2)
                        .background(MacroColors.protein.opacity(0.2))
                        .foregroundColor(MacroColors.protein)
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            Text(DateFormatter.timeFormatter.string(from: food.timestamp))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(Spacing.md)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(CornerRadius.md)
    }
}

// MARK: - AI Suggestions Card
struct AISuggestionsCard: View {
    let currentMacros: (calories: Double, protein: Double, carbs: Double, fat: Double, fiber: Double)
    let targetMacros: Goal
    let foods: [Food]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Label("AI Insights", systemImage: "sparkles")
                    .font(.headline)
                    .foregroundColor(.accentColor)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: Spacing.sm) {
                if currentMacros.protein < targetMacros.proteinG * 0.8 {
                    SuggestionRow(
                        icon: "flame.fill",
                        text: "Consider adding more protein-rich foods",
                        color: MacroColors.protein
                    )
                }
                
                if currentMacros.fiber < targetMacros.fiberG * 0.6 {
                    SuggestionRow(
                        icon: "leaf.fill",
                        text: "Add more fiber with vegetables or whole grains",
                        color: MacroColors.fiber
                    )
                }
                
                if currentMacros.calories < targetMacros.kCals * 0.7 {
                    SuggestionRow(
                        icon: "exclamationmark.circle.fill",
                        text: "You're under your calorie goal - consider a healthy snack",
                        color: .orange
                    )
                }
                
                if foods.count >= 3 {
                    SuggestionRow(
                        icon: "checkmark.circle.fill",
                        text: "Great job logging your meals consistently!",
                        color: .green
                    )
                }
            }
        }
        .padding(Spacing.lg)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(CornerRadius.lg)
    }
}

struct SuggestionRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 16)
            
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

// MARK: - No Goals View
struct NoGoalsView: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "target")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: Spacing.md) {
                Text("No Goals Set")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Set up your macro goals to start tracking your progress")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Set Goals") {
                // This would trigger goal setup
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.vertical, Spacing.xxl)
    }
}

// MARK: - Date Formatter Extensions
extension DateFormatter {
    static let dashboardDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }()
    
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    DashboardView()
        .environmentObject(AppState())
}