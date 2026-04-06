# PawPass — UI Design Preview Prompt

> Paste this entire prompt into Claude, v0, Bolt, Cursor, or any AI code generator to get a full visual design preview of the PawPass app with dummy data and dummy assets.

---

## OVERVIEW

Build a **pixel-perfect, interactive HTML/React UI design preview** of **PawPass** — a Digital Pet Passport mobile app. Use **dummy data** and **placeholder assets** throughout. This is a design preview only — no backend, no auth, no real data. The goal is to see how the app looks and feels.

---

## DESIGN SYSTEM

### Aesthetic: Warm Organic Minimalism
Clean, airy, trustworthy. Like a modern vet clinic that's actually welcoming.

### Active Theme: 🌿 Forest (Default)
| Token | Hex |
|---|---|
| `primary` | `#3D7A5F` |
| `primaryLight` | `#A8C5B5` |
| `background` | `#FAF6F1` |
| `surface` | `#FFFFFF` |
| `textPrimary` | `#1E2D2B` |
| `textMuted` | `#8A9A96` |
| `alertAmber` | `#E8A838` |
| `alertRed` | `#D95F52` |
| `successGreen` | `#4CAF82` |

### Typography
| Role | Font | Weight | Size |
|---|---|---|---|
| Display / Hero | `DM Serif Display` | Regular | 32–40px |
| Heading | `DM Serif Display` | Regular | 22–28px |
| Subheading | `Plus Jakarta Sans` | 600 | 16–18px |
| Body | `Plus Jakarta Sans` | 400 | 14–15px |
| Caption / Label | `Plus Jakarta Sans` | 500 | 11–12px |

Load both Google Fonts via CDN:
```
https://fonts.googleapis.com/css2?family=DM+Serif+Display&family=Plus+Jakarta+Sans:wght@400;500;600;700&display=swap
```

### Component Rules
- **Border radius:** Cards = `16px`, Buttons = `14px`, Chips/Badges = `100px` (pill)
- **Shadow:** `box-shadow: 0 2px 12px rgba(0,0,0,0.06)`
- **Spacing scale:** 4 / 8 / 12 / 16 / 20 / 24 / 32 / 48px
- **Status badges:** Pill shape, colored background + matching text + colored dot
- **Pet avatars:** Circular, with a warm `#A8C5B5` placeholder + 🐾 paw emoji inside
- **Section headers:** Plus Jakarta Sans 500 11px, `#8A9A96`, ALL CAPS, letter-spacing 0.08em
- **Buttons (primary):** `#3D7A5F` background, white text, 14px radius, 48px height
- **Buttons (secondary):** `#A8C5B5` background, `#1E2D2B` text
- **Quick action buttons:** `#A8C5B5` fill, `#3D7A5F` icon + text

---

## SCREENS TO BUILD

Render all screens as a **horizontally scrollable row of mobile frames** (375×812px iPhone viewport each). Label each frame below.

---

### Screen 1 — Dashboard (Home Tab)

**App Bar:**
- Left: pet avatar (60px circle, `#A8C5B5` bg + 🐾) + pet name "Milo" in DM Serif Display 18px + small dropdown chevron
- Right: bell icon (notification)
- Background: `#FAF6F1`

**Body (scrollable):**

**Section: "Good morning, Sarah 🌿"** — DM Serif Display 28px

**Active Pet Card** (full-width, surface white, radius 16, shadow):
- Left: 80px circle avatar (warm sage placeholder + 🐾)
- Pet name: "Milo" — DM Serif 22px
- Species chip: "🐶 Dog · Labrador"
- Age: "3 years, 2 months"
- Weight: "28.5 kg"
- Neutered badge: "✂️ Neutered" pill in successGreen

**Vaccine Summary Row** (pill chips in a horizontal row):
- "✅ 4 up to date" — successGreen pill
- "🟡 1 due soon" — alertAmber pill

**Active Medications Widget** (surface card):
- Title: "Medications"
- "2 Active" badge in primaryLight
- List item: "Heartgard · Daily · Since Mar 2025"
- List item: "Bravecto · Monthly · Since Jan 2025"

**Upcoming Appointment Card** (surface card, left border in successGreen 4px):
- "Annual Checkup" — Plus Jakarta Sans 600 15px
- "Dr. Chen · Happy Paws Clinic"
- "Tomorrow · 10:30 AM"
- Calendar icon

**Quick Actions Row** (3 buttons, `#A8C5B5` bg):
- "➕ Record"
- "⚖️ Weight"
- "📅 Appt"

---

### Screen 2 — Pet List (Pets Tab)

**App Bar:** "My Pets" — DM Serif Display 22px + FAB "+" button in primary green

