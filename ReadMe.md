# SpotIt Flutter Codebase Client setup 📱

This folder contains a fully translated **Flutter & Dart** implementation of the SpotIt decentralized citizen report desk, tailored specifically for mobile phone deployment. It matches the beautiful high-fidelity custom design grids, fonts, maps, and offline fallback flows of the Web App exactly, but adds Native Mobile Geolocation capabilities!

---

## 🚀 Key Mobile Features Added

1. **Native Location Synchronization**: Taking real location access upon opening. It maps instantly to where you are living right now using native Android/iOS GPS coordinates, reverse-geocoding the location using Nominatim open-source APIs.
2. **Pulsing Blue Position Pin**: Places a live pinpoint blue pulsing dot to mark your localized physical spot in real-time.
3. **Tactile Sparkle Particles Overlay**: A performance-optimized custom painter particle system emitting gentle sparkles (✨, ✦, ⭐) upon every screen tap, mirroring the web experience elegantly.
4. **Offline Fallback Sync**: Continues running beautifully on local memory database buffers even if offline or before Firebase initialization parameters are setup!

---

## 🛠️ Step-by-Step Implementation Guide

To run this app on your physical mobile device/simulator:

### 1. Install Flutter SDK
Make sure you have Flutter installed on your system. Run `flutter doctor` in your terminal to see if everything is green.

### 2. Extract into Flutter workspace
1. Download standard zip file from AI Studio
2. Locate the `/flutter_app` folder
3. Run the following command inside `/flutter_app` directory to fetch absolute dependencies:
   ```bash
   flutter pub get
   ```

### 3. Open Emulator or Connect Physical Phone
- Enable **USB Debugging** on your phone (under Developer Settings).
- Connect via USB or start an Android/iOS emulator block.
- Verify connected devices:
   ```bash
   flutter devices
   ```

### 4. Boot App
Deploy directly using:
```bash
flutter run
```

---

## 🔥 Hooking Up to Firebase Firestore Database

To bind this client to real, permanent, multi-user Cloud storage in 3 straightforward steps:

### Step 1: Initialize Firebase Project
1. Go to the [Firebase Console](https://console.firebase.google.com/).
2. Create a new project called `SpotIt`.

### Step 2: Set Up Mobile Client Apps in Firebase Console
For Android or iOS integration, Firestore requires credentials inside the directory to recognize permissions:

#### For Android:
1. Click the **Android Icon** in your project dashboard.
2. Add your package name (e.g., `com.spotit.app`).
3. Download the `google-services.json` file.
4. Drag and drop `google-services.json` into `/flutter_app/android/app/` folder.

#### For iOS:
1. Click the **iOS Icon** in your project dashboard.
2. Add your Bundle ID.
3. Download `GoogleService-Info.plist`.
4. Drag and drop `GoogleService-Info.plist` into `/flutter_app/ios/Runner/` folder via Xcode.

### Step 3: Run FlutterFire configuration (Simplest Method)
Alternatively, you can configure everything automatically with the Flutter CLI:
```bash
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
flutterfire configure
```
This generates `firebase_options.dart` under `lib/` and wires up everything cleanly!

### Step 4: Write Database Rule and Authentication
1. Go to **Authentication** in your Firebase console and enable **Anonymous sign-in** under Sign-in methods.
2. Go to **Firestore Database**, create a database, and set rules to allow read/write access. Here are the matching Firestore rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if true;
    }
    match /issues/{issueId} {
      allow read, write: if true;
    }
  }
}
```

Now you are fully ready to report, resolve, and locate live community hazards! 🚀
