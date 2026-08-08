import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../services/contribution_service.dart';

Future<void> showSubmitSmsPaymentSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String eventId,
  required VoidCallback onSubmitted,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _SubmitSmsPaymentSheet(
      eventId: eventId,
      onSubmitted: onSubmitted,
    ),
  );
}

class _SubmitSmsPaymentSheet extends ConsumerStatefulWidget {
  const _SubmitSmsPaymentSheet({
    required this.eventId,
    required this.onSubmitted,
  });

  final String eventId;
  final VoidCallback onSubmitted;

  @override
  ConsumerState<_SubmitSmsPaymentSheet> createState() =>
      _SubmitSmsPaymentSheetState();
}

class _SubmitSmsPaymentSheetState
    extends ConsumerState<_SubmitSmsPaymentSheet> {
  final _amountController = TextEditingController(text: '5000');
  final _notesController = TextEditingController();
  PlatformFile? _selectedFile;
  bool _submitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int get _amountTzs => int.tryParse(_amountController.text.trim()) ?? 0;

  int get _smsCount => _amountTzs ~/ ApiConfig.smsPriceTzs;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
      withData: false,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _selectedFile = result.files.first);
    }
  }

  Future<void> _submit() async {
    if (_selectedFile?.path == null) {
      AppToast.warning('Attach proof of payment');
      return;
    }

    if (_amountTzs < ApiConfig.minSmsPurchaseTzs) {
      AppToast.warning(
        'Minimum payment is ${ApiConfig.minSmsPurchaseTzs} TZS',
      );
      return;
    }

    if (_smsCount < 1) {
      AppToast.warning('Amount is too low for SMS credits');
      return;
    }

    setState(() => _submitting = true);
    try {
      final service = ref.read(contributionServiceProvider);
      final result = await service.submitPaymentWithProof(
        eventId: widget.eventId,
        amountTzs: _amountTzs,
        filePath: _selectedFile!.path!,
        fileName: _selectedFile!.name,
        notes: _notesController.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onSubmitted();
      AppToast.success(result.message);
    } catch (error) {
      if (!mounted) return;
      final message = error is DioException
          ? (error.response?.data is Map
                ? (error.response!.data as Map)['error']?.toString()
                : null) ??
              error.message ??
              'Failed to submit payment'
          : error.toString().replaceFirst('Exception: ', '');
      AppToast.error(message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 12, 24, bottomInset + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 20),
          Text(
            'Buy SMS credits',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload proof of payment. Credits are granted after admin approval at ${ApiConfig.smsPriceTzs} TZS per SMS.',
            style: const TextStyle(color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Amount (TZS)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '≈ $_smsCount SMS credits',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _submitting ? null : _pickFile,
            icon: const Icon(Icons.attach_file_rounded),
            label: Text(
              _selectedFile?.name ?? 'Attach proof (JPG, PNG, PDF)',
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Notes (optional)',
              hintText: 'Reference number, payer name...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Submit for review'),
          ),
        ],
      ),
    );
  }
}
