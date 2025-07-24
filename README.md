🚀 ChatGPT Flutter Clone
A pixel-perfect, feature-rich ChatGPT clone built with Flutter, showcasing clean architecture, BLoC state management, and direct integration with OpenAI API, Cloudinary for image uploads, and MongoDB for chat history persistence.

<p align="center">
<img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter Badge">
<img src="https://img.shields.io/badge/BLoC-00B2E2?style=for-the-badge&logo=bloc&logoColor=white" alt="BLoC Badge">
<img src="https://img.shields.io/badge/OpenAI-412991?style=for-the-badge&logo=openai&logoColor=white" alt="OpenAI Badge">
<img src="https://img.shields.io/badge/Cloudinary-3448C5?style=for-the-badge&logo=cloudinary&logoColor=white" alt="Cloudinary Badge">
<img src="https://img.shields.io/badge/MongoDB-47A248?style=for-the-badge&logo=mongodb&logoColor=white" alt="MongoDB Badge">
<img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License Badge">
</p>

✨ Features
💬 Chat Interface: Responsive and pixel-perfect UI mirroring ChatGPT's mobile app.

🗣️ Multimodal Input: Send text messages and upload images for analysis (powered by OpenAI Vision models like GPT-4o).

⬆️ Image Uploads: Seamless direct image uploads to Cloudinary.

📜 Chat History: Persistent storage and retrieval of conversations using MongoDB.

🔄 Model Selection: Option to switch between different OpenAI models (e.g., GPT-4o, GPT-3.5 Turbo).

➕ New Chat: Easily start fresh conversations.

🔍 Search History: Search through past conversations in the sidebar.

🗑️ Delete Chat: Dismiss individual conversations from history.

📸 Camera & Gallery: Choose images from your device's gallery or capture new photos with the camera.

🔄 Loading Indicators: Clear visual feedback for image uploads and AI processing.

📱 Cross-Platform: Works seamlessly on both Android and iOS.

⚙️ BLoC State Management: Robust, predictable, and testable state management.

🔐 Device-Specific History: Each device maintains its own chat history.

📸 Screenshots / Demo
(Add your beautiful screenshots or a short GIF/video demo here to showcase the app!)

🛠️ Tech Stack
Frontend Framework: Flutter

State Management: BLoC / flutter_bloc

API Integration:

OpenAI Chat Completion API

Database: MongoDB Atlas

Database Client: mongo_dart (for direct MongoDB connection)

Cloud Storage: Cloudinary

Image Picking: image_picker

Environment Variables: flutter_dotenv

Local Storage: shared_preferences

Unique IDs: uuid

Fonts: Google Fonts (Inter font for ChatGPT aesthetic)

⚠️ Security Warning (Crucial for Internship / Production)
This project demonstrates direct client-side integration with Cloudinary (via unsigned uploads) and MongoDB (via mongo_dart). This approach is highly insecure and is NOT suitable for production applications.

Cloudinary (Unsigned Uploads): Your Cloudinary Cloud Name and Upload Preset are exposed in the app. Anyone can find these and potentially upload unauthorized content to your Cloudinary account, consuming your resources.

MongoDB (mongo_dart): Your MongoDB connection string (including username and password) is embedded in the app. This is easily discoverable, granting anyone full read/write/delete access to your entire database.

For a secure, production-ready application, you MUST implement a separate backend server. This backend would:

Securely store your Cloudinary API Key/Secret and generate signed upload parameters.

Handle all MongoDB interactions, authenticating requests and applying proper access control.

Please discuss these critical security implications with your internship mentors.

🚀 Getting Started
Follow these steps to get the project up and running on your local machine.

1. Prerequisites
Flutter SDK installed and configured.

Git installed.

An IDE like VS Code with Flutter extensions or Android Studio.

Cloudinary Account: Create a free account at cloudinary.com.

Create an Unsigned Upload Preset: Go to Settings > Upload > Upload presets > Add upload preset. Set Signing Mode to "Unsigned". Note your Cloud Name and the Preset Name.

