import 'dart:async';
import 'dart:core';
import 'dart:math';

import 'package:float_stock/api.dart';
import 'package:float_stock/utils.dart';
import 'package:memory_cache/memory_cache.dart';

import 'entity.dart';

Future<List<StockInfo>> getStockLatestInfo(List<StockInfo> list) async {
  var needQueryStock = list.where(checkNeedQueryByApi).toList();

  var newList = await queryStockByStockList(needQueryStock);
  var newMap = {for (var s in newList) s.key: s};
  newMap.forEach((key, info) {
    MemoryCache.instance.create(key, info.price);
  });
  for (var s in list) {
    s.price = MemoryCache.instance.read<StockRtInfo>(s.key);
  }
  return list;
}

Map<String, StockRtInfo?> readStockFromCache(List<StockInfo> list) {
  return {for (var s in list) s.key: MemoryCache.instance.read<StockRtInfo>(s.key)};
}

bool checkNeedQueryByApi(StockInfo stock) {
  // 如果缓存里面没有，那一定要查一次
  var inCache = MemoryCache.instance.read<StockRtInfo>(stock.key);
  if (inCache == null) {
    return true;
  }
  return checkMarketStatus(stock.type) != MarketStatus.close;
}
