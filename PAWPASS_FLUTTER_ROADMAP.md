# 🐾 PawPass — Flutter Mobile Roadmap

> **Stack:** Flutter + Supabase + Apple IAP / Google Play Billing + Resend
> **Goal:** Launch a Digital Pet Passport mobile app on iOS & Android. Reach $1K MRR in 3 months.

---

## 🎨 Design System & Visual Identity

### Aesthetic Direction: **Warm Organic Minimalism** (default)
Clean, airy, and trustworthy — like a modern vet clinic that actually feels welcoming. Every screen feels calm and structured, never cluttered. Users can switch between **6 themes** from their Profile screen, giving the app a personal feel for every owner.

---

### 🎨 Theme Catalogue

Each theme has a name, a personality, and a full set of semantic color tokens. All UI components reference tokens — never raw hex values.

---

#### Theme 1 — 🌿 Forest (Default)
*Warm, natural, trustworthy*

| Token | Hex | Preview |
|---|---|---|
| `primary` | `#3D7A5F` | Deep forest green |
| `primaryLight` | `#A8C5B5` | Sage mist |
| `background` | `#FAF6F1` | Warm cream |
| `surface` | `#FFFFFF` | Pure white |
| `textPrimary` | `#1E2D2B` | Deep charcoal |
| `textMuted` | `#8A9A96` | Muted sage gray |

---

#### Theme 2 — 🌊 Ocean
*Cool, calm, clinical — feels premium*

| Token | Hex | Preview |
|---|---|---|
| `primary` | `#2B6CB0` | Deep ocean blue |
| `primaryLight` | `#BEE3F8` | Sky mist |
| `background` | `#F0F7FF` | Ice blue tint |
| `surface` | `#FFFFFF` | White |
| `textPrimary` | `#1A2F45` | Dark navy |
| `textMuted` | `#718096` | Steel gray |

---

#### Theme 3 — 🌸 Blossom
*Soft, playful, warm — great for cat owners*

| Token | Hex | Preview |
|---|---|---|
| `primary` | `#B85C84` | Rose berry |
| `primaryLight` | `#F5C6DA` | Petal pink |
| `background` | `#FFF7F9` | Blush white |
| `surface` | `#FFFFFF` | White |
| `textPrimary` | `#3D1A26` | Deep plum |
| `textMuted` | `#A07080` | Dusty rose |

---

#### Theme 4 — 🍊 Amber
*Energetic, warm, sunny — great for dog owners*

| Token | Hex | Preview |
|---|---|---|
| `primary` | `#C2680A` | Burnt amber |
| `primaryLight` | `#FDDCAB` | Peach glow |
| `background` | `#FFFBF4` | Vanilla cream |
| `surface` | `#FFFFFF` | White |
| `textPrimary` | `#2D1A05` | Deep espresso |
| `textMuted` | `#9A7850` | Warm taupe |

---

#### Theme 5 — 🌙 Midnight (Dark)
*Sleek, modern dark mode*

| Token | Hex | Preview |
|---|---|---|
| `primary` | `#4CAF82` | Neon mint |
| `primaryLight` | `#1E4D38` | Dark emerald |
| `background` | `#0F1612` | Near black |
| `surface` | `#1C2820` | Dark card |
| `textPrimary` | `#E8F5EE` | Off white |
| `textMuted` | `#6B8C7A` | Dim sage |

---

#### Theme 6 — 🪻 Lavender
*Gentle, elegant, calming*

| Token | Hex | Preview |
|---|---|---|
| `primary` | `#6B5EA8` | Deep violet |
| `primaryLight` | `#D6CEFF` | Soft lavender |
| `background` | `#F8F6FF` | Ghost white |
| `surface` | `#FFFFFF` | White |
| `textPrimary` | `#1F1640` | Dark purple |
| `textMuted` | `#8878B5` | Muted violet |

---

### Shared Semantic Tokens (same across all themes)

| Token | Hex | Usage |
|---|---|---|
| `alertAmber` | `#E8A838` | Due-soon vaccine warnings |
| `alertRed` | `#D95F52` | Overdue, errors, destructive actions |
| `successGreen` | `#4CAF82` | Up-to-date status, success toasts |

---

### Theme Data Model

