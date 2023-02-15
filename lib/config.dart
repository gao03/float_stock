import 'dart:convert';

import 'entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String ConfigSaveKey = "FloatStockConfig";

Future<AppConfig> readConfig() async {
  try {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var s = sharedPreferences.getString(ConfigSaveKey);
    if (s != null) {
      return AppConfig.fromJson(jsonDecode(s));
    }
  } catch (e) {
    print(e);
  }
  return AppConfig(
      FloatConfig(
          enable: false,
          opacity: 0.5,
          showColumns: [],
          frequency: 2,
          windowHeight: 0.2,
          windowWidth: 0.2,
          screenHeight: 1000,
          screenWidth: 800),
      []);
}

Future<bool> updateConfig(AppConfig appConfig) async {
  try {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setString(ConfigSaveKey, jsonEncode(appConfig.toJson()));
    return true;
  } catch (e) {
    print(e);
    return false;
  }
}
