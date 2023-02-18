// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FloatConfig _$FloatConfigFromJson(Map<String, dynamic> json) => FloatConfig(
      enable: json['enable'] as bool,
      opacity: (json['opacity'] as num).toDouble(),
      showColumns:
          (json['showColumns'] as List<dynamic>).map((e) => e as int).toList(),
      frequency: json['frequency'] as int,
      windowHeight: (json['windowHeight'] as num).toDouble(),
      windowWidth: (json['windowWidth'] as num).toDouble(),
      screenHeight: (json['screenHeight'] as num).toDouble(),
      screenWidth: (json['screenWidth'] as num).toDouble(),
    );

Map<String, dynamic> _$FloatConfigToJson(FloatConfig instance) =>
    <String, dynamic>{
      'enable': instance.enable,
      'opacity': instance.opacity,
      'showColumns': instance.showColumns,
      'frequency': instance.frequency,
      'windowHeight': instance.windowHeight,
      'windowWidth': instance.windowWidth,
      'screenHeight': instance.screenHeight,
      'screenWidth': instance.screenWidth,
    };

StockRtInfo _$StockRtInfoFromJson(Map<String, dynamic> json) => StockRtInfo(
      name: json['name'] as String,
      currentPrice: (json['currentPrice'] as num?)?.toDouble(),
      currentDiff: (json['currentDiff'] as num?)?.toDouble(),
      basePrice: (json['basePrice'] as num?)?.toDouble(),
      openPrice: (json['openPrice'] as num?)?.toDouble(),
      outPrice: (json['outPrice'] as num?)?.toDouble(),
      outDiff: (json['outDiff'] as num?)?.toDouble(),
      highestPrice: (json['highestPrice'] as num?)?.toDouble(),
      lowestPrice: (json['lowestPrice'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$StockRtInfoToJson(StockRtInfo instance) =>
    <String, dynamic>{
      'name': instance.name,
      'currentPrice': instance.currentPrice,
      'currentDiff': instance.currentDiff,
      'basePrice': instance.basePrice,
      'openPrice': instance.openPrice,
      'outPrice': instance.outPrice,
      'outDiff': instance.outDiff,
      'highestPrice': instance.highestPrice,
      'lowestPrice': instance.lowestPrice,
    };

StockInfo _$StockInfoFromJson(Map<String, dynamic> json) => StockInfo(
      code: json['code'] as String,
      type: json['type'] as String,
      name: json['name'] as String,
      price: json['price'] == null
          ? null
          : StockRtInfo.fromJson(json['price'] as Map<String, dynamic>),
      showInFloat: json['showInFloat'] as bool? ?? true,
    );

Map<String, dynamic> _$StockInfoToJson(StockInfo instance) => <String, dynamic>{
      'code': instance.code,
      'type': instance.type,
      'name': instance.name,
      'showInFloat': instance.showInFloat,
      'price': instance.price,
    };

AppConfig _$AppConfigFromJson(Map<String, dynamic> json) => AppConfig(
      FloatConfig.fromJson(json['floatConfig'] as Map<String, dynamic>),
      (json['stockList'] as List<dynamic>)
          .map((e) => StockInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AppConfigToJson(AppConfig instance) => <String, dynamic>{
      'floatConfig': instance.floatConfig,
      'stockList': instance.stockList,
    };
