import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/constants/api_config.dart';
import '../../../l10n/l10n.dart';
import 'my_request_store.dart';

/// Cardly's own numbers, for people who'd rather call or WhatsApp.
class CardlyContact {
  CardlyContact._();

  static const whatsapp = '255618298314';
  static const callNumbers = ['255618298314', '255658349329'];

  /// "255618298314" → "0618 298 314".
  static String display(String phone) {
    final local = phone.startsWith('255') ? '0${phone.substring(3)}' : phone;
    if (local.length != 10) return local;
    return '${local.substring(0, 4)} ${local.substring(4, 7)} ${local.substring(7)}';
  }
}

enum EventType {
  wedding('wedding'),
  sendOff('send_off'),
  kitchenParty('kitchen_party'),
  birthday('birthday'),
  corporate('corporate'),
  other('other');

  const EventType(this.apiValue);
  final String apiValue;

  String label(AppLocalizations l10n) => switch (this) {
    wedding => l10n.eventTypeWedding,
    sendOff => l10n.eventTypeSendOff,
    kitchenParty => l10n.eventTypeKitchenParty,
    birthday => l10n.eventTypeBirthday,
    corporate => l10n.eventTypeCorporate,
    other => l10n.eventTypeOther,
  };
}

enum GuestRange {
  under100('under_100', null),
  from100('100_300', '100–300'),
  from300('300_600', '300–600'),
  over600('600_plus', '600+');

  const GuestRange(this.apiValue, this._label);
  final String apiValue;
  final String? _label;

  String label(AppLocalizations l10n) => _label ?? l10n.guestsUnder100;
}

class EventRequestDraft {
  const EventRequestDraft({
    required this.name,
    required this.phone,
    required this.email,
    required this.eventType,
    required this.eventDate,
    required this.venue,
    required this.guestRange,
    required this.note,
  });

  final String name;

  /// 255XXXXXXXXX.
  final String phone;
  final String? email;
  final EventType eventType;
  final DateTime? eventDate;
  final String venue;
  final GuestRange guestRange;
  final String? note;

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'email': email,
    'eventType': eventType.apiValue,
    'eventDate': eventDate == null
        ? null
        : '${eventDate!.year.toString().padLeft(4, '0')}-'
              '${eventDate!.month.toString().padLeft(2, '0')}-'
              '${eventDate!.day.toString().padLeft(2, '0')}',
    'venue': venue,
    'guestRange': guestRange.apiValue,
    'note': note,
  };
}

/// Why sending failed, in words the person can act on. [fields] holds the
/// server's message for each field it rejected, keyed like [toJson].
class EventRequestException implements Exception {
  EventRequestException(this.message, {this.fields = const {}});

  final String message;
  final Map<String, String> fields;

  @override
  String toString() => message;
}

/// What a "choose your password" link from the SMS or email is for: the
/// request the event was made from, and its owner's contacts, masked.
class SetupLinkTarget {
  const SetupLinkTarget({
    required this.requestId,
    required this.name,
    this.smsHint,
    this.emailHint,
  });

  final String requestId;
  final String name;
  final String? smsHint;
  final String? emailHint;

  String get firstName => name.trim().split(RegExp(r'\s+')).first;
}

/// Why a "choose your password" link can't be used.
enum SetupLinkProblem { invalid, used, expired, offline, unknown }

class SetupLinkException implements Exception {
  const SetupLinkException(this.problem);
  final SetupLinkProblem problem;
}

final eventRequestServiceProvider = Provider<EventRequestService>(
  EventRequestService.new,
);

/// Sends a "Plan an event" request. No account needed: the portal saves
/// it, texts and emails the person, and alerts the Cardly team. The app
/// never talks to the SMS or email services itself.
class EventRequestService {
  EventRequestService(this._ref);

  final Ref _ref;

  /// Where requests go. Dev builds show it on the form, so a request that
  /// went to the wrong server is obvious.
  String get serverUrl =>
      AppEnvironment.baseUrl(_ref.read(sharedPreferencesProvider));

