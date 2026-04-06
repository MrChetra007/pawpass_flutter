import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_theme_data.dart';
import '../../data/models/vet_record_model.dart';
import '../../shared/providers/pet_provider.dart';
import '../../shared/providers/record_provider.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/skeleton_loader.dart';
import 'add_edit_record_screen.dart';

// ---------------------------------------------------------------------------
// Document preview overlay
// ---------------------------------------------------------------------------

/// Shows a full-screen overlay to preview a document URL.
/// - Image files  → rendered with Image.network + pinch-to-zoom
/// - PDF / other  → downloads to temp dir then renders via flutter_pdfview
///   (see inline comments). Falls back to "open with device app" until the
///   package is added to pubspec.yaml.
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
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: Center(
        child: Image.network(
          widget.url,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            final pct = progress.expectedTotalBytes != null
                ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                : null;
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(value: pct, color: Colors.white),
                  const SizedBox(height: 12),
                  Text(
                    pct != null
                        ? '${(pct * 100).toStringAsFixed(0)}%'
                        : 'Loading…',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            );
          },
          errorBuilder: (context, error, _) => const Center(
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
                  'Could not load preview',
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

// ---------------------------------------------------------------------------
// PDF preview page
// ---------------------------------------------------------------------------

enum _PreviewState { loading, ready, error }

/// Downloads the document to a temp file, then renders it.
///
/// To enable native PDF rendering:
///   1. Add `flutter_pdfview: ^2.x.x` to pubspec.yaml
///   2. Uncomment the PDFView block in [_PdfPreviewPageState.build]
///   3. Add `import 'package:flutter_pdfview/flutter_pdfview.dart';` at the top
///
/// Until then, the widget shows a "open with device app" fallback.
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

      if (mounted)
        setState(() {
          _localPath = path;
          _state = _PreviewState.ready;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _state = _PreviewState.error;
        });
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
        // ── Uncomment after adding flutter_pdfview to pubspec.yaml ──────
        // return PDFView(
        //   filePath: _localPath!,
        //   enableSwipe: true,
        //   swipeHorizontal: true,
        //   autoSpacing: false,
        //   pageFling: true,
        // );
        // ── Fallback ─────────────────────────────────────────────────────
        return _NoPreviewFallback(localPath: _localPath!);

      case _PreviewState.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.white54,
                  size: 56,
                ),
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
              'Add flutter_pdfview to pubspec.yaml to enable it.\n'
              'In the meantime you can open the file below.',
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

// ---------------------------------------------------------------------------
// Download helper
// ---------------------------------------------------------------------------

class _DocumentDownloader {
  static Future<void> download(
    BuildContext context,
    String url,
    String title,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    String? savePath;

    // Resolve destination directory.
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

    // Show progress.
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

// ---------------------------------------------------------------------------
// Main screen
// ---------------------------------------------------------------------------

class RecordsListScreen extends ConsumerStatefulWidget {
  const RecordsListScreen({super.key});

  @override
  ConsumerState<RecordsListScreen> createState() => _RecordsListScreenState();
}

class _RecordsListScreenState extends ConsumerState<RecordsListScreen>
    with TickerProviderStateMixin {
  late AnimationController _listAnimationController;
  late Animation<double> _fadeAnimation;
  String? _selectedPetId;
  String _filterType = 'all';

  @override
  void initState() {
    super.initState();
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _listAnimationController, curve: Curves.easeOut),
    );
    Future.microtask(
      () => ref.read(recordNotifierProvider.notifier).loadRecords(),
    );
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final petsAsync = ref.watch(petNotifierProvider);
    final recordsAsync = ref.watch(recordNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 100,
            floating: true,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Health Records',
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Track your pet\'s medical history',
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
            _buildTypeFilter(),
            Expanded(
              child: recordsAsync.when(
                loading: () => _buildLoadingState(),
                error: (e, _) => _buildErrorState(e.toString()),
                data: (records) {
                  final filteredRecords = _filterRecords(records);
                  if (filteredRecords.isEmpty) {
                    return EmptyState(
                      icon: Icons.description,
                      title: 'No records yet',
                      subtitle:
                          'Add health records to keep track of your pet\'s medical history',
                      actionLabel: 'Add Record',
                      onAction: () => _showAddRecord(petsAsync),
                    );
                  }
                  _listAnimationController.forward();
                  return _buildRecordsList(filteredRecords);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _AnimatedFab(
        onPressed: () => _showAddRecord(petsAsync),
        theme: theme,
      ),
    );
  }

  // ── Filters ───────────────────────────────────────────────────────────────

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

  Widget _buildTypeFilter() {
    final theme = Theme.of(context);
    const types = [
      'all',
      'checkup',
      'surgery',
      'illness',
      'injury',
      'dental',
      'other',
    ];
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: types.map((type) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_getTypeLabel(type)),
              selected: _filterType == type,
              selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
              checkmarkColor: theme.colorScheme.primary,
              onSelected: (_) => setState(() => _filterType = type),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── States ────────────────────────────────────────────────────────────────

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
                ref.read(recordNotifierProvider.notifier).loadRecords(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ── List ──────────────────────────────────────────────────────────────────

  Widget _buildRecordsList(List<VetRecord> records) {
    final groupedRecords = _groupByYear(records);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedRecords.length,
      itemBuilder: (context, index) {
        final year = groupedRecords.keys.elementAt(index);
        final yearRecords = groupedRecords[year]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        year.toString(),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${yearRecords.length} record${yearRecords.length > 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
            ),
            ...yearRecords.map(
              (record) => FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildRecordCard(record),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Card ──────────────────────────────────────────────────────────────────

  Widget _buildRecordCard(VetRecord record) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _showEditRecord(record),
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
            // Top row: icon + text info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    record.typeEmoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          record.typeLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: theme.textTheme.labelMedium?.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM d, yyyy').format(record.date),
                            style: theme.textTheme.labelMedium,
                          ),
                        ],
                      ),
                      if (record.clinicName != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.local_hospital,
                              size: 14,
                              color: theme.textTheme.labelMedium?.color,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                record.clinicName!,
                                style: theme.textTheme.labelMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            // Bottom row: View / Download + cost badge
            if (record.docUrl != null || record.cost != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (record.docUrl != null) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _showDocumentPreview(record.docUrl!, record.title),
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
                            _downloadDocument(record.docUrl!, record.title),
                        icon: const Icon(Icons.download_outlined, size: 18),
                        label: const Text('Download'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                    if (record.cost != null) const SizedBox(width: 8),
                  ],
                  if (record.cost != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: PawThemeData.successGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '\$${record.cost!.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: PawThemeData.successGreen,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
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

  // ── Document actions ──────────────────────────────────────────────────────

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

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<VetRecord> _filterRecords(List<VetRecord> records) {
    var filtered = records;
    if (_selectedPetId != null) {
      filtered = filtered.where((r) => r.petId == _selectedPetId).toList();
    }
    if (_filterType != 'all') {
      filtered = filtered.where((r) => r.type == _filterType).toList();
    }
    return filtered;
  }

  Map<int, List<VetRecord>> _groupByYear(List<VetRecord> records) {
    final grouped = <int, List<VetRecord>>{};
    for (final record in records) {
      grouped.putIfAbsent(record.date.year, () => []).add(record);
    }
    return grouped;
  }

  void _showAddRecord(AsyncValue<List> petsAsync) {
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
            builder: (context) => AddEditRecordScreen(petId: _selectedPetId!),
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
                      builder: (context) => AddEditRecordScreen(petId: pet.id),
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

  void _showEditRecord(VetRecord record) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddEditRecordScreen(petId: record.petId, record: record),
      ),
    );
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
      case 'other':
        return 'Other';
      default:
        return 'All';
    }
  }
}

// ---------------------------------------------------------------------------
// Animated FAB
// ---------------------------------------------------------------------------

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
