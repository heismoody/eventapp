import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/providers.dart';

/// Where a request is, as the portal sees it.
enum RequestStage {
  /// Sent, waiting for Cardly's call.
  received,

  /// Cardly has called and is setting the event up.
  contacted,

  /// The event and the owner's account exist: they can choose a password.
  ready,

  /// It won't go ahead (or staff removed it).
  closed,
}

/// The latest status the portal gave, kept so the page shows something
/// straight away and offline.
class RequestProgress {
  const RequestProgress({
    required this.stage,
    required this.receivedAt,
    this.contactedAt,
    this.closedAt,
  });

  final RequestStage stage;
  final DateTime receivedAt;
  final DateTime? contactedAt;

  /// When it was booked or closed.
  final DateTime? closedAt;

  /// From `GET /api/mobile/event-requests/{id}`.
  factory RequestProgress.fromApi(Map<String, dynamic> json) {
    final status = json['status'] as String?;
    final ready = json['eventReady'] == true;
    return RequestProgress(
      stage: switch (status) {
        'contacted' => RequestStage.contacted,
        // Booked but the event not made yet: still being set up.
        'booked' => ready ? RequestStage.ready : RequestStage.contacted,
        'closed' => RequestStage.closed,
        _ => RequestStage.received,
      },
      receivedAt: _date(json['receivedAt']) ?? DateTime.now(),
      contactedAt: _date(json['contactedAt']),
      closedAt: _date(json['closedAt']),
    );
  }

  factory RequestProgress.fromJson(Map<String, dynamic> json) =>
      RequestProgress(
        stage: RequestStage.values.firstWhere(
          (s) => s.name == json['stage'],
          orElse: () => RequestStage.received,
        ),
        receivedAt: _date(json['receivedAt']) ?? DateTime.now(),
        contactedAt: _date(json['contactedAt']),
        closedAt: _date(json['closedAt']),
      );

  Map<String, dynamic> toJson() => {
    'stage': stage.name,
    'receivedAt': receivedAt.toIso8601String(),
    'contactedAt': contactedAt?.toIso8601String(),
    'closedAt': closedAt?.toIso8601String(),
  };

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toLocal() : null;
}

/// The event request sent from this phone. Only this phone knows its id,
/// which is what lets it ask the portal for the status.
class MyRequest {
  const MyRequest({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.progress,
  });

  final String id;
  final String name;

  /// 255XXXXXXXXX.
  final String phone;
  final String? email;
  final RequestProgress progress;

  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  MyRequest withProgress(RequestProgress next) =>
      MyRequest(id: id, name: name, phone: phone, email: email, progress: next);

  factory MyRequest.fromJson(Map<String, dynamic> json) => MyRequest(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    email: json['email'] as String?,
    progress: RequestProgress.fromJson(
      (json['progress'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'email': email,
    'progress': progress.toJson(),
  };
}

final myRequestProvider = NotifierProvider<MyRequestStore, MyRequest?>(
  MyRequestStore.new,
);

/// Keeps [MyRequest] on the phone, so the welcome screen can offer
/// "Track my request" after the app is closed and opened again.
class MyRequestStore extends Notifier<MyRequest?> {
  static const _key = 'my_event_request';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  MyRequest? build() => _load(_prefs);

  static MyRequest? _load(SharedPreferences prefs) {
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return MyRequest.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Unreadable: forget it rather than show something wrong.
      prefs.remove(_key);
      return null;
    }
  }

  Future<void> save(MyRequest request) async {
    state = request;
    await _prefs.setString(_key, jsonEncode(request.toJson()));
  }

  Future<void> updateProgress(RequestProgress progress) async {
    final current = state;
    if (current == null) return;
    await save(current.withProgress(progress));
  }

  /// Back to "Plan an event": after they sign in to their event, or once
  /// they've seen it closed.
  Future<void> clear() async {
    state = null;
    await _prefs.remove(_key);
  }
}