  Dio get _dio => Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  /// Sends the request and remembers it on this phone, so the person can
  /// track it later.
  Future<void> send(EventRequestDraft draft) async {
    final url = '$serverUrl${ApiConfig.eventRequestsPath}';

    try {
      final response = await _dio.post(url, data: draft.toJson());
      debugPrint('[event-request] POST $url -> ${response.statusCode}');
      final data = response.data;
      final id = data is Map ? data['id'] as String? : null;
      if (id != null) {
        await _ref
            .read(myRequestProvider.notifier)
            .save(
              MyRequest(
                id: id,
                name: draft.name,
                phone: draft.phone,
                email: draft.email,
                progress: RequestProgress(
                  stage: RequestStage.received,
                  receivedAt: DateTime.now(),
                ),
              ),
            );
      }
    } on DioException catch (error) {
      // Shows in `adb logcat` even in release builds.
      debugPrint(
        '[event-request] POST $url failed: ${error.type.name} '
        '${error.response?.statusCode ?? ''} ${error.response?.data ?? error.message ?? ''}',
      );
      final explained = _explain(error);
      if (AppEnvironment.isProd) throw explained;
      // Dev builds say exactly what went wrong.
      throw EventRequestException(
        '${explained.message}\n[dev] ${error.response?.statusCode ?? error.type.name} from $url',
        fields: explained.fields,
      );
    }
  }

  /// Asks the portal where the request is now and saves the answer. A
  /// request the portal no longer has counts as closed.
  Future<RequestProgress> refreshStatus(MyRequest request) async {
    final url = '$serverUrl${ApiConfig.eventRequestsPath}/${request.id}';
    RequestProgress progress;
    try {
      final response = await _dio.get(url);
      progress = RequestProgress.fromApi(
        (response.data as Map).cast<String, dynamic>(),
      );
    } on DioException catch (error) {
      debugPrint(
        '[event-request] GET $url failed: ${error.type.name} '
        '${error.response?.statusCode ?? ''}',
      );
      // Only the portal's own "not found" (JSON) means the request is
      // gone. A server without this route answers 404 too, as a page.
      final gone =
          error.response?.statusCode == 404 && error.response?.data is Map;
      if (!gone) throw _explain(error);
      progress = RequestProgress(
        stage: RequestStage.closed,
        receivedAt: request.progress.receivedAt,
        contactedAt: request.progress.contactedAt,
        closedAt: request.progress.closedAt ?? DateTime.now(),
      );
    }
    await _ref.read(myRequestProvider.notifier).updateProgress(progress);
    return progress;
  }

  /// Opens a "choose your password" link (`/set-password/<token>`) in the
  /// app. The token is the only proof the link needs, so it's never logged.
  Future<SetupLinkTarget> lookUpSetupLink(String token) async {
    try {
      final response = await _dio.get(
        '$serverUrl${ApiConfig.accountSetupPath(token)}',
      );
      final data = (response.data as Map).cast<String, dynamic>();
      return SetupLinkTarget(
        requestId: data['requestId'] as String,
        name: data['name'] as String? ?? '',
        smsHint: data['smsHint'] as String?,
        emailHint: data['emailHint'] as String?,
      );
    } on DioException catch (error) {
      debugPrint(
        '[event-request] setup link check failed: ${error.type.name} '
        '${error.response?.statusCode ?? ''}',
      );
      final data = error.response?.data;
      throw SetupLinkException(switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.connectionError => SetupLinkProblem.offline,
        _ => switch (data is Map ? data['reason'] : null) {
          'invalid' => SetupLinkProblem.invalid,
          'used' => SetupLinkProblem.used,
          'expired' => SetupLinkProblem.expired,
          _ => SetupLinkProblem.unknown,
        },
      });
    } catch (_) {
      throw const SetupLinkException(SetupLinkProblem.unknown);
    }
  }

  EventRequestException _explain(DioException error) {
    final data = error.response?.data;
    final serverMessage = data is Map ? data['error'] as String? : null;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionError:
        return EventRequestException(appL10n.requestUnreachable);
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode ?? 0;
        if (status == 422 && data is Map && data['fields'] is Map) {
          return EventRequestException(
            serverMessage ?? appL10n.requestCheckFields,
            fields: (data['fields'] as Map).map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            ),
          );
        }
        if (status == 429) {
          return EventRequestException(serverMessage ?? appL10n.requestTooMany);
        }
        return EventRequestException(serverMessage ?? appL10n.requestFailed);
      default:
        return EventRequestException(
          "We couldn't send your request. Please try again.",
        );
    }
  }
}
