import SwiftUI

struct SettingsView: View {
    @Environment(\.themeManager) private var themeManager
    @State private var viewModel = SettingsViewModel()
    @State private var showSignOutAlert = false
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfService = false
    @State private var showThemePicker = false
    @State private var reminderDate = Date()

    var body: some View {
        let palette = themeManager.currentPalette
        ZStack {
            palette.background.ignoresSafeArea()
            VStack(spacing: 0) {
                headerBar(palette: palette)
                ScrollView(showsIndicators: false) {
                    VStack(spacing: Theme.spaceL) {
                        themeCard
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
        .sheet(isPresented: $showThemePicker) { ThemePickerView() }
        .sheet(isPresented: $viewModel.showChangePassword) { changePasswordSheet }
        .sheet(isPresented: $showPrivacyPolicy) {
            LegalDocumentScreen(title: "Privacy Policy", content: privacyPolicyText)
                .environment(\.themeManager, themeManager)
                .onDisappear { showPrivacyPolicy = false }
        }
        .sheet(isPresented: $showTermsOfService) {
            LegalDocumentScreen(title: "Terms of Service", content: termsOfServiceText)
                .environment(\.themeManager, themeManager)
                .onDisappear { showTermsOfService = false }
        }
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
    private func headerBar(palette: ThemePalette) -> some View {
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
        .background(
            LinearGradient(
                colors: [palette.primaryGradientStart, palette.primaryGradientEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    // MARK: - Theme / Appearance
    private var themeCard: some View {
        let palette = themeManager.currentPalette
        return VStack(alignment: .leading, spacing: 0) {
            SectionHeader(icon: "paintpalette.fill", title: "Theme", subtitle: "Appearance", tint: palette.brandTint, textColor: palette.text, subtitleColor: palette.mutedText)
            VStack(alignment: .leading, spacing: Theme.spaceM) {
                HStack(spacing: Theme.spaceS) {
                    Text("Current theme")
                        .font(.themeCaptionMedium())
                        .foregroundStyle(palette.mutedText)
                    Spacer()
                    Text(themeManager.currentTheme.name)
                        .font(.themeBodyMedium())
                        .foregroundStyle(palette.text)
                }
                HStack(spacing: 6) {
                    ForEach(Array(palette.previewColors.prefix(5).enumerated()), id: \.offset) { _, color in
                        Circle()
                            .fill(color)
                            .frame(width: 20, height: 20)
                            .overlay(Circle().stroke(palette.border.opacity(0.4), lineWidth: 1))
                    }
                }
                Button {
                    showThemePicker = true
                } label: {
                    HStack {
                        Image(systemName: "paintbrush.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(palette.brandTint)
                            .frame(width: 28)
                        Text("Change Theme")
                            .font(.themeBodyMedium())
                            .foregroundStyle(palette.text)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(palette.mutedText)
                    }
                    .padding(.horizontal, Theme.spaceM)
                    .padding(.vertical, Theme.spaceM)
                }
                .buttonStyle(.plain)
                Text("Choose a theme. Locked themes can be unlocked.")
                    .font(.themeCaption())
                    .foregroundStyle(palette.mutedText)
            }
            .padding(Theme.spaceM)
            .background(palette.card)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium))
            .shadow(color: Theme.cardShadow().color, radius: Theme.cardShadow().radius, y: Theme.cardShadow().y)
        }
        .padding(.top, Theme.spaceM)
    }

    // MARK: - Notifications & reminders (grouped soft card)
    private var notificationsCard: some View {
        let palette = themeManager.currentPalette
        return VStack(alignment: .leading, spacing: 0) {
            SectionHeader(icon: "bell.fill", title: "Notifications & reminders", subtitle: "When to nudge you", tint: palette.brandTint, textColor: palette.text, subtitleColor: palette.mutedText)
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(palette.brandTint)
                        .frame(width: 28)
                    Text("Push notifications")
                        .font(.themeBodyMedium())
                        .foregroundStyle(palette.text)
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
                        .fill(palette.border.opacity(0.12))
                        .frame(height: 1)
                        .padding(.leading, 56)
                    HStack {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(palette.brandTint)
                            .frame(width: 28)
                        Text("Daily reminder")
                            .font(.themeBodyMedium())
                            .foregroundStyle(palette.text)
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
            .background(palette.card)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium))
            .shadow(color: Theme.cardShadow().color, radius: Theme.cardShadow().radius, y: Theme.cardShadow().y)
        }
        .padding(.top, Theme.spaceM)
    }

    // MARK: - Account (grouped)
    private var accountCard: some View {
        let palette = themeManager.currentPalette
        return VStack(alignment: .leading, spacing: 0) {
            SectionHeader(icon: "person.fill", title: "Account", tint: palette.brandTint, textColor: palette.text, subtitleColor: palette.mutedText)
            Button {
                viewModel.showChangePassword = true
            } label: {
                HStack {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(palette.brandTint)
                        .frame(width: 28)
                    Text("Change password")
                        .font(.themeBodyMedium())
                        .foregroundStyle(palette.text)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(palette.mutedText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Theme.spaceM)
                .padding(.vertical, Theme.spaceM)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(palette.card)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium))
            .shadow(color: Theme.cardShadow().color, radius: Theme.cardShadow().radius, y: Theme.cardShadow().y)
        }
    }

    // MARK: - Support & legal (grouped)
    private var supportCard: some View {
        let palette = themeManager.currentPalette
        return VStack(alignment: .leading, spacing: 0) {
            SectionHeader(icon: "questionmark.circle.fill", title: "Support & legal", tint: palette.brandTint, textColor: palette.text, subtitleColor: palette.mutedText)
            VStack(spacing: 0) {
                Button { showPrivacyPolicy = true } label: {
                    settingsRow(icon: "hand.raised.fill", title: "Privacy Policy", palette: palette)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Rectangle()
                    .fill(palette.border.opacity(0.12))
                    .frame(height: 1)
                    .padding(.leading, 56)
                Button { showTermsOfService = true } label: {
                    settingsRow(icon: "doc.text.fill", title: "Terms of Service", palette: palette)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .background(palette.card)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium))
            .shadow(color: Theme.cardShadow().color, radius: Theme.cardShadow().radius, y: Theme.cardShadow().y)
        }
    }

    // MARK: - About
    private var aboutCard: some View {
        let palette = themeManager.currentPalette
        return VStack(alignment: .leading, spacing: 0) {
            SectionHeader(icon: "heart.fill", title: "About", tint: palette.brandTint, textColor: palette.text, subtitleColor: palette.mutedText)
            HStack {
                Image(systemName: "heart.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(palette.accent)
                    .frame(width: 28)
                Text("App version")
                    .font(.themeBodyMedium())
                    .foregroundStyle(palette.text)
                Spacer()
                Text("1.0.0")
                    .font(.themeCallout())
                    .foregroundStyle(palette.mutedText)
            }
            .padding(.horizontal, Theme.spaceM)
            .padding(.vertical, Theme.spaceM)
            .background(palette.card)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium))
            .shadow(color: Theme.cardShadow().color, radius: Theme.cardShadow().radius, y: Theme.cardShadow().y)
        }
    }

    // MARK: - Sign out (soft primary style)
    private var signOutButton: some View {
        let palette = themeManager.currentPalette
        return Button { showSignOutAlert = true } label: {
            HStack(spacing: Theme.spaceS) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                Text("Sign out")
                    .font(.themeHeadline())
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.spaceM)
            .background(
                LinearGradient(
                    colors: [palette.primaryGradientStart, palette.primaryGradientEnd],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium))
            .shadow(color: palette.primary.opacity(0.2), radius: 6, y: 3)
        }
        .padding(.top, Theme.spaceS)
    }

    private func settingsRow(icon: String, title: String, palette: ThemePalette) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(palette.brandTint)
                .frame(width: 28)
            Text(title)
                .font(.themeBodyMedium())
                .foregroundStyle(palette.text)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.medium))
                .foregroundStyle(palette.mutedText)
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
        Privacy Policy — MoodLift

        Last updated: 18 February 2026
        Developer / Owner: SunTzu Technologies
        Contact: suntzutechnologies@gmail.com

        —

        1. Introduction

        MoodLift ("the App") is designed to provide users with daily emotional support through encouragement messages, inspirational quotes, jokes, and fun facts.

        Your privacy is important to us.
        This Privacy Policy explains how MoodLift collects, uses, and protects your information when you use the application.

        By using MoodLift, you agree to the collection and use of information in accordance with this policy.

        —

        2. Information We Collect

        2.1 Information You Provide

        MoodLift does not require account registration to use its main features.

        However, the app may store:
        • Your selected preferences (categories, mood interests)
        • Notification settings
        • Theme and customization choices

        These are stored locally on your device.

        —

        2.2 Automatically Collected Information

        To improve app stability and performance, we may collect:
        • Device type and OS version
        • App version
        • Anonymous usage statistics (e.g., feature usage frequency)
        • Crash logs and error reports

        This data is anonymous and cannot identify you personally.

        —

        2.3 Notifications

        If you enable notifications, the app stores:
        • Reminder schedule
        • Notification preferences

        MoodLift does not read your messages, contacts, photos, or personal files.

        —

        3. How We Use Information

        We use collected information only to:
        • Deliver daily messages
        • Improve app performance and stability
        • Fix bugs and crashes
        • Personalize user experience
        • Improve content quality

        We do NOT sell or rent your data to anyone.

        —

        4. Data Storage

        Most MoodLift data is stored locally on your device.

        Some anonymous analytics or crash reports may be processed through secure third-party services solely to improve the app.

        We do not store personal identity data on our servers.

        —

        5. Third-Party Services

        MoodLift may use trusted third-party tools (e.g., analytics or crash reporting services) that process limited technical data.

        These services:
        • Do not receive your personal identity
        • Do not track you across other apps
        • Are used only for app improvement

        —

        6. Children's Privacy

        MoodLift is suitable for general audiences.
        We do not knowingly collect personal information from children under 13.

        If a parent believes a child has provided personal information, please contact us and we will remove it immediately.

        —

        7. Your Rights

        You can control your data anytime by:
        • Disabling notifications
        • Resetting the app data
        • Uninstalling the app

        Uninstalling the app removes all locally stored data.

        —

        8. Security

        We implement reasonable security measures to protect information from unauthorized access, alteration, or disclosure.

        However, no digital system can guarantee absolute security.

        —

        9. Changes to This Policy

        We may update this Privacy Policy from time to time.
        Changes will be posted inside the app or website.

        Continued use of the app means you accept the updated policy.

        —

        10. Contact Us

        If you have any questions about this Privacy Policy:

        SunTzu Technologies
        📧 suntzutechnologies@gmail.com
        """
    }

    private var termsOfServiceText: String {
        """
        Terms of Service — MoodLift

        Last updated: 18 February 2026
        Developer / Owner: SunTzu Technologies
        Contact: suntzutechnologies@gmail.com

        —

        1. Acceptance of Terms

        By downloading, installing, or using MoodLift ("the App"), you agree to be bound by these Terms of Service.

        If you do not agree with any part of these terms, please do not use the application.

        —

        2. Description of the Service

        MoodLift is a wellness and lifestyle application that delivers:
        • Encouragement messages
        • Inspirational quotes
        • Jokes
        • Fun facts
        • Daily emotional support content

        The content is intended for general positivity and entertainment purposes only.

        MoodLift is not a medical, psychological, or professional mental health service.

        —

        3. Not Medical Advice

        MoodLift does not provide:
        • Medical diagnosis
        • Psychological therapy
        • Counseling services
        • Emergency support

        If you are experiencing emotional distress, depression, or mental health crisis, please contact a qualified professional or local emergency services.

        The app should not be used as a substitute for professional care.

        —

        4. User Responsibilities

        You agree to:
        • Use the app lawfully
        • Not attempt to reverse engineer or hack the app
        • Not misuse the service in a harmful or abusive manner
        • Not redistribute app content commercially without permission

        —

        5. Content Disclaimer

        MoodLift provides automatically generated and curated content.

        We do not guarantee that:
        • All messages will be accurate
        • Content will always match your personal beliefs
        • Every message will positively affect your mood

        Content is subjective and varies by individual experience.

        —

        6. Intellectual Property

        All app design, branding, and compiled content belong to:

        SunTzu Technologies

        You may not copy, reproduce, or redistribute any part of the app without written permission.

        Quotes from public figures remain property of their respective owners.

        —

        7. Availability of Service

        We strive to keep the app available but we do not guarantee:
        • Continuous uptime
        • Error-free operation
        • Permanent feature availability

        Features may be modified, added, or removed at any time without notice.

        —

        8. Limitation of Liability

        SunTzu Technologies is not liable for:
        • Emotional reactions to content
        • Decisions made based on messages
        • Loss of data from device issues
        • App interruptions or bugs

        You use the app at your own discretion.

        —

        9. Termination

        We reserve the right to restrict or terminate access to the app if misuse or abuse is detected.

        You may stop using the app anytime by uninstalling it.

        —

        10. Changes to Terms

        We may update these Terms of Service periodically.
        Continued use of MoodLift after updates means you accept the revised terms.

        —

        11. Contact

        For questions regarding these Terms:

        SunTzu Technologies
        📧 suntzutechnologies@gmail.com
        """
    }
}

// MARK: - Legal document sheet (Privacy Policy / Terms of Service) — themed, redesigned
struct LegalDocumentView: View {
    let title: String
    let content: String
    @Environment(\.themeManager) private var themeManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let palette = themeManager.currentPalette
        VStack(spacing: 0) {
            // Themed header bar
            HStack(spacing: Theme.spaceM) {
                Text(title)
                    .font(.themeTitle())
                    .foregroundStyle(.white)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.themeHeadline())
                        .foregroundStyle(.white)
                        .padding(.horizontal, Theme.spaceL)
                        .padding(.vertical, Theme.spaceS)
                        .background(Capsule().fill(.white.opacity(0.25)))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Theme.spaceM)
            .padding(.vertical, Theme.spaceM)
            .background(
                LinearGradient(
                    colors: [palette.primaryGradientStart, palette.primaryGradientEnd],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            // Scrollable content: themed background + card-style content block
            ScrollView(showsIndicators: true) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(content)
                        .font(.themeBody())
                        .foregroundStyle(palette.text)
                        .lineSpacing(8)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Theme.spaceL)
                .background(
                    RoundedRectangle(cornerRadius: Theme.radiusLarge)
                        .fill(palette.card)
                        .shadow(color: Theme.cardShadow().color, radius: Theme.cardShadow().radius, y: Theme.cardShadow().y)
                )
                .padding(.horizontal, Theme.spaceM)
                .padding(.top, Theme.spaceM)
                .padding(.bottom, Theme.spaceXXL)
            }
            .background(palette.background)
        }
        .background(palette.background)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
