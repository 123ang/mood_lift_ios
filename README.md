# MoodLift iOS - Native SwiftUI App

A native iOS app built with SwiftUI for daily mood boosting through crowdsourced encouragement, inspiration, fun facts, and jokes.

## Features

- **SwiftUI** with iOS 17+ (uses @Observable, modern APIs)
- **MVVM Architecture** - clean separation of concerns
- **4 Content Categories** - Encouragement, Inspiration, Fun Facts, Jokes
- **Crowdsourced Content** - users submit, vote, and report content
- **Daily Check-in System** - streak tracking with progressive point rewards
- **Points Economy** - earn points via check-ins, spend to unlock content
- **Swipeable Content Cards** - beautiful card-based content viewer
- **Offline Support** - cached content, saved items, and user profile
- **Push Notifications** - user-configurable daily reminders
- **Secure Auth** - JWT tokens stored in Keychain
- **Beautiful UI** - pink/yellow/green/blue color scheme matching the brand

## Requirements

- Xcode 15+
- iOS 17+
- Swift 5.9+

## Setup

### 1. Create Xcode Project

1. Open Xcode
2. Create new project: **iOS > App**
3. Product Name: `MoodLift`
4. Interface: **SwiftUI**
5. Language: **Swift**
6. Storage: **None** (we use custom caching)

### 2. Add Source Files

Copy all files from the `MoodLift/` directory into your Xcode project:

```
MoodLift/
├── MoodLiftApp.swift          # App entry point
├── Models/
│   ├── User.swift             # User model
│   ├── Content.swift          # Content models
│   ├── CheckinInfo.swift      # Check-in models
│   ├── PointsTransaction.swift # Transaction models
│   ├── SavedItem.swift        # Saved item model
│   ├── UserStats.swift        # Stats model
│   └── APIError.swift         # Error types
├── Services/
│   ├── APIService.swift       # HTTP client (actor)
│   ├── AuthService.swift      # Authentication
│   ├── ContentService.swift   # Content operations
│   ├── CheckinService.swift   # Daily check-in
│   ├── SavedService.swift     # Saved items
│   ├── PointsService.swift    # Points & stats
│   └── NotificationService.swift # Push notifications
├── ViewModels/
│   ├── HomeViewModel.swift
│   ├── ContentViewModel.swift
│   ├── SavedItemsViewModel.swift
│   ├── ProfileViewModel.swift
│   ├── SubmitContentViewModel.swift
│   └── SettingsViewModel.swift
├── Views/
│   ├── Auth/
│   │   ├── LoginView.swift
│   │   └── SignupView.swift
│   ├── Main/
│   │   ├── MainTabView.swift
│   │   ├── HomeView.swift
│   │   ├── ContentDetailView.swift
│   │   ├── DailyCheckinView.swift
│   │   ├── ProfileView.swift
│   │   ├── RecentActivityView.swift
│   │   ├── SavedItemsView.swift
│   │   ├── SettingsView.swift
│   │   └── SubmitContentView.swift
│   └── Components/
│       └── (reusable components)
├── Utilities/
│   ├── Colors.swift           # Color definitions & ContentCategory enum
│   ├── Constants.swift        # App constants
│   └── KeychainHelper.swift   # Secure token storage
└── Persistence/
    └── CacheManager.swift     # Offline caching
```

### 3. Configure API URL

Edit `Services/APIService.swift` and update the `baseURL`:

```swift
private let baseURL = "https://your-api-domain.com/api"
```

For local development, use:
```swift
private let baseURL = "http://localhost:3000/api"
```

### 4. Local development – run the backend first

To test sign up, login, and all API features locally:

1. **Start the MoodLift backend** (sibling repo `mood_lift_web`):
   ```bash
   cd ../mood_lift_web
   npm install
   cp .env.example .env
   # Edit .env: set DB_PASSWORD (and DB_* if needed)
   ```
2. **Create the database and schema** (PostgreSQL must be running):
   ```bash
   psql -U postgres -c "CREATE DATABASE moodlift;"
   psql -U postgres -d moodlift -f models/schema.sql
   ```
3. **Start the API server** (default port 3000):
   ```bash
   npm run dev
   ```
   You should see: `MoodLift server running on port 3000`.
4. **Run the iOS app** from Xcode (⌘R) with the simulator. The app uses `http://localhost:3000/api`; the simulator uses your Mac’s localhost, so sign up and login will hit this backend.

If you see **"Something went wrong"** on sign up or login, the app likely cannot reach the API: ensure the backend is running on port 3000 and the database is set up.

### 5. Configure Notifications

In Xcode:
1. Go to project settings > Signing & Capabilities
2. Add **Push Notifications** capability
3. Add **Background Modes** > Remote notifications

### 6. Build and Run

1. Select your target device/simulator (iOS 17+)
2. Build and run (Cmd+R)

## Architecture

### MVVM Pattern

```
View → ViewModel → Service → APIService → Backend
                      ↓
                  CacheManager (offline)
```

- **Views**: SwiftUI views, purely declarative UI
- **ViewModels**: @Observable classes with business logic
- **Services**: Networking and data operations
- **APIService**: Central HTTP client (Swift actor for thread safety)
- **CacheManager**: File-based offline caching

### Authentication Flow

1. User logs in/registers → JWT token received
2. Token stored securely in iOS Keychain
3. Token attached to all API requests via Authorization header
4. On app launch, token checked and profile loaded
5. On logout, token removed from Keychain

### Content Flow

1. Home screen shows 4 category cards
2. Tap category → ContentDetailView loads daily assignments
3. First item is free, others require points to unlock
4. Users can vote (up/down), save, and report content
5. Users can submit their own content via SubmitContentView

### Points System

| Action | Points |
|--------|--------|
| Sign up bonus | +5 |
| Daily check-in (days 1-6) | +1 |
| Daily check-in (day 7+) | +(5/7 * day) |
| 30-day bonus | +10 |
| First content unlock | -5 |
| Subsequent unlocks | -15 |

### Offline Support

- Content cached per category
- Daily content cached per day
- Saved items cached locally
- User profile cached
- Check-in info cached
- Graceful fallback to cache when network unavailable

## Color Scheme

| Category | Color | Hex |
|----------|-------|-----|
| Encouragement | Pink | #ff6b6b |
| Inspiration | Yellow | #ffd93d |
| Fun Facts | Green | #4ecdc4 |
| Jokes | Blue | #45b7d1 |

## Backend

This app connects to the MoodLift backend API (see `../mood_lift_web/`).

## Contributing

1. Follow SwiftUI best practices
2. Use @Observable for ViewModels (iOS 17+)
3. Keep views small and composable
4. Use the color system from `Colors.swift`
5. Cache all network responses for offline support