```dart
// lib/core/theme/app_theme_data.dart

enum PawTheme {
  forest,
  ocean,
  blossom,
  amber,
  midnight,
  lavender,
}

class PawThemeData {
  final PawTheme id;
  final String name;
  final String emoji;
  final Color primary;
  final Color primaryLight;
  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textMuted;
  final Brightness brightness;

  const PawThemeData({
    required this.id,
    required this.name,
    required this.emoji,
    required this.primary,
    required this.primaryLight,
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textMuted,
    this.brightness = Brightness.light,
  });

  // Shared semantic tokens
  static const alertAmber   = Color(0xFFE8A838);
  static const alertRed     = Color(0xFFD95F52);
  static const successGreen = Color(0xFF4CAF82);

  static const all = <PawTheme, PawThemeData>{
    PawTheme.forest: PawThemeData(
      id: PawTheme.forest, name: 'Forest', emoji: '🌿',
      primary: Color(0xFF3D7A5F), primaryLight: Color(0xFFA8C5B5),
      background: Color(0xFFFAF6F1), surface: Color(0xFFFFFFFF),
      textPrimary: Color(0xFF1E2D2B), textMuted: Color(0xFF8A9A96),
    ),
    PawTheme.ocean: PawThemeData(
      id: PawTheme.ocean, name: 'Ocean', emoji: '🌊',
      primary: Color(0xFF2B6CB0), primaryLight: Color(0xFFBEE3F8),
      background: Color(0xFFF0F7FF), surface: Color(0xFFFFFFFF),
      textPrimary: Color(0xFF1A2F45), textMuted: Color(0xFF718096),
    ),
    PawTheme.blossom: PawThemeData(
      id: PawTheme.blossom, name: 'Blossom', emoji: '🌸',
      primary: Color(0xFFB85C84), primaryLight: Color(0xFFF5C6DA),
      background: Color(0xFFFFF7F9), surface: Color(0xFFFFFFFF),
      textPrimary: Color(0xFF3D1A26), textMuted: Color(0xFFA07080),
    ),
    PawTheme.amber: PawThemeData(
      id: PawTheme.amber, name: 'Amber', emoji: '🍊',
      primary: Color(0xFFC2680A), primaryLight: Color(0xFFFDDCAB),
      background: Color(0xFFFFFBF4), surface: Color(0xFFFFFFFF),
      textPrimary: Color(0xFF2D1A05), textMuted: Color(0xFF9A7850),
    ),
    PawTheme.midnight: PawThemeData(
      id: PawTheme.midnight, name: 'Midnight', emoji: '🌙',
      primary: Color(0xFF4CAF82), primaryLight: Color(0xFF1E4D38),
      background: Color(0xFF0F1612), surface: Color(0xFF1C2820),
      textPrimary: Color(0xFFE8F5EE), textMuted: Color(0xFF6B8C7A),
      brightness: Brightness.dark,
    ),
    PawTheme.lavender: PawThemeData(
      id: PawTheme.lavender, name: 'Lavender', emoji: '🪻',
      primary: Color(0xFF6B5EA8), primaryLight: Color(0xFFD6CEFF),
      background: Color(0xFFF8F6FF), surface: Color(0xFFFFFFFF),
      textPrimary: Color(0xFF1F1640), textMuted: Color(0xFF8878B5),
    ),
  };
}
```

---

### Typography

| Role | Font | Weight | Size |
|---|---|---|---|
| Display / Hero | `DM Serif Display` | Regular | 32–40sp |
| Heading | `DM Serif Display` | Regular | 22–28sp |
| Subheading | `Plus Jakarta Sans` | SemiBold | 16–18sp |
| Body | `Plus Jakarta Sans` | Regular | 14–15sp |
| Caption / Label | `Plus Jakarta Sans` | Medium | 11–12sp |

```yaml
# pubspec.yaml — fonts
fonts:
  - family: DMSerifDisplay
    fonts:
      - asset: assets/fonts/DMSerifDisplay-Regular.ttf
  - family: PlusJakartaSans
    fonts:
      - asset: assets/fonts/PlusJakartaSans-Regular.ttf
        weight: 400
      - asset: assets/fonts/PlusJakartaSans-Medium.ttf
        weight: 500
      - asset: assets/fonts/PlusJakartaSans-SemiBold.ttf
        weight: 600
      - asset: assets/fonts/PlusJakartaSans-Bold.ttf
        weight: 700
```

---

### Component Style Rules

- **Border radius:** Cards = `16px`, Buttons = `14px`, Chips/Badges = `100px` (pill)
- **Shadows:** Subtle `BoxShadow(blurRadius: 12, color: Colors.black.withOpacity(0.06))`
- **Spacing system:** 4 / 8 / 12 / 16 / 20 / 24 / 32 / 48px scale
- **Buttons:** Filled (primary actions), outlined (secondary), text-only (destructive/cancel)
- **Bottom sheets:** Used instead of full-screen modals for forms where possible
- **Status badges:** Pill shape, colored background + matching text, always with a dot icon
- **Pet avatars:** Circular, `60px` in lists, `100px` on profile pages, warm placeholder with paw icon
- **Empty states:** Centered illustration (SVG) + heading + subtext + CTA button
- **Loading:** Skeleton shimmer using `shimmer` package, not spinners

---

### Navigation Pattern

```
BottomNavigationBar (5 tabs)
├── 🏠 Home (Dashboard)
├── 🐾 Pets
├── 📋 Records
├── 📅 Appointments
└── 👤 Profile
```

- Active tab uses `primaryGreen` icon + label
- Floating Action Button (FAB) on context-aware screens for quick add
- iOS: `CupertinoTabScaffold` for native feel; Android: Material 3 BottomNavigationBar

---

## 📦 Plan Tiers

| Feature | Free | Pro ($4.99/mo) | Premium ($9.99/mo) |
|---------|------|---------------------|------------------------|
| Pet profiles | 1 pet | 3 pets | Unlimited |
| Health records | 5 records | Unlimited | Unlimited |
| Vaccine tracker | ✅ | ✅ | ✅ |
| File/doc uploads | ❌ | ✅ | ✅ |
| Appointment reminders | ❌ | ✅ | ✅ |
| Push notifications | ❌ | ✅ | ✅ |
| PDF passport export | ❌ | ❌ | ✅ |

---

## 🗂️ Project Folder Structure

