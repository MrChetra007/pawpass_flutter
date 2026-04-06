import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import '../../core/constants/supabase_constants.dart';
import '../../core/utils/validators.dart';
import '../../data/models/pet_model.dart';
import '../../shared/providers/pet_provider.dart';

class AddEditPetScreen extends ConsumerStatefulWidget {
  final Pet? pet;

  const AddEditPetScreen({super.key, this.pet});

  @override
  ConsumerState<AddEditPetScreen> createState() => _AddEditPetScreenState();
}

class _AddEditPetScreenState extends ConsumerState<AddEditPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _colorController = TextEditingController();
  final _microchipController = TextEditingController();
  final _notesController = TextEditingController();
  final _weightController = TextEditingController();

  String _selectedSpecies = 'Dog';
  String? _selectedGender;
  DateTime? _dob;
  bool _neutered = false;
  bool _isLoading = false;
  bool _isUploadingPhoto = false;

  /// Public URL of the existing saved photo (loaded from DB when editing)
  String? _existingPhotoUrl;

  /// Newly picked image bytes — used for instant local preview before upload
  Uint8List? _pickedImageBytes;

  /// The XFile from image_picker, kept for upload
  XFile? _pickedImage;

  bool get isEditing => widget.pet != null;

  @override
  void initState() {
    super.initState();
    if (widget.pet != null) {
      _nameController.text = widget.pet!.name;
      _selectedSpecies = widget.pet!.species;
      _breedController.text = widget.pet!.breed ?? '';
      _selectedGender = widget.pet!.gender;
      _dob = widget.pet!.dob;
      _weightController.text = widget.pet!.weightKg?.toString() ?? '';
      _colorController.text = widget.pet!.color ?? '';
      _microchipController.text = widget.pet!.microchip ?? '';
      _neutered = widget.pet!.neutered;
      _notesController.text = widget.pet!.notes ?? '';
      _existingPhotoUrl = widget.pet!.photoUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _colorController.dispose();
    _microchipController.dispose();
    _notesController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image == null) return;

      // readAsBytes() works with content:// URIs on Android,
      // file:// on iOS, and blobs on web — no File() needed
      final bytes = await image.readAsBytes();

      if (bytes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not read image. Try another.')),
          );
        }
        return;
      }

      setState(() {
        _pickedImage = image;
        _pickedImageBytes = bytes;
      });
    } catch (e) {
      debugPrint('Image pick error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime.now().subtract(const Duration(days: 365)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  /// Uploads image bytes to Supabase Storage (public bucket)
  /// and returns the public URL.
  Future<String?> _uploadPickedImage() async {
    if (_pickedImage == null || _pickedImageBytes == null) return null;

    setState(() => _isUploadingPhoto = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return null;

      final storagePath =
          '${user.id}/pets/${DateTime.now().millisecondsSinceEpoch}.jpg';

      await supabase.storage
          .from('pet-photos')
          .uploadBinary(
            storagePath,
            _pickedImageBytes!,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      // getPublicUrl works because the bucket is set to public
      return supabase.storage.from('pet-photos').getPublicUrl(storagePath);
    } catch (e) {
      debugPrint('Photo upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to upload photo: $e')));
      }
      return null;
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final weight = _weightController.text.isNotEmpty
          ? double.tryParse(_weightController.text)
          : null;

      // Upload new image if one was picked, otherwise keep the existing URL
      String? finalPhotoUrl = _existingPhotoUrl;
      if (_pickedImage != null) {
        finalPhotoUrl = await _uploadPickedImage();
      }

      if (isEditing) {
        final updateData = <String, dynamic>{
          'name': _nameController.text.trim(),
          'species': _selectedSpecies,
          'breed': _breedController.text.trim().isNotEmpty
              ? _breedController.text.trim()
              : null,
          'gender': _selectedGender,
          'dob': _dob?.toIso8601String().split('T').first,
          'weight_kg': weight,
          'color': _colorController.text.trim().isNotEmpty
              ? _colorController.text.trim()
              : null,
          'microchip': _microchipController.text.trim().isNotEmpty
              ? _microchipController.text.trim()
              : null,
          'neutered': _neutered,
          'notes': _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
          if (finalPhotoUrl != null) 'photo_url': finalPhotoUrl,
        };

        await ref
            .read(petNotifierProvider.notifier)
            .updatePet(widget.pet!.id, updateData);
      } else {
        await ref
            .read(petNotifierProvider.notifier)
            .createPet(
              name: _nameController.text.trim(),
              species: _selectedSpecies,
              breed: _breedController.text.trim().isNotEmpty
                  ? _breedController.text.trim()
                  : null,
              gender: _selectedGender,
              dob: _dob,
              weightKg: weight,
              color: _colorController.text.trim().isNotEmpty
                  ? _colorController.text.trim()
                  : null,
              microchip: _microchipController.text.trim().isNotEmpty
                  ? _microchipController.text.trim()
                  : null,
              neutered: _neutered,
              notes: _notesController.text.trim().isNotEmpty
                  ? _notesController.text.trim()
                  : null,
              photoUrl: finalPhotoUrl,
            );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Image display priority:
  /// 1. Freshly picked → Image.memory (bytes, no URI/path issues at all)
  /// 2. Existing saved → Image.network (public URL from Supabase)
  /// 3. Nothing → placeholder paw icon
  Widget _buildAvatarContent(ThemeData theme) {
    // Newly picked image — show bytes directly, always works
    if (_pickedImageBytes != null) {
      return ClipOval(
        child: Image.memory(
          _pickedImageBytes!,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (_, error, __) {
            debugPrint('Image.memory error: $error');
            return _placeholderIcon(theme);
          },
        ),
      );
    }

    // Existing saved photo — public URL
    if (_existingPhotoUrl != null && _existingPhotoUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          _existingPhotoUrl!,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          },
          errorBuilder: (_, error, __) {
            debugPrint('Image.network error: $error');
            return _placeholderIcon(theme);
          },
        ),
      );
    }

    return _placeholderIcon(theme);
  }

  Widget _placeholderIcon(ThemeData theme) =>
      Icon(Icons.pets, size: 48, color: theme.colorScheme.primary);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Pet' : 'Add Pet'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Photo picker ──────────────────────────────────────────
            Center(
              child: GestureDetector(
                onTap: _isUploadingPhoto ? null : _pickImage,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withValues(
                          alpha: 0.3,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: _buildAvatarContent(theme),
                    ),
                    if (_isUploadingPhoto) const CircularProgressIndicator(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _isUploadingPhoto ? null : _pickImage,
                child: Text(
                  (_pickedImageBytes != null || _existingPhotoUrl != null)
                      ? 'Change Photo'
                      : 'Add Photo',
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Name ──────────────────────────────────────────────────
            TextFormField(
              controller: _nameController,
              validator: Validators.petName,
              decoration: const InputDecoration(
                labelText: 'Name *',
                prefixIcon: Icon(Icons.pets),
              ),
            ),
            const SizedBox(height: 24),

            // ── Species ───────────────────────────────────────────────
            Text('Species *', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: SupabaseConstants.petSpecies.map((species) {
                final isSelected = _selectedSpecies == species;
                final emoji = _getSpeciesEmoji(species);
                return ChoiceChip(
                  label: Text('$emoji $species'),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedSpecies = species),
                );
              }).toList(),
            ),
            if (_selectedSpecies == 'Other') ...[
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Specify Species',
                  prefixIcon: Icon(Icons.pets),
                  hintText: 'e.g., Hamster, Guinea Pig, etc.',
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    setState(() => _selectedSpecies = value);
                  }
                },
              ),
            ],
            const SizedBox(height: 24),

            // ── Breed ─────────────────────────────────────────────────
            TextFormField(
              controller: _breedController,
              decoration: const InputDecoration(
                labelText: 'Breed',
                prefixIcon: Icon(Icons.category),
              ),
            ),
            const SizedBox(height: 16),

            // ── Gender ────────────────────────────────────────────────
            Text('Gender', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Male'),
                    selected: _selectedGender == 'male',
                    onSelected: (_) => setState(() => _selectedGender = 'male'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Female'),
                    selected: _selectedGender == 'female',
                    onSelected: (_) =>
                        setState(() => _selectedGender = 'female'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Unknown'),
                    selected: _selectedGender == 'unknown',
                    onSelected: (_) =>
                        setState(() => _selectedGender = 'unknown'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Date of Birth ─────────────────────────────────────────
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.cake),
              title: const Text('Date of Birth'),
              subtitle: Text(
                _dob != null
                    ? '${_dob!.day}/${_dob!.month}/${_dob!.year}'
                    : 'Not set',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _selectDate,
            ),
            const Divider(),
            const SizedBox(height: 16),

            // ── Weight / Color / Microchip ────────────────────────────
            TextFormField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              validator: Validators.weight,
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                prefixIcon: Icon(Icons.monitor_weight),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _colorController,
              decoration: const InputDecoration(
                labelText: 'Color',
                prefixIcon: Icon(Icons.palette),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _microchipController,
              decoration: const InputDecoration(
                labelText: 'Microchip ID',
                prefixIcon: Icon(Icons.qr_code),
              ),
            ),
            const SizedBox(height: 24),

            // ── Neutered / Notes ──────────────────────────────────────
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Neutered/Spayed'),
              value: _neutered,
              onChanged: (v) => setState(() => _neutered = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes',
                prefixIcon: Icon(Icons.notes),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _getSpeciesEmoji(String species) {
    switch (species.toLowerCase()) {
      case 'dog':
        return '🐶';
      case 'cat':
        return '🐱';
      case 'rabbit':
        return '🐰';
      case 'bird':
        return '🐦';
      case 'fish':
        return '🐟';
      case 'hamster':
        return '🐹';
      default:
        return '🐾';
    }
  }
}
