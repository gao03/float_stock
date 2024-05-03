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
  var typeMap = {'sz': 'SZ', 'sh': 'SH', 'rt_hk': 'HK', 'gb_': 'US'};

  for (var entry in typeMap.entries) {
    if (!prefix.startsWith(entry.key)) {
      continue;
    }
    var name = data[0];
    if (entry.key == 'rt_hk') {
      name = data[1];
    }
    return StockInfo(
      code: prefix.substring(entry.key.length).toUpperCase(),
      type: typeMap[entry.key] ?? entry.key.toUpperCase(),
      name: name,
      showInFloat: true,
    );
  }
  return null;
}
