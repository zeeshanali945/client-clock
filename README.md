# Client Clock (Flutter)

Time zone companion for freelancers: client time board, deadline converter (daylight saving safe), meeting overlap finder and local reminders. Offline-first. No location or contacts permission.

This source was written without a Flutter SDK available, so it has not been compiled yet. Expect to fix small errors on the first run, and send them back to be fixed.

## Build the APK on GitHub (no Android tools needed on your computer)

1. Create an empty repository on github.com and push this folder to it.
2. Open the repository's Actions tab, choose "Build Client Clock APK" and click Run workflow. The APK is a download on the finished run.
3. For a public download link, push a version tag: `git tag v1.0.0` then `git push origin v1.0.0`. The APK appears on the Releases page, and this link always gives the newest one:
   `https://github.com/YOUR-USERNAME/YOUR-REPO/releases/latest/download/client-clock.apk`
4. For a download page, open Settings > Pages, choose Deploy from a branch, branch `main`, folder `/docs`, and save. The page is `https://YOUR-USERNAME.github.io/YOUR-REPO/`.

The workflow creates the Android files itself, then `tool/patch_android.py` applies the notification settings listed further down, so you do not edit any Gradle or manifest file by hand. The APK is signed with a debug key, which is fine for installing from a file but not for the Play Store.

## Set up on your computer

1. Install Flutter (stable) and run `flutter doctor`.
2. Create a fresh project, then copy this code in:

```bash
flutter create --org com.zad --project-name client_clock client_clock
cd client_clock
# copy these from this folder, replacing what is there:
#   pubspec.yaml, lib/, test/
rm test/widget_test.dart
flutter pub get
flutter test          # runs the daylight saving and overlap tests
flutter run
```

## Android changes (needed for notifications)

In `android/app/build.gradle` (or `build.gradle.kts`):

```gradle
android {
    compileOptions {
        coreLibraryDesugaringEnabled true
        sourceCompatibility JavaVersion.VERSION_11
        targetCompatibility JavaVersion.VERSION_11
    }
}
dependencies {
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.0.4'
}
```

In `android/app/src/main/AndroidManifest.xml`, inside `<manifest>` add:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

and inside `<application>` add:

```xml
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
    </intent-filter>
</receiver>
```

## iOS change

In `ios/Runner/AppDelegate.swift`, inside `application(_:didFinishLaunchingWithOptions:)` before `return`:

```swift
if #available(iOS 10.0, *) {
  UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
}
```

## What is built (MVP)

- First-launch setup: detected time zone, own working hours and days off
- Client list: name, time zone, working hours, days off (edit and delete)
- Home board: live local time per client, inside or outside working hours, gap to your time
- Deadline converter with time left and a warning when it lands outside your hours
- Reminders 24 h and 2 h before (local notifications, inexact scheduling so no exact-alarm permission)
- Meeting finder: overlap windows for a chosen day, skipping days off, with copy-to-clipboard message
- Free plan limit of 3 clients (constant `freeClientLimit` in `lib/models.dart`)

## Not built yet (from the brief)

- Firebase (Crashlytics, Remote Config, backup): needs your own Firebase project and `flutterfire configure`
- Ads and Premium purchase (google_mobile_ads, in_app_purchase)
- Public holidays, Urdu interface, home screen widget, share sheet
- Drift database: replaced by shared_preferences with JSON, which needs no code generation. Switch to Drift later if you want saved deadlines history.

## Size

`timezone/data/latest_10y.dart` keeps zone data small. Check with `flutter build apk --analyze-size` and release as an App Bundle.
