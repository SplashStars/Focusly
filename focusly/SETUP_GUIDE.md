# 🚀 Focusly — Complete Setup Guide
### From Zero → Running on Android → Live on Google Play Store

---

## ⚡ QUICK OVERVIEW

You will do these 4 things (in order):
1. Install tools on your computer (Flutter + Android Studio)
2. Set up the Focusly project
3. Run it on your Android phone or emulator
4. Publish to the Google Play Store

**Total time:** 2–4 hours for a first-timer

---

## STEP 1 — Install Flutter SDK

Flutter is the tool that turns the Focusly code into an Android app.

1. Go to **https://flutter.dev/docs/get-started/install**
2. Click your operating system (Windows / Mac / Linux)
3. Download the Flutter SDK `.zip` file
4. Unzip it to a simple path — **no spaces in the folder name!**
   - ✅ Good: `C:\flutter` or `C:\dev\flutter`
   - ❌ Bad: `C:\Program Files\flutter` (has a space)

5. **Add Flutter to PATH** so your terminal can find it:

   **Windows:**
   - Search "environment variables" in Start Menu
   - Click "Environment Variables"
   - Under "System variables", find `Path` → click Edit → click New
   - Type: `C:\flutter\bin` (or wherever you unzipped it)
   - Click OK on all windows

   **Mac / Linux:**
   Open Terminal and run:
   ```bash
   echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.zshrc && source ~/.zshrc
   ```

6. Verify Flutter is installed — open a new terminal and run:
   ```bash
   flutter --version
   ```
   You should see something like `Flutter 3.x.x`

---

## STEP 2 — Install Android Studio

Android Studio gives you the Android build tools and an emulator.

1. Download from **https://developer.android.com/studio**
2. Install with **default settings** (just keep clicking Next/OK)
3. On first launch, complete the Setup Wizard — install the default SDK
4. Once open, go to: **SDK Manager** (wrench icon at top right)
   - Make sure "Android SDK Platform-Tools" is checked ✅
   - Click Apply/OK

---

## STEP 3 — Connect Flutter to Android Studio

In a terminal, run:
```bash
flutter doctor
```

This shows you what's working ✅ and what needs fixing ⚠️.

**Common fixes:**
- If it says "cmdline-tools component is missing": Open SDK Manager → SDK Tools → check "Android SDK Command-line Tools" → Apply
- If it says "Android license not accepted": Run `flutter doctor --android-licenses` and type `y` to each question

Keep running `flutter doctor` until you see mostly green checkmarks.

---

## STEP 4 — Set Up the Focusly Project

### 4A. Create a fresh Flutter project
```bash
flutter create focusly
cd focusly
```
This creates the base project with all the Android plumbing Flutter needs.

### 4B. Replace the files with the Focusly code
Copy everything from the `focusly/` folder in your zip **into** the project folder you just created.

When asked if you want to replace files — say **YES to all**.

Files you're replacing/adding:
- The entire `lib/` folder (all the app screens and logic)
- `pubspec.yaml` (the list of packages/libraries to use)
- `android/app/build.gradle` (Android build settings)
- `android/settings.gradle`
- `android/gradle.properties`
- `android/gradle/wrapper/gradle-wrapper.properties`
- `android/app/src/main/AndroidManifest.xml` (app permissions)
- `android/app/src/main/kotlin/com/example/focusly/MainActivity.kt`
- `android/app/src/main/res/values/styles.xml`
- `android/app/src/main/res/drawable/launch_background.xml`
- `analysis_options.yaml`

### 4C. Install all the packages
```bash
flutter pub get
```
This downloads all the libraries Focusly needs. Takes 1–2 minutes.

---

## STEP 5 — Run on an Emulator (Virtual Phone on Your Computer)

### Create an emulator:
1. Open Android Studio
2. Click **Device Manager** (phone icon in the right sidebar)
3. Click **"Create Virtual Device"**
4. Choose **Pixel 8** (or any Pixel) → Click Next
5. Download the latest Android image (click the download arrow) → Next → Finish
6. Click the ▶️ Play button to start the emulator

### Run Focusly:
In your terminal (inside the focusly project folder):
```bash
flutter run
```

The app will build and launch in the emulator. **First build takes 2–5 minutes** — subsequent builds are much faster.

🎉 **You should see Focusly with the purple theme running!**

---

## STEP 6 — Run on Your Real Android Phone (Recommended)

Testing on a real phone gives you the real experience including notifications.

### Enable Developer Mode on your phone:
1. Open **Settings** → **About Phone**
2. Tap **"Build Number"** exactly **7 times** quickly
3. You'll see "You are now a developer!"

### Enable USB Debugging:
1. Go back to **Settings** → **Developer Options** (now visible)
2. Toggle **"USB Debugging"** to ON

### Connect and run:
1. Connect your phone to your computer with a USB cable
2. On the phone, accept the "Allow USB Debugging?" prompt
3. In terminal:
   ```bash
   flutter devices
   ```
   Your phone should appear in the list.
