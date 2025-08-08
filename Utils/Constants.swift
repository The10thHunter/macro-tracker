import SwiftUI

// MARK: - Spacing Constants
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius Constants
enum CornerRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
}

// MARK: - Macro Colors
enum MacroColors {
    static let calories = Color(red: 1.0, green: 0.84, blue: 0.04) // Golden yellow
    static let protein = Color(red: 0.39, green: 0.82, blue: 1.0) // Light blue
    static let carbs = Color(red: 1.0, green: 0.62, blue: 0.04) // Orange
    static let fat = Color(red: 0.75, green: 0.35, blue: 0.95) // Purple
    static let fiber = Color(red: 0.19, green: 0.82, blue: 0.35) // Green
}

// MARK: - Animation Constants
enum AnimationDuration {
    static let fast: Double = 0.2
    static let standard: Double = 0.3
    static let slow: Double = 0.5
}

// MARK: - Size Constants
enum Size {
    static let minTouchTarget: CGFloat = 44
    static let captureButton: CGFloat = 80
    static let foodImageSize: CGFloat = 60
    static let progressRingThickness: CGFloat = 8
}

// MARK: - API Constants
enum API {
    static let openAIBaseURL = "https://api.openai.com/v1"
    static let gpt4oModel = "gpt-4o"
    static let maxTokens = 500
    static let temperature = 0.3
}

// MARK: - Validation Constants
enum ValidationLimits {
    static let maxCalories: Double = 5000
    static let maxProtein: Double = 500
    static let maxCarbs: Double = 1000
    static let maxFat: Double = 500
    static let maxFiber: Double = 200
    static let maxServings: Double = 50
    static let maxHealthContextLength = 1000
}