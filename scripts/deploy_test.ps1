# Deploy Script for SMSChat CI/CD Pipeline (Windows/PowerShell)
# This script helps you test the deployment locally before pushing to GitHub

Write-Host "🚀 SMSChat Local Deployment Test" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

# Function to check if command succeeded
function Check-Status {
    param($StepName)
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ $StepName succeeded" -ForegroundColor Green
    } else {
        Write-Host "✗ $StepName failed" -ForegroundColor Red
        exit 1
    }
}

# Step 1: Install dependencies
Write-Host "Step 1: Installing dependencies..." -ForegroundColor Yellow
flutter pub get
Check-Status "Dependency installation"
Write-Host ""

# Step 2: Run analysis
Write-Host "Step 2: Running static analysis..." -ForegroundColor Yellow
flutter analyze
Check-Status "Static analysis"
Write-Host ""

# Step 3: Run tests
Write-Host "Step 3: Running tests..." -ForegroundColor Yellow
flutter test
Check-Status "Tests"
Write-Host ""

# Step 4: Build APK
Write-Host "Step 4: Building release APK (obfuscated)..." -ForegroundColor Yellow
flutter build apk --release --obfuscate --split-debug-info=build/debug
Check-Status "APK build"
Write-Host ""

# Step 5: Check file size
Write-Host "Step 5: Checking APK size..." -ForegroundColor Yellow
$APK_PATH = "build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path $APK_PATH) {
    $SIZE = (Get-Item $APK_PATH).Length / 1MB
    Write-Host "APK generated: $APK_PATH ($([math]::Round($SIZE, 2)) MB)" -ForegroundColor Green
} else {
    Write-Host "APK not found!" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 6: Deploy Edge Functions (optional)
Write-Host "Step 6: Deploy Supabase Edge Functions? (y/n)" -ForegroundColor Yellow
$DEPLOY_FUNCTIONS = Read-Host
if ($DEPLOY_FUNCTIONS -eq "y") {
    Write-Host "Deploying Edge Functions..."
    supabase functions deploy --project-ref oizpvbhqevegxjqimpne
    Check-Status "Edge Functions deployment"
}
Write-Host ""

# Summary
Write-Host "=================================" -ForegroundColor Green
Write-Host "✓ All steps completed successfully!" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host "1. Install the APK on your device: $APK_PATH"
Write-Host "2. Push to GitHub to trigger automatic deployment:"
Write-Host "   git add ."
Write-Host "   git commit -m 'Deploy update'"
Write-Host "   git push origin main"
Write-Host "3. Monitor the build in GitHub Actions tab"
Write-Host ""
