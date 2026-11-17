import 'package:eventapp/features/event_request/services/my_request_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  RequestStage stageOf(String status, {bool eventReady = false}) =>
      RequestProgress.fromApi({
        'status': status,
        'receivedAt': '2026-11-16T11:02:00.000Z',
        'eventReady': eventReady,
      }).stage;

  test('portal statuses map to the steps the customer sees', () {
    expect(stageOf('new'), RequestStage.received);
    expect(stageOf('contacted'), RequestStage.contacted);
    expect(stageOf('booked', eventReady: true), RequestStage.ready);
    expect(stageOf('closed'), RequestStage.closed);
  });

  test('booked before the event exists is still being set up', () {
    expect(stageOf('booked'), RequestStage.contacted);
  });

  test('an unknown status shows as received, not as an error', () {
    expect(stageOf('something_new'), RequestStage.received);
  });

  test('a saved request reads back the same', () {
    final request = MyRequest(
      id: '3f0c1d2e-0000-4000-8000-000000000001',
      name: 'Amina Juma',
      phone: '255712345678',
      email: null,
      progress: RequestProgress(
        stage: RequestStage.contacted,
        receivedAt: DateTime.utc(2026, 11, 16, 11, 2),
        contactedAt: DateTime.utc(2026, 11, 17, 6, 30),
      ),
    );
    final back = MyRequest.fromJson(request.toJson());
    expect(back.id, request.id);
    expect(back.firstName, 'Amina');
    expect(back.progress.stage, RequestStage.contacted);
    expect(back.progress.contactedAt, request.progress.contactedAt!.toLocal());
  });
}
