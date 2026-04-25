import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme_data.dart';
import '../../data/models/vaccine_model.dart';
import '../../shared/providers/pet_provider.dart';
import '../../shared/providers/vaccine_provider.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/skeleton_loader.dart';
import '../../shared/widgets/status_badge.dart';
import 'add_edit_vaccine_screen.dart';

class _DocumentPreviewOverlay extends StatefulWidget {
  final String url;
  final String title;

  const _DocumentPreviewOverlay({required this.url, required this.title});

  @override
  State<_DocumentPreviewOverlay> createState() =>
      _DocumentPreviewOverlayState();
}

class _DocumentPreviewOverlayState extends State<_DocumentPreviewOverlay>
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
        ),
        body: _isImage
            ? _buildImagePreview()
            : _PdfPreviewPage(url: widget.url, title: widget.title),
      ),
    );
  }

  Widget _buildImagePreview() {
    return _LocalImagePreview(url: widget.url);
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

enum _PreviewState { loading, ready, error }

class _PdfPreviewPage extends StatefulWidget {
  final String url;
  final String title;
  const _PdfPreviewPage({required this.url, required this.title});

  @override
  State<_PdfPreviewPage> createState() => _PdfPreviewPageState();
}

class _PdfPreviewPageState extends State<_PdfPreviewPage> {
  _PreviewState _state = _PreviewState.loading;
  String? _localPath;
  String? _error;
  double _downloadProgress = 0;

  @override
  void initState() {
    super.initState();
    _fetchFile();
  }

  Future<void> _fetchFile() async {
    try {
      final dir = await getTemporaryDirectory();
      final fileName = widget.url.split('/').last.split('?').first;
      final path = '${dir.path}/${fileName.isNotEmpty ? fileName : 'document'}';

      await Dio().download(
        widget.url,
        path,
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() => _downloadProgress = received / total);
          }
        },
      );

      if (mounted) {
        setState(() {
          _localPath = path;
          _state = _PreviewState.ready;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _state = _PreviewState.error;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case _PreviewState.loading:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                value: _downloadProgress > 0 ? _downloadProgress : null,
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              Text(
                _downloadProgress > 0
                    ? '${(_downloadProgress * 100).toStringAsFixed(0)}%'
                    : 'Loading document…',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        );

      case _PreviewState.ready:
        return _NoPreviewFallback(localPath: _localPath!);

      case _PreviewState.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.white54, size: 56),
              const SizedBox(height: 12),
              const Text(
                'Failed to load document',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? '',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
    }
  }
}

class _NoPreviewFallback extends StatelessWidget {
  final String localPath;
  const _NoPreviewFallback({required this.localPath});

  @override
  Widget build(BuildContext context) {
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
              'In-app PDF preview not enabled',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Add flutter_pdfview to pubspec.yaml to enable it.\nIn the meantime you can open the file below.',
              style: TextStyle(color: Colors.white60, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => OpenFilex.open(localPath),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open with device app'),
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
  }
}

class _DocumentDownloader {
  static Future<void> download(
    BuildContext context,
    String url,
    String title,
  ) async {
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
      final rawName = url.split('/').last.split('?').first;
      final fileName = rawName.isNotEmpty ? rawName : '${title}_document';
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
        url,
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
      if (context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
    }
  }
}

class VaccinesListScreen extends ConsumerStatefulWidget {
  final String? initialPetId;

  const VaccinesListScreen({super.key, this.initialPetId});

  @override
  ConsumerState<VaccinesListScreen> createState() => _VaccinesListScreenState();
}

class _VaccinesListScreenState extends ConsumerState<VaccinesListScreen>
    with TickerProviderStateMixin {
  late AnimationController _listAnimationController;
  late Animation<double> _fadeAnimation;
  String? _selectedPetId;

  @override
  void initState() {
    super.initState();
    _selectedPetId = widget.initialPetId;
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _listAnimationController, curve: Curves.easeOut),
    );
    Future.microtask(() {
      ref.read(vaccineNotifierProvider.notifier).loadVaccines();
    });
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final petsAsync = ref.watch(petNotifierProvider);
    final vaccinesAsync = ref.watch(vaccineNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 100,
            floating: true,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(48, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vaccines', style: theme.textTheme.headlineMedium),
                      const SizedBox(height: 4),
                      Text(
                        'Track vaccinations and reminders',
                        style: theme.textTheme.labelLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        body: Column(
          children: [
            _buildPetFilter(petsAsync),
            Expanded(
              child: vaccinesAsync.when(
                loading: () => _buildLoadingState(),
                error: (e, _) => _buildErrorState(e.toString()),
                data: (vaccines) {
                  final filteredVaccines = _selectedPetId != null
                      ? vaccines
                            .where((v) => v.petId == _selectedPetId)
                            .toList()
                      : vaccines;

                  if (filteredVaccines.isEmpty) {
                    return EmptyState(
                      icon: Icons.vaccines,
                      title: 'No vaccines yet',
                      subtitle:
                          'Track your pet\'s vaccinations and get reminders',
                      actionLabel: 'Add Vaccine',
                      onAction: () => _showAddVaccine(petsAsync),
                    );
                  }
                  _listAnimationController.forward();
                  return _buildVaccinesList(filteredVaccines, petsAsync);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _AnimatedFab(
        onPressed: () => _showAddVaccine(petsAsync),
        theme: theme,
      ),
    );
  }

  Widget _buildPetFilter(AsyncValue<List> petsAsync) {
    final theme = Theme.of(context);
    return petsAsync.when(
      data: (pets) {
        if (pets.isEmpty) return const SizedBox();
        return Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: const Text('All Pets'),
                  selected: _selectedPetId == null,
                  selectedColor: theme.colorScheme.primary.withValues(
                    alpha: 0.2,
                  ),
                  onSelected: (_) => setState(() => _selectedPetId = null),
                ),
              ),
              ...pets.map(
                (pet) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(pet.name),
                    selected: _selectedPetId == pet.id,
                    selectedColor: theme.colorScheme.primary.withValues(
                      alpha: 0.2,
                    ),
                    onSelected: (_) => setState(() => _selectedPetId = pet.id),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: SkeletonCard(),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text('Error: $error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () =>
                ref.read(vaccineNotifierProvider.notifier).loadVaccines(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildVaccinesList(
    List<Vaccine> vaccines,
    AsyncValue<List> petsAsync,
  ) {
    final activeVaccines = vaccines.where((v) => v.isActive).toList();
    final inactiveVaccines = vaccines.where((v) => !v.isActive).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (activeVaccines.isNotEmpty) ...[
          FadeTransition(
            opacity: _fadeAnimation,
            child: _buildSectionHeader(
              context,
              'Active',
              activeVaccines.length,
            ),
          ),
          const SizedBox(height: 12),
          ...activeVaccines.map(
            (vaccine) => FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildVaccineCard(vaccine, petsAsync),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (inactiveVaccines.isNotEmpty) ...[
          FadeTransition(
            opacity: _fadeAnimation,
            child: _buildSectionHeader(
              context,
              'Inactive',
              inactiveVaccines.length,
            ),
          ),
          const SizedBox(height: 12),
          ...inactiveVaccines.map(
            (vaccine) => FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildVaccineCard(vaccine, petsAsync),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('$count', style: theme.textTheme.labelMedium),
        ),
      ],
    );
  }

  Widget _buildVaccineCard(Vaccine vaccine, AsyncValue<List> petsAsync) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(vaccine.status);

    String petName = 'Unknown Pet';
    petsAsync.whenData((pets) {
      final pet = pets.where((p) => p.id == vaccine.petId).firstOrNull;
      if (pet != null) petName = pet.name;
    });

    return GestureDetector(
      onTap: () => _showEditVaccine(vaccine),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.vaccines, color: statusColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vaccine.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.pets,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            petName,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Given: ${DateFormat('MMM d, yyyy').format(vaccine.dateGiven)}',
                        style: theme.textTheme.labelMedium,
                      ),
                      if (vaccine.nextDueDate != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Due: ${DateFormat('MMM d, yyyy').format(vaccine.nextDueDate!)}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                StatusBadge(status: _getStatusType(vaccine.status)),
              ],
            ),
            if (vaccine.docUrl != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _showDocumentPreview(vaccine.docUrl!, vaccine.name),
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text('View'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _downloadDocument(vaccine.docUrl!, vaccine.name),
                      icon: const Icon(Icons.download_outlined, size: 18),
                      label: const Text('Download'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDocumentPreview(String url, String title) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) =>
            _DocumentPreviewOverlay(url: url, title: title),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  Future<void> _downloadDocument(String url, String title) async {
    await _DocumentDownloader.download(context, url, title);
  }

  Color _getStatusColor(VaccineStatus status) {
    switch (status) {
      case VaccineStatus.upToDate:
        return PawThemeData.successGreen;
      case VaccineStatus.dueSoon:
        return Colors.orange;
      case VaccineStatus.overdue:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  StatusType _getStatusType(VaccineStatus status) {
    switch (status) {
      case VaccineStatus.upToDate:
        return StatusType.upToDate;
      case VaccineStatus.dueSoon:
        return StatusType.dueSoon;
      case VaccineStatus.overdue:
        return StatusType.overdue;
      default:
        return StatusType.unknown;
    }
  }

  void _showDeleteConfirmation(Vaccine vaccine) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vaccine?'),
        content: Text('Are you sure you want to delete ${vaccine.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(vaccineNotifierProvider.notifier)
                  .deleteVaccine(vaccine.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddVaccine(AsyncValue<List> petsAsync) {
    petsAsync.whenData((pets) {
      if (pets.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Add a pet first')));
        return;
      }

      if (_selectedPetId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddEditVaccineScreen(petId: _selectedPetId!),
          ),
        );
      } else {
        _showPetPicker(pets);
      }
    });
  }

  void _showPetPicker(List pets) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Select Pet', style: theme.textTheme.titleLarge),
            ),
            ...pets.map(
              (pet) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.1,
                  ),
                  child: Text(pet.speciesEmoji),
                ),
                title: Text(pet.name),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddEditVaccineScreen(petId: pet.id),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showEditVaccine(Vaccine vaccine) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddEditVaccineScreen(petId: vaccine.petId, vaccine: vaccine),
      ),
    );
  }
}

class _AnimatedFab extends StatefulWidget {
  final VoidCallback onPressed;
  final ThemeData theme;

  const _AnimatedFab({required this.onPressed, required this.theme});

  @override
  State<_AnimatedFab> createState() => _AnimatedFabState();
}

class _AnimatedFabState extends State<_AnimatedFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FloatingActionButton(
        onPressed: () {
          _controller.forward().then((_) {
            _controller.reverse();
            widget.onPressed();
          });
        },
        backgroundColor: widget.theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}
