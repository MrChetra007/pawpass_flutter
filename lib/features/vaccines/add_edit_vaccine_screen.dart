import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import '../../shared/providers/vaccine_provider.dart';
import '../../core/utils/feature_gate.dart';

final _storageClient = Supabase.instance.client;

class AddEditVaccineScreen extends ConsumerStatefulWidget {
  final String petId;
  final dynamic vaccine;

  const AddEditVaccineScreen({super.key, required this.petId, this.vaccine});

  @override
  ConsumerState<AddEditVaccineScreen> createState() =>
      _AddEditVaccineScreenState();
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

  File? _selectedFile;
  String? _selectedFileName;
  String? _docUrl;
  bool _isUploading = false;

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
      _docUrl = widget.vaccine.docUrl;
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

  Future<void> _pickFile() async {
    final hasAccess = await FeatureGate.check(
      context: context,
      ref: ref,
      feature: 'file_upload',
      showModal: true,
    );

    if (!hasAccess) return;

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
      initialDate:
          _nextDueDate ?? DateTime.now().add(const Duration(days: 365)),
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
      String? uploadedDocUrl;

      if (_selectedFile != null) {
        uploadedDocUrl = await _uploadFile();
        if (uploadedDocUrl == null) {
          setState(() => _isLoading = false);
          return;
        }
      }

      final docUrlToSave = uploadedDocUrl ?? _docUrl;

      if (isEditing) {
        await ref
            .read(vaccineNotifierProvider.notifier)
            .updateVaccine(widget.vaccine.id, {
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
              'doc_url': docUrlToSave,
            });
      } else {
        await ref
            .read(vaccineNotifierProvider.notifier)
            .createVaccine(
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
              docUrl: docUrlToSave,
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

  void _showDocumentPreview(String url, String title) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) => _DocPreviewOverlay(url: url, title: title),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
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
              validator: (v) =>
                  v?.trim().isEmpty == true ? 'Vaccine name is required' : null,
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
            const SizedBox(height: 24),
            Text(
              'DOCUMENT',
              style: theme.textTheme.labelLarge?.copyWith(letterSpacing: 1.2),
            ),
            const SizedBox(height: 12),
            if (_selectedFile != null || _docUrl != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.description, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedFile != null
                            ? _selectedFileName!
                            : _docUrl!.split('/').last,
                        style: theme.textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_docUrl != null && _selectedFile == null)
                      IconButton(
                        icon: const Icon(Icons.visibility),
                        onPressed: () => _showDocumentPreview(
                          _docUrl!,
                          widget.vaccine?.name ?? 'Vaccine Document',
                        ),
                        tooltip: 'View document',
                      ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() {
                        _selectedFile = null;
                        _selectedFileName = null;
                        _docUrl = null;
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            OutlinedButton.icon(
              onPressed: _isUploading ? null : _pickFile,
              icon: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file),
              label: Text(
                _selectedFile != null || _docUrl != null
                    ? 'Change Document'
                    : 'Upload Document',
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _DocPreviewOverlay extends StatefulWidget {
  final String url;
  final String title;
  const _DocPreviewOverlay({required this.url, required this.title});

  @override
  State<_DocPreviewOverlay> createState() => _DocPreviewOverlayState();
}

class _DocPreviewOverlayState extends State<_DocPreviewOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  bool get _isImage {
    final lower = widget.url.toLowerCase();
    return lower.contains('.png') ||
        lower.contains('.jpg') ||
        lower.contains('.jpeg') ||
        lower.contains('.gif') ||
        lower.contains('.webp') ||
        lower.contains('image') ||
        lower.contains('photo');
  }

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _animCtrl.reverse();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(
            widget.title,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: _dismiss,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.download, color: Colors.white),
              onPressed: () => _downloadDoc(context),
              tooltip: 'Download',
            ),
          ],
        ),
        body: _isImage ? _buildImagePreview() : _buildPdfPreview(),
      ),
    );
  }

  Widget _buildImagePreview() {
    return _LocalImagePreview(url: widget.url);
  }

  Widget _buildPdfPreview() {
    return FutureBuilder<String>(
      future: _downloadTemp(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.picture_as_pdf_outlined,
                  color: Colors.white54,
                  size: 72,
                ),
                const SizedBox(height: 20),
                const Text(
                  'PDF Document',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Tap Open to view with your device's PDF viewer",
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: () => OpenFilex.open(snapshot.data!),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String> _downloadTemp() async {
    try {
      final urlParts = widget.url.split('/vet-documents/');
      if (urlParts.length < 2) {
        throw Exception('Invalid URL format');
      }
      final filePath = urlParts.last.split('?').first;
      final fileName = filePath.split('/').last;
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/$fileName';

      final bytes = await _storageClient.storage
          .from('vet-documents')
          .download(filePath);
      final file = File(path);
      await file.writeAsBytes(bytes);
      return path;
    } catch (e) {
      final dir = await getTemporaryDirectory();
      final fileName = widget.url.split('/').last.split('?').first;
      final path = '${dir.path}/${fileName.isNotEmpty ? fileName : 'document'}';
      await Dio().download(widget.url, path);
      return path;
    }
  }

  Future<void> _downloadDoc(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    String? savePath;
    try {
      final Directory dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
        if (!dir.existsSync()) dir.createSync(recursive: true);
      } else {
        dir = await getApplicationDocumentsDirectory();
      }
      final rawName = widget.url.split('/').last.split('?').first;
      final fileName = rawName.isNotEmpty
          ? rawName
          : '${widget.title}_document';
      savePath = '${dir.path}/$fileName';
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not resolve save path: $e')),
      );
      return;
    }
    final progressNotifier = ValueNotifier<double?>(null);
    final controller = messenger.showSnackBar(
      SnackBar(
        duration: const Duration(minutes: 5),
        content: ValueListenableBuilder<double?>(
          valueListenable: progressNotifier,
          builder: (_, pct, __) => Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  value: pct,
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                pct != null
                    ? 'Downloading… ${(pct * 100).toStringAsFixed(0)}%'
                    : 'Downloading…',
              ),
            ],
          ),
        ),
      ),
    );
    try {
      final finalPath = savePath;
      await Dio().download(
        widget.url,
        finalPath,
        onReceiveProgress: (received, total) {
          if (total > 0) progressNotifier.value = received / total;
        },
      );
      controller.close();
      progressNotifier.dispose();
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              Platform.isAndroid ? 'Saved to Downloads' : 'Saved to Documents',
            ),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => OpenFilex.open(finalPath),
            ),
          ),
        );
      }
    } catch (e) {
      controller.close();
      progressNotifier.dispose();
      if (context.mounted)
        messenger.showSnackBar(SnackBar(content: Text('Download failed: $e')));
    }
  }
}

