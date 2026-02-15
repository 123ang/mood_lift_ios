import SwiftUI

struct SignupView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var shakeError = false

    private var isFormValid: Bool {
        !username.isEmpty && !email.isEmpty && !password.isEmpty && !confirmPassword.isEmpty
    }

    private var validationError: String? {
        if password.count > 0 && password.count < 6 {
            return "Password must be at least 6 characters"
        }
        if !confirmPassword.isEmpty && password != confirmPassword {
            return "Passwords do not match"
        }
        return nil
    }

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
                        .frame(height: 12)

                    // MARK: - Header
                    headerSection

                    // MARK: - Bonus Badge
                    bonusBadge

                    // MARK: - Registration Card
                    registrationCard

                    // MARK: - Sign In Link
                    signInLink

                    Spacer()
                        .frame(height: 40)
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(.white.opacity(0.2))
                        .clipShape(Circle())
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart.fill")
                .font(.system(size: 48))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.12), radius: 6, y: 3)

            Text("Create Account")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Join the MoodLift community")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
        }
    }

    // MARK: - Bonus Badge

    private var bonusBadge: some View {
        HStack(spacing: 10) {
            Image(systemName: "star.fill")
                .font(.title3)
                .foregroundStyle(Color(hex: "#f39c12"))

            Text("Get 5 bonus points to start!")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.darkText)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color.inspirationYellow.opacity(0.9))
                .shadow(color: .inspirationYellow.opacity(0.3), radius: 6, y: 3)
        )
    }

    // MARK: - Registration Card

    private var registrationCard: some View {
        VStack(spacing: 18) {
            // Error / validation message
            if let message = errorMessage ?? validationError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.subheadline)
                    Text(message)
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

            // Username field
            HStack(spacing: 12) {
                Image(systemName: "person.fill")
                    .foregroundStyle(Color.lightText)
                    .frame(width: 20)

                TextField("Username", text: $username)
                    .textContentType(.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .padding(16)
            .background(Color.appBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            // Email field
            HStack(spacing: 12) {
                Image(systemName: "envelope.fill")
                    .foregroundStyle(Color.lightText)
                    .frame(width: 20)

                TextField("Email address", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .padding(16)
            .background(Color.appBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            // Password field
            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .foregroundStyle(Color.lightText)
                    .frame(width: 20)

                Group {
                    if showPassword {
                        TextField("Password (min 6 characters)", text: $password)
                    } else {
                        SecureField("Password (min 6 characters)", text: $password)
                    }
                }
                .textContentType(.newPassword)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

                Button {
                    showPassword.toggle()
                } label: {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .foregroundStyle(Color.lightText)
                        .contentTransition(.symbolEffect(.replace))
                }
            }
            .padding(16)
            .background(Color.appBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            // Confirm password field
            HStack(spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .foregroundStyle(Color.lightText)
                    .frame(width: 20)

                Group {
                    if showPassword {
                        TextField("Confirm password", text: $confirmPassword)
                    } else {
                        SecureField("Confirm password", text: $confirmPassword)
                    }
                }
                .textContentType(.newPassword)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            }
            .padding(16)
            .background(Color.appBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            // Password strength indicator
            if !password.isEmpty {
                passwordStrengthView
            }

            // Create Account button
            Button(action: handleRegister) {
                Group {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Create Account")
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .foregroundStyle(.white)
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
            .disabled(isLoading || !isFormValid || validationError != nil)
            .opacity(!isFormValid || validationError != nil ? 0.7 : 1.0)
            .padding(.top, 4)
        }
        .padding(24)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
    }

    // MARK: - Password Strength

    private var passwordStrengthView: some View {
        let strength = passwordStrength
        return HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(index < strength.level ? strength.color : Color.gray.opacity(0.2))
                    .frame(height: 4)
            }
            Text(strength.label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(strength.color)
        }
    }

    private var passwordStrength: (level: Int, label: String, color: Color) {
        let count = password.count
        if count < 6 {
            return (1, "Weak", .errorRed)
        } else if count < 10 {
            return (2, "Good", .warningOrange)
        } else {
            return (3, "Strong", .successGreen)
        }
    }

    // MARK: - Sign In Link

    private var signInLink: some View {
        Button {
            dismiss()
        } label: {
            HStack(spacing: 4) {
                Text("Already have an account?")
                    .foregroundStyle(.white.opacity(0.85))
                Text("Sign In")
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
            .font(.subheadline)
        }
    }

    // MARK: - Helpers

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

    private func handleRegister() {
        guard isFormValid else { return }

        // Client-side validation
        if password.count < 6 {
            errorMessage = "Password must be at least 6 characters."
            shakeError.toggle()
            return
        }
        if password != confirmPassword {
            errorMessage = "Passwords do not match."
            shakeError.toggle()
            return
        }

        errorMessage = nil
        isLoading = true

        Task {
            do {
                try await AuthService.shared.register(
                    email: email,
                    username: username,
                    password: password
                )
            } catch let error as APIError {
                await MainActor.run {
                    errorMessage = error.userMessage
                    shakeError.toggle()
                    isLoading = false
                }
            } catch {
                await MainActor.run {
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
        SignupView()
    }
}
