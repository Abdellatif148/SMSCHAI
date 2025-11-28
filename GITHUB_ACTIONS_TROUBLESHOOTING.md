# GitHub Actions Troubleshooting Guide

## Common Errors and Solutions

### ❌ Error: "Flutter SDK is not available"

**Full Error Message**:
```
Because smschat depends on flutter_test from sdk which doesn't exist 
(the Flutter SDK is not available), version solving failed.
Flutter users should use `flutter pub` instead of `dart pub`.
Error: Process completed with exit code 69
```

**Cause**: 
- Flutter SDK not properly initialized before running `flutter pub get`
- GitHub Actions trying to use `dart pub` instead of `flutter pub`

**Solution** ✅:
Added to workflow file:
```yaml
- name: Setup Flutter
  uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.24.0'
    channel: 'stable'
    cache: true  # ← Added this

- name: Verify Flutter Installation  # ← Added this step
  run: |
    flutter --version
    flutter doctor -v

- name: Install Dependencies
  run: flutter pub get
```

---

### ❌ Error: "No such file or directory: build/debug"

**Cause**: Debug symbols folder doesn't exist when Sentry tries to upload

**Solution**:
Add a check before uploading:
```yaml
- name: Upload Debug Symbols to Sentry
  run: |
    if [ -d "build/debug" ]; then
      sentry-cli debug-files upload build/debug
    else
      echo "No debug symbols to upload"
    fi
```

---

### ❌ Error: "Invalid access token" (Supabase)

**Cause**: Missing or incorrect `SUPABASE_ACCESS_TOKEN` secret

**Solution**:
1. Go to [Supabase Dashboard → Account → Access Tokens](https://supabase.com/dashboard/account/tokens)
2. Generate a new token
3. Add to GitHub: **Settings → Secrets → Actions → New secret**
   - Name: `SUPABASE_ACCESS_TOKEN`
   - Value: `[your token]`

---

### ❌ Error: "Sentry authentication failed"

**Cause**: Missing or incorrect `SENTRY_AUTH_TOKEN` secret

**Solution**:
1. Go to [Sentry → Settings → Auth Tokens](https://sentry.io/settings/account/api/auth-tokens/)
2. Create a new token with `project:releases` permission
3. Add to GitHub: **Settings → Secrets → Actions → New secret**
   - Name: `SENTRY_AUTH_TOKEN`
   - Value: `[your token]`

---

### ❌ Error: "flutter analyze" fails

**Example**:
```
error • Undefined name 'someVariable' • lib/main.dart:42
```

**Solution**:
Fix linting errors locally first:
```bash
flutter analyze
# Fix all reported errors
git add .
git commit -m "Fix linting errors"
git push
```

---

### ❌ Error: Tests failed

**Example**:
```
00:01 +0 -1: test/widget_test.dart: Counter increments smoke test [E]
Expected: <1>
Actual: <0>
```

**Solution**:
Run tests locally and fix:
```bash
flutter test
# Fix failing tests
git add .
git commit -m "Fix failing tests"
git push
```

---

### ❌ Error: APK not generated

**Cause**: Build failed but workflow continued

**Solution**:
Check the "Build Release APK" step logs for specific errors. Common issues:
- Missing Android signing configuration
- Gradle build errors
- Missing dependencies

---

### ❌ Error: "No artifacts found"

**Cause**: Build succeeded but APK path is wrong

**Solution**:
Verify the APK path in the workflow:
```yaml
- name: Upload APK Artifact
  uses: actions/upload-artifact@v4
  with:
    name: release-apk
    path: build/app/outputs/flutter-apk/app-release.apk  # Correct path
```

---

## Verification Checklist

Before pushing, verify locally:

```bash
# ✅ Dependencies install
flutter pub get

# ✅ Code analysis passes
flutter analyze

# ✅ Tests pass
flutter test

# ✅ Build succeeds
flutter build apk --release
```

---

## Workflow Debugging Tips

### 1. Enable Debug Logging

Add to the beginning of your workflow:
```yaml
env:
  ACTIONS_STEP_DEBUG: true
  ACTIONS_RUNNER_DEBUG: true
```

### 2. Check Secret Values (Safely)

Never echo secrets! Instead, check if they exist:
```yaml
- name: Check Secrets
  run: |
    if [ -z "${{ secrets.SENTRY_AUTH_TOKEN }}" ]; then
      echo "SENTRY_AUTH_TOKEN is not set"
    else
      echo "SENTRY_AUTH_TOKEN is set"
    fi
```

### 3. Cache Flutter Dependencies

Speeds up builds and reduces errors:
```yaml
- name: Setup Flutter
  uses: subosito/flutter-action@v2
  with:
    cache: true  # Enables caching
```

---

## Quick Fixes Reference

| Error | Quick Fix |
|-------|-----------|
| Flutter SDK not available | Add `cache: true` and verification step |
| Sentry upload fails | Verify `SENTRY_AUTH_TOKEN` secret |
| Supabase deploy fails | Verify `SUPABASE_ACCESS_TOKEN` secret |
| Build fails | Run `flutter build apk` locally first |
| Tests fail | Run `flutter test` locally and fix |
| No artifacts | Check APK output path |

---

## Still Having Issues?

1. **Check the full logs** in GitHub Actions
2. **Run locally first** using `scripts/deploy_test.ps1`
3. **Compare with working workflow** in [main.yml](file:///c:/Users/DELL/Desktop/smschat/smschat/.github/workflows/main.yml)
4. **Check GitHub Actions status**: https://www.githubstatus.com/

---

**Last Updated**: 2025-11-28  
**Related**: [CI_CD_GUIDE.md](file:///c:/Users/DELL/Desktop/smschat/smschat/CI_CD_GUIDE.md)
