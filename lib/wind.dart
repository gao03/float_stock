import 'dart:async';
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
  late List<StockInfo> stockList;

  final int stockHeightBase = 400;

  @override
  void initState() {
    super.initState();
    config = widget.config;
    stockList = config.stockList.where((i) => i.showInFloat).toList();

    // refresh(widget.config);
    // Timer(const Duration(seconds: 1), () {
    //   refresh(widget.config);
    // });
    SchedulerBinding.instance.addPostFrameCallback((_) {
      w = Window.of(context);
      w?.onData((source, name, data) async {
        if (name == "config") {
          refresh(AppConfig.fromJson(jsonDecode(data)));
        } else if (name == "stockList") {
          var newData = (json.decode(data) as List).map((data) => StockInfo.fromJson(data)).toList();
          setState(() {
            stockList = newData;
          });
        }
      });
    });
  }

  void refresh(AppConfig newConfig) async {
    var stockMap = {for (var e in config.stockList) e.key: e};
    for (var stock in newConfig.stockList) {
      stock.price = stockMap[stock.key]?.price;
    }
    setState(() {
      config = newConfig;
      stockList = config.stockList.where((i) => i.showInFloat).toList();
    });
    await w?.show(visible: newConfig.floatConfig.enable);
    // var screenHeight = w?.system?.screenHeight ?? newConfig.floatConfig.screenHeight;
    var screenWidth = w?.system?.screenWidth ?? newConfig.floatConfig.screenWidth;
    await w?.update(WindowConfig(
      height: (newConfig.floatConfig.windowHeight * stockHeightBase * stockList.length).toInt(),
      width: (newConfig.floatConfig.windowWidth * screenWidth).toInt(),
    ));

    // timer?.cancel();
    // timer = Timer.periodic(Duration(seconds: newConfig.floatConfig.frequency), (timer) {
    //   refreshStockInfo();
    // });
    // refreshStockInfo();
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: config.floatConfig.windowWidth * config.floatConfig.screenWidth,
        height: config.floatConfig.windowHeight * stockHeightBase * stockList.length,
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
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.left),
                  Offstage(offstage: (stock.key == stockList.last.key), child: const Divider(indent: 15)),
                ])
            ])));
  }
}
