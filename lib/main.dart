import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:float_stock/config.dart';
import 'package:float_stock/sina.dart';
import 'package:float_stock/utils.dart';
import 'package:float_stock/widget.dart';
import 'package:float_stock/wind.dart';
import 'package:float_stock/entity.dart';
import 'package:flutter_floatwing/flutter_floatwing.dart';
import "package:collection/collection.dart";
import 'dart:developer';

import 'loading.dart';

late AppConfig config;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  config = await readConfig();
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

  final floatWindowColumn = ["名称", "代码", "价格", "涨跌幅"];

  double? _maxHeight;
  double? _maxWidth;
  final _debounce = Debouncer(milliseconds: 500);

  @override
  void initState() {
    super.initState();
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

  checkFloatPermission() async {
    var p1 = await FloatwingPlugin().checkPermission();

    var p2 = await FloatwingPlugin().isServiceRunning();
    if (!p2) {
      await FloatwingPlugin().startService();
    }

    if (!p1) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("请配置悬浮窗权限")),
        );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${stock.name}已经在列表中了")),
      );
      oldStock.showInFloat = true;
    } else {
      config.stockList.add(stock);
    }
    await updateConfigAndRefresh();
  }

  Future<bool> deleteStock(stock) async {
    var isConfirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("确定删除【${stock.name}】?"),
          actions: [
            TextButton(
              child: const Text("取消"),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text("确定"),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
    if (!isConfirm) {
      return false;
    }
    config.stockList.removeWhere((element) => element.symbol == stock.symbol);
    await updateConfigAndRefresh();
    return true;
  }

  Future updateConfigAndRefresh({notify = true}) async {
    var start = DateTime.now();
    debugPrint('start: $start');

    config.floatConfig.screenWidth = MediaQuery.of(context).size.width;
    config.floatConfig.screenHeight = MediaQuery.of(context).size.height;
    config.stockList.sort((a, b) => a.showInFloat == b.showInFloat
        ? 0
        : a.showInFloat
            ? -1
            : 1);

    await checkFloatPermission();
    debugPrint('checkFloatPermission: ${start.difference(DateTime.now())}');
    await checkLongPortConfig();
    debugPrint('checkLongPortConfig: ${start.difference(DateTime.now())}');
    var result = await updateConfig(config);
    debugPrint('updateConfig: ${start.difference(DateTime.now())}');
    if (context.mounted && notify && !result) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("操作失败")),
      );
    }

    await checkAndShowWindow();
    debugPrint('checkAndShowWindow: ${start.difference(DateTime.now())}');

    setState(() {});
  }

  Future<void> checkLongPortConfig() async {
    if (config.longPortConfig != null &&
        config.longPortConfig!.appKey.isNotEmpty) {
      return;
    }
    var inputCfg = LongPortConfig("", "", "");
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("请填写 LongPort 配置"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: "App Key"),
                onChanged: (value) => inputCfg.appKey = value.trim(),
              ),
              TextField(
                decoration: const InputDecoration(labelText: "App Secret"),
                onChanged: (value) => inputCfg.appSecret = value.trim(),
              ),
              TextField(
                decoration: const InputDecoration(labelText: "Access Token"),
                onChanged: (value) => inputCfg.accessToken = value.trim(),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("确定"),
              onPressed: () {
                config.longPortConfig = inputCfg;
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
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
      var isConfirm = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("确定选择【${stockList[0].name}】?"),
            actions: [
              TextButton(
                child: const Text("取消"),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: const Text("确定"),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );
      if (!isConfirm) {
        selectedIndex = -1;
      }
    } else {
      var conditions = stockList.map((e) => e.name).toList().cast<String>();
      await showDialog(
        context: context,
        builder: (_) => StatefulBuilder(
          builder: (context, state) {
            return SimpleDialog(
              title: const Text('请选择股票'),
              children: conditions
                  .asMap()
                  .entries
                  .map((entry) => RadioListTile(
                        title: Text(entry.value),
                        value: entry.key,
                        groupValue: selectedIndex,
                        onChanged: (int? value) {
                          state(() {
                            selectedIndex = value!;
                          });
                        },
                      ))
                  .toList(),
            );
          },
        ),
      );
    }
    return selectedIndex >= 0 ? stockList[selectedIndex] : null;
  }

  void showStockInputDialog() async {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('输入编号'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "请输入编号"),
          ),
          actions: [
            TextButton(
              child: const Text("取消"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("确定"),
              onPressed: () async {
                Navigator.of(context).pop();
                LoadingScreen.instance().show(context: context);
                List<StockInfo> stockList = [];
                try {
                  stockList = await queryStockByCode(controller.text);
                } finally {
                  LoadingScreen.instance().hide();
                }

                if (stockList.isEmpty) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("没找到")),
                    );
                  }
                } else {
                  var stock = await chooseNewStock(stockList);
                  if (stock != null) {
                    addNewStock(stock);
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void setStateAndSave(VoidCallback fn) {
    setState(fn);
    _debounce.run(() {
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
                SwitchListTile(
                  title: const Text("是否启用"),
                  value: config.floatConfig.enable,
                  onChanged: (newValue) {
                    setStateAndSave(() {
                      config.floatConfig.enable = newValue;
                    });
                  },
                ),
                SliderWidget(
                  title: "透明度",
                  value: config.floatConfig.opacity,
                  onChanged: (data) {
                    setStateAndSave(() {
                      config.floatConfig.opacity = data;
                    });
                  },
                ),
                SliderWidget(
                  minValue: 0.01,
                  maxValue: 0.5,
                  value: config.floatConfig.windowWidth,
                  onChanged: (data) {
                    setStateAndSave(() {
                      config.floatConfig.windowWidth = data;
                    });
                  },
                  title: '窗口宽度',
                ),
                SliderWidget(
                  title: "窗口高度",
                  minValue: 0.05,
                  maxValue: 1,
                  value: config.floatConfig.windowHeight,
                  onChanged: (data) {
                    setStateAndSave(() {
                      config.floatConfig.windowHeight = data;
                    });
                  },
                ),
                SliderWidget(
                  title: "字体大小",
                  minValue: 0.05,
                  maxValue: 0.3,
                  value: config.floatConfig.fontSize,
                  onChanged: (data) {
                    setStateAndSave(() {
                      config.floatConfig.fontSize = data;
                    });
                  },
                ),
                Container(
                  color: const Color(0xfafafaff),
                  height: 10,
                ),
                ReorderableListView(
                  shrinkWrap: true,
                  onReorder: (int oldIndex, int newIndex) {
                    setStateAndSave(() {
                      if (oldIndex < newIndex) {
                        newIndex -= 1;
                      }
                      var temp = config.stockList.removeAt(oldIndex);
                      config.stockList.insert(newIndex, temp);
                    });
                  },
                  children: List.generate(config.stockList.length * 2, (index) {
                        if (index.isOdd) {
                          int itemIndex = index ~/ 2;
                          final stock = config.stockList[itemIndex];
                          return Dismissible(
                            key: Key(stock.symbol),
                            background: Container(color: Colors.red),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (direction) => deleteStock(stock),
                            child: ListTile(
                              title: Text(stock.name),
                              trailing: Switch(
                                value: stock.showInFloat,
                                onChanged: (bool value) {
                                  setState(() {
                                    stock.showInFloat = value;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "在悬浮窗${value ? '' : '不'}展示${stock.name}",
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        } else {
                          return Divider(
                            key: ValueKey('divider_$index'),
                            thickness: 0.5,
                            height: 1,
                            indent: 10,
                            endIndent: 10,
                          );
                        }
                      }) +
                      [
                        const Divider(
                          key: ValueKey('divider_-1'),
                          thickness: 0.5,
                          height: 1,
                          indent: 10,
                          endIndent: 10,
                        )
                      ],
                ),
              ])))),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              IconButton(
                tooltip: "刷新",
                icon: const Icon(Icons.refresh),
                onPressed: updateConfigAndRefresh,
              ),
              IconButton(
                icon: const Icon(Icons.exit_to_app),
                tooltip: "退出",
                onPressed: () {
                  // 关闭应用程序
                  exit(0);
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showStockInputDialog,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
