import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/app_toast.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../contributions/models/contribution_models.dart';
import '../../contributions/services/contribution_service.dart';
import '../../events/providers/event_provider.dart';
import '../services/attendee_service.dart';
import '../widgets/attendee_display.dart';
import '../widgets/guest_edit_sheet.dart';

class GuestDetailScreen extends ConsumerWidget {
  const GuestDetailScreen({super.key, required this.attendeeId});

  final String attendeeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventId = ref.watch(activeEventIdProvider);

    if (eventId == null) {
      return const Scaffold(
        body: Center(child: Text('Select an event first')),
      );
    }

    final attendeesAsync = ref.watch(attendeesProvider(eventId));

    return attendeesAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8FAFC),
          foregroundColor: AppColors.onSurface,
          elevation: 0,
        ),
        body: Center(
          child: OutlinedButton(
            onPressed: () => ref.invalidate(attendeesProvider(eventId)),
            child: const Text('Try again'),
          ),
        ),
      ),
      data: (attendees) {
        AttendeeRecord? attendee;
        for (final item in attendees) {
          if (item.id == attendeeId) {
            attendee = item;
            break;
          }
        }

        if (attendee == null) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: const Color(0xFFF8FAFC),
              foregroundColor: AppColors.onSurface,
              elevation: 0,
            ),
            body: const Center(child: Text('Guest not found')),
          );
        }

        return _GuestDetailBody(
          eventId: eventId,
          attendee: attendee,
        );
      },
    );
  }
}

class _GuestDetailBody extends ConsumerStatefulWidget {
  const _GuestDetailBody({
    required this.eventId,
    required this.attendee,
  });

  final String eventId;
  final AttendeeRecord attendee;

  @override
  ConsumerState<_GuestDetailBody> createState() => _GuestDetailBodyState();
}

