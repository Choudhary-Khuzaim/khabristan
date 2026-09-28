# KhabarIsTan - Premium Flutter News Application

<p align="center">
  <img src="assets/readme/banner.png" alt="KhabarIsTan Banner" width="100%" onerror="this.style.display='none'">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Version-2.1.0-FFD700?style=for-the-badge&logoColor=white&color=002366" alt="Version">
  <img src="https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Theme-Glassmorphism-002366?style=for-the-badge" alt="Theme">
  <img src="https://img.shields.io/badge/Material--3-7D5260?style=for-the-badge&logo=materialdesign&logoColor=white" alt="Material 3">
</p>

## Overview

**KhabarIsTan** is a high-fidelity, ultra-premium news reading application built with Flutter. Designed with a "Luxury First" philosophy, it completely reimagines the news consumption experience by combining a modern **Glassmorphic** UI aesthetic with highly functional features like AI Voice Reporting (TTS), smart offline bookmarking, and seamless in-app web views. 

Whether you are browsing top headlines, exploring specific sources, or reading full articles, KhabarIsTan delivers a flawless, animated, and immersive experience.

---

## ✨ Key Features

- **💎 Glassmorphic UI & Royal Aesthetics**: A complete visual treat featuring frosted glass containers, smooth blur effects (`BackdropFilter`), and elegant gradients using modern typography (Google Fonts).
- **🎙️ AI Voice Reporting (TTS)**: Fully integrated Text-to-Speech (`flutter_tts`) allows users to listen to news articles hands-free with playback controls.
- **🔖 Smart Bookmarking**: Save your favorite articles locally via `shared_preferences` for quick access later in the "Saved News" section.
- **🌗 Adaptive Theming**: Real-time, dynamic Light and Dark mode switching that automatically respects system preferences or user overrides.
- **🌐 In-App Browser**: Read full, detailed articles without leaving the application context via integrated `webview_flutter`.
- **🚀 Immersive Animations**: From the Welcome Screen to the staggered list animations (`flutter_staggered_animations`) and shimmer loading states, every interaction feels cinematic and responsive.
- **📰 Comprehensive News Engine**: Fetches, parses, and categorizes news intelligently. Includes dedicated screens for exploring categories, viewing all news, and drilling down into specific news sources.
- **🛡️ Privacy & Legal**: Built-in dedicated Legal/Privacy screens to maintain transparency with users.

---

## 📱 Screens & Navigation Flow

1. **Welcome Screen** (`welcome_screen.dart`): An engaging onboarding experience that introduces the user to the app's premium feel.
2. **Home Screen** (`home_screen.dart`): The central hub featuring top headlines, categorized feeds, and visually stunning "Featured News Cards".
3. **Explore Screen** (`explore_screen.dart`): Discover news by categories and specific media sources.
4. **News Detail Screen** (`news_detail_screen.dart`): A beautiful, parallax-style article reader with options to share, bookmark, and listen to the article via TTS.
5. **Article View Screen** (`article_view_screen.dart`): An embedded WebView for reading the source's complete webpage directly within the app.
6. **Saved News Screen** (`saved_news_screen.dart`): A dedicated space for all your bookmarked content.
7. **Source News Screen** (`source_news_screen.dart`): Filter and read news tailored to specific publishers.

---

## 🏗️ Architecture & Folder Structure

The project follows a clean, modular architecture ensuring high maintainability and scalability:

```text
lib/
├── main.dart                  # App Entry Point & Theme Initialization
├── models/                    # Data Models (e.g., NewsModel)
├── screens/                   # UI Views (Home, Explore, Detail, etc.)
├── services/                  # Business Logic & API Handlers
│   ├── bookmarks_service.dart # Local Storage for Saved News
│   ├── news_service.dart      # Network API calls and XML/JSON Parsing
│   ├── preferences_service.dart # User Settings & Configuration
│   └── theme_service.dart     # Dynamic Theme Management
├── utils/                     # Helpers (Date formatting, String formatting)
└── widgets/                   # Reusable UI Components
    ├── featured_news_card.dart# Glassmorphic featured cards
    ├── news_card.dart         # Standard list news cards
    ├── glass_background.dart  # Reusable frosted glass wrapper
    ├── glass_container.dart   # Reusable frosted container
    └── shimmer_loading.dart   # Skeleton loading animations
```

---

## 🛠️ Modern Tech Stack

This project leverages some of the best packages in the Flutter ecosystem:

- **Core UI**: Flutter SDK (v3.4.0+), Material 3
- **Networking**: `http` (API requests), `xml` (RSS/XML Parsing)
- **Image Handling**: `cached_network_image` (Fast, optimized image caching)
- **Storage**: `shared_preferences` (Local data persistence)
- **Audio/Voice**: `flutter_tts` (Text-to-Speech synthesis)
- **Animations**: `flutter_staggered_animations`, `animations`
- **Web Integration**: `webview_flutter`, `url_launcher`
- **Utility**: `intl` (Date formatting), `share_plus` (Social sharing)

---

## 🚀 Installation & Setup

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (Version 3.4.0 or higher)
- Dart SDK
- Android Studio / VS Code / Xcode

### Getting Started

1. **Clone the repository**
   ```bash
   git clone https://github.com/Choudhary-Khuzaim/khabristan.git
   cd khabristan
   ```

2. **Install Dependencies**
   Run the following command to fetch all required packages:
   ```bash
   flutter pub get
   ```

3. **Run the Application**
   Connect your device or emulator and run:
   ```bash
   flutter run
   ```

---

## 🤝 Contribution Guidelines

Contributions are always welcome! Whether it's a bug report, a new feature, or a UI enhancement, feel free to collaborate.

1. **Fork** the project repository.
2. Create your Feature Branch: `git checkout -b feature/AmazingFeature`
3. Commit your Changes: `git commit -m 'Add some AmazingFeature'`
4. Push to the Branch: `git push origin feature/AmazingFeature`
5. Open a **Pull Request**.

---

## 📄 License

This project is distributed under the MIT License. See the `LICENSE` file for more details.

---

<p align="center">
  Crafted with ❤️ and Excellence by <b>Khuzaim Sajjad</b><br>
  <i>Empowering readers through beautiful technology</i>
</p>
