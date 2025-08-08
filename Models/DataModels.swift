import Foundation

// MARK: - User Model
struct User: Codable, Identifiable {
    let id = UUID()
    var healthContext: String
    var preferences: UserPreferences
    var createdAt: Date = Date()
    
    init(healthContext: String, preferences: UserPreferences = UserPreferences()) {
        self.healthContext = healthContext
        self.preferences = preferences
    }
}

struct UserPreferences: Codable {
    var measurementSystem: MeasurementSystem = .imperial
    var darkMode: Bool = true
    
    enum CodingKeys: String, CodingKey {
        case measurementSystem, darkMode
    }
}

// MARK: - Goal Model
struct Goal: Codable, Identifiable {
    let id = UUID()
    var date: String
    var kCals: Double
    var proteinG: Double
    var carbsG: Double
    var fatG: Double
    var fiberG: Double
    var createdAt: Date = Date()
    var isActive: Bool = true
    
    init(date: String, kCals: Double, proteinG: Double, carbsG: Double, fatG: Double, fiberG: Double) {
        self.date = date
        self.kCals = kCals
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
        self.fiberG = fiberG
    }
}

// MARK: - Food Model
struct Food: Codable, Identifiable {
    let id = UUID()
    var foodName: String
    var servings: Double
    var timestamp: Date
    var kCals: Double
    var proteinG: Double
    var carbsG: Double
    var fatG: Double
    var fiberG: Double
    var photoData: Data?
    
    init(foodName: String, servings: Double, timestamp: Date = Date(), 
         kCals: Double, proteinG: Double, carbsG: Double, fatG: Double, fiberG: Double, photoData: Data? = nil) {
        self.foodName = foodName
        self.servings = servings
        self.timestamp = timestamp
        self.kCals = kCals
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
        self.fiberG = fiberG
        self.photoData = photoData
    }
}

// MARK: - JSON Response Models for GPT
struct GoalResponse: Codable {
    let date: String
    let kCals: Double
    let proteinG: Double
    let carbsG: Double
    let fatG: Double
    let fiberG: Double
    
    private enum CodingKeys: String, CodingKey {
        case date
        case kCals = "k_cals"
        case proteinG = "protein_g"
        case carbsG = "carbs_g"
        case fatG = "fat_g"
        case fiberG = "fiber_g"
    }
}

struct FoodResponse: Codable {
    let foodName: String
    let servings: Double
    let timestamp: String
    let kCals: Double
    let proteinG: Double
    let carbsG: Double
    let fatG: Double
    let fiberG: Double
    
    private enum CodingKeys: String, CodingKey {
        case foodName = "food_name"
        case servings
        case timestamp
        case kCals = "k_cals"
        case proteinG = "protein_g"
        case carbsG = "carbs_g"
        case fatG = "fat_g"
        case fiberG = "fiber_g"
    }
}