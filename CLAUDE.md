# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Family Star is a Flutter application for parents to track their children's tasks, reward them with stars, and manage family objectives. The app uses Firebase for authentication and data storage, with Provider for state management.

## Common Commands

### Development
- `flutter run` - Run the app in debug mode
- `flutter pub get` - Get dependencies after pulling changes
- `flutter clean` - Clean build artifacts (useful when switching branches or fixing build issues)

### Testing
- `flutter test` - Run all tests
- `flutter test test/widget_test.dart` - Run a specific test file

### Analysis
- `flutter analyze` - Analyze code for errors, warnings, and lints
- `dart format .` - Format all Dart code

### Build
- `flutter build apk` - Build Android APK
- `flutter build ios` - Build iOS app
- `flutter build web` - Build web app

## Architecture

### State Management
Uses **Provider** pattern with two main providers:
- `AuthProvider` - Manages user authentication state and operations (login, register, Google Sign-In)
- `ChildrenProvider` - Manages children data and CRUD operations

### Firebase Integration
- **Firebase Auth**: Email/password and Google Sign-In authentication
- **Cloud Firestore**: Real-time database with collections for parents, children, tasks, and star_losses
- **Firebase Storage**: Image storage for profile photos
- Dual storage approach: SQLite (local) and Firestore (cloud sync)

### Data Models
Located in `lib/models/`:
- `Parent` - Parent user data
- `Child` - Child profile with stars, objectives, birth date calculations
- `Task` - Tasks with status, rewards, recurrence
- `StarLoss` - Records of star deductions

### Services Layer
- `FirebaseAuthService` - Firebase authentication operations
- `FirestoreService` - Cloud Firestore CRUD operations with real-time streams
- `DatabaseService` - Local SQLite database operations
- `FirebaseStorageService` - Image upload/download to Firebase Storage

### UI Structure
- `lib/screens/auth/` - Login and registration screens
- `lib/screens/dashboard/` - Main dashboard after login
- `lib/screens/children/` - Child management, profiles, and add child screens

### Routing
App uses named routes defined in [main.dart](lib/main.dart):
- `/login` - Login screen
- `/dashboard` - Dashboard screen
- `AppRouter` widget handles authentication-based routing

## Firebase Setup

Firebase configuration is required before running the app. See [FIREBASE_SETUP.md](FIREBASE_SETUP.md) for detailed setup instructions including:
- Creating Firebase project
- Enabling Authentication (Email/Password, Google Sign-In)
- Setting up Firestore Database
- Configuring platform-specific files (`google-services.json`, `GoogleService-Info.plist`)
- Security rules for Firestore

The `firebase_options.dart` file must be updated with your Firebase project credentials.

## Key Dependencies

- `provider: ^6.1.2` - State management
- `firebase_core: ^3.6.0` - Firebase initialization
- `firebase_auth: ^5.3.1` - Authentication
- `cloud_firestore: ^5.4.3` - Cloud database
- `firebase_storage: ^12.3.2` - File storage
- `google_sign_in: ^6.2.1` - Google authentication
- `sqflite: ^2.3.3+1` - Local SQLite database
- `shared_preferences: ^2.2.3` - Local key-value storage
- `image_picker: ^1.1.2` - Image selection from device
- `flutter_rating_bar: ^4.0.1` - Star rating UI component