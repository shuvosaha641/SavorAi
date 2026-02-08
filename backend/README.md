# SavorAI Backend Setup Guide

## Step 1: Install Node.js Dependencies

In PowerShell, navigate to the backend folder and install:

```powershell
cd backend
npm install
```

This will install:

- express (web server)
- groq-sdk (AI integration)
- cors (allow Flutter to connect)

## Step 2: Set Your Groq API Key

In PowerShell:

```powershell
$env:GROQ_API_KEY="your_groq_api_key_here"
```

Replace `your_groq_api_key_here` with the actual key you got from Groq.

## Step 3: Start the Backend

```powershell
npm start
```

You should see:

```
🚀 SavorAI Backend running on port 8080
🔑 API Key configured: Yes
```

## Step 4: Install ngrok

1. Download from: https://ngrok.com/download
2. Sign up for free account
3. Get auth token from dashboard
4. In PowerShell:

```powershell
ngrok authtoken your_token_here
```

## Step 5: Expose Backend with ngrok

Open a NEW PowerShell terminal and run:

```powershell
ngrok http 8080
```

You'll see output like:

```
Forwarding  https://abcd-1234-5678.ngrok-free.app -> http://localhost:8080
```

Copy that HTTPS URL (e.g., `https://abcd-1234-5678.ngrok-free.app`)

## Step 6: Update Flutter ChatService

In `lib/services/chat_service.dart`, replace:

```dart
static const String _backendUrl = 'http://localhost:8080';
```

With your ngrok URL:

```dart
static const String _backendUrl = 'https://abcd-1234-5678.ngrok-free.app';
```

## Step 7: Update home.dart

Add this import at the top:

```dart
import 'package:recipeappflutter/pages/chat_page.dart';
```

Replace the `_buildChatFab()` onTap:

```dart
onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const ChatPage()),
  );
},
```

## Step 8: Test

1. Hot restart Flutter app
2. Tap the chatbot icon (bottom-left)
3. Type ingredients (e.g., "chicken, tomato, garlic")
4. Wait for recipe generation
5. Tap "View Full Recipe"

## Troubleshooting

**Backend not starting?**

- Make sure Node.js is installed: `node --version`
- Check API key is set: `echo $env:GROQ_API_KEY`

**Flutter can't connect?**

- Use ngrok URL, not localhost
- Make sure ngrok is running
- Check firewall isn't blocking

**Recipe not generating?**

- Check backend console for errors
- Test backend directly: `curl http://localhost:8080`
- Verify Groq API key is valid

## Keep Running

For development:

- Terminal 1: `cd backend && npm start` (backend)
- Terminal 2: `ngrok http 8080` (expose)
- Terminal 3: `flutter run` (app)

Each time you restart ngrok, you'll get a new URL—update ChatService accordingly.
