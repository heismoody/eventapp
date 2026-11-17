import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../../l10n/l10n.dart';
import '../../auth/widgets/login_form.dart';
import '../services/event_request_service.dart';
import '../services/my_request_store.dart';

/// "Track my request": right after sending, and whenever the person comes
/// back from the welcome screen. One page whose steps and main button
/// follow where the request is in the portal.
class RequestSentScreen extends ConsumerStatefulWidget {
  const RequestSentScreen({super.key});

  @override
  ConsumerState<RequestSentScreen> createState() => _RequestSentScreenState();
}

class _RequestSentScreenState extends ConsumerState<RequestSentScreen> {
  bool _checking = false;
  bool _failed = false;
  DateTime? _checkedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    final request = ref.read(myRequestProvider);
    if (request == null || _checking) return;
    setState(() {
      _checking = true;
      _failed = false;
    });
    try {
      await ref.read(eventRequestServiceProvider).refreshStatus(request);
      if (mounted) setState(() => _checkedAt = DateTime.now());
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  /// Back to the welcome screen. A closed request has been seen by now,
  /// so the button there goes back to "Plan an event".
  Future<void> _leave() async {
    final request = ref.read(myRequestProvider);
    if (request?.progress.stage == RequestStage.closed) {
      await ref.read(myRequestProvider.notifier).clear();
    }
    if (mounted) context.go('/login');
  }

  Future<void> _sendNew() async {
    await ref.read(myRequestProvider.notifier).clear();
    if (mounted) context.go('/plan-event');
  }

  Future<void> _open(Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      AppToast.error(
        appL10n.couldntOpenCallUs(
          CardlyContact.display(CardlyContact.callNumbers.first),
        ),
      );
    }
  }

  Future<void> _call() async {
    final number = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final n in CardlyContact.callNumbers)
              ListTile(
                leading: const Icon(Icons.call_outlined),
                title: Text(CardlyContact.display(n)),
                onTap: () => Navigator.pop(context, n),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (number != null) await _open(Uri(scheme: 'tel', path: '+$number'));
  }

