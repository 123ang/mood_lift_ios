import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @State private var showSignOutAlert = false
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfService = false
    @State private var reminderDate = Date()

    private var headerGradient: LinearGradient {
        LinearGradient(
            colors: [Color.primaryGradientStart, Color.primaryGradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                headerBar
                ScrollView(showsIndicators: false) {
                    VStack(spacing: Theme.spaceL) {
                        notificationsCard
                        accountCard
                        supportCard
                        aboutCard
                        signOutButton
                    }
                    .padding(.horizontal, Theme.spaceM)
                    .padding(.top, Theme.spaceS)
                    .padding(.bottom, Theme.spaceXXL)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.loadSettings()
            updateReminderDate()
        }
        .sheet(isPresented: $viewModel.showChangePassword) { changePasswordSheet }
        .sheet(isPresented: $showPrivacyPolicy) { legalSheet(title: "Privacy Policy", content: privacyPolicyText) }
        .sheet(isPresented: $showTermsOfService) { legalSheet(title: "Terms of Service", content: termsOfServiceText) }
        .alert("Sign out?", isPresented: $showSignOutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Sign out", role: .destructive) { Task { await viewModel.signOut() } }
        } message: {
            Text("You can sign back in anytime.")
        }
        .alert("Error", isPresented: .init(get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert("Done", isPresented: .init(get: { viewModel.successMessage != nil }, set: { if !$0 { viewModel.successMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.successMessage ?? "")
        }
    }

    // MARK: - Header (comfort, not config)
    private var headerBar: some View {
        HStack(spacing: Theme.spaceM) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.95))
            Text("Preferences")
                .font(.themeTitleSmall())
                .foregroundStyle(.white)
            Spacer()
        }
        .padding(.horizontal, Theme.spaceM)
        .padding(.vertical, Theme.spaceM)
        .background(headerGradient)
    }

    // MARK: - Notifications & reminders (grouped soft card)
    private var notificationsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(icon: "bell.fill", title: "Notifications & reminders", subtitle: "When to nudge you")
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.brandPrimary)
                        .frame(width: 28)
                    Text("Push notifications")
                        .font(.themeBodyMedium())
                        .foregroundStyle(Color.darkText)
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { viewModel.notificationsEnabled },
                        set: { _ in Task { await viewModel.toggleNotifications() } }
                    ))
                    .tint(Color.successSoft)
                }
                .padding(.horizontal, Theme.spaceM)
                .padding(.vertical, Theme.spaceM)

                if viewModel.notificationsEnabled {
                    Rectangle()
                        .fill(Color.borderColor.opacity(0.12))
                        .frame(height: 1)
                        .padding(.leading, 56)
                    HStack {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.brandPrimary)
                            .frame(width: 28)
                        Text("Daily reminder")
                            .font(.themeBodyMedium())
                            .foregroundStyle(Color.darkText)
                        Spacer()
                        DatePicker("", selection: $reminderDate, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .onChange(of: reminderDate) { _, newValue in
                                let cal = Calendar.current
                                viewModel.reminderHour = cal.component(.hour, from: newValue)
                                viewModel.reminderMinute = cal.component(.minute, from: newValue)
                                Task { await viewModel.updateReminderTime() }
                            }
                    }
                    .padding(.horizontal, Theme.spaceM)
                    .padding(.vertical, Theme.spaceS + 2)
                }
            }
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium))
            .shadow(color: Theme.cardShadow().color, radius: Theme.cardShadow().radius, y: Theme.cardShadow().y)
        }
        .padding(.top, Theme.spaceM)
    }

    // MARK: - Account (grouped)
    private var accountCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(icon: "person.fill", title: "Account")
            Button {
                viewModel.showChangePassword = true
            } label: {
                HStack {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.brandPrimary)
                        .frame(width: 28)
                    Text("Change password")
                        .font(.themeBodyMedium())
                        .foregroundStyle(Color.darkText)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.lightText)
                }
                .padding(.horizontal, Theme.spaceM)
                .padding(.vertical, Theme.spaceM)
            }
            .buttonStyle(.plain)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium))
            .shadow(color: Theme.cardShadow().color, radius: Theme.cardShadow().radius, y: Theme.cardShadow().y)
        }
    }

    // MARK: - Support & legal (grouped)
    private var supportCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(icon: "questionmark.circle.fill", title: "Support & legal")
            VStack(spacing: 0) {
                Button { showPrivacyPolicy = true } label: { settingsRow(icon: "hand.raised.fill", title: "Privacy Policy") }
                .buttonStyle(.plain)
                Rectangle()
                    .fill(Color.borderColor.opacity(0.12))
                    .frame(height: 1)
                    .padding(.leading, 56)
                Button { showTermsOfService = true } label: { settingsRow(icon: "doc.text.fill", title: "Terms of Service") }
                .buttonStyle(.plain)
            }
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium))
            .shadow(color: Theme.cardShadow().color, radius: Theme.cardShadow().radius, y: Theme.cardShadow().y)
        }
    }

    // MARK: - About
    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(icon: "heart.fill", title: "About")
            HStack {
                Image(systemName: "heart.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.encouragementPink)
                    .frame(width: 28)
                Text("App version")
                    .font(.themeBodyMedium())
                    .foregroundStyle(Color.darkText)
                Spacer()
                Text("1.0.0")
                    .font(.themeCallout())
                    .foregroundStyle(Color.lightText)
            }
            .padding(.horizontal, Theme.spaceM)
            .padding(.vertical, Theme.spaceM)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium))
            .shadow(color: Theme.cardShadow().color, radius: Theme.cardShadow().radius, y: Theme.cardShadow().y)
        }
    }

    // MARK: - Sign out (soft primary style)
    private var signOutButton: some View {
        Button { showSignOutAlert = true } label: {
            HStack(spacing: Theme.spaceS) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                Text("Sign out")
                    .font(.themeHeadline())
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.spaceM)
            .background(headerGradient)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium))
            .shadow(color: Color.primarySoft.opacity(0.2), radius: 6, y: 3)
        }
        .padding(.top, Theme.spaceS)
    }

    private func settingsRow(icon: String, title: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color.brandPrimary)
                .frame(width: 28)
            Text(title)
                .font(.themeBodyMedium())
                .foregroundStyle(Color.darkText)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.lightText)
        }
        .padding(.horizontal, Theme.spaceM)
        .padding(.vertical, Theme.spaceM)
    }

    // MARK: - Change Password Sheet (soft theme)
    private var changePasswordSheet: some View {
        NavigationStack {
            VStack(spacing: Theme.spaceL) {
                VStack(alignment: .leading, spacing: Theme.spaceXS) {
                    Text("Current password")
                        .font(.themeCaptionMedium())
                        .foregroundStyle(Color.lightText)
                    SecureField("Enter current password", text: $viewModel.currentPassword)
                        .textContentType(.password)
                        .padding(Theme.spaceM)
                        .background(Color.appBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSmall))
                        .overlay(RoundedRectangle(cornerRadius: Theme.radiusSmall).stroke(Color.borderColor.opacity(0.15), lineWidth: 1))
                }
                VStack(alignment: .leading, spacing: Theme.spaceXS) {
                    Text("New password")
                        .font(.themeCaptionMedium())
                        .foregroundStyle(Color.lightText)
                    SecureField("Enter new password", text: $viewModel.newPassword)
                        .textContentType(.newPassword)
                        .padding(Theme.spaceM)
                        .background(Color.appBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSmall))
                        .overlay(RoundedRectangle(cornerRadius: Theme.radiusSmall).stroke(Color.borderColor.opacity(0.15), lineWidth: 1))
                }
                VStack(alignment: .leading, spacing: Theme.spaceXS) {
                    Text("Confirm new password")
                        .font(.themeCaptionMedium())
                        .foregroundStyle(Color.lightText)
                    SecureField("Confirm new password", text: $viewModel.confirmPassword)
                        .textContentType(.newPassword)
                        .padding(Theme.spaceM)
                        .background(Color.appBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSmall))
                        .overlay(RoundedRectangle(cornerRadius: Theme.radiusSmall).stroke(Color.borderColor.opacity(0.15), lineWidth: 1))
                }
                Button {
                    Task { await viewModel.changePassword() }
                } label: {
                    Group {
                        if viewModel.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Save password")
                                .font(.themeHeadline())
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .foregroundStyle(.white)
                    .background(
                        LinearGradient(
                            colors: [Color.primaryGradientStart, Color.primaryGradientEnd],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium))
                    .shadow(color: Color.primarySoft.opacity(0.2), radius: 6, y: 3)
                }
                .disabled(viewModel.isLoading || viewModel.currentPassword.isEmpty || viewModel.newPassword.isEmpty || viewModel.confirmPassword.isEmpty)
                .opacity(viewModel.currentPassword.isEmpty || viewModel.newPassword.isEmpty || viewModel.confirmPassword.isEmpty ? 0.6 : 1)
                Spacer()
            }
            .padding(Theme.spaceL)
            .navigationTitle("Change password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        viewModel.showChangePassword = false
                        viewModel.currentPassword = ""
                        viewModel.newPassword = ""
                        viewModel.confirmPassword = ""
                    }
                    .foregroundStyle(Color.brandPrimary)
                }
            }
        }
    }

    private func legalSheet(title: String, content: String) -> some View {
        NavigationStack {
            ScrollView {
                Text(content)
                    .font(.themeCallout())
                    .foregroundStyle(Color.darkText)
                    .padding(Theme.spaceL)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showPrivacyPolicy = false
                        showTermsOfService = false
                    }
                    .foregroundStyle(Color.brandPrimary)
                }
            }
        }
    }

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
