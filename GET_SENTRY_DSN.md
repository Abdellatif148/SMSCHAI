# How to Get Your Sentry DSN

## Option 1: From Sentry Dashboard (Recommended)

1. **Login to Sentry**: Go to https://choukri-group.sentry.io/auth/login/choukri-group/
2. **Navigate to Project Settings**: 
   - Click on "Projects" in the left sidebar
   - Select your "flutter" project
   - Go to "Settings" → "Client Keys (DSN)"
3. **Copy the DSN**: You'll see a DSN that looks like:
   ```
   https://[32-character-key]@choukri-group.ingest.sentry.io/[project-id]
   ```
4. **Update constants.dart**: Copy the DSN and paste it in `lib/core/constants.dart`

## Option 2: Run Sentry Wizard

If you haven't run the wizard yet, execute these commands:

```powershell
cd c:\Users\DELL\Desktop\smschat\smschat

# Download and run Sentry wizard
$downloadUrl = "https://github.com/getsentry/sentry-wizard/releases/download/v4.0.1/sentry-wizard-win-x64.exe"
Invoke-WebRequest $downloadUrl -OutFile sentry-wizard.exe
./sentry-wizard.exe -i flutter --saas --org choukri-group --project flutter
```

The wizard will:
- ✅ Automatically add your DSN to the code
- ✅ Configure source maps for better error tracking
- ✅ Set up release tracking

## Quick Link

**Direct link to your DSN**: https://choukri-group.sentry.io/settings/projects/flutter/keys/

---

Once you have your DSN, I'll update `constants.dart` for you!
