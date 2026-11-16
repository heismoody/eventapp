import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/services/connectivity_service.dart';
import '../../../shared/widgets/category_donut_chart.dart';
import '../../../shared/widgets/hero_stats_card.dart';
import '../../attendees/services/attendee_service.dart';
import '../../attendees/widgets/attendee_display.dart';
import '../../events/providers/event_provider.dart';
import '../models/door_summary.dart';
import '../providers/scanner_provider.dart';
import '../../../l10n/l10n.dart';

/// The Scan tab, laid out like Contributions: the door's numbers in the
/// brown card, then Overview, Arrived and Still to come tabs, with the
/// camera one tap away.
class ScanHubScreen extends ConsumerStatefulWidget {
  const ScanHubScreen({super.key});

  @override
  ConsumerState<ScanHubScreen> createState() => _ScanHubScreenState();
}

enum _ListMode { arrived, toCome }

const _tabular = [FontFeature.tabularFigures()];

class _ScanHubScreenState extends ConsumerState<ScanHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  String _search = '';

  /// Card type shown in the two lists; null shows every type.
  String? _category;
  bool _isOnline = true;
  StreamSubscription<bool>? _connectivity;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    ref.read(connectivityServiceProvider).isOnline().then((online) {
      if (mounted) setState(() => _isOnline = online);
    });
    _connectivity = ref
        .read(connectivityServiceProvider)
        .onStatusChanged
        .listen((online) {
          if (!mounted) return;
          setState(() => _isOnline = online);
          if (online) _refresh();
        });
    // Other gates' entries reach this phone through the guest list.
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refresh(),
    );
    _refresh();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _connectivity?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final eventId = ref.read(activeEventIdProvider);
    if (eventId == null) return;
    if (_isOnline) {
      try {
        await ref.read(attendeeServiceProvider).fetchAttendees(eventId);
      } catch (_) {
        // Keep showing the phone's copy.
      }
    }
    if (mounted) ref.invalidate(doorSummaryProvider(eventId));
  }

  Future<void> _openScanner() async {
    await context.push('/scan');
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final eventId = ref.watch(activeEventIdProvider);
    final summaryAsync = eventId == null
        ? null
        : ref.watch(doorSummaryProvider(eventId));

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          context.l10n.navScan,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(child: _ConnectionPill(isOnline: _isOnline)),
          ),
        ],
      ),
      floatingActionButton: eventId == null
          ? null
          : FloatingActionButton.extended(
              heroTag: 'scan-card',
              onPressed: _openScanner,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              elevation: 3,
              icon: const Icon(Icons.qr_code_scanner),
              label: Text(
                context.l10n.scanCard,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
      body: switch (summaryAsync) {
        null => _Message(
          icon: Icons.event_outlined,
          title: context.l10n.noEventSelected,
          body: context.l10n.pickEventToCheckIn,
        ),
        AsyncValue(:final value?) => _buildBody(value),
        AsyncError() => _Message(
          icon: Icons.error_outline,
          title: context.l10n.loadGuestListFailed,
          body: context.l10n.pullToRetry,
          onRefresh: _refresh,
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  Widget _buildBody(DoorSummary summary) {
    if (summary.isEmpty) {
      return _Message(
        icon: _isOnline ? Icons.group_add_outlined : Icons.cloud_off_outlined,
        title: _isOnline
            ? context.l10n.noGuestsOnEvent
            : context.l10n.noGuestListOnPhone,
        body: _isOnline
            ? context.l10n.noGuestsOnEventHint
            : context.l10n.noGuestListOnPhoneHint,
        onRefresh: _refresh,
      );
    }

    final colors = {
      for (var i = 0; i < summary.categories.length; i++)
        summary.categories[i].name: categoryPalette[i % categoryPalette.length],
    };
    // A filter left over from a type that no longer exists shows everyone.
    final category = colors.containsKey(_category) ? _category : null;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: _DoorStatsCard(summary: summary),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: TabBar(
            controller: _tabs,
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
              Tab(text: context.l10n.tabOverview),
              Tab(text: context.l10n.tabArrived),
              Tab(text: context.l10n.tabStillToCome),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _OverviewTab(
                summary: summary,
                colors: colors,
                onRefresh: _refresh,
              ),
              for (final mode in _ListMode.values)
                _GuestListTab(
                  mode: mode,
                  summary: summary,
                  colors: colors,
                  category: category,
                  search: _search,
                  onCategoryChanged: (value) =>
                      setState(() => _category = value),
                  onSearchChanged: (value) => setState(() => _search = value),
                  onRefresh: _refresh,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// The brown card: people in against people expected.
// ---------------------------------------------------------------------------

class _DoorStatsCard extends StatelessWidget {
  const _DoorStatsCard({required this.summary});

  final DoorSummary summary;

  @override
  Widget build(BuildContext context) {
    final soft = AppColors.onPrimary.withValues(alpha: 0.8);
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
                      context.l10n.peopleIn,
                      style: TextStyle(
                        color: soft,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${summary.peopleIn}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onPrimary,
                        fontFeatures: _tabular,
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
                      color: soft,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${summary.peopleExpected}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onPrimary.withValues(alpha: 0.85),
                      fontFeatures: _tabular,
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
              value: summary.progress,
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
                label: context.l10n.tabStillToCome,
                value: '${summary.peopleToCome}',
                color: AppColors.onPrimary,
              ),
              HeroStatItem(
                label: context.l10n.cardsUsed,
                value: '${summary.cardsArrived}/${summary.cards.length}',
                color: AppColors.onPrimary,
              ),
              HeroStatItem(
                label: context.l10n.partlyIn,
                value: '${summary.cardsPartlyIn}',
                color: AppColors.onPrimary,
              ),
            ],
          ),
          if (summary.waitingSync > 0) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.cloud_upload_outlined, color: soft, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.waitingSyncPeople(summary.waitingSync),
                    style: TextStyle(color: soft, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Overview tab
// ---------------------------------------------------------------------------

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.summary,
    required this.colors,
    required this.onRefresh,
  });

  final DoorSummary summary;
  final Map<String, Color> colors;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        // Bottom room so the Scan card button doesn't cover the last row.
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 104),
        children: [
          _CardShell(
            title: context.l10n.byCardType,
            child: Column(
              children: [
                for (var i = 0; i < summary.categories.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _CardTypeRow(
                    category: summary.categories[i],
                    color: colors[summary.categories[i].name]!,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// White card with a title, like the Contributions chart cards.
class _CardShell extends StatelessWidget {
  const _CardShell({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
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
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _CardTypeRow extends StatelessWidget {
  const _CardTypeRow({required this.category, required this.color});

  final DoorCategory category;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final allIn = category.peopleToCome == 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${category.peopleIn}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                    TextSpan(
                      text: ' / ${category.peopleExpected}',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                style: const TextStyle(fontFeatures: _tabular),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: category.progress,
              minHeight: 6,
              backgroundColor: color.withValues(alpha: 0.12),
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            allIn
                ? context.l10n.everyoneIsIn
                : context.l10n.categoryProgress(
                    category.peopleToCome,
                    category.cardsArrived,
                    category.cards,
                  ),
            style: TextStyle(
              fontSize: 12.5,
              color: allIn ? AppColors.success : AppColors.muted,
              fontWeight: allIn ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Arrived / Still to come tabs
// ---------------------------------------------------------------------------

class _GuestListTab extends StatelessWidget {
  const _GuestListTab({
    required this.mode,
    required this.summary,
    required this.colors,
    required this.category,
    required this.search,
    required this.onCategoryChanged,
    required this.onSearchChanged,
    required this.onRefresh,
  });

  final _ListMode mode;
  final DoorSummary summary;
  final Map<String, Color> colors;
  final String? category;
  final String search;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String> onSearchChanged;
  final Future<void> Function() onRefresh;

  int _countFor(String? type) => mode == _ListMode.arrived
      ? summary.arrived(category: type).length
      : summary.toCome(category: type).length;

  Future<void> _showFilterSheet(BuildContext context) async {
    final picked = await showModalBottomSheet<_FilterChoice>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _FilterSheet(
        title: mode == _ListMode.arrived
            ? context.l10n.filterArrived
            : context.l10n.filterToCome,
        options: [
          _FilterOption(
            value: null,
            label: context.l10n.allCardTypes,
            count: _countFor(null),
          ),
          for (final type in summary.categories)
            _FilterOption(
              value: type.name,
              label: type.name,
              color: colors[type.name],
              count: _countFor(type.name),
            ),
        ],
        selected: category,
      ),
    );
    if (picked != null) onCategoryChanged(picked.value);
  }

  @override
  Widget build(BuildContext context) {
    var cards = mode == _ListMode.arrived
        ? summary.arrived(category: category)
        : summary.toCome(category: category);
    final query = search.trim().toLowerCase();
    if (query.isNotEmpty) {
      cards = [
        for (final card in cards)
          if (card.name.toLowerCase().contains(query) ||
              card.phone.contains(query))
            card,
      ];
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverToBoxAdapter(
              child: _SearchField(
                // Keeps the typed text when switching between the two lists.
                initialValue: search,
                onChanged: onSearchChanged,
                filterActive: category != null,
                onFilterTap: () => _showFilterSheet(context),
              ),
            ),
          ),
          if (category != null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: InputChip(
                    label: Text(context.l10n.cardTypeCards(category!)),
                    avatar: CircleAvatar(
                      backgroundColor: colors[category],
                      radius: 5,
                    ),
                    onPressed: () => _showFilterSheet(context),
                    onDeleted: () => onCategoryChanged(null),
                    deleteButtonTooltipMessage: context.l10n.showAllCardTypes,
                    backgroundColor: AppColors.surface,
                    side: BorderSide(color: AppColors.border),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          if (cards.isEmpty)
            // Centred in the space left under the search bar. The bottom
            // padding keeps it clear of the Scan card button.
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 24, 32, 96),
                child: Center(
                  child: _EmptyList(
                    mode: mode,
                    category: category,
                    searching: query.isNotEmpty,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              // Bottom room so the Scan card button doesn't cover the last row.
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 104),
              sliver: SliverList.separated(
                itemCount: cards.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _GuestCard(
                  card: cards[index],
                  mode: mode,
                  color:
                      colors[cards[index].category ??
                          DoorSummary.uncategorisedLabel] ??
                      AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField({
    required this.initialValue,
    required this.onChanged,
    required this.filterActive,
    required this.onFilterTap,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;
  final bool filterActive;
  final VoidCallback onFilterTap;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final _controller = TextEditingController(text: widget.initialValue);

  @override
  void didUpdateWidget(covariant _SearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: context.l10n.searchByNameOrPhone,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              ),
              onChanged: widget.onChanged,
            ),
          ),
          Container(width: 1, height: 24, color: AppColors.border),
          IconButton(
            onPressed: widget.onFilterTap,
            tooltip: context.l10n.filterByCardType,
            icon: Badge(
              isLabelVisible: widget.filterActive,
              backgroundColor: AppColors.primary,
              smallSize: 8,
              child: Icon(
                Icons.tune,
                color: widget.filterActive
                    ? AppColors.primary
                    : AppColors.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

/// One choice in the filter sheet. A null value is "all card types".
class _FilterOption {
  const _FilterOption({
    required this.value,
    required this.label,
    required this.count,
    this.color,
  });

  final String? value;
  final String label;
  final int count;
  final Color? color;
}

/// What the sheet returns: wrapped so "all types" (null) can be told apart
/// from closing the sheet without choosing.
class _FilterChoice {
  const _FilterChoice(this.value);

  final String? value;
}

class _FilterSheet extends StatelessWidget {
  const _FilterSheet({
    required this.title,
    required this.options,
    required this.selected,
  });

  final String title;
  final List<_FilterOption> options;
  final String? selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
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
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              context.l10n.cardType,
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final option in options)
                      _FilterSheetRow(
                        option: option,
                        selected: option.value == selected,
                        onTap: () =>
                            Navigator.pop(context, _FilterChoice(option.value)),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterSheetRow extends StatelessWidget {
  const _FilterSheetRow({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _FilterOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  if (option.color != null)
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: option.color,
                        shape: BoxShape.circle,
                      ),
                    )
                  else
                    Icon(Icons.select_all, size: 16, color: AppColors.muted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      option.label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? AppColors.primary
                            : AppColors.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    context.l10n.dashGuestCount(option.count),
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                      fontFeatures: _tabular,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    size: 20,
                    color: selected ? AppColors.primary : AppColors.border,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A guest's card, styled like the Contributions list cards.
class _GuestCard extends StatelessWidget {
  const _GuestCard({
    required this.card,
    required this.mode,
    required this.color,
  });

  final DoorCard card;
  final _ListMode mode;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final type = card.category ?? DoorSummary.uncategorisedLabel;
    final detail = switch (mode) {
      _ListMode.arrived =>
        card.lastEntryAt == null
            ? type
            : context.l10n.typeAtTime(
                type,
                DateFormatter.formatTime(card.lastEntryAt),
              ),
      _ListMode.toCome =>
        card.partlyIn
            ? context.l10n.typePartlyIn(type, card.entered, card.admits)
            : type,
    };

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: card.attendeeId == null
            ? null
            : () => context.push('/shell/guests/${card.attendeeId}'),
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
                backgroundColor: color.withValues(alpha: 0.12),
                child: Text(
                  guestInitials(card.name),
                  style: TextStyle(color: color, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (card.waiting > 0) ...[
                Tooltip(
                  message: context.l10n.waitingSyncTooltip,
                  child: Icon(
                    Icons.cloud_upload_outlined,
                    size: 18,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              _PeopleBadge(card: card, mode: mode),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeopleBadge extends StatelessWidget {
  const _PeopleBadge({required this.card, required this.mode});

  final DoorCard card;
  final _ListMode mode;

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (mode) {
      _ListMode.toCome => (
        context.l10n.placesLeftShort(card.placesLeft),
        card.partlyIn ? AppColors.warning : AppColors.accent,
      ),
      _ListMode.arrived => (
        context.l10n.enteredShort(card.entered, card.admits),
        card.entered > card.admits
            ? AppColors.danger
            : card.partlyIn
            ? AppColors.warning
            : AppColors.success,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          fontFeatures: _tabular,
        ),
      ),
    );
  }
}

class _EmptyList extends StatelessWidget {
  const _EmptyList({
    required this.mode,
    required this.category,
    required this.searching,
  });

  final _ListMode mode;
  final String? category;
  final bool searching;

  @override
  Widget build(BuildContext context) {
    final (title, body) = searching
        ? (context.l10n.noSearchMatch, context.l10n.noSearchMatchHint)
        : switch (mode) {
            _ListMode.arrived => (
              category == null
                  ? context.l10n.noOneInYet
                  : context.l10n.noOneOfTypeInYet(category!),
              context.l10n.tapScanWhenArrives,
            ),
            _ListMode.toCome => (
              category == null
                  ? context.l10n.everyoneIsIn
                  : context.l10n.everyTypeIn(category!),
              context.l10n.noPlacesToFill,
            ),
          };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            searching
                ? Icons.search_off
                : mode == _ListMode.arrived
                ? Icons.how_to_reg_outlined
                : Icons.celebration_outlined,
            size: 48,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.muted),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    this.onRefresh,
  });

  final IconData icon;
  final String title;
  final String body;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final content = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(32, 96, 32, 32),
      children: [
        Icon(icon, size: 40, color: AppColors.muted),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.muted),
        ),
      ],
    );
    final refresh = onRefresh;
    return refresh == null
        ? content
        : RefreshIndicator(onRefresh: refresh, child: content);
  }
}

class _ConnectionPill extends StatelessWidget {
  const _ConnectionPill({required this.isOnline});

  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final color = isOnline ? AppColors.success : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isOnline ? Icons.wifi : Icons.wifi_off, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            isOnline ? context.l10n.online : context.l10n.offline,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
