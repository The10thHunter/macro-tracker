import Foundation

class JSONValidator {
    static let shared = JSONValidator()
    private init() {}
    
    // MARK: - Goal JSON Validation
    func validateGoalJSON(_ jsonString: String) -> Result<GoalResponse, ValidationError> {
        // Remove any potential markdown formatting
        let cleanedJSON = cleanJSONString(jsonString)
        
        // Regex pattern for goal JSON structure
        let goalPattern = """
        \\{\\s*"date"\\s*:\\s*"[^"]*"\\s*,\\s*"k_cals"\\s*:\\s*\\d+(?:\\.\\d+)?\\s*,\\s*"protein_g"\\s*:\\s*\\d+(?:\\.\\d+)?\\s*,\\s*"carbs_g"\\s*:\\s*\\d+(?:\\.\\d+)?\\s*,\\s*"fat_g"\\s*:\\s*\\d+(?:\\.\\d+)?\\s*,\\s*"fiber_g"\\s*:\\s*\\d+(?:\\.\\d+)?\\s*\\}
        """
        
        guard isValidJSONStructure(cleanedJSON, pattern: goalPattern) else {
            return .failure(.invalidFormat("Goal JSON format is invalid"))
        }
        
        // Try to decode the JSON
        guard let jsonData = cleanedJSON.data(using: .utf8) else {
            return .failure(.encodingError("Could not encode string to data"))
        }
        
        do {
            let goalResponse = try JSONDecoder().decode(GoalResponse.self, from: jsonData)
            
            // Validate ranges
            if !isValidMacroRanges(calories: goalResponse.kCals, 
                                 protein: goalResponse.proteinG, 
                                 carbs: goalResponse.carbsG, 
                                 fat: goalResponse.fatG, 
                                 fiber: goalResponse.fiberG) {
                return .failure(.invalidRange("Macro values are outside valid ranges"))
            }
            
            return .success(goalResponse)
        } catch {
            return .failure(.decodingError(error.localizedDescription))
        }
    }
    
    // MARK: - Food JSON Validation  
    func validateFoodJSON(_ jsonString: String) -> Result<FoodResponse, ValidationError> {
        let cleanedJSON = cleanJSONString(jsonString)
        
        // Regex pattern for food JSON structure
        let foodPattern = """
        \\{\\s*"food_name"\\s*:\\s*"[^"]*"\\s*,\\s*"servings"\\s*:\\s*\\d+(?:\\.\\d+)?\\s*,\\s*"timestamp"\\s*:\\s*"[^"]*"\\s*,\\s*"k_cals"\\s*:\\s*\\d+(?:\\.\\d+)?\\s*,\\s*"protein_g"\\s*:\\s*\\d+(?:\\.\\d+)?\\s*,\\s*"carbs_g"\\s*:\\s*\\d+(?:\\.\\d+)?\\s*,\\s*"fat_g"\\s*:\\s*\\d+(?:\\.\\d+)?\\s*,\\s*"fiber_g"\\s*:\\s*\\d+(?:\\.\\d+)?\\s*\\}
        """
        
        guard isValidJSONStructure(cleanedJSON, pattern: foodPattern) else {
            return .failure(.invalidFormat("Food JSON format is invalid"))
        }
        
        guard let jsonData = cleanedJSON.data(using: .utf8) else {
            return .failure(.encodingError("Could not encode string to data"))
        }
        
        do {
            let foodResponse = try JSONDecoder().decode(FoodResponse.self, from: jsonData)
            
            // Validate ranges
            if !isValidMacroRanges(calories: foodResponse.kCals, 
                                 protein: foodResponse.proteinG, 
                                 carbs: foodResponse.carbsG, 
                                 fat: foodResponse.fatG, 
                                 fiber: foodResponse.fiberG) {
                return .failure(.invalidRange("Macro values are outside valid ranges"))
            }
            
            // Validate servings
            if foodResponse.servings <= 0 || foodResponse.servings > 50 {
                return .failure(.invalidRange("Servings must be between 0 and 50"))
            }
            
            return .success(foodResponse)
        } catch {
            return .failure(.decodingError(error.localizedDescription))
        }
    }
    
    // MARK: - Helper Methods
    private func cleanJSONString(_ jsonString: String) -> String {
        // Remove markdown code block formatting
        let withoutBackticks = jsonString.replacingOccurrences(of: "```json", with: "")
                                        .replacingOccurrences(of: "```", with: "")
        
        // Remove extra whitespace and newlines
        let trimmed = withoutBackticks.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return trimmed
    }
    
    private func isValidJSONStructure(_ jsonString: String, pattern: String) -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let range = NSRange(location: 0, length: jsonString.utf16.count)
            return regex.firstMatch(in: jsonString, options: [], range: range) != nil
        } catch {
            print("Regex error: \(error)")
            return false
        }
    }
    
    private func isValidMacroRanges(calories: Double, protein: Double, carbs: Double, fat: Double, fiber: Double) -> Bool {
        // Reasonable ranges for macro validation
        let isCaloriesValid = calories >= 0 && calories <= 5000
        let isProteinValid = protein >= 0 && protein <= 500
        let isCarbsValid = carbs >= 0 && carbs <= 1000
        let isFatValid = fat >= 0 && fat <= 500
        let isFiberValid = fiber >= 0 && fiber <= 200
        
        return isCaloriesValid && isProteinValid && isCarbsValid && isFatValid && isFiberValid
    }
}

// MARK: - Validation Error Types
enum ValidationError: Error, LocalizedError {
    case invalidFormat(String)
    case invalidRange(String)
    case encodingError(String)
    case decodingError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat(let message):
            return "Invalid format: \(message)"
        case .invalidRange(let message):
            return "Invalid range: \(message)"
        case .encodingError(let message):
            return "Encoding error: \(message)"
        case .decodingError(let message):
            return "Decoding error: \(message)"
        }
    }
}