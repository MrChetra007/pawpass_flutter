# PawPass — Flutter UI Implementation Prompt

> Paste this into Claude, Cursor, or any AI coding assistant to generate production-ready Flutter widget code.
> The backend (Supabase, Riverpod providers, repositories, models) is already wired up.
> **Task: Build every screen's UI only.** Assume all providers and data models exist.

---

## CONTEXT

The PawPass Flutter app is **fully functional** — Supabase is connected, all Riverpod providers exist, GoRouter is configured, and all Freezed data models are generated. The only thing missing is **polished UI code** for each screen. Do not generate backend logic, SQL, or Edge Functions. Focus entirely on widget trees, theming, and layout.

**Stack already in place:**
- Flutter 3.x + Material 3
- Riverpod 2.x with code generation (`ref.watch`, `ref.read`)
- GoRouter for navigation (`context.go`, `context.push`)
- Supabase Flutter (already initialized)
- Freezed data models: `Pet`, `VetRecord`, `Vaccine`, `Appointment`, `Medication`, `WeightLog`
- Packages installed: `shimmer`, `cached_network_image`, `fl_chart`, `flutter_svg`, `image_picker`, `file_picker`, `intl`, `shared_preferences`

---

## DESIGN SYSTEM — IMPLEMENT EXACTLY AS SPECIFIED

### Theme Tokens (Forest — Default)

```dart
// Reference these via Theme.of(context) or directly as constants
// Primary green
static const primary       = Color(0xFF3D7A5F);
static const primaryLight  = Color(0xFFA8C5B5);
static const background    = Color(0xFFFAF6F1);
static const surface       = Color(0xFFFFFFFF);
static const textPrimary   = Color(0xFF1E2D2B);
static const textMuted     = Color(0xFF8A9A96);

// Semantic
static const alertAmber    = Color(0xFFE8A838);
static const alertRed      = Color(0xFFD95F52);
static const successGreen  = Color(0xFF4CAF82);
```

All 6 themes (Forest, Ocean, Blossom, Amber, Midnight, Lavender) are already in `lib/core/theme/app_theme_data.dart`. The active theme is applied via `AnimatedTheme` at the app root. Always use `Theme.of(context).colorScheme.primary` for primary color — never hardcode hex in widgets.

### Typography

```dart
// DM Serif Display — hero text, headings, pet names
TextStyle display = const TextStyle(fontFamily: 'DMSerifDisplay', fontSize: 36, color: textPrimary);
TextStyle heading = const TextStyle(fontFamily: 'DMSerifDisplay', fontSize: 24, color: textPrimary);

// Plus Jakarta Sans — everything else
TextStyle subheading = const TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600, fontSize: 16);
TextStyle body       = const TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w400, fontSize: 14);
TextStyle caption    = const TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w500, fontSize: 11, letterSpacing: 0.8);

// Section header (uppercase muted label)
TextStyle sectionHeader = TextStyle(
  fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w500,
  fontSize: 11, letterSpacing: 1.2,
  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
);
```

### Core Shared Widgets

Build these reusable widgets first in `lib/shared/widgets/`. Every screen uses them.

---

#### `PawCard` — Standard content card

```dart
// lib/shared/widgets/paw_card.dart
class PawCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const PawCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              blurRadius: 12,
              color: Colors.black.withOpacity(0.06),
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}
```

---

#### `StatusBadge` — Vaccine / appointment status pill

```dart
// lib/shared/widgets/status_badge.dart
enum BadgeStatus { upToDate, dueSoon, overdue, active, inactive, unknown }

class StatusBadge extends StatelessWidget {
  final BadgeStatus status;

  const StatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (status) {
      BadgeStatus.upToDate  => (const Color(0xFF4CAF82).withOpacity(0.12), const Color(0xFF2E7D52), 'Up to date'),
      BadgeStatus.dueSoon   => (const Color(0xFFE8A838).withOpacity(0.12), const Color(0xFFA8730A), 'Due soon'),
      BadgeStatus.overdue   => (const Color(0xFFD95F52).withOpacity(0.12), const Color(0xFFB33B30), 'Overdue'),
      BadgeStatus.active    => (const Color(0xFF4CAF82).withOpacity(0.12), const Color(0xFF2E7D52), 'Active'),
      BadgeStatus.inactive  => (Colors.grey.withOpacity(0.12), Colors.grey.shade600, 'Inactive'),
      BadgeStatus.unknown   => (Colors.grey.withOpacity(0.12), Colors.grey.shade600, 'Unknown'),
    };

    final dot = switch (status) {
      BadgeStatus.upToDate || BadgeStatus.active => '●',
      BadgeStatus.dueSoon  => '●',
      BadgeStatus.overdue  => '●',
      _ => '●',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(dot, style: TextStyle(color: fg, fontSize: 8)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: fg, fontSize: 11, fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
```

---

#### `PetAvatar` — Circular pet photo with warm placeholder

```dart
// lib/shared/widgets/pet_avatar.dart
class PetAvatar extends StatelessWidget {
  final String? photoUrl;
  final double size;

  const PetAvatar({super.key, this.photoUrl, this.size = 60});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox.square(
        dimension: size,
        child: photoUrl != null && photoUrl!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: photoUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) => _placeholder(context),
              errorWidget: (_, __, ___) => _placeholder(context),
            )
          : _placeholder(context),
      ),
    );
  }

  Widget _placeholder(BuildContext context) => Container(
    color: Theme.of(context).colorScheme.secondary,
    child: Center(
      child: Icon(Icons.pets_rounded,
        color: Theme.of(context).colorScheme.primary,
        size: size * 0.45,
      ),
    ),
  );
}
```

