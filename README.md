# NFC Eligibility Checker

A Flutter mobile application that uses a phone's built-in NFC capability to scan NFC cards and verify whether the card holder is eligible based on their account balance stored in a Supabase database.

## Features

- **NFC Card Scanning**: Reads unique UIDs from NFC cards using the phone's built-in NFC reader
- **Balance Verification**: Queries Supabase database to check user account balance
- **Eligibility Check**: Determines eligibility based on minimum balance requirement (100 birr)
- **Visual Feedback**: Displays green "Eligible" or red "Not Eligible" status with user details
- **Modular Architecture**: Clean separation of concerns with abstraction layers for easy hardware replacement

## Architecture

The application follows a modular architecture with clear separation of concerns:

- **NFC Reader Abstraction**: `NfcReaderInterface` allows easy switching between different NFC reader implementations (built-in phone NFC, external USB/Bluetooth readers)
- **Supabase Service**: Handles all database operations for user data queries
- **Business Logic**: `EligibilityChecker` contains core eligibility verification logic
- **UI Layer**: Clean Flutter interface for scanning and displaying results

This architecture makes it easy to replace the phone's NFC reader with external USB or Bluetooth NFC readers in the future without changing the core business logic.

## Prerequisites

- Flutter SDK (3.12.2 or higher)
- Android device with NFC capability or iPhone 7+ with NFC
- Supabase account and project
- NFC cards for testing

## Setup

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Configure Supabase

1. Create a Supabase project at [supabase.com](https://supabase.com)
2. Create a `users` table with the following schema:
   ```sql
   CREATE TABLE users (
     id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
     card_uid TEXT UNIQUE NOT NULL,
     name TEXT NOT NULL,
     balance NUMERIC NOT NULL DEFAULT 0,
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
   );
   ```
3. Enable Row Level Security (RLS) and add appropriate policies
4. Get your Supabase URL and anon key from project settings
5. Update `lib/main.dart` with your credentials:
   ```dart
   await Supabase.initialize(
     url: 'YOUR_SUPABASE_URL',
     anonKey: 'YOUR_SUPABASE_ANON_KEY',
   );
   ```

### 3. Platform Configuration

#### Android
NFC permissions are already configured in `android/app/src/main/AndroidManifest.xml`.

#### iOS
NFC permissions are already configured in `ios/Runner/Info.plist`.

**Note**: For iOS, you need to enable the "Near Field Communication Tag Reading" capability in Xcode:
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select the Runner target
3. Go to "Signing & Capabilities"
4. Click "+ Capability" and add "Near Field Communication Tag Reading"

## Usage

1. Run the app on a physical device with NFC capability:
   ```bash
   flutter run
   ```

2. Tap an NFC card to the back of your phone

3. The app will:
   - Read the card's unique UID
   - Query Supabase for the associated user
   - Check if the balance is at least 100 birr
   - Display the eligibility status

## Database Schema

The `users` table should have:
- `card_uid`: Unique identifier from the NFC card (TEXT)
- `name`: User's name (TEXT)
- `balance`: Account balance in birr (NUMERIC)

## Extending the Application

### Adding External NFC Readers

To add support for external NFC readers (USB/Bluetooth):

1. Create a new class implementing `NfcReaderInterface`:
   ```dart
   class ExternalNfcReader implements NfcReaderInterface {
     // Implement the interface methods
   }
   ```

2. Update the initialization in `lib/main.dart`:
   ```dart
   final nfcReader = ExternalNfcReader(); // Instead of PhoneNfcReader()
   ```

The rest of the application will work without any changes due to the abstraction layer.

## Use Cases

This application provides a scalable foundation for:
- Transport fare collection systems
- Access control systems
- Event attendance verification
- Membership eligibility checking
- Any NFC-based verification system requiring balance checks

## Troubleshooting

- **NFC not working**: Ensure your device has NFC hardware and it's enabled in system settings
- **User not found**: Verify the card UID exists in your Supabase users table
- **Balance check failing**: Ensure the balance field exists and is a numeric type in your database
- **iOS NFC issues**: Make sure you've enabled the NFC capability in Xcode as described above

## License

This project is provided as-is for educational and commercial use.
