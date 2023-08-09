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
    print(call.method);
    print(call.arguments);
    if (call.method == "onQuote" && onQuote != null) {
      var event = PushQuoteEvent.fromJson(jsonDecode(call.arguments));
      await onQuote!.call(event.symbol!, event.event!);
    }
  }

  @override
  Future<void> subscribes(List<String> symbols) async {
    await invoke("subscribes", symbols);
  }

  @override
  Future<List<SecurityQuote>> getQuotes(List<String> symbols) async {
    var resp = await invoke("getQuotes", symbols);
    return List<SecurityQuote>.from(json.decode(resp).map((model) => SecurityQuote.fromJson(model)));
  }

  @override
  Future<List<SecurityStaticInfo>> getStaticInfo(List<String> symbols) async {
    var resp = await invoke("getStaticInfo", symbols);
    return List<SecurityStaticInfo>.from(json.decode(resp).map((model) => SecurityStaticInfo.fromJson(model)));
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
    try {
      print("invoke longport $method");
      var result = await channel.invokeMethod(method, jsonEncode(arguments));
      print("invoke: $method , $result");
      return result;
    } catch (e) {
      print("longport method error $method");
      print(e);
      return "";
    }
  }
}
