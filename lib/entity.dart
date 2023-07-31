import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'entity.g.dart';

abstract class ToJsonString {
  Map<String, dynamic> toJson();

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

@JsonSerializable()
class FloatConfig extends ToJsonString {
  bool enable;
  double opacity;
  List<int> showColumns;
  int frequency;
  double windowHeight;
  double windowWidth;
  double screenHeight;
  double screenWidth;
  double fontSize;
  String fontColorType;

  FloatConfig(
      {required this.enable,
      required this.opacity,
      required this.showColumns,
      required this.frequency,
      required this.windowHeight,
      required this.windowWidth,
      required this.screenHeight,
      required this.screenWidth,
      this.fontSize = 20,
      this.fontColorType = ""});

  factory FloatConfig.fromJson(Map<String, dynamic> json) => _$FloatConfigFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$FloatConfigToJson(this);
}

@JsonSerializable()
class StockRtInfo extends ToJsonString {
  double? currentPrice;
  double? currentDiff;
  double? outPrice;
  double? outDiff;
  String name;
  @JsonKey(includeFromJson: false)
  double? basePrice;
  @JsonKey(includeFromJson: false)
  double? openPrice;
  @JsonKey(includeFromJson: false)
  double? highestPrice;
  @JsonKey(includeFromJson: false)
  double? lowestPrice;

  StockRtInfo(
      {required this.name,
      this.currentPrice,
      this.currentDiff,
      this.basePrice,
      this.openPrice,
      this.outPrice,
      this.outDiff,
      this.highestPrice,
      this.lowestPrice});

  factory StockRtInfo.fromJson(Map<String, dynamic> json) => _$StockRtInfoFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$StockRtInfoToJson(this);
}

@JsonSerializable()
class StockInfo extends ToJsonString {
  String code;
  String type;
  String name;
  bool showInFloat;
  StockRtInfo? price;
  double? lastPrice;

  StockInfo({required this.code, required this.type, required this.name, this.price, this.showInFloat = true});

  String get key {
    return '$code.$type';
  }

  factory StockInfo.fromJson(Map<String, dynamic> json) => _$StockInfoFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$StockInfoToJson(this);
}

@JsonSerializable()
class LongPortConfig extends ToJsonString {
  String appKey;
  String appSecret;
  String accessToken;

  LongPortConfig({required this.appKey, required this.appSecret, required this.accessToken});

  factory LongPortConfig.fromJson(Map<String, dynamic> json) => _$LongPortConfigFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$LongPortConfigToJson(this);
}

@JsonSerializable()
class AppConfig extends ToJsonString {
  FloatConfig floatConfig;
  List<StockInfo> stockList;
  LongPortConfig? longPortConfig;

  AppConfig({required this.floatConfig, required this.stockList, this.longPortConfig});

  factory AppConfig.fromJson(Map<String, dynamic> json) => _$AppConfigFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$AppConfigToJson(this);
}