```
pawpass/
├── lib/
│   ├── core/
│   │   ├── theme/
│   │   │   ├── app_theme_data.dart      ← PawThemeData + all 6 themes
│   │   │   ├── app_theme_builder.dart   ← ThemeData factory from PawThemeData
│   │   │   └── app_text_styles.dart
│   │   ├── constants/
│   │   │   └── supabase_constants.dart
│   │   ├── router/
│   │   │   └── app_router.dart          ← GoRouter
│   │   └── utils/
│   │       ├── date_utils.dart
│   │       └── validators.dart
│   ├── data/
│   │   ├── models/
│   │   │   ├── pet_model.dart
│   │   │   ├── vet_record_model.dart
│   │   │   ├── vaccine_model.dart
│   │   │   ├── appointment_model.dart
│   │   │   ├── medication_model.dart
│   │   │   └── weight_log_model.dart
│   │   └── repositories/
│   │       ├── auth_repository.dart
│   │       ├── pet_repository.dart
│   │       ├── record_repository.dart
│   │       ├── vaccine_repository.dart
│   │       ├── appointment_repository.dart
│   │       ├── medication_repository.dart
│   │       └── weight_repository.dart
│   ├── features/
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   ├── dashboard/
│   │   │   └── dashboard_screen.dart
│   │   ├── pets/
│   │   │   ├── pet_list_screen.dart
│   │   │   ├── pet_profile_screen.dart
│   │   │   └── add_edit_pet_screen.dart
│   │   ├── records/
│   │   ├── vaccines/
│   │   ├── appointments/
│   │   ├── medications/
│   │   ├── weight/
│   │   ├── profile/
│   │   │   ├── profile_screen.dart
│   │   │   └── theme_picker_screen.dart ← NEW
│   │   └── billing/
│   ├── shared/
│   │   ├── widgets/
│   │   │   ├── paw_button.dart
│   │   │   ├── paw_card.dart
│   │   │   ├── status_badge.dart
│   │   │   ├── empty_state.dart
│   │   │   ├── skeleton_loader.dart
│   │   │   └── upgrade_modal.dart
│   │   └── providers/
│   │       ├── auth_provider.dart
│   │       ├── pet_provider.dart
│   │       └── theme_provider.dart      ← NEW
│   └── main.dart
├── assets/
│   ├── fonts/
│   ├── images/
│   └── icons/
└── pubspec.yaml
```

---

## 🪜 Step-by-Step Build Plan

---

### Step 1 — Project Setup

- [ ] Create Flutter project: `flutter create pawpass --org com.pawpass`
- [ ] Set minimum SDK: iOS 14+, Android API 23+
- [ ] Add core dependencies to `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.x.x
  go_router: ^14.x.x
  riverpod: ^2.x.x              # State management
  flutter_riverpod: ^2.x.x
  riverpod_annotation: ^2.x.x
  image_picker: ^1.x.x
  file_picker: ^8.x.x
  cached_network_image: ^3.x.x
  shimmer: ^3.x.x
  intl: ^0.19.x
  freezed_annotation: ^2.x.x
  json_annotation: ^4.x.x
  flutter_local_notifications: ^17.x.x
  in_app_purchase: ^3.x.x          # Apple IAP + Google Play Billing
  url_launcher: ^6.x.x             # Open links (manage subscription, share)
  share_plus: ^9.x.x
  flutter_svg: ^2.x.x
  lottie: ^3.x.x                # Animations
  shared_preferences: ^2.x.x    # Persist theme selection locally

dev_dependencies:
  build_runner: ^2.x.x
  freezed: ^2.x.x
  json_serializable: ^6.x.x
  riverpod_generator: ^2.x.x
```

- [ ] Configure `supabase_flutter` in `main.dart`
- [ ] Setup GoRouter with initial routes: `/`, `/login`, `/register`, `/dashboard`
- [ ] Configure `AndroidManifest.xml` + `Info.plist` for camera, photo library, notifications
- [ ] Add custom fonts to `assets/fonts/` and register in `pubspec.yaml`
- [ ] Create `AppTheme` with full `ThemeData` (colors, text, input, button, card themes)
- [ ] Setup flavor environments (development / production) with separate `.env` values

**✅ Done when:** App launches on simulator/emulator with custom font and cream background. No errors.

---

### Step 2 — Supabase Setup

- [ ] Create Supabase project at `app.supabase.com`
- [ ] Run `schema.sql` in SQL Editor (all 8 tables created in one shot)
- [ ] Confirm RLS enabled on all tables
- [ ] Confirm storage buckets: `pet-photos` (public), `vet-documents` (private)
- [ ] Add Deep Link config for Supabase Auth redirects:
  - Android: `android:scheme="pawpass"` in `AndroidManifest.xml`
  - iOS: URL scheme `pawpass://` in `Info.plist`
- [ ] Store credentials securely using `flutter_dotenv` or `--dart-define`

```dart
// lib/main.dart
await Supabase.initialize(
  url: const String.fromEnvironment('SUPABASE_URL'),
  anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
);
```

**✅ Done when:** `supabase.from('pets').select()` returns empty list with no error.

---

### Step 3 — Authentication

- [ ] Build `LoginScreen` — email/password + Google sign-in button + "Don't have an account?" link
- [ ] Build `RegisterScreen` — name, email, password + confirm password
- [ ] Setup Google Sign-In:
  - Android: `google-services.json` + SHA-1 fingerprint in Supabase
  - iOS: `GoogleService-Info.plist` + URL scheme
