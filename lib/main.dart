import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:bruno/bruno.dart';
import 'package:float_stock/api.dart';
import 'package:float_stock/config.dart';
import 'package:float_stock/data.dart';
import 'package:float_stock/utils.dart';
import 'package:float_stock/widget.dart';
import 'package:float_stock/wind.dart';
import 'package:float_stock/entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_floatwing/flutter_floatwing.dart';
import 'package:collection/collection.dart';
import 'package:flutter/rendering.dart';

late AppConfig config;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  config = await readConfig();
  BrnInitializer.register(
      allThemeConfig: BrnAllThemeConfig(
    commonConfig: BrnCommonConfig(brandPrimary: Colors.red, brandAuxiliary: Colors.redAccent),
  ));
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    debugPaintSizeEnabled = false;
    return MaterialApp(
      title: '盯盘',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      initialRoute: "/",
      routes: {
        "/": (_) => const HomePage(title: "盯"),
        "/float": (_) => FloatWindowView(config: config).floatwing(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Window window = WindowConfig(
    id: "float",
    route: "/float",
    draggable: true,
    autosize: false,
    y: 100,
  ).to();

  // 展示字段组建需要的数据
  final floatWindowColumn = ["名称", "代码", "价格", "涨跌幅"];
  late List<bool> floatWindowSelectColumnFlagList;

  double? _maxHeight;
  double? _maxWidth;
  Timer? timer;

  GlobalKey fontColorTypeKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    floatWindowSelectColumnFlagList =
        floatWindowColumn.asMap().keys.map((e) => config.floatConfig.showColumns.contains(e)).toList();
    initStateAsync();
  }

  void initStateAsync() async {
    await _createWindows();

    Timer(const Duration(seconds: 5), () {
      timer = Timer.periodic(Duration(seconds: config.floatConfig.frequency), (timer) {
        refreshStockData();
      });
    });
  }

  void refreshStockData() async {
    var newStockData = await getStockLatestInfo(config.stockList);
    setState(() {
      config.stockList = newStockData;
    });
    var stockListStr = newStockData.where((i) => i.showInFloat).map((e) => e.toJson()).toList();
    await shareDataToFloat(stockListStr, "stockList");
  }

  _createWindows() async {
    await FloatwingPlugin().initialize();
    var isRunning = await FloatwingPlugin().isServiceRunning();
    if (!isRunning) {
      await FloatwingPlugin().startService();
    }
    await checkAndShowWindow();
  }

  double get maxHeight {
    _maxHeight ??= MediaQuery.of(context).size.height;
    return _maxHeight!;
  }

  double get maxWidth {
    _maxWidth ??= MediaQuery.of(context).size.width;
    return _maxWidth!;
  }

  String get floatSelectColumnStr {
    return config.floatConfig.showColumns.map((e) => floatWindowColumn[e]).toList().join(",");
  }

  checkFloatPermission() async {
    var p1 = await FloatwingPlugin().checkPermission();

    var p2 = await FloatwingPlugin().isServiceRunning();
    if (!p2) {
      await FloatwingPlugin().startService();
    }

    if (!p1) {
      if (context.mounted) {
        BrnToast.show("请配置悬浮窗权限", context);
      }
      await FloatwingPlugin().openPermissionSetting();
      return;
    }

    var _w = FloatwingPlugin().windows[window.id];
    if (null != _w) {
      return;
    }
    await window.create(start: true);
  }

  void addNewStock(StockInfo stock) async {
    var oldStock = config.stockList.firstWhereOrNull((e) => e.key == stock.key);
    if (oldStock != null) {
      BrnToast.show("${stock.name}已经在列表中了", context);
      // 添加的时候，默认展示在悬浮窗
      oldStock.showInFloat = true;
    } else {
      config.stockList.add(stock);
    }
    await updateConfigAndRefresh();
  }

  Future<bool> deleteStock(stock) async {
    var isConfirm = await showConfirmDialog(context, "确定删除【${stock.name}】?");
    if (!isConfirm) {
      return false;
    }
    config.stockList.removeWhere((element) => element.key == stock.key);
    await updateConfigAndRefresh();
    return true;
  }

  Future updateConfigAndRefresh({notify = true}) async {
    config.floatConfig.screenWidth = MediaQuery.of(context).size.width;
    config.floatConfig.screenHeight = MediaQuery.of(context).size.height;
    config.stockList.sort((a, b) => a.showInFloat == b.showInFloat
        ? 0
        : a.showInFloat
            ? -1
            : 1);

    await checkFloatPermission();

    var result = await updateConfig(config);
    if (context.mounted && notify && !result) {
      BrnToast.show("操作失败", context);
    }

    timer?.cancel();
    timer = Timer.periodic(Duration(seconds: config.floatConfig.frequency), (timer) {
      refreshStockData();
    });

    await checkAndShowWindow();
    setState(() {});
  }

  Future<void> checkAndShowWindow() async {
    if (config.floatConfig.enable) {
      await checkFloatPermission();
      // var showStockCount = config.stockList.where((i) => i.showInFloat).length;
      // var showColumnCount = config.floatConfig.showColumns.length;
      // if (showStockCount == 0) {
      //   if (context.mounted) {
      //     BrnToast.show("可显示股票为空，不开启悬浮窗", context);
      //   }
      //   return;
      // }
      // if (showColumnCount == 0) {
      //   if (context.mounted) {
      //     BrnToast.show("可显示字段为空，不开启悬浮窗", context);
      //   }
      //   return;
      // }
    }

    await shareDataToFloat(config.toJson(), "config");
  }

  Future<void> shareDataToFloat(dynamic data, String name) async {
    try {
      return FloatwingPlugin().windows[window.id]?.share(jsonEncode(data), name: name);
    } catch (e) {
      print(e);
    }
  }

  Future<StockInfo?> chooseNewStock(List<StockInfo> stockList) async {
    var selectedIndex = 0;

    if (stockList.length == 1) {
      var isConfirm = await showConfirmDialog(context, "确定选择【${stockList[0].name}】?");
      if (!isConfirm) {
        selectedIndex = -1;
      }
    } else {
      var conditions = stockList.map((e) => e.name).toList().cast<String>();
      await showDialog(
          context: context,
          builder: (_) => StatefulBuilder(
                builder: (context, state) {
                  return BrnSingleSelectDialog(
                      isClose: true,
                      title: '请选择股票',
                      conditions: conditions,
                      checkedItem: conditions[selectedIndex],
                      submitText: '提交',
                      onItemClick: (BuildContext context, int index) {
                        selectedIndex = index;
                      },
                      onCloseClick: () {
                        selectedIndex = -1;
                      });
                },
              ));
    }
    return selectedIndex >= 0 ? stockList[selectedIndex] : null;
  }

  void showStockInputDialog() async {
    {
      BrnMiddleInputDialog(
          title: '输入编号',
          cancelText: '取消',
          confirmText: '确定',
          maxLength: 100,
          maxLines: 1,
          autoFocus: true,
          onConfirm: (value) async {
            Navigator.pop(context);
            showLoadingDialog(context, "查询中");
            var stockList = await queryStockByCode(value);
            if (context.mounted) {
              closeLoadingDialog(context);
            }
            if (stockList.isEmpty) {
              if (context.mounted) {
                showToast(context, "没找到");
              }
            } else {
              var stock = await chooseNewStock(stockList);
              if (stock != null) {
                addNewStock(stock);
              }
            }
          },
          onCancel: () {
            Navigator.pop(context);
          }).show(context);
    }
  }

  void setStateAndSave(VoidCallback fn) {
    setState(fn);
    updateConfigAndRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
          child: Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                  child: Column(children: [
                NormalFormGroup(title: "悬浮窗配置", children: [
                  BrnSwitchFormItem(
                    title: "是否启用",
                    isRequire: false,
                    value: config.floatConfig.enable,
                    onChanged: (oldValue, newValue) {
                      setStateAndSave(() {
                        config.floatConfig.enable = newValue;
                      });
                    },
                  ),
                  SliderWidget(
                      title: "透明度   ",
                      value: config.floatConfig.opacity,
                      onChanged: (data) {
                        setStateAndSave(() {
                          config.floatConfig.opacity = data;
                        });
                      }),
                  SliderWidget(
                      title: "窗口宽度",
                      minValue: 0.05,
                      maxValue: 1,
                      value: config.floatConfig.windowWidth,
                      onChanged: (data) {
                        setStateAndSave(() {
                          config.floatConfig.windowWidth = data;
                        });
                      }),
                  SliderWidget(
                      title: "窗口高度",
                      minValue: 0.05,
                      maxValue: 1,
                      value: config.floatConfig.windowHeight,
                      onChanged: (data) {
                        setStateAndSave(() {
                          config.floatConfig.windowHeight = data;
                        });
                      }),
                  SliderWidget(
                      title: "字体大小",
                      minValue: 10,
                      maxValue: 60,
                      value: config.floatConfig.fontSize,
                      label: config.floatConfig.fontSize.toStringAsFixed(1),
                      onChanged: (data) {
                        setStateAndSave(() {
                          config.floatConfig.fontSize = data;
                        });
                      }),
                  SliderWidget(
                    value: config.floatConfig.frequency.toDouble(),
                    title: "刷新频率",
                    minValue: 1,
                    maxValue: 100,
                    label: "${config.floatConfig.frequency.toInt()}秒",
                    onChanged: (data) {
                      setStateAndSave(() {
                        config.floatConfig.frequency = data.toInt();
                      });
                    },
                  ),
                  BrnRadioInputFormItem(
                    key: fontColorTypeKey,
                    title: "字体颜色",
                    options: const ["黑色", "当日涨跌", "同比涨跌"],
                    value: config.floatConfig.fontColorType,
                    onChanged: (oldValue, newValue) {
                      if (newValue != null) {
                        setStateAndSave(() {
                          config.floatConfig.fontColorType = newValue;
                        });
                      }
                    },
                  ),
                  BrnTextQuickSelectFormItem(
                    title: "展示字段",
                    btnsTxt: floatWindowColumn,
                    value: floatSelectColumnStr,
                    selectBtnList: floatWindowSelectColumnFlagList,
                    onBtnSelectChanged: (int index) {
                      setStateAndSave(() {
                        if (config.floatConfig.showColumns.contains(index)) {
                          config.floatConfig.showColumns.remove(index);
                        } else {
                          config.floatConfig.showColumns.add(index);
                        }
                        floatWindowSelectColumnFlagList[index] = !floatWindowSelectColumnFlagList[index];
                      });
                    },
                  ),
                ]),
                const Divider(indent: 5, color: Colors.white),
                NormalFormGroup(
                    title: "股票",
                    onReorder: (int oldIndex, int newIndex) {
                      setStateAndSave(() {
                        if (oldIndex < newIndex) {
                          newIndex -= 1;
                        }
                        var temp = config.stockList.removeAt(oldIndex);
                        config.stockList.insert(newIndex, temp);
                      });
                    },
                    children: [
                      for (var stock in config.stockList)
                        Dismissible(
                            key: Key(stock.key),
                            background: Container(color: Colors.red),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (direction) => deleteStock(stock),
                            child: StockInfoWidget(
                                stock: stock,
                                onVisibleChange: (value) {
                                  setStateAndSave(() {
                                    stock.showInFloat = value;
                                  });
                                  BrnToast.show("在悬浮窗${value ? '' : '不'}展示${stock.name}", context);
                                })),
                    ]),
              ])))),
      bottomSheet: BrnBottomButtonPanel(
        mainButtonName: '确定',
        mainButtonOnTap: updateConfigAndRefresh,
        secondaryButtonName: '添加',
        secondaryButtonOnTap: showStockInputDialog,
      ),
    );
  }
}
