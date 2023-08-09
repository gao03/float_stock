import 'package:longport/entity.dart';

import 'longport_platform_interface.dart';

class Longport {
  var isInit = false;

  Future<void> init(
      String appKey, String appSecret, String accessToken, Future<void> Function(String, PushQuote)? onQuote) async {
    await LongportPlatform.instance.init(appKey, appSecret, accessToken, onQuote);
    isInit = true;
  }

  Future<void> subscribes(List<String> symbols) async {
    return await LongportPlatform.instance.subscribes(symbols);
  }

  Future<List<SecurityQuote>> getQuotes(List<String> symbols) async {
    return await LongportPlatform.instance.getQuotes(symbols);
  }

  Future<List<SecurityStaticInfo>> getStaticInfo(List<String> symbols) async {
    return await LongportPlatform.instance.getStaticInfo(symbols);
  }

  Future<List<WatchListGroup>> getWatchList() async {
    return await LongportPlatform.instance.getWatchList();
  }

  Future<StockPositionsResponse> getStockPositions() async {
    return await LongportPlatform.instance.getStockPositions();
  }
}
