import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:bruno/bruno.dart';
import 'package:float_stock/api.dart';
import 'package:float_stock/config.dart';
import 'package:float_stock/utils.dart';
import 'package:float_stock/widget.dart';
import 'package:float_stock/wind.dart';
import 'package:float_stock/entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_floatwing/flutter_floatwing.dart';
import 'package:collection/collection.dart';

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
  Window windowConfig = WindowConfig(route: "/float", draggable: true, autosize: false).to();

  // 展示字段组建需要的数据
  final floatWindowColumn = ["名称", "代码", "价格", "涨跌幅"];
  String floatSelectColumnStr = '';
  late List<bool> floatWindowSelectColumnFlagList = List.filled(floatWindowColumn.length, false);

  double? _maxHeight;
  double? _maxWidth;

  @override
  void initState() {
    super.initState();

    updateUiHelperVar();

    _createWindows();
  }

  _createWindows() async {
    await FloatwingPlugin().initialize();

    var isRunning = await FloatwingPlugin().isServiceRunning();
    if (!isRunning) {
      await FloatwingPlugin().startService();
    }
  }

  double get maxHeight {
    _maxHeight ??= MediaQuery.of(context).size.height;
    return _maxHeight!;
  }

  double get maxWidth {
    _maxWidth ??= MediaQuery.of(context).size.width;
    return _maxWidth!;
  }

  void updateUiHelperVar() {
    for (var i = 0; i < floatWindowColumn.length; i++) {
      floatWindowSelectColumnFlagList[i] = config.floatConfig.showColumns.contains(i);
    }
    floatSelectColumnStr = config.floatConfig.showColumns.map((e) => floatWindowColumn[e]).toList().join(",");
  }

  checkFloatPermission() async {
    var p1 = await FloatwingPlugin().checkPermission();

    if (!p1) {
      if (context.mounted) {
        BrnToast.show("请配置悬浮窗权限", context);
      }
      FloatwingPlugin().openPermissionSetting();
      return;
    }

    var p2 = await FloatwingPlugin().isServiceRunning();
    if (!p2) {
      FloatwingPlugin().startService();
    }
    var _w = FloatwingPlugin().windows[windowConfig.id];
    if (null != _w) {
      return;
    }
    windowConfig.create();
  }

  void addNewStock(StockInfo stock) async {
    var oldStock = config.stockList.firstWhereOrNull((e) => e.key == stock.key);
    if (oldStock == null) {
      config.stockList.add(stock);
      BrnToast.show("${stock.name}已经在列表中了", context);
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
    var showStockCount =  config.stockList.where((s) => s.showInFloat).length;
    config.floatConfig.windowHeight = max(config.floatConfig.windowHeight, 40.0 * showStockCount / maxHeight);
    config.floatConfig.screenWidth = MediaQuery.of(context).size.width;
    config.floatConfig.screenHeight = MediaQuery.of(context).size.height;
    var result = await updateConfig(config);
    if (context.mounted && notify) {
      BrnToast.show("操作${result ? "成功" : "失败"}", context);
    }
    FloatwingPlugin().windows[windowConfig.id]?.share(jsonEncode(config.toJson())).then((value) {
      // and window can return value.
      print("share then");
    });
    if (result) {
      setState(() {
        config = config;
        updateUiHelperVar();
      });
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

  void submitConfig() async {
    windowConfig.config?.width = (config.floatConfig.windowWidth * config.floatConfig.screenWidth).toInt();
    windowConfig.config?.height = (config.floatConfig.windowHeight * config.floatConfig.screenHeight).toInt();
    if (config.floatConfig.enable) {
      checkFloatPermission();
      windowConfig.start();
      windowConfig.show();
    } else {
      windowConfig.close();
    }
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
            heightFactor: 1,
            child: Column(children: [
              BrnNormalFormGroup(title: "悬浮窗配置", children: [
                BrnSwitchFormItem(
                  title: "是否启用",
                  isRequire: false,
                  value: config.floatConfig.enable,
                  onChanged: (oldValue, newValue) {
                    setState(() {
                      config.floatConfig.enable = newValue;
                    });
                  },
                ),
                SliderWidget(
                    title: "透明度",
                    value: config.floatConfig.opacity,
                    onChanged: (data) {
                      setState(() {
                        config.floatConfig.opacity = data;
                        updateConfigAndRefresh();
                      });
                    }),
                SliderWidget(
                    title: "窗口宽度",
                    minValue: 0.05,
                    value: config.floatConfig.windowWidth,
                    label: (config.floatConfig.windowWidth * maxWidth).toStringAsFixed(0),
                    onChanged: (data) {
                      setState(() {
                        config.floatConfig.windowWidth = data;
                        updateConfigAndRefresh();
                      });
                    }),
                SliderWidget(
                    title: "窗口高度",
                    minValue: 0.05,
                    maxValue: 0.5,
                    value: config.floatConfig.windowHeight,
                    label: (config.floatConfig.windowHeight * maxHeight).toStringAsFixed(0),
                    onChanged: (data) {
                      setState(() {
                        config.floatConfig.windowHeight = data;
                        updateConfigAndRefresh();
                      });
                    }),
                BrnTextQuickSelectFormItem(
                  title: "展示字段",
                  btnsTxt: floatWindowColumn,
                  value: floatSelectColumnStr,
                  selectBtnList: floatWindowSelectColumnFlagList,
                  onBtnSelectChanged: (int index) {
                    setState(() {
                      if (config.floatConfig.showColumns.contains(index)) {
                        config.floatConfig.showColumns.remove(index);
                      } else {
                        config.floatConfig.showColumns.add(index);
                      }
                      floatWindowSelectColumnFlagList[index] = !floatWindowSelectColumnFlagList[index];
                      updateConfigAndRefresh();
                    });
                  },
                ),
                BrnStepInputFormItem(
                  value: config.floatConfig.frequency,
                  title: "刷新频率(秒)",
                  minLimit: 1,
                  onChanged: (oldValue, newValue) {
                    config.floatConfig.frequency = newValue;
                    updateConfigAndRefresh();
                  },
                )
              ]),
              const Divider(indent: 5),
              BrnNormalFormGroup(title: "股票信息", children: [
                SizedBox(
                  height: max(maxHeight - 616, 200),
                  child: ReorderableListView(
                      onReorder: (int oldIndex, int newIndex) {
                        setState(() {
                          if (oldIndex < newIndex) {
                            newIndex -= 1;
                          }
                          var temp = config.stockList.removeAt(oldIndex);
                          config.stockList.insert(newIndex, temp);
                          updateConfigAndRefresh();
                        });
                      },
                      children: [
                        for (var stock in config.stockList)
                          Dismissible(
                              key: Key(stock.key),
                              background: Container(color: Colors.red),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (direction) => deleteStock(stock),
                              child: BrnSwitchFormItem(
                                title: stock.name,
                                subTitle: stock.code,
                                value: stock.showInFloat,
                                // prefixIconType: BrnPrefixIconType.remove,
                                isRequire: false,
                                onRemoveTap: () {
                                  deleteStock(stock);
                                },
                                onChanged: (oldValue, newValue) {
                                  setState(() {
                                    stock.showInFloat = newValue;
                                    updateConfigAndRefresh();
                                  });
                                  BrnToast.show("在悬浮窗${newValue ? '' : '不'}展示${stock.name}", context);
                                },
                              ))
                      ]),
                )
              ]),
              BrnBottomButtonPanel(
                mainButtonName: '确定',
                mainButtonOnTap: submitConfig,
                secondaryButtonName: '添加',
                secondaryButtonOnTap: showStockInputDialog,
              )
            ])));
  }
}
