import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workspace/forex/bob/bob_controller.dart';
import 'package:flutter_workspace/forex/analysis/analysis_view.dart';
import 'package:flutter_workspace/forex/crypto/crypto_client.dart';
import 'package:flutter_workspace/forex/crypto/crypto_controller.dart';
import 'package:flutter_workspace/forex/data/coins.dart';
import 'package:flutter_workspace/forex/data/prefs.dart';
import 'package:flutter_workspace/forex/ff_models.dart';
import 'package:flutter_workspace/forex/forex_controller.dart';
import 'package:flutter_workspace/forex/live/live_notification.dart';
import 'package:flutter_workspace/forex/news/news_controller.dart';
import 'package:flutter_workspace/forex/news/news_models.dart';
import 'package:flutter_workspace/forex/news/news_view.dart';
import 'package:flutter_workspace/forex/settings/settings_page.dart';
import 'package:flutter_workspace/forex/widgets/price_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ForexController extends ForexController {
  _ForexController(this.fixture);
  final List<FfEvent> fixture;

  @override
  List<FfEvent> get calendarEvents => fixture;
}

class _CryptoClient extends CryptoClient {
  @override
  Future<List<CryptoPrice>> fetch(List<String> ids) async => [
    for (final id in ids)
      CryptoPrice(
        id: id,
        symbol: coinById(id)!.symbol,
        usd: 120,
        change24h: -2.5,
        decimals: 2,
      ),
  ];
}

