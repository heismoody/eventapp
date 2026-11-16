import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/hero_stats_card.dart';
import '../../../shared/widgets/category_donut_chart.dart';
import '../../../shared/widgets/day_bucket_bar_chart.dart';
import '../../../shared/widgets/speed_dial_fab.dart';
import '../../attendees/services/attendee_service.dart';
import '../../attendees/widgets/attendee_display.dart';
import '../../events/providers/event_provider.dart';
import '../services/contribution_service.dart';
import '../widgets/add_contribution_sheet.dart';
import '../../../l10n/l10n.dart';

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
                  label: context.l10n.addContribution,
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
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          context.l10n.navContributions,
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
                    tabs: [
                      Tab(text: context.l10n.tabStats),
                      Tab(text: context.l10n.tabList),
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
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: context.l10n.searchByName,
                        prefixIcon: const Icon(Icons.search),
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
      loading: () => const HeroStatsCard(child: SizedBox(height: 120)),
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

        return HeroStatsCard(
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
                          context.l10n.collected,
                          style: TextStyle(
                            color: AppColors.onPrimary.withValues(alpha: 0.8),
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
                            color: AppColors.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        context.l10n.expected,
                        style: TextStyle(
                          color: AppColors.onPrimary.withValues(alpha: 0.8),
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
                          color: AppColors.onPrimary.withValues(alpha: 0.85),
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
                  backgroundColor: AppColors.onPrimary.withValues(alpha: 0.2),
                  color: AppColors.onPrimary,
                ),
              ),
              const SizedBox(height: 16),
              HeroStatRow(
                labelColor: AppColors.onPrimary.withValues(alpha: 0.75),
                dividerColor: AppColors.onPrimary.withValues(alpha: 0.25),
                items: [
                  HeroStatItem(
                    label: context.l10n.statusFullyPaid,
                    value: '$paidCount',
                    color: AppColors.onPrimary,
                  ),
                  HeroStatItem(
                    label: context.l10n.partial,
                    value: '$partialCount',
                    color: AppColors.onPrimary,
                  ),
                  HeroStatItem(
                    label: context.l10n.outstanding,
                    value: formatCompactAmount(outstanding.toDouble()),
                    color: AppColors.onPrimary,
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
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
      title: context.l10n.byCategoryTitle,
      contentHeight: 176,
      child: attendeesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            _ChartEmptyState(message: context.l10n.loadCategoryDataFailed),
        data: (attendees) {
          final tracked = attendees.where((a) => a.paidAmount > 0).toList();

          if (tracked.isEmpty) {
            return _ChartEmptyState(
              message: context.l10n.noContributionsCollected,
            );
          }

          final byCategory = <String, double>{};
          for (final a in tracked) {
            final label = a.categoryName ?? context.l10n.uncategorized;
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
              centerLabel: context.l10n.collected,
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
      title: context.l10n.overTime,
      child: contributionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            _ChartEmptyState(message: context.l10n.loadContributionsFailed),
        data: (records) {
          if (records.isEmpty) {
            return _ChartEmptyState(message: context.l10n.dashNoContributions);
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
          Icon(Icons.pie_chart_outline, size: 28, color: AppColors.muted),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 13),
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
    final l10n = context.l10n;
    final options = [
      ('all', l10n.filterAll),
      ('unpaid', l10n.filterUnpaid),
      ('partial', l10n.filterPartial),
      ('full', l10n.filterFull),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
      color: AppColors.surface,
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
                  style: TextStyle(
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
                      style: TextStyle(
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
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
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
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_outlined, size: 56, color: AppColors.muted),
            SizedBox(height: 16),
            Text(
              context.l10n.selectEventFirst,
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
          child: Icon(
            Icons.payments_outlined,
            size: 42,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          context.l10n.noContributionsFound,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.noContributionsFoundHint,
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
            child: Icon(Icons.error_outline, color: AppColors.danger, size: 34),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.loadContributionsFailed,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onRetry,
            child: Text(context.l10n.tryAgain),
          ),
        ],
      ),
    );
  }
}
