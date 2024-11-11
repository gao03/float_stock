import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:float_stock/entity.dart';
import 'package:float_stock/utils.dart';
import 'package:flutter_floatwing/flutter_floatwing.dart';
import 'package:longport/entity.dart';
import 'package:longport/longport.dart';

class FloatWindowView extends StatefulWidget {
  final AppConfig config;

  const FloatWindowView({Key? key, required this.config}) : super(key: key);

  @override
  State<FloatWindowView> createState() => FloatWindowViewState();
}

class FloatWindowViewState extends State<FloatWindowView> {
  late AppConfig config;
  List<StockInfo>? stockList;
  Window? window;
  final int stockHeightBase = 400;
  final Longport longPortService = Longport();
  bool isLongPortInitialized = false;

  @override
  void initState() {
    super.initState();
    config = widget.config;
    initializeLongPort();
    updateStockList(config.stockList);

    SchedulerBinding.instance.addPostFrameCallback((_) {
      window = Window.of(context);
      window?.onData((source, name, data) async {
        if (name == "config") {
          refresh(AppConfig.fromJson(jsonDecode(data)));
        }
      });
    });
  }

  void initializeLongPort() async {
    var longPortConfig = config.longPortConfig;
    if (longPortConfig != null && !isLongPortInitialized) {
      longPortService.init(longPortConfig.appKey, longPortConfig.appSecret, longPortConfig.accessToken, onQuoteReceived);
      isLongPortInitialized = true;
    }
  }

  Future<void> onQuoteReceived(String symbol, PushQuote quote) async {
    if (stockList == null) return;

    for (var stock in stockList!) {
      if (symbol.startsWith(convertStockCode(stock).toUpperCase()) && quote.lastDone != null) {
        stock.color = getStockColor(quote.lastDone, stock.lastPrice);
        stock.lastPrice = quote.lastDone!;
        break;
      }
    }
    setState(() {
      stockList = stockList?.where(canStockBeShown).toList();
    });
  }

  bool canStockBeShown(StockInfo stock) {
    return stock.showInFloat && checkMarketStatus(stock.type) != MarketStatus.close;
  }

  void refresh(AppConfig newConfig) async {
    setState(() {
      config = newConfig;
      updateStockList(config.stockList);
    });
    initializeLongPort();
    await window?.show(visible: newConfig.floatConfig.enable);

    var screenWidth = window?.system?.screenWidth ?? newConfig.floatConfig.screenWidth;
    if (screenWidth == 0) {
      screenWidth = newConfig.floatConfig.screenWidth;
    }
    await window?.update(WindowConfig(
      height: (newConfig.floatConfig.windowHeight * stockHeightBase * stockList!.length).toInt(),
      width: (newConfig.floatConfig.windowWidth * screenWidth).toInt(),
    ));
  }

  void updateStockList(List<StockInfo> newStockList) {
    var filteredStockList = newStockList.where(canStockBeShown).toList();
    longPortService.subscribes(filteredStockList.map(convertStockCode).toList());
    setState(() {
      stockList = filteredStockList;
    });
  }

  String convertStockCode(StockInfo stock) {
    var code = stock.symbol;
    if (stock.type == "HK") {
      code = code.replaceFirst(RegExp(r'^0+'), '');
    }
    return code;
  }

  String generateStockText(StockInfo stock) {
    return formatNum(stock.lastPrice);
  }

  Color getStockColor(double? currentPrice, double? previousPrice) {
    if (currentPrice == null || previousPrice == null || currentPrice == previousPrice) {
      return Colors.black;
    }
    return currentPrice > previousPrice ? Colors.red : Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
        visible:  stockList?.isNotEmpty ?? false,
        child: SizedBox(
          width: config.floatConfig.windowWidth * config.floatConfig.screenWidth,
          height: config.floatConfig.windowHeight * stockHeightBase * stockList!.length,
          child: GestureDetector(
            onDoubleTap: window?.launchMainActivity,
            child: Card(
              elevation: 0,
              color: Colors.white.withOpacity(config.floatConfig.opacity),
              child: Column(
                children: [
                  const Padding(padding: EdgeInsets.all(3)),
                  for (var stock in stockList!)
                    Column(
                      children: [
                        Text(
                          generateStockText(stock),
                          style: TextStyle(
                            color: stock.color,
                            fontSize: config.floatConfig.fontSize * 100,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.left,
                        ),
                        if (stock.symbol != stockList!.last.symbol) const Divider(indent: 15),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ));
  }
}
