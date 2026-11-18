import 'dart:typed_data';
import 'dart:ui' show ImageFilter;

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/services/connectivity_service.dart';
import '../../contributions/services/contribution_service.dart';

/// Guests from an Excel or CSV file. The portal reads the file (the same
/// rules as its own Import button): first a preview of what would happen,
/// then the import. Returns true when guests were added.
Future<bool?> showExcelImportSheet({
  required BuildContext context,
  required String eventId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _ExcelImportSheet(eventId: eventId),
  );
}

const _maxBytes = 2 * 1024 * 1024;

class _PickedFile {
  const _PickedFile(this.name, this.bytes);

  final String name;
  final List<int> bytes;
}

class _GuestRow {
  _GuestRow.fromJson(Map<String, dynamic> json)
    : rowNumber = (json['rowNumber'] as num?)?.toInt() ?? 0,
      name = json['name'] as String? ?? '',
      phone = json['phone'] as String? ?? '',
      category = json['category'] as String?,
      admits = (json['admits'] as num?)?.toInt(),
      companions = (json['companions'] as num?)?.toInt() ?? 0;

  final int rowNumber;
  final String name;
  final String phone;
  final String? category;
  final int? admits;
  final int companions;
}

class _BadRow {
  _BadRow.fromJson(Map<String, dynamic> json)
    : rowNumber = (json['rowNumber'] as num?)?.toInt() ?? 0,
      name = json['name'] as String?,
      error = json['error'] as String? ?? '';

  final int rowNumber;
  final String? name;
  final String error;
}

class _Preview {
  _Preview.fromJson(Map<String, dynamic> json)
    : toAdd = (json['toAdd'] as num?)?.toInt() ?? 0,
      sample = _list(json['sample'], _GuestRow.fromJson),
      duplicates = (json['duplicates'] as num?)?.toInt() ?? 0,
      duplicateRows = _list(json['duplicateRows'], _GuestRow.fromJson),
      invalid = (json['invalid'] as num?)?.toInt() ?? 0,
      invalidRows = _list(json['invalidRows'], _BadRow.fromJson),
      newCategories = (json['newCategories'] as List? ?? const [])
          .whereType<String>()
          .toList();

  final int toAdd;
  final List<_GuestRow> sample;
  final int duplicates;
  final List<_GuestRow> duplicateRows;
  final int invalid;
  final List<_BadRow> invalidRows;
  final List<String> newCategories;

  static List<T> _list<T>(
    Object? raw,
    T Function(Map<String, dynamic>) parse,
  ) => (raw as List? ?? const [])
      .whereType<Map<String, dynamic>>()
      .map(parse)
      .toList();
}

class _ExcelImportSheet extends ConsumerStatefulWidget {
  const _ExcelImportSheet({required this.eventId});

  final String eventId;

  @override
  ConsumerState<_ExcelImportSheet> createState() => _ExcelImportSheetState();
}

class _ExcelImportSheetState extends ConsumerState<_ExcelImportSheet> {
  _PickedFile? _file;
  _Preview? _preview;
  bool _reading = false;
  bool _importing = false;
  bool _savingSample = false;
  String? _error;

  Future<void> _downloadSample() async {
    if (!await _online() || !mounted) return;
    final l10n = context.l10n;
    setState(() => _savingSample = true);
    try {
      final response = await ref
          .read(apiClientProvider)
          .get<List<int>>(
            ApiConfig.attendeesImportTemplatePath,
            options: Options(responseType: ResponseType.bytes),
          );
      final saved = await FilePicker.platform.saveFile(
        dialogTitle: l10n.downloadSampleSheet,
        fileName: 'cardly-guest-list.xlsx',
        type: FileType.custom,
        allowedExtensions: const ['xlsx'],
        bytes: Uint8List.fromList(response.data ?? const []),
      );
      if (saved != null && mounted) AppToast.success(l10n.sampleSheetSaved);
    } catch (_) {
      if (mounted) AppToast.error(l10n.sampleSheetFailed);
    } finally {
      if (mounted) setState(() => _savingSample = false);
    }
  }

