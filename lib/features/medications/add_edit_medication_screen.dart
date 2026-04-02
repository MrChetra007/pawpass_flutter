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

    setState(() => _isLoading = true);

    try {
      if (isEditing) {
        await ref.read(medicationNotifierProvider.notifier).updateMedication(
              widget.medication.id,
              {
                'name': _nameController.text.trim(),
                'dosage': _dosageController.text.trim().isNotEmpty
                    ? _dosageController.text.trim()
                    : null,
                'frequency': _selectedFrequency,
                'start_date': _startDate?.toIso8601String().split('T').first,
                'end_date': _endDate?.toIso8601String().split('T').first,
                'prescribed_by': _prescribedByController.text.trim().isNotEmpty
                    ? _prescribedByController.text.trim()
                    : null,
                'notes': _notesController.text.trim().isNotEmpty
                    ? _notesController.text.trim()
                    : null,
                'is_active': _isActive,
              },
            );
      } else {
        await ref.read(medicationNotifierProvider.notifier).createMedication(
              petId: widget.petId,
              name: _nameController.text.trim(),
              dosage: _dosageController.text.trim().isNotEmpty
                  ? _dosageController.text.trim()
                  : null,
              frequency: _selectedFrequency,
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
            Text('Frequency', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: SupabaseConstants.medicationFrequencies.map((freq) {
                return ChoiceChip(
                  label: Text(freq),
                  selected: _selectedFrequency == freq.toLowerCase(),
                  onSelected: (_) {
                    setState(() {
                      _selectedFrequency = freq.toLowerCase();
                    });
                  },
                );
              }).toList(),
            ),
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
