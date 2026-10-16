import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workspace/forex/data/notification_options.dart';
import 'package:flutter_workspace/forex/data/prefs.dart';
import 'package:flutter_workspace/forex/economic_alerts.dart';
import 'package:flutter_workspace/forex/ff_models.dart';
import 'package:flutter_workspace/forex/crypto/crypto_client.dart';
import 'package:flutter_workspace/forex/live/live_notification.dart';
import 'package:flutter_workspace/forex/settings/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

FfEvent _event(int id, DateTime at, {String impact = 'high'}) => FfEvent(
  id: id,
  name: 'CPI',
  currency: 'USD',
  impact: impact,
  time: at,
  actual: '',
  forecast: '',
  previous: '',
  betterWorse: 0,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('concurrent reminders send once and failed delivery can retry', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'high_impact_alerts': true,
      'alert_lead_minutes': 0,
    });
    const channel = MethodChannel('dexterous.com/flutter/local_notifications');
    var sends = 0;
    var failNext = false;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'initialize') return true;
      if (call.method == 'show') {
        sends++;
        if (failNext) {
          failNext = false;
          throw PlatformException(code: 'delivery_failed');
        }
      }
      return null;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    final events = [_event(31, DateTime.now())];
    await Future.wait([
      EconomicAlerts.notifyDue(events, background: true),
      EconomicAlerts.notifyDue(events, background: true),
    ]);
    expect(sends, 1);
    final sp = await SharedPreferences.getInstance();
    await sp.remove('economic_alerts_sent');
    failNext = true;
    await EconomicAlerts.notifyDue(events, background: true);
    expect(sp.getStringList('economic_alerts_sent') ?? [], isEmpty);
    await EconomicAlerts.notifyDue(events, background: true);
    expect(sends, 3);
    expect(sp.getStringList('economic_alerts_sent'), hasLength(1));
  }, variant: TargetPlatformVariant({TargetPlatform.android}));

  test('only enabled high-impact events in the reminder window are due', () {
    final now = DateTime(2026, 10, 16, 12);
    final events = [
      _event(1, now.add(const Duration(minutes: 5))),
      _event(2, now.add(const Duration(minutes: 3))),
      _event(3, now.add(const Duration(minutes: 2))),
      _event(4, now.add(const Duration(minutes: 6))),
      _event(5, now.add(const Duration(minutes: 5)), impact: 'medium'),
    ];
    const enabled = NotificationOptions(alerts: true);
    expect(EconomicAlerts.dueEvents(events, enabled, now).map((e) => e.id), [
      1,
      2,
    ]);
    expect(
      EconomicAlerts.dueEvents(events, const NotificationOptions(), now),
      isEmpty,
    );
    final atRelease = [
      _event(6, now),
      _event(7, now.add(const Duration(seconds: 1))),
    ];
    expect(
      EconomicAlerts.dueEvents(
        atRelease,
        enabled.copyWith(leadMinutes: 0),
        now,
      ).map((e) => e.id),
      [6],
    );
  });

  test(
    'notification choices survive reload and reject empty content',
    () async {
      SharedPreferences.setMockInitialValues({});
      const options = NotificationOptions(
        sections: {'prices', 'events'},
        featuredCoin: 'ethereum',
        alerts: true,
        leadMinutes: 15,
      );
      await Prefs.setNotificationOptions(options);
      final saved = await Prefs.notificationOptions();
      expect(saved.sections, {'prices', 'events'});
      expect(saved.featuredCoin, 'ethereum');
      expect(saved.alerts, true);
      expect(saved.leadMinutes, 15);
      await expectLater(
        Prefs.setNotificationOptions(options.copyWith(sections: {'change'})),
        throwsArgumentError,
      );
      expect((await Prefs.notificationOptions()).sections, {
        'prices',
        'events',
      });
    },
  );

  test(
    'a hidden percentage stays out of notification text and is flagged for Android',
    () {
      final snapshot = MarketSnapshot(
        prices: [
          CryptoPrice(
            id: 'bitcoin',
            symbol: 'BTC',
            usd: 100,
            change24h: 2,
            decimals: 2,
          ),
        ],
        bob: null,
        events: [],
        updatedAt: DateTime(2026, 10, 16),
        selectedCount: 1,
        showChanges: false,
      );
      expect(snapshot.summary, 'BTC \$100.00');
      expect(snapshot.lines.single, isNot(contains('%')));
      expect(snapshot.toMap(ongoing: true)['showChanges'], false);
    },
  );

  testWidgets(
    'panel content and featured coin can be saved independently of the watchlist',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'selected_coins': ['bitcoin', 'ethereum'],
      });
      await tester.pumpWidget(
        MaterialApp(
          home: AppFlowyTheme(
            data: AppFlowyDefaultTheme().light(),
            child: const SettingsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Contenido del panel'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('USD/BOB'));
      await tester.tap(find.text('USD/BOB'));
      await tester.pumpAndSettle();
      expect(
        (await Prefs.notificationOptions()).sections,
        isNot(contains('bob')),
      );
      await tester.ensureVisible(find.byType(DropdownButton<String>));
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ETH').last);
      await tester.pumpAndSettle();
      expect((await Prefs.notificationOptions()).featuredCoin, 'ethereum');
      expect(await Prefs.coins(), ['bitcoin', 'ethereum']);
    },
    variant: TargetPlatformVariant({TargetPlatform.linux}),
  );
}