**Grid (2 columns):**

**Pet Card 1 — Milo:**
- 100px circle avatar placeholder (sage + 🐾)
- Name: "Milo" DM Serif 18px
- "🐶 Labrador · 3 yrs"
- Vaccine dot: 🟢

**Pet Card 2 — Luna:**
- 100px circle avatar placeholder (rose-tinted `#F5C6DA` + 🐾)
- Name: "Luna" DM Serif 18px
- "🐱 Persian · 5 yrs"
- Vaccine dot: 🟡

**Add Pet Card (dashed border):**
- "+ Add Pet" centered, muted text
- `#A8C5B5` dashed border

---

### Screen 3 — Pet Profile (Milo)

**Hero Section:**
- Full-width 200px tall warm sage gradient rectangle as photo placeholder
- Gradient overlay from transparent to `#1E2D2B`
- "Milo" in DM Serif Display 32px white over gradient
- "🐶 Labrador · Male" subtitle white

**Stats Row (4 cards):**
- "Age: 3 yrs 2 mo"
- "Weight: 28.5 kg"
- "Microchip: ✅"
- "Neutered: ✅"

**Tab Bar:** Records · Vaccines · Appointments · Meds · Weight

**Active Tab: Vaccines (shown):**

Vaccine Card 1:
- "Rabies" — Plus Jakarta Sans 600
- "Last: Jan 2024 · Next: Jan 2025"
- Status: 🔴 "Overdue" pill in alertRed

Vaccine Card 2:
- "DHPP" — Plus Jakarta Sans 600
- "Last: Mar 2025 · Next: Mar 2026"
- Status: 🟢 "Up to date" pill in successGreen

Vaccine Card 3:
- "Bordetella" — Plus Jakarta Sans 600
- "Last: Feb 2025 · Next: May 2025"
- Status: 🟡 "Due soon" pill in alertAmber

---

### Screen 4 — Health Records

**App Bar:** "Records" DM Serif Display + filter icon

**Filter Tabs (horizontal scroll):** All · Checkup · Surgery · Dental · Other

**Year Header:** "2025" — uppercase muted caption

**Record Card 1:**
- Left icon circle (`#A8C5B5` bg): 🩺
- "Annual Checkup" — 600 15px
- "Dr. Chen · Happy Paws Clinic"
- "Mar 15, 2025"
- "💊 Diagnosis: Healthy" muted caption
- Paperclip icon: "report.pdf"

**Record Card 2:**
- Left icon circle: 🦷
- "Dental Cleaning"
- "Dr. Park · Bright Smiles Vet"
- "Jan 8, 2025"
- Cost: "$280"

**Year Header:** "2024"

**Record Card 3:**
- Left icon circle: ✂️
- "Neuter Surgery"
- "Dr. Lee · City Animal Hospital"
- "Nov 3, 2024"

---

### Screen 5 — Appointments

**App Bar:** "Appointments" + "+" FAB

**Tab Bar:** Upcoming (active) · Past

**Appointment Card 1 (green left border 4px):**
- "Annual Checkup" 600 15px
- "Tomorrow · 10:30 AM"
- "Dr. Chen · Happy Paws Clinic"
- "🏥 Checkup" chip
- Swipe hint: "← Cancel   Complete →"

**Appointment Card 2 (green left border):**
- "Rabies Vaccination"
- "Apr 12, 2026 · 2:00 PM"
- "Dr. Park · Happy Paws Clinic"
- "💉 Vaccination" chip

**Appointment Card 3 (green left border):**
- "Dental Cleaning Follow-up"
- "May 3, 2026 · 11:00 AM"
- "Dr. Lee · Bright Smiles Vet"
- "🦷 Dental" chip

---

### Screen 6 — Medications

**App Bar:** "Medications"

**Section: ACTIVE (2)**

**Medication Card 1:**
- "Heartgard" — 600 15px
- "Dosage: 68mcg · Daily"
- "Since: Mar 1, 2025"
- "Prescribed by: Dr. Chen"
- Active toggle: ON (primary green)

**Medication Card 2:**
- "Bravecto"
- "Dosage: 500mg · Every 3 months"
- "Since: Jan 15, 2025"
- Active toggle: ON

**Section: INACTIVE (1)**

**Medication Card 3 (muted):**
- "Amoxicillin"
- "Dosage: 250mg · Twice daily"
- "Jan 1–14, 2025"
- Active toggle: OFF

---

### Screen 7 — Weight Log

**App Bar:** "Weight History · Milo" + "+" icon