class _GuestDetailBodyState extends ConsumerState<_GuestDetailBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _busy = false;

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

  AttendeeRecord get _attendee => widget.attendee;

  List<SmsLogRecord> _guestLogs(List<SmsLogRecord> logs) {
    return logs
        .where(
          (log) =>
              log.attendeeId == _attendee.id ||
              log.phone == _attendee.phone,
        )
        .toList();
  }

  Future<void> _refresh() async {
    ref.invalidate(attendeesProvider(widget.eventId));
    ref.invalidate(smsLogsProvider(widget.eventId));
    await Future.wait([
      ref.read(attendeesProvider(widget.eventId).future),
      ref.read(smsLogsProvider(widget.eventId).future),
    ]);
  }

  Future<void> _editGuest() async {
    await showGuestEditSheet(
      context: context,
      ref: ref,
      attendee: _attendee,
    );
    if (mounted) await _refresh();
  }

  Future<void> _sendSms(String type) async {
    setState(() => _busy = true);
    try {
      final result = await ref.read(contributionServiceProvider).sendContributionSms(
            eventId: widget.eventId,
            type: type,
            attendeeIds: [_attendee.id],
          );
      ref.invalidate(smsBillingProvider(widget.eventId));
      ref.invalidate(smsCreditsProvider(widget.eventId));
      ref.invalidate(smsLogsProvider(widget.eventId));
      if (mounted) {
        if (!result.allowed) {
          AppToast.warning(
            result.error ?? 'No SMS credits available for this event',
          );
          return;
        }
        AppToast.success('Sent ${result.sent}, failed ${result.failed}');
      }
    } catch (_) {
      if (mounted) {
        AppToast.error('Failed to send SMS');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copyPhone() async {
    await Clipboard.setData(ClipboardData(text: _attendee.phone));
    if (mounted) {
      AppToast.info('Phone number copied');
    }
  }

  double get _progress {
    if (_attendee.targetAmountValue <= 0) return 0;
    return (_attendee.paidAmount / _attendee.targetAmountValue).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final status = _attendee.paymentStatus;
    final statusColor = contributionStatusColor(status);
    final statusLabel = contributionStatusLabel(status);
    final logsAsync = ref.watch(smsLogsProvider(widget.eventId));
    final guestLogs = logsAsync.maybeWhen(
      data: _guestLogs,
      orElse: () => <SmsLogRecord>[],
    );
    final smsSentCount =
        guestLogs.where((log) => log.status == 'sent').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton(
        onPressed: _busy ? null : _editGuest,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        tooltip: 'Edit guest',
        child: const Icon(Icons.edit_outlined),
      ),
      body: Column(
        children: [
          _GuestProfileHeader(
            name: _attendee.name,
            statusLabel: statusLabel,
            statusColor: statusColor,
            checkedIn: _attendee.checkedIn,
            amountPaid: _attendee.paidAmount,
            smsSentCount: smsSentCount,
            balance: _attendee.balanceAmount,
            hasTarget: _attendee.targetAmountValue > 0,
            onBack: () => context.pop(),
          ),
          Material(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.muted,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Payment'),
                Tab(text: 'SMS'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(
                  attendee: _attendee,
                  onRefresh: _refresh,
                  onCopyPhone: _copyPhone,
                ),
                _PaymentTab(
                  attendee: _attendee,
                  status: status,
                  statusColor: statusColor,
                  statusLabel: statusLabel,
                  progress: _progress,
                  busy: _busy,
                  onRefresh: _refresh,
                  onSendSms: _sendSms,
                ),
                _SmsTab(
                  logs: guestLogs,
                  loading: logsAsync.isLoading,
                  onRefresh: _refresh,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestProfileHeader extends StatelessWidget {
  const _GuestProfileHeader({
    required this.name,
    required this.statusLabel,
    required this.statusColor,
    required this.checkedIn,
    required this.amountPaid,
    required this.smsSentCount,
    required this.balance,
    required this.hasTarget,
    required this.onBack,
  });

  final String name;
  final String statusLabel;
  final Color statusColor;
  final bool checkedIn;
  final double amountPaid;
  final int smsSentCount;
  final double balance;
  final bool hasTarget;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withValues(alpha: 0.14),
            const Color(0xFFF8FAFC),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back),
                    color: AppColors.onSurface,
                  ),
                  const Expanded(
                    child: Text(
                      'Guest profile',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: Text(
                      guestInitials(name),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 28,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: checkedIn ? AppColors.success : AppColors.muted,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: _StatItem(
                      value: formatCompactAmount(amountPaid),
                      label: 'Amount paid',
                    ),
                  ),
                  Container(width: 1, height: 36, color: AppColors.border),
                  Expanded(
                    child: _StatItem(
                      value: '$smsSentCount',
                      label: 'SMS sent',
                    ),
                  ),
                  Container(width: 1, height: 36, color: AppColors.border),
                  Expanded(
                    child: _StatItem(
                      value: hasTarget
                          ? formatCompactAmount(balance)
                          : (checkedIn ? 'Yes' : 'No'),
                      label: hasTarget ? 'Balance' : 'Checked in',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.attendee,
    required this.onRefresh,
    required this.onCopyPhone,
  });

  final AttendeeRecord attendee;
  final Future<void> Function() onRefresh;
  final VoidCallback onCopyPhone;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
        children: [
          _SectionCard(
            title: 'Contact',
            icon: Icons.phone_outlined,
            children: [
              _DetailRow(
                label: 'Mobile number',
                value: '+${attendee.phone}',
                trailing: IconButton(
                  tooltip: 'Copy number',
                  onPressed: onCopyPhone,
                  icon: const Icon(Icons.copy_outlined, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Check-in',
            icon: Icons.qr_code_scanner_outlined,
            children: [
              _DetailRow(
                label: 'Status',
                value: attendee.checkedIn ? 'Checked in' : 'Not checked in',
                valueColor:
                    attendee.checkedIn ? AppColors.success : AppColors.muted,
              ),
              if (attendee.checkedInAt != null) ...[
                const SizedBox(height: 12),
                _DetailRow(
                  label: 'Checked in at',
                  value: DateFormatter.formatDateTime(attendee.checkedInAt),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Contribution',
            icon: Icons.category_outlined,
            children: [
              _DetailRow(
                label: 'Category',
                value: attendee.categoryName ?? 'Not assigned',
              ),
              if (attendee.targetAmountValue > 0) ...[
                const SizedBox(height: 12),
                _DetailRow(
                  label: 'Target amount',
                  value: formatTzsAmount(attendee.targetAmountValue),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'QR card',
            icon: Icons.qr_code_2_outlined,
            children: [
              _DetailRow(
                label: 'QR card SMS',
                value: attendee.qrActivatedAt != null ? 'Sent' : 'Not sent yet',
                valueColor: attendee.qrActivatedAt != null
                    ? AppColors.success
                    : AppColors.muted,
              ),
              if (attendee.qrActivatedAt != null) ...[
                const SizedBox(height: 12),
                _DetailRow(
                  label: 'Sent at',
                  value: DateFormatter.formatDateTime(attendee.qrActivatedAt),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentTab extends StatelessWidget {
  const _PaymentTab({
    required this.attendee,
    required this.status,
    required this.statusColor,
    required this.statusLabel,
    required this.progress,
    required this.busy,
    required this.onRefresh,
    required this.onSendSms,
  });

  final AttendeeRecord attendee;
  final ContributionPaymentStatus status;
  final Color statusColor;
  final String statusLabel;
  final double progress;
  final bool busy;
  final Future<void> Function() onRefresh;
  final Future<void> Function(String type) onSendSms;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
        children: [
          _SectionCard(
            title: 'Payment summary',
            icon: Icons.payments_outlined,
            children: [
              _DetailRow(
                label: 'Amount paid',
                value: formatTzsAmount(attendee.paidAmount),
                valueColor: AppColors.primary,
              ),
              if (attendee.targetAmountValue > 0) ...[
                const SizedBox(height: 12),
                _DetailRow(
                  label: 'Target amount',
                  value: formatTzsAmount(attendee.targetAmountValue),
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  label: 'Balance remaining',
                  value: formatTzsAmount(attendee.balanceAmount),
                  valueColor: attendee.balanceAmount > 0
                      ? AppColors.warning
                      : AppColors.success,
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: AppColors.border,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(progress * 100).round()}% of target paid',
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
              const SizedBox(height: 12),
              _DetailRow(
                label: 'Payment status',
                value: statusLabel,
                valueColor: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (busy)
            const Center(child: CircularProgressIndicator())
          else ...[
            if (status == ContributionPaymentStatus.partial ||
                status == ContributionPaymentStatus.unpaid)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => onSendSms('reminder'),
                  icon: const Icon(Icons.sms_outlined),
                  label: const Text('Send payment reminder'),
                ),
              ),
            if (status == ContributionPaymentStatus.paid)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => onSendSms('completion'),
                  icon: const Icon(Icons.qr_code_2_outlined),
                  label: const Text('Send QR card SMS'),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _SmsTab extends StatelessWidget {
  const _SmsTab({
    required this.logs,
    required this.loading,
    required this.onRefresh,
  });

  final List<SmsLogRecord> logs;
  final bool loading;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (loading && logs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (logs.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(
              child: Text(
                'No SMS sent to this guest yet',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
        itemCount: logs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _GuestSmsLogTile(log: logs[index]),
      ),
    );
  }
}

class _GuestSmsLogTile extends StatelessWidget {
  const _GuestSmsLogTile({required this.log});

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
                width: 8,
                height: 8,
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
            log.message,
            maxLines: 3,
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.trailing,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: valueColor ?? AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
