import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/date_formatter.dart';
import '../../events/providers/event_provider.dart';
import '../models/contribution_models.dart';
import '../services/contribution_service.dart';
import '../widgets/sms_actions_fab.dart';
import '../widgets/sms_compose_sheet.dart';
import '../widgets/sms_template_sheet.dart';
import '../widgets/submit_sms_payment_sheet.dart';

class SmsBillingScreen extends ConsumerStatefulWidget {
  const SmsBillingScreen({super.key});

  @override
  ConsumerState<SmsBillingScreen> createState() => _SmsBillingScreenState();
}

class _SmsBillingScreenState extends ConsumerState<SmsBillingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh(String eventId) async {
    ref.invalidate(smsCreditsProvider(eventId));
    ref.invalidate(smsBillingProvider(eventId));
    ref.invalidate(smsLogsProvider(eventId));
    ref.invalidate(smsPaymentsProvider(eventId));
    ref.invalidate(smsTemplatesProvider(eventId));
    await Future.wait([
      ref.read(smsCreditsProvider(eventId).future),
      ref.read(smsBillingProvider(eventId).future),
      ref.read(smsLogsProvider(eventId).future),
      ref.read(smsPaymentsProvider(eventId).future).catchError((_) => <PaymentSubmissionRecord>[]),
      ref.read(smsTemplatesProvider(eventId).future).catchError((_) => <SmsTemplate>[]),
    ]);
  }

  void _openPaymentSheet(String eventId) {
    showSubmitSmsPaymentSheet(
      context: context,
      ref: ref,
      eventId: eventId,
      onSubmitted: () async {
        await _refresh(eventId);
        if (mounted) _tabController.animateTo(1);
      },
    );
  }

  void _openTemplateSheet(String eventId, {SmsTemplate? template}) {
    showSmsTemplateSheet(
      context: context,
      eventId: eventId,
      template: template,
    ).then((_) {
      if (mounted) ref.invalidate(smsTemplatesProvider(eventId));
    });
  }

  void _openBroadcastSheet(String eventId) {
    showSmsComposeSheet(
      context: context,
      ref: ref,
      eventId: eventId,
      mode: SmsComposeMode.broadcast,
      onSent: () => _refresh(eventId),
    );
  }

  void _openIndividualSheet(String eventId) {
    showSmsComposeSheet(
      context: context,
      ref: ref,
      eventId: eventId,
      mode: SmsComposeMode.individual,
      onSent: () => _refresh(eventId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventId = ref.watch(activeEventIdProvider);
    if (eventId == null) {
      return const Scaffold(
        body: Center(child: Text('Select an event first')),
      );
    }

    final creditsAsync = ref.watch(smsCreditsProvider(eventId));
    final billingAsync = ref.watch(smsBillingProvider(eventId));
    final logsAsync = ref.watch(smsLogsProvider(eventId));
    final paymentsAsync = ref.watch(smsPaymentsProvider(eventId));
    final templatesAsync = ref.watch(smsTemplatesProvider(eventId));

    final isLoading =
        creditsAsync.isLoading || billingAsync.isLoading || logsAsync.isLoading;

    final hasError =
        creditsAsync.hasError || billingAsync.hasError || logsAsync.hasError;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'SMS billing',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.onSurface),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : hasError
                    ? Center(
                        child: OutlinedButton(
                          onPressed: () => _refresh(eventId),
                          child: const Text('Try again'),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                            child: _StatsRow(
                              credits: creditsAsync.requireValue,
                              billing: billingAsync.requireValue,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TabBar(
                            controller: _tabController,
                            labelColor: AppColors.primary,
                            unselectedLabelColor: AppColors.muted,
                            indicatorColor: AppColors.primary,
                            indicatorWeight: 3,
                            labelStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                            tabs: const [
                              Tab(text: 'Message log'),
                              Tab(text: 'Payment history'),
                              Tab(text: 'Templates'),
                            ],
                          ),
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _LogsTab(
                                  logs: logsAsync.valueOrNull ?? [],
                                  onRefresh: () => _refresh(eventId),
                                ),
                                _PaymentsTab(
                                  paymentsAsync: paymentsAsync,
                                  onRefresh: () => _refresh(eventId),
                                ),
                                _TemplatesTab(
                                  templatesAsync: templatesAsync,
                                  onRefresh: () => _refresh(eventId),
                                  onAddTemplate: () => _openTemplateSheet(eventId),
                                  onEditTemplate: (template) =>
                                      _openTemplateSheet(eventId, template: template),
                                  onDeleteTemplate: (templateId) async {
                                    try {
                                      await ref
                                          .read(contributionServiceProvider)
                                          .deleteSmsTemplate(templateId);
                                      ref.invalidate(smsTemplatesProvider(eventId));
                                    } catch (_) {
                                      if (context.mounted) {
                                        AppToast.error('Failed to delete template');
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: SmsActionsFab(
              onBuySms: () => _openPaymentSheet(eventId),
              onBroadcastSms: () => _openBroadcastSheet(eventId),
              onIndividualSms: () => _openIndividualSheet(eventId),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.credits,
    required this.billing,
  });

  final SmsCreditsSummary credits;
  final SmsBillingSummary billing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Available',
            value: '${credits.available}',
            icon: Icons.sms_outlined,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Sent',
            value: '${billing.totalSent}',
            icon: Icons.check_circle_outline,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Failed',
            value: '${billing.totalFailed}',
            icon: Icons.error_outline,
            color: AppColors.danger,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogsTab extends StatelessWidget {
  const _LogsTab({
    required this.logs,
    required this.onRefresh,
  });

  final List<SmsLogRecord> logs;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: const [
            _EmptyState(
              icon: Icons.inbox_outlined,
              message: 'No messages sent yet',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        itemCount: logs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _LogTile(log: logs[index]),
      ),
    );
  }
}

class _TemplatesTab extends StatelessWidget {
  const _TemplatesTab({
    required this.templatesAsync,
    required this.onRefresh,
    required this.onAddTemplate,
    required this.onEditTemplate,
    required this.onDeleteTemplate,
  });

  final AsyncValue<List<SmsTemplate>> templatesAsync;
  final Future<void> Function() onRefresh;
  final VoidCallback onAddTemplate;
  final void Function(SmsTemplate template) onEditTemplate;
  final Future<void> Function(String templateId) onDeleteTemplate;

  @override
  Widget build(BuildContext context) {
    return templatesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: OutlinedButton(
          onPressed: onRefresh,
          child: const Text('Try again'),
        ),
      ),
      data: (templates) {
        if (templates.isEmpty) {
          return RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              children: [
                const SizedBox(height: 48),
                const _EmptyState(
                  icon: Icons.article_outlined,
                  message:
                      'No SMS templates yet.\nCreate one to customize your messages.',
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onAddTemplate,
                  icon: const Icon(Icons.add),
                  label: const Text('Add SMS template'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            itemCount: templates.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              if (index == 0) {
                return OutlinedButton.icon(
                  onPressed: onAddTemplate,
                  icon: const Icon(Icons.add),
                  label: const Text('Add template'),
                );
              }

              final template = templates[index - 1];
              return _TemplateTile(
                template: template,
                onEdit: () => onEditTemplate(template),
                onDelete: () => onDeleteTemplate(template.id),
              );
            },
          ),
        );
      },
    );
  }
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.template,
    required this.onEdit,
    required this.onDelete,
  });

  final SmsTemplate template;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  template.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Edit',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 20),
              ),
              IconButton(
                tooltip: 'Delete',
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.danger,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            template.body,
            style: const TextStyle(
              color: AppColors.onSurface,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentsTab extends StatelessWidget {
  const _PaymentsTab({
    required this.paymentsAsync,
    required this.onRefresh,
  });

  final AsyncValue<List<PaymentSubmissionRecord>> paymentsAsync;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return paymentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: OutlinedButton(
          onPressed: onRefresh,
          child: const Text('Try again'),
        ),
      ),
      data: (payments) {
        if (payments.isEmpty) {
          return RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              children: const [
                _EmptyState(
                  icon: Icons.payments_outlined,
                  message: 'No payment submissions yet',
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            itemCount: payments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) =>
                _PaymentTile(payment: payments[index]),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.muted, size: 32),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.log});

  final SmsLogRecord log;

  Color get _statusColor {
    switch (log.status) {
      case 'sent':
        return AppColors.success;
      case 'failed':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }

  String get _statusLabel {
    switch (log.status) {
      case 'sent':
        return 'Sent';
      case 'failed':
        return 'Failed';
      default:
        return 'Pending';
    }
  }

  String get _typeLabel {
    switch (log.smsType) {
      case 'reminder':
        return 'Reminder';
      case 'completion':
        return 'QR card';
      case 'broadcast':
        return 'Broadcast';
      default:
        return log.smsType ?? 'SMS';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _statusLabel,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _statusColor,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.border.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _typeLabel,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ),
              const Spacer(),
              Text(
                DateFormatter.formatDateTime(log.sentAt),
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            log.attendeeName ?? 'Unknown guest',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          if (log.phone != null) ...[
            const SizedBox(height: 2),
            Text(log.phone!, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          ],
          const SizedBox(height: 8),
          Text(
            log.message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.onSurface, height: 1.35),
          ),
          if (log.status == 'failed' && log.providerError != null) ...[
            const SizedBox(height: 8),
            Text(
              log.providerError!,
              style: const TextStyle(color: AppColors.danger, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.payment});

  final PaymentSubmissionRecord payment;

  Color get _statusColor {
    switch (payment.status) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.payments_outlined, color: _statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TZS ${payment.amountTzs} • ${payment.smsCount} SMS',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormatter.formatDateTime(payment.createdAt),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                if (payment.reviewNotes != null &&
                    payment.reviewNotes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    payment.reviewNotes!,
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              payment.status[0].toUpperCase() + payment.status.substring(1),
              style: TextStyle(
                color: _statusColor,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
