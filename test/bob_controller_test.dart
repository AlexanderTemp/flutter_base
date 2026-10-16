import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workspace/forex/bob/bob_client.dart';
import 'package:flutter_workspace/forex/bob/bob_controller.dart';
import 'package:flutter_workspace/forex/data/prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _BobClient extends BobClient {
  final response = Completer<BobRate?>();
  final requested = Completer<void>();

  @override
  Future<BobRate?> fetch() {
    requested.complete();
    return response.future;
  }
}

class _RecoveringClient extends BobClient {
  BobRate? result;
  @override
  Future<BobRate?> fetch() async => result;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'saved BOB history survives failures and is replaced by a fresh response',
    () async {
      final savedAt = DateTime(2026, 10, 15, 12);
      final saved = BobRate(
        value: '11,68',
        vigencia: '16 de octubre de 2026',
        date: DateTime(2026, 10, 16),
        history: [BobPoint(date: DateTime(2026, 10, 16), cents: 1168)],
      );
      SharedPreferences.setMockInitialValues({
        'bob_cache': jsonEncode({
          'fetchedAt': savedAt.toIso8601String(),
          'rate': saved.toJson(),
        }),
      });
      final client = _RecoveringClient()..warning = 'Sin conexión';
      final controller = BobController(client: client);
      addTearDown(controller.dispose);
      await controller.load();
      expect(controller.rate!.history.single.cents, 1168);
      expect(controller.lastUpdated, savedAt);
      expect(controller.showingPrevious, true);
      client.warning = null;
      client.result = BobRate(
        value: '11,70',
        vigencia: '17 de octubre de 2026',
        date: DateTime(2026, 10, 17),
        history: [BobPoint(date: DateTime(2026, 10, 17), cents: 1170)],
      );
      await controller.load();
      expect(controller.rate!.value, '11,70');
      expect(controller.showingPrevious, false);
      expect(controller.error, isNull);
      final persisted =
          jsonDecode((await Prefs.bobCache())!) as Map<String, dynamic>;
      expect((persisted['rate'] as Map)['value'], '11,70');
    },
  );
  test(
    'startup future waits for the initial data and allows disposal during a load',
    () async {
      SharedPreferences.setMockInitialValues({});
      final client = _BobClient();
      final controller = BobController(client: client);
      var completed = false;
      final startup = controller.start().then((_) => completed = true);
      await client.requested.future;
      expect(controller.loading, true);
      expect(completed, false);
      controller.dispose();
      client.response.complete(null);
      await startup;
      expect(completed, true);
    },
  );
}
