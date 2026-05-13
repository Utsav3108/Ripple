# Ripple

Ripple is a modern, premium messaging application built with Flutter, featuring a highly polished dark-themed user interface and seamless API integration.

## ✨ Features

- **Premium Dark UI**: A sleek, pure black interface designed with Material Design 3 principles.
- **Dynamic Chat List**: Real-time searchable list of conversations with personas (Presidents).
- **Modern Interactions**: Includes pull-to-refresh, smooth scrolling, and high-quality card components.
- **Global Theme Management**: Centralized theme configuration using the Poppins typeface.
- **Robust Networking**: Integrated with a FastAPI backend using Dio for efficient data fetching.

## 🛠 Tech Stack

- **Frontend**: [Flutter](https://flutter.dev)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Networking**: [Dio](https://pub.dev/packages/dio)
- **Typography**: [Google Fonts (Poppins)](https://pub.dev/packages/google_fonts)
- **Backend**: [FastAPI](https://fastapi.tiangolo.com/) (documented in `lib/Docs/api_doc.md`)

## 📁 Project Structure

```text
lib/
├── Docs/             # API Documentation
├── Model/            # Data models (Persona, Message)
├── Network/          # Dio networking configuration
├── Provider/         # Chat and State providers
├── Theme/            # Global AppTheme and typography
└── chat_list_screen.dart  # Main messaging dashboard
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (^3.9.2)
- Dart SDK
- Android Studio / VS Code

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/Ripple.git
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the application:
   ```bash
   flutter run
   ```

## 📄 API Documentation

Refer to [api_doc.md](lib/Docs/api_doc.md) for detailed information regarding backend endpoints, including:
- President search
- Chat history retrieval
- Message exchange logic

## 🎨 Design Philosophy

Ripple focuses on a "Less is More" approach, utilizing deep blacks (`#000000`), subtle shadows, and a signature lime accent color (`#E6F58A`) to create a high-contrast, readable, and premium messaging experience.
