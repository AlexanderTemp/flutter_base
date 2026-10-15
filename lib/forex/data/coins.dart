// Catálogo de monedas disponibles para trackear (id de CoinGecko, símbolo,
// decimales). Basado en tu coinwatch.py + algunas comunes.
class Coin {
  const Coin(this.id, this.symbol, this.decimals);
  final String id;
  final String symbol;
  final int decimals;
}

const kCoins = <Coin>[
  Coin('bitcoin', 'BTC', 2),
  Coin('ethereum', 'ETH', 2),
  Coin('ripple', 'XRP', 4),
  Coin('binancecoin', 'BNB', 2),
  Coin('solana', 'SOL', 2),
  Coin('sui', 'SUI', 4),
  Coin('cardano', 'ADA', 4),
  Coin('dogecoin', 'DOGE', 5),
  Coin('tron', 'TRX', 4),
  Coin('chainlink', 'LINK', 3),
  Coin('avalanche-2', 'AVAX', 3),
  Coin('polkadot', 'DOT', 3),
];

/// Selección por defecto (≥4), tu watchlist principal.
const kDefaultCoins = <String>['bitcoin', 'ethereum', 'ripple', 'binancecoin'];

Coin? coinById(String id) {
  for (final c in kCoins) {
    if (c.id == id) return c;
  }
  return null;
}
