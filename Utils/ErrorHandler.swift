import Foundation
import SwiftUI

class ErrorHandler: ObservableObject {
    static let shared = ErrorHandler()
    private init() {}
    
    @Published var currentError: AppError?
    @Published var showingErrorAlert = false
    
    func handle(_ error: Error, context: String = "") {
        DispatchQueue.main.async {
            let appError = AppError.from(error, context: context)
            self.currentError = appError
            self.showingErrorAlert = true
            
            // Log error for debugging
            self.logError(appError, originalError: error)
        }
    }
    
    private func logError(_ appError: AppError, originalError: Error) {
        print("🔴 ERROR: \(appError.title)")
        print("   Context: \(appError.context)")
        print("   Message: \(appError.message)")
        print("   Original: \(originalError.localizedDescription)")
        print("   Type: \(type(of: originalError))")
        
        // In a production app, you might want to send this to a crash reporting service
        // like Crashlytics or Sentry
    }
    
    func clearError() {
        currentError = nil
        showingErrorAlert = false
    }
}

// MARK: - App Error Model
struct AppError: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let context: String
    let isRetryable: Bool
    let severity: ErrorSeverity
    
    enum ErrorSeverity {
        case low      // User can continue normally
        case medium   // Feature unavailable but app functional
        case high     // Critical error affecting core functionality
    }
    
    static func from(_ error: Error, context: String = "") -> AppError {
        switch error {
        // OpenAI Service Errors
        case let openAIError as OpenAIError:
            return handleOpenAIError(openAIError, context: context)
            
        // CloudKit Errors
        case let cloudKitError as CloudKitError:
            return handleCloudKitError(cloudKitError, context: context)
            
        // Validation Errors
        case let validationError as ValidationError:
            return handleValidationError(validationError, context: context)
            
        // Network Errors
        case let urlError as URLError:
            return handleNetworkError(urlError, context: context)
            
        // Generic errors
        default:
            return AppError(
                title: "Unexpected Error",
                message: error.localizedDescription,
                context: context,
                isRetryable: true,
                severity: .medium
            )
        }
    }
    
    private static func handleOpenAIError(_ error: OpenAIError, context: String) -> AppError {
        switch error {
        case .noAPIKey:
            return AppError(
                title: "API Key Required",
                message: "Please add your OpenAI API key in Settings to use AI features.",
                context: context,
                isRetryable: false,
                severity: .high
            )
            
        case .invalidResponse(let message):
            return AppError(
                title: "AI Analysis Failed",
                message: "The AI service returned an unexpected response: \(message). Please try again.",
                context: context,
                isRetryable: true,
                severity: .medium
            )
            
        case .apiError(let message):
            return AppError(
                title: "API Error",
                message: message.contains("401") ? "Invalid API key. Please check your OpenAI API key in Settings." : 
                        message.contains("429") ? "Rate limit exceeded. Please wait a moment and try again." :
                        "API request failed: \(message)",
                context: context,
                isRetryable: !message.contains("401"),
                severity: message.contains("401") ? .high : .medium
            )
            
        case .imageProcessingFailed:
            return AppError(
                title: "Image Processing Failed",
                message: "Unable to process the selected image. Please try a different photo.",
                context: context,
                isRetryable: true,
                severity: .low
            )
        }
    }
    
    private static func handleCloudKitError(_ error: CloudKitError, context: String) -> AppError {
        switch error {
        case .accountNotAvailable:
            return AppError(
                title: "iCloud Not Available",
                message: "Please sign in to iCloud in Settings to enable data sync.",
                context: context,
                isRetryable: false,
                severity: .medium
            )
            
        case .syncFailed(let message):
            return AppError(
                title: "Sync Failed",
                message: "Unable to sync data to iCloud: \(message). Your data is still saved locally.",
                context: context,
                isRetryable: true,
                severity: .low
            )
            
        case .fetchFailed(let message):
            return AppError(
                title: "Fetch Failed",
                message: "Unable to fetch data from iCloud: \(message). Using local data.",
                context: context,
                isRetryable: true,
                severity: .low
            )
        }
    }
    
    private static func handleValidationError(_ error: ValidationError, context: String) -> AppError {
        switch error {
        case .invalidFormat(let message):
            return AppError(
                title: "Data Format Error",
                message: "The AI returned data in an unexpected format: \(message). Please try again.",
                context: context,
                isRetryable: true,
                severity: .medium
            )
            
        case .invalidRange(let message):
            return AppError(
                title: "Invalid Data",
                message: "The AI returned unrealistic values: \(message). Please verify the results.",
                context: context,
                isRetryable: true,
                severity: .low
            )
            
        case .encodingError(let message), .decodingError(let message):
            return AppError(
                title: "Data Processing Error",
                message: "Unable to process the data: \(message). Please try again.",
                context: context,
                isRetryable: true,
                severity: .medium
            )
        }
    }
    
    private static func handleNetworkError(_ error: URLError, context: String) -> AppError {
        let (title, message, isRetryable) = {
            switch error.code {
            case .notConnectedToInternet:
                return ("No Internet Connection", "Please check your internet connection and try again.", true)
            case .timedOut:
                return ("Request Timed Out", "The request took too long to complete. Please try again.", true)
            case .cannotFindHost:
                return ("Server Unreachable", "Unable to reach the server. Please try again later.", true)
            case .cancelled:
                return ("Request Cancelled", "The request was cancelled.", false)
            default:
                return ("Network Error", "A network error occurred: \(error.localizedDescription)", true)
            }
        }()
        
        return AppError(
            title: title,
            message: message,
            context: context,
            isRetryable: isRetryable,
            severity: error.code == .notConnectedToInternet ? .high : .medium
        )
    }
}

