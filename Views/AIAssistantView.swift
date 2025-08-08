import SwiftUI
import PhotosUI

enum AIAssistantMode {
    case generateGoals
    case modifyGoals
    case analyzeFood
}

struct AIAssistantView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @StateObject private var openAIService = OpenAIService.shared
    
    let mode: AIAssistantMode
    let currentGoal: Goal?
    
    @State private var inputText = ""
    @State private var selectedImage: UIImage?
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.secondary)
                
                Spacer()
                
                Text(headerTitle)
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
                    // Mode-specific content
                    switch mode {
                    case .generateGoals:
                        goalGenerationContent
                    case .modifyGoals:
                        goalModificationContent
                    case .analyzeFood:
                        foodAnalysisContent
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.lg)
                .padding(.bottom, 120) // Space for bottom input
            }
            
            // Bottom input area (chat-style)
            VStack(spacing: Spacing.sm) {
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, Spacing.lg)
                }
                
                HStack(spacing: Spacing.sm) {
                    if mode == .analyzeFood {
                        // Image picker button for food analysis
                        Menu {
                            Button("Take Photo") {
                                showingCamera = true
                            }
                            Button("Choose from Library") {
                                showingImagePicker = true
                            }
                        } label: {
                            Image(systemName: "camera.fill")
                                .foregroundColor(.accentColor)
                        }
                        .frame(width: 44, height: 44)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(Circle())
                    }
                    
                    TextField(placeholderText, text: $inputText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...4)
                    
                    Button(action: processRequest) {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "paperplane.fill")
                        }
                    }
                    .frame(width: 44, height: 44)
                    .background(canSubmit ? Color.accentColor : Color.gray)
                    .foregroundColor(.white)
                    .clipShape(Circle())
                    .disabled(!canSubmit)
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
        .sheet(isPresented: $showingImagePicker) {
            PhotosPicker("Select Photo", selection: Binding<PhotosPickerItem?>(
                get: { nil },
                set: { item in
                    Task {
                        if let item = item,
                           let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            await MainActor.run {
                                selectedImage = image
                            }
                        }
                    }
                }
            ))
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraImagePicker(image: $selectedImage, sourceType: .camera)
        }
    }
    
    private var headerTitle: String {
        switch mode {
        case .generateGoals: return "Set Goals"
        case .modifyGoals: return "Modify Goals"
        case .analyzeFood: return "Analyze Food"
        }
    }
    
    private var placeholderText: String {
        switch mode {
        case .generateGoals: return "Describe your health context and goals..."
        case .modifyGoals: return "How would you like to adjust your goals?"
        case .analyzeFood: return "Describe the food (optional)..."
        }
    }
    
    private var canSubmit: Bool {
        !isProcessing && (
            (!inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ||
            (mode == .analyzeFood && selectedImage != nil)
        )
    }
    
    @ViewBuilder
    private var goalGenerationContent: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Tell me about yourself")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Share your health context, activity level, and goals so I can create personalized macro targets for you.")
                .font(.body)
                .foregroundColor(.secondary)
            
            Text("Example: \"22 year old male, 180 lbs, moderately active, looking to build muscle\"")
                .font(.caption)
                .foregroundColor(Color.secondary)
                .italic()
                .padding(.top, Spacing.sm)
        }
    }
    
    @ViewBuilder
    private var goalModificationContent: some View {
        if let goal = currentGoal {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Current Goals")
                    .font(.title2)
                    .fontWeight(.bold)
                
                GoalSummaryView(goal: goal)
            }
        }
    }
    
    @ViewBuilder
    private var foodAnalysisContent: some View {
        VStack(spacing: Spacing.lg) {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            } else {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    Text("Take a photo or select from library")
                        .font(.title3)
                        .fontWeight(.medium)
                    
                    Text("I'll analyze the food and estimate macro content")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, Spacing.xl)
            }
        }
    }
    
    private func processRequest() {
        Task {
            isProcessing = true
            errorMessage = nil
            
            do {
                switch mode {
                case .generateGoals:
                    await generateGoals()
                case .modifyGoals:
                    await modifyGoals()
                case .analyzeFood:
                    await analyzeFood()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isProcessing = false
                }
            }
        }
    }
    
    private func generateGoals() async {
        do {
            let goalResponse = try await openAIService.generateGoals(for: inputText)
            
            let newGoal = Goal(
                date: goalResponse.date,
                kCals: goalResponse.kCals,
                proteinG: goalResponse.proteinG,
                carbsG: goalResponse.carbsG,
                fatG: goalResponse.fatG,
                fiberG: goalResponse.fiberG
            )
            
            await MainActor.run {
                DataManager.shared.saveGoal(newGoal)
                appState.currentGoal = newGoal
                isProcessing = false
                dismiss()
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isProcessing = false
            }
        }
    }
    
    private func modifyGoals() async {
        guard let currentGoal = currentGoal else {
            await MainActor.run {
                errorMessage = "No current goal found"
                isProcessing = false
            }
            return
        }
        
        do {
            let modifiedGoalResponse = try await openAIService.modifyGoals(
                currentGoal: currentGoal,
                userRequest: inputText
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
                DataManager.shared.saveGoal(newGoal)
                appState.currentGoal = newGoal
                isProcessing = false
                dismiss()
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isProcessing = false
            }
        }
    }
    
    private func analyzeFood() async {
        guard let image = selectedImage else {
            await MainActor.run {
                errorMessage = "Please select an image"
                isProcessing = false
            }
            return
        }
        
        do {
            let foodResponse = try await openAIService.analyzeFoodFromImage(
                image,
                description: inputText
            )
            
            let food = Food(
                foodName: foodResponse.foodName,
                servings: foodResponse.servings,
                kCals: foodResponse.kCals,
                proteinG: foodResponse.proteinG,
                carbsG: foodResponse.carbsG,
                fatG: foodResponse.fatG,
                fiberG: foodResponse.fiberG,
                photoData: image.jpegData(compressionQuality: 0.7)
            )
            
            await MainActor.run {
                DataManager.shared.saveFood(food)
                isProcessing = false
                dismiss()
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isProcessing = false
            }
        }
    }
}

// Helper view for image picking
struct CameraImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraImagePicker
        
        init(_ parent: CameraImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    AIAssistantView(mode: .generateGoals, currentGoal: nil)
        .environmentObject(AppState())
}