**Line Chart (fl_chart style):**
- X axis: Sep · Oct · Nov · Dec · Jan · Feb · Mar
- Y axis: 26 · 27 · 28 · 29 kg
- Smooth line in `#3D7A5F`, filled area in `#A8C5B5` 20% opacity
- Data points: 26.5 · 27.0 · 27.8 · 28.0 · 28.3 · 28.4 · 28.5
- Latest point highlighted with a circle dot

**Latest: "28.5 kg" in DM Serif Display 32px primary green**
**"↑ 0.2 kg from last entry" in successGreen**

**Weight History List:**
- "Mar 15, 2026 — 28.5 kg — After checkup"
- "Feb 10, 2026 — 28.3 kg"
- "Jan 20, 2026 — 28.0 kg"
- "Dec 5, 2025 — 27.8 kg"

---

### Screen 8 — Profile

**App Bar:** "Profile"

**Account Section:**
- 80px circle avatar: `#A8C5B5` bg + 🐾 emoji
- "Sarah Johnson" — DM Serif 20px
- "sarah@example.com" — muted
- "🐾 Paw Plan" badge — `#A8C5B5` fill, `#3D7A5F` text, pill

**APP SETTINGS section header:**

ListTile rows:
- 🎨 App Theme → "🌿 Forest" trailing
- 🔔 Notifications → toggle ON
- ⚖️ Units → "kg" trailing

**SUBSCRIPTION section header:**

ListTile rows:
- 💎 Your Plan → "Paw Plan · Renews May 1" trailing
- 🔄 Restore Purchases
- 🛒 Manage Subscription

**SUPPORT section header:**

ListTile rows:
- ❓ Help & FAQ
- 🔒 Privacy Policy
- 📜 Terms of Service
- ⭐ Rate PawPass

**DANGER ZONE (extra top padding):**
- "Sign Out" — `#E8A838` text
- "Delete Account" — `#D95F52` text

---

### Screen 9 — Theme Picker

**App Bar:** "← Choose Theme"

**2-column grid of theme cards (radius 16, shadow):**

Each card contains:
- Large emoji top-left
- Theme name in DM Serif 18px
- Three color dot circles (primary, primaryLight, background)
- Active theme has `#3D7A5F` 2px border + ✅ check icon

Themes:
1. 🌿 Forest — dots: `#3D7A5F` · `#A8C5B5` · `#FAF6F1` — ACTIVE (green border)
2. 🌊 Ocean — dots: `#2B6CB0` · `#BEE3F8` · `#F0F7FF`
3. 🌸 Blossom — dots: `#B85C84` · `#F5C6DA` · `#FFF7F9`
4. 🍊 Amber — dots: `#C2680A` · `#FDDCAB` · `#FFFBF4`
5. 🌙 Midnight — dots: `#4CAF82` · `#1E4D38` · `#0F1612`
6. 🪻 Lavender — dots: `#6B5EA8` · `#D6CEFF` · `#F8F6FF`

---

### Screen 10 — Pricing / Upgrade

**Top:** 🐾 paw icon 64px in primary green, DM Serif Display "Unlock PawPass Premium" 28px centered

**Plan Cards (stacked vertically):**

**Paw Plan card (surface white):**
- "🐾 Paw Plan" header
- "$4.99 / month"
- Feature list with ✅ checkmarks:
  - ✅ Up to 3 pets
  - ✅ Unlimited health records
  - ✅ File & document uploads
  - ✅ Appointment reminders
  - ✅ Push notifications
  - ❌ PDF passport export
  - ❌ Family sharing
- "Start Paw Plan" outlined button

**Family Plan card (primary green 2px border + "Best Value" badge in primary):**
- "👨‍👩‍👧 Family Plan" header
- "$9.99 / month"
- "Best Value" pill badge in `#3D7A5F` top-right
- Feature list:
  - ✅ Unlimited pets
  - ✅ Everything in Paw
  - ✅ PDF passport export
  - ✅ Family sharing
- "Start Family Plan" filled primary button

---

### Screen 11 — Add Pet (Bottom Sheet)

Show this as a bottom sheet modal overlaid on the Pets screen (dark overlay behind, sheet slides up 75% of screen).

**Sheet content:**
- Handle bar at top
- "Add New Pet" — DM Serif 24px

**Form fields (styled inputs, radius 14, `#A8C5B5` border, `#FAF6F1` fill):**
- Pet Name: "Milo"
- Species chips: [🐶 Dog (selected)] [🐱 Cat] [🐰 Rabbit] [🐦 Bird] [✨ Other]
- Breed: "Labrador Retriever"
- Gender chips: [♂ Male (selected)] [♀ Female]
- Date of Birth: "Feb 14, 2023"
- Weight: "28.5 kg"
- Microchip: "985112003456789"
- Neutered toggle: ON