- [ ] Create `AuthRepository` with `signIn`, `signUp`, `signOut`, `currentUser`
- [ ] Create `AuthNotifier` (Riverpod) — watches `supabase.auth.onAuthStateChange`
- [ ] Create `AuthGuard` in GoRouter — redirects unauthenticated users to `/login`
- [ ] "Forgot Password" screen — triggers Supabase password reset email
- [ ] Verify `handle_new_user` trigger creates row in `public.users` on signup

**Design notes:**
- Login screen: Full-bleed warm cream bg, large DM Serif Display logo at top, centered card-less form
- Google button: White with Google logo SVG, outlined border, pill shape
- Password field: Toggle visibility icon (eye)

**✅ Done when:** User can sign up, log in with Google, log out, and reset password.

---

### Step 4 — Navigation Shell & Dashboard

- [ ] Build `MainShell` with `BottomNavigationBar` (5 tabs)
- [ ] Dashboard widgets:
  - **Active Pet Card** — large card with pet photo, name, species, age
  - **Upcoming Appointments** — horizontal scroll, next 3 appointments
  - **Vaccine Status Summary** — pill row: `✅ 4 up to date · 🟡 1 due soon`
  - **Active Medications** — count badge with list preview
  - **Quick Actions Row** — Add Record / Log Weight / Add Appointment
- [ ] Pet switcher in app bar — tappable pet name + avatar → bottom sheet with pet list
- [ ] Notification bell icon in app bar (placeholder)
- [ ] Pull-to-refresh on Dashboard
- [ ] Skeleton shimmer loaders for all dashboard widgets
- [ ] Empty state for new users: illustration + "Add your first pet →" CTA

**Design notes:**
- Dashboard background: `theme.background`
- Section headings: DM Serif Display 22sp, `theme.textPrimary`
- Cards: `theme.surface`, `borderRadius: 16`, subtle shadow
- Quick action buttons: `theme.primaryLight` fill, `theme.primary` icon + text

**✅ Done when:** Dashboard loads with shimmer, shows real data, pet switcher works.

---

### Step 5 — Multi-Theme System

#### 5a — Theme Provider (Riverpod + SharedPreferences)

The selected theme is persisted locally with `shared_preferences` so it survives app restarts. It is also saved to `public.users` so it syncs across devices when the user logs in.

- [ ] Add dependency: `shared_preferences: ^2.x.x`
- [ ] Create `ThemeNotifier`:

```dart
// lib/shared/providers/theme_provider.dart
@riverpod
class ThemeNotifier extends _$ThemeNotifier {
  static const _key = 'selected_theme';

  @override
  PawTheme build() {
    _loadSaved(); // async load — starts as default
    return PawTheme.forest;
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null) {
      final theme = PawTheme.values.firstWhere(
        (t) => t.name == saved,
        orElse: () => PawTheme.forest,
      );
      state = theme;
    }
  }

  Future<void> setTheme(PawTheme theme) async {
    state = theme;
    // 1. Persist locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, theme.name);
    // 2. Sync to Supabase for cross-device consistency
    final uid = supabase.auth.currentUser?.id;
    if (uid != null) {
      await supabase.from('users')
        .update({'theme': theme.name})
        .eq('id', uid);
    }
  }
}
```

- [ ] Add `theme` column to `public.users` in Supabase:

```sql
-- Run in Supabase SQL Editor
alter table public.users
  add column theme text not null default 'forest'
  check (theme in ('forest','ocean','blossom','amber','midnight','lavender'));
```

- [ ] On login, load saved theme from `public.users` and override local preference

---

#### 5b — ThemeData Builder

Convert `PawThemeData` into Flutter's `ThemeData` so all Material widgets automatically match the active theme:

```dart
// lib/core/theme/app_theme_builder.dart
class AppThemeBuilder {
  static ThemeData build(PawThemeData t) {
    return ThemeData(
      useMaterial3: true,
      brightness: t.brightness,
      colorScheme: ColorScheme(
        brightness: t.brightness,
        primary: t.primary,
        onPrimary: Colors.white,
        secondary: t.primaryLight,
        onSecondary: t.textPrimary,
        surface: t.surface,
        onSurface: t.textPrimary,
        error: PawThemeData.alertRed,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: t.background,
      cardTheme: CardTheme(
        color: t.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: t.background,
        foregroundColor: t.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'DMSerifDisplay',
          fontSize: 22,
          color: t.textPrimary,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: t.surface,
        selectedItemColor: t.primary,
        unselectedItemColor: t.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: t.primaryLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: t.primaryLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: t.primary, width: 2),
        ),
        hintStyle: TextStyle(color: t.textMuted, fontFamily: 'PlusJakartaSans'),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: t.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      fontFamily: 'PlusJakartaSans',
    );
  }
}
```

- [ ] Wire into `MaterialApp` in `main.dart`:

```dart
// lib/main.dart
Consumer(builder: (context, ref, _) {
  final themeKey = ref.watch(themeNotifierProvider);
  final themeData = PawThemeData.all[themeKey]!;
  return MaterialApp.router(
    theme: AppThemeBuilder.build(themeData),
    routerConfig: appRouter,
  );
})
```

---

#### 5c — Theme Picker Screen (Profile → Themes)

