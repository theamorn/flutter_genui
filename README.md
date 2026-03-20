# Flutter GenUI Interactive AI Assistant

A state-of-the-art Flutter application demonstrating the sheer power of **Generative UI** using Google Gemini. This app connects a traditional chat interface to the `genui` framework, allowing the AI to stream not just raw text—but completely rendered, interactive, responsive high-fidelity Flutter Widgets directly into the chat flow. 

Built with a stunning futuristic "Dark HUD" aesthetic (think JARVIS-like neon glows, deep dark blues, and monospace tech-typography), this application showcases a seamless bridge between Flutter's UI declarative nature and `gemini-3-flash-preview` intelligence.

## 🚀 Key Features

* **Conversational Generative UI (`ChatScreen`)**: An interactive chat list view built over `GenUiConversation` and `A2uiMessageProcessor`. Send a message, and watch the AI stream text—and instantiate bespoke, stateful Flutter Widgets in response to your queries.
* **Component Catalog Previewer**: A built-in floating catalog directory allows you to inspect the system's available generative widgets and inject mocked rendering previews instantly via pop-up dialogs.
* **Dynamic Event Host Interception**: Showcases how to decouple URL launching logic and other side effects from the components themselves by having the *Flutter Host Application* intercept `UserActionEvent` classes directly from the `CustomA2uiMessageProcessor` pipeline.
* **Futuristic HUD UI Aesthetics**: Advanced Dart widget styling replacing generic `Card` widgets with deeply stylized semi-transparent containers, neon boxShadow gradients, linear gradients, and `BoxShape` glassmorphism filters.

## 🧩 The Generated UI Catalog (`catalog.dart`)

The AI is equipped with a heavily customized `Catalog` of tools representing real-world financial/personal assistant logic. 
Each catalog item uses robust typing powered by `json_schema_builder` and handles missing arguments safely. 

1. **`ExpenseProgressLineGraph`**: A visually rich, draggable progression bar showing monthly budgeting stats. The progress gradient changes color dynamically (Neon Green -> Orange -> Red) based on expenditures.
2. **`DailyBalanceWidget`**: A HUD data check-in tracker acting as an interactive Stepper modifier. Users can dial their daily limits up or down on the fly, accompanied by system logs showing itemized, daily granular deductions.
3. **`StockWidget`**: An asset portfolio analyzer mapping company ticker names to live corporate brand logos dynamically via Clearbit's image API, presenting real-time price drops and gains through colorized indicators.
4. **`RecommendExpenseWidget`**: A highly interactive widget rewarding the user for frugal expenditures. Tapping the generating token initializes a particle/confetti blast sequence via the `confetti` package.
5. **`ProductShoppingWidget`**: An advanced cyber-themed shopping card displaying dynamic high-resolution product images (utilizing Unsplash as intelligent fallbacks), memory specs, estimated fiat valuation, and executing an "AUTHORIZE PROCUREMENT" hook leading to Gemini via `url_launcher`.

## 🛠️ Tech Stack & Packages Used

* `flutter` (SDK 3.11.0+)
* `genui` & `genui_firebase_ai`: Core generative UI processing framework provided by Google.
* `json_schema_builder`: For structurally defining how the agent maps generative data down to the app's widgets.
* `firebase_core` & `firebase_ai`: Establishing secure AI conversational streams.
* `confetti`: Complex particle emission effects.
* `url_launcher`: Offloading host-app intents to external browser environments.

## ⚙️ Getting Started

1. Set up your Flutter environment and install the required dependencies:  
   `flutter pub get`
2. Run the application via simulator, web, or physical device:  
   `flutter run`
3. Ask the assistant something like:  
   > "How are my Google and Apple stocks doing today?"  
   > "I want to buy a high-end mechanical keyboard."  
   > "What is my daily spending check-in?"  
   
...and watch the UI manifest right in front of your eyes!
