import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentStep = 0
    @State private var apiKey = ""
    @State private var healthContext = ""
    @State private var isGeneratingGoals = false
    @State private var showPrivacyAlert = false
    @State private var agreedToPrivacy = false
    @State private var errorMessage: String?
    
    let steps = ["Welcome", "Privacy", "API Key", "Health Context", "Generate Goals"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                
                VStack(spacing: Spacing.lg) {
                    // Progress indicator
                    ProgressView(value: Double(currentStep), total: Double(steps.count - 1))
                        .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                        .padding(.horizontal, Spacing.lg)
                    
                    // Step content
                    TabView(selection: $currentStep) {
                        WelcomeStepView()
                            .tag(0)
                        
                        PrivacyStepView(agreedToPrivacy: $agreedToPrivacy)
                            .tag(1)
                        
                        APIKeyStepView(apiKey: $apiKey)
                            .tag(2)
                        
                        HealthContextStepView(healthContext: $healthContext)
                            .tag(3)
                        
                        GoalGenerationStepView(
                            isGeneratingGoals: $isGeneratingGoals,
                            healthContext: healthContext,
                            errorMessage: $errorMessage
                        )
                        .tag(4)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: AnimationDuration.standard), value: currentStep)
                    
                    // Navigation buttons
                    HStack {
                        if currentStep > 0 {
                            Button("Back") {
                                withAnimation {
                                    currentStep -= 1
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        Spacer()
                        
                        Button(currentStep == steps.count - 1 ? "Get Started" : "Next") {
                            handleNextButton()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!canProceed)
                    }
                    .padding(.horizontal, Spacing.lg)
                }
                .padding(.vertical, Spacing.lg)
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 0: return true
        case 1: return agreedToPrivacy
        case 2: return !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 3: return !healthContext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 4: return !isGeneratingGoals
        default: return false
        }
    }
    
    private func handleNextButton() {
        switch currentStep {
        case 0, 1:
            withAnimation {
                currentStep += 1
            }
        case 2:
            saveAPIKey()
        case 3:
            withAnimation {
                currentStep += 1
            }
        case 4:
            // This is handled in GoalGenerationStepView
            break
        default:
            break
        }
    }
    
    private func saveAPIKey() {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if KeychainManager.shared.saveAPIKey(trimmedKey) {
            appState.hasAPIKey = true
            withAnimation {
                currentStep += 1
            }
        } else {
            errorMessage = "Failed to save API key. Please try again."
        }
    }
}

// MARK: - Welcome Step
struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            
            Image(systemName: "camera.aperture")
                .font(.system(size: 80, weight: .thin))
                .foregroundColor(.accentColor)
            
            VStack(spacing: Spacing.md) {
                Text("MacroTracker")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Smart macro tracking with AI-powered food analysis")
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
    }
}

// MARK: - Privacy Step
struct PrivacyStepView: View {
    @Binding var agreedToPrivacy: Bool
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            VStack(spacing: Spacing.md) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)
                
                Text("Privacy First")
                    .font(.title)
                    .fontWeight(.bold)
            }
            
            VStack(alignment: .leading, spacing: Spacing.md) {
                PrivacyPointView(
                    icon: "checkmark.circle.fill",
                    title: "Local Storage",
                    description: "All your data is stored locally on your device"
                )
                
                PrivacyPointView(
                    icon: "icloud.fill", 
                    title: "iCloud Sync",
                    description: "Optional backup to your private iCloud"
                )
                
                PrivacyPointView(
                    icon: "exclamationmark.triangle.fill",
                    title: "AI Analysis",
                    description: "Photos are sent to OpenAI for food analysis only"
                )
                
                PrivacyPointView(
                    icon: "key.fill",
                    title: "Your API Key",
                    description: "We use your OpenAI API key, securely stored in Keychain"
                )
            }
            
            Toggle("I understand and agree to these privacy terms", isOn: $agreedToPrivacy)
                .padding(.top, Spacing.lg)
            
            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
    }
}

struct PrivacyPointView: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - API Key Step
struct APIKeyStepView: View {
    @Binding var apiKey: String
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            VStack(spacing: Spacing.md) {
                Image(systemName: "key.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)
                
                Text("OpenAI API Key")
                    .font(.title)
                    .fontWeight(.bold)
            }
            
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Enter your OpenAI API key to enable AI-powered food analysis")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Link("Get your API key from OpenAI", destination: URL(string: "https://platform.openai.com/api-keys")!)
                    .font(.caption)
                    .foregroundColor(.accentColor)
            }
            