  @override
  Widget build(BuildContext context) {
    final request = ref.watch(myRequestProvider);
    if (request == null) {
      // Nothing to track (cleared on another screen): back to the start.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/login');
      });
      return Scaffold(backgroundColor: AppColors.background);
    }

    final theme = Theme.of(context);
    final l10n = context.l10n;
    final progress = request.progress;
    final stage = progress.stage;
    final phone = CardlyContact.display(request.phone);
    final strong = TextStyle(
      color: AppColors.onSurface,
      fontWeight: FontWeight.w700,
    );
    final time = DateFormat('d MMM, HH:mm', l10n.localeName);

    final title = switch (stage) {
      RequestStage.received =>
        request.firstName.isEmpty
            ? l10n.requestWithUs
            : l10n.requestSentTo(request.firstName),
      RequestStage.contacted => l10n.requestSpokenTitle,
      RequestStage.ready => l10n.requestReadyTitle,
      RequestStage.closed => l10n.requestClosedTitle,
    };

    final lead = switch (stage) {
      RequestStage.received => [
        ...spansWith(l10n.callYouOn, phone, strong),
        if (request.email != null)
          TextSpan(text: ' ${l10n.emailedCopyTo(request.email!)}'),
      ],
      RequestStage.contacted => [TextSpan(text: l10n.requestSettingUpLead)],
      RequestStage.ready => spansWith(l10n.requestReadyLead, phone, strong),
      RequestStage.closed => [TextSpan(text: l10n.requestClosedLead)],
    };

    final contacted = progress.contactedAt;
    final steps = <_StepData>[
      _StepData(
        _Mark.done,
        l10n.stepReceived,
        time.format(progress.receivedAt),
      ),
      if (stage == RequestStage.received)
        _StepData(_Mark.current, l10n.stepWeCall, l10n.stepCallHint)
      else if (contacted != null)
        _StepData(_Mark.done, l10n.stepWeCalled, time.format(contacted))
      else if (stage != RequestStage.closed)
        _StepData(_Mark.done, l10n.stepWeCalled, null),
      switch (stage) {
        RequestStage.received => _StepData(
          _Mark.pending,
          l10n.stepSetUp,
          l10n.stepSetUpHint,
        ),
        RequestStage.contacted => _StepData(
          _Mark.current,
          l10n.stepSettingUp,
          l10n.stepSetUpHint,
        ),
        RequestStage.ready => _StepData(
          _Mark.success,
          l10n.stepSetUp,
          progress.closedAt == null ? null : time.format(progress.closedAt!),
        ),
        RequestStage.closed => _StepData(
          _Mark.closed,
          l10n.requestClosedTitle,
          progress.closedAt == null ? null : time.format(progress.closedAt!),
        ),
      },
    ];

    final statusLine = _checking
        ? l10n.checkingForUpdates
        : _failed
        ? l10n.statusRefreshFailed
        : _checkedAt == null
        ? null
        : l10n.statusUpdatedAt(
            DateFormat.Hm(l10n.localeName).format(_checkedAt!),
          );

    final primary = switch (stage) {
      RequestStage.received || RequestStage.contacted => FilledButton(
        onPressed: _leave,
        style: _primaryStyle,
        child: Text(l10n.done),
      ),
      RequestStage.ready => FilledButton(
        onPressed: () =>
            context.push('/plan-event/password', extra: request.phone),
        style: _primaryStyle,
        child: Text(l10n.choosePasswordButton),
      ),
      RequestStage.closed => FilledButton(
        onPressed: _sendNew,
        style: _primaryStyle,
        child: Text(l10n.sendNewRequest),
      ),
    };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: _StageBadge(stage: stage),
                ),
                const SizedBox(height: 28),
                Text(
                  title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.12,
                  ),
                ),
                const SizedBox(height: 10),
                Text.rich(
                  TextSpan(
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.muted,
                      height: 1.5,
                    ),
                    children: lead,
                  ),
                ),
                const SizedBox(height: 28),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (stage == RequestStage.received) ...[
                          Text(
                            l10n.whatHappensNext,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        for (var i = 0; i < steps.length; i++)
                          _Step(steps[i], last: i == steps.length - 1),
                      ],
                    ),
                  ),
                ),
                if (statusLine != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    statusLine,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                primary,
                if (stage == RequestStage.ready)
                  TextButton(
                    onPressed: () => context.go(
                      '/login?skip=1',
                      extra: LoginPrefill(identifier: phone),
                    ),
                    style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: Text(
                      l10n.signIn,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                if (stage == RequestStage.closed)
                  TextButton(
                    onPressed: _leave,
                    style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: Text(
                      l10n.done,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                Text(
                  l10n.cantWait,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _open(
                          Uri.parse('https://wa.me/${CardlyContact.whatsapp}'),
                        ),
                        icon: const Icon(Icons.chat_outlined),
                        label: Text(l10n.whatsApp),
                        style: _contactStyle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _call,
                        icon: const Icon(Icons.call_outlined),
                        label: Text(l10n.callUs),
                        style: _contactStyle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final _primaryStyle = FilledButton.styleFrom(
  minimumSize: const Size.fromHeight(54),
  textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
);

final _contactStyle = OutlinedButton.styleFrom(
  minimumSize: const Size.fromHeight(52),
  foregroundColor: AppColors.primary,
  backgroundColor: AppColors.surface,
  side: BorderSide(color: AppColors.border),
  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
);

class _StageBadge extends StatelessWidget {
  const _StageBadge({required this.stage});

  final RequestStage stage;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (stage) {
      RequestStage.received => (Icons.check_rounded, AppColors.primary),
      RequestStage.contacted => (Icons.call_rounded, AppColors.primary),
      RequestStage.ready => (Icons.celebration_rounded, AppColors.success),
      RequestStage.closed => (Icons.close_rounded, AppColors.muted),
    };
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, color: AppColors.onPrimary, size: 38),
    );
  }
}

enum _Mark { done, current, pending, success, closed }

class _StepData {
  const _StepData(this.mark, this.title, this.subtitle);

  final _Mark mark;
  final String title;
  final String? subtitle;
}

/// One line of the timeline: a dot, the line down to the next one, and
/// what happened (or will happen) with when.
class _Step extends StatelessWidget {
  const _Step(this.data, {this.last = false});

  final _StepData data;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = data.mark != _Mark.pending && data.mark != _Mark.current;
    final dimmed = data.mark == _Mark.pending;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                _Dot(data.mark),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: done ? AppColors.primary : AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16, top: 1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: dimmed ? AppColors.muted : AppColors.onSurface,
                    ),
                  ),
                  if (data.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      data.subtitle!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.mark);

  final _Mark mark;

  @override
  Widget build(BuildContext context) {
    Widget filled(Color color, IconData icon) => Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, size: 15, color: AppColors.onPrimary),
    );

    return switch (mark) {
      _Mark.done => filled(AppColors.primary, Icons.check_rounded),
      _Mark.success => filled(AppColors.success, Icons.check_rounded),
      _Mark.closed => filled(AppColors.muted, Icons.close_rounded),
      _Mark.current => Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.accent, width: 2),
        ),
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
          ),
        ),
      ),
      _Mark.pending => Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border, width: 2),
        ),
      ),
    };
  }
}
