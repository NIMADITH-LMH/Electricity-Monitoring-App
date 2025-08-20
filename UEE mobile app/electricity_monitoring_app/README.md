# Electricity Monitoring App

A comprehensive mobile application for monitoring electricity usage, managing appliances, setting budgets, and receiving energy-saving tips, built with Flutter and Firebase.

## 📋 Table of Contents

- [Technology Stack](#️-technology-stack)
- [Project Structure](#-project-structure)
- [Prerequisites](#-prerequisites)
- [Installation & Setup](#-installation--setup)
- [Features](#-features)
- [Contributing](#-contributing)

## 🛠️ Technology Stack

- **Frontend**: Flutter (v3.8+)
- **Backend**: Firebase
  - Authentication: Firebase Auth
  - Database: Cloud Firestore
  - Push Notifications: Firebase Messaging
- **State Management**: Provider
- **Visualization**: FL Chart
- **PDF Generation**: PDF package
- **Animations**: Lottie
- **Local Storage**: Shared Preferences
- **Notifications**: Flutter Local Notifications

## 📁 Project Structure

```plaintext
electricity_monitoring_app/
├── lib/                     # Source code
│   ├── animations/          # Animation files
│   ├── models/              # Data models
│   │   ├── appliance_model.dart
│   │   ├── budget_model.dart
│   │   ├── tip_model.dart
│   │   ├── usage_record_model.dart
│   │   └── user_model.dart
│   ├── screens/             # UI screens
│   │   ├── appliance/       # Appliance management screens
│   │   ├── auth/            # Authentication screens
│   │   ├── bills/           # Billing screens
│   │   ├── budget/          # Budget management screens
│   │   ├── dashboard/       # Dashboard views
│   │   ├── home/            # Home screen components
│   │   ├── settings/        # Settings screens
│   │   ├── tips/            # Energy-saving tips screens
│   │   └── usage/           # Usage monitoring screens
│   ├── services/            # Business logic and API services
│   │   ├── appliance_service.dart
│   │   ├── auth_service.dart
│   │   ├── budget_service.dart
│   │   ├── notification_service.dart
│   │   ├── pdf_report_service.dart
│   │   ├── report_service.dart
│   │   ├── tip_service.dart
│   │   ├── usage_record_service.dart
│   │   └── user_profile_service.dart
│   ├── theme/               # App theme configurations
│   ├── utils/               # Utility functions and helpers
│   ├── widgets/             # Reusable UI components
│   └── main.dart            # Application entry point
├── assets/                  # Static assets
│   ├── animations/          # Lottie animation files
│   └── images/              # Image assets
├── android/                 # Android-specific configuration
├── ios/                     # iOS-specific configuration
├── web/                     # Web platform configuration
├── pubspec.yaml             # Dependencies and package configuration
└── README.md                # Project documentation
```

## ✅ Prerequisites

Before you begin, ensure you have the following installed:

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (v3.8 or higher)
- [Dart SDK](https://dart.dev/get-dart) (v3.8 or higher)
- [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/) with Flutter extensions
- [Git](https://git-scm.com/)
- A Firebase account for backend services

## 🚀 Installation & Setup

1. **Clone the repository:**

   ```bash
   git clone https://github.com/NIMADITH-LMH/Electricity-Monitoring-App.git
   cd Electricity-Monitoring-App/UEE\ mobile\ app/electricity_monitoring_app
   ```

2. **Install dependencies:**

   ```bash
   flutter pub get
   ```

3. **Firebase Setup:**
   - Create a new Firebase project in the [Firebase Console](https://console.firebase.google.com/)
   - Add Android & iOS apps to your Firebase project
   - Download and place the `google-services.json` file in the `/android/app/` directory
   - Download and place the `GoogleService-Info.plist` file in the `/ios/Runner/` directory

4. **Run the app:**

   ```bash
   flutter run
   ```

   This command will build the app and run it on a connected device or emulator.

5. **Building for release:**

   ```bash
   flutter build apk --release  # For Android
   flutter build ios --release  # For iOS (requires Mac)
   ```

## ✨ Features

- **User Authentication**: Sign up, login, and password recovery
- **Dashboard**: Overview of electricity usage and costs
- **Appliance Management**: Add, edit, and track electricity consumption of home appliances
- **Usage Monitoring**: Track and visualize electricity usage patterns
- **Budget Planning**: Set and monitor electricity budget goals
- **Energy-Saving Tips**: Receive personalized tips to reduce electricity consumption
- **Bill Management**: Track and manage electricity bills
- **Reports**: Generate and export PDF reports of usage history
- **Notifications**: Receive alerts for budget limits, tips, and important updates
- **User Profile**: Manage personal information and app preferences
- **Settings**: Customize app behavior and notification preferences

## 👥 Contributing

1. Fork the repository
2. Create a new branch (`git checkout -b feature/your-feature-name`)
3. Commit your changes (`git commit -m 'Add some feature'`)
4. Push to the branch (`git push origin feature/your-feature-name`)
5. Open a Pull Request
