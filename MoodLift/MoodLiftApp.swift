import SwiftUI

@main
struct MoodLiftApp: App {
    @State private var authService = AuthService.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isLoading {
                    splashScreen
                } else if authService.isAuthenticated {
                    MainTabView()
                } else {
                    NavigationStack {
                        LoginView()
                    }
                }
            }
            .animation(.easeInOut(duration: 0.4), value: authService.isAuthenticated)
            .animation(.easeInOut(duration: 0.3), value: authService.isLoading)
        }
    }

    // MARK: - Splash Screen

    private var splashScreen: some View {
        ZStack {
            LinearGradient(
                colors: [.primaryGradientStart, .primaryGradientEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)

                Text("MoodLift")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Your daily dose of positivity")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))

                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.1)
                    .padding(.top, 8)
            }
        }
    }
}

