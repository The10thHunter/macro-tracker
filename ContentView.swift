import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState()
    
    var body: some View {
        Group {
            if appState.isOnboardingComplete {
                MainTabView()
                    .environmentObject(appState)
            } else {
                OnboardingView()
                    .environmentObject(appState)
            }
        }
        .preferredColorScheme(.dark)
        .errorAlert()
    }
}

#Preview {
    ContentView()
}