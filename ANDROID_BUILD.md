# Build an Android APK

This ZIP does not contain a compiled APK yet. The build environment used to create it did not have Godot or the Android export SDK/templates installed, so it would be misleading to label any file as an APK.

## Build it using Godot 4

1. Install Godot 4.x on a computer (the standard editor build).
2. Open Godot and import this folder by selecting `project.godot`.
3. In Godot, open **Editor > Manage Export Templates** and install the export templates matching your exact Godot version.
4. Install Android Studio and use its SDK Manager to install the Android SDK Platform, Android SDK Build-Tools, Platform-Tools, and command-line tools.
5. In Godot, open **Editor > Editor Settings > Export > Android** and set the Android SDK path and Java SDK path. Use a compatible JDK; check the documentation for your exact Godot version.
6. Open **Project > Export**, add an **Android** preset, and choose an APK export path.
7. Export a debug APK first. Install it on your Android phone and test it.
8. For release distribution, configure a signing keystore and export a signed build.

## Important

- This is an early prototype, not the complete requested game.
- It has not been compiled or runtime-tested in this environment.
- The current NPC collapse is a placeholder, not a full skeletal ragdoll.
- Vehicle/plane systems, destructible environments, complete weapon implementations, and mobile touch controls still need work.
- Do not install APKs from unknown sources unless you trust the origin and have inspected the build.