---

#### `SectionHeader` — Uppercase muted section label

```dart
// lib/shared/widgets/section_header.dart
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SectionHeader(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontWeight: FontWeight.w500,
                fontSize: 11,
                letterSpacing: 1.2,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
```

---

#### `EmptyState` — Centered illustration + CTA

```dart
// lib/shared/widgets/empty_state.dart
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String heading;
  final String subtext;
  final String? ctaLabel;
  final VoidCallback? onCta;

  const EmptyState({
    super.key,
    required this.icon,
    required this.heading,
    required this.subtext,
    this.ctaLabel,
    this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 96, height: 96,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
              size: 44,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(heading,
            style: const TextStyle(fontFamily: 'DMSerifDisplay', fontSize: 22),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(subtext,
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
          if (ctaLabel != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onCta,
              child: Text(ctaLabel!),
            ),
          ],
        ]),
      ),
    );
  }
}
```

---

#### `SkeletonLoader` — Shimmer placeholder while loading

```dart
// lib/shared/widgets/skeleton_loader.dart
// Uses the 'shimmer' package
class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const SkeletonBox({super.key, required this.width, required this.height, this.radius = 12});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.secondary.withOpacity(0.4),
      highlightColor: Theme.of(context).colorScheme.surface,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

// Pet card skeleton
class PetCardSkeleton extends StatelessWidget {
  const PetCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.secondary.withOpacity(0.4),
      highlightColor: Theme.of(context).colorScheme.surface,
      child: PawCard(
        child: Row(children: [
          const SkeletonBox(width: 60, height: 60, radius: 100),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SkeletonBox(width: 120, height: 16),
            const SizedBox(height: 8),
            SkeletonBox(width: 80, height: 12),
          ]),
        ]),
      ),
    );
  }
}
```

---

## SCREENS

Build each screen as a separate file in `lib/features/`. Every screen is a `ConsumerWidget`. Use `ref.watch(...)` to read live data from providers.

---

### 1. `MainShell` — Bottom Navigation Container

**File:** `lib/features/shell/main_shell.dart`

```dart
// Assume this provider exists: activePetProvider → Pet?
// Assume: themeNotifierProvider → PawTheme

class MainShell extends ConsumerStatefulWidget { ... }

// Build a persistent BottomNavigationBar with 5 tabs using StatefulShellRoute from GoRouter.
// Tab icons (outlined when inactive, filled when active):
//   0 → Icons.home_outlined / Icons.home_rounded        label: "Home"
//   1 → Icons.pets_outlined / Icons.pets                label: "Pets"
//   2 → Icons.folder_outlined / Icons.folder_rounded    label: "Records"
//   3 → Icons.calendar_today_outlined / Icons.calendar_today  label: "Appts"
//   4 → Icons.person_outline / Icons.person             label: "Profile"

// Design rules:
// - Bar background: Theme.of(context).colorScheme.surface
// - Top border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5))
// - Selected color: Theme.of(context).colorScheme.primary
// - Unselected color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45)
// - Label style: PlusJakartaSans 10px Medium
// - Bar height: 80px (use MediaQuery bottom padding for safe area)
// - No elevation, no background shadow
```

---

### 2. `DashboardScreen`

**File:** `lib/features/dashboard/dashboard_screen.dart`

**Providers to watch:**
```dart
// ref.watch(activePetProvider)              → AsyncValue<Pet?>
// ref.watch(upcomingAppointmentsProvider)   → AsyncValue<List<Appointment>>
// ref.watch(vaccineStatusSummaryProvider)   → AsyncValue<VaccineSummary>
// ref.watch(activeMedicationsProvider)      → AsyncValue<List<Medication>>
// ref.watch(authUserProvider)               → User?
```

**AppBar:**
```dart
// Left: PetSwitcher widget — tappable row with PetAvatar(size: 36) + pet name in DMSerifDisplay 18px + ExpandMore icon
// Right: IconButton(icon: Icon(Icons.notifications_outlined))
// Background: theme.scaffoldBackgroundColor
// Elevation: 0
// Bottom: no divider
```

**Body layout (ListView, padding: EdgeInsets.symmetric(horizontal: 20)):**

