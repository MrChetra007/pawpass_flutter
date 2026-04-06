# PawPass - Digital Pet Passport

A comprehensive mobile application for pet owners to manage their pets' health records, vaccinations, medications, appointments, and more.

## Features

### Pet Management
- Add and manage multiple pets
- Store pet profiles with photo, breed, age, weight, and medical information
- Track weight history with visual charts

### Health Records
- Record vet visits, surgeries, illnesses, injuries, and more
- Add diagnosis, treatment, notes, and cost information
- Upload and store veterinary documents (images, PDFs)
- View and share documents with others

### Vaccinations
- Track vaccination records with due dates
- Color-coded status badges (up-to-date, due soon, overdue)
- Add vaccine name, date, batch number, and vet info

### Medications
- Manage ongoing and past medications
- Set dosage, frequency, and start/end dates
- Track medication schedules

### Appointments
- Schedule vet appointments
- Set reminders with notifications
- View appointment history

### Documents
- Securely store veterinary documents in Supabase storage
- View documents directly in the app
- Share documents via other apps

### Additional Features
- PDF export for pet health records
- Subscription/premium features (Paw Plan)
- Dark/Light theme support
- Multi-language support

## Tech Stack

- **Framework**: Flutter
- **Backend**: Supabase (Auth, Database, Storage)
- **State Management**: Riverpod
- **Navigation**: GoRouter
- **Notifications**: Flutter Local Notifications
- **Payments**: In-App Purchases

## Getting Started

### Prerequisites
- Flutter SDK 3.10+
- Dart 3.10+
- Android SDK / Xcode (for iOS)

### Installation

1. Clone the repository
```bash
git clone <repository-url>
cd pawpass
```

2. Install dependencies
```bash
flutter pub get
```

3. Configure environment variables
- Copy `.env.example` to `.env`
- Add your Supabase credentials:
  ```
  SUPABASE_URL=your_supabase_url
  SUPABASE_ANON_KEY=your_anon_key
  ```

4. Run the app
```bash
flutter run
```

### Build APK
```bash
flutter build apk --release
```

## Project Structure

```
lib/
├── core/               # Core utilities, constants, theme
├── data/               # Models and repositories
├── features/           # Feature modules
│   ├── appointments/   # Appointment management
│   ├── auth/           # Authentication
│   ├── billing/        # Subscription & billing
│   ├── dashboard/      # Home dashboard
│   ├── medications/   # Medication tracking
│   ├── pets/          # Pet management
│   ├── profile/       # User profile & settings
│   ├── records/       # Vet health records
│   ├── vaccines/      # Vaccination tracking
│   └── weight/        # Weight tracking
└── shared/             # Shared widgets, providers
```

## License

Copyright © 2026 PawPass. All rights reserved.