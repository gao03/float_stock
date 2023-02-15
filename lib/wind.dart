import 'dart:async';
import 'dart:convert';

import 'package:float_stock/entity.dart';
import 'package:float_stock/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_floatwing/flutter_floatwing.dart';

import 'data.dart';

class FloatWindowView extends StatefulWidget {
  AppConfig config;

  FloatWindowView({Key? key, required this.config}) : super(key: key);

  @override
  State<FloatWindowView> createState() => _FloatWindowViewState();
}

class _FloatWindowViewState extends State<FloatWindowView> {
  late AppConfig config;
  late Timer timer;
  late List<StockInfo> stockList;

  @override
  void initState() {
    super.initState();
    config = widget.config;
    stockList = config.stockList.where((i) => i.showInFloat).toList();

    timer = Timer.periodic(Duration(seconds: config.floatConfig.frequency), (timer) {
      refreshStockInfo();
    });

    SchedulerBinding.instance.addPostFrameCallback((_) {
      w = Window.of(context);
      w?.onData((source, name, data) async {
        var newConfig = AppConfig.fromJson(jsonDecode(data));
        stockList = newConfig.stockList.where((i) => i.showInFloat).toList();

        setState(() {
          config = newConfig;
        });

        var screenHeight = w?.system?.screenHeight ?? newConfig.floatConfig.screenHeight;
        var screenWidth = w?.system?.screenWidth ?? newConfig.floatConfig.screenWidth;
        w?.update(WindowConfig(
          height: (newConfig.floatConfig.windowHeight * screenHeight).toInt(),
          width: (newConfig.floatConfig.windowWidth * screenWidth).toInt(),
        ));

        if (newConfig.floatConfig.enable) {
        } else {
          w?.hide();
        }

        timer.cancel();
        timer = Timer.periodic(Duration(seconds: newConfig.floatConfig.frequency), (timer) {
          refreshStockInfo();
        });
        refreshStockInfo();
      });
    });
  }

  void refreshStockInfo() async {
    var newStockList = await getStockLatestInfo(stockList);
    setState(() {
      stockList = newStockList;
    });
  }

  Window? w;
  bool dragging = false;

  String generateStockText(StockInfo stock) {
    return config.floatConfig.showColumns.map((e) => getStockField(stock, e)).join(" ");
  }

  String getStockField(StockInfo stock, int index) {
    //["名称", "代码", "价格", "涨跌幅"];
    return [stock.name, stock.code, formatNum(getShowPrice(stock)), '${formatNum(getShowDiff(stock))}%'][index];
  }

  String formatNum(double? num) {
    if (num == null) {
      return '-';
    }

    // 有些情况下，数据是有3位小数的，这种时候要保留3位
    var ln = num.toStringAsFixed(3);
    if (ln[ln.length - 1] != '0') {
      return ln;
    }

    return num.toStringAsFixed(2);
  }

  double? getShowPrice(StockInfo stock) {
    if (stock.type != "gb_") {
      return stock.price?.currentPrice;
    }
    if (checkUsMarketStatus() == MarketStatus.pre || checkUsMarketStatus() == MarketStatus.post) {
      return stock.price?.outPrice;
    }
    return stock.price?.currentPrice;
  }

  double? getShowDiff(StockInfo stock) {
    if (stock.type != "gb_") {
      return stock.price?.currentDiff;
    }
    if (checkUsMarketStatus() == MarketStatus.pre || checkUsMarketStatus() == MarketStatus.post) {
      return stock.price?.outDiff;
    }
    return stock.price?.currentDiff;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        width: config.floatConfig.windowWidth * config.floatConfig.screenWidth,
        height: config.floatConfig.windowHeight * config.floatConfig.screenHeight,
        // color: Colors.white.withOpacity(config.floatConfig.opacity),
        child: Card(
            elevation: 0,
            color: Colors.white.withOpacity(config.floatConfig.opacity),
            child: Column(children: [
              const Padding(
                padding: EdgeInsets.all(3),
              ),
              for (var stock in stockList)
                Column(children: [
                  Text(generateStockText(stock),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                      ),
                      textAlign: TextAlign.left),
                  Offstage(offstage: (stock.key == stockList.last.key), child: const Divider(indent: 15)),
                ])
            ])));
  }
}