```
// ── Greeting ──────────────────────────────────
Text("Good morning, [firstName] 🌿")
Style: DMSerifDisplay 28px, textPrimary
Top padding: 20px

// ── Active Pet Card ───────────────────────────
PawCard (full-width):
  Row:
    PetAvatar(size: 80, photoUrl: pet.photoUrl)
    SizedBox(width: 16)
    Column:
      Text(pet.name) → DMSerifDisplay 22px
      Text("${pet.species} · ${pet.breed}") → body muted
      SizedBox(height: 4)
      Row:
        Text(ageString(pet.dob)) → caption primary
        SizedBox(width: 8)
        Text("${pet.weightKg} kg") → caption muted
      SizedBox(height: 8)
      if (pet.neutered)
        Chip(label: "Neutered", bg: successGreen.withOpacity(0.1), fg: successGreen)

// ── Vaccine Summary ───────────────────────────
PawCard:
  Row(children: [
    Text("Vaccines") → subheading
    Spacer()
    TextButton("See all", onPressed: () → navigate to vaccines tab)
  ])
  SizedBox(height: 12)
  // Horizontal scrollable row of pill chips
  // Each chip: colored dot + count + label
  // e.g.: "● 4 Up to date" (successGreen), "● 1 Due soon" (alertAmber), "● 1 Overdue" (alertRed)
  // Only show chip if count > 0

// ── Upcoming Appointments ─────────────────────
SectionHeader("Upcoming")
// Horizontal ListView of AppointmentMiniCard (140px wide each):
//   Card: radius 12, surface white, shadow
//   Top colored band (4px): successGreen if upcoming, alertRed if cancelled
//   Pet avatar (small, 32px)
//   Appointment title truncated 1 line
//   Date in caption muted
//   Doctor name in caption

// ── Active Medications ────────────────────────
PawCard:
  Row: Text("Medications") + badge chip showing active count in primaryLight bg
  Divider
  For each active medication (max 3 shown):
    MedicationMiniRow: Icon(Icons.medication_outlined) + name + frequency + since date
  if more than 3: TextButton "View all medications"

// ── Quick Actions Row ─────────────────────────
Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly):
  _QuickActionButton(icon: Icons.add_circle_outline, label: "Record", onTap: …)
  _QuickActionButton(icon: Icons.monitor_weight_outlined, label: "Weight", onTap: …)
  _QuickActionButton(icon: Icons.event_note_outlined, label: "Appt", onTap: …)

// _QuickActionButton style:
//   Container: 72px width, primaryLight 20% opacity bg, radius 14
//   Icon: 22px, primary color
//   Label: caption, primary color
```

**Loading state:** Show `PetCardSkeleton` repeated 3 times with shimmer.

**Empty state (no pets):** `EmptyState(icon: Icons.pets, heading: "Welcome to PawPass", subtext: "Add your first pet to get started", ctaLabel: "Add Pet", onCta: () => context.push('/pets/add'))`

---

### 3. `PetListScreen`

**File:** `lib/features/pets/pet_list_screen.dart`

**Provider:** `ref.watch(petsProvider)` → `AsyncValue<List<Pet>>`

**AppBar:** "My Pets" (DMSerifDisplay 22px) + FAB or AppBar action "+" navigating to `/pets/add`

**Body:**
```
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
    childAspectRatio: 0.9,
  ),
  padding: EdgeInsets.all(20),
)

// Pet Grid Card:
PawCard(onTap: () => context.push('/pets/${pet.id}')):
  Column:
    Center: PetAvatar(size: 88, photoUrl: pet.photoUrl)
    SizedBox(height: 12)
    Text(pet.name) → DMSerifDisplay 20px, center
    Text("${emoji} ${pet.species}${breed}") → caption muted, center
    SizedBox(height: 8)
    // Vaccine status dot row (centered)
    Row(mainAxisAlignment: center):
      StatusBadge(vaccineStatus)

// Last card: "Add Pet" dashed card
DashedBorderCard(onTap: () => context.push('/pets/add')):
  Column:
    Icon(Icons.add_circle_outline, size: 36, color: primary)
    Text("Add Pet") → body primary

// If Free plan and pets.length >= 1: show "Add Pet" card but onTap → UpgradeModal
```

**Empty state:** `EmptyState(icon: Icons.pets_outlined, heading: "No pets yet", subtext: "Add your first furry friend", ctaLabel: "Add Pet")`

---

### 4. `PetProfileScreen`

**File:** `lib/features/pets/pet_profile_screen.dart`

**Param:** `petId` from GoRouter path param
**Provider:** `ref.watch(petProvider(petId))` → `AsyncValue<Pet>`

**Layout:**

```
// ── Hero Section ───────────────────────────────
SliverAppBar(
  expandedHeight: 220,
  pinned: true,
  flexibleSpace: FlexibleSpaceBar(
    background: Stack(
      fit: StackFit.expand,
      children: [
        // Photo or placeholder
        pet.photoUrl != null
          ? CachedNetworkImage(fit: BoxFit.cover)
          : Container(color: primaryLight)
        // Gradient overlay bottom
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
            ),
          ),
        ),
        // Pet name bottom-left
        Positioned(bottom: 16, left: 20,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(pet.name, style: DMSerifDisplay 32px white),
            Text("${emoji(pet.species)} ${pet.species} · ${pet.gender}", style: body white 0.8 opacity),
          ])
        ),
      ],
    ),
  ),
  actions: [
    IconButton(icon: Icon(Icons.edit_outlined), onPressed: () => context.push('/pets/${pet.id}/edit')),
  ],
)

// ── Stats Row ──────────────────────────────────
// Horizontal scroll row of mini stat cards:
// [ Age ] [ Weight ] [ Microchip ] [ Neutered ]
// Each: 80px wide, surface card, stat value in primary 16px 600, label in caption muted

// ── Tab Bar ────────────────────────────────────
TabBar(
  tabs: [Tab("Records"), Tab("Vaccines"), Tab("Appts"), Tab("Meds"), Tab("Weight")],
  // Style: indicator = 3px underline in primary, labelColor = primary, unselectedLabelColor = textMuted
  // labelStyle: PlusJakartaSans 13px 600
)

// Each TabBarView renders the relevant sub-screen as a scrollable list
// (Records list, Vaccines list, Appointments list, Medications list, Weight chart + list)
```

---

### 5. `AddEditPetScreen`

**File:** `lib/features/pets/add_edit_pet_screen.dart`

**Present as:** Full screen (not bottom sheet — too many fields)

**AppBar:** "Add Pet" / "Edit Pet" + Save action button (text button "Save" in primary)

