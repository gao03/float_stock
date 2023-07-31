import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:longport/entity.dart';

import 'longport_platform_interface.dart';

class MethodChannelLongport extends LongportPlatform {
  @visibleForTesting
  final channel = const MethodChannel("com.gaozhiqiang03.float_stock/longport");

  Future<void> Function(String, PushQuote)? onQuote;

  @override
  Future<String> init(
      String appKey, String appSecret, String accessToken, Future<void> Function(String, PushQuote)? onQuote) async {
    Map<String, String> arg = {
      "appKey": appKey,
      "appSecret": appSecret,
      "accessToken": accessToken,
    };
    this.onQuote = onQuote;
    channel.setMethodCallHandler(onMethodCall);
    return await invoke("init", arg);
  }

  Future<dynamic> onMethodCall(MethodCall call) async {
    if (call.method == "onQuote" && onQuote != null) {
      var event = PushQuoteEvent.fromJson(jsonDecode(call.arguments));
      await onQuote!.call(event.symbol!, event.event!);
    }
  }

  @override
  Future<String> subscribe(String symbol) async {
    return await invoke("subscribe", symbol);
  }

  @override
  Future<void> subscribes(List<String> symbols) async {
    await invoke("subscribes", symbols);
  }

  @override
  Future<SecurityQuote> getQuote(String symbol) async {
    var resp = await invoke("getQuote", symbol);
    return SecurityQuote.fromJson(jsonDecode(resp));
  }

  @override
  Future<List<SecurityQuote>> getQuotes(List<String> symbols) async {
    var resp = await invoke("getQuotes", symbols);
    return List<SecurityQuote>.from(json.decode(resp).map((model) => SecurityQuote.fromJson(model)));
  }

  @override
  Future<List<WatchListGroup>> getWatchList() async {
    var resp = await invoke("getWatchList");
    return List<WatchListGroup>.from(json.decode(resp).map((model) => WatchListGroup.fromJson(model)));
  }

  @override
  Future<StockPositionsResponse> getStockPositions() async {
    var resp = await invoke("getStockPositions");
    return StockPositionsResponse.fromJson(jsonDecode(resp));
  }

  Future<String> invoke(String method, [dynamic arguments]) async {
    var result = await channel.invokeMethod(method, jsonEncode(arguments));
    debugPrint("invoke: $method , $result");
    return result;
  }
}
