import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:bruno/bruno.dart';
import 'package:float_stock/entity.dart';
import 'package:float_stock/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_floatwing/flutter_floatwing.dart';
import 'package:longport/entity.dart';
import 'package:longport/longport.dart';

class FloatWindowView extends StatefulWidget {
  final AppConfig config;

  const FloatWindowView({Key? key, required this.config}) : super(key: key);

  @override
  State<FloatWindowView> createState() => _FloatWindowViewState();
}

class _FloatWindowViewState extends State<FloatWindowView> {
  late AppConfig config;
  List<StockInfo>? stockList;

  Window? w;
  final int stockHeightBase = 400;
  final Longport ls = Longport();
  bool lsInit = false;

  @override
  void initState() {
    super.initState();
    config = widget.config;
    checkAndInitLs();
    updateStockList(config.stockList);

    SchedulerBinding.instance.addPostFrameCallback((_) {
      w = Window.of(context);
      w?.onData((source, name, data) async {
        if (name == "config") {
          refresh(AppConfig.fromJson(jsonDecode(data)));
        }
      });
    });
  }

  void checkAndInitLs() async {
    var c = config.longPortConfig;
    if (c != null && !lsInit) {
      await ls.init(c.appKey, c.appSecret, c.accessToken, onQuote);
      lsInit = true;
    }
  }

  Future<void> onQuote(String symbol, PushQuote quote) async {
    for (var stock in stockList!) {
      if (symbol.startsWith(stock.code.toUpperCase()) && quote.lastDone != null) {
        stock.color = getStockColor(quote.lastDone, stock.lastPrice);
        stock.lastPrice = quote.lastDone!;
        break;
      }
    }
    setState(() {
      stockList = stockList?.where(checkStockCanShow).toList();
    });
  }

  bool checkStockCanShow(StockInfo stock) {
    if (!stock.showInFloat) {
      return false;
    }
    return checkMarketStatus(stock.type) != MarketStatus.close;
  }

  void refresh(AppConfig newConfig) async {
    setState(() {
      config = newConfig;
      updateStockList(config.stockList);
    });
    checkAndInitLs();
    await w?.show(visible: newConfig.floatConfig.enable);
    // var screenHeight = w?.system?.screenHeight ?? newConfig.floatConfig.screenHeight;
    var screenWidth = w?.system?.screenWidth ?? newConfig.floatConfig.screenWidth;
    await w?.update(WindowConfig(
      height: (newConfig.floatConfig.windowHeight * stockHeightBase * stockList!.length).toInt(),
      width: (newConfig.floatConfig.windowWidth * screenWidth).toInt(),
    ));
  }

  void updateStockList(List<StockInfo> newStockList) {
    var filterStockList = newStockList.where((i) => i.showInFloat == true).where(checkStockCanShow).toList();
    ls.subscribes(filterStockList.map((e) => e.symbol).toList().cast<String>());
    setState(() {
      stockList = filterStockList;
    });
  }

  String generateStockText(StockInfo stock) {
    return config.floatConfig.showColumns.map((e) => getStockField(stock, e)).join(" ");
  }

  String getStockField(StockInfo stock, int index) {
    //["名称", "代码", "价格", "涨跌幅"];
    return [stock.name, stock.code, formatNum(stock.lastPrice), '${formatNum(getShowDiff(stock))}%'][index];
  }

  Color getStockColor(double? curPrice, double? oldPrice) {
    if (config.floatConfig.fontColorType == "黑色" || curPrice == null || oldPrice == null) {
      return Colors.black;
    }
    // if (config.floatConfig.fontColorType == "当日涨跌") {
    //   var showDiff = getShowDiff(stock) ?? 0;
    //   return showDiff == 0
    //       ? Colors.black
    //       : showDiff > 0
    //           ? Colors.red
    //           : Colors.green;
    // }
    if (config.floatConfig.fontColorType == "同比涨跌") {
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
              w?.hide();
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
                            color: stock.color,
                            fontSize: config.floatConfig.fontSize,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.left),
                      Offstage(offstage: (stock.symbol == stockList!.last.symbol), child: const Divider(indent: 15)),
                    ])
                ]))));
  }
}
