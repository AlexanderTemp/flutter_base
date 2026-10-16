import 'dart:convert';

import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workspace/forex/calendar_view.dart';
import 'package:flutter_workspace/forex/ff_exception.dart';
import 'package:flutter_workspace/forex/ff_feed_client.dart';
import 'package:flutter_workspace/forex/ff_models.dart';
import 'package:flutter_workspace/forex/forex_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FeedClient extends FfFeedClient {
  _FeedClient(this.response, this.fetchedAt);
  Future<List<FfEvent>> Function() response;
  DateTime? fetchedAt;

  @override
  DateTime? get lastFetchedAt => fetchedAt;

  @override
  Future<List<FfEvent>> fetchWeek() => response();
}

FfEvent _event(int id) => FfEvent(
  id: id,
  name: 'Evento $id',
  currency: 'USD',
  impact: 'high',
  time: DateTime(2020, 1, id, 9),
  actual: '',
  forecast: '2%',
  previous: '1%',
  betterWorse: 0,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'saved calendar survives restart and is replaced when the feed recovers',
    () async {
      SharedPreferences.setMockInitialValues({});
      final at = DateTime(2020, 1, 1, 8);
      final first = ForexController(
        client: _FeedClient(() async => [_event(1)], at),
      );
      await first.load();
      first.dispose();

      final client = _FeedClient(
        () async => throw FfException('Límite temporal'),
        null,
      );
      final restored = ForexController(client: client);
      addTearDown(restored.dispose);
      await restored.load();
      expect(restored.canShowPrevious, true);
      expect(restored.calendarEvents, isEmpty);
      restored.showPreviousData();
      expect(restored.events.single.id, 1);
      expect(restored.scope, ForexScope.week);
      expect(restored.showingPrevious, true);
      expect(restored.lastUpdated, at);

      client.response = () async => [_event(2)];
      client.fetchedAt = DateTime(2020, 1, 2, 8);
      await restored.load();
      expect(restored.calendarEvents.single.id, 2);
      expect(restored.showingPrevious, false);
      expect(restored.error, isNull);
      expect(restored.lastUpdated, client.fetchedAt);

      client.warning = 'El servicio sigue limitado';
      await restored.load();
      expect(restored.calendarEvents.single.id, 2);
      expect(restored.lastUpdated, client.fetchedAt);
      expect(restored.showingPrevious, true);
    },
  );

  test('a first failed download cannot invent previous events', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = ForexController(
      client: _FeedClient(
        () async => throw FfException('Límite temporal'),
        null,
      ),
    );
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.canShowPrevious, false);
    controller.showPreviousData();
    expect(controller.calendarEvents, isEmpty);
    expect(controller.lastUpdated, isNull);
    expect(controller.error, 'Límite temporal');
  });

  testWidgets('previous data button exposes the saved calendar and its date', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'calendar_cache': jsonEncode({
        'fetchedAt': DateTime(2020, 1, 1, 8).toIso8601String(),
        'events': [_event(1).toJson()],
      }),
    });
    final controller = ForexController(
      client: _FeedClient(
        () async => throw FfException('Límite temporal'),
        null,
      ),
    );
    addTearDown(controller.dispose);
    await controller.load();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: AppFlowyTheme(
          data: AppFlowyDefaultTheme().dark(),
          child: Scaffold(
            body: AnimatedBuilder(
              animation: controller,
              builder: (_, __) => CalendarFeedStatus(controller: controller),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Mostrar datos anteriores'));
    await tester.pumpAndSettle();
    expect(controller.calendarEvents.single.id, 1);
    expect(find.text('Datos anteriores'), findsOneWidget);
    expect(find.textContaining('Guardados el 01/01/2020'), findsOneWidget);
    expect(find.text('Mostrar datos anteriores'), findsNothing);
    expect(
      tester.getSize(find.byType(CalendarFeedStatus)).height,
      lessThan(110),
    );
    expect(find.text('Límite temporal'), findsNothing);
    await tester.tap(find.text('Datos anteriores'));
    await tester.pumpAndSettle();
    expect(find.text('Límite temporal'), findsOneWidget);
    expect(find.text('Reintentar ahora'), findsOneWidget);
  });
}