**Photo area:** Dashed circle 100px, "+ Add Photo" text centered

**Primary button:** "Save Pet" — full width, primary green

---

## BOTTOM NAVIGATION BAR

Show on all main screens. 5 tabs. Active tab uses `#3D7A5F` icon + label. Inactive: `#8A9A96`.

| Tab | Icon | Label |
|---|---|---|
| 1 | 🏠 | Home |
| 2 | 🐾 | Pets |
| 3 | 📋 | Records |
| 4 | 📅 | Appointments |
| 5 | 👤 | Profile |

Bar: white background, subtle top border, no elevation. Height 80px.

---

## DUMMY DATA REFERENCE

```
Logged-in user: Sarah Johnson (sarah@example.com) · Plan: Paw

Pets:
  1. Milo — Male Labrador, 3 yrs 2 mo, 28.5kg, Neutered, Microchip: 985112003456789
  2. Luna — Female Persian Cat, 5 yrs, 4.2kg, Spayed, No microchip

Vaccines (Milo):
  - Rabies: Given Jan 2024, Next Jan 2025 → OVERDUE 🔴
  - DHPP: Given Mar 2025, Next Mar 2026 → UP TO DATE 🟢
  - Bordetella: Given Feb 2025, Next May 2025 → DUE SOON 🟡
  - Leptospirosis: Given Apr 2025, Next Apr 2026 → UP TO DATE 🟢

Vaccines (Luna):
  - Rabies: Given Nov 2024, Next Nov 2025 → DUE SOON 🟡
  - FVRCP: Given Nov 2024, Next Nov 2025 → DUE SOON 🟡

Appointments (Milo):
  - Annual Checkup — Apr 5, 2026 10:30 AM — Dr. Chen · Happy Paws Clinic — Upcoming
  - Rabies Vaccination — Apr 12, 2026 2:00 PM — Dr. Park · Happy Paws Clinic — Upcoming
  - Dental Follow-up — May 3, 2026 11:00 AM — Dr. Lee · Bright Smiles Vet — Upcoming
  - Annual Checkup — Mar 15, 2025 — Dr. Chen — Completed (Past)

Health Records (Milo):
  - Annual Checkup — Mar 15, 2025 — Dr. Chen — Healthy, all good
  - Dental Cleaning — Jan 8, 2025 — Dr. Park — $280 — report.pdf attached
  - Neuter Surgery — Nov 3, 2024 — Dr. Lee — City Animal Hospital

Medications (Milo):
  - Heartgard 68mcg — Daily — Active since Mar 1, 2025 — Dr. Chen
  - Bravecto 500mg — Every 3 months — Active since Jan 15, 2025
  - Amoxicillin 250mg — Twice daily — Inactive (Jan 1–14, 2025 course)

Weight Log (Milo):
  - Mar 15 → 28.5 kg
  - Feb 10 → 28.3 kg
  - Jan 20 → 28.0 kg
  - Dec 5  → 27.8 kg
  - Nov 12 → 27.0 kg
  - Oct 8  → 26.5 kg
```

---

## ASSETS APPROACH (No real images needed)

Since this is a design preview, use these substitutes:

| Asset | Substitute |
|---|---|
| Pet photos | Circular divs with `#A8C5B5` or `#F5C6DA` bg + 🐾 emoji centered |
| User avatar | Circle with initials "SJ" on `#A8C5B5` bg |
| Hero photo area | Tall rectangle with sage gradient + pet name overlay |
| App icon | 🐾 emoji in a rounded square, primary green bg |
| Empty state illustration | Simple centered emoji (🐾 or 📋) + heading + subtext |
| PDF attachment | 📎 paperclip icon + "report.pdf" pill chip |
| Lottie animations | Static placeholder cards with muted text "Animation area" |

---

## IMPLEMENTATION NOTES

- Render all 11 screens side-by-side in a horizontal scroll container
- Each screen: 375px wide × 812px tall iPhone frame (white bg + rounded corners + shadow)
- Label each frame below with its screen name
- Use real Google Fonts (DM Serif Display + Plus Jakarta Sans) via CDN link in `<head>`
- Bottom nav bar is fixed to the bottom of each frame
- Status bar at top: show "9:41" time + signal/battery icons in dark
- Make the Theme Picker screen feel live — clicking a theme card could swap the color on that card's border
- The line chart on the Weight screen should be drawn with pure SVG or canvas (no library needed, just bezier curves)
- Add subtle hover states on all tappable elements
- The Pricing screen Upgrade Modal should show as Screen 10 with a dark overlay behind it

---

*Generated from the PawPass Flutter Roadmap · April 2026*