class _LocalImagePreview extends StatefulWidget {
  final String url;
  const _LocalImagePreview({required this.url});

  @override
  State<_LocalImagePreview> createState() => _LocalImagePreviewState();
}

class _LocalImagePreviewState extends State<_LocalImagePreview> {
  String? _localPath;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _downloadImage();
  }

  Future<void> _downloadImage() async {
    try {
      final supabase = Supabase.instance.client;
      final urlParts = widget.url.split('/vet-documents/');
      if (urlParts.length < 2) {
        throw Exception('Invalid URL format');
      }
      final filePath = urlParts.last.split('?').first;
      final fileName = filePath.split('/').last;
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/$fileName';

      final bytes = await supabase.storage
          .from('vet-documents')
          .download(filePath);
      final file = File(path);
      await file.writeAsBytes(bytes);

      if (mounted) {
        setState(() {
          _localPath = path;
          _isLoading = false;
        });
      }
    } catch (e) {
      try {
        final dir = await getTemporaryDirectory();
        final fileName = widget.url.split('/').last.split('?').first;
        final path = '${dir.path}/${fileName.isNotEmpty ? fileName : 'image'}';
        await Dio().download(widget.url, path);

        if (mounted) {
          setState(() {
            _localPath = path;
            _isLoading = false;
          });
        }
      } catch (e2) {
        if (mounted) {
          setState(() {
            _error = e.toString();
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 12),
            Text('Loading image…', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    if (_error != null || _localPath == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.broken_image_outlined,
              color: Colors.white54,
              size: 64,
            ),
            const SizedBox(height: 12),
            const Text(
              'Could not load preview',
              style: TextStyle(color: Colors.white70),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: Center(
        child: Image.file(
          File(_localPath!),
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white54,
                  size: 64,
                ),
                SizedBox(height: 12),
                Text(
                  'Could not load image',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
