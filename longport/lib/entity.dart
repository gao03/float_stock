// 根据 Json 定义生成的代码
// https://javiercbk.github.io/json_to_dart/

class WatchListGroup {
  int? id;
  String? name;
  List<Securities>? securities;

  WatchListGroup({this.id, this.name, this.securities});

  WatchListGroup.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    if (json['securities'] != null) {
      securities = <Securities>[];
      json['securities'].forEach((v) {
        securities!.add(Securities.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    if (securities != null) {
      data['securities'] = securities!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Securities {
  String? market;
  String? name;
  String? symbol;

  Securities({this.market, this.name, this.symbol});

  Securities.fromJson(Map<String, dynamic> json) {
    market = json['market'];
    name = json['name'];
    symbol = json['symbol'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['market'] = market;
    data['name'] = name;
    data['symbol'] = symbol;
    return data;
  }
}

class StockPositionsResponse {
  List<Channels>? channels;

  StockPositionsResponse({this.channels});

  StockPositionsResponse.fromJson(Map<String, dynamic> json) {
    if (json['channels'] != null) {
      channels = <Channels>[];
      json['channels'].forEach((v) {
        channels!.add(Channels.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (channels != null) {
      data['channels'] = channels!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Channels {
  String? accountChannel;
  List<Positions>? positions;

  Channels({this.accountChannel, this.positions});

  Channels.fromJson(Map<String, dynamic> json) {
    accountChannel = json['accountChannel'];
    if (json['positions'] != null) {
      positions = <Positions>[];
      json['positions'].forEach((v) {
        positions!.add(Positions.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['accountChannel'] = accountChannel;
    if (positions != null) {
      data['positions'] = positions!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Positions {
  int? availableQuantity;
  double? costPrice;
  String? currency;
  String? market;
  int? quantity;
  String? symbol;
  String? symbolName;

  Positions(
      {this.availableQuantity,
      this.costPrice,
      this.currency,
      this.market,
      this.quantity,
      this.symbol,
      this.symbolName});

  Positions.fromJson(Map<String, dynamic> json) {
    availableQuantity = json['availableQuantity'];
    costPrice = json['costPrice'];
    currency = json['currency'];
    market = json['market'];
    quantity = json['quantity'];
    symbol = json['symbol'];
    symbolName = json['symbolName'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['availableQuantity'] = availableQuantity;
    data['costPrice'] = costPrice;
    data['currency'] = currency;
    data['market'] = market;
    data['quantity'] = quantity;
    data['symbol'] = symbol;
    data['symbolName'] = symbolName;
    return data;
  }
}

class SecurityQuote {
  double? high;
  double? lastDone;
  double? low;
  double? open;
  PostMarketQuote? postMarketQuote;
  PostMarketQuote? preMarketQuote;
  double? prevClose;
  String? symbol;
  String? tradeStatus;
  int? volume;

  SecurityQuote(
      {this.high,
      this.lastDone,
      this.low,
      this.open,
      this.postMarketQuote,
      this.preMarketQuote,
      this.prevClose,
      this.symbol,
      this.tradeStatus,
      this.volume});

  SecurityQuote.fromJson(Map<String, dynamic> json) {
    high = json['high'];
    lastDone = json['lastDone'];
    low = json['low'];
    open = json['open'];
    postMarketQuote = json['postMarketQuote'] != null ? PostMarketQuote.fromJson(json['postMarketQuote']) : null;
    preMarketQuote = json['preMarketQuote'] != null ? PostMarketQuote.fromJson(json['preMarketQuote']) : null;
    prevClose = json['prevClose'];
    symbol = json['symbol'];
    tradeStatus = json['tradeStatus'];
    volume = json['volume'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['high'] = high;
    data['lastDone'] = lastDone;
    data['low'] = low;
    data['open'] = open;
    if (postMarketQuote != null) {
      data['postMarketQuote'] = postMarketQuote!.toJson();
    }
    if (preMarketQuote != null) {
      data['preMarketQuote'] = preMarketQuote!.toJson();
    }
    data['prevClose'] = prevClose;
    data['symbol'] = symbol;
    data['tradeStatus'] = tradeStatus;
    data['volume'] = volume;
    return data;
  }
}

class PostMarketQuote {
  double? high;
  double? lastDone;
  double? low;
  double? prevClose;
  double? turnover;
  int? volume;

  PostMarketQuote({this.high, this.lastDone, this.low, this.prevClose, this.turnover, this.volume});

  PostMarketQuote.fromJson(Map<String, dynamic> json) {
    high = json['high'];
    lastDone = json['lastDone'];
    low = json['low'];
    prevClose = json['prevClose'];
    turnover = json['turnover'];
    volume = json['volume'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['high'] = high;
    data['lastDone'] = lastDone;
    data['low'] = low;
    data['prevClose'] = prevClose;
    data['turnover'] = turnover;
    data['volume'] = volume;
    return data;
  }
}

class PushQuoteEvent {
  String? symbol;
  PushQuote? event;

  PushQuoteEvent({this.symbol, this.event});

  PushQuoteEvent.fromJson(Map<String, dynamic> json) {
    symbol = json['symbol'];
    event = json['event'] != null ? PushQuote.fromJson(json['event']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['symbol'] = symbol;
    if (event != null) {
      data['event'] = event!.toJson();
    }
    return data;
  }
}

class PushQuote {
  double? high;
  double? lastDone;
  double? low;
  double? open;
  String? tradeSession;
  String? tradeStatus;

  PushQuote({this.high, this.lastDone, this.low, this.open, this.tradeSession, this.tradeStatus});

  PushQuote.fromJson(Map<String, dynamic> json) {
    high = json['high'];
    lastDone = json['lastDone'];
    low = json['low'];
    open = json['open'];
    tradeSession = json['tradeSession'];
    tradeStatus = json['tradeStatus'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['high'] = high;
    data['lastDone'] = lastDone;
    data['low'] = low;
    data['open'] = open;
    data['tradeSession'] = tradeSession;
    data['tradeStatus'] = tradeStatus;
    return data;
  }
}

class SecurityStaticInfo {
  String? board;
  double? bps;
  int? circulatingShares;
  String? currency;
  String? exchange;
  int? hkShares;
  int? lotSize;
  String? nameCn;
  String? nameEn;
  String? nameHk;
  List<String>? stockDerivatives;
  String? symbol;
  int? totalShares;

  SecurityStaticInfo(
      {this.board,
      this.bps,
      this.circulatingShares,
      this.currency,
      this.exchange,
      this.hkShares,
      this.lotSize,
      this.nameCn,
      this.nameEn,
      this.nameHk,
      this.stockDerivatives,
      this.symbol,
      this.totalShares});

  SecurityStaticInfo.fromJson(Map<String, dynamic> json) {
    board = json['board'];
    bps = json['bps'];
    circulatingShares = json['circulatingShares'];
    currency = json['currency'];
    exchange = json['exchange'];
    hkShares = json['hkShares'];
    lotSize = json['lotSize'];
    nameCn = json['nameCn'];
    nameEn = json['nameEn'];
    nameHk = json['nameHk'];
    stockDerivatives = json['stockDerivatives'].cast<String>();
    symbol = json['symbol'];
    totalShares = json['totalShares'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['board'] = board;
    data['bps'] = bps;
    data['circulatingShares'] = circulatingShares;
    data['currency'] = currency;
    data['exchange'] = exchange;
    data['hkShares'] = hkShares;
    data['lotSize'] = lotSize;
    data['nameCn'] = nameCn;
    data['nameEn'] = nameEn;
    data['nameHk'] = nameHk;
    data['stockDerivatives'] = stockDerivatives;
    data['symbol'] = symbol;
    data['totalShares'] = totalShares;
    return data;
  }
}
