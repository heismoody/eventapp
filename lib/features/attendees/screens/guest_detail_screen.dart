import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/app_toast.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/guest_result_sheet.dart';
import '../../auth/providers/auth_provider.dart';
import '../../events/providers/event_provider.dart';
import '../../scanner/providers/scanner_provider.dart';
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
      return const Scaffold(body: Center(child: Text('Select an event first')));
    }

    final attendeesAsync = ref.watch(attendeesProvider(eventId));

    return attendeesAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
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

        return _GuestDetailBody(eventId: eventId, attendee: attendee);
      },
    );
  }
}

class _GuestDetailBody extends ConsumerStatefulWidget {
  const _GuestDetailBody({required this.eventId, required this.attendee});

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
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  AttendeeRecord get _attendee => widget.attendee;

  Future<void> _refresh() async {
    ref.invalidate(attendeesProvider(widget.eventId));
    await ref.read(attendeesProvider(widget.eventId).future);
  }

  Future<void> _editGuest() async {
    await showGuestEditSheet(context: context, ref: ref, attendee: _attendee);
    if (mounted) await _refresh();
  }

  Future<void> _manualCheckIn() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Check in without QR?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _attendee.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              _attendee.phone,
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            Text(
              _attendee.categoryName ?? 'No category',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Confirm this is the person at the door. This will be recorded '
              'as a manual check-in.',
              style: TextStyle(color: AppColors.muted, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Check in'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final result = await ref.read(scannerProvider).manualCheckIn(_attendee);
      ref.invalidate(pendingSyncCountProvider);
      ref.invalidate(checkinCountProvider(widget.eventId));
      ref.invalidate(recentCheckinsProvider(widget.eventId));
      ref.invalidate(attendeesProvider(widget.eventId));
      if (!mounted) return;
      await showGuestResultSheet(context, result: result);
    } catch (_) {
      if (mounted) AppToast.error('Check-in failed. Try again.');
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
            balance: _attendee.balanceAmount,
            hasTarget: _attendee.targetAmountValue > 0,
            onBack: () => context.pop(),
          ),
          if (ref.watch(currentUserProvider)?.canCheckIn == true &&
              !_attendee.checkedIn)
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: FilledButton.icon(
                onPressed: _busy ? null : _manualCheckIn,
                icon: const Icon(Icons.how_to_reg_outlined),
                label: const Text('Check in guest'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: AppColors.success,
                ),
              ),
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
                  statusColor: statusColor,
                  statusLabel: statusLabel,
                  progress: _progress,
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
    required this.balance,
    required this.hasTarget,
    required this.onBack,
  });

  final String name;
  final String statusLabel;
  final Color statusColor;
  final bool checkedIn;
  final double amountPaid;
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
                valueColor: attendee.checkedIn
                    ? AppColors.success
                    : AppColors.muted,
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
                label: 'QR card message',
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
    required this.statusColor,
    required this.statusLabel,
    required this.progress,
    required this.onRefresh,
  });

  final AttendeeRecord attendee;
  final Color statusColor;
  final String statusLabel;
  final double progress;
  final Future<void> Function() onRefresh;

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
