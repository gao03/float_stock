import 'package:longport/entity.dart';

import 'longport_platform_interface.dart';

class Longport {
  Future<String> init(
      String appKey, String appSecret, String accessToken, Future<void> Function(String, PushQuote)? onQuote) async {
    return LongportPlatform.instance.init(appKey, appSecret, accessToken, onQuote);
  }

  Future<void> subscribe(String symbol) async {
    return LongportPlatform.instance.subscribe(symbol);
  }

  Future<void> subscribes(List<String> symbols) async {
    return await LongportPlatform.instance.subscribes(symbols);
  }

  Future<SecurityQuote> getQuote(String symbol) async {
    return await LongportPlatform.instance.getQuote(symbol);
  }

  Future<List<SecurityQuote>> getQuotes(List<String> symbols) async {
    return await LongportPlatform.instance.getQuotes(symbols);
  }

  Future<List<WatchListGroup>> getWatchList() async {
    return await LongportPlatform.instance.getWatchList();
  }

  Future<StockPositionsResponse> getStockPositions() async {
    return await LongportPlatform.instance.getStockPositions();
  }
}
