import 'dart:async';
import 'dart:convert';
import 'dart:developer';

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
    WidgetsFlutterBinding.ensureInitialized();

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
      ls.init(c.appKey, c.appSecret, c.accessToken, onQuote);
      lsInit = true;
    }
  }

  Future<void> onQuote(String symbol, PushQuote quote) async {
    for (var stock in stockList!) {
      debugPrint("onQuote: $symbol");
      if (symbol.startsWith(convertStockCode(stock).toUpperCase()) &&
          quote.lastDone != null) {
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
    var screenWidth =
        w?.system?.screenWidth ?? newConfig.floatConfig.screenWidth;
    if (screenWidth == 0) {
      screenWidth = newConfig.floatConfig.screenWidth;
    }
    await w?.update(WindowConfig(
      height: (newConfig.floatConfig.windowHeight *
              stockHeightBase *
              stockList!.length)
          .toInt(),
      width: (newConfig.floatConfig.windowWidth * screenWidth).toInt(),
    ));
  }

  void updateStockList(List<StockInfo> newStockList) {
    debugPrint("updateStockList all: ${jsonEncode(newStockList)}");
    var filterStockList = newStockList
        .where((i) => i.showInFloat == true)
        .where(checkStockCanShow)
        .toList();
    debugPrint("updateStockList filter: ${jsonEncode(filterStockList)}");
    ls.subscribes(filterStockList
        .map((e) => convertStockCode(e))
        .toList()
        .cast<String>());
    setState(() {
      stockList = filterStockList;
    });
  }

  String convertStockCode(StockInfo stock) {
    var code = stock.symbol;
    if (stock.type == "HK") {
      while (code.startsWith("0")) {
        code = code.substring(1);
      }
    }
    return code;
  }

  String generateStockText(StockInfo stock) {
    return formatNum(stock.lastPrice);
  }

  Color getStockColor(double? curPrice, double? oldPrice) {
    return curPrice == oldPrice || curPrice == null || oldPrice == null
        ? Colors.black
        : curPrice > oldPrice
            ? Colors.red
            : Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: config.floatConfig.windowWidth * config.floatConfig.screenWidth,
        height: config.floatConfig.windowHeight *
            stockHeightBase *
            stockList!.length,
        child: GestureDetector(
            onDoubleTap: () {
              w?.launchMainActivity();
            },
            onLongPress: () {
              // w?.hide();
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
                            fontSize: config.floatConfig.fontSize * 100,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.left),
                      Offstage(
                          offstage: (stock.symbol == stockList!.last.symbol),
                          child: const Divider(indent: 15)),
                    ])
                ]))));
  }
}
