import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/supabase_constants.dart';
import '../../data/models/vet_record_model.dart';
import '../../shared/providers/record_provider.dart';
import '../../shared/widgets/upgrade_modal.dart';
import '../../core/utils/feature_gate.dart';

class AddEditRecordScreen extends ConsumerStatefulWidget {
  final String petId;
  final VetRecord? record;

  const AddEditRecordScreen({super.key, required this.petId, this.record});

  @override
  ConsumerState<AddEditRecordScreen> createState() =>
      _AddEditRecordScreenState();
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
  String? _docUrl;
  File? _selectedFile;
  String? _selectedFileName;
  bool _isUploading = false;

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
      _docUrl = widget.record!.docUrl;
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

  Future<void> _pickFile() async {
    final canAccess = await FeatureGate.check(
      context: context,
      ref: ref,
      feature: 'file_upload',
      customMessage: 'Upload documents with Paw Plan',
    );

    if (!canAccess) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = File(result.files.first.path!);
          _selectedFileName = result.files.first.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
      }
    }
  }

  Future<String?> _uploadFile() async {
    if (_selectedFile == null) return _docUrl;

    setState(() => _isUploading = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final fileName =
          '${user.id}/${DateTime.now().millisecondsSinceEpoch}_$_selectedFileName';

      await supabase.storage
          .from('vet-documents')
          .upload(fileName, _selectedFile!);

      final url = await supabase.storage
          .from('vet-documents')
          .createSignedUrl(fileName, 31536000);

      setState(() => _isUploading = false);
      return url;
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading file: $e')));
      }
      return null;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? uploadedDocUrl;

      if (_selectedFile != null) {
        uploadedDocUrl = await _uploadFile();
        if (uploadedDocUrl == null) {
          setState(() => _isLoading = false);
          return;
        }
      }

      final docUrlToSave = uploadedDocUrl ?? _docUrl;
      final cost = _costController.text.isNotEmpty
          ? double.tryParse(_costController.text)
          : null;

      if (isEditing) {
        await ref
            .read(recordNotifierProvider.notifier)
            .updateRecord(widget.record!.id, {
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
              'doc_url': docUrlToSave,
              'cost': cost,
            });
      } else {
        await ref
            .read(recordNotifierProvider.notifier)
            .createRecord(
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
              docUrl: docUrlToSave,
              cost: cost,
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
              validator: (v) =>
                  v?.trim().isEmpty == true ? 'Title is required' : null,
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
            _buildDocumentUpload(),
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
      case 'checkup':
        return '🩺';
      case 'surgery':
        return '💉';
      case 'illness':
        return '🤒';
      case 'injury':
        return '🩹';
      case 'dental':
        return '🦷';
      case 'grooming':
        return '✨';
      case 'lab_result':
        return '🧪';
      default:
        return '📋';
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'checkup':
        return 'Checkup';
      case 'surgery':
        return 'Surgery';
      case 'illness':
        return 'Illness';
      case 'injury':
        return 'Injury';
      case 'dental':
        return 'Dental';
      case 'grooming':
        return 'Grooming';
      case 'lab_result':
        return 'Lab Result';
      default:
        return 'Other';
    }
  }

  Widget _buildDocumentUpload() {
    final theme = Theme.of(context);

    final bool isImage = _docUrl != null && _isImageFile(_docUrl!);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerTheme.color ?? Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_file, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('Document', style: theme.textTheme.titleMedium),
              const Spacer(),
              if (_isUploading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_selectedFile != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.description, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedFileName ?? 'File',
                      style: theme.textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: theme.colorScheme.error),
                    onPressed: () => setState(() => _selectedFile = null),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            )
          else if (_docUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _docUrl!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('Image load error: $error for URL: $_docUrl');
                  return Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.description,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Document attached',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.description, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _docUrl!.split('/').last,
                    style: theme.textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: theme.colorScheme.error),
                  onPressed: () => setState(() => _docUrl = null),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ] else
            OutlinedButton.icon(
              onPressed: _isUploading ? null : _pickFile,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload Document'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'PDF, Images (max 10MB)',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.textTheme.labelLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  bool _isImageFile(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.png') ||
        lower.contains('.jpg') ||
        lower.contains('.jpeg') ||
        lower.contains('.gif') ||
        lower.contains('.webp') ||
        lower.contains('image') ||
        lower.contains('photo');
  }

  Widget _buildDocumentPlaceholder(ThemeData theme) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Icon(
          Icons.description,
          size: 40,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