  Future<bool> _online() async {
    final online = await ref.read(connectivityServiceProvider).isOnline();
    if (!online && mounted) AppToast.warning(context.l10n.importNeedsInternet);
    return online;
  }

  Future<void> _choose() async {
    final l10n = context.l10n;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx', 'xls', 'csv'],
      withData: true,
    );
    final picked = result?.files.single;
    if (picked == null || !mounted) return;
    final bytes = picked.bytes;
    if (bytes == null) {
      setState(() => _error = l10n.excelReadFailed);
      return;
    }
    if (bytes.length > _maxBytes) {
      setState(() => _error = l10n.excelFileTooBig);
      return;
    }
    final file = _PickedFile(picked.name, bytes);
    setState(() {
      _file = file;
      _preview = null;
      _error = null;
    });
    if (!await _online()) return;
    await _readPreview(file);
  }

  Future<Map<String, dynamic>> _send(_PickedFile file, String mode) async {
    final dio = ref.read(apiClientProvider);
    final response = await dio.post(
      ApiConfig.attendeesImportFilePath,
      data: FormData.fromMap({
        'eventId': widget.eventId,
        'mode': mode,
        'file': MultipartFile.fromBytes(file.bytes, filename: file.name),
      }),
    );
    return response.data as Map<String, dynamic>;
  }

  String _explain(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['error'] is String) return data['error'];
      if (error.response == null) return context.l10n.importNeedsInternet;
    }
    return context.l10n.excelReadFailed;
  }

  Future<void> _readPreview(_PickedFile file) async {
    setState(() => _reading = true);
    try {
      final preview = _Preview.fromJson(await _send(file, 'preview'));
      if (mounted) setState(() => _preview = preview);
    } catch (error) {
      if (mounted) setState(() => _error = _explain(error));
    } finally {
      if (mounted) setState(() => _reading = false);
    }
  }

  Future<void> _import() async {
    final file = _file;
    if (file == null || !await _online()) return;
    setState(() {
      _importing = true;
      _error = null;
    });
    try {
      final data = await _send(file, 'import');
      ref.invalidate(contributionCategoriesProvider(widget.eventId));
      if (!mounted) return;
      AppToast.success(
        context.l10n.excelImported((data['inserted'] as num?)?.toInt() ?? 0),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = _explain(error));
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final preview = _preview;
    final busy = _reading || _importing;

    final Widget body;
    if (_reading) {
      body = _Reading(fileName: _file?.name ?? '');
    } else if (preview != null) {
      body = _PreviewView(
        fileName: _file!.name,
        preview: preview,
        onChooseAnother: busy ? null : _choose,
      );
    } else {
      body = const _ColumnGuide();
    }

    final Widget action = preview != null && !_reading
        ? FilledButton(
            onPressed: busy || preview.toAdd == 0 ? null : _import,
            child: _importing
                ? Text(l10n.importing)
                : Text(l10n.excelImportCount(preview.toAdd)),
          )
        : Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: busy ? null : _choose,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: Text(l10n.chooseFile),
                ),
              ),
              const SizedBox(width: 10),
              Tooltip(
                message: l10n.downloadSampleSheet,
                child: OutlinedButton.icon(
                  onPressed: busy || _savingSample ? null : _downloadSample,
                  icon: _savingSample
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_rounded),
                  label: Text(l10n.sampleSheet),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    foregroundColor: AppColors.primary,
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.55),
                      width: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          );

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
            child: Text(
              l10n.importFromExcel,
              style: theme.textTheme.titleLarge,
            ),
          ),
          Flexible(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: KeyedSubtree(
                key: ValueKey(
                  _reading
                      ? 'reading'
                      : (preview == null ? 'guide' : 'preview'),
                ),
                child: body,
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: _Notice(text: _error!, color: AppColors.danger),
            ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            child: SizedBox(height: 52, child: action),
          ),
        ],
      ),
    );
  }
}

