import SwiftUI

struct MainTabView: View {
    @Environment(\.themeManager) private var themeManager
    @State private var selectedTab = 0

    var body: some View {
        let palette = themeManager.currentPalette
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tag(0)
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }

            NavigationStack {
                FeedsView()
            }
            .tag(1)
            .tabItem {
                Label("Feeds", systemImage: "square.stack.3d.up.fill")
            }

            NavigationStack {
                ProfileView()
            }
            .tag(2)
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }

            NavigationStack {
                SettingsView()
            }
            .tag(3)
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
        .tint(palette.brandTint)
        .toolbarBackground(palette.background, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

#Preview {
    MainTabView()
}