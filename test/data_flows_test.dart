import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workspace/forex/crypto/crypto_client.dart';
import 'package:flutter_workspace/forex/crypto/crypto_controller.dart';
import 'package:flutter_workspace/forex/data/prefs.dart';
import 'package:flutter_workspace/forex/news/news_client.dart';
import 'package:flutter_workspace/forex/news/news_controller.dart';
import 'package:flutter_workspace/forex/news/news_models.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NewsClient extends NewsClient {
  Future<List<NewsItem>> Function() response = () async => [];
  int calls = 0;

  @override
  Future<List<NewsItem>> fetchAll() {
    calls++;
    return response();
  }
}

class _CryptoClient extends CryptoClient {
  final ids = <List<String>>[];
  final requests = <Completer<List<CryptoPrice>>>[];
  final firstRequested = Completer<void>();
  final secondRequested = Completer<void>();

  @override
  Future<List<CryptoPrice>> fetch(List<String> selected) {
    ids.add(List.of(selected));
    final request = Completer<List<CryptoPrice>>();
    requests.add(request);
    if (requests.length == 1) firstRequested.complete();
    if (requests.length == 2) secondRequested.complete();
    return request.future;
  }
}

CryptoPrice _price(String id) =>
    CryptoPrice(id: id, symbol: id, usd: 100, change24h: 0, decimals: 2);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'news suppresses overlapping loads and late updates after disposal',
    () async {
      final response = Completer<List<NewsItem>>();
      final client = _NewsClient()..response = () => response.future;
      final controller = NewsController(client: client);
      final first = controller.load(silent: true);
      await controller.load();
      expect(client.calls, 1);
      controller.dispose();
      response.complete([]);
      await first;
    },
  );

  test(
    'failed RSS refresh keeps headlines and their successful timestamp',
    () async {
      final client = _NewsClient()
        ..response = () async => [
          NewsItem(title: 'Titular guardado', link: '', source: 'Prueba'),
        ];
      final controller = NewsController(client: client);
      addTearDown(controller.dispose);
      await controller.load();
      final at = controller.lastUpdated;
      client.response = () async => [];
      await controller.load();
      expect(controller.items.single.title, 'Titular guardado');
      expect(controller.lastUpdated, at);
      expect(controller.error, isNotNull);
    },
  );

  test(
    'changing the watchlist during a request loads the latest selection next',
    () async {
      SharedPreferences.setMockInitialValues({
        'selected_coins': ['bitcoin'],
      });
      final client = _CryptoClient();
      final controller = CryptoController(client: client);
      addTearDown(controller.dispose);
      final load = controller.load();
      await client.firstRequested.future;
      await Prefs.setCoins(['ethereum']);
      await controller.reloadSelection();
      client.requests.first.complete([_price('bitcoin')]);
      await client.secondRequested.future;
      expect(client.ids, [
        ['bitcoin'],
        ['ethereum'],
      ]);
      client.requests.last.complete([_price('ethereum')]);
      await load;
      expect(controller.prices.single.id, 'ethereum');
      expect(controller.loading, false);
    },
  );

  test(
    'RSS numeric time zones preserve the actual publication instant',
    () async {
      final client = NewsClient(
        client: MockClient(
          (_) async => http.Response('''
<rss><channel><item><title>Dato</title><link>https://example.com/news</link>
<pubDate>Fri, 16 Oct 2026 14:30:00 -0400</pubDate></item></channel></rss>
''', 200),
        ),
      );
      addTearDown(client.close);
      final items = await client.fetchAll();
      expect(items, isNotEmpty);
      for (final item in items) {
        expect(item.published!.toUtc(), DateTime.utc(2026, 10, 16, 18, 30));
      }
    },
  );

  test(
    'missing quote fields do not become a zero price or a fake percentage',
    () async {
      final client = CryptoClient(
        client: MockClient(
          (_) async => http.Response(
            '{"bitcoin":{"usd":100,"usd_24h_change":0},"ethereum":{"usd":null,"usd_24h_change":2},"audit-no-change":{"usd":1}}',
            200,
          ),
        ),
      );
      addTearDown(client.close);
      final prices = await client.fetch([
        'bitcoin',
        'ethereum',
        'audit-no-change',
      ]);
      expect(prices.map((p) => p.id), ['bitcoin']);
      expect(prices.single.change24h, 0);
      await expectLater(client.fetch(['audit-invalid']), throwsFormatException);
    },
  );
}