4. Run the app:
   ```bash
   flutter run
   ```
5. Select your phone when asked

---

## STEP 7 — Publish to Google Play Store

### 7A. Create a Developer Account (one-time, $25 fee)
1. Go to **https://play.google.com/console**
2. Sign in with your Google account
3. Pay the $25 registration fee
4. Fill in the developer profile form

### 7B. Generate Your App Signing Key (KEEP THIS FILE SAFE FOREVER!)
This is like a digital signature that proves you own the app.

```bash
keytool -genkey -v -keystore ~/focusly-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias focusly
```

You'll be asked several questions:
- Enter a password (remember it!)
- Enter your name, organization, city, country
- Confirm with `yes`

The file `focusly-keystore.jks` is created in your home folder. **Back this up to Google Drive or Dropbox — if you lose it, you can never update your app.**

### 7C. Configure Signing in the Project

Create a new file `android/key.properties` with this content:
```
storePassword=YOUR_PASSWORD_HERE
keyPassword=YOUR_PASSWORD_HERE
keyAlias=focusly
storeFile=/Users/YourName/focusly-keystore.jks
```

Then open `android/app/build.gradle` and replace the `buildTypes` section with:
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
        storePassword keystoreProperties['storePassword']
    }
}

buildTypes {
    release {
        signingConfig signingConfigs.release
        minifyEnabled false
    }
}
```

### 7D. Build the Release App Bundle
```bash
flutter build appbundle --release
```

Your file will be at:
`build/app/outputs/bundle/release/app-release.aab`

### 7E. Create the App in Play Console
1. Go to **play.google.com/console** → click **"Create app"**
2. Fill in:
   - App name: **Focusly — Your Daily Planner**
   - Default language: English
   - App or Game: **App**
   - Free or Paid: **Free**
3. Complete ALL required sections (Play Console will show you a checklist):

   | Section | What to do |
   |---|---|
   | Store listing | Add description, 2+ screenshots, feature graphic |
   | Content rating | Fill the questionnaire |
   | Target audience | Select "Everyone" |
   | Privacy policy | Create free one at https://app-privacy-policy-generator.firebaseapp.com |
   | App content | Select relevant categories |

### 7F. Upload and Submit
1. Play Console → **Testing** → **Internal testing** → Create new release
2. Upload your `app-release.aab` file
3. Add release notes: "Initial release"
4. Save and roll out
5. Test it yourself (install from the internal test link)
6. When ready: **Production** → Create release → Roll out to 100%
7. Google reviews it (1–3 days for first submission)
8. **Your app goes live! 🎉**

---

## STEP 8 — App Icon (Required Before Publishing)

You need a **1024×1024 PNG** icon.

**Make a free one:**
1. Go to **canva.com** → Create a design → Custom size: 1024×1024
2. Dark purple background (#0D0820) + gold (#F59E0B) letter "F" or target icon
3. Download as PNG

**Add it to the project:**
```bash
# Install the icon generator
flutter pub add --dev flutter_launcher_icons

# Edit pubspec.yaml and add:
flutter_launcher_icons:
  android: true
  ios: false
  image_path: "assets/icon.png"

# Copy your icon to: assets/icon.png
# Then run:
flutter pub run flutter_launcher_icons
```

---

## Common Commands Reference

| Command | What it does |
|---|---|
| `flutter run` | Run in debug mode (on emulator or phone) |
| `flutter run --release` | Run in release mode (faster, no debug tools) |
| `flutter build apk` | Build a single APK file (for direct install) |
| `flutter build appbundle` | Build App Bundle (for Play Store) |
| `flutter doctor` | Check your setup for issues |
| `flutter pub get` | Install/update packages |
| `flutter clean` | Delete build cache (fixes many weird errors) |
| `flutter hot reload` | Press `r` while running — updates app instantly |

---

## Getting Help

- **Official docs:** https://flutter.dev/docs
- **Video tutorials:** YouTube → search "Flutter beginners tutorial"
- **Community help:** https://stackoverflow.com/questions/tagged/flutter
- **Flutter Discord:** https://discord.gg/flutter

---

## Troubleshooting — Most Common Issues

**"Gradle build failed"**
→ Run `flutter clean` then `flutter pub get` then try again.
→ Make sure `android/local.properties` has the correct paths.

**"No devices found"**
→ Make sure your emulator is running, OR your phone's USB debugging is on.
→ Run `flutter doctor` to check.

**"flutter: command not found"**
→ Flutter isn't in your PATH. Re-do Step 1, items 5 & 6.

**"Package not found" errors**
→ Run `flutter pub get` to download all packages.

**App crashes on launch**
→ Run `flutter run` (not release) and read the error message in the terminal.

---

**You've got this! 💪 Focusly is a real app — once it's live, share it with people and gather feedback for Version 2.**
