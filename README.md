# Flip10

A focused offline Shut the Box dice game built with Flutter for Android, iOS,
and web.

## Stack

- Flutter Material 3 app shell
- Pure Dart game rules and turn state
- Local settings and recent match persistence with `shared_preferences`
- Offline pass-and-play for 1-4 players

## Commands

```sh
flutter test
flutter analyze
flutter run
flutter build apk --release
flutter build ios --release
flutter build web --release
```

Golden image baselines are kept for local visual checks:

```sh
flutter test test/golden_test.dart
```

## Web deployment

The production web app is deployed to Cloudflare Pages:

```sh
flutter build web --release
npx wrangler pages deploy build/web --project-name=flip10 --branch=main
```