MongoDB Atlas Account: Create a free account at cloud.mongodb.com.

Create a Free Cluster (M0 Sandbox).

Create a Database User: Go to Security > Database Access > Add New Database User. Grant readWriteAnyDatabase role (or specific roles for chat_db). Save the username and password!

Configure Network Access: Go to Security > Network Access. Click Add IP Address. For testing, you can temporarily select "Allow Access from Anywhere" (0.0.0.0/0). (Remember to remove this for security after testing if not needed).

Get Connection String: Go to Database Deployments, click Connect on your cluster. Choose Connect your application. Select Node.js (or Python) as the driver to get the URI. It will look like mongodb+srv://<username>:<password>@cluster0.abcde.mongodb.net/.

Important: Replace <username> and <password> with your database user's credentials.

Append your database name: Add /chat_db?retryWrites=true&w=majority to the end of the URI (assuming your database is chat_db).

Example: mongodb+srv://myuser:mypassword@cluster0.abcde.mongodb.net/chat_db?retryWrites=true&w=majority

OpenAI Account: Create an account at platform.openai.com.

Generate an API Key from API keys section.

2. Clone the Repository
git clone https://github.com/YOUR_USERNAME/YOUR_REPOSITORY.git
cd YOUR_REPOSITORY_FOLDER

3. Install Dependencies
flutter pub get

4. Configure Environment Variables
Create a file named .env in the root of your project (same level as pubspec.yaml).

OPENAI_API_KEY="sk-YOUR_OPENAI_API_KEY"
CLOUDINARY_CLOUD_NAME="YOUR_CLOUDINARY_CLOUD_NAME"
CLOUDINARY_UPLOAD_PRESET="YOUR_CLOUDINARY_UPLOAD_PRESET_NAME"
MONGO_DB_CONNECTION_STRING="YOUR_MONGODB_CONNECTION_STRING"

Important:

Replace placeholders with your actual keys/names.

Wrap values in double quotes.

Do NOT commit this .env file to public repositories! Add .env to your .gitignore.

5. Update pubspec.yaml Assets
Ensure your .env file is included as an asset. Open pubspec.yaml and add:

flutter:
  uses-material-design: true

  assets:
    - .env # Make sure this line is present

Then run flutter pub get again.

6. iOS Specific Setup
If you are building for iOS, you need to add privacy descriptions to ios/Runner/Info.plist:

<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs access to your photo library to allow you to select images for chat messages.</string>
<key>NSCameraUsageDescription</key>
<string>This app needs access to your camera to allow you to take photos for chat messages.</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app needs access to your microphone to allow you to record voice messages.</string>

7. Run the Application
flutter run

Connect an Android or iOS device/emulator. The app should launch.

💡 Usage
Start a New Chat: The app will automatically start a new chat.

Type Messages: Use the input field at the bottom.

Upload Images: Click the image icon to choose from the gallery or take a photo. The image will be sent with your message and analyzed by the AI (if using a vision model like GPT-4o).

Select Model: Use the dropdown in the AppBar to switch between available OpenAI models.

View History: Open the left-hand drawer to see previous conversations.

Search History: Use the search bar in the drawer to filter conversations.

Delete History: Swipe left on a conversation in the history list to delete it.

📈 Future Enhancements
Authentication: Implement user authentication (e.g., Firebase Auth, custom backend) for more secure and personalized chat history.

Streaming Responses: Implement real-time streaming of AI responses for a smoother user experience.

Voice Input/Output: Integrate text-to-speech (TTS) and speech-to-text (STT) for voice interactions.

Backend Server: Migrate Cloudinary and MongoDB logic to a dedicated backend server for enhanced security and scalability.

Real-time Database Sync: For mongo_dart, use change streams to update chat history in real-time if multiple devices are logged in.

Error Handling: More granular and user-friendly error messages and retry mechanisms.

UI/UX Polish: Add subtle animations, better empty states, and haptic feedback.

Unit & Integration Tests: Implement comprehensive tests for BLoCs, repositories, and UI.

