import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/supabase_constants.dart';
import '../../shared/providers/medication_provider.dart';

class AddEditMedicationScreen extends ConsumerStatefulWidget {
  final String petId;
  final dynamic medication;

  const AddEditMedicationScreen({
    super.key,
    required this.petId,
    this.medication,
  });

  @override
  ConsumerState<AddEditMedicationScreen> createState() => _AddEditMedicationScreenState();
}

class _AddEditMedicationScreenState extends ConsumerState<AddEditMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _prescribedByController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedFrequency;
  String? _selectedMealTiming;
  String? _selectedFrequencyType;
  int _frequencyTimes = 1;
  final Set<String> _selectedTimesOfDay = {};
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isActive = true;
  bool _isLoading = false;

  bool get isEditing => widget.medication != null;

  @override
  void initState() {
    super.initState();
    if (widget.medication != null) {
      _nameController.text = widget.medication.name;
      _dosageController.text = widget.medication.dosage ?? '';
      _selectedFrequency = widget.medication.frequency;
      _selectedMealTiming = widget.medication.mealTiming;
      _selectedFrequencyType = widget.medication.frequencyType;
      _frequencyTimes = widget.medication.frequencyTimes ?? 1;
      _selectedTimesOfDay.addAll(widget.medication.timeOfDay);
      _startDate = widget.medication.startDate;
      _endDate = widget.medication.endDate;
      _prescribedByController.text = widget.medication.prescribedBy ?? '';
      _notesController.text = widget.medication.notes ?? '';
      _isActive = widget.medication.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _prescribedByController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFrequencyType != null && _selectedTimesOfDay.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one time of day')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'name': _nameController.text.trim(),
        'dosage': _dosageController.text.trim().isNotEmpty
            ? _dosageController.text.trim()
            : null,
        'frequency': _selectedFrequency,
        'meal_timing': _selectedMealTiming,
        'frequency_type': _selectedFrequencyType,
        'frequency_times': _frequencyTimes,
        'time_of_day': _selectedTimesOfDay.toList(),
        'start_date': _startDate?.toIso8601String().split('T').first,
        'end_date': _endDate?.toIso8601String().split('T').first,
        'prescribed_by': _prescribedByController.text.trim().isNotEmpty
            ? _prescribedByController.text.trim()
            : null,
        'notes': _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      };

      if (isEditing) {
        data['is_active'] = _isActive;
        await ref.read(medicationNotifierProvider.notifier).updateMedication(
              widget.medication.id,
              data,
            );
      } else {
        await ref.read(medicationNotifierProvider.notifier).createMedication(
              petId: widget.petId,
              name: _nameController.text.trim(),
              dosage: _dosageController.text.trim().isNotEmpty
                  ? _dosageController.text.trim()
                  : null,
              frequency: _selectedFrequency,
              mealTiming: _selectedMealTiming,
              frequencyType: _selectedFrequencyType,
              frequencyTimes: _frequencyTimes,
              timeOfDay: _selectedTimesOfDay.toList(),
              startDate: _startDate,
              endDate: _endDate,
              prescribedBy: _prescribedByController.text.trim().isNotEmpty
                  ? _prescribedByController.text.trim()
                  : null,
              notes: _notesController.text.trim().isNotEmpty
                  ? _notesController.text.trim()
                  : null,
            );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Medication' : 'Add Medication'),
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
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Medication Name *',
                prefixIcon: Icon(Icons.medication),
                hintText: 'e.g., Heartgard, Apoquel',
              ),
              validator: (v) => v?.trim().isEmpty == true ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dosageController,
              decoration: const InputDecoration(
                labelText: 'Dosage',
                prefixIcon: Icon(Icons.science),
                hintText: 'e.g., 50mg, 1 tablet',
              ),
            ),
            const SizedBox(height: 24),
            Text('Meal Timing', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Any'),
                  selected: _selectedMealTiming == null || _selectedMealTiming == 'any',
                  onSelected: (_) => setState(() => _selectedMealTiming = 'any'),
                ),
                ChoiceChip(
                  label: const Text('Before Meal'),
                  selected: _selectedMealTiming == 'before_meal',
                  onSelected: (_) => setState(() => _selectedMealTiming = 'before_meal'),
                ),
                ChoiceChip(
                  label: const Text('After Meal'),
                  selected: _selectedMealTiming == 'after_meal',
                  onSelected: (_) => setState(() => _selectedMealTiming = 'after_meal'),
                ),
                ChoiceChip(
                  label: const Text('With Meal'),
                  selected: _selectedMealTiming == 'with_meal',
                  onSelected: (_) => setState(() => _selectedMealTiming = 'with_meal'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Frequency Type', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Daily'),
                  selected: _selectedFrequencyType == 'daily',
                  onSelected: (_) => setState(() {
                    _selectedFrequencyType = 'daily';
                    if (_selectedTimesOfDay.isEmpty) _selectedTimesOfDay.add('morning');
                  }),
                ),
                ChoiceChip(
                  label: const Text('Weekly'),
                  selected: _selectedFrequencyType == 'weekly',
                  onSelected: (_) => setState(() {
                    _selectedFrequencyType = 'weekly';
                    if (_selectedTimesOfDay.isEmpty) _selectedTimesOfDay.add('morning');
                  }),
                ),
                ChoiceChip(
                  label: const Text('Monthly'),
                  selected: _selectedFrequencyType == 'monthly',
                  onSelected: (_) => setState(() {
                    _selectedFrequencyType = 'monthly';
                    if (_selectedTimesOfDay.isEmpty) _selectedTimesOfDay.add('morning');
                  }),
                ),
              ],
            ),
            if (_selectedFrequencyType != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('Times per $_selectedFrequencyType:', style: theme.textTheme.bodyMedium),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: _frequencyTimes > 1
                        ? () => setState(() => _frequencyTimes--)
                        : null,
                  ),
                  Text('$_frequencyTimes', style: theme.textTheme.titleMedium),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: _frequencyTimes < 10
                        ? () => setState(() => _frequencyTimes++)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Time of Day', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Morning'),
                    selected: _selectedTimesOfDay.contains('morning'),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTimesOfDay.add('morning');
                        } else {
                          _selectedTimesOfDay.remove('morning');
                        }
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text('Afternoon'),
                    selected: _selectedTimesOfDay.contains('afternoon'),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTimesOfDay.add('afternoon');
                        } else {
                          _selectedTimesOfDay.remove('afternoon');
                        }
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text('Evening'),
                    selected: _selectedTimesOfDay.contains('evening'),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTimesOfDay.add('evening');
                        } else {
                          _selectedTimesOfDay.remove('evening');
                        }
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text('Night'),
                    selected: _selectedTimesOfDay.contains('night'),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTimesOfDay.add('night');
                        } else {
                          _selectedTimesOfDay.remove('night');
                        }
                      });
                    },
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Start Date'),
                    subtitle: Text(
                      _startDate != null
                          ? DateFormat('MMM d, yyyy').format(_startDate!)
                          : 'Not set',
                    ),
                    onTap: _selectStartDate,
                  ),
                ),
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event),
                    title: const Text('End Date'),
                    subtitle: Text(
                      _endDate != null
                          ? DateFormat('MMM d, yyyy').format(_endDate!)
                          : 'Ongoing',
                    ),
                    trailing: _endDate != null
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() => _endDate = null),
                          )
                        : null,
                    onTap: _selectEndDate,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _prescribedByController,
              decoration: const InputDecoration(
                labelText: 'Prescribed By',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes',
                prefixIcon: Icon(Icons.notes),
                alignLabelWithHint: true,
              ),
            ),
            if (isEditing) ...[
              const SizedBox(height: 24),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active Medication'),
                subtitle: const Text('Inactive medications are archived'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
