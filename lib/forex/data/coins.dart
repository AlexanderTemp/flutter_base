// Catálogo de monedas disponibles para trackear (id de CoinGecko, símbolo,
// decimales). Los precios proceden de CoinGecko.
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
  Coin('tether', 'USDT', 4),
  Coin('usd-coin', 'USDC', 4),
  Coin('staked-ether', 'STETH', 2),
  Coin('wrapped-bitcoin', 'WBTC', 2),
  Coin('the-open-network', 'TON', 4),
  Coin('litecoin', 'LTC', 2),
  Coin('bitcoin-cash', 'BCH', 2),
  Coin('stellar', 'XLM', 5),
  Coin('hedera-hashgraph', 'HBAR', 5),
  Coin('hyperliquid', 'HYPE', 3),
  Coin('monero', 'XMR', 2),
  Coin('zcash', 'ZEC', 2),
  Coin('dai', 'DAI', 4),
  Coin('uniswap', 'UNI', 3),
  Coin('aave', 'AAVE', 2),
  Coin('near', 'NEAR', 4),
  Coin('aptos', 'APT', 4),
  Coin('internet-computer', 'ICP', 3),
  Coin('bittensor', 'TAO', 2),
  Coin('ethereum-classic', 'ETC', 3),
  Coin('cosmos', 'ATOM', 3),
  Coin('render-token', 'RENDER', 4),
  Coin('filecoin', 'FIL', 4),
  Coin('arbitrum', 'ARB', 5),
  Coin('optimism', 'OP', 5),
  Coin('polygon-ecosystem-token', 'POL', 5),
  Coin('algorand', 'ALGO', 5),
  Coin('vechain', 'VET', 6),
  Coin('fetch-ai', 'FET', 5),
  Coin('injective-protocol', 'INJ', 3),
  Coin('sei-network', 'SEI', 5),
  Coin('pepe', 'PEPE', 8),
  Coin('shiba-inu', 'SHIB', 8),
  Coin('bonk', 'BONK', 8),
  Coin('floki', 'FLOKI', 8),
  Coin('jupiter-exchange-solana', 'JUP', 5),
  Coin('ondo-finance', 'ONDO', 4),
  Coin('pendle', 'PENDLE', 4),
  Coin('pancakeswap-token', 'CAKE', 4),
  Coin('lido-dao', 'LDO', 4),
  Coin('crypto-com-chain', 'CRO', 5),
  Coin('okb', 'OKB', 2),
  Coin('pax-gold', 'PAXG', 2),
  Coin('tether-gold', 'XAUT', 2),
];

/// Selección inicial; una lista vacía guardada se respeta.
const kDefaultCoins = <String>['bitcoin', 'ethereum', 'ripple', 'binancecoin'];

Coin? coinById(String id) {
  for (final c in kCoins) {
    if (c.id == id) return c;
  }
  return null;
}