- [ ] Create `ThemePickerScreen` — accessible from Profile screen
- [ ] Show all 6 themes as a 2-column grid of cards
- [ ] Each card shows: emoji, theme name, and a mini color preview strip (3 colored circles: primary, background, surface)
- [ ] Active theme has a `primaryGreen` checkmark border
- [ ] Tapping a card instantly applies the theme (no save button needed — reactive via Riverpod)
- [ ] Animated transition: use `AnimatedTheme` widget at app root so colors interpolate smoothly when switching

```dart
// lib/features/profile/theme_picker_screen.dart
class ThemePicker extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Choose Theme')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
        ),
        itemCount: PawThemeData.all.length,
        itemBuilder: (context, index) {
          final entry = PawThemeData.all.entries.elementAt(index);
          final isActive = entry.key == currentTheme;
          final t = entry.value;
          return GestureDetector(
            onTap: () => ref.read(themeNotifierProvider.notifier).setTheme(entry.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isActive ? t.primary : Colors.transparent,
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: 8),
                  Text(t.name,
                    style: TextStyle(
                      fontFamily: 'DMSerifDisplay',
                      fontSize: 18,
                      color: t.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  // Color preview strip
                  Row(children: [
                    _ColorDot(t.primary),
                    const SizedBox(width: 6),
                    _ColorDot(t.primaryLight),
                    const SizedBox(width: 6),
                    _ColorDot(t.background),
                    if (isActive) ...[
                      const Spacer(),
                      Icon(Icons.check_circle, color: t.primary, size: 20),
                    ],
                  ]),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  const _ColorDot(this.color);
  @override
  Widget build(BuildContext context) => Container(
    width: 20, height: 20,
    decoration: BoxDecoration(
      color: color, shape: BoxShape.circle,
      border: Border.all(color: Colors.black.withOpacity(0.08)),
    ),
  );
}
```

- [ ] Add "Themes" row to Profile screen (with current theme emoji preview):

```dart
// In profile_screen.dart
ListTile(
  leading: const Icon(Icons.palette_outlined),
  title: const Text('App Theme'),
  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
    Text(currentThemeData.emoji, style: const TextStyle(fontSize: 20)),
    const SizedBox(width: 4),
    Text(currentThemeData.name,
      style: TextStyle(color: context.textMuted, fontSize: 13)),
    const Icon(Icons.chevron_right),
  ]),
  onTap: () => context.push('/profile/themes'),
),
```

**Design notes:**
- The entire app (background, cards, buttons, nav bar, text) reacts instantly when a theme is switched
- `Midnight` theme sets `brightness: Brightness.dark` — system status bar, keyboard, and pickers follow automatically
- Theme switch animation: 300ms interpolation via `AnimatedTheme` feels smooth and intentional, not jarring
- Show the current theme's emoji on the Profile screen row as a subtle preview

**✅ Done when:** User can open Profile → Themes, tap any of the 6 theme cards, and watch the entire app repaint in real-time. Selection persists across restarts and syncs across devices.

---

### Step 6 — Pet Profiles

- [ ] `PetListScreen` — grid of pet avatar cards (name, species, age)
- [ ] `AddEditPetScreen` (bottom sheet or full screen):
  - Fields: name, species (chip selector), breed, gender (chip), DOB (date picker), weight, color, microchip, neutered toggle, notes
  - Photo upload: `image_picker` → upload to Supabase `pet-photos` bucket
- [ ] `PetProfileScreen` — hero photo at top, detail sections in cards below
- [ ] Delete pet — confirmation bottom sheet with destructive red button
- [ ] `PetRepository` with `getPets`, `createPet`, `updatePet`, `deletePet`
- [ ] `PetsNotifier` (Riverpod)
- [ ] **Gate:** Free plan → block adding 2nd pet → show `UpgradeModal`

**Design notes:**
- Species selector: horizontal chip row with emoji icons (🐶 Dog, 🐱 Cat, 🐰 Rabbit, 🐦 Bird, ✨ Other)
- Pet profile hero: full-width image with gradient overlay, pet name in DM Serif Display over image
- Age auto-calculated from DOB and displayed as "2 years, 3 months"

**✅ Done when:** User can add, view, edit, delete pets. Free plan capped at 1.

---

### Step 7 — Health Records

- [ ] `RecordsListScreen` — filter tabs by type (All / Checkup / Surgery / Dental / etc.)
- [ ] `AddEditRecordScreen`:
  - Fields: type (icon + label selector), title, date, vet name, clinic, diagnosis, treatment, notes, cost
  - Document upload: `file_picker` (PDF or image) → Supabase `vet-documents` bucket
- [ ] `RecordDetailScreen` — full record with inline PDF preview or download button
- [ ] Sort by date desc; section headers "2025" / "2024"
- [ ] `RecordRepository` + `RecordsNotifier`
- [ ] **Gate:** Free → max 5 records → `UpgradeModal`
- [ ] **Gate:** Free → no file upload → `UpgradeModal` on file tap

**Design notes:**
- Record type icons: outlined icons with `theme.primaryLight` background circle
- Cost field: currency input with `$` prefix, formatted with `intl` package
- Document attachment chip: pill with paperclip icon, tappable to preview

**✅ Done when:** Records list, add, edit, delete work. Document upload works for paid users.

---

### Step 8 — Vaccine Tracker

- [ ] `VaccinesListScreen` — card per vaccine with status badge
- [ ] `AddEditVaccineScreen`:
  - Fields: name, date given, next due date, vet name, clinic, batch number, notes, certificate upload
