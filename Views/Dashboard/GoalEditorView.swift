import SwiftUI

struct GoalEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @StateObject private var openAIService = OpenAIService.shared
    
    let currentGoal: Goal?
    
    @State private var modificationRequest = ""
    @State private var isModifying = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Edit Goals")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Placeholder for symmetry
                Text("Cancel")
                    .foregroundColor(.clear)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(Color(.systemBackground))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(.separator)),
                alignment: .bottom
            )
            
            // Content
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    if let goal = currentGoal {
                        // Current goals display
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text("Current Goals")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            GoalSummaryView(goal: goal)
                        }
                    } else {
                        // No current goals
                        VStack(spacing: Spacing.lg) {
                            Image(systemName: "target")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)
                            
                            VStack(spacing: Spacing.md) {
                                Text("No Goals Set")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text("Complete onboarding to set up your initial goals")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.vertical, Spacing.xl)
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.lg)
                .padding(.bottom, 120) // Space for bottom input
            }
            
            // Bottom input area (chat-style)
            if currentGoal != nil {
                VStack(spacing: Spacing.sm) {
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, Spacing.lg)
                    }
                    
                    HStack(spacing: Spacing.sm) {
                        TextField("Describe how to adjust your goals...", text: $modificationRequest, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(1...4)
                        
                        Button(action: modifyGoals) {
                            if isModifying {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "paperplane.fill")
                            }
                        }
                        .frame(width: 44, height: 44)
                        .background(modificationRequest.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isModifying ? Color.gray : Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                        .disabled(modificationRequest.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isModifying)
                    }
                    .padding(.horizontal, Spacing.lg)
                }
                .padding(.vertical, Spacing.md)
                .background(Color(.systemBackground))
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color(.separator)),
                    alignment: .top
                )
            }
        }
    }
    
    private func modifyGoals() {
        guard let currentGoal = currentGoal else { return }
        
        Task {
            isModifying = true
            errorMessage = nil
            
            do {
                let modifiedGoalResponse = try await openAIService.modifyGoals(
                    currentGoal: currentGoal,
                    userRequest: modificationRequest
                )
                
                let newGoal = Goal(
                    date: modifiedGoalResponse.date,
                    kCals: modifiedGoalResponse.kCals,
                    proteinG: modifiedGoalResponse.proteinG,
                    carbsG: modifiedGoalResponse.carbsG,
                    fatG: modifiedGoalResponse.fatG,
                    fiberG: modifiedGoalResponse.fiberG
                )
                
                await MainActor.run {
                    // Save the new goal
                    DataManager.shared.saveGoal(newGoal)
                    appState.currentGoal = newGoal
                    
                    // Clear the form
                    modificationRequest = ""
                    isModifying = false
                    
                    // Dismiss the sheet
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isModifying = false
                }
            }
        }
    }
}

#Preview {
    let sampleGoal = Goal(
        date: "2024-01-01",
        kCals: 2200,
        proteinG: 150,
        carbsG: 250,
        fatG: 80,
        fiberG: 30
    )
    
    return GoalEditorView(currentGoal: sampleGoal)
        .environmentObject(AppState())
}