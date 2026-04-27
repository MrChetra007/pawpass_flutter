import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router/app_router.dart';
import 'core/services/iap_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme_builder.dart';
import 'core/theme/app_theme_data.dart';
import 'data/repositories/appointment_repository.dart';
import 'data/repositories/vaccine_repository.dart';
import 'data/repositories/medication_repository.dart';
import 'data/repositories/pet_repository.dart';
import 'dart:async';

import 'shared/providers/auth_provider.dart';
import 'shared/providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();

  String supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  String supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception('SUPABASE_URL or SUPABASE_ANON_KEY not found');
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  initGoogleSignIn();

  await IAPService().initialize();
  await NotificationService().initialize();

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const PawPassApp(),
    ),
  );
}

Future<void> rescheduleAllReminders(WidgetRef ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return;

  try {
    final appointments = await AppointmentRepository(
      Supabase.instance.client,
    ).getUpcomingAppointments();
    final vaccines = await VaccineRepository(
      Supabase.instance.client,
    ).getVaccines();
    final medications = await MedicationRepository(
      Supabase.instance.client,
    ).getMedications(activeOnly: true);
    final pets = await PetRepository(Supabase.instance.client).getPets();

    final petMap = {for (final p in pets) p.id: p.name};

    final aptData = appointments
        .where((a) => a.datetime.isAfter(DateTime.now()))
        .map(
          (a) => {
            'id': a.id,
            'petName': petMap[a.petId] ?? 'Your pet',
            'title': a.title,
            'datetime': a.datetime,
          },
        )
        .toList();

    final vacData = vaccines
        .where(
          (v) =>
              v.nextDueDate != null && v.nextDueDate!.isAfter(DateTime.now()),
        )
        .map(
          (v) => {
            'id': v.id,
            'petName': petMap[v.petId] ?? 'Your pet',
            'name': v.name,
            'dueDate': v.nextDueDate,
          },
        )
        .toList();

    final medData = medications
        .where((m) => m.timeOfDay.isNotEmpty)
        .map(
          (m) => {
            'id': m.id,
            'petName': petMap[m.petId] ?? 'Your pet',
            'name': m.name,
            'dosage': m.dosage,
            'timeOfDay': m.timeOfDay,
            'frequency': m.frequency,
            'startDate': m.startDate,
            'endDate': m.endDate,
          },
        )
        .toList();

    await NotificationService().scheduleAllReminders(
      appointments: aptData,
      vaccines: vacData,
      medications: medData,
    );
  } catch (e) {
    debugPrint('Failed to reschedule reminders: $e');
  }
}

class PawPassApp extends ConsumerStatefulWidget {
  const PawPassApp({super.key});

  @override
  ConsumerState<PawPassApp> createState() => _PawPassAppState();
}

class _PawPassAppState extends ConsumerState<PawPassApp> {
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(routerProvider).go('/reset-password');
        });
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeKey = ref.watch(themeNotifierProvider);
    final themeData = PawThemeData.all[themeKey]!;
    final router = ref.watch(routerProvider);

    return AnimatedTheme(
      data: AppThemeBuilder.build(themeData),
      duration: const Duration(milliseconds: 300),
      child: MaterialApp.router(
        title: 'PawPass',
        debugShowCheckedModeBanner: false,
        theme: AppThemeBuilder.build(themeData),
        routerConfig: router,
      ),
    );
  }
}
