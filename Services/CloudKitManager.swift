import Foundation

// Disabled CloudKitManager for core build - can be re-enabled later
class CloudKitManager: ObservableObject {
    static let shared = CloudKitManager()
    
    @Published var isAvailable = false
    @Published var accountStatus: String = "disabled"
    
    private init() {
        // CloudKit disabled for core build
        isAvailable = false
    }
    
    func checkAccountStatus() {
        // CloudKit disabled for core build
        DispatchQueue.main.async {
            self.accountStatus = "disabled"
            self.isAvailable = false
        }
    }
    
    func syncUserData() async throws {
        // CloudKit disabled - no-op
    }
    
    func fetchDataFromCloud() async throws {
        // CloudKit disabled - no-op
    }
}

// Simple error enum for compatibility
enum CloudKitError: Error, LocalizedError {
    case accountNotAvailable
    case syncFailed(String)
    case fetchFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .accountNotAvailable:
            return "CloudKit is disabled in this build."
        case .syncFailed(let message):
            return "Sync failed: \(message)"
        case .fetchFailed(let message):
            return "Fetch failed: \(message)"
        }
    }
}