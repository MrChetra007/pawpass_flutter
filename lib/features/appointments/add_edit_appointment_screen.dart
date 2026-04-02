import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../shared/providers/appointment_provider.dart';

class AddEditAppointmentScreen extends ConsumerStatefulWidget {
  final String petId;
  final dynamic appointment;

  const AddEditAppointmentScreen({
    super.key,
    required this.petId,
    this.appointment,
  });

  @override
  ConsumerState<AddEditAppointmentScreen> createState() => _AddEditAppointmentScreenState();
}

class _AddEditAppointmentScreenState extends ConsumerState<AddEditAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _vetNameController = TextEditingController();
  final _clinicController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedType = 'vet';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;

  bool get isEditing => widget.appointment != null;

  @override
  void initState() {
    super.initState();
    if (widget.appointment != null) {
      _titleController.text = widget.appointment.title;
      _selectedType = widget.appointment.type ?? 'vet';
      _selectedDate = widget.appointment.datetime;
      _selectedTime = TimeOfDay.fromDateTime(widget.appointment.datetime);
      _vetNameController.text = widget.appointment.vetName ?? '';
      _clinicController.text = widget.appointment.clinicName ?? '';
      _phoneController.text = widget.appointment.clinicPhone ?? '';
      _addressController.text = widget.appointment.clinicAddress ?? '';
      _notesController.text = widget.appointment.notes ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _vetNameController.dispose();
    _clinicController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  DateTime get _combinedDateTime {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (isEditing) {
        await ref.read(appointmentNotifierProvider.notifier).updateAppointment(
              widget.appointment.id,
              {
                'title': _titleController.text.trim(),
                'type': _selectedType,
                'datetime': _combinedDateTime.toUtc().toIso8601String(),
                'vet_name': _vetNameController.text.trim().isNotEmpty
                    ? _vetNameController.text.trim()
                    : null,
                'clinic_name': _clinicController.text.trim().isNotEmpty
                    ? _clinicController.text.trim()
                    : null,
                'clinic_phone': _phoneController.text.trim().isNotEmpty
                    ? _phoneController.text.trim()
                    : null,
                'clinic_address': _addressController.text.trim().isNotEmpty
                    ? _addressController.text.trim()
                    : null,
                'notes': _notesController.text.trim().isNotEmpty
                    ? _notesController.text.trim()
                    : null,
              },
            );
      } else {
        await ref.read(appointmentNotifierProvider.notifier).createAppointment(
              petId: widget.petId,
              title: _titleController.text.trim(),
              datetime: _combinedDateTime,
              type: _selectedType,
              vetName: _vetNameController.text.trim().isNotEmpty
                  ? _vetNameController.text.trim()
                  : null,
              clinicName: _clinicController.text.trim().isNotEmpty
                  ? _clinicController.text.trim()
                  : null,
              clinicPhone: _phoneController.text.trim().isNotEmpty
                  ? _phoneController.text.trim()
                  : null,
              clinicAddress: _addressController.text.trim().isNotEmpty
                  ? _addressController.text.trim()
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
        title: Text(isEditing ? 'Edit Appointment' : 'New Appointment'),
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
            Text('Appointment Type', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildTypeChip('vet', '🩺 Vet Visit'),
                _buildTypeChip('grooming', '✂️ Grooming'),
                _buildTypeChip('training', '🎓 Training'),
                _buildTypeChip('other', '📅 Other'),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                prefixIcon: Icon(Icons.title),
                hintText: 'e.g., Annual checkup',
              ),
              validator: (v) => v?.trim().isEmpty == true ? 'Title is required' : null,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Date'),
                    subtitle: Text(DateFormat('MMM d, yyyy').format(_selectedDate)),
                    onTap: _selectDate,
                  ),
                ),
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.access_time),
                    title: const Text('Time'),
                    subtitle: Text(_selectedTime.format(context)),
                    onTap: _selectTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'CLINIC INFO',
              style: theme.textTheme.labelLarge?.copyWith(letterSpacing: 1.2),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _vetNameController,
              decoration: const InputDecoration(
                labelText: 'Vet/Professional Name',
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
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Address',
                prefixIcon: Icon(Icons.location_on),
                alignLabelWithHint: true,
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

  Widget _buildTypeChip(String type, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedType == type,
      onSelected: (_) => setState(() => _selectedType = type),
    );
  }
}
