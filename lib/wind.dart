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
  State<FloatWindowView> createState() => _FloatWindowViewState();
}

class _FloatWindowViewState extends State<FloatWindowView> {
  late AppConfig config;
  List<StockInfo>? stockList;
  Window? window;
  final int stockHeightBase = 400;
  final Longport longportService = Longport();
  bool isLongportInitialized = false;

  @override
  void initState() {
    super.initState();
    config = widget.config;
    _initializeLongport();
    _updateStockList(config.stockList);

    SchedulerBinding.instance.addPostFrameCallback((_) {
      window = Window.of(context);
      window?.onData((source, name, data) async {
        if (name == "config") {
          _refresh(AppConfig.fromJson(jsonDecode(data)));
        }
      });
    });
  }

  void _initializeLongport() async {
    var longportConfig = config.longPortConfig;
    if (longportConfig != null && !isLongportInitialized) {
      longportService.init(longportConfig.appKey, longportConfig.appSecret, longportConfig.accessToken, _onQuoteReceived);
      isLongportInitialized = true;
    }
  }

  Future<void> _onQuoteReceived(String symbol, PushQuote quote) async {
    if (stockList == null) return;

    for (var stock in stockList!) {
      if (symbol.startsWith(_convertStockCode(stock).toUpperCase()) && quote.lastDone != null) {
        stock.color = _getStockColor(quote.lastDone, stock.lastPrice);
        stock.lastPrice = quote.lastDone!;
        break;
      }
    }
    setState(() {
      stockList = stockList?.where(_canStockBeShown).toList();
    });
  }

  bool _canStockBeShown(StockInfo stock) {
    return stock.showInFloat && checkMarketStatus(stock.type) != MarketStatus.close;
  }

  void _refresh(AppConfig newConfig) async {
    setState(() {
      config = newConfig;
      _updateStockList(config.stockList);
    });
    _initializeLongport();
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

  void _updateStockList(List<StockInfo> newStockList) {
    var filteredStockList = newStockList
            .where((stock) => stock.showInFloat)
            .where((stock) => checkMarketStatus(stock.type) != MarketStatus.close)
            .toList();
    longportService.subscribes(filteredStockList.map(_convertStockCode).toList());
    setState(() {
      stockList = filteredStockList;
    });
  }

  String _convertStockCode(StockInfo stock) {
    var code = stock.symbol;
    if (stock.type == "HK") {
      code = code.replaceFirst(RegExp(r'^0+'), '');
    }
    return code;
  }

  String _generateStockText(StockInfo stock) {
    return formatNum(stock.lastPrice);
  }

  Color _getStockColor(double? currentPrice, double? previousPrice) {
    if (currentPrice == null || previousPrice == null || currentPrice == previousPrice) {
      return Colors.black;
    }
    return currentPrice > previousPrice ? Colors.red : Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
                      _generateStockText(stock),
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
    );
  }
}
