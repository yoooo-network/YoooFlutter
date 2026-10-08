# Yooo.App for Flutter

The Yooo.App mobile client, built with Flutter. It connects people with profiles and services on the Yooo platform, with onboarding, location and preference settings, profile browsing, filters, and account management.

Want to see the platform in action? Visit [Yooo.App](https://www.yooo.app) to explore the live service.

## Features

- Guided onboarding to set preferences and location
- Browse profiles and view profile details
- Filter profiles and update search preferences
- Sign in, manage an account, and access bookings and profile settings
- Receive app update information

## Built with

- [Flutter](https://flutter.dev/) and Dart
- Material 3
- HTTP and Dio for API communication
- Shared Preferences for local settings and session state
- Workmanager for background tasks

## Getting started

### Prerequisites

- Flutter SDK compatible with the Dart constraint in `pubspec.yaml`
- Android Studio or Xcode for building and running on a device or emulator

### Run locally

```bash
git clone <repository-url>
cd YoooCMS-Flutter
flutter pub get
flutter run
```

Replace `<repository-url>` with the URL of your Git repository. To build a release, use the relevant Flutter command for your target platform, such as `flutter build apk` or `flutter build ios`.

## Project structure

```text
lib/
├── filters/       # Profile search filters
├── main_page/     # Main navigation and profile browsing
├── onboarding/    # First-run preference and location setup
├── profile/       # Profile details and sections
├── settings/      # App and search settings
├── update/        # Update checks and prompts
└── user-panel/    # Sign-in, dashboard, bookings, and account pages
```


## Reusable widget package

The app's reusable profile presentation widgets live in [`packages/yooo_profile_widgets`](packages/yooo_profile_widgets). The app currently depends on that package by local path so changes can be developed together.

To publish it for other Flutter projects:

1. Confirm `yooo_profile_widgets` is available on pub.dev, choose a final package name if needed, and add the real repository and issue tracker URLs to the package `pubspec.yaml`.
2. Review the package README, license, and changelog; update the version in its `pubspec.yaml` for each release.
3. From `packages/yooo_profile_widgets`, run `flutter pub get` and `dart pub publish --dry-run`. Review the included files and resolve any warnings.
4. Sign in to pub.dev when prompted, then run `dart pub publish` and confirm the upload. Publishing is public and package versions generally cannot be removed.
5. In a consuming app, add `yooo_profile_widgets: ^0.1.0` under `dependencies` (or run `flutter pub add yooo_profile_widgets`) and import `package:yooo_profile_widgets/yooo_profile_widgets.dart`.

For a team package, set up a [verified publisher](https://dart.dev/tools/pub/verified-publishers) before the first release. See the [official publishing guide](https://dart.dev/tools/pub/publishing) for the current workflow and requirements.

## Configuration

The app communicates with the Yooo platform. Review the API and platform configuration in the source before building for another environment. Keep credentials and environment-specific values out of source control.

## License

This project is released under the [MIT License](LICENSE).