- [ ] Status badge logic (computed client-side from `next_due_date`):
  - 🟢 **Up to date** — due > 30 days away
  - 🟡 **Due soon** — due within 30 days
  - 🔴 **Overdue** — past due date
- [ ] Vaccine summary widget for Dashboard (reusable `VaccineSummaryChip`)
- [ ] `VaccineRepository` + `VaccinesNotifier`

```dart
VaccineStatus getStatus(DateTime? nextDue) {
  if (nextDue == null) return VaccineStatus.unknown;
  final now = DateTime.now();
  if (nextDue.isBefore(now)) return VaccineStatus.overdue;
  if (nextDue.difference(now).inDays <= 30) return VaccineStatus.dueSoon;
  return VaccineStatus.upToDate;
}
```

**✅ Done when:** Vaccines show correct badges. Dashboard summary reflects real data.

---

### Step 9 — Appointments

- [ ] `AppointmentsScreen` — tabs: Upcoming / Past
- [ ] `AddEditAppointmentScreen`:
  - Fields: title, type (chip), date + time (combined picker), vet name, clinic, phone, address, notes
- [ ] Swipe-to-complete and swipe-to-cancel gestures on appointment cards
- [ ] Upcoming appointments horizontal scroll widget for Dashboard
- [ ] `AppointmentRepository` + `AppointmentsNotifier`
- [ ] **Gate:** Free → no appointment creation → `UpgradeModal`

**Design notes:**
- Appointment card: left colored border (green=upcoming, gray=past, red=cancelled)
- Date/time: `CupertinoDatePicker` on iOS, `showDatePicker` + `showTimePicker` on Android

**✅ Done when:** Appointments CRUD works, dashboard widget shows upcoming. Free gate blocks creation.

---

### Step 10 — Medications

- [ ] `MedicationsScreen` — two sections: Active / Inactive
- [ ] `AddEditMedicationScreen`:
  - Fields: name, dosage, frequency (dropdown: Daily / Weekly / Monthly / As Needed / Custom), start date, end date (optional), prescribed by, notes
- [ ] Toggle active/inactive with confirmation
- [ ] Active medication count badge on Dashboard widget
- [ ] `MedicationRepository` + `MedicationsNotifier`

**✅ Done when:** Medications track correctly. Dashboard shows active count.

---

### Step 11 — Weight Log

- [ ] Weight log tab inside `PetProfileScreen` or dedicated screen
- [ ] Quick-add weight bottom sheet: weight input + date (default today) + optional note
- [ ] Weight history list (date + weight)
- [ ] Weight chart using `fl_chart` package — line chart with smooth curve, `primaryGreen` line
- [ ] Latest weight synced back to pet profile display
- [ ] `WeightRepository` + `WeightNotifier`

```yaml
# Add to pubspec.yaml
fl_chart: ^0.69.x
```

**✅ Done when:** User can log weights and see a line chart of history.

---

### Step 12 — Push Notifications & Reminders

- [ ] Setup `flutter_local_notifications` for local scheduled notifications
- [ ] On appointment creation → schedule local notification 24h before `datetime`
- [ ] On vaccine `next_due_date` approaching → schedule local notification 7 days before
- [ ] Request notification permission on first launch (iOS: native prompt, Android 13+: runtime permission)
- [ ] Cancel notifications when appointment is deleted or cancelled
- [ ] **Server-side (Supabase Edge Function):** Cron to call Resend for Pro plan users:
  - Query appointments within next 24h where `reminder_sent = false`
  - Send email via Resend, set `reminder_sent = true`
- [ ] **Gate:** Push + email reminders only for Pro Plan

**✅ Done when:** Creating an appointment schedules a local notification. Email reminder fires from server.

---

### Step 13 — In-App Purchases (IAP)

> Apple and Google require all digital subscription revenue inside mobile apps to go through their own IAP systems. No third-party checkout (LemonSqueezy, Stripe, etc.) allowed for in-app upgrades.

#### 13a — Store Setup

**Apple App Store Connect:**
- [ ] Go to App Store Connect → Your App → Subscriptions
- [ ] Create Subscription Group: `PawPass Premium`
- [ ] Create auto-renewable subscription:
  - `com.pawpass.pro.monthly` — $4.99/mo — "Pro Plan Monthly"
- [ ] Add subscription descriptions + promotional images
- [ ] Enable StoreKit testing in Xcode (StoreKit Configuration file for sandbox)

**Google Play Console:**
- [ ] Go to Play Console → Your App → Monetize → Subscriptions
- [ ] Create subscription with matching product ID:
  - `com.pawpass.pro.monthly`
- [ ] Add base plan (monthly) + optional offer for each
- [ ] Enable License Testing in Play Console settings

---

#### 13b — Flutter IAP Integration

- [ ] Add `in_app_purchase` package:

```yaml
dependencies:
  in_app_purchase: ^3.x.x
```

- [ ] Create `IAPRepository` — wraps `InAppPurchase` singleton:

```dart
// lib/data/repositories/iap_repository.dart
class IAPRepository {
  static const _productIds = {
    'com.pawpass.pro.monthly',
  };

  final _iap = InAppPurchase.instance;

  // Load products from the store
  Future<List<ProductDetails>> fetchProducts() async {
    final response = await _iap.queryProductDetails(_productIds);
    return response.productDetails;
  }

  // Initiate a purchase
  Future<void> buySubscription(ProductDetails product) async {
    final param = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  // Restore previous purchases (required by Apple guidelines)
  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }
}
```

