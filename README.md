# NCommonApp

A Flutter application with Supabase authentication and Firebase analytics.

## Features

- Email and password authentication
- Social authentication (Google, Apple, GitHub)
- Biometric authentication
- Email verification
- Password reset
- Profile completion
- Analytics tracking

## Setup

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Create a `.env` file in the root directory with the following variables:
   ```
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   FIREBASE_ANALYTICS_ENABLED=true
   ```

4. Set up Supabase:
   - Create a new project at https://supabase.com
   - Enable Email auth provider
   - Configure social auth providers (Google, Apple, GitHub)
   - Create a `users` table with the following columns:
     - `id` (uuid, primary key)
     - `email` (text, unique)
     - `full_name` (text)
     - `dob` (date)
     - `mood` (text)
     - `interests` (text[])
     - `profile_picture` (text)
     - `created_at` (timestamp with time zone)
     - `updated_at` (timestamp with time zone)

5. Set up Firebase:
   - Create a new project at https://firebase.google.com
   - Add your Android/iOS app
   - Download and add the configuration files
   - Enable Analytics

6. Run the app:
   ```bash
   flutter run
   ```

## Development

### Code Structure

```
lib/
  ├── constants/         # App constants
  ├── services/          # Business logic
  ├── screens/          # UI screens
  ├── widgets/          # Reusable widgets
  ├── models/           # Data models
  ├── utils/            # Utility functions
  └── main.dart         # App entry point
```

### Testing

Run tests:
```bash
flutter test
```

### Building

Build for Android:
```bash
flutter build apk
```

Build for iOS:
```bash
flutter build ios
```

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
