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
        showToast("请配置悬浮窗权限");
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
      showToast("${stock.name}已经在列表中了");
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
      showToast("操作失败");
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
    int? selectedIndex;

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
      if (isConfirm) {
        selectedIndex = 0;
      }
    } else {
      var conditions = stockList.map((e) => e.name).toList().cast<String>();
      int? currentIndex;

      await showDialog(
        context: context,
        builder: (_) => StatefulBuilder(
          builder: (context, state) {
            return SimpleDialog(
              title: const Text('请选择股票'),
              children: [
                ...conditions.asMap().entries.map((entry) {
                  return RadioListTile(
                    title: Text(entry.value),
                    value: entry.key,
                    groupValue: currentIndex,
                    onChanged: (int? value) {
                      state(() {
                        currentIndex = value!;
                      });
                    },
                  );
                }).toList(),
                const Divider(), // 添加分隔线以区分选项和按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, null); // 取消选择，返回 null
                      },
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () {
                        selectedIndex = currentIndex;
                        Navigator.pop(context, selectedIndex); // 确定选择，返回选中的索引
                      },
                      child: const Text('确定'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
    }

    return selectedIndex != null ? stockList[selectedIndex!] : null;
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
                  showToast("没找到");
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
        child: Column(
          children: [
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
            Expanded(
              child: ReorderableListView(
                onReorder: (int oldIndex, int newIndex) {
                  oldIndex = oldIndex ~/ 2;
                  newIndex = newIndex ~/ 2;
                  debugPrint(
                      "index $oldIndex $newIndex ${config.stockList[oldIndex].name}");
                  setStateAndSave(() {
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    // 移动元素并更新列表
                    var movedItem = config.stockList.removeAt(oldIndex);
                    config.stockList.insert(newIndex, movedItem);
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
                                setStateAndSave(() {
                                  stock.showInFloat = value;
                                });
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
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 26.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              SizedBox(
                width: 80.0,
                child: IconButton(
                  iconSize: 30.0,
                  tooltip: "刷新",
                  icon: const Icon(Icons.refresh),
                  onPressed: updateConfigAndRefresh,
                ),
              ),
              SizedBox(
                width: 80.0,
                child: IconButton(
                  iconSize: 30.0,
                  icon: const Icon(Icons.close),
                  tooltip: "退出",
                  onPressed: () {
                    // 关闭应用程序
                    exit(0);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showStockInputDialog,
        tooltip: "添加",
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
