#!/bin/bash
# Development Environment Configuration for Linux/Mac
# Run this script to start the app with environment variables

export SUPABASE_URL="https://oizpvbhqevegxjqimpne.supabase.co"
export SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9penB2YmhxZXZlZ3hqcWltcG5lIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzAwNDQxNTEsImV4cCI6MjA0NTYyMDE1MX0.wVu-vyC2NKBaJ0Ujv3xeDw_eSmLfezR52Cz_jYJ3H8I"
export SENTRY_DSN="https://9612a5eeb16eb5382335ab884bae2eb9@o4510427909128192.ingest.de.sentry.io/4510427913453648"

echo "Starting Flutter app with development environment..."

flutter run \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
  --dart-define=SENTRY_DSN=$SENTRY_DSN

# For production builds, create a separate env_config_prod.sh file
