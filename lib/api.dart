import 'dart:collection';

import 'package:dio/dio.dart';
import 'package:gbk_codec/gbk_codec.dart';

import 'entity.dart';

typedef BiFunction<T, U, R> = R Function(T first, U second);

String gbkDecoder(List<int> responseBytes, RequestOptions options, ResponseBody responseBody) {
  return gbk_bytes.decode(responseBytes);
}

Future<List<StockInfo>> queryStockByCode(String code) async {
  code = code.trim();
  if (code.length < 2) {
    return [];
  }
  var types = ["gb_", "sh", "sz", "rt_hk"];
  return queryStockByCode0(types.map((e) => e + code).toList());
}

Future<List<StockInfo>> queryStockByStockList(List<StockInfo> lst) async {
  return queryStockByCode0(lst.map((e) => e.key).toList());
}

Future<List<StockInfo>> queryStockByCode0(List<String> codeLst) async {
  try {
    if (codeLst.isEmpty) {
      return [];
    }
    var response = await Dio().get('https://hq.sinajs.cn/rn?list=${codeLst.join(',')}',
        options: Options(headers: {
          "Referer": "https://sina.com.cn",
        }, responseDecoder: gbkDecoder));
    var reg = RegExp("hq_str_(.*?)=\"(.*?)\"");
    var lst = reg.allMatches(response.data);
    return lst.map(convert).where((i) => i != null).toList().cast<StockInfo>();
  } catch (e) {
    return [];
  }
}

StockInfo? convert(RegExpMatch m) {
  var prefix = m.group(1);
  var dataStr = m.group(2)?.trim();
  if (prefix == null || dataStr == null || dataStr.isEmpty) {
    return null;
  }
  var data = dataStr.split(",");
  var convertFuncMap = {'sz': convertA, 'sh': convertA, 'rt_hk': convertHk, 'gb_': convertGb};

  for (var entry in convertFuncMap.entries) {
    if (!prefix.startsWith(entry.key)) {
      continue;
    }
    var price = entry.value(data);
    if (price == null) {
      return null;
    }
    return StockInfo(
      code: prefix.substring(entry.key.length),
      type: entry.key,
      name: price.name,
      price: price,
      showInFloat: true,
    );
  }
  return null;
}

StockRtInfo? convertGb(List<String> data) {
  try {
    return StockRtInfo(
        name: data[0],
        currentPrice: double.parse(data[1]),
        currentDiff: double.parse(data[2]),
        openPrice: double.parse(data[5]),
        highestPrice: double.parse(data[6]),
        lowestPrice: double.parse(data[7]),
        basePrice: double.parse(data[26]),
        outPrice: double.parse(data[21]),
        outDiff: double.parse(data[22]));
  } catch (e) {
    return null;
  }
}

StockRtInfo? convertHk(List<String> data) {
  try {
    return StockRtInfo(
        name: data[1],
        currentPrice: double.parse(data[6]),
        currentDiff: double.parse(data[8]),
        highestPrice: double.parse(data[4]),
        lowestPrice: double.parse(data[5]),
        openPrice: double.parse(data[2]),
        basePrice: double.parse(data[3]));
  } catch (e) {
    return null;
  }
}

StockRtInfo? convertA(List<String> data) {
  try {
    var basePrice = double.parse(data[2]);
    var currentPrice = double.parse(data[3]);
    var currentDiff =
        basePrice == 0 ? 0.0 : num.parse(((currentPrice - basePrice) / basePrice * 100).toStringAsFixed(2)).toDouble();
    return StockRtInfo(
      name: data[0],
      currentPrice: currentPrice,
      currentDiff: currentDiff,
      basePrice: basePrice,
      openPrice: double.parse(data[1]),
      highestPrice: double.parse(data[4]),
      lowestPrice: double.parse(data[5]),
    );
  } catch (e) {
    return null;
  }
}
