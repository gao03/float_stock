import 'dart:collection';

import 'package:float_stock/api.dart';

import 'entity.dart';

Map<String, StockInfo> stockCache = HashMap();

Future<List<StockInfo>> getStockLatestInfo(List<StockInfo> list) async {
  // todo 判断是否开盘
  var newList = await queryStockByStockList(list);
  var newMap = {for (var s in newList) s.key: s};
  for (var s in list) {
    s.price = newMap[s.key]?.price;
  }
  return list;
}