**Form layout (SingleChildScrollView > Column, padding: 20px H):**

```
// ── Photo Picker ───────────────────────────────
Center:
  GestureDetector(onTap: pickPhoto):
    Stack:
      PetAvatar(size: 100, photoUrl: selectedPhoto)
      Positioned(bottom: 0, right: 0):
        CircleAvatar(radius: 16, bg: primary):
          Icon(Icons.camera_alt, size: 14, color: white)

// ── Name ───────────────────────────────────────
TextFormField(
  decoration: InputDecoration(labelText: "Pet name", hintText: "e.g. Milo"),
  // Input style: radius 14, filled, fillColor: background, border: primaryLight
)

// ── Species (chip selector) ────────────────────
// Horizontal wrap of selectable emoji chips:
// 🐶 Dog · 🐱 Cat · 🐰 Rabbit · 🐦 Bird · ✨ Other
// Selected: primary bg + white text. Unselected: surface + primaryLight border

// ── Breed ─────────────────────────────────────
TextFormField(labelText: "Breed", hintText: "e.g. Labrador Retriever")

// ── Gender ────────────────────────────────────
// Two chips: ♂ Male · ♀ Female (same chip style as species)

// ── Date of Birth ─────────────────────────────
TextFormField(
  labelText: "Date of Birth",
  readOnly: true,
  onTap: () => showDatePicker → CupertinoDatePicker on iOS,
  suffixIcon: Icon(Icons.calendar_today_outlined),
)

// ── Weight ────────────────────────────────────
TextFormField(
  labelText: "Weight",
  hintText: "e.g. 28.5",
  keyboardType: TextInputType.number,
  // Trailing unit toggle: kg / lbs (reads from preferencesProvider)
  suffixText: "kg",
)

// ── Microchip ─────────────────────────────────
TextFormField(labelText: "Microchip number", keyboardType: TextInputType.number)

// ── Neutered toggle ───────────────────────────
SwitchListTile(
  title: Text("Neutered / Spayed"),
  value: isNeutered,
  activeColor: successGreen,
  // No contentPadding — flush with form
)

// ── Notes ─────────────────────────────────────
TextFormField(labelText: "Notes", maxLines: 3)

// ── Save Button ───────────────────────────────
SizedBox(width: double.infinity, height: 52):
  ElevatedButton(child: Text("Save Pet"), onPressed: _submit)

// ── Delete Button (edit mode only) ────────────
TextButton(
  onPressed: () => _showDeleteConfirmation(context),
  child: Text("Delete Pet", style: TextStyle(color: alertRed)),
)
```

---

### 6. `RecordsListScreen`

**File:** `lib/features/records/records_list_screen.dart`

**Provider:** `ref.watch(recordsProvider(petId))` → `AsyncValue<List<VetRecord>>`

**AppBar:** "Health Records" + filter icon

```
// ── Filter Tab Bar ─────────────────────────────
// Horizontal scroll chip row: All · Checkup · Surgery · Dental · Lab · Vaccination · Other
// Selected chip: primary bg + white text. Unselected: surface + border

// ── Grouped List by Year ───────────────────────
// Group records by year, show sticky year headers

// Record Card (PawCard with onTap → RecordDetailScreen):
Row:
  // Type icon circle (48px, primaryLight bg)
  Container(48px, circle, color: primaryLight):
    Icon(recordTypeIcon(record.type), color: primary, size: 22)
  SizedBox(width: 12)
  Expanded:
    Column:
      Text(record.title) → subheading 15px
      Text("${record.vetName} · ${record.clinicName}") → body muted
      SizedBox(height: 4)
      Row:
        Text(formatDate(record.date)) → caption muted
        Spacer()
        if (record.cost != null)
          Text("\$${record.cost!.toStringAsFixed(0)}") → caption primary
  if (record.documentUrl != null)
    // Attachment chip (bottom of card, below row)
    // Pill: 📎 icon + "document.pdf" in muted, tappable to open

// Record type → icon mapping:
// checkup → Icons.medical_information_outlined
// surgery → Icons.healing_outlined
// dental  → Icons.sentiment_very_satisfied_outlined
// lab     → Icons.biotech_outlined
// vaccination → Icons.vaccines_outlined
// other   → Icons.folder_outlined
```

**Empty state:** `EmptyState(icon: Icons.folder_open_outlined, heading: "No records yet", subtext: "Add your first health record", ctaLabel: "Add Record")`

---

### 7. `VaccinesListScreen`

**File:** `lib/features/vaccines/vaccines_list_screen.dart`

**Provider:** `ref.watch(vaccinesProvider(petId))` → `AsyncValue<List<Vaccine>>`

```
// Each vaccine as PawCard:
Row:
  Expanded:
    Column:
      Text(vaccine.name) → subheading 15px
      SizedBox(4)
      Text("Given: ${formatDate(vaccine.dateGiven)}") → body muted
      if (vaccine.nextDue != null)
        Text("Next due: ${formatDate(vaccine.nextDue!)}") → body muted
      if (vaccine.vetName != null)
        Text(vaccine.vetName!) → caption muted
  Column:
    StatusBadge(computeVaccineStatus(vaccine.nextDue))
    // if attachment exists: Icon(Icons.attach_file, size: 16, color: textMuted)

// Status computation:
VaccineStatus computeVaccineStatus(DateTime? nextDue) {
  if (nextDue == null) return VaccineStatus.unknown;
  final now = DateTime.now();
  if (nextDue.isBefore(now)) return VaccineStatus.overdue;
  if (nextDue.difference(now).inDays <= 30) return VaccineStatus.dueSoon;
  return VaccineStatus.upToDate;
}

// Overdue vaccines sorted to top. Then dueSoon. Then upToDate.
```