/// What the file should look like, before one is chosen.
class _ColumnGuide extends StatelessWidget {
  const _ColumnGuide();

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
      children: [
        Text(
          context.l10n.excelImportLead,
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 16),
        const _SheetSketch(),
      ],
    );
  }
}

class _Reading extends StatelessWidget {
  const _Reading({required this.fileName});

  final String fileName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            context.l10n.readingFile(fileName),
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _PreviewView extends StatelessWidget {
  const _PreviewView({
    required this.fileName,
    required this.preview,
    required this.onChooseAnother,
  });

  final String fileName;
  final _Preview preview;
  final VoidCallback? onChooseAnother;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final more = preview.toAdd - preview.sample.length;

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
      children: [
        Row(
          children: [
            Icon(Icons.description_outlined, size: 20, color: AppColors.muted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.muted),
              ),
            ),
            TextButton(
              onPressed: onChooseAnother,
              child: Text(l10n.chooseAnotherFile),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          l10n.excelWillAdd(preview.toAdd),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (preview.sample.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final row in preview.sample) _GuestLine(row: row),
          if (more > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n.excelMoreRows(more),
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ),
        ],
        if (preview.newCategories.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            l10n.excelNewCategories,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final name in preview.newCategories)
                Chip(
                  label: Text(name),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: AppColors.chipFill,
                  side: BorderSide.none,
                ),
            ],
          ),
        ],
        if (preview.duplicates > 0) ...[
          const SizedBox(height: 14),
          _Section(
            title: l10n.excelDuplicates(preview.duplicates),
            hint: l10n.excelDuplicatesHint,
            color: AppColors.warning,
            children: [
              for (final row in preview.duplicateRows)
                _RowLine(
                  rowNumber: row.rowNumber,
                  title: row.name,
                  detail: row.phone,
                ),
            ],
          ),
        ],
        if (preview.invalid > 0) ...[
          const SizedBox(height: 10),
          _Section(
            title: l10n.excelProblems(preview.invalid),
            hint: l10n.excelProblemsHint,
            color: AppColors.danger,
            initiallyExpanded: preview.toAdd == 0,
            children: [
              for (final row in preview.invalidRows)
                _RowLine(
                  rowNumber: row.rowNumber,
                  title: row.error,
                  detail: row.name,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _GuestLine extends StatelessWidget {
  const _GuestLine({required this.row});

  final _GuestRow row;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final extras = [
      if (row.category != null) row.category!,
      if (row.admits != null) l10n.admitsPeople(row.admits!),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  row.phone,
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          if (extras.isNotEmpty)
            Text(
              extras.join(', '),
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
        ],
      ),
    );
  }
}

/// Skipped rows, folded away until asked for.
class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.hint,
    required this.color,
    required this.children,
    this.initiallyExpanded = false,
  });

  final String title;
  final String hint;
  final Color color;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    return Material(
      color: color.withValues(alpha: 0.08),
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        shape: shape,
        collapsedShape: shape,
        tilePadding: const EdgeInsets.symmetric(horizontal: 14),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        leading: Icon(Icons.info_outline_rounded, color: color),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600, color: color),
        ),
        subtitle: Text(
          hint,
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        children: children,
      ),
    );
  }
}

class _RowLine extends StatelessWidget {
  const _RowLine({required this.rowNumber, required this.title, this.detail});

  final int rowNumber;
  final String title;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              context.l10n.excelRow(rowNumber),
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14)),
                if (detail != null && detail!.isNotEmpty)
                  Text(
                    detail!,
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(color: color)),
          ),
        ],
      ),
    );
  }
}

/// A sketch of the import template, like the portal's Import dialog: Name,
/// Phone, Category and People, then Companions with Name and Phone under
/// it. A guest's cells run down beside each of their companions' rows.
class _SheetSketch extends StatelessWidget {
  const _SheetSketch();

