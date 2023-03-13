import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:bruno/bruno.dart';
import 'package:float_stock/entity.dart';
import 'package:float_stock/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_floatwing/flutter_floatwing.dart';

import 'data.dart';

class FloatWindowView extends StatefulWidget {
  final AppConfig config;

  const FloatWindowView({Key? key, required this.config}) : super(key: key);

  @override
  State<FloatWindowView> createState() => _FloatWindowViewState();
}

class _FloatWindowViewState extends State<FloatWindowView> {
  late AppConfig config;
  Timer? timer;
  List<StockInfo>? stockList;
  Map<String, StockInfo> oldStockPriceMap = HashMap();

  Window? w;
  final int stockHeightBase = 400;

  @override
  void initState() {
    super.initState();
    config = widget.config;
    updateStockList(config.stockList);

    SchedulerBinding.instance.addPostFrameCallback((_) {
      w = Window.of(context);
      w?.onData((source, name, data) async {
        if (name == "config") {
          refresh(AppConfig.fromJson(jsonDecode(data)));
        } else if (name == "stockList") {
          var newData = (json.decode(data) as List).map((data) => StockInfo.fromJson(data)).toList();
          updateStockList(newData);
        }
      });
    });
  }

  void refresh(AppConfig newConfig) async {
    setState(() {
      config = newConfig;
      updateStockList(config.stockList);
    });
    await w?.show(visible: newConfig.floatConfig.enable);
    // var screenHeight = w?.system?.screenHeight ?? newConfig.floatConfig.screenHeight;
    var screenWidth = w?.system?.screenWidth ?? newConfig.floatConfig.screenWidth;
    await w?.update(WindowConfig(
      height: (newConfig.floatConfig.windowHeight * stockHeightBase * stockList!.length).toInt(),
      width: (newConfig.floatConfig.windowWidth * screenWidth).toInt(),
    ));
  }

  void updateStockList(var newStockList) {
    // 如果新传过来的数据没有价格信息，就用老得价格
    var stockMap = {for (var e in config.stockList) e.key: e};
    for (var stock in newStockList) {
      stock.price ??= stockMap[stock.key]?.price;
    }
    if (stockList != null) {
      for (var stock in stockList!) {
        oldStockPriceMap[stock.key] = stock;
      }
    }
    setState(() {
      stockList = newStockList.where((i) => i.showInFloat == true).toList();
    });
  }

  void refreshStockInfo() async {
    var newStockList = await getStockLatestInfo(stockList!);
    updateStockList(newStockList);
  }

  String generateStockText(StockInfo stock) {
    return config.floatConfig.showColumns.map((e) => getStockField(stock, e)).join(" ");
  }

  String getStockField(StockInfo stock, int index) {
    //["名称", "代码", "价格", "涨跌幅"];
    return [stock.name, stock.code, formatNum(getShowPrice(stock)), '${formatNum(getShowDiff(stock))}%'][index];
  }

  Color getStockColor(StockInfo stock) {
    if (config.floatConfig.fontColorType == "黑色" || stock.price == null) {
      return Colors.black;
    }
    if (config.floatConfig.fontColorType == "当日涨跌") {
      var showDiff = getShowDiff(stock) ?? 0;
      return showDiff == 0
          ? Colors.black
          : showDiff > 0
          ? Colors.red
          : Colors.green;
    }
    if (config.floatConfig.fontColorType == "同比涨跌") {
      var old = oldStockPriceMap[stock.key];
      if (old == null) {
        return Colors.black;
      }
      double curPrice = getShowPrice(stock) ?? 0;
      double oldPrice = getShowPrice(old) ?? 0;
      return curPrice == oldPrice
          ? Colors.black
          : curPrice > oldPrice
          ? Colors.red
          : Colors.green;
    }

    return Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: config.floatConfig.windowWidth * config.floatConfig.screenWidth,
        height: config.floatConfig.windowHeight * stockHeightBase * stockList!.length,
        child: GestureDetector(
            onDoubleTap: () {
              w?.launchMainActivity();
            },
            onLongPress: () {
              w?.close();
            },
            child: Card(
                elevation: 0,
                color: Colors.white.withOpacity(config.floatConfig.opacity),
                child: Column(children: [
                  const Padding(
                    padding: EdgeInsets.all(3),
                  ),
                  for (var stock in stockList!)
                    Column(children: [
                      Text(generateStockText(stock),
                          style: TextStyle(
                            color: getStockColor(stock),
                            fontSize: config.floatConfig.fontSize,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.left),
                      Offstage(offstage: (stock.key == stockList!.last.key), child: const Divider(indent: 15)),
                    ])
                ]))));
  }
}
