import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/constants/api_config.dart';
import '../../../l10n/l10n.dart';

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

  Future<void> send(EventRequestDraft draft) async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    final url = '$serverUrl${ApiConfig.eventRequestsPath}';

    try {
      final response = await dio.post(url, data: draft.toJson());
      debugPrint('[event-request] POST $url -> ${response.statusCode}');
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
