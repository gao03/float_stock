import 'dart:collection';

import 'package:float_stock/api.dart';
import 'package:float_stock/utils.dart';

import 'entity.dart';

Map<String, StockInfo> stockCache = HashMap();

Future<List<StockInfo>> getStockLatestInfo(List<StockInfo> list) async {
  var needQueryStock = list.where(checkNeedQueryByApi).toList();

  var newList = await queryStockByStockList(needQueryStock);
  var newMap = {for (var s in newList) s.key: s};
  newMap.forEach((key, info) {
    stockCache[key] = info;
  });

  for (var s in list) {
    s.price = stockCache[s.key]?.price;
  }
  return list;
}

bool checkNeedQueryByApi(StockInfo stock) {
  // 如果缓存里面没有，那一定要查一次
  if (!stockCache.containsKey(stock.key)) {
    return true;
  }
  return checkMarketStatus(stock.type) != MarketStatus.close;
}
