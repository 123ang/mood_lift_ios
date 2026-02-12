import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @State private var showSignOutAlert = false
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfService = false
    @State private var reminderDate = Date()

    private let purpleGradient = LinearGradient(
        colors: [Color(hex: "#667eea"), Color(hex: "#764ba2")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        ZStack {
            purpleGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        notificationsSection
                        accountSection
                        supportSection
                        aboutSection
                        signOutSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.loadSettings()
            updateReminderDate()
        }
        .sheet(isPresented: $viewModel.showChangePassword) {
            changePasswordSheet
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            legalSheet(title: "Privacy Policy", content: privacyPolicyText)
        }
        .sheet(isPresented: $showTermsOfService) {
            legalSheet(title: "Terms of Service", content: termsOfServiceText)
        }
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                Task { await viewModel.signOut() }
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert("Success", isPresented: .init(
            get: { viewModel.successMessage != nil },
            set: { if !$0 { viewModel.successMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.successMessage ?? "")
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack(spacing: 16) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 22))
                .foregroundStyle(.white)

            Text("Settings")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        VStack(spacing: 0) {
            sectionHeader(icon: "bell.fill", title: "Notifications")

            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color(hex: "#667eea"))
                        .frame(width: 28)

                    Text("Push Notifications")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.darkText)

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { viewModel.notificationsEnabled },
                        set: { _ in
                            Task { await viewModel.toggleNotifications() }
                        }
                    ))
                    .tint(.successGreen)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                if viewModel.notificationsEnabled {
                    Divider()
                        .padding(.leading, 56)

                    HStack {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color(hex: "#667eea"))
                            .frame(width: 28)

                        Text("Daily Reminder")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.darkText)

                        Spacer()

                        DatePicker(
                            "",
                            selection: $reminderDate,
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                        .onChange(of: reminderDate) { _, newValue in
                            let calendar = Calendar.current
                            viewModel.reminderHour = calendar.component(.hour, from: newValue)
                            viewModel.reminderMinute = calendar.component(.minute, from: newValue)
                            Task { await viewModel.updateReminderTime() }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
            }
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        VStack(spacing: 0) {
            sectionHeader(icon: "person.fill", title: "Account")

            Button {
                viewModel.showChangePassword = true
            } label: {
                HStack {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color(hex: "#667eea"))
                        .frame(width: 28)

                    Text("Change Password")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.darkText)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.lightText)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
        }
    }

    // MARK: - Support Section

    private var supportSection: some View {
        VStack(spacing: 0) {
            sectionHeader(icon: "questionmark.circle.fill", title: "Support & Legal")

            VStack(spacing: 0) {
                Button {
                    showPrivacyPolicy = true
                } label: {
                    settingsRow(icon: "hand.raised.fill", title: "Privacy Policy")
                }
                .buttonStyle(.plain)

                Divider()
                    .padding(.leading, 56)

                Button {
                    showTermsOfService = true
                } label: {
                    settingsRow(icon: "doc.text.fill", title: "Terms of Service")
                }
                .buttonStyle(.plain)
            }
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(spacing: 0) {
            sectionHeader(icon: "info.circle.fill", title: "About")

            HStack {
                Image(systemName: "heart.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.encouragementPink)
                    .frame(width: 28)

                Text("App Version")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.darkText)

                Spacer()

                Text("1.0.0")
                    .font(.subheadline)
                    .foregroundStyle(Color.lightText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
        }
    }

    // MARK: - Sign Out Section

    private var signOutSection: some View {
        Button {
            showSignOutAlert = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 16, weight: .semibold))
                Text("Sign Out")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.errorRed)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.errorRed.opacity(0.3), radius: 8, y: 4)
        }
        .padding(.top, 8)
    }

    // MARK: - Reusable Components

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.9))
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
        .padding(.bottom, 8)
        .padding(.top, 4)
    }

    private func settingsRow(icon: String, title: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color(hex: "#667eea"))
                .frame(width: 28)

            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.darkText)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.lightText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Change Password Sheet

    private var changePasswordSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Current Password")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.lightText)
                    SecureField("Enter current password", text: $viewModel.currentPassword)
                        .textContentType(.password)
                        .padding(14)
                        .background(Color.appBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.borderColor.opacity(0.15), lineWidth: 1)
                        )
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("New Password")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.lightText)
                    SecureField("Enter new password", text: $viewModel.newPassword)
                        .textContentType(.newPassword)
                        .padding(14)
                        .background(Color.appBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.borderColor.opacity(0.15), lineWidth: 1)
                        )
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Confirm Password")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.lightText)
                    SecureField("Confirm new password", text: $viewModel.confirmPassword)
                        .textContentType(.newPassword)
                        .padding(14)
                        .background(Color.appBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.borderColor.opacity(0.15), lineWidth: 1)
                        )
                }

                Button {
                    Task { await viewModel.changePassword() }
                } label: {
                    Group {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Save Password")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .foregroundStyle(.white)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#667eea"), Color(hex: "#764ba2")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: Color(hex: "#667eea").opacity(0.3), radius: 8, y: 4)
                }
                .disabled(viewModel.isLoading || viewModel.currentPassword.isEmpty || viewModel.newPassword.isEmpty || viewModel.confirmPassword.isEmpty)
                .opacity(viewModel.currentPassword.isEmpty || viewModel.newPassword.isEmpty || viewModel.confirmPassword.isEmpty ? 0.6 : 1.0)

                Spacer()
            }
            .padding(24)
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        viewModel.showChangePassword = false
                        viewModel.currentPassword = ""
                        viewModel.newPassword = ""
                        viewModel.confirmPassword = ""
                    }
                }
            }
        }
    }

    // MARK: - Legal Sheet

    private func legalSheet(title: String, content: String) -> some View {
        NavigationStack {
            ScrollView {
                Text(content)
                    .font(.subheadline)
                    .foregroundStyle(Color.darkText)
                    .padding(24)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showPrivacyPolicy = false
                        showTermsOfService = false
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func updateReminderDate() {
        var components = DateComponents()
        components.hour = viewModel.reminderHour
        components.minute = viewModel.reminderMinute
        if let date = Calendar.current.date(from: components) {
            reminderDate = date
        }
    }

    private var privacyPolicyText: String {
        """
        Privacy Policy for MoodLift

        Last updated: 2024

        Your privacy is important to us. This privacy policy explains how MoodLift collects, uses, and protects your personal information.

        Information We Collect:
        - Account information (email, username)
        - Usage data (check-ins, points, saved items)
        - Device information for push notifications

        How We Use Your Information:
        - To provide and improve our services
        - To send daily reminders (if enabled)
        - To track your progress and streaks

        Data Protection:
        - All data is encrypted in transit
        - We do not sell your personal information
        - You can request data deletion at any time

        Contact us at support@moodlift.app for any privacy concerns.
        """
    }

    private var termsOfServiceText: String {
        """
        Terms of Service for MoodLift

        Last updated: 2024

        By using MoodLift, you agree to these terms:

        1. Account Responsibility
        You are responsible for maintaining the security of your account and password.

        2. Acceptable Use
        You agree not to submit inappropriate, offensive, or harmful content.

        3. Points System
        Points are earned through daily check-ins and engagement. Points have no monetary value.

        4. Content Submission
        Content you submit may be reviewed and moderated. We reserve the right to remove any content.

        5. Service Availability
        We strive for 99.9% uptime but do not guarantee uninterrupted service.

        6. Modifications
        We may update these terms at any time. Continued use constitutes acceptance.

        Contact us at support@moodlift.app for any questions.
        """
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
