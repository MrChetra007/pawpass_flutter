import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/supabase_constants.dart';
import '../../data/models/vet_record_model.dart';
import '../../shared/providers/record_provider.dart';

class AddEditRecordScreen extends ConsumerStatefulWidget {
  final String petId;
  final VetRecord? record;

  const AddEditRecordScreen({
    super.key,
    required this.petId,
    this.record,
  });

  @override
  ConsumerState<AddEditRecordScreen> createState() => _AddEditRecordScreenState();
}

class _AddEditRecordScreenState extends ConsumerState<AddEditRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _vetNameController = TextEditingController();
  final _clinicController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _notesController = TextEditingController();
  final _costController = TextEditingController();

  String _selectedType = 'checkup';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  bool get isEditing => widget.record != null;

  @override
  void initState() {
    super.initState();
    if (widget.record != null) {
      _titleController.text = widget.record!.title;
      _selectedType = widget.record!.type;
      _selectedDate = widget.record!.date;
      _vetNameController.text = widget.record!.vetName ?? '';
      _clinicController.text = widget.record!.clinicName ?? '';
      _diagnosisController.text = widget.record!.diagnosis ?? '';
      _treatmentController.text = widget.record!.treatment ?? '';
      _notesController.text = widget.record!.notes ?? '';
      _costController.text = widget.record!.cost?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _vetNameController.dispose();
    _clinicController.dispose();
    _diagnosisController.dispose();
    _treatmentController.dispose();
    _notesController.dispose();
    _costController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final cost = _costController.text.isNotEmpty
          ? double.tryParse(_costController.text)
          : null;

      if (isEditing) {
        await ref.read(recordNotifierProvider.notifier).updateRecord(
              widget.record!.id,
              {
                'type': _selectedType,
                'title': _titleController.text.trim(),
                'date': _selectedDate.toIso8601String().split('T').first,
                'vet_name': _vetNameController.text.trim().isNotEmpty
                    ? _vetNameController.text.trim()
                    : null,
                'clinic_name': _clinicController.text.trim().isNotEmpty
                    ? _clinicController.text.trim()
                    : null,
                'diagnosis': _diagnosisController.text.trim().isNotEmpty
                    ? _diagnosisController.text.trim()
                    : null,
                'treatment': _treatmentController.text.trim().isNotEmpty
                    ? _treatmentController.text.trim()
                    : null,
                'notes': _notesController.text.trim().isNotEmpty
                    ? _notesController.text.trim()
                    : null,
                'cost': cost,
              },
            );
      } else {
        await ref.read(recordNotifierProvider.notifier).createRecord(
              petId: widget.petId,
              type: _selectedType,
              title: _titleController.text.trim(),
              date: _selectedDate,
              vetName: _vetNameController.text.trim().isNotEmpty
                  ? _vetNameController.text.trim()
                  : null,
              clinicName: _clinicController.text.trim().isNotEmpty
                  ? _clinicController.text.trim()
                  : null,
              diagnosis: _diagnosisController.text.trim().isNotEmpty
                  ? _diagnosisController.text.trim()
                  : null,
              treatment: _treatmentController.text.trim().isNotEmpty
                  ? _treatmentController.text.trim()
                  : null,
              notes: _notesController.text.trim().isNotEmpty
                  ? _notesController.text.trim()
                  : null,
              cost: cost,
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
        title: Text(isEditing ? 'Edit Record' : 'Add Record'),
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
            Text('Record Type', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: SupabaseConstants.recordTypes.map((type) {
                final isSelected = _selectedType == type;
                final emoji = _getTypeEmoji(type);
                return ChoiceChip(
                  label: Text('$emoji ${_getTypeLabel(type)}'),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedType = type),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (v) => v?.trim().isEmpty == true ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date'),
              subtitle: Text(DateFormat('MMM d, yyyy').format(_selectedDate)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _selectDate,
            ),
            const Divider(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _vetNameController,
              decoration: const InputDecoration(
                labelText: 'Vet Name',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _clinicController,
              decoration: const InputDecoration(
                labelText: 'Clinic Name',
                prefixIcon: Icon(Icons.local_hospital),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _diagnosisController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Diagnosis',
                prefixIcon: Icon(Icons.medical_information),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _treatmentController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Treatment',
                prefixIcon: Icon(Icons.healing),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _costController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cost',
                prefixIcon: Icon(Icons.attach_money),
                prefixText: '\$ ',
              ),
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

  String _getTypeEmoji(String type) {
    switch (type) {
      case 'checkup': return '🩺';
      case 'surgery': return '💉';
      case 'illness': return '🤒';
      case 'injury': return '🩹';
      case 'dental': return '🦷';
      case 'grooming': return '✨';
      case 'lab_result': return '🧪';
      default: return '📋';
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'checkup': return 'Checkup';
      case 'surgery': return 'Surgery';
      case 'illness': return 'Illness';
      case 'injury': return 'Injury';
      case 'dental': return 'Dental';
      case 'grooming': return 'Grooming';
      case 'lab_result': return 'Lab Result';
      default: return 'Other';
    }
  }
}
