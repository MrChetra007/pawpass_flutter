import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../shared/providers/vaccine_provider.dart';

class AddEditVaccineScreen extends ConsumerStatefulWidget {
  final String petId;
  final dynamic vaccine;

  const AddEditVaccineScreen({
    super.key,
    required this.petId,
    this.vaccine,
  });

  @override
  ConsumerState<AddEditVaccineScreen> createState() => _AddEditVaccineScreenState();
}

class _AddEditVaccineScreenState extends ConsumerState<AddEditVaccineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _vetNameController = TextEditingController();
  final _clinicController = TextEditingController();
  final _batchController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _dateGiven = DateTime.now();
  DateTime? _nextDueDate;
  bool _isLoading = false;

  bool get isEditing => widget.vaccine != null;

  @override
  void initState() {
    super.initState();
    if (widget.vaccine != null) {
      _nameController.text = widget.vaccine.name;
      _dateGiven = widget.vaccine.dateGiven;
      _nextDueDate = widget.vaccine.nextDueDate;
      _vetNameController.text = widget.vaccine.vetName ?? '';
      _clinicController.text = widget.vaccine.clinicName ?? '';
      _batchController.text = widget.vaccine.batchNumber ?? '';
      _notesController.text = widget.vaccine.notes ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _vetNameController.dispose();
    _clinicController.dispose();
    _batchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDateGiven() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateGiven,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _dateGiven = picked);
    }
  }

  Future<void> _selectNextDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextDueDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _nextDueDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (isEditing) {
        await ref.read(vaccineNotifierProvider.notifier).updateVaccine(
              widget.vaccine.id,
              {
                'name': _nameController.text.trim(),
                'date_given': _dateGiven.toIso8601String().split('T').first,
                'next_due_date': _nextDueDate?.toIso8601String().split('T').first,
                'vet_name': _vetNameController.text.trim().isNotEmpty
                    ? _vetNameController.text.trim()
                    : null,
                'clinic_name': _clinicController.text.trim().isNotEmpty
                    ? _clinicController.text.trim()
                    : null,
                'batch_number': _batchController.text.trim().isNotEmpty
                    ? _batchController.text.trim()
                    : null,
                'notes': _notesController.text.trim().isNotEmpty
                    ? _notesController.text.trim()
                    : null,
              },
            );
      } else {
        await ref.read(vaccineNotifierProvider.notifier).createVaccine(
              petId: widget.petId,
              name: _nameController.text.trim(),
              dateGiven: _dateGiven,
              nextDueDate: _nextDueDate,
              vetName: _vetNameController.text.trim().isNotEmpty
                  ? _vetNameController.text.trim()
                  : null,
              clinicName: _clinicController.text.trim().isNotEmpty
                  ? _clinicController.text.trim()
                  : null,
              batchNumber: _batchController.text.trim().isNotEmpty
                  ? _batchController.text.trim()
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
        title: Text(isEditing ? 'Edit Vaccine' : 'Add Vaccine'),
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
                labelText: 'Vaccine Name *',
                prefixIcon: Icon(Icons.vaccines),
                hintText: 'e.g., Rabies, DHPP, Bordetella',
              ),
              validator: (v) => v?.trim().isEmpty == true ? 'Vaccine name is required' : null,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date Given'),
              subtitle: Text(DateFormat('MMM d, yyyy').format(_dateGiven)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _selectDateGiven,
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: const Text('Next Due Date'),
              subtitle: Text(
                _nextDueDate != null
                    ? DateFormat('MMM d, yyyy').format(_nextDueDate!)
                    : 'Not set',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_nextDueDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _nextDueDate = null),
                    ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: _selectNextDueDate,
            ),
            const SizedBox(height: 24),
            Text(
              'VET & CLINIC INFO',
              style: theme.textTheme.labelLarge?.copyWith(letterSpacing: 1.2),
            ),
            const SizedBox(height: 12),
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
              controller: _batchController,
              decoration: const InputDecoration(
                labelText: 'Batch/Lot Number',
                prefixIcon: Icon(Icons.qr_code),
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
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
