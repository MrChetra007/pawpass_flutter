import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
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
  final _nameController = TextEditingController();
  final _petNameController = TextEditingController();
  final _breedController = TextEditingController();
  final _microchipController = TextEditingController();
  final _notesController = TextEditingController();
  final _weightController = TextEditingController();

  String _selectedSpecies = 'Dog';
  String? _selectedGender;
  DateTime? _dob;
  bool _neutered = false;
  bool _isLoading = false;
  String? _photoPath;
  String? _petPhotoPath;

  final List<String> _species = ['Dog', 'Cat', 'Rabbit', 'Bird', 'Other'];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _petNameController.dispose();
    _breedController.dispose();
    _microchipController.dispose();
    _notesController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _pickImage(bool isPet) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (isPet) {
          _petPhotoPath = image.path;
        } else {
          _photoPath = image.path;
        }
      });
    }
  }

  Future<void> _requestNotificationPermission() async {
    final plugin = FlutterLocalNotificationsPlugin();
    final android = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }

  Future<String?> _uploadImage(String path, String bucket, String folder) async {
    final file = File(path);
    final fileName = '$folder/${DateTime.now().millisecondsSinceEpoch}';
    
    await Supabase.instance.client.storage
        .from(bucket)
        .upload(fileName, file);
    
    final url = Supabase.instance.client.storage
        .from(bucket)
        .getPublicUrl(fileName);
    return url;
  }

  Future<void> _saveOnboarding() async {
    if (_currentPage == 0 && _formKey.currentState?.validate() != true) {
      return;
    }
    if (_currentPage == 1 && !_validatePetForm()) {
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

      String? avatarUrl;
      if (_photoPath != null) {
        avatarUrl = await _uploadImage(_photoPath!, 'avatars', user.id);
      }

      await supabase.from('users').update({
        'full_name': _nameController.text.trim(),
        'avatar_url': avatarUrl,
        'is_onboarding': false,
      }).eq('id', user.id);

      if (_petNameController.text.isNotEmpty) {
        String? petPhotoUrl;
        if (_petPhotoPath != null) {
          petPhotoUrl = await _uploadImage(_petPhotoPath!, 'pet-photos', user.id);
        }

        await supabase.from('pets').insert({
          'user_id': user.id,
          'name': _petNameController.text.trim(),
          'species': _selectedSpecies,
          'breed': _breedController.text.trim().isEmpty ? null : _breedController.text.trim(),
          'gender': _selectedGender,
          'dob': _dob?.toIso8601String(),
          'weight_kg': _weightController.text.isEmpty ? null : double.tryParse(_weightController.text),
          'microchip': _microchipController.text.trim().isEmpty ? null : _microchipController.text.trim(),
          'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          'neutered': _neutered,
          'photo_url': petPhotoUrl,
        });
      }

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

  bool _validatePetForm() {
    if (_petNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your pet\'s name')),
      );
      return false;
    }
    return true;
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
                children: List.generate(3, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
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
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildProfilePage(theme),
                  _buildPetPage(theme),
                  _buildNotificationPage(theme),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousPage,
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 16),
                  Expanded(
                    flex: _currentPage == 0 ? 1 : 1,
                    child: FilledButton(
                      onPressed: _isLoading ? null : () {
                        if (_currentPage == 2) {
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
                          : Text(_currentPage == 2 ? 'Get Started' : 'Continue'),
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

  Widget _buildProfilePage(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to PawPass!',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Let\'s set up your profile',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: GestureDetector(
                onTap: () => _pickImage(false),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                      backgroundImage: _photoPath != null
                          ? FileImage(File(_photoPath!))
                          : null,
                      child: _photoPath == null
                          ? Icon(
                              Icons.person,
                              size: 50,
                              color: theme.colorScheme.primary,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: theme.colorScheme.primary,
                        child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Your Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetPage(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Your First Pet',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Skip this step if you don\'t have a pet yet',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: GestureDetector(
              onTap: () => _pickImage(true),
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    backgroundImage: _petPhotoPath != null
                        ? FileImage(File(_petPhotoPath!))
                        : null,
                    child: _petPhotoPath == null
                        ? Icon(
                            Icons.pets,
                            size: 50,
                            color: theme.colorScheme.primary,
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: theme.colorScheme.primary,
                      child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
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
          ),
          const SizedBox(height: 16),
          Text(
            'Species',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _species.map((species) {
              final isSelected = _selectedSpecies == species;
              return ChoiceChip(
                label: Text(species),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedSpecies = species);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _breedController,
            decoration: const InputDecoration(
              labelText: 'Breed (Optional)',
              prefixIcon: Icon(Icons.category_outlined),
            ),
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
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
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
                labelText: 'Date of Birth (Optional)',
                prefixIcon: Icon(Icons.cake_outlined),
              ),
              child: Text(
                _dob != null
                    ? '${_dob!.day}/${_dob!.month}/${_dob!.year}'
                    : 'Select date',
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _weightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Weight (kg) (Optional)',
              prefixIcon: Icon(Icons.monitor_weight_outlined),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Neutered'),
            value: _neutered,
            onChanged: (value) => setState(() => _neutered = value),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationPage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_active,
              size: 64,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Enable Notifications',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Get notified about upcoming vaccinations, appointments, and medication reminders.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                await _requestNotificationPermission();
              },
              icon: const Icon(Icons.notifications),
              label: const Text('Enable Notifications'),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _saveOnboarding,
            child: const Text('Maybe Later'),
          ),
        ],
      ),
    );
  }
}
