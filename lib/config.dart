import 'dart:convert';
import 'dart:developer';

import 'entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

const configSaveKey = "FloatStockConfig";

Future<AppConfig> readConfig() async {
  try {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var s = sharedPreferences.getString(configSaveKey);
    if (s != null) {
      return AppConfig.fromJson(jsonDecode(s));
    }
  } catch (e) {
    log("read config error", error: e);
  }
  return AppConfig(
      floatConfig: FloatConfig(
          enable: false,
          opacity: 0.5,
          showColumns: [],
          frequency: 2,
          windowHeight: 0.2,
          windowWidth: 0.4,
          screenHeight: 1000,
          screenWidth: 800,
          fontSize: 20,
          fontColorType: "黑色"),
      stockList: []);
}

Future<bool> updateConfig(AppConfig appConfig) async {
  try {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setString(configSaveKey, jsonEncode(appConfig.toJson()));
    return true;
  } catch (e) {
    log("update config error", error: e);
    return false;
  }
}
