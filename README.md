# SMSChat

A modern Flutter messaging application with cloud sync, end-to-end encryption, and real-time features powered by Supabase.

## Features

- 📱 **SMS Integration**: Native SMS reading and sending
- ☁️ **Cloud Sync**: Automatic message backup to Supabase
- 🔐 **End-to-End Encryption**: Secure message storage
- 👥 **Group Chats**: Create and manage group conversations
- 📎 **Rich Attachments**: Send images, videos, and files
- 🚀 **Real-time Updates**: Live message synchronization
- 📊 **Performance Monitoring**: Integrated Sentry tracking

## Tech Stack

- **Frontend**: Flutter 3.24.0
- **Backend**: Supabase (PostgreSQL + Edge Functions)
- **State Management**: Provider
- **Local Database**: SQLite (sqflite)
- **Monitoring**: Sentry

## Getting Started

### Prerequisites

- Flutter SDK 3.24.0 or higher
- Android Studio / VS Code
- Supabase account
- Sentry account (optional, for monitoring)

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/YOUR_USERNAME/smschat.git
   cd smschat
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure environment**:
   
   The app uses compile-time environment variables for configuration. You can run it in two ways:
   
   **Option 1: Use the provided scripts (Recommended)**
   
   Windows (PowerShell):
   ```powershell
   .\env_config.ps1
   ```
   
   Linux/Mac (Bash):
   ```bash
   chmod +x env_config.sh
   ./env_config.sh
   ```
   
   **Option 2: Run with dart-define directly**
   ```bash
   flutter run \
     --dart-define=SUPABASE_URL=your-url \
     --dart-define=SUPABASE_ANON_KEY=your-key \
     --dart-define=SENTRY_DSN=your-dsn
   ```
   
   > **Note**: Default values are provided in `lib/core/constants.dart` for development.
   > For production, always override with your actual credentials.

4. **Run the app**:
   ```bash
   flutter run
   ```
   
   Or use the environment scripts mentioned above for automatic configuration.

### Building for Production

**Android APK** (obfuscated):
```bash
flutter build apk --release --obfuscate --split-debug-info=build/debug
```

**Android App Bundle** (for Play Store):
```bash
flutter build appbundle --release
```

---

## CI/CD Pipeline

This project uses **GitHub Actions** for automated builds and deployments.

### Quick Start

1. **Configure GitHub Secrets** (Settings → Secrets → Actions):
   - `SENTRY_AUTH_TOKEN`: Your Sentry authentication token
   - `SUPABASE_ACCESS_TOKEN`: Your Supabase personal access token

2. **Push to main branch**:
   ```bash
   git add .
   git commit -m "Your changes"
   git push origin main
   ```

3. **Monitor the build**:
   - Go to the **Actions** tab in GitHub
   - View build progress and download APK artifacts

### Pipeline Features

- ✅ Automated testing (`flutter analyze` + `flutter test`)
- 📦 APK build with code obfuscation
- 🐛 Debug symbols upload to Sentry
- 🚀 Automatic Supabase Edge Functions deployment
- 📥 Downloadable release APK artifacts

**For full CI/CD documentation, see [CI_CD_GUIDE.md](CI_CD_GUIDE.md)**

---

## Project Structure

```
smschat/
├── lib/
│   ├── core/              # App constants, themes, utilities
│   ├── features/          # Feature modules (chat, home, auth, etc.)
│   ├── providers/         # State management (Provider)
│   ├── services/          # Business logic (SMS, database, Supabase)
│   └── main.dart          # App entry point
├── supabase/
│   └── functions/         # Edge Functions (TypeScript/Deno)
├── scripts/               # Helper scripts for deployment
├── .github/workflows/     # CI/CD pipeline configuration
└── README.md
```

---

## Development

### Run Static Analysis
```bash
flutter analyze
```

### Run Tests
```bash
flutter test
```

### Format Code
```bash
flutter format .
```

### Local Deployment Test

**Windows** (PowerShell):
```powershell
.\scripts\deploy_test.ps1
```

**Linux/Mac** (Bash):
```bash
chmod +x scripts/deploy_test.sh
./scripts/deploy_test.sh
```

---

## Supabase Setup

### Database Schema

The app uses the following tables:
- `messages_backup`: Encrypted message storage
- `groups`: Group chat metadata
- `group_members`: Group membership
- `message_reactions`: Emoji reactions

For the full schema, see [supabase_schema.sql](supabase_schema.sql)

### Edge Functions

- **proxy_api**: API proxy for external services

To deploy functions locally:
```bash
supabase functions deploy --project-ref oizpvbhqevegxjqimpne
```

---

## Sentry Integration

### Crash Reporting

Sentry automatically captures:
- Unhandled exceptions
- Flutter framework errors
- Native platform errors

### Performance Monitoring

Tracked operations:
- SMS sync (`sms.sync`)
- Message sending (`sms.send`)
- Database queries (`db.query`)
- File uploads (`network.upload`)

**View in Sentry**: [choukri-group/flutter](https://sentry.io)

---

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Support

- **Documentation**: See [CI_CD_GUIDE.md](CI_CD_GUIDE.md) for deployment help
- **Issues**: Report bugs on [GitHub Issues](https://github.com/YOUR_USERNAME/smschat/issues)
- **Discussions**: Ask questions in [GitHub Discussions](https://github.com/YOUR_USERNAME/smschat/discussions)

---

## Roadmap

- [ ] iOS support
- [ ] Web support
- [ ] Voice messages
- [ ] Video calls
- [ ] Message scheduling
- [ ] Dark/Light theme toggle
- [ ] Multi-language support

---

**Built with ❤️ using Flutter and Supabase**
