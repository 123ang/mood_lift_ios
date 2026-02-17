import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var shakeError = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [.primaryGradientStart, .primaryGradientEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    Spacer()
                        .frame(height: 20)

                    // MARK: - Header
                    headerSection

                    // MARK: - Login Card
                    loginCard

                    // MARK: - Sign Up Link
                    signUpLink

                    // MARK: - Daily Reminder
                    reminderCard

                    Spacer()
                        .frame(height: 40)
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart.fill")
                .font(.system(size: 52))
                .foregroundStyle(Color.darkText.opacity(0.9))
                .shadow(color: .black.opacity(0.08), radius: 6, y: 3)

            Text("MoodLift")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(Color.darkText)

            Text("Welcome back!")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Color.darkText.opacity(0.85))
        }
        .padding(.bottom, 8)
    }

    // MARK: - Login Card

    private var loginCard: some View {
        VStack(spacing: 20) {
            // Error message
            if let errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.subheadline)
                    Text(errorMessage)
                        .font(.subheadline)
                        .multilineTextAlignment(.leading)
                }
                .foregroundStyle(Color.errorRed)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.errorRed.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .offset(x: shakeError ? -6 : 0)
                .animation(
                    .default.repeatCount(3, autoreverses: true).speed(6),
                    value: shakeError
                )
            }

            // Email field (dark placeholder + text)
            HStack(spacing: 12) {
                Image(systemName: "envelope.fill")
                    .foregroundStyle(Color.darkText)
                    .frame(width: 20)

                ZStack(alignment: .leading) {
                    if email.isEmpty {
                        Text("Email address")
                            .font(.system(size: 17))
                            .foregroundStyle(Color.placeholderOnLight)
                    }
                    TextField("", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .foregroundStyle(Color.darkText)
                        .tint(Color.brandPrimary)
                }
            }
            .padding(16)
            .background(Color.appBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            // Password field
            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .foregroundStyle(Color.darkText)
                    .frame(width: 20)

                ZStack(alignment: .leading) {
                    if password.isEmpty {
                        Text("Password")
                            .font(.system(size: 17))
                            .foregroundStyle(Color.placeholderOnLight)
                    }
                    Group {
                        if showPassword {
                            TextField("", text: $password)
                        } else {
                            SecureField("", text: $password)
                        }
                    }
                    .textContentType(.password)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundStyle(Color.darkText)
                    .tint(Color.brandPrimary)
                }

                Button {
                    showPassword.toggle()
                } label: {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .foregroundStyle(Color.darkText)
                        .contentTransition(.symbolEffect(.replace))
                }
            }
            .padding(16)
            .background(Color.appBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            // Sign In button (dark text on light gradient for contrast)
            Button(action: handleLogin) {
                Group {
                    if isLoading {
                        ProgressView()
                            .tint(Color.darkText)
                    } else {
                        Text("Sign In")
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .foregroundStyle(Color.darkText)
                .background(
                    LinearGradient(
                        colors: [.primaryGradientStart, .primaryGradientEnd],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .encouragementPink.opacity(0.4), radius: 8, y: 4)
            }
            .disabled(isLoading || email.isEmpty || password.isEmpty)
            .opacity(email.isEmpty || password.isEmpty ? 0.7 : 1.0)
            .padding(.top, 4)
        }
        .padding(24)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
    }

    // MARK: - Sign Up Link

    private var signUpLink: some View {
        NavigationLink {
            SignupView()
        } label: {
            HStack(spacing: 4) {
                Text("Don't have an account?")
                    .foregroundStyle(Color.darkText.opacity(0.9))
                Text("Sign Up")
                    .fontWeight(.bold)
                    .foregroundStyle(Color.darkText)
            }
            .font(.subheadline)
        }
    }

    // MARK: - Reminder Card

    private var reminderCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.title3)
                .foregroundStyle(Color.inspirationYellow)

            VStack(alignment: .leading, spacing: 2) {
                Text("Daily Check-ins")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.darkText)
                Text("Earn points & track your mood every day!")
                    .font(.caption)
                    .foregroundStyle(Color.darkText.opacity(0.85))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Helpers

    private func authFriendlyMessage(_ error: APIError) -> String {
        switch error {
        case .authError:
            return "Invalid email or password. New here? Tap Sign Up to create an account."
        case .serverError(let msg):
            return msg
        default:
            return error.userMessage
        }
    }

    private func connectionErrorMessage(for error: Error) -> String {
        let ns = error as NSError
        if ns.domain == NSURLErrorDomain {
            switch ns.code {
            case NSURLErrorCannotConnectToHost, NSURLErrorNetworkConnectionLost,
                 NSURLErrorTimedOut, NSURLErrorNotConnectedToInternet:
                #if DEBUG
                return "Cannot connect to server. Is the backend running at \(Constants.apiBaseURL.replacingOccurrences(of: "/api", with: ""))?"
                #else
                return "Cannot connect to server. Please check your internet connection and try again."
                #endif
            default:
                break
            }
        }
        return "Something went wrong. Please try again."
    }

    // MARK: - Actions

    private func handleLogin() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, !trimmedPassword.isEmpty else { return }

        errorMessage = nil
        isLoading = true

        Task {
            do {
                try await AuthService.shared.login(email: trimmedEmail, password: trimmedPassword)
            } catch let error as APIError {
                await MainActor.run {
                    email = trimmedEmail
                    password = trimmedPassword
                    errorMessage = authFriendlyMessage(error)
                    shakeError.toggle()
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    email = trimmedEmail
                    password = trimmedPassword
                    errorMessage = connectionErrorMessage(for: error)
                    shakeError.toggle()
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        LoginView()
    }
}