- [ ] Listen to purchase updates stream in `main.dart` (must be active for the lifetime of the app):

```dart
// lib/main.dart — inside initState or provider
final purchaseStream = InAppPurchase.instance.purchaseStream;
_subscription = purchaseStream.listen(
  _onPurchaseUpdate,
  onDone: () => _subscription.cancel(),
  onError: (error) => debugPrint('IAP error: $error'),
);
```

---

#### 13c — Server-Side Receipt Validation (Required)

Never trust the client alone. Validate receipts server-side before unlocking features.

- [ ] Create Supabase Edge Function: `validate-purchase`

```typescript
// supabase/functions/validate-purchase/index.ts
Deno.serve(async (req) => {
  const { platform, purchaseToken, productId, userId } = await req.json();

  if (platform === 'android') {
    // Call Google Play Developer API
    // GET https://androidpublisher.googleapis.com/androidpublisher/v3/
    //   applications/{packageName}/purchases/subscriptions/{subscriptionId}/tokens/{token}
    const valid = await verifyGooglePurchase(purchaseToken, productId);
    if (valid) await updateUserPlan(userId, productId);

  } else if (platform === 'ios') {
    // Call App Store Server API (recommended over legacy verifyReceipt)
    // POST https://api.storekit.itunes.apple.com/inApps/v1/subscriptions/{transactionId}
    const valid = await verifyApplePurchase(purchaseToken);
    if (valid) await updateUserPlan(userId, productId);
  }

  return new Response(JSON.stringify({ success: true }));
});

async function updateUserPlan(userId: string, productId: string) {
  const plan = 'pro';
  await supabase.from('users').update({ plan }).eq('id', userId);
}
```

- [ ] From Flutter, call the Edge Function after a successful purchase:

```dart
void _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
  for (final purchase in purchases) {
    if (purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored) {

      // 1. Send to your server for validation
      await supabase.functions.invoke('validate-purchase', body: {
        'platform': Platform.isIOS ? 'ios' : 'android',
        'purchaseToken': purchase.verificationData.serverVerificationData,
        'productId': purchase.productID,
        'userId': supabase.auth.currentUser!.id,
      });

      // 2. Complete the purchase (REQUIRED — do not skip)
      await InAppPurchase.instance.completePurchase(purchase);

      // 3. Refresh local plan state
      ref.invalidate(subscriptionProvider);
    }

    if (purchase.status == PurchaseStatus.error) {
      debugPrint('Purchase error: ${purchase.error}');
    }
  }
}
```

---

#### 13d — Subscription State & UI

- [ ] `SubscriptionNotifier` (Riverpod) — reads `plan` from `public.users`:

```dart
@riverpod
class SubscriptionNotifier extends _$SubscriptionNotifier {
  bool get isPro => state.plan == 'pro';
}
```

- [ ] `PricingScreen` — Pro plan card with feature list + price loaded from store
- [ ] `UpgradeModal` — bottom sheet shown at every feature gate
- [ ] "Restore Purchases" button on pricing screen (required by Apple)
- [ ] Apply gates across all features using `ref.watch(subscriptionProvider)`
- [ ] Handle edge cases: pending purchases, billing issues, expired subscriptions

**Design notes:**
- Pricing card: Pro Plan with feature list
- Show real prices fetched from `ProductDetails` — never hardcode prices in UI (exchange rates vary)
- `UpgradeModal`: paw icon at top, benefit list with checkmarks, two tappable plan cards

**✅ Done when:** Sandbox purchase upgrades `users.plan` in Supabase. Receipt validated server-side. All feature gates unlock. Restore Purchases works.

---

### Step 14 — Profile Screen

The Profile tab is the control centre for account, theme, subscription, and preferences.

- [ ] Build `ProfileScreen` with the following sections:

**Account section:**
```
[Avatar] Full Name
         email@example.com
```
- [ ] Tappable avatar → `image_picker` → upload to Supabase Storage `pet-photos` bucket
- [ ] Edit name inline or via a bottom sheet
- [ ] Show current subscription plan badge (Free / Pro) next to name

**App settings section:**
- [ ] `ListTile` — **App Theme** → current theme emoji + name → navigates to `ThemePickerScreen`
- [ ] `ListTile` — **Notifications** → toggle push on/off, opens system notification settings via `url_launcher`
- [ ] `ListTile` — **Units** → toggle weight between kg / lbs (stored in `shared_preferences`)

**Subscription section:**
- [ ] `ListTile` — **Your Plan** → shows plan name + expiry → taps to Pricing screen
- [ ] `ListTile` — **Restore Purchases** → calls `InAppPurchase.instance.restorePurchases()`
- [ ] `ListTile` — **Manage Subscription** → `url_launcher` to App Store / Play Store subscription management

**Support & Legal section:**
- [ ] `ListTile` — **Help & FAQ** → opens in-app WebView or external URL
- [ ] `ListTile` — **Privacy Policy**
- [ ] `ListTile` — **Terms of Service**
- [ ] `ListTile` — **Rate PawPass** → `url_launcher` to App Store / Play Store listing

**Danger zone:**
- [ ] `ListTile` — **Sign Out** → `alertAmber` text color, triggers `AuthRepository.signOut()`
- [ ] `ListTile` — **Delete Account** → `alertRed` text color → confirmation bottom sheet → deletes Supabase auth user + cascades all data

