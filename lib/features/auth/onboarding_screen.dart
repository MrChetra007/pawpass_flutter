import 'dart:io' show File, InternetAddress;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final _formKey = GlobalKey<FormState>();
  final _petNameController = TextEditingController();

  String _selectedSpecies = 'Dog';
  String? _selectedGender;
  DateTime? _dob;
  bool _isLoading = false;
  String? _petPhotoPath;

  bool _enableNotifications = false;
  bool _addVaccine = true;
  bool _addMedication = false;
  bool _addAppointment = false;

  final List<Map<String, dynamic>> _speciesOptions = [
    {'label': 'Dog', 'emoji': '🐕', 'animation': 'assets/animations/Happy Dog.json'},
    {'label': 'Cat', 'emoji': '🐱', 'animation': 'assets/animations/Happy Cat.json'},
    {'label': 'Rabbit', 'emoji': '🐰', 'animation': 'assets/animations/Goldfish.json'},
    {'label': 'Bird', 'emoji': '🐦', 'animation': 'assets/animations/Cat Playing.json'},
    {'label': 'Other', 'emoji': '🐾', 'animation': 'assets/animations/Cute Dog.json'},
  ];

  final List<String> _stepAnimations = [
    'assets/animations/Happy Dog.json',
    'assets/animations/Tablet Management.json',
    'assets/animations/Cute Doggie.json',
    'assets/animations/Hand with syringe monkeypox vaccine.json',
    'assets/animations/Prescription docAppoint.json',
    'assets/animations/Celebrations Begin.json',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _petNameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 5) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _petPhotoPath = image.path);
    }
  }

  Future<void> _requestNotificationPermission() async {
    final plugin = FlutterLocalNotificationsPlugin();
    final android = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }

  Future<bool> _checkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> _showNoConnectionDialog() async {
    setState(() => _isLoading = false);
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 150,
                child: Lottie.asset(
                  'assets/animations/no connection to internet.json',
                  repeat: true,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No Internet Connection',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please check your connection and try again',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    if (await _checkConnection()) {
                      _saveOnboarding();
                    } else {
                      _showNoConnectionDialog();
                    }
                  },
                  child: const Text('Retry'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _uploadImage(String path, String bucket, String folder) async {
    final file = File(path);
    final fileName = '$folder/${DateTime.now().millisecondsSinceEpoch}';
    await Supabase.instance.client.storage.from(bucket).upload(fileName, file);
    return Supabase.instance.client.storage.from(bucket).getPublicUrl(fileName);
  }

  String _getAnimationForStep(int step) {
    if (step >= 0 && step < _stepAnimations.length) {
      return _stepAnimations[step];
    }
    return _stepAnimations[0];
  }

  String _getAnimationForSpecies() {
    final option = _speciesOptions.firstWhere(
      (s) => s['label'] == _selectedSpecies,
      orElse: () => _speciesOptions.last,
    );
    return option['animation'] as String;
  }

  Future<void> _saveOnboarding() async {
    if (_petNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your pet\'s name')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        if (mounted) context.go('/login');
        return;
      }

      if (_enableNotifications) {
        await _requestNotificationPermission();
      }

      if (!await _checkConnection()) {
        await _showNoConnectionDialog();
        return;
      }

      String? petPhotoUrl;
      if (_petPhotoPath != null) {
        petPhotoUrl = await _uploadImage(_petPhotoPath!, 'pet-photos', user.id);
      }

      final petId = await supabase.from('pets').insert({
        'user_id': user.id,
        'name': _petNameController.text.trim(),
        'species': _selectedSpecies,
        'gender': _selectedGender,
        'dob': _dob?.toIso8601String(),
        'photo_url': petPhotoUrl,
      }).select('id').single();

      if (_addVaccine) {
        await supabase.from('vaccines').insert({
          'pet_id': petId['id'],
          'name': '${_selectedSpecies == 'Dog' ? 'DHPP' : 'FVRCP'}',
          'due_date': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
          'status': 'scheduled',
        });
      }

      if (_addMedication) {
        await supabase.from('medications').insert({
          'pet_id': petId['id'],
          'name': 'Flea Prevention',
          'dosage': 'Monthly',
          'frequency': 'monthly',
          'is_active': true,
        });
      }

      if (_addAppointment) {
        await supabase.from('appointments').insert({
          'pet_id': petId['id'],
          'title': 'First Vet Checkup',
          'date': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
          'type': 'checkup',
        });
      }

      await supabase.from('users').update({
        'is_onboarding': false,
      }).eq('id', user.id);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_complete', true);

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: List.generate(6, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: index <= _currentPage
                            ? theme.colorScheme.primary
                            : theme.colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildWelcomePage(theme),
                  _buildPetTypePage(theme),
                  _buildPetInfoPage(theme),
                  _buildAhaMomentPage(theme),
                  _buildSuggestionsPage(theme),
                  _buildDonePage(theme),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_currentPage > 0 && _currentPage < 5)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousPage,
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentPage > 0 && _currentPage < 5) const SizedBox(width: 16),
                  Expanded(
                    flex: _currentPage == 0 || _currentPage == 5 ? 2 : 1,
                    child: FilledButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              if (_currentPage == 5) {
                                _saveOnboarding();
                              } else {
                                _nextPage();
                              }
                            },
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _currentPage == 0
                                  ? 'Get Started'
                                  : _currentPage == 5
                                      ? 'Go to Home'
                                      : 'Continue',
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimation(String animationPath, {double height = 200}) {
    return SizedBox(
      height: height,
      child: Lottie.asset(
        animationPath,
        repeat: true,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildWelcomePage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildAnimation(_getAnimationForStep(0)),
          const SizedBox(height: 32),
          Text(
            'Welcome to PawPass!',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Your pet\'s health companion\nall in one place',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPetTypePage(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnimation(_getAnimationForStep(1), height: 120),
          const SizedBox(height: 24),
          Text(
            'What type of pet\ndo you have?',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select your pet type to get started',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
            ),
            itemCount: _speciesOptions.length,
            itemBuilder: (context, index) {
              final option = _speciesOptions[index];
              final isSelected = _selectedSpecies == option['label'];
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedSpecies = option['label'];
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary.withValues(alpha: 0.1)
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        option['emoji'],
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        option['label'],
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPetInfoPage(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnimation(_getAnimationForSpecies(), height: 120),
            const SizedBox(height: 16),
            Text(
              'Tell us about\n${_selectedSpecies == 'Dog' ? 'your dog' : _selectedSpecies == 'Cat' ? 'your cat' : 'your pet'}',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You can add more details later',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                      backgroundImage: _petPhotoPath != null
                          ? FileImage(File(_petPhotoPath!))
                          : null,
                      child: _petPhotoPath == null
                          ? Icon(
                              Icons.pets,
                              size: 40,
                              color: theme.colorScheme.primary,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: theme.colorScheme.primary,
                        child: const Icon(
                          Icons.camera_alt,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _petNameController,
              decoration: const InputDecoration(
                labelText: 'Pet Name',
                prefixIcon: Icon(Icons.pets),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your pet\'s name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedGender,
                    decoration: const InputDecoration(
                      labelText: 'Gender',
                      prefixIcon: Icon(Icons.wc_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('Male')),
                      DropdownMenuItem(value: 'female', child: Text('Female')),
                      DropdownMenuItem(value: 'unknown', child: Text('Unknown')),
                    ],
                    onChanged: (value) => setState(() => _selectedGender = value),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dob ?? DateTime.now().subtract(const Duration(days: 365)),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _dob = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Birthday',
                        prefixIcon: Icon(Icons.cake_outlined),
                      ),
                      child: Text(
                        _dob != null
                            ? '${_dob!.day}/${_dob!.month}/${_dob!.year}'
                            : 'Select',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAhaMomentPage(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildAnimation(_getAnimationForStep(3), height: 120),
          const SizedBox(height: 16),
          Text(
            'See What PawPass\nCan Do!',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildFeaturePreview(theme, icon: Icons.vaccines, title: 'Track Vaccines', subtitle: 'Never miss a shot'),
          _buildFeaturePreview(theme, icon: Icons.medication, title: 'Medication Reminders', subtitle: 'Daily schedule made easy'),
          _buildFeaturePreview(theme, icon: Icons.calendar_today, title: 'Book Appointments', subtitle: 'Never forget a vet visit'),
          _buildFeaturePreview(theme, icon: Icons.description, title: 'Health Records', subtitle: 'All in one place'),
        ],
      ),
    );
  }

  Widget _buildFeaturePreview(ThemeData theme, {required IconData icon, required String title, required String subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsPage(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnimation(_getAnimationForStep(4), height: 120),
          const SizedBox(height: 16),
          Text(
            'Let\'s get started\nright away!',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pick what you want to track',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          _buildSuggestionToggle(theme, icon: Icons.vaccines, title: 'Vaccinations', subtitle: 'Schedule ${_selectedSpecies == 'Dog' ? 'DHPP' : 'FVRCP'}', value: _addVaccine, onChanged: (v) => setState(() => _addVaccine = v)),
          _buildSuggestionToggle(theme, icon: Icons.medication, title: 'Medications', subtitle: 'Flea & worm prevention', value: _addMedication, onChanged: (v) => setState(() => _addMedication = v)),
          _buildSuggestionToggle(theme, icon: Icons.calendar_today, title: 'First Checkup', subtitle: 'Book a vet appointment', value: _addAppointment, onChanged: (v) => setState(() => _addAppointment = v)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.notifications_active, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Enable Notifications', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      Text('Get reminders for vaccines, meds & appointments', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                Switch(value: _enableNotifications, onChanged: (v) => setState(() => _enableNotifications = v)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionToggle(ThemeData theme, {required IconData icon, required String title, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }

  Widget _buildDonePage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildAnimation(_getAnimationForStep(5)),
          const SizedBox(height: 32),
          Text(
            'All Set! 🎉',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            _petNameController.text.isNotEmpty
                ? '${_petNameController.text} is ready to be tracked!'
                : 'Your pet is ready to be tracked!',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lightbulb, color: theme.colorScheme.onPrimaryContainer),
                const SizedBox(width: 8),
                Text(
                  'Pro tip: Add more pets anytime',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}