---

### 8. `AppointmentsScreen`

**File:** `lib/features/appointments/appointments_screen.dart`

**Provider:**
```dart
ref.watch(upcomingAppointmentsProvider(petId)) → AsyncValue<List<Appointment>>
ref.watch(pastAppointmentsProvider(petId))     → AsyncValue<List<Appointment>>
```

```
// TabBar: Upcoming · Past

// Appointment Card (dismissible for upcoming):
Dismissible(
  key: Key(appointment.id),
  background: // Red "Cancel" action (left)
  secondaryBackground: // Green "Complete" action (right)
  child:
    PawCard:
      Row:
        // Left colored border (Container 4px wide, height 80)
        Container(width: 4, height: 80,
          color: upcoming ? successGreen : Colors.grey.shade300,
          decoration: BoxDecoration(borderRadius: BorderRadius.only(topLeft: 8, bottomLeft: 8)),
        )
        SizedBox(width: 12)
        Expanded:
          Column:
            Text(appointment.title) → subheading 15px
            SizedBox(4)
            Text("${formatDateTime(appointment.datetime)}") → body muted
            Text("${appointment.vetName} · ${appointment.clinicName}") → caption muted
        // Type chip (appointment.type: Checkup, Vaccination, Dental, etc.)
        Chip(label: appointment.type, style: small, outlined)
)

// Past appointments show identical card without left border color, muted text
```

---

### 9. `MedicationsScreen`

**File:** `lib/features/medications/medications_screen.dart`

**Provider:** `ref.watch(medicationsProvider(petId))` → `AsyncValue<List<Medication>>`

```
// Two sections: ACTIVE and INACTIVE

SectionHeader("Active (${activeCount})")
// For each active medication:
PawCard:
  Row:
    // Icon (48px circle, primaryLight bg)
    Container(48px circle):
      Icon(Icons.medication_outlined, color: primary, size: 22)
    SizedBox(12)
    Expanded:
      Column:
        Text(medication.name) → subheading 15px
        Text("${medication.dosage} · ${medication.frequency}") → body muted
        Text("Since ${formatDate(medication.startDate)}") → caption muted
        if (medication.prescribedBy != null)
          Text("Dr. ${medication.prescribedBy}") → caption muted
    // Active toggle
    Switch(
      value: medication.isActive,
      activeColor: successGreen,
      onChanged: (val) => ref.read(medicationsNotifier.notifier).toggleActive(medication.id),
    )

SectionHeader("Inactive (${inactiveCount})")
// Same card but muted style: name in textMuted, icon bg in grey.withOpacity(0.1)
```

---

### 10. `WeightScreen`

**File:** `lib/features/weight/weight_screen.dart`

**Provider:**
```dart
ref.watch(weightLogsProvider(petId)) → AsyncValue<List<WeightLog>>
```

```
// ── Current Weight Hero ────────────────────────
PawCard:
  Row:
    Column:
      Text("Current Weight") → caption muted uppercase
      SizedBox(4)
      Row(crossAxisAlignment: CrossAxisAlignment.end):
        Text(latestWeight.toStringAsFixed(1)) → DMSerifDisplay 40px primary
        SizedBox(4)
        Text("kg") → body muted (baseline aligned)
    Spacer()
    Column:
      Text(changeLabel) → e.g. "↑ 0.2 kg" in successGreen or "↓ 0.1 kg" in alertRed
      Text("since last entry") → caption muted

// ── Line Chart (fl_chart) ─────────────────────
SizedBox(height: 200):
  LineChart(
    LineChartData(
      lineBarsData: [
        LineChartBarData(
          spots: weightLogs.map((w) => FlSpot(x, w.weightKg)).toList(),
          isCurved: true,
          color: Theme.of(context).colorScheme.primary,
          barWidth: 2.5,
          belowBarData: BarAreaData(
            show: true,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
          ),
          dotData: FlDotData(
            show: true,
            // Only show dot on last point
          ),
        ),
      ],
      gridData: FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: monthLabel)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
    ),
  )

// ── Weight History List ────────────────────────
SectionHeader("History")
// For each weight log (newest first):
ListTile:
  leading: Icon(Icons.monitor_weight_outlined, color: primary)
  title: Text("${log.weightKg.toStringAsFixed(1)} kg") → subheading
  subtitle: Text(log.note ?? "") → body muted
  trailing: Text(formatDate(log.date)) → caption muted

// ── FAB: "+ Log Weight" ────────────────────────
FloatingActionButton.extended(
  onPressed: () => _showAddWeightSheet(context, ref),
  label: Text("Log Weight"),
  icon: Icon(Icons.add),
  backgroundColor: primary,
)

// Quick-add bottom sheet:
showModalBottomSheet:
  Column:
    Handle bar
    Text("Log Weight") → DMSerifDisplay 22px
    TextFormField(labelText: "Weight (kg)", keyboardType: decimal)
    TextFormField(labelText: "Date", readOnly, datePicker)
    TextFormField(labelText: "Note (optional)")
    ElevatedButton(child: "Save")
```

---

### 11. `ProfileScreen`

**File:** `lib/features/profile/profile_screen.dart`

**Provider:** `ref.watch(authUserProvider)`, `ref.watch(subscriptionProvider)`, `ref.watch(themeNotifierProvider)`

