import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../../shared/widgets/category_donut_chart.dart';
import '../../../shared/widgets/summary_stat_row.dart';
import '../../attendees/services/attendee_service.dart';
import '../../attendees/widgets/attendee_display.dart';
import '../../events/providers/event_provider.dart';
import '../models/event_report.dart';
import '../services/report_service.dart';
import '../widgets/report_pdf_builder.dart';

class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventId = ref.watch(activeEventIdProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Event Report',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: eventId == null
          ? const Center(child: Text('Select an event first'))
          : _ReportBody(eventId: eventId),
    );
  }
}

class _ReportBody extends ConsumerWidget {
  const _ReportBody({required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(eventReportProvider(eventId));

    return reportAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 34),
            const SizedBox(height: 12),
            const Text('Failed to load the report'),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => ref.invalidate(eventReportProvider(eventId)),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
      data: (report) => _ReportContent(eventId: eventId, report: report),
    );
  }
}

class _ReportContent extends ConsumerStatefulWidget {
  const _ReportContent({required this.eventId, required this.report});

  final String eventId;
  final EventReport report;

  @override
  ConsumerState<_ReportContent> createState() => _ReportContentState();
}

class _ReportContentState extends ConsumerState<_ReportContent>
    with SingleTickerProviderStateMixin {
  bool _exporting = false;
  bool _includeParticipants = false;
  late TabController _tabController;

  List<_ReportTab> get _tabs {
    final report = widget.report;
    return [
      _ReportTab('Attendance', _AttendanceTab(report: report)),
      if (report.contributions != null)
        _ReportTab(
          'Contribution',
          _ContributionsSection(contributions: report.contributions!),
        ),
      if (report.messaging != null)
        _ReportTab(
          'Messaging',
          _MessagingSection(messaging: report.messaging!),
        ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _downloadPdf() async {
    setState(() => _exporting = true);
    try {
      List<AttendeeRecord>? attendees;
      if (_includeParticipants) {
        attendees = await ref.read(attendeesProvider(widget.eventId).future);
      }

      final bytes = await buildEventReportPdf(
        widget.report,
        attendees: attendees,
      );
      final safeName = widget.report.event.name.toLowerCase().replaceAll(
        RegExp(r'[^a-z0-9]+'),
        '-',
      );

      // Lets the user pick where the file is actually saved on-device
      // (Downloads, Files app, etc.) — the share sheet used before only
      // offers "send to an app", not a real save/download.
      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save report',
        fileName: 'event-report-$safeName.pdf',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        bytes: bytes,
      );

      if (mounted && savedPath != null) {
        AppToast.success('Report saved');
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final dateFmt = DateFormat('d MMM yyyy, h:mm a');
    final tabs = _tabs;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.event.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    dateFmt.format(report.event.date.toLocal()),
                    if (report.event.venue != null &&
                        report.event.venue!.isNotEmpty)
                      report.event.venue!,
                  ].join(' · '),
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: _ReportTabBar(controller: _tabController, tabs: tabs),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                for (final tab in tabs)
                  ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    children: [tab.child],
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 20, 0),
            child: InkWell(
              onTap: () =>
                  setState(() => _includeParticipants = !_includeParticipants),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  Checkbox(
                    value: _includeParticipants,
                    activeColor: AppColors.primary,
                    onChanged: (value) =>
                        setState(() => _includeParticipants = value ?? false),
                  ),
                  const Expanded(
                    child: Text(
                      'Include all participants',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _exporting ? null : _downloadPdf,
                icon: _exporting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.picture_as_pdf_outlined),
                label: Text(_exporting ? 'Preparing PDF…' : 'Download PDF'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A hand-built tab row (rather than [TabBar]'s default equal-width-segment
/// layout) so each tab hugs its own label width and the group is spread
/// across the row with even gaps between them, like CSS's space-between.
class _ReportTabBar extends StatelessWidget {
  const _ReportTabBar({required this.controller, required this.tabs});

  final TabController controller;
  final List<_ReportTab> tabs;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < tabs.length; i++)
              GestureDetector(
                onTap: () => controller.animateTo(i),
                behavior: HitTestBehavior.opaque,
                child: IntrinsicWidth(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        tabs[i].label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: controller.index == i
                              ? AppColors.primary
                              : AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: controller.index == i
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ReportTab {
  const _ReportTab(this.label, this.child);

  final String label;
  final Widget child;
}

class _AttendanceTab extends StatelessWidget {
  const _AttendanceTab({required this.report});

  final EventReport report;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMM yyyy, h:mm a');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ReportSectionTitle('Overview'),
        SummaryStatRow(
          items: [
            SummaryStatItem(
              icon: Icons.people_outline,
              label: 'Registered',
              value: '${report.totals.registered}',
              accent: AppColors.primary,
            ),
            SummaryStatItem(
              icon: Icons.login_rounded,
              label: 'Checked in',
              value: '${report.totals.checkedIn}',
              accent: AppColors.success,
            ),
            SummaryStatItem(
              icon: Icons.percent_rounded,
              label: 'Check-in rate',
              value: '${report.totals.checkInRate.round()}%',
              accent: AppColors.accent,
            ),
          ],
        ),
        const SizedBox(height: 20),
        SummaryStatRow(
          items: [
            SummaryStatItem(
              icon: Icons.person_off_outlined,
              label: 'Not checked in',
              value: '${report.totals.notCheckedIn}',
              accent: AppColors.warning,
            ),
            SummaryStatItem(
              icon: Icons.badge_outlined,
              label: 'Cards assigned',
              value: '${report.totals.cardsAssigned}',
              accent: AppColors.primary,
            ),
            SummaryStatItem(
              icon: Icons.qr_code_outlined,
              label: 'Cards activated',
              value: '${report.totals.cardsActivated}',
              accent: AppColors.accent,
            ),
          ],
        ),

        if (report.categories.isNotEmpty) ...[
          const SizedBox(height: 24),
          _ReportSectionTitle('By category'),
          _CategoryTable(categories: report.categories),
        ],

        const SizedBox(height: 24),
        _ReportSectionTitle('Timeline'),
        _TimelineRow(
          label: 'Check-ins',
          timeline: report.checkIns,
          dateFmt: dateFmt,
        ),
        const SizedBox(height: 10),
        _TimelineRow(
          label: 'Registrations',
          timeline: report.registrations,
          dateFmt: dateFmt,
        ),
      ],
    );
  }
}

class _ReportSectionTitle extends StatelessWidget {
  const _ReportSectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 15,
          color: AppColors.onSurface,
        ),
      ),
    );
  }
}

class _CategoryTable extends StatelessWidget {
  const _CategoryTable({required this.categories});

  final List<ReportCategoryRow> categories;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < categories.length; i++) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: categoryPalette[i % categoryPalette.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    categories[i].name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
                Text(
                  '${categories[i].checkedIn}/${categories[i].attendees}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
          if (i < categories.length - 1)
            Divider(height: 1, color: AppColors.border.withValues(alpha: 0.6)),
        ],
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.label,
    required this.timeline,
    required this.dateFmt,
  });

  final String label;
  final ReportTimeline timeline;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    final first = timeline.first;
    final last = timeline.last;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              first == null || last == null
                  ? 'No activity yet'
                  : '${dateFmt.format(first.toLocal())} — ${dateFmt.format(last.toLocal())}',
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessagingSection extends StatelessWidget {
  const _MessagingSection({required this.messaging});

  final ReportMessaging messaging;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final channel in messaging.channels) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        channel.channel == 'sms' ? 'SMS' : 'WhatsApp',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      '${channel.sent} sent · ${channel.failed} failed · '
                      '${channel.available} credits left',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              Text(
                '${messaging.attendeesReached} guests reached',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _ReportSectionTitle('Recent messages'),
        if (messaging.messages.isEmpty)
          const Text(
            'No messages sent yet',
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          )
        else
          _MessageList(messages: messaging.messages),
      ],
    );
  }
}

