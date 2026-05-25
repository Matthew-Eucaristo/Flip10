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

## Web deployment

The production web app is deployed to Cloudflare Pages:

```sh
flutter build web --release
npx wrangler pages deploy build/web --project-name=flip10 --branch=main
```

GitHub Actions is configured in `.github/workflows/deploy-cloudflare-pages.yml`
to build, test, and deploy on pushes to `main`. Add these repository secrets
before expecting automatic deploys:

- `CLOUDFLARE_ACCOUNT_ID`
- `CLOUDFLARE_API_TOKEN`

The API token only needs Account > Cloudflare Pages > Edit permission.