```
// ── Account Header ────────────────────────────
PawCard:
  Row:
    // Avatar: 80px circle, tappable → image_picker
    GestureDetector(onTap: _pickAvatar):
      Stack:
        CircleAvatar(radius: 40, bg: primaryLight):
          // CachedNetworkImage or initials text
        Positioned(bottom: 0, right: 0):
          CircleAvatar(radius: 13, bg: primary):
            Icon(Icons.camera_alt, size: 12, color: white)
    SizedBox(16)
    Column(crossAxisAlignment: CrossAxisAlignment.start):
      Text(user.name) → DMSerifDisplay 20px
      Text(user.email) → body muted
      SizedBox(4)
      // Plan badge chip
      Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: planBadgeBg(plan),   // Free: muted outline, Paw: primaryLight, Family: primary
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(planLabel(plan),
          style: TextStyle(color: planBadgeFg(plan), fontSize: 11, fontWeight: FontWeight.w600)),
      )

// ── Settings Sections ─────────────────────────
// Use a ListView with these sections, separated by SectionHeader widgets.
// Rows use standard Material ListTile with:
//   leadingIcon: outlined icon in primary color
//   titleStyle: PlusJakartaSans 400 15px textPrimary
//   trailing: [value text in muted] + [chevron right icon]
// Dividers only between sections, not between rows within a section.

SectionHeader("App Settings")
ListTile(leading: palette_outlined,  title: "App Theme",       trailing: "${themeEmoji} ${themeName} ›",   onTap: () => context.push('/profile/themes'))
ListTile(leading: notifications,     title: "Notifications",   trailing: Switch(value: notifEnabled, activeColor: primary))
ListTile(leading: scale_outlined,    title: "Weight Units",    trailing: SegmentedButton<String>(segments: ["kg", "lbs"]))

SectionHeader("Subscription")
ListTile(leading: workspace_premium, title: "Your Plan",       trailing: "${planName} ›",  onTap: → PricingScreen)
ListTile(leading: restore,           title: "Restore Purchases", onTap: _restorePurchases)
ListTile(leading: open_in_new,       title: "Manage Subscription", onTap: _openStoreManagement)

SectionHeader("Support")
ListTile(leading: help_outline,      title: "Help & FAQ",      onTap: _openHelp)
ListTile(leading: privacy_tip,       title: "Privacy Policy",  onTap: _openPrivacy)
ListTile(leading: article_outlined,  title: "Terms of Service",onTap: _openTerms)
ListTile(leading: star_outline,      title: "Rate PawPass",    onTap: _openAppStore)

// Danger zone — extra SizedBox(height: 24) gap before
ListTile(
  title: Text("Sign Out", style: TextStyle(color: alertAmber, fontFamily: 'PlusJakartaSans')),
  leading: Icon(Icons.logout, color: alertAmber),
  onTap: _signOut,
)
ListTile(
  title: Text("Delete Account", style: TextStyle(color: alertRed, fontFamily: 'PlusJakartaSans')),
  leading: Icon(Icons.delete_forever_outlined, color: alertRed),
  onTap: _showDeleteAccountSheet,
)
```

---

### 12. `ThemePickerScreen`

**File:** `lib/features/profile/theme_picker_screen.dart`

```dart
// AppBar: "← Choose Theme"

GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.05,
  ),
  padding: EdgeInsets.all(20),
  itemCount: PawThemeData.all.length,
  itemBuilder: (context, index) {
    final entry = PawThemeData.all.entries.elementAt(index);
    final isActive = entry.key == ref.watch(themeNotifierProvider);
    final t = entry.value;

    return GestureDetector(
      onTap: () => ref.read(themeNotifierProvider.notifier).setTheme(entry.key),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 250),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? t.primary : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: [BoxShadow(blurRadius: 12, color: Colors.black.withOpacity(0.06))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.emoji, style: TextStyle(fontSize: 28)),
          SizedBox(height: 8),
          Text(t.name, style: TextStyle(fontFamily: 'DMSerifDisplay', fontSize: 18, color: t.textPrimary)),
          Spacer(),
          Row(children: [
            _ColorDot(t.primary),
            SizedBox(width: 6),
            _ColorDot(t.primaryLight),
            SizedBox(width: 6),
            _ColorDot(t.background),
            if (isActive) ...[Spacer(), Icon(Icons.check_circle, color: t.primary, size: 20)],
          ]),
        ]),
      ),
    );
  },
)
```

---

### 13. `PricingScreen` (Upgrade Modal)

**File:** `lib/features/billing/pricing_screen.dart`

**Present as:** Full screen navigated from Profile, OR as bottom sheet via `UpgradeModal`.

