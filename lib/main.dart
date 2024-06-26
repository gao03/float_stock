import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bruno/bruno.dart';
import 'package:float_stock/config.dart';
import 'package:float_stock/sina.dart';
import 'package:float_stock/utils.dart';
import 'package:float_stock/widget.dart';
import 'package:float_stock/wind.dart';
import 'package:float_stock/entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_floatwing/flutter_floatwing.dart';
import "package:collection/collection.dart";
import 'package:flutter/rendering.dart';
import 'dart:developer';

late AppConfig config;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  config = await readConfig();
  BrnInitializer.register(
      allThemeConfig: BrnAllThemeConfig(
    commonConfig: BrnCommonConfig(
        brandPrimary: Colors.red, brandAuxiliary: Colors.redAccent),
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
          primarySwatch: Colors.red, scaffoldBackgroundColor: Colors.white),
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
  final _debouncer = Debouncer(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    floatWindowSelectColumnFlagList = floatWindowColumn
        .asMap()
        .keys
        .map((e) => config.floatConfig.showColumns.contains(e))
        .toList();
    _createWindows();
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
    return config.floatConfig.showColumns
        .map((e) => floatWindowColumn[e])
        .toList()
        .join(",");
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

    var w = FloatwingPlugin().windows[window.id];
    if (null != w) {
      return;
    }
    await window.create(start: true);
  }

  void addNewStock(StockInfo stock) async {
    var oldStock =
        config.stockList.firstWhereOrNull((e) => e.symbol == stock.symbol);
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
    config.stockList.removeWhere((element) => element.symbol == stock.symbol);
    await updateConfigAndRefresh();
    return true;
  }

  Future updateConfigAndRefresh({notify = true}) async {
    var start = DateTime.now();
    log('start: $start');

    config.floatConfig.screenWidth = MediaQuery.of(context).size.width;
    config.floatConfig.screenHeight = MediaQuery.of(context).size.height;
    config.stockList.sort((a, b) => a.showInFloat == b.showInFloat
        ? 0
        : a.showInFloat
            ? -1
            : 1);

    await checkFloatPermission();
    log('checkFloatPermission: ${start.difference(DateTime.now())}');
    await checkLongPortConfig();
    log('checkLongPortConfig: ${start.difference(DateTime.now())}');
    var result = await updateConfig(config);
    log('updateConfig: ${start.difference(DateTime.now())}');
    if (context.mounted && notify && !result) {
      BrnToast.show("操作失败", context);
    }

    await checkAndShowWindow();
    log('checkAndShowWindow: ${start.difference(DateTime.now())}');

    setState(() {});
  }

  Future<void> checkLongPortConfig() async {
    if (config.longPortConfig != null &&
        config.longPortConfig!.appKey.isNotEmpty) {
      return;
    }
    var inputCfg = LongPortConfig("", "", "");
    BrnDialogManager.showSingleButtonDialog(context,
        label: "确定",
        title: "请填写 LongPort 配置",
        messageWidget: NormalFormGroup(
          title: "",
          children: [
            BrnTextInputFormItem(
              title: "App Key",
              onChanged: (newValue) {
                inputCfg.appKey = newValue.trim();
              },
            ),
            BrnTextInputFormItem(
              title: "App Secret",
              onChanged: (newValue) {
                inputCfg.appSecret = newValue.trim();
              },
            ),
            BrnTextInputFormItem(
              title: "Access Token",
              onChanged: (newValue) {
                inputCfg.accessToken = newValue.trim();
              },
            ),
          ],
        ), onTap: () async {
      config.longPortConfig = inputCfg;
      if (context.mounted) {
        Navigator.pop(context);
      }
    });
  }

  Future<void> checkAndShowWindow() async {
    if (config.floatConfig.enable) {
      await checkFloatPermission();
      window.show(visible: true);
    }

    try {
      await shareDataToFloat(config.toJson(), "config");
    } catch (e) {
      log("checkAndShowWindow", error: e);
    }
  }

  Future<void> shareDataToFloat(dynamic data, String name) async {
    try {
      return FloatwingPlugin()
          .windows[window.id]
          ?.share(jsonEncode(data), name: name);
    } catch (e) {
      log("shareDataToFloat", error: e);
    }
  }

  Future<StockInfo?> chooseNewStock(List<StockInfo> stockList) async {
    var selectedIndex = 0;

    if (stockList.length == 1) {
      var isConfirm =
          await showConfirmDialog(context, "确定选择【${stockList[0].name}】?");
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
    _debouncer.run(() {
      updateConfigAndRefresh();
    });
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
                      minValue: 0.01,
                      maxValue: 0.5,
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
                      minValue: 5,
                      maxValue: 30,
                      value: config.floatConfig.fontSize,
                      label: config.floatConfig.fontSize.toStringAsFixed(1),
                      onChanged: (data) {
                        setStateAndSave(() {
                          config.floatConfig.fontSize = data;
                        });
                      }),
                  BrnRadioInputFormItem(
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
                        floatWindowSelectColumnFlagList[index] =
                            !floatWindowSelectColumnFlagList[index];
                      });
                    },
                  ),
                ]),
                Container(
                  color: const Color(0xfafafaff),
                  height: 10,
                ),
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
                            key: Key(stock.symbol),
                            background: Container(color: Colors.red),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (direction) => deleteStock(stock),
                            child: StockInfoWidget(
                                stock: stock,
                                onVisibleChange: (value) {
                                  setStateAndSave(() {
                                    stock.showInFloat = value;
                                  });
                                  BrnToast.show(
                                      "在悬浮窗${value ? '' : '不'}展示${stock.name}",
                                      context);
                                })),
                    ]),
              ])))),
      bottomSheet: BrnBottomButtonPanel(
        mainButtonName: '确定',
        mainButtonOnTap: updateConfigAndRefresh,
        secondaryButtonName: '添加',
        secondaryButtonOnTap: showStockInputDialog,
        iconButtonList: [
          BrnVerticalIconButton(
            name: "关闭",
            iconWidget: const Icon(Icons.exit_to_app),
            onTap: () {
              exit(0);
            },
          ),
        ],
      ),
    );
  }
}