Color _messageStatusColor(String status) {
  switch (status) {
    case 'sent':
      return AppColors.success;
    case 'failed':
      return AppColors.danger;
    default:
      return AppColors.warning;
  }
}

String _messageStatusLabel(String status) {
  switch (status) {
    case 'sent':
      return 'Sent';
    case 'failed':
      return 'Failed';
    default:
      return 'Pending';
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({required this.messages});

  final List<ReportMessageDetail> messages;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMM, h:mm a');

    return Column(
      children: [
        for (var i = 0; i < messages.length; i++) ...[
          _MessageRow(message: messages[i], dateFmt: dateFmt),
          if (i < messages.length - 1)
            Divider(height: 1, color: AppColors.border.withValues(alpha: 0.6)),
        ],
      ],
    );
  }
}

class _MessageRow extends StatelessWidget {
  const _MessageRow({required this.message, required this.dateFmt});

  final ReportMessageDetail message;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    final color = _messageStatusColor(message.status);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            message.channel == 'whatsapp'
                ? Icons.chat_outlined
                : Icons.sms_outlined,
            size: 18,
            color: AppColors.muted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.recipientName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${message.type} · ${dateFmt.format(message.createdAt.toLocal())}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
                if (message.status == 'failed' &&
                    message.failureReason != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    message.failureReason!,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _messageStatusLabel(message.status),
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContributionsSection extends StatelessWidget {
  const _ContributionsSection({required this.contributions});

  final ReportContributions contributions;

  @override
  Widget build(BuildContext context) {
    final slices = [
      for (var i = 0; i < contributions.categories.length; i++)
        CategorySlice(
          label: contributions.categories[i].name,
          value: contributions.categories[i].collected,
          color: categoryPalette[i % categoryPalette.length],
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ContributionStat(
                    label: 'Collected',
                    value: formatTzsAmount(contributions.totalCollected),
                  ),
                  _ContributionStat(
                    label: 'Expected',
                    value: formatTzsAmount(contributions.totalExpected),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: contributions.totalExpected > 0
                      ? (contributions.totalCollected /
                                contributions.totalExpected)
                            .clamp(0, 1)
                            .toDouble()
                      : 0,
                  minHeight: 8,
                  backgroundColor: AppColors.border,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 14),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _ContributionStat(
                        label: 'Fully paid',
                        value: '${contributions.fullyPaidCount}',
                      ),
                    ),
                    SizedBox(
                      width: 24,
                      child: Center(
                        child: FractionallySizedBox(
                          heightFactor: 0.6,
                          child: VerticalDivider(
                            width: 1,
                            thickness: 1.5,
                            color: AppColors.border.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _ContributionStat(
                        label: 'Partial',
                        value: '${contributions.partialCount}',
                      ),
                    ),
                    SizedBox(
                      width: 24,
                      child: Center(
                        child: FractionallySizedBox(
                          heightFactor: 0.6,
                          child: VerticalDivider(
                            width: 1,
                            thickness: 1.5,
                            color: AppColors.border.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _ContributionStat(
                        label: 'Unpaid',
                        value: '${contributions.unpaidCount}',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (slices.isNotEmpty) ...[
          const SizedBox(height: 16),
          _ReportSectionTitle('By category'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: CategoryDonutChart(
                slices: slices,
                size: 140,
                strokeWidth: 20,
                centerValue: formatCompactAmount(contributions.totalCollected),
                centerLabel: 'Collected',
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ContributionStat extends StatelessWidget {
  const _ContributionStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
      ],
    );
  }
}
