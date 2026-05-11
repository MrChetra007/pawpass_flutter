# PawPass - Digital Pet Passport

A comprehensive Flutter mobile application for pet owners to manage their pets' health records, vaccinations, medications, appointments, and more. Built with Supabase backend and Riverpod state management.

## Features

### Pet Management
- Add and manage multiple pets with profiles (photo, breed, age, weight, microchip, neuter status)
- Species support: Dog, Cat, Rabbit, Bird, Other
- Soft-delete with `is_active` flag
- Share pet profiles via QR-coded ID cards and share links

### Health Records
- Record vet visits, surgeries, illnesses, injuries, dental, and other events
- Add diagnosis, treatment, notes, and cost information
- Upload and store veterinary documents (images, PDFs) in Supabase Storage
- Filter records by type (Checkup, Surgery, Dental, Other)

### Vaccinations
- Track vaccination records with batch numbers and vet info
- Color-coded status badges: Up-to-date (green), Due soon (amber), Overdue (red)
- Next-due-date tracking with reminder scheduling

### Medications
- Manage active and past medications
- Set dosage, frequency, and date ranges
- Active/inactive toggle with visual distinction

### Appointments
- Schedule vet appointments with date, time, location, and vet info
- Set reminders via local push notifications (timezone-aware)
- Upcoming vs. Past views

### Weight Tracking
- Log weight entries with notes
- Interactive line chart (`fl_chart`) showing weight history
- Trends and deltas from last entry

### Notifications & Reminders
- Flutter Local Notifications for appointment, vaccine, and medication reminders
- Auto-reschedule on app launch and auth state change
- Schedule all reminders via centralized `NotificationService`

### Subscription / Paw Plan
- In-app purchases (Apple IAP / Google Play Billing) via `in_app_purchase`
- **Paw Plan** ($2.99/mo): Up to 3 pets, unlimited records, file uploads, reminders
- **Family Plan** ($4.99/mo): Unlimited pets, PDF passport export, family sharing
- Plan-gated features via `FeatureGate` utility with upgrade modal

### PDF Export & ID Cards
- Generate PDF health record summaries
- Create and share pet ID cards (with QR code for sharing)

### Theme System
- 6 color themes: Forest (default), Ocean, Blossom, Amber, Midnight, Lavender
- Persisted locally (SharedPreferences) and synced to Supabase
- 300ms animated transitions via `AnimatedTheme`

### Authentication
- Email/password registration and login
- Google OAuth sign-in
- Password reset flow
- Onboarding flow for new users
- Row-Level Security enforces user data isolation

## Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter (Dart) |
| **Backend** | Supabase (Auth, PostgreSQL, Storage, Edge Functions) |
| **State Management** | Riverpod 3.x (Provider, Notifier, StreamProvider, FutureProvider) |
| **Routing** | GoRouter (declarative, auth-guarded) |
| **Notifications** | flutter_local_notifications + timezone |
| **Payments** | in_app_purchase (Apple IAP / Google Play Billing) |
| **Charts** | fl_chart |
| **PDF** | pdf + printing |
| **QR Codes** | qr_flutter |
| **Fonts** | DM Serif Display (headings), Plus Jakarta Sans (body) |
| **Icon Generation** | flutter_launcher_icons |

## Project Structure

```
lib/
├── core/                        # Cross-cutting infrastructure
│   ├── constants/               # Supabase bucket names, enums
│   ├── router/                  # GoRouter + auth guards + shell
│   ├── services/                # Notification, IAP, Sharing, PDF, ID Card
│   ├── theme/                   # 6 themes, builder, context extensions
│   └── utils/                   # Feature gates, validators, date utils
├── data/                        # Data layer
│   ├── models/                  # Pet, Vaccine, Medication, Appointment,
│   │                            # VetRecord, WeightLog (with fromJson/toJson)
│   └── repositories/            # CRUD repos using SupabaseClient
├── features/                    # Feature modules (screens only)
│   ├── appointments/            # List + add/edit appointment
│   ├── auth/                    # Landing, Login, Register, Forgot/Reset PW, Onboarding
│   ├── billing/                 # Subscription management
│   ├── dashboard/               # Home screen with pet summary
│   ├── medications/             # List + add/edit medication
│   ├── pets/                    # List, profile, add/edit pet
│   ├── profile/                 # Settings, Theme picker, Help, Privacy, Terms
│   ├── records/                 # List + add/edit vet record
│   ├── vaccines/                # List + add/edit vaccine
│   └── weight/                  # History chart + add weight
├── shared/                      # Shared app logic
│   ├── providers/               # Auth, Theme, Pet, Vaccine, Medication,
│   │                            # Appointment, Record, Weight, Notification
│   └── widgets/                 # PawCard, StatusBadge, SkeletonLoader,
│                                # EmptyState, UpgradeModal, PetIdCard
└── main.dart                    # Entry point: Supabase init, IAP, notifications
```

## Database Schema

Supabase PostgreSQL with Row-Level Security on all tables:

- **users** — Extended profiles (plan, IAP tokens, theme, onboarding status). Auto-created via `handle_new_user` trigger.
- **pets** — Core pet data with `share_token` (UUID), `is_sharing_enabled`, soft-delete (`is_active`).
- **vet_records** — Health records linked to pets with type, diagnosis, treatment, cost, document attachments.
- **vaccines** — Vaccination records with batch number, given date, next due date, vet info.
- **appointments** — Vet appointments with datetime, location, notes, reminder settings.
- **medications** — Medication schedules with dosage, frequency, time of day, date ranges.
- **weight_logs** — Weight entries with date and optional notes.
- **family_members** — Family sharing with roles (viewer/admin) and status (pending/active/removed).

Storage buckets: `pet-photos` (public), `vet-documents` (private, user-scoped), `avatars` (public).

## Architecture & Patterns

- **Feature-first, layered**: UI → Riverpod Providers → Repositories → Supabase
- **State management**: Riverpod 3.x with `Notifier<T>` + `AsyncValue<T>` for loading/error/data states
- **Repositories** are instantiated with a `SupabaseClient` per call (no DI container)
- **Singletons** for platform services: `NotificationService`, `IAPService`, `SharingService`
- **Soft deletes** via `is_active` flags (pets)
- **Plan gating** via `FeatureGate.check()` with consistent upgrade modals
- **Optimistic UI** updates in notifiers with error rollback
- **Staggered animations** on dashboard (fade-in sections with `AnimationController`)

## Getting Started

### Prerequisites
- Flutter SDK 3.10+
- Dart 3.10+
- Android SDK / Xcode (for iOS)
- A Supabase project

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd pawpass
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure environment variables in `.env`:
   ```
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_anon_key
   IOS_CLIENT_ID=your_google_oauth_ios_client_id
   WEB_CLIENT_ID=your_google_oauth_web_client_id
   ```

4. Run the schema against your Supabase project:
   - Execute `schema.sql` in the Supabase SQL editor

5. Run the app:
   ```bash
   flutter run
   ```

### Build

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

## Configuration

- **App icon**: Update `assets/icons/icon.png` and run `flutter pub run flutter_launcher_icons`
- **Notifications**: Configure notification channels in `NotificationService.initialize()`
- **IAP products**: Define product IDs in `IAPService` (matching App Store Connect / Google Play Console)

## License

Copyright © 2026 PawPass. All rights reserved.