```
// ── Hero ──────────────────────────────────────
Center:
  Container(width: 72, height: 72, bg: primaryLight, radius: 100):
    Icon(Icons.pets, size: 36, color: primary)
  SizedBox(16)
  Text("Unlock PawPass Premium") → DMSerifDisplay 26px center
  Text("Everything your pet needs in one place") → body muted center

// ── Plan Cards (stacked vertically) ───────────

// Paw Plan Card (surface, outlined border 1px primaryLight):
PawCard:
  Row:
    Text("🐾 Paw Plan") → subheading 18px
    Spacer()
    Column:
      Text("\$4.99") → DMSerifDisplay 22px primary
      Text("/ month") → caption muted
  Divider(height: 20)
  // Feature list
  _FeatureRow(icon: check_circle, label: "Up to 3 pets", available: true)
  _FeatureRow(icon: check_circle, label: "Unlimited health records", available: true)
  _FeatureRow(icon: check_circle, label: "File & document uploads", available: true)
  _FeatureRow(icon: check_circle, label: "Appointment reminders", available: true)
  _FeatureRow(icon: check_circle, label: "Push notifications", available: true)
  _FeatureRow(icon: close,        label: "PDF passport export", available: false)
  _FeatureRow(icon: close,        label: "Family sharing", available: false)
  SizedBox(12)
  OutlinedButton(child: "Start Paw Plan", onPressed: _buyPaw, style: full-width, height: 50)

// Family Plan Card (2px primary border + "Best Value" badge):
Stack:
  PawCard(border: Border.all(color: primary, width: 2)):
    // same structure but all features ✅
    // price: $9.99
    ElevatedButton(child: "Start Family Plan", style: full-width primary bg)
  Positioned(top: -1, right: 16):
    Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(100)),
      child: Text("Best Value", style: TextStyle(color: white, fontSize: 11, fontWeight: FontWeight.w600)),
    )

// _FeatureRow:
Row:
  Icon(icon, size: 16, color: available ? successGreen : textMuted)
  SizedBox(8)
  Text(label, style: body, color: available ? textPrimary : textMuted)

// ── Footer ────────────────────────────────────
TextButton("Restore Purchases", onPressed: _restore)
Text("Cancel anytime. Prices may vary by region.", style: caption muted center)
```

---

### 14. `UpgradeModal` (Bottom Sheet)

**File:** `lib/shared/widgets/upgrade_modal.dart`

```dart
// Called anywhere a feature gate is hit:
// showModalBottomSheet(context: context, builder: (_) => UpgradeModal(feature: "document uploads"))

class UpgradeModal extends StatelessWidget {
  final String feature;
  const UpgradeModal({super.key, required this.feature});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle bar
        Container(width: 40, height: 4, margin: EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
        // Paw icon
        Container(width: 64, height: 64, decoration: BoxDecoration(color: primaryLight.withOpacity(0.3), shape: BoxShape.circle)):
          Icon(Icons.pets, size: 32, color: primary)
        SizedBox(16),
        Text("Upgrade to unlock\n$feature", style: DMSerifDisplay 22px center),
        SizedBox(8),
        Text("Get unlimited records, reminders, file uploads and more.", style: body muted center),
        SizedBox(20),
        // Benefit chips row
        Wrap(spacing: 8, children: [
          _BenefitChip("Unlimited records"),
          _BenefitChip("File uploads"),
          _BenefitChip("Reminders"),
          _BenefitChip("3 pets"),
        ]),
        SizedBox(24),
        ElevatedButton(child: "View Plans", onPressed: () { Navigator.pop(context); context.push('/pricing'); }, style: full-width height 52),
        SizedBox(8),
        TextButton(child: "Maybe later", onPressed: () => Navigator.pop(context)),
      ]),
    );
  }
}
```

---

### 15. `LoginScreen` & `RegisterScreen`

**File:** `lib/features/auth/login_screen.dart`

```
// Full-screen, no AppBar, background: theme.background (cream)

SafeArea:
  SingleChildScrollView:
    Column(padding: 32px H):
      SizedBox(height: 60)
      // App logo
      Row(mainAxisAlignment: center):
        Container(48px, radius: 14, color: primary):
          Icon(Icons.pets, color: white, size: 28)
        SizedBox(12)
        Text("PawPass") → DMSerifDisplay 32px primary

      SizedBox(40)
      Text("Welcome back") → DMSerifDisplay 28px
      Text("Sign in to your account") → body muted
      SizedBox(32)

      TextFormField(labelText: "Email", keyboardType: email)
      SizedBox(16)
      TextFormField(
        labelText: "Password",
        obscureText: _obscure,
        suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_off : Icons.visibility), onPressed: toggle),
      )
      SizedBox(8)
      Align(alignment: Alignment.centerRight):
        TextButton("Forgot password?", onPressed: _forgotPassword, style: TextStyle(color: primary))

      SizedBox(24)
      ElevatedButton(child: "Sign In", style: full-width height 52, onPressed: _signIn)
      SizedBox(16)

      // Divider with "or"
      Row: [Expanded(Divider()), Padding(Text("or")), Expanded(Divider())]
      SizedBox(16)

      // Google Sign-In button (white, outlined, pill)
      OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          backgroundColor: Colors.white,
          minimumSize: Size(double.infinity, 52),
        ),
        onPressed: _signInWithGoogle,
        child: Row(mainAxisAlignment: center, children: [
          // Google "G" logo — draw as colored SVG or use a package
          SvgPicture.asset("assets/icons/google.svg", width: 20),
          SizedBox(12),
          Text("Continue with Google", style: subheading textPrimary),
        ]),
      )

      SizedBox(32)
      Row(mainAxisAlignment: center):
        Text("Don't have an account? ", style: body muted)
        TextButton("Sign up", onPressed: () => context.push('/register'), style: TextStyle(color: primary, fontWeight: 600))
```

---

## ADD / EDIT RECORD SCREEN

**File:** `lib/features/records/add_edit_record_screen.dart`