  /// One entry per guest: each companion, true when they have a phone.
  static const _guests = [
    [true, false],
    [true],
    [true, false, false],
    <bool>[],
  ];
  static const _row = 12.0;
  static const _blurBands = 12;
  static const _bandHeight = 8.0;
  static const _gap = 5.0;

  @override
  Widget build(BuildContext context) {
    Widget header(String label, {bool sub = false, double? height}) =>
        Container(
          height: height,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.secondaryAlt.withValues(alpha: sub ? 0.6 : 1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        );

    Widget bar() => Container(
      height: 5,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(3),
      ),
    );

    Widget cell(double height) => Container(
      height: height,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(3),
      ),
      child: bar(),
    );

    Widget gapped(List<Widget> children, {Axis axis = Axis.horizontal}) {
      final spaced = <Widget>[];
      for (final (i, child) in children.indexed) {
        if (i > 0) {
          spaced.add(
            axis == Axis.horizontal
                ? const SizedBox(width: _gap)
                : const SizedBox(height: _gap),
          );
        }
        spaced.add(axis == Axis.horizontal ? Expanded(child: child) : child);
      }
      return axis == Axis.horizontal
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: spaced)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: spaced,
            );
    }

    const headerTall = 46.0;
    final rows = <Widget>[];
    for (final (i, companions) in _guests.indexed) {
      final span = companions.isEmpty ? 1 : companions.length;
      final height = span * _row + (span - 1) * _gap;
      rows.add(
        Opacity(
          opacity: (1 - i * 0.2).clamp(0.2, 1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: gapped([for (var c = 0; c < 4; c++) cell(height)]),
              ),
              const SizedBox(width: _gap),
              Expanded(
                flex: 2,
                child: gapped([
                  for (var r = 0; r < span; r++)
                    SizedBox(
                      height: _row,
                      child: gapped([
                        r < companions.length
                            ? Center(child: bar())
                            : const SizedBox(),
                        r < companions.length && companions[r]
                            ? Center(child: bar())
                            : const SizedBox(),
                      ]),
                    ),
                ], axis: Axis.vertical),
              ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Stack(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
              child: Stack(
                children: [
                  Positioned(
                    left: 10,
                    right: 10,
                    top: 10,
                    bottom: 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 0),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(10),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow.withValues(alpha: 0.18),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: AppColors.border),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(width: 72, child: bar()),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: gapped([
                                      for (final label in const [
                                        'Name',
                                        'Phone',
                                        'Category',
                                        'People',
                                      ])
                                        header(label, height: headerTall),
                                    ]),
                                  ),
                                  const SizedBox(width: _gap),
                                  Expanded(
                                    flex: 2,
                                    child: SizedBox(
                                      height: headerTall,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Expanded(child: header('Companions')),
                                          const SizedBox(height: _gap),
                                          Expanded(
                                            child: gapped([
                                              header('Name', sub: true),
                                              header('Phone', sub: true),
                                            ]),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: _gap),
                              gapped(rows, axis: Axis.vertical),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Like the portal: the lower rows blur and fade into the sheet,
          // across the panel's full width, stopping short of the headers.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: _blurBands * _bandHeight,
            child: IgnorePointer(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // A blur that builds up gradually: thin bands, each a
                  // little stronger than the one above, so there's no
                  // visible edge where it starts.
                  for (var band = 0; band < _blurBands; band++)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: band * _bandHeight,
                      height: _bandHeight,
                      child: ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: (band + 1) * 0.3,
                            sigmaY: (band + 1) * 0.3,
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          AppColors.surfaceRaised,
                          AppColors.surfaceRaised.withValues(alpha: 0.85),
                          AppColors.surfaceRaised.withValues(alpha: 0),
                        ],
                        stops: const [0, 0.35, 1],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
