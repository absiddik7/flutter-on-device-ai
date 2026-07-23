# Local AI: On-Device Assistant 🤖📱

A premium, privacy-first Flutter application that runs a large language model (LLM) entirely **on-device** using native `llama.cpp` bindings. No internet connection is required after the initial model download, ensuring complete data privacy and zero latency.

## ✨ Features

- **100% Offline Inference**: Runs the Qwen 2.5 1.5B Instruct model locally on your phone using the `fllama` package (a wrapper for `llama.cpp`).
- **Automated Model Management**: Intelligently checks for the GGUF model on startup. If missing, it downloads the model automatically with a beautiful, real-time progress UI and size validation.
- **Token-by-Token Streaming**: Experience fast, real-time chat responses as the model generates them token-by-token.
- **Native Prompt Formatting**: Automatically builds ChatML formatted prompts for optimal responses from the Qwen instruct model.
- **Premium UI/UX**: Features a sleek, modern dark theme with glass-like surfaces, animated typing indicators, custom message bubbles, and fluid transitions.

## 🛠 Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **Inference Engine**: [fllama](https://pub.dev/packages/fllama) (`llama.cpp`)
- **Networking**: [Dio](https://pub.dev/packages/dio) (for downloading the GGUF model)
- **UI & Styling**: Vanilla Flutter widgets, custom gradient backgrounds, and [Google Fonts](https://pub.dev/packages/google_fonts) (Inter).

## Screenshots
| Model Download | AI Chat |
|:--------------:|:--------------------:|
|<img width="1080" height="1500" alt="model_download_screen" src="https://github.com/user-attachments/assets/0c0863c2-e586-413a-b044-ef074255fb61" />|<img width="1080" height="1500" alt="ai_chat_screen" src="https://github.com/user-attachments/assets/fd285cd1-b530-4a8c-b4b2-4be4f3043317" />|



## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Android Studio / Xcode for deploying to a physical device.
- **Note on Performance**: Running a 1.5B parameter LLM requires a modern smartphone with a decent amount of RAM. Running on a physical device is highly recommended over an emulator.

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/absiddik7/flutter-on-device-ai.git
   cd flutter-on-device-ai
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run --release
   ```
   *Tip: Use `--release` mode for significantly better inference performance compared to debug mode.*

## 📂 Project Structure

```text
lib/
├── core/
│   ├── constants.dart       # App-wide configurations, URLs, and generation settings
│   └── theme.dart           # Global dark theme and color palette
├── models/
│   └── chat_message.dart    # Data model for conversation history
├── screens/
│   ├── chat_screen.dart     # Main chat UI with real-time streaming
│   └── download_screen.dart # Splash screen & model downloader UI
├── services/
│   ├── download_service.dart # Handles HTTP downloading and file checks
│   └── llm_service.dart      # Wrapper around fllama for context management and inference
└── main.dart                # App entry point
```

## 🧠 Model Information

By default, the app is configured to use:
- **Model**: [Qwen2.5-1.5B-Instruct-Q4_K_M.gguf](https://huggingface.co/bartowski/Qwen2.5-1.5B-Instruct-GGUF)
- **Format**: GGUF (Q4_K_M quantization)
- **Size**: ~1.1 GB

These parameters can be easily adjusted in `lib/core/constants.dart` if you wish to experiment with different GGUF models.

## 🛡 Privacy

All conversations happen securely on your device. Once the model is downloaded, the app can function completely completely offline without sending any data to external servers.