            SecureField("sk-...", text: $apiKey)
                .textFieldStyle(.roundedBorder)
                .font(.monospaced(.body)())
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Label("Securely stored in iOS Keychain", systemImage: "lock.fill")
                Label("Never shared or transmitted except to OpenAI", systemImage: "shield.fill")
                Label("You can change this anytime in Settings", systemImage: "gearshape.fill")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
    }
}

// MARK: - Health Context Step
struct HealthContextStepView: View {
    @Binding var healthContext: String
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            VStack(spacing: Spacing.md) {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)
                
                Text("Health Context")
                    .font(.title)
                    .fontWeight(.bold)
            }
            
            Text("Help us create personalized macro goals by sharing some basic health information")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Example: 22 year old male, 180 lbs, moderately active, looking to build muscle")
                    .font(.caption)
                    .foregroundColor(Color.secondary)
                    .italic()
            }
            
            TextEditor(text: $healthContext)
                .frame(minHeight: 120)
                .padding(Spacing.sm)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(Color(.separator), lineWidth: 1)
                )
            
            Text("\(healthContext.count)/\(ValidationLimits.maxHealthContextLength)")
                .font(.caption)
                .foregroundColor(healthContext.count > ValidationLimits.maxHealthContextLength ? .red : .secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
            
            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
    }
}

// MARK: - Goal Generation Step
struct GoalGenerationStepView: View {
    @EnvironmentObject var appState: AppState
    @Binding var isGeneratingGoals: Bool
    let healthContext: String
    @Binding var errorMessage: String?
    
    @State private var generatedGoal: Goal?
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            if isGeneratingGoals {
                VStack(spacing: Spacing.lg) {
                    ProgressView()
                        .scaleEffect(2.0)
                    
                    Text("Generating Your Goals")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("AI is analyzing your health context to create personalized macro goals...")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            } else if let goal = generatedGoal {
                VStack(spacing: Spacing.lg) {
                    Text("Your Daily Goals")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    GoalSummaryView(goal: goal)
                    
                    Button("Looks Good!") {
                        let user = User(healthContext: healthContext)
                        appState.completeOnboarding(user: user, goal: goal)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            } else {
                VStack(spacing: Spacing.lg) {
                    Image(systemName: "target")
                        .font(.system(size: 60))
                        .foregroundColor(.accentColor)
                    
                    Text("Ready to Generate Goals")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("We'll create personalized macro goals based on your health information")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.body)
                            .foregroundColor(.red)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(CornerRadius.md)
                    }
                    
                    Button("Generate My Goals") {
                        Task {
                            await generateGoals()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
    }
    
    private func generateGoals() async {
        isGeneratingGoals = true
        errorMessage = nil
        
        do {
            let goalResponse = try await OpenAIService.shared.generateGoals(for: healthContext)
            let goal = Goal(
                date: goalResponse.date,
                kCals: goalResponse.kCals,
                proteinG: goalResponse.proteinG,
                carbsG: goalResponse.carbsG,
                fatG: goalResponse.fatG,
                fiberG: goalResponse.fiberG
            )
            
            await MainActor.run {
                self.generatedGoal = goal
                self.isGeneratingGoals = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isGeneratingGoals = false
            }
        }
    }
}

struct GoalSummaryView: View {
    let goal: Goal
    
    var body: some View {
        VStack(spacing: Spacing.md) {
            HStack {
                MacroSummaryCard(
                    title: "Calories", 
                    value: "\(Int(goal.kCals))",
                    unit: "kcal",
                    color: MacroColors.calories
                )
                
                MacroSummaryCard(
                    title: "Protein",
                    value: "\(Int(goal.proteinG))",
                    unit: "g",
                    color: MacroColors.protein
                )
            }
            
            HStack {
                MacroSummaryCard(
                    title: "Carbs",
                    value: "\(Int(goal.carbsG))",
                    unit: "g", 
                    color: MacroColors.carbs
                )
                
                MacroSummaryCard(
                    title: "Fat",
                    value: "\(Int(goal.fatG))",
                    unit: "g",
                    color: MacroColors.fat
                )
            }
            
            MacroSummaryCard(
                title: "Fiber",
                value: "\(Int(goal.fiberG))",
                unit: "g",
                color: MacroColors.fiber
            )
            .frame(maxWidth: .infinity)
        }
    }
}

struct MacroSummaryCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: Spacing.xs) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.md)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(CornerRadius.md)
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}