// MARK: - Error Alert Modifier
struct ErrorAlertModifier: ViewModifier {
    @ObservedObject var errorHandler = ErrorHandler.shared
    
    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: $errorHandler.showingErrorAlert) {
                if let error = errorHandler.currentError {
                    if error.isRetryable {
                        Button("Retry") {
                            // The calling code should handle retry logic
                            errorHandler.clearError()
                        }
                        
                        Button("Cancel", role: .cancel) {
                            errorHandler.clearError()
                        }
                    } else {
                        Button("OK") {
                            errorHandler.clearError()
                        }
                    }
                }
            } message: {
                if let error = errorHandler.currentError {
                    Text(error.message)
                }
            }
    }
}

extension View {
    func errorAlert() -> some View {
        modifier(ErrorAlertModifier())
    }
}

// MARK: - Loading State Manager
class LoadingStateManager: ObservableObject {
    static let shared = LoadingStateManager()
    private init() {}
    
    @Published private var loadingStates: [String: Bool] = [:]
    
    func isLoading(_ key: String) -> Bool {
        return loadingStates[key] ?? false
    }
    
    func setLoading(_ key: String, _ loading: Bool) {
        DispatchQueue.main.async {
            self.loadingStates[key] = loading
        }
    }
    
    func isAnyLoading() -> Bool {
        return loadingStates.values.contains(true)
    }
}

// MARK: - Retry Manager
class RetryManager {
    private var retryAttempts: [String: Int] = [:]
    private let maxRetries = 3
    
    func canRetry(_ operation: String) -> Bool {
        let attempts = retryAttempts[operation, default: 0]
        return attempts < maxRetries
    }
    
    func recordAttempt(_ operation: String) {
        retryAttempts[operation, default: 0] += 1
    }
    
    func resetAttempts(_ operation: String) {
        retryAttempts[operation] = 0
    }
    
    func executeWithRetry<T>(
        operation: String,
        maxRetries: Int = 3,
        delay: TimeInterval = 1.0,
        task: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                let result = try await task()
                resetAttempts(operation)
                return result
            } catch {
                lastError = error
                recordAttempt(operation)
                
                if attempt < maxRetries {
                    try await Task.sleep(nanoseconds: UInt64(delay * Double(attempt) * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? NSError(domain: "RetryManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Max retries exceeded"])
    }
}