// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FloatConfig _$FloatConfigFromJson(Map<String, dynamic> json) => FloatConfig(
      enable: json['enable'] as bool,
      opacity: (json['opacity'] as num).toDouble(),
      frequency: json['frequency'] as int,
      windowHeight: (json['windowHeight'] as num).toDouble(),
      windowWidth: (json['windowWidth'] as num).toDouble(),
      screenHeight: (json['screenHeight'] as num).toDouble(),
      screenWidth: (json['screenWidth'] as num).toDouble(),
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 20,
    );

Map<String, dynamic> _$FloatConfigToJson(FloatConfig instance) =>
    <String, dynamic>{
      'enable': instance.enable,
      'opacity': instance.opacity,
      'frequency': instance.frequency,
      'windowHeight': instance.windowHeight,
      'windowWidth': instance.windowWidth,
      'screenHeight': instance.screenHeight,
      'screenWidth': instance.screenWidth,
      'fontSize': instance.fontSize,
    };

StockRtInfo _$StockRtInfoFromJson(Map<String, dynamic> json) => StockRtInfo(
      name: json['name'] as String,
      currentPrice: (json['currentPrice'] as num?)?.toDouble(),
      currentDiff: (json['currentDiff'] as num?)?.toDouble(),
      outPrice: (json['outPrice'] as num?)?.toDouble(),
      outDiff: (json['outDiff'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$StockRtInfoToJson(StockRtInfo instance) =>
    <String, dynamic>{
      'currentPrice': instance.currentPrice,
      'currentDiff': instance.currentDiff,
      'outPrice': instance.outPrice,
      'outDiff': instance.outDiff,
      'name': instance.name,
    };

StockInfo _$StockInfoFromJson(Map<String, dynamic> json) => StockInfo(
      code: json['code'] as String,
      type: json['type'] as String,
      name: json['name'] as String,
      showInFloat: json['showInFloat'] as bool? ?? true,
    );

Map<String, dynamic> _$StockInfoToJson(StockInfo instance) => <String, dynamic>{
      'code': instance.code,
      'type': instance.type,
      'name': instance.name,
      'showInFloat': instance.showInFloat,
    };

LongPortConfig _$LongPortConfigFromJson(Map<String, dynamic> json) =>
    LongPortConfig(
      json['appKey'] as String,
      json['appSecret'] as String,
      json['accessToken'] as String,
    );

Map<String, dynamic> _$LongPortConfigToJson(LongPortConfig instance) =>
    <String, dynamic>{
      'appKey': instance.appKey,
      'appSecret': instance.appSecret,
      'accessToken': instance.accessToken,
    };

AppConfig _$AppConfigFromJson(Map<String, dynamic> json) => AppConfig(
      floatConfig:
          FloatConfig.fromJson(json['floatConfig'] as Map<String, dynamic>),
      stockList: (json['stockList'] as List<dynamic>)
          .map((e) => StockInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      longPortConfig: json['longPortConfig'] == null
          ? null
          : LongPortConfig.fromJson(
              json['longPortConfig'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AppConfigToJson(AppConfig instance) => <String, dynamic>{
      'floatConfig': instance.floatConfig,
      'stockList': instance.stockList,
      'longPortConfig': instance.longPortConfig,
    };
