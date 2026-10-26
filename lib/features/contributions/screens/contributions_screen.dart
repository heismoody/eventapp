import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/category_donut_chart.dart';
import '../../../shared/widgets/day_bucket_bar_chart.dart';
import '../../../shared/widgets/speed_dial_fab.dart';
import '../../attendees/services/attendee_service.dart';
import '../../attendees/widgets/attendee_display.dart';
import '../../events/providers/event_provider.dart';
import '../services/contribution_service.dart';
import '../widgets/add_contribution_sheet.dart';

/// Mirrors the Guests screen's layout (search + filter bar + card list) but
/// scoped to contribution status instead of check-in status.
class ContributionsScreen extends ConsumerStatefulWidget {
  const ContributionsScreen({super.key});

  @override
  ConsumerState<ContributionsScreen> createState() =>
      _ContributionsScreenState();
}

class _ContributionsScreenState extends ConsumerState<ContributionsScreen>
    with SingleTickerProviderStateMixin {
  String _filter = 'all';
  String _search = '';
  late final TabController _sectionController;

  @override
  void initState() {
    super.initState();
    _sectionController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _sectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventId = ref.watch(activeEventIdProvider);

    return Stack(
      children: [
        _buildScaffold(eventId),
        if (eventId != null)
          Positioned.fill(
            child: SpeedDialFab(
              actions: [
                SpeedDialAction(
                  icon: Icons.add_card_outlined,
                  label: 'Add contribution',
                  onTap: () => showAddContributionSheet(
                    context: context,
                    ref: ref,
                    eventId: eventId,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildScaffold(String? eventId) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Contributions',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: eventId == null
          ? const _ContributionsEmptySelectionState()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: _ContributionsStatsCard(eventId: eventId),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: TabBar(
                    controller: _sectionController,
                    isScrollable: false,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.muted,
                    indicatorColor: AppColors.primary,
                    dividerColor: Colors.transparent,
                    labelPadding: const EdgeInsets.symmetric(vertical: 4),
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                    tabs: const [
                      Tab(text: 'Stats'),
                      Tab(text: 'List'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _sectionController,
                    children: [
                      _ContributionsStatsTab(eventId: eventId),
                      _ContributionsListTab(
                        eventId: eventId,
                        filter: _filter,
                        search: _search,
                        onFilterChanged: (value) =>
                            setState(() => _filter = value),
                        onSearchChanged: (value) =>
                            setState(() => _search = value),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _ContributionsStatsTab extends StatelessWidget {
  const _ContributionsStatsTab({required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(attendeesProvider(eventId));
            ref.invalidate(contributionsProvider(eventId));
            await ref.read(attendeesProvider(eventId).future);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              _CategoryBreakdownCard(eventId: eventId),
              const SizedBox(height: 16),
              _ContributionsOverTimeCard(eventId: eventId),
            ],
          ),
        );
      },
    );
  }
}

class _ContributionsListTab extends StatelessWidget {
  const _ContributionsListTab({
    required this.eventId,
    required this.filter,
    required this.search,
    required this.onFilterChanged,
    required this.onSearchChanged,
  });

  final String eventId;
  final String filter;
  final String search;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(attendeesProvider(eventId));
            await ref.read(attendeesProvider(eventId).future);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search by name',
                        prefixIcon: Icon(Icons.search),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      onChanged: onSearchChanged,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _ContributionFilterBar(
                    value: filter,
                    onChanged: onFilterChanged,
                  ),
                ),
              ),
              _ContributionsListSliver(
                eventId: eventId,
                filter: filter,
                search: search,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ContributionsStatsCard extends ConsumerWidget {
  const _ContributionsStatsCard({required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendeesAsync = ref.watch(attendeesProvider(eventId));

    return attendeesAsync.when(
      loading: () => const _StatsCardShell(child: SizedBox(height: 120)),
      error: (_, _) => const SizedBox.shrink(),
      data: (attendees) {
        final tracked = attendees
            .where((a) => a.targetAmountValue > 0 || a.paidAmount > 0)
            .toList();

        final expected = tracked.fold<double>(
          0,
          (sum, a) => sum + a.targetAmountValue,
        );
        final collected = tracked.fold<double>(
          0,
          (sum, a) => sum + a.paidAmount,
        );
        final progress = expected > 0
            ? (collected / expected).clamp(0, 1)
            : 0.0;
        final outstanding = (expected - collected).clamp(0, double.infinity);

        final paidCount = tracked
            .where((a) => a.paymentStatus == ContributionPaymentStatus.paid)
            .length;
        final partialCount = tracked
            .where((a) => a.paymentStatus == ContributionPaymentStatus.partial)
            .length;

        return _StatsCardShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Collected',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatTzsAmount(collected),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Expected',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatTzsAmount(expected),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress.toDouble(),
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              _StatRow(
                labelColor: Colors.white.withValues(alpha: 0.75),
                dividerColor: Colors.white.withValues(alpha: 0.25),
                items: [
                  _StatItem(
                    label: 'Fully paid',
                    value: '$paidCount',
                    color: Colors.white,
                  ),
                  _StatItem(
                    label: 'Partial',
                    value: '$partialCount',
                    color: Colors.white,
                  ),
                  _StatItem(
                    label: 'Outstanding',
                    value: formatCompactAmount(outstanding.toDouble()),
                    color: Colors.white,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Matches the dashboard's countdown card — same gradient, same floating
/// translucent circles — so the two "hero" cards read as one family.
class _StatsCardShell extends StatelessWidget {
  const _StatsCardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -30,
              right: -20,
              child: _StatsCardBubble(size: 100, opacity: 0.14),
            ),
            const Positioned(
              bottom: -36,
              left: -16,
              child: _StatsCardBubble(size: 90, opacity: 0.1),
            ),
            Padding(padding: const EdgeInsets.all(18), child: child),
          ],
        ),
      ),
    );
  }
}

class _StatsCardBubble extends StatelessWidget {
  const _StatsCardBubble({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

class _StatItem {
  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.items,
    this.labelColor = AppColors.muted,
    this.dividerColor = AppColors.border,
  });

  final List<_StatItem> items;
  final Color labelColor;
  final Color dividerColor;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              SizedBox(
                width: 16,
                child: Center(
                  child: FractionallySizedBox(
                    heightFactor: 0.6,
                    child: VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: dividerColor,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    items[i].value,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: items[i].color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    items[i].label,
                    style: TextStyle(
                      color: labelColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Shared shell for a chart card — white rounded container with a title
/// above a fixed-height content area, so the two decoupled charts below
/// line up and don't jump height between loading/empty/data states.
class _ChartCardShell extends StatelessWidget {
  const _ChartCardShell({
    required this.title,
    required this.child,
    this.contentHeight = 220,
  });

  final String title;
  final Widget child;
  final double contentHeight;

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
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(height: contentHeight, child: child),
        ],
      ),
    );
  }
}

class _CategoryBreakdownCard extends ConsumerWidget {
  const _CategoryBreakdownCard({required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendeesAsync = ref.watch(attendeesProvider(eventId));

    return _ChartCardShell(
      title: 'By Category',
      contentHeight: 176,
      child: attendeesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            const _ChartEmptyState(message: 'Failed to load category data'),
        data: (attendees) {
          final tracked = attendees.where((a) => a.paidAmount > 0).toList();

          if (tracked.isEmpty) {
            return const _ChartEmptyState(
              message: 'No contributions collected yet',
            );
          }

          final byCategory = <String, double>{};
          for (final a in tracked) {
            final label = a.categoryName ?? 'Uncategorized';
            byCategory[label] = (byCategory[label] ?? 0) + a.paidAmount;
          }
          final sortedEntries = byCategory.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          final slices = [
            for (var i = 0; i < sortedEntries.length; i++)
              CategorySlice(
                label: sortedEntries[i].key,
                value: sortedEntries[i].value,
                color: categoryPalette[i % categoryPalette.length],
              ),
          ];
          final total = slices.fold<double>(0, (a, b) => a + b.value);

          return Center(
            child: CategoryDonutChart(
              slices: slices,
              centerValue: formatCompactAmount(total),
              centerLabel: 'Collected',
            ),
          );
        },
      ),
    );
  }
}

class _ContributionsOverTimeCard extends ConsumerWidget {
  const _ContributionsOverTimeCard({required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contributionsAsync = ref.watch(contributionsProvider(eventId));

    return _ChartCardShell(
      title: 'Over Time',
      child: contributionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            const _ChartEmptyState(message: 'Failed to load contributions'),
        data: (records) {
          if (records.isEmpty) {
            return const _ChartEmptyState(
              message: 'No contributions recorded yet',
            );
          }

          return DayBucketBarChart(
            dates: records.map((r) => r.createdAt).toList(),
            amounts: records.map((r) => r.amountValue).toList(),
            accent: AppColors.success,
            highlight: AppColors.warning,
            chartHeight: 190,
          );
        },
      ),
    );
  }
}

class _ChartEmptyState extends StatelessWidget {
  const _ChartEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.pie_chart_outline, size: 28, color: AppColors.muted),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ContributionFilterBar extends StatelessWidget {
  const _ContributionFilterBar({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = [
      ('all', 'All'),
      ('unpaid', 'Unpaid'),
      ('partial', 'Partial'),
      ('full', 'Full'),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: _FilterTab(
                label: option.$2,
                selected: value == option.$1,
                onTap: () => onChanged(option.$1),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.1)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.primary : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _ContributionsListSliver extends ConsumerWidget {
  const _ContributionsListSliver({
    required this.eventId,
    required this.filter,
    required this.search,
  });

  final String eventId;
  final String filter;
  final String search;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendeesAsync = ref.watch(attendeesProvider(eventId));

    return attendeesAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(top: 60),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: _ContributionsErrorState(
          onRetry: () => ref.invalidate(attendeesProvider(eventId)),
        ),
      ),
      data: (attendees) {
        // Only guests actually being tracked for contributions belong here
        // at all — categories are just a tag, pledges/payments are the
        // real signal (per the category/contribution decoupling).
        var tracked = attendees
            .where((a) => a.targetAmountValue > 0 || a.paidAmount > 0)
            .toList();

        if (filter == 'unpaid') {
          tracked = tracked
              .where((a) => a.paymentStatus == ContributionPaymentStatus.unpaid)
              .toList();
        }
        if (filter == 'partial') {
          tracked = tracked
              .where(
                (a) => a.paymentStatus == ContributionPaymentStatus.partial,
              )
              .toList();
        }
        if (filter == 'full') {
          tracked = tracked
              .where((a) => a.paymentStatus == ContributionPaymentStatus.paid)
              .toList();
        }
        if (search.isNotEmpty) {
          tracked = tracked
              .where((a) => a.name.toLowerCase().contains(search.toLowerCase()))
              .toList();
        }

        if (tracked.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 40, 20, 32),
              child: _ContributionsEmptyState(),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              if (index.isOdd) return const SizedBox(height: 12);
              final attendee = tracked[index ~/ 2];
              return _ContributionCard(
                attendee: attendee,
                onTap: () => context.push('/shell/guests/${attendee.id}'),
              );
            }, childCount: tracked.length * 2 - 1),
          ),
        );
      },
    );
  }
}

class _ContributionCard extends StatelessWidget {
  const _ContributionCard({required this.attendee, required this.onTap});

  final AttendeeRecord attendee;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = attendee.paymentStatus;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  guestInitials(attendee.name),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attendee.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${formatTzsAmount(attendee.paidAmount)} / '
                      '${formatTzsAmount(attendee.targetAmountValue)}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: contributionStatusColor(
                    status,
                  ).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  contributionStatusLabel(status),
                  style: TextStyle(
                    color: contributionStatusColor(status),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContributionsEmptySelectionState extends StatelessWidget {
  const _ContributionsEmptySelectionState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_outlined, size: 56, color: AppColors.muted),
            SizedBox(height: 16),
            Text(
              'Select an event first',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContributionsEmptyState extends StatelessWidget {
  const _ContributionsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.payments_outlined,
            size: 42,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'No contributions found',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Try a different filter, or set a pledge on a guest to track it here.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, height: 1.5),
        ),
      ],
    );
  }
}

class _ContributionsErrorState extends StatelessWidget {
  const _ContributionsErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              color: AppColors.danger,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Failed to load contributions',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
