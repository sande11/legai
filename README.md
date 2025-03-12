LegAI - AI-Powered Legal Assistant

LegAI is a Flutter-based AI-powered legal assistant that helps users get answers to legal questions through text, voice, and images. The app provides real-time legal insights based on various constitutional laws from different countries.

Features

✅ Splash Screen - Displays every time the app is launched.
✅ Onboarding Screen - Shown only to first-time users.
✅ Authentication - Login & Registration system.
✅ AI Chatbot - Ask legal questions via text, voice, or images.
✅ Chat History - Saves previous conversations for easy access.
✅ User Account & Settings - Manage profile and preferences.

Project Structure

1. /lib (Root)
main.dart → App entry point. Initializes state & routing.
2. /blocs (State Management using BLoC)
auth_bloc.dart → Handles authentication state.
chat_bloc.dart → Manages AI chat logic.
3. /models (Data Models)
user_model.dart → Defines user attributes.
message_model.dart → Defines chat message structure.
4. /repositories (Backend API)
auth_repository.dart → Handles authentication requests.
chat_repository.dart → Connects to AI model for legal queries.
5. /screens (UI Pages)
splash_screen.dart → Initial loading screen.
onboarding_screen.dart → Introduction for first-time users.
login_screen.dart → Login & registration page.
home_screen.dart → Main chat interface.
6. /widgets (Reusable Components)
custom_drawer.dart → Sidebar for navigation.
chat_bubble.dart → Chat UI element.
Installation & Setup

Prerequisites
Install Flutter SDK (latest version).
Install Dart.
Setup Android Studio or VS Code with Flutter plugin.
