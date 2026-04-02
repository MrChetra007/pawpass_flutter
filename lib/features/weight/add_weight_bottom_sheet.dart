import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../shared/providers/weight_provider.dart';

class AddWeightBottomSheet extends ConsumerStatefulWidget {
  final String petId;

  const AddWeightBottomSheet({super.key, required this.petId});

  @override
  ConsumerState<AddWeightBottomSheet> createState() => _AddWeightBottomSheetState();
}

class _AddWeightBottomSheetState extends ConsumerState<AddWeightBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();
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
      final weight = double.parse(_weightController.text);

      await ref.read(weightNotifierProvider.notifier).createWeightLog(
            petId: widget.petId,
            weightKg: weight,
            recordedAt: _selectedDate,
            notes: _notesController.text.trim().isNotEmpty
                ? _notesController.text.trim()
                : null,
          );

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

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerTheme.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Log Weight',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Weight (kg) *',
                prefixIcon: Icon(Icons.monitor_weight),
                suffixText: 'kg',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Weight is required';
                final weight = double.tryParse(v);
                if (weight == null || weight <= 0) return 'Enter a valid weight';
                if (weight > 500) return 'Weight seems too high';
                return null;
              },
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isLoading ? null : _save,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