**Design notes:**
- Avatar: 80px circle, `theme.primaryLight` placeholder background with a paw icon
- Plan badge: pill chip — Free = `textMuted` outline, Pro = `primary` fill + white text
- Section headers: `Plus Jakarta Sans` Medium 11sp, `textMuted`, all-caps with letter spacing
- Dividers between sections only, not between rows within a section
- Destructive actions (Sign Out, Delete) separated visually at the bottom with extra top padding

**✅ Done when:** User can update avatar, switch theme, manage subscription, and sign out from the Profile tab.

---

### Step 15 — App Store Submission

- [ ] Set app icons — 1024x1024 PNG (no alpha) for iOS, adaptive icon for Android
- [ ] Set splash screen using `flutter_native_splash`
- [ ] Write `App Store Connect` listing: title, subtitle, description, keywords, screenshots (6.7", 6.1", iPad)
- [ ] Write `Google Play Console` listing: title, short/full description, screenshots, feature graphic
- [ ] Configure signing:
  - iOS: distribution certificate + provisioning profile in Xcode
  - Android: `upload-keystore.jks` + signing config in `build.gradle`
- [ ] Set version + build number in `pubspec.yaml`
- [ ] Run `flutter build ipa --release` and `flutter build appbundle --release`
- [ ] Submit for review (Apple: ~1-3 days, Google: ~3-7 days)

**✅ Done when:** App is live on both App Store and Google Play.

---

## 🗃️ Data Models (Freezed + JSON)

```dart
// lib/data/models/pet_model.dart
@freezed
class Pet with _$Pet {
  const factory Pet({
    required String id,
    required String userId,
    required String name,
    required String species,
    String? breed,
    String? gender,
    DateTime? dob,
    double? weightKg,
    String? photoUrl,
    String? microchip,
    @Default(false) bool neutered,
    @Default(true) bool isActive,
    required DateTime createdAt,
  }) = _Pet;

  factory Pet.fromJson(Map<String, dynamic> json) => _$PetFromJson(json);
}
```

Apply same pattern for: `VetRecord`, `Vaccine`, `Appointment`, `Medication`, `WeightLog`.

---

## 🛠️ Full Tech Stack

| Layer | Tool | Why |
|-------|------|-----|
| Framework | Flutter 3.x | Single codebase → iOS + Android |
| State | Riverpod 2.x + code gen | Scalable, testable, reactive |
| Navigation | GoRouter | Declarative, deep link support |
| Backend | Supabase | Auth + DB + Storage + RLS |
| Payments | in_app_purchase | Apple StoreKit + Google Play Billing — required for mobile subscriptions |
| Email reminders | Resend + Supabase Edge Functions | Server-side appointment email alerts |
| Local notifications | flutter_local_notifications | Scheduled push alerts on device |
| Theming | SharedPreferences + Riverpod | 6 live themes, persisted locally + synced to Supabase |
| Charts | fl_chart | Weight history line chart |
| Image loading | cached_network_image | Cached pet photos from Supabase Storage |
| File/doc upload | file_picker | Pick PDFs/images from device |
| Serialization | Freezed + JSON serializable | Type-safe, immutable data models |
| Fonts | DM Serif Display + Plus Jakarta Sans | Warm, distinctive, readable |
| Animations | Lottie + AnimatedTheme + Hero | Empty states, theme transitions, page transitions |
| Deep links | GoRouter + app scheme | Auth callbacks, billing success redirect |
| Links | url_launcher | Open external URLs (manage subscription, share, etc.) |

---

## 🚀 Post-Launch Roadmap

### Phase 2 — Growth
- [ ] PDF Passport Export — downloadable pet passport using `pdf` package
- [ ] Vet Share Link — read-only web link to share pet records
- [ ] Google Calendar Sync — `google_sign_in` + Calendar API
- [ ] Custom accent color picker — let users fine-tune their theme's primary color (Pro)
- [ ] Per-pet theme — assign a different theme color to each pet profile (Pro)

### Phase 3 — Expansion
- [ ] AI Symptom Checker — photo or text → Claude API health suggestion
- [ ] Groomer module — grooming appointments + coat condition notes
- [ ] Pet Insurance tracker — policy storage + claim history
- [ ] Multilingual — Thai, Khmer, Vietnamese (`flutter_localizations`)
- [ ] Vet clinic B2B accounts
- [ ] Seasonal themes — limited-edition holiday themes (Christmas, Lunar New Year)

---

## 💰 Revenue Milestones

| Milestone | Target | How |
|-----------|--------|-----|
| First paying user | App Store live | Friends, Facebook pet groups |
| $500 MRR | Month 2 | 100 free → 50 paid conversions |
| $1,000 MRR | Month 3 | App Store optimization + Reddit |
| $3,000 MRR | Month 5 | Vet clinic B2B |
| $10,000 MRR | Month 9 | SEA market + Pro plan push |

---

## 🔗 Project Links *(fill in as you go)*

- **Supabase:** `https://app.supabase.com/project/YOUR_ID`
- **App Store Connect:** `https://appstoreconnect.apple.com/`
- **Google Play Console:** `https://play.google.com/console/`
- **Resend:** `https://resend.com/`
- **GitHub:** `https://github.com/YOUR_USERNAME/pawpass-flutter`

---

*Last updated: April 2026 · Built with ❤️ for pet lovers*