```
// Fields:
// Type selector: horizontal wrap of icon chips (🩺 Checkup · ✂️ Surgery · 🦷 Dental · 🧪 Lab · 💉 Vaccination · 📋 Other)
// Title: TextFormField
// Date: TextFormField (datePicker)
// Vet Name: TextFormField
// Clinic: TextFormField
// Diagnosis: TextFormField (multiline 2)
// Treatment: TextFormField (multiline 2)
// Notes: TextFormField (multiline 3)
// Cost: TextFormField(keyboardType: number, prefix: Text("\$"))
// Document upload:
//   if no doc: OutlinedButton(icon: attach_file, "Attach Document (PDF or image)")
//   if doc selected: pill chip with doc name + close X to remove
```

---

## ADD / EDIT VACCINE SCREEN

**File:** `lib/features/vaccines/add_edit_vaccine_screen.dart`

```
// Fields:
// Vaccine name: TextFormField (with common vaccine quick-fill chips: Rabies · DHPP · Bordetella · Leptospirosis · FVRCP)
// Date given: datePicker
// Next due date: datePicker (optional)
// Vet name: TextFormField
// Clinic: TextFormField
// Batch / lot number: TextFormField
// Notes: multiline
// Certificate upload: same as record document upload
```

---

## ADD / EDIT APPOINTMENT SCREEN

```
// Fields:
// Title: TextFormField
// Type chips: Checkup · Vaccination · Dental · Surgery · Grooming · Other
// Date + Time: combined picker (CupertinoDatePicker on iOS, DatePicker + TimePicker on Android)
// Vet name, Clinic name, Phone, Address: TextFormFields
// Notes: multiline
```

---

## DESIGN RULES CHECKLIST

Apply these rules to every screen without exception:

- [ ] Every heading uses `DMSerifDisplay` font
- [ ] Every body/label uses `PlusJakartaSans` font
- [ ] Cards use `borderRadius: 16`, buttons `14`, chips `100` (pill)
- [ ] Card shadow: `BoxShadow(blurRadius: 12, color: Colors.black.withOpacity(0.06), offset: Offset(0, 2))`
- [ ] Section headers: uppercase, 11px, `letterSpacing: 1.2`, `textMuted` color
- [ ] Loading states use `Shimmer`, never `CircularProgressIndicator`
- [ ] Empty states use `EmptyState` widget with icon + heading + subtext + optional CTA
- [ ] Status colors: successGreen `#4CAF82`, alertAmber `#E8A838`, alertRed `#D95F52`
- [ ] All colors via `Theme.of(context).colorScheme.*` — never hardcode hex in widgets
- [ ] Status badges are always pill-shaped with a colored dot prefix
- [ ] Pet avatars use `PetAvatar` widget with `CachedNetworkImage` + sage placeholder fallback
- [ ] Bottom sheets have a handle bar (40×4px rounded rect, grey300)
- [ ] Destructive actions (Sign Out, Delete) always have a confirmation step
- [ ] Forms use `GlobalKey<FormState>` with proper validators on all required fields
- [ ] Input decoration: `filled: true`, `fillColor: background`, `borderRadius: 14`
- [ ] Focused input border: 2px primary color
- [ ] All dates formatted with `intl` package: `DateFormat('MMM d, yyyy').format(date)`
- [ ] Age shown as: `"2 years, 3 months"` — compute from DOB using `Duration`
- [ ] Weight unit (kg/lbs) reads from `ref.watch(preferencesProvider).weightUnit`
- [ ] Every screen handles all 3 states: loading (shimmer), error (error card + retry), data

---

## FILE NAMING CONVENTION

```
lib/
  features/
    auth/
      login_screen.dart
      register_screen.dart
    dashboard/
      dashboard_screen.dart
      widgets/
        pet_switcher.dart
        vaccine_summary_widget.dart
        appointment_mini_card.dart
        quick_action_button.dart
    pets/
      pet_list_screen.dart
      pet_profile_screen.dart
      add_edit_pet_screen.dart
    records/
      records_list_screen.dart
      record_detail_screen.dart
      add_edit_record_screen.dart
    vaccines/
      vaccines_list_screen.dart
      add_edit_vaccine_screen.dart
    appointments/
      appointments_screen.dart
      add_edit_appointment_screen.dart
    medications/
      medications_screen.dart
      add_edit_medication_screen.dart
    weight/
      weight_screen.dart
    profile/
      profile_screen.dart
      theme_picker_screen.dart
    billing/
      pricing_screen.dart
  shared/
    widgets/
      paw_card.dart
      paw_button.dart
      status_badge.dart
      pet_avatar.dart
      section_header.dart
      empty_state.dart
      skeleton_loader.dart
      upgrade_modal.dart
```

---

## HOW TO USE THIS PROMPT

**Step 1 — Build shared widgets first:**
> "Build all shared widgets from the Design Shared Widgets section: PawCard, StatusBadge, PetAvatar, SectionHeader, EmptyState, SkeletonLoader, UpgradeModal."

**Step 2 — Build screens one by one:**
> "Build DashboardScreen. Assume all providers exist. Follow the design rules exactly."

**Step 3 — Request screen by name:**
> "Build PetProfileScreen with the hero photo, stats row, and tabbed sub-screens."

**Step 4 — Apply theme:**
> "The theme tokens come from Theme.of(context).colorScheme. Make sure no colors are hardcoded."

**Step 5 — Polish pass:**
> "Review all screens and ensure: DMSerifDisplay font on all headings, shimmer loading states, empty states on all lists, pill badges on all status fields."

---

*PawPass Flutter UI Implementation Prompt · April 2026*
*Backend: Supabase ✅ · Providers: Riverpod ✅ · Models: Freezed ✅ · UI: pending 🎨*
