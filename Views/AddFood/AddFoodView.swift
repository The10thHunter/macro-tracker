import SwiftUI
import PhotosUI

struct AddFoodView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var openAIService = OpenAIService.shared
    @StateObject private var dataManager = DataManager.shared
    
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var foodDescription = ""
    @State private var isAnalyzing = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: Spacing.md) {
                Text("Add Food")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Analyze your food to track macros")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.xl)
            .padding(.bottom, Spacing.lg)
            
            // Content
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Image area - simplified with action buttons integrated
                    VStack(spacing: Spacing.md) {
                        ZStack {
                            RoundedRectangle(cornerRadius: CornerRadius.xl)
                                .fill(Color(.secondarySystemBackground))
                                .frame(height: 280)
                                .overlay(
                                    RoundedRectangle(cornerRadius: CornerRadius.xl)
                                        .strokeBorder(
                                            LinearGradient(
                                                colors: [Color.accentColor.opacity(0.3), Color.accentColor.opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2
                                        )
                                )
                            
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 280)
                                    .clipped()
                                    .cornerRadius(CornerRadius.xl)
                                    .overlay(
                                        // Overlay with retake button
                                        VStack {
                                            HStack {
                                                Spacer()
                                                Button(action: { showImageOptions() }) {
                                                    Image(systemName: "camera.rotate")
                                                        .font(.system(size: 16, weight: .semibold))
                                                        .foregroundColor(.white)
                                                        .padding(Spacing.sm)
                                                        .background(Color.black.opacity(0.6))
                                                        .clipShape(Circle())
                                                }
                                                .padding(Spacing.md)
                                            }
                                            Spacer()
                                        }
                                    )
                            } else {
                                VStack(spacing: Spacing.lg) {
                                    Image(systemName: "camera.viewfinder")
                                        .font(.system(size: 50))
                                        .foregroundColor(.accentColor)
                                    
                                    VStack(spacing: Spacing.sm) {
                                        Text("Add Photo")
                                            .font(.title2)
                                            .fontWeight(.semibold)
                                        
                                        Text("Take a photo or choose from library")
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                    }
                                    
                                    // Action buttons integrated into empty state
                                    HStack(spacing: Spacing.md) {
                                        Button(action: { showingCamera = true }) {
                                            HStack(spacing: Spacing.xs) {
                                                Image(systemName: "camera.fill")
                                                    .font(.system(size: 16, weight: .medium))
                                                    .foregroundColor(.white)
                                                Text("Camera")
                                                    .font(.body)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.white)
                                            }
                                            .padding(.horizontal, Spacing.lg)
                                            .padding(.vertical, Spacing.md)
                                            .background(isAnalyzing ? Color.gray : Color.accentColor)
                                            .clipShape(Capsule())
                                        }
                                        .disabled(isAnalyzing)
                                        
                                        Button(action: { showingImagePicker = true }) {
                                            HStack(spacing: Spacing.xs) {
                                                Image(systemName: "photo.on.rectangle")
                                                    .font(.system(size: 16, weight: .medium))
                                                    .foregroundColor(.primary)
                                                Text("Photos")
                                                    .font(.body)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.primary)
                                            }
                                            .padding(.horizontal, Spacing.lg)
                                            .padding(.vertical, Spacing.md)
                                            .background(isAnalyzing ? Color(.quaternarySystemFill) : Color(.tertiarySystemBackground))
                                            .clipShape(Capsule())
                                        }
                                        .disabled(isAnalyzing)
                                    }
                                }
                            }
                        }
                        .animation(.easeInOut(duration: 0.3), value: selectedImage != nil)
                    }
                    .padding(.horizontal, Spacing.lg)
                }
                .padding(.bottom, 120) // Space for bottom input
                .contentShape(Rectangle())
                .onTapGesture {
                    dismissKeyboard()
                }
            }
            
            // Bottom area with text input (chat style)
            VStack(spacing: Spacing.sm) {
                if let error = errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.body)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(CornerRadius.md)
                    .padding(.horizontal, Spacing.lg)
                }
                
                HStack(spacing: Spacing.sm) {
                    // Custom styled text field
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "text.bubble")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                        
                        TextField("Add context (optional)", text: $foodDescription, axis: .vertical)
                            .font(.body)
                            .lineLimit(1...3)
                            .disabled(isAnalyzing)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(CornerRadius.lg)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.lg)
                            .strokeBorder(Color(.separator), lineWidth: 1)
                    )
                    
                    // Analyze button
                    Button(action: analyzeFood) {
                        Group {
                            if isAnalyzing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                        }
                        .frame(width: 44, height: 44)
                        .background(canAnalyze ? Color.accentColor : Color.gray)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                    }
                    .disabled(!canAnalyze)
                    .animation(.easeInOut(duration: 0.2), value: canAnalyze)
                }
                .padding(.horizontal, Spacing.lg)
            }
            .padding(.vertical, Spacing.md)
            .background(
                Color(.systemBackground)
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: -5)
            )
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(.separator)),
                alignment: .top
            )
        }
        .sheet(isPresented: $showingImagePicker) {
            AddFoodImagePicker(image: $selectedImage, sourceType: .photoLibrary)
        }
        .fullScreenCover(isPresented: $showingCamera) {
            AddFoodImagePicker(image: $selectedImage, sourceType: .camera)
        }
    }
    
    private var canAnalyze: Bool {
        selectedImage != nil && !isAnalyzing
    }
    
    private func showImageOptions() {
        let alert = UIAlertController(title: "Change Photo", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Take Photo", style: .default) { _ in
            showingCamera = true
        })
        
        alert.addAction(UIAlertAction(title: "Choose from Library", style: .default) { _ in
            showingImagePicker = true
        })
        
        alert.addAction(UIAlertAction(title: "Remove Photo", style: .destructive) { _ in
            selectedImage = nil
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }
    
    private func analyzeFood() {
        guard let image = selectedImage else { return }
        
        Task {
            isAnalyzing = true
            errorMessage = nil
            
            do {
                let foodResponse = try await openAIService.analyzeFoodFromImage(
                    image, 
                    description: foodDescription
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
                    dataManager.saveFood(food)
                    resetForm()
                    isAnalyzing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Analysis failed: \(error.localizedDescription)"
                    isAnalyzing = false
                }
            }
        }
    }
    
    private func resetForm() {
        selectedImage = nil
        foodDescription = ""
        errorMessage = nil
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Image Picker
struct AddFoodImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: AddFoodImagePicker
        
        init(_ parent: AddFoodImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    AddFoodView()
        .environmentObject(AppState())
}