Widget _app(Widget child, {bool reducedMotion = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reducedMotion),
    child: AppFlowyTheme(data: AppFlowyDefaultTheme().light(), child: child),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('warning, badges and price text keep contrast in both themes', () {
    double contrast(Color a, Color b) {
      final x = a.computeLuminance();
      final y = b.computeLuminance();
      return x > y ? (x + .05) / (y + .05) : (y + .05) / (x + .05);
    }

    for (final theme in [
      AppFlowyDefaultTheme().light(),
      AppFlowyDefaultTheme().dark(),
    ]) {
      expect(
        contrast(
          theme.textColorScheme.primary,
          theme.fillColorScheme.warningLight,
        ),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(
          theme.textColorScheme.warning,
          theme.fillColorScheme.warningLight,
        ),
        greaterThanOrEqualTo(3),
      );
      expect(
        contrast(theme.textColorScheme.info, theme.fillColorScheme.infoLight),
        greaterThanOrEqualTo(4.5),
      );
      for (final surface in [
        theme.surfaceColorScheme.primary,
        theme.surfaceColorScheme.layer02,
      ]) {
        expect(
          contrast(theme.textColorScheme.success, surface),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(theme.textColorScheme.error, surface),
          greaterThanOrEqualTo(4.5),
        );
      }
      final badge = Color.alphaBlend(
        theme.textColorScheme.tertiary.withValues(alpha: .06),
        theme.surfaceColorScheme.primary,
      );
      expect(
        contrast(theme.textColorScheme.secondary, badge),
        greaterThanOrEqualTo(4.5),
      );
    }
  });

  test('an empty saved watchlist stays empty and removes old prices', () async {
    SharedPreferences.setMockInitialValues({
      'selected_coins': ['bitcoin'],
    });
    final controller = CryptoController(client: _CryptoClient());
    addTearDown(controller.dispose);
    await controller.reloadSelection();
    expect(controller.prices.single.symbol, 'BTC');
    await Prefs.setCoins([]);
    await controller.reloadSelection();
    expect(await Prefs.coins(), isEmpty);
    expect(controller.prices, isEmpty);
    expect(controller.error, isNull);
  });

  test('market panel preserves signs, precision and event dates', () {
    final snapshot = MarketSnapshot(
      prices: [
        CryptoPrice(
          id: 'bitcoin',
          symbol: 'BTC',
          usd: 123456.78,
          change24h: -2.5,
          decimals: 2,
        ),
      ],
      bob: null,
      updatedAt: DateTime(2026, 10, 16, 12, 30),
      selectedCount: 5,
      events: [
        FfEvent(
          id: 1,
          name: 'CPI',
          currency: 'USD',
          impact: 'high',
          time: DateTime(2026, 10, 17, 9),
          actual: '',
          forecast: '',
          previous: '',
          betterWorse: 0,
        ),
      ],
    );
    final payload = snapshot.toMap(ongoing: true);
    expect(payload['ongoing'], true);
    expect(payload['selectedCount'], 5);
    expect((payload['prices'] as List).single, {
      'symbol': 'BTC',
      'price': '\$123,456.78',
      'change': '-2.50%',
      'up': false,
    });
    expect(payload['events'], ['Mañana 09:00 · USD CPI']);
    expect(payload['time'], '12:30');
    expect(snapshot.summary, 'BTC \$123,456.78 -2.50%');
  });

  testWidgets('news filters published impact without assigning it to RSS', (
    tester,
  ) async {
    final forex = _ForexController([
      for (final impact in ['high', 'medium', 'low'])
        FfEvent(
          id: impact.hashCode,
          name: 'Indicador $impact',
          currency: 'USD',
          impact: impact,
          time: DateTime(2026, 10, 16, 14),
          actual: '',
          forecast: '1',
          previous: '2',
          betterWorse: 0,
        ),
    ]);
    final news = NewsController()
      ..items = [
        NewsItem(
          title: 'Titular sin clasificación',
          link: '',
          source: 'FXStreet',
        ),
      ];
    addTearDown(forex.dispose);
    addTearDown(news.dispose);
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: NewsView(controller: news, forex: forex),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Indicador high'), findsOneWidget);
    expect(find.text('Indicador low'), findsOneWidget);
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Alto impacto'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Alto impacto'));
    await tester.pumpAndSettle();
    expect(find.text('Indicador high'), findsOneWidget);
    expect(find.text('Indicador low'), findsNothing);
    expect(find.text('16/10/2026'), findsOneWidget);
    await tester.ensureVisible(
      find.widgetWithText(ChoiceChip, 'Titulares RSS'),
    );
    await tester.tap(find.widgetWithText(ChoiceChip, 'Titulares RSS'));
    await tester.pumpAndSettle();
    expect(find.text('Titular sin clasificación'), findsOneWidget);
    expect(find.text('Sin impacto publicado'), findsOneWidget);
  });

  testWidgets(
    'analysis fits a narrow screen and preserves small coin precision',
    (tester) async {
      final forex = _ForexController([]);
      final crypto = CryptoController();
      addTearDown(forex.dispose);
      addTearDown(crypto.dispose);
      crypto.prices = [
        CryptoPrice(
          id: 'shiba-inu',
          symbol: 'SHIB',
          usd: .00000123,
          change24h: 1,
          decimals: 8,
        ),
        ...await _CryptoClient().fetch(kCoins.map((coin) => coin.id).toList()),
      ];
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: SizedBox(
              width: 320,
              child: AnalysisView(forex: forex, crypto: crypto),
            ),
          ),
        ),
      );
      expect(find.text('\$0.00000123'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('RSS links with unsupported schemes are not opened', (
    tester,
  ) async {
    final forex = _ForexController([]);
    final news = NewsController()
      ..items = [
        NewsItem(
          title: 'Enlace no válido',
          link: 'file:///private/data',
          source: 'Prueba',
        ),
      ];
    addTearDown(forex.dispose);
    addTearDown(news.dispose);
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: NewsView(controller: news, forex: forex),
        ),
      ),
    );
    await tester.tap(find.widgetWithText(ChoiceChip, 'Titulares RSS'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enlace no válido'));
    await tester.pumpAndSettle();
    expect(find.text('No se pudo abrir la noticia.'), findsOneWidget);
  });

  testWidgets('price ribbon moves automatically and respects reduced motion', (
    tester,
  ) async {
    final crypto = CryptoController(client: _CryptoClient());
    final bob = BobController();
    addTearDown(crypto.dispose);
    addTearDown(bob.dispose);
    crypto.prices = await _CryptoClient().fetch(kDefaultCoins);
    Widget ribbon(bool reducedMotion) => _app(
      Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 260,
            child: PriceBar(crypto: crypto, bob: bob),
          ),
        ),
      ),
      reducedMotion: reducedMotion,
    );
    await tester.pumpWidget(ribbon(false));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    final scroll = tester
        .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
        .controller!;
    expect(scroll.offset, greaterThan(0));
    await tester.tap(find.byTooltip('Pausar cinta de precios'));
    await tester.pump();
    final manuallyPaused = scroll.offset;
    await tester.pump(const Duration(seconds: 4));
    expect(scroll.offset, manuallyPaused);
    await tester.tap(find.byTooltip('Reanudar cinta de precios'));
    await tester.pump();
    final touch = await tester.startGesture(
      tester.getCenter(find.byType(PriceBar)),
    );
    final paused = scroll.offset;
    await tester.pump(const Duration(milliseconds: 100));
    expect(scroll.offset, paused);
    await touch.up();
    await tester.pumpWidget(ribbon(true));
    final stopped = scroll.offset;
    await tester.pump(const Duration(seconds: 5));
    expect(scroll.offset, stopped);
    await tester.pumpWidget(ribbon(false));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(scroll.offset, greaterThan(stopped));
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings shows app information and developer credits', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(_app(const SettingsPage()));
    await tester.pumpAndSettle();
    final about = find.text('Acerca de Tradex');
    await tester.ensureVisible(about);
    await tester.tap(about);
    await tester.pumpAndSettle();
    expect(find.byType(AboutDialog), findsOneWidget);
    expect(find.text('Desarrollado por Aynicode'), findsOneWidget);
    expect(find.textContaining('Fuentes: Forex Factory'), findsOneWidget);
  }, variant: TargetPlatformVariant({TargetPlatform.linux}));

  testWidgets('settings searches the expanded catalog and saves a selection', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'selected_coins': <String>[]});
    await tester.pumpWidget(_app(const SettingsPage()));
    await tester.pumpAndSettle();
    expect(find.text('Ajustes'), findsOneWidget);
    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'paxg');
    await tester.pumpAndSettle();
    expect(find.text('PAXG'), findsOneWidget);
    expect(find.text('BTC'), findsNothing);
    await tester.ensureVisible(find.text('PAXG'));
    await tester.tap(find.text('PAXG'));
    await tester.pumpAndSettle();
    expect(await Prefs.coins(), ['pax-gold']);
    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'no-existe');
    await tester.pumpAndSettle();
    expect(find.text('No hay monedas con estos filtros.'), findsOneWidget);
  }, variant: TargetPlatformVariant({TargetPlatform.linux}));
}
