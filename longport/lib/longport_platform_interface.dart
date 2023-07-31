import 'dart:convert';

import 'package:longport/entity.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'longport_method_channel.dart';

abstract class LongportPlatform extends PlatformInterface {
  /// Constructs a LongportPlatform.
  LongportPlatform() : super(token: _token);

  static final Object _token = Object();

  static LongportPlatform _instance = MethodChannelLongport();

  /// The default instance of [LongportPlatform] to use.
  ///
  /// Defaults to [MethodChannelLongport].
  static LongportPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [LongportPlatform] when
  /// they register themselves.
  static set instance(LongportPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String> init(
      String appKey, String appSecret, String accessToken, Future<void> Function(String, PushQuote)? onQuote);

  Future<void> subscribe(String symbol);

  Future<void> subscribes(List<String> symbols);

  Future<SecurityQuote> getQuote(String symbol);

  Future<List<SecurityQuote>> getQuotes(List<String> symbols);

  Future<List<WatchListGroup>> getWatchList();

  Future<StockPositionsResponse> getStockPositions();
}
