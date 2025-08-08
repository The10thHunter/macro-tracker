import Foundation
import UIKit

class OpenAIService: ObservableObject {
    static let shared = OpenAIService()
    private init() {}
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var apiKey: String? {
        return KeychainManager.shared.getAPIKey()
    }
    
    // MARK: - Goal Generation
    func generateGoals(for healthContext: String) async throws -> GoalResponse {
        guard let apiKey = apiKey else {
            throw OpenAIError.noAPIKey
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let prompt = """
        Based on the following health context, generate personalized macro goals for today. 
        Return ONLY a JSON object in this exact format, no other text or markdown:
        
        {
            "date": "\(DateFormatter.goalDateFormatter.string(from: Date()))",
            "k_cals": [number],
            "protein_g": [number],
            "carbs_g": [number],
            "fat_g": [number],
            "fiber_g": [number]
        }
        
        Health Context: \(healthContext)
        
        Consider typical nutritional needs for their goals. If insufficient information, request more context by returning an error JSON.
        """
        
        let response = try await sendChatRequest(prompt: prompt, apiKey: apiKey)
        
        // Validate and parse the response
        let validationResult = JSONValidator.shared.validateGoalJSON(response)
        
        switch validationResult {
        case .success(let goalResponse):
            return goalResponse
        case .failure(let error):
            throw OpenAIError.invalidResponse(error.localizedDescription)
        }
    }
    
    // MARK: - Food Analysis
    func analyzeFoodFromImage(_ image: UIImage, description: String = "") async throws -> FoodResponse {
        guard let apiKey = apiKey else {
            throw OpenAIError.noAPIKey
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // Convert image to base64
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw OpenAIError.imageProcessingFailed
        }
        let base64Image = imageData.base64EncodedString()
        
        let prompt = """
        Analyze this food image and provide macro information. \(description.isEmpty ? "" : "Additional context: \(description)")
        
        Return ONLY a JSON object in this exact format, no other text or markdown:
        
        {
            "food_name": "[descriptive food name]",
            "servings": [estimated servings as decimal],
            "timestamp": "\(ISO8601DateFormatter().string(from: Date()))",
            "k_cals": [estimated calories],
            "protein_g": [grams of protein],
            "carbs_g": [grams of carbohydrates],
            "fat_g": [grams of fat],
            "fiber_g": [grams of fiber]
        }
        
        Be conservative with estimates. If you cannot identify the food clearly, return an error.
        """
        
        let response = try await sendVisionRequest(prompt: prompt, base64Image: base64Image, apiKey: apiKey)
        
        // Validate and parse the response
        let validationResult = JSONValidator.shared.validateFoodJSON(response)
        
        switch validationResult {
        case .success(let foodResponse):
            return foodResponse
        case .failure(let error):
            throw OpenAIError.invalidResponse(error.localizedDescription)
        }
    }
    
    // MARK: - Goal Modification
    func modifyGoals(currentGoal: Goal, userRequest: String) async throws -> GoalResponse {
        guard let apiKey = apiKey else {
            throw OpenAIError.noAPIKey
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let prompt = """
        User wants to modify their current macro goals. Current goals:
        - Calories: \(currentGoal.kCals)
        - Protein: \(currentGoal.proteinG)g
        - Carbs: \(currentGoal.carbsG)g  
        - Fat: \(currentGoal.fatG)g
        - Fiber: \(currentGoal.fiberG)g
        
        User request: \(userRequest)
        
        Return ONLY a JSON object with modified goals in this exact format:
        
        {
            "date": "\(DateFormatter.goalDateFormatter.string(from: Date()))",
            "k_cals": [number],
            "protein_g": [number],
            "carbs_g": [number],
            "fat_g": [number],
            "fiber_g": [number]
        }
        """
        
        let response = try await sendChatRequest(prompt: prompt, apiKey: apiKey)
        
        let validationResult = JSONValidator.shared.validateGoalJSON(response)
        
        switch validationResult {
        case .success(let goalResponse):
            return goalResponse
        case .failure(let error):
            throw OpenAIError.invalidResponse(error.localizedDescription)
        }
    }
    
    // MARK: - Private API Methods
    private func sendChatRequest(prompt: String, apiKey: String) async throws -> String {
        let url = URL(string: "\(API.openAIBaseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "model": API.gpt4oModel,
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "max_tokens": API.maxTokens,
            "temperature": API.temperature
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse("No HTTP response")
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw OpenAIError.apiError("API returned \(httpResponse.statusCode): \(errorMessage)")
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let choices = json?["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw OpenAIError.invalidResponse("Could not parse response")
        }
        
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func sendVisionRequest(prompt: String, base64Image: String, apiKey: String) async throws -> String {
        let url = URL(string: "\(API.openAIBaseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "model": API.gpt4oModel,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": prompt
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)"
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": API.maxTokens,
            "temperature": API.temperature
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse("No HTTP response")
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw OpenAIError.apiError("API returned \(httpResponse.statusCode): \(errorMessage)")
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let choices = json?["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw OpenAIError.invalidResponse("Could not parse response")
        }
        
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - OpenAI Error Types
enum OpenAIError: Error, LocalizedError {
    case noAPIKey
    case invalidResponse(String)
    case apiError(String)
    case imageProcessingFailed
    
    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "No API key found. Please add your OpenAI API key in settings."
        case .invalidResponse(let message):
            return "Invalid response: \(message)"
        case .apiError(let message):
            return "API error: \(message)"
        case .imageProcessingFailed:
            return "Failed to process image for analysis"
        }
    }
}

// MARK: - Date Formatter Extension
extension DateFormatter {
    static let goalDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}