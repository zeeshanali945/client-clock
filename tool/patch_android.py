#!/usr/bin/env python3
"""Applies the Android settings Client Clock needs for reminders.

Run it after `flutter create` has generated the android/ folder. It is safe to
run more than once: each change is skipped if it is already there.

What it does:
  1. Turns on core library desugaring (needed by flutter_local_notifications)
  2. Adds the notification permissions and receivers to AndroidManifest.xml
  3. Sets the app name shown on the phone to "Client Clock"
"""
import os
import re
import sys

DESUGAR_VERSION = "2.1.4"
APP_DIR = os.path.join("android", "app")
MANIFEST = os.path.join(APP_DIR, "src", "main", "AndroidManifest.xml")


def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


def write(path, text):
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)


def fail(message, path=None):
    print("PATCH FAILED: " + message)
    if path and os.path.exists(path):
        print("---- " + path + " ----")
        print(read(path))
    sys.exit(1)


def patch_gradle():
    kts = os.path.join(APP_DIR, "build.gradle.kts")
    groovy = os.path.join(APP_DIR, "build.gradle")
    if os.path.exists(kts):
        path, is_kts = kts, True
    elif os.path.exists(groovy):
        path, is_kts = groovy, False
    else:
        fail("no android/app/build.gradle(.kts) found. Did flutter create run?")

    text = read(path)
    changed = False

    flag = "isCoreLibraryDesugaringEnabled = true" if is_kts else "coreLibraryDesugaringEnabled true"
    if "oreLibraryDesugaringEnabled" not in text:
        match = re.search(r"compileOptions\s*\{", text)
        if match:
            text = text[: match.end()] + "\n        " + flag + text[match.end():]
        else:
            match = re.search(r"\bandroid\s*\{", text)
            if not match:
                fail("could not find an android { } block", path)
            block = "\n    compileOptions {\n        " + flag + "\n    }\n"
            text = text[: match.end()] + block + text[match.end():]
        changed = True

    if "coreLibraryDesugaring" not in text.replace("oreLibraryDesugaringEnabled", ""):
        dep = (
            'coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:%s")' % DESUGAR_VERSION
            if is_kts
            else "coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:%s'" % DESUGAR_VERSION
        )
        # Look for a top level dependencies block (column 0), not one nested in android { }.
        match = re.search(r"^dependencies\s*\{", text, re.M)
        if match:
            text = text[: match.end()] + "\n    " + dep + text[match.end():]
        else:
            text = text.rstrip() + "\n\ndependencies {\n    " + dep + "\n}\n"
        changed = True

    if changed:
        write(path, text)
        print("patched " + path)
    else:
        print("already patched " + path)


def patch_manifest():
    if not os.path.exists(MANIFEST):
        fail("AndroidManifest.xml not found", MANIFEST)
    text = read(MANIFEST)
    changed = False

    if "POST_NOTIFICATIONS" not in text:
        match = re.search(r"<manifest[^>]*>", text)
        if not match:
            fail("no <manifest> tag found", MANIFEST)
        perms = (
            '\n    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>'
            '\n    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>'
        )
        text = text[: match.end()] + perms + text[match.end():]
        changed = True

    if "ScheduledNotificationReceiver" not in text:
        receivers = (
            '\n        <receiver android:exported="false"'
            '\n            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />'
            '\n        <receiver android:exported="false"'
            '\n            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">'
            "\n            <intent-filter>"
            '\n                <action android:name="android.intent.action.BOOT_COMPLETED"/>'
            '\n                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>'
            "\n            </intent-filter>"
            "\n        </receiver>\n    "
        )
        if "</application>" not in text:
            fail("no </application> tag found", MANIFEST)
        text = text.replace("</application>", receivers + "</application>", 1)
        changed = True

    if 'android:label="client_clock"' in text:
        text = text.replace('android:label="client_clock"', 'android:label="Client Clock"', 1)
        changed = True

    if changed:
        write(MANIFEST, text)
        print("patched " + MANIFEST)
    else:
        print("already patched " + MANIFEST)


if __name__ == "__main__":
    patch_gradle()
    patch_manifest()
    print("Android patch done.")
