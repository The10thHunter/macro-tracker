import Foundation
import SwiftUI

class AppState: ObservableObject {
    @Published var isOnboardingComplete: Bool = false
    @Published var hasAPIKey: Bool = false
    @Published var currentUser: User?
    @Published var currentGoal: Goal?
    @Published var measurementSystem: MeasurementSystem = .imperial
    
    init() {
        checkOnboardingStatus()
        checkAPIKey()
        loadUserPreferences()
    }
    
    private func checkOnboardingStatus() {
        isOnboardingComplete = UserDefaults.standard.bool(forKey: "onboardingComplete")
    }
    
    private func checkAPIKey() {
        hasAPIKey = KeychainManager.shared.getAPIKey() != nil
    }
    
    private func loadUserPreferences() {
        if let systemString = UserDefaults.standard.string(forKey: "measurementSystem"),
           let system = MeasurementSystem(rawValue: systemString) {
            measurementSystem = system
        }
    }
    
    func completeOnboarding(user: User, goal: Goal) {
        self.currentUser = user
        self.currentGoal = goal
        self.isOnboardingComplete = true
        UserDefaults.standard.set(true, forKey: "onboardingComplete")
        
        // Save user and goal data
        DataManager.shared.saveUser(user)
        DataManager.shared.saveGoal(goal)
    }
}

enum MeasurementSystem: String, CaseIterable, Codable {
    case metric = "metric"
    case imperial = "imperial"
    
    var weightUnit: String {
        switch self {
        case .metric: return "kg"
        case .imperial: return "lbs"
        }
    }
    
    var macroUnit: String {
        switch self {
        case .metric: return "g"
        case .imperial: return "oz"
        }
    }
}