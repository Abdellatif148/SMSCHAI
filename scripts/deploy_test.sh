#!/bin/bash

# Deploy Script for SMSChat CI/CD Pipeline
# This script helps you test the deployment locally before pushing to GitHub

echo "🚀 SMSChat Local Deployment Test"
echo "================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if command succeeded
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1 succeeded${NC}"
    else
        echo -e "${RED}✗ $1 failed${NC}"
        exit 1
    fi
}

# Step 1: Install dependencies
echo -e "${YELLOW}Step 1: Installing dependencies...${NC}"
flutter pub get
check_status "Dependency installation"
echo ""

# Step 2: Run analysis
echo -e "${YELLOW}Step 2: Running static analysis...${NC}"
flutter analyze
check_status "Static analysis"
echo ""

# Step 3: Run tests
echo -e "${YELLOW}Step 3: Running tests...${NC}"
flutter test
check_status "Tests"
echo ""

# Step 4: Build APK
echo -e "${YELLOW}Step 4: Building release APK (obfuscated)...${NC}"
flutter build apk --release --obfuscate --split-debug-info=build/debug
check_status "APK build"
echo ""

# Step 5: Check file size
echo -e "${YELLOW}Step 5: Checking APK size...${NC}"
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
if [ -f "$APK_PATH" ]; then
    SIZE=$(du -h "$APK_PATH" | cut -f1)
    echo -e "${GREEN}APK generated: $APK_PATH ($SIZE)${NC}"
else
    echo -e "${RED}APK not found!${NC}"
    exit 1
fi
echo ""

# Step 6: Deploy Edge Functions (optional)
echo -e "${YELLOW}Step 6: Deploy Supabase Edge Functions? (y/n)${NC}"
read -r DEPLOY_FUNCTIONS
if [ "$DEPLOY_FUNCTIONS" = "y" ]; then
    echo "Deploying Edge Functions..."
    supabase functions deploy --project-ref oizpvbhqevegxjqimpne
    check_status "Edge Functions deployment"
fi
echo ""

# Summary
echo -e "${GREEN}================================="
echo "✓ All steps completed successfully!"
echo "=================================${NC}"
echo ""
echo "Next steps:"
echo "1. Install the APK on your device: $APK_PATH"
echo "2. Push to GitHub to trigger automatic deployment"
echo "3. Monitor the build at: https://github.com/YOUR_USERNAME/YOUR_REPO/actions"
echo ""
