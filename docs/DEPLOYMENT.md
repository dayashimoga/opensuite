# OpenSuite — Deployment Guide

## Web Deployment (Cloudflare Pages)

### Prerequisites
1. [Cloudflare account](https://dash.cloudflare.com/sign-up)
2. GitHub repository connected to Cloudflare

### Setup Steps

1. **Create Cloudflare Pages project:**
   - Go to Cloudflare Dashboard → Pages → Create a project
   - Connect your GitHub repository
   - Project name: `opensuite`
   - Build settings are handled by GitHub Actions (not Cloudflare build)

2. **Configure API tokens:**
   - Go to Cloudflare Dashboard → My Profile → API Tokens
   - Create token with `Cloudflare Pages: Edit` permission
   - Copy the Account ID from the dashboard URL

3. **Add GitHub Secrets:**
   - Repository → Settings → Secrets and variables → Actions
   - Add `CLOUDFLARE_API_TOKEN` — your API token
   - Add `CLOUDFLARE_ACCOUNT_ID` — your account ID

4. **Deploy:**
   - Push to `main` branch
   - GitHub Actions will build and deploy automatically
   - Access at: `https://opensuite.pages.dev`

### Manual Deployment

```bash
# Build web
docker compose -f docker/docker-compose.yml run --rm build-web

# Deploy with Wrangler CLI
npx wrangler pages deploy apps/opensuite/build/web/ --project-name=opensuite
```

## Android

### Debug APK
```bash
docker compose -f docker/docker-compose.yml run --rm build-android
# Output: apps/opensuite/build/app/outputs/flutter-apk/app-release.apk
```

### Release APK (requires keystore)
1. Generate a keystore:
   ```bash
   keytool -genkey -v -keystore opensuite-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias opensuite
   ```
2. Create `apps/opensuite/android/key.properties`:
   ```properties
   storePassword=<password>
   keyPassword=<password>
   keyAlias=opensuite
   storeFile=<path-to-keystore>
   ```
3. Build: `flutter build apk --release` or `flutter build appbundle`

## Windows / macOS / Linux

```bash
# Windows (requires Windows host)
flutter build windows --release

# macOS (requires macOS host)
flutter build macos --release

# Linux
docker compose -f docker/docker-compose.yml run --rm build-linux
```

## iOS

```bash
# Requires macOS with Xcode
flutter build ios --release
# Then archive and distribute via Xcode or Fastlane
```

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `CLOUDFLARE_API_TOKEN` | Cloudflare Pages API token | For web deploy |
| `CLOUDFLARE_ACCOUNT_ID` | Cloudflare account ID | For web deploy |
