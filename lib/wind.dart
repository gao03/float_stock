import 'dart:async';
import 'dart:convert';

import 'package:float_stock/entity.dart';
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
    stockList = config.stockList;

    timer = Timer.periodic(Duration(seconds: config.floatConfig.frequency), (timer) {
      refreshStockInfo();
    });

    SchedulerBinding.instance.addPostFrameCallback((_) {
      w = Window.of(context);
      w?.onData((source, name, data) async {
        var newConfig = AppConfig.fromJson(jsonDecode(data));
        stockList = newConfig.stockList;

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
    var price = stock.showPrice?.toStringAsFixed(2) ?? '-';
    var diff = stock.showDiff == null ? '-' : '${stock.showDiff!.toStringAsFixed(2)}%';
    return [stock.name, stock.code, price, diff][index];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        width: config.floatConfig.windowWidth * config.floatConfig.screenWidth,
        height: config.floatConfig.windowHeight * config.floatConfig.screenHeight,
        child: Card(
            color: Colors.white.withOpacity(config.floatConfig.opacity),
            child: Column(children: [
              const Padding(
                padding: EdgeInsets.all(3),
              ),
              for (var stock in stockList.where((i) => i.showInFloat))
                Column(children: [
                  Text(generateStockText(stock),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                      ),
                      textAlign: TextAlign.left),
                  const Divider(indent: 15),
                ])
            ])));
  }
}
