import SwiftUI

struct TrendsView: View {
    @StateObject private var dataManager = DataManager.shared
    @State private var selectedTimeRange: TimeRange = .week
    @State private var foods: [Food] = []
    @State private var currentGoal: Goal?
    
    enum TimeRange: String, CaseIterable {
        case week = "7D"
        case month = "30D"
        case threeMonths = "3M"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .threeMonths: return 90
            }
        }
        
        var title: String {
            switch self {
            case .week: return "This Week"
            case .month: return "This Month"
            case .threeMonths: return "3 Months"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: Spacing.lg) {
                    // Time range selector
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, Spacing.lg)
                    
                    if !foods.isEmpty {
                        // Simple stats cards instead of charts
                        SimpleStatsView(foods: filteredFoods, goal: currentGoal, timeRange: selectedTimeRange)
                            .padding(.horizontal, Spacing.lg)
                        
                        // Average macros card
                        AverageMacrosCard(foods: filteredFoods, goal: currentGoal)
                            .padding(.horizontal, Spacing.lg)
                        
                        // Consistency metrics
                        ConsistencyMetricsCard(foods: filteredFoods, timeRange: selectedTimeRange)
                            .padding(.horizontal, Spacing.lg)
                        
                    } else {
                        // Empty state
                        VStack(spacing: Spacing.lg) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)
                            
                            VStack(spacing: Spacing.md) {
                                Text("No Data Yet")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text("Start logging foods to see your trends and insights")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.vertical, Spacing.xxl)
                    }
                }
                .padding(.vertical, Spacing.lg)
            }
            .navigationTitle("Trends")
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            loadData()
        }
        .onChange(of: selectedTimeRange) { _ in
            loadData()
        }
    }
    
    private var filteredFoods: [Food] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -selectedTimeRange.days, to: Date()) ?? Date()
        return foods.filter { $0.timestamp >= cutoffDate }
    }
    
    private func loadData() {
        foods = dataManager.loadFoods()
        currentGoal = dataManager.loadGoal()
    }
}

// MARK: - Simple Stats View (replaces complex charts)
struct SimpleStatsView: View {
    let foods: [Food]
    let goal: Goal?
    let timeRange: TrendsView.TimeRange
    
    private var totalMacros: (calories: Double, protein: Double, carbs: Double, fat: Double, fiber: Double) {
        let totalCalories = foods.reduce(0) { $0 + $1.kCals }
        let totalProtein = foods.reduce(0) { $0 + $1.proteinG }
        let totalCarbs = foods.reduce(0) { $0 + $1.carbsG }
        let totalFat = foods.reduce(0) { $0 + $1.fatG }
        let totalFiber = foods.reduce(0) { $0 + $1.fiberG }
        
        return (totalCalories, totalProtein, totalCarbs, totalFat, totalFiber)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Period Totals")
                .font(.title2)
                .fontWeight(.bold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: Spacing.md) {
                StatCard(
                    title: "Total Calories",
                    value: "\(Int(totalMacros.calories))",
                    unit: "kcal",
                    color: MacroColors.calories
                )
                
                StatCard(
                    title: "Avg Daily",
                    value: "\(Int(totalMacros.calories / Double(max(timeRange.days, 1))))",
                    unit: "kcal/day",
                    color: MacroColors.calories
                )
                
                StatCard(
                    title: "Total Protein",
                    value: "\(Int(totalMacros.protein))",
                    unit: "g",
                    color: MacroColors.protein
                )
                
                StatCard(
                    title: "Total Carbs",
                    value: "\(Int(totalMacros.carbs))",
                    unit: "g",
                    color: MacroColors.carbs
                )
            }
            
            // Simple macro distribution
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Macro Distribution")
                    .font(.headline)
                
                HStack(spacing: 0) {
                    let total = totalMacros.protein + totalMacros.carbs + totalMacros.fat
                    if total > 0 {
                        Rectangle()
                            .fill(MacroColors.protein)
                            .frame(width: CGFloat(totalMacros.protein / total) * 250)
                        
                        Rectangle()
                            .fill(MacroColors.carbs)
                            .frame(width: CGFloat(totalMacros.carbs / total) * 250)
                        
                        Rectangle()
                            .fill(MacroColors.fat)
                            .frame(width: CGFloat(totalMacros.fat / total) * 250)
                    }
                }
                .frame(height: 20)
                .cornerRadius(10)
                
                HStack {
                    MacroLabel(color: MacroColors.protein, text: "Protein")
                    MacroLabel(color: MacroColors.carbs, text: "Carbs")
                    MacroLabel(color: MacroColors.fat, text: "Fat")
                }
            }
        }
        .padding(Spacing.lg)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(CornerRadius.lg)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(CornerRadius.md)
    }
}

