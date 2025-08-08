import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var dataManager = DataManager.shared
    
    @State private var apiKey = ""
    @State private var showingAPIKeyEditor = false
    @State private var showingDataExport = false
    @State private var showingResetAlert = false
    @State private var showingAbout = false
    
    var body: some View {
        NavigationView {
            List {
                // User Profile Section
                Section("Profile") {
                    if let user = appState.currentUser {
                        NavigationLink(destination: ProfileEditView(user: user)) {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .foregroundColor(.accentColor)
                                    .font(.title2)
                                
                                VStack(alignment: .leading, spacing: Spacing.xs) {
                                    Text("Health Profile")
                                        .font(.headline)
                                    
                                    Text("Tap to edit your health context")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                
                // API Configuration
                Section("OpenAI Configuration") {
                    Button(action: { showingAPIKeyEditor = true }) {
                        HStack {
                            Image(systemName: "key.fill")
                                .foregroundColor(.accentColor)
                            
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text("API Key")
                                    .foregroundColor(.primary)
                                
                                Text(appState.hasAPIKey ? "••••••••••••••••" : "Not configured")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if appState.hasAPIKey {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
                
                // Preferences
                Section("Preferences") {
                    
                    HStack {
                        Image(systemName: "icloud.fill")
                            .foregroundColor(.accentColor)
                        
                        Text("iCloud Sync")
                        
                        Spacer()
                        
                        Toggle("", isOn: .constant(true))
                            .labelsHidden()
                    }
                }
                
                // Data Management
                Section("Data") {
                    Button(action: { showingDataExport = true }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.accentColor)
                            
                            Text("Export Data")
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Button(action: { showingResetAlert = true }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            
                            Text("Reset All Data")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // Privacy & Support
                Section("Privacy & Support") {
                    NavigationLink(destination: PrivacyPolicyView()) {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                                .foregroundColor(.accentColor)
                            
                            Text("Privacy Policy")
                        }
                    }
                    
                    Button(action: { showingAbout = true }) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.accentColor)
                            
                            Text("About MacroTracker")
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            loadAPIKeyStatus()
        }
        .sheet(isPresented: $showingAPIKeyEditor) {
            APIKeyEditorView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showingDataExport) {
            DataExportView()
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .alert("Reset All Data", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetAllData()
            }
        } message: {
            Text("This will permanently delete all your food entries, goals, and user data. This action cannot be undone.")
        }
    }
    
    private func loadAPIKeyStatus() {
        appState.hasAPIKey = KeychainManager.shared.getAPIKey() != nil
    }
    
    private func resetAllData() {
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: "onboardingComplete")
        UserDefaults.standard.removeObject(forKey: "currentUser")
        UserDefaults.standard.removeObject(forKey: "currentGoal")
        UserDefaults.standard.removeObject(forKey: "savedFoods")
        
        // Clear Keychain
        KeychainManager.shared.deleteAPIKey()
        
        // Reset app state
        appState.isOnboardingComplete = false
        appState.hasAPIKey = false
        appState.currentUser = nil
        appState.currentGoal = nil
    }
}

// MARK: - API Key Editor
struct APIKeyEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    
    @State private var apiKey = ""
    @State private var showingKey = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
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
                    Text("Your API key is securely stored in iOS Keychain and only used to communicate with OpenAI for food analysis.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Link("Get your API key from OpenAI", destination: URL(string: "https://platform.openai.com/api-keys")!)
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
                
                VStack(spacing: Spacing.md) {
                    HStack {
                        if showingKey {
                            TextField("sk-...", text: $apiKey)
                                .textFieldStyle(.roundedBorder)
                                .font(.monospaced(.body)())
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        } else {
                            SecureField("sk-...", text: $apiKey)
                                .textFieldStyle(.roundedBorder)
                                .font(.monospaced(.body)())
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        
                        Button(action: { showingKey.toggle() }) {
                            Image(systemName: showingKey ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if appState.hasAPIKey {
                        Button("Remove Current Key") {
                            removeAPIKey()
                        }
                        .foregroundColor(.red)
                    }
                }
                
                if let error = errorMessage {
                    Text(error)
                        .font(.body)
                        .foregroundColor(.red)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(CornerRadius.md)
                }
                
                Spacer()
            }
            .padding(Spacing.lg)
            .navigationTitle("API Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveAPIKey()
                    }
                    .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            if let existingKey = KeychainManager.shared.getAPIKey() {
                apiKey = existingKey
            }
        }
    }
    
    private func saveAPIKey() {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if KeychainManager.shared.saveAPIKey(trimmedKey) {
            appState.hasAPIKey = true
            dismiss()
        } else {
            errorMessage = "Failed to save API key. Please try again."
        }
    }
    
    private func removeAPIKey() {
        if KeychainManager.shared.deleteAPIKey() {
            appState.hasAPIKey = false
            apiKey = ""
            dismiss()
        } else {
            errorMessage = "Failed to remove API key. Please try again."
        }
    }
}

// MARK: - Profile Edit View
struct ProfileEditView: View {
    let user: User
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @StateObject private var dataManager = DataManager.shared
    
    @State private var healthContext: String
    @State private var hasChanges = false
    
    init(user: User) {
        self.user = user
        self._healthContext = State(initialValue: user.healthContext)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: Spacing.lg) {
                Text("Update your health context to help AI provide better macro recommendations")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                TextEditor(text: $healthContext)
                    .frame(minHeight: 200)
                    .padding(Spacing.sm)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(CornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(Color(.separator), lineWidth: 1)
                    )
                    .onChange(of: healthContext) { _ in
                        hasChanges = true
                    }
                
                Text("\(healthContext.count)/\(ValidationLimits.maxHealthContextLength)")
                    .font(.caption)
                    .foregroundColor(healthContext.count > ValidationLimits.maxHealthContextLength ? .red : .secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                
                Spacer()
            }
            .padding(Spacing.lg)
            .navigationTitle("Health Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .disabled(!hasChanges)
                    .fontWeight(.semibold)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func saveProfile() {
        var updatedUser = user
        updatedUser.healthContext = healthContext
        
        dataManager.saveUser(updatedUser)
        appState.currentUser = updatedUser
        
        dismiss()
    }
}

// MARK: - Data Export View
struct DataExportView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var dataManager = DataManager.shared
    
    @State private var exportData = ""
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: Spacing.lg) {
                Text("Export your data as JSON for backup or analysis")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                ScrollView {
                    Text(exportData.isEmpty ? "Generating export data..." : exportData)
                        .font(.caption)
                        .font(.monospaced(.caption)())
                        .padding(Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(CornerRadius.md)
                }
                .frame(maxHeight: 400)
                
                Button("Share Export") {
                    showingShareSheet = true
                }
                .buttonStyle(.borderedProminent)
                .disabled(exportData.isEmpty)
            }
            .padding(Spacing.lg)
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            generateExportData()
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: [exportData])
        }
    }
    
    private func generateExportData() {
        let foods = dataManager.loadFoods()
        let goal = dataManager.loadGoal()
        let user = dataManager.loadUser()
        
        let exportDict: [String: Any] = [
            "export_date": ISO8601DateFormatter().string(from: Date()),
            "user": user?.healthContext ?? "",
            "current_goal": goal != nil ? [
                "calories": goal!.kCals,
                "protein": goal!.proteinG,
                "carbs": goal!.carbsG,
                "fat": goal!.fatG,
                "fiber": goal!.fiberG
            ] : [:],
            "foods": foods.map { food in
                [
                    "name": food.foodName,
                    "timestamp": ISO8601DateFormatter().string(from: food.timestamp),
                    "servings": food.servings,
                    "calories": food.kCals,
                    "protein": food.proteinG,
                    "carbs": food.carbsG,
                    "fat": food.fatG,
                    "fiber": food.fiberG
                ]
            }
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: exportDict, options: .prettyPrinted)
            exportData = String(data: jsonData, encoding: .utf8) ?? "Error generating export data"
        } catch {
            exportData = "Error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Privacy Policy View
struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text("Privacy Policy")
                    .font(.title)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("Data Collection")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("MacroTracker collects minimal data necessary for functionality:")
                    
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("• Health context you provide during onboarding")
                        Text("• Food photos and descriptions you submit for analysis")
                        Text("• Macro tracking data (foods logged, goals set)")
                        Text("• App preferences and settings")
                    }
                    .font(.body)
                }
                
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("Data Storage")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Your data is stored locally on your device and optionally synced to your private iCloud account. We do not store any data on external servers.")
                }
                
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("Third-Party Services")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("MacroTracker uses OpenAI's GPT-4o API for food analysis. When you analyze food photos:")
                    
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("• Photos are sent to OpenAI for analysis")
                        Text("• OpenAI processes the image and returns nutrition data")
                        Text("• OpenAI's privacy policy applies to this data transmission")
                        Text("• No photos are stored by OpenAI or MacroTracker beyond processing")
                    }
                    .font(.body)
                }
                
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("Your Rights")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("You can export or delete all your data at any time through the Settings page.")
                }
            }
            .padding(Spacing.lg)
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - About View
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: Spacing.xl) {
                Image(systemName: "camera.aperture")
                    .font(.system(size: 80, weight: .thin))
                    .foregroundColor(.accentColor)
                
                VStack(spacing: Spacing.md) {
                    Text("MacroTracker")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Version 1.0.0")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: Spacing.lg) {
                    Text("Smart macro tracking powered by AI")
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: Spacing.sm) {
                        Text("Built with:")
                            .font(.headline)
                        
                        VStack(spacing: Spacing.xs) {
                            Text("• SwiftUI & iOS")
                            Text("• OpenAI GPT-4o Vision API")
                            Text("• Core Data & CloudKit")
                        }
                        .font(.body)
                        .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(Spacing.lg)
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}