struct MacroLabel: View {
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: Spacing.xs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Average Macros Card
struct AverageMacrosCard: View {
    let foods: [Food]
    let goal: Goal?
    
    private var averages: (calories: Double, protein: Double, carbs: Double, fat: Double, fiber: Double) {
        guard !foods.isEmpty else { return (0, 0, 0, 0, 0) }
        
        let totalCalories = foods.reduce(0) { $0 + $1.kCals }
        let totalProtein = foods.reduce(0) { $0 + $1.proteinG }
        let totalCarbs = foods.reduce(0) { $0 + $1.carbsG }
        let totalFat = foods.reduce(0) { $0 + $1.fatG }
        let totalFiber = foods.reduce(0) { $0 + $1.fiberG }
        
        let uniqueDays = Set(foods.map { Calendar.current.startOfDay(for: $0.timestamp) })
        let dayCount = Double(uniqueDays.count)
        
        return (
            totalCalories / dayCount,
            totalProtein / dayCount,
            totalCarbs / dayCount,
            totalFat / dayCount,
            totalFiber / dayCount
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Daily Averages")
                .font(.title2)
                .fontWeight(.bold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: Spacing.md) {
                AverageStatView(
                    title: "Calories",
                    average: Int(averages.calories),
                    target: goal != nil ? Int(goal!.kCals) : nil,
                    unit: "kcal",
                    color: MacroColors.calories
                )
                
                AverageStatView(
                    title: "Protein",
                    average: Int(averages.protein),
                    target: goal != nil ? Int(goal!.proteinG) : nil,
                    unit: "g",
                    color: MacroColors.protein
                )
                
                AverageStatView(
                    title: "Carbs",
                    average: Int(averages.carbs),
                    target: goal != nil ? Int(goal!.carbsG) : nil,
                    unit: "g",
                    color: MacroColors.carbs
                )
                
                AverageStatView(
                    title: "Fat",
                    average: Int(averages.fat),
                    target: goal != nil ? Int(goal!.fatG) : nil,
                    unit: "g",
                    color: MacroColors.fat
                )
            }
        }
        .padding(Spacing.lg)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(CornerRadius.lg)
    }
}

struct AverageStatView: View {
    let title: String
    let average: Int
    let target: Int?
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(average)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let target = target {
                Text("Goal: \(target) \(unit)")
                    .font(.caption2)
                    .foregroundColor(Color.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.sm)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(CornerRadius.sm)
    }
}

// MARK: - Consistency Metrics Card
struct ConsistencyMetricsCard: View {
    let foods: [Food]
    let timeRange: TrendsView.TimeRange
    
    private var metrics: (daysLogged: Int, totalDays: Int, averageMealsPerDay: Double, streak: Int) {
        guard !foods.isEmpty else { return (0, timeRange.days, 0.0, 0) }
        
        let uniqueDays = Set(foods.map { Calendar.current.startOfDay(for: $0.timestamp) })
        let daysLogged = uniqueDays.count
        let averageMeals = Double(foods.count) / Double(daysLogged)
        
        // Calculate current streak
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var checkDate = today
        
        while uniqueDays.contains(checkDate) && streak < 365 { // Max streak of 1 year
            streak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }
        
        return (daysLogged, timeRange.days, averageMeals, streak)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Consistency")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: Spacing.md) {
                HStack {
                    ConsistencyStatView(
                        title: "Days Logged",
                        value: "\(metrics.daysLogged)/\(metrics.totalDays)",
                        subtitle: "\(Int((Double(metrics.daysLogged) / Double(metrics.totalDays)) * 100))%",
                        icon: "calendar.badge.checkmark"
                    )
                    
                    ConsistencyStatView(
                        title: "Avg Meals/Day",
                        value: String(format: "%.1f", metrics.averageMealsPerDay),
                        subtitle: "meals",
                        icon: "fork.knife"
                    )
                }
                
                HStack {
                    ConsistencyStatView(
                        title: "Current Streak",
                        value: "\(metrics.streak)",
                        subtitle: "days",
                        icon: "flame.fill"
                    )
                    
                    ConsistencyStatView(
                        title: "Total Entries",
                        value: "\(foods.count)",
                        subtitle: "foods",
                        icon: "list.bullet"
                    )
                }
            }
        }
        .padding(Spacing.lg)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(CornerRadius.lg)
    }
}

struct ConsistencyStatView: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(Color.secondary)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.sm)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(CornerRadius.sm)
    }
}

#Preview {
    TrendsView()
}