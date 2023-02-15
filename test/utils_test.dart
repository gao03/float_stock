import 'package:float_stock/utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    Now.clearCustomTime();
  });
  group('A股', () {
    var testList = {
      "2023-02-15 08:00:00": MarketStatus.close, // 未开盘-前
      "2023-02-15 09:15:00": MarketStatus.pre, // 早上集合竞价
      "2023-02-15 09:27:00": MarketStatus.pre, // 早上开盘
      "2023-02-15 09:30:00": MarketStatus.open, // 早上开盘
      "2023-02-15 11:32:00": MarketStatus.open, // 早上开盘-缓冲期
      "2023-02-15 11:58:00": MarketStatus.close, // 早上收盘
      "2023-02-15 12:35:00": MarketStatus.close, // 早上收盘
      "2023-02-15 12:58:00": MarketStatus.open, // 下午开盘-缓冲期
      "2023-02-15 13:45:00": MarketStatus.open, // 下午开盘
      "2023-02-15 14:56:00": MarketStatus.open, // 下午开盘-集合竞价前
      "2023-02-15 14:57:00": MarketStatus.post, // 下午开盘-集合竞价1
      "2023-02-15 14:58:00": MarketStatus.post, // 下午开盘-集合竞价2
      "2023-02-15 15:01:00": MarketStatus.post, // 下午开盘-后缓冲期
      "2023-02-15 16:01:00": MarketStatus.close, // 下午收盘
    };
    testList.forEach((mockTime, expected) {
      test("DA $mockTime -> $expected", () {
        Now.customTime = DateTime.parse(mockTime);
        expect(checkDaMarketStatus(), expected);
      });
    });
  });
  group('港股', () {
    var testList = {
      "2023-02-15 08:00:00": MarketStatus.close, // 未开盘-前
      "2023-02-15 09:15:00": MarketStatus.pre, // 早上集合竞价
      "2023-02-15 09:27:00": MarketStatus.pre, // 早上集合竞价
      "2023-02-15 09:30:00": MarketStatus.open, // 早上开盘
      "2023-02-15 11:32:00": MarketStatus.open, // 早上开盘
      "2023-02-15 11:58:00": MarketStatus.open, // 早上开盘
      "2023-02-15 12:02:00": MarketStatus.open, // 早上开盘-缓冲期
      "2023-02-15 12:35:00": MarketStatus.close, // 早上收盘
      "2023-02-15 12:58:00": MarketStatus.open, // 下午开盘-缓冲期
      "2023-02-15 13:45:00": MarketStatus.open, // 下午开盘
      "2023-02-15 14:58:00": MarketStatus.open, // 下午开盘
      "2023-02-15 15:01:00": MarketStatus.open, // 下午开盘
      "2023-02-15 16:01:00": MarketStatus.post, // 下午收盘-集合竞价1
      "2023-02-15 16:10:00": MarketStatus.post, // 下午收盘-集合竞价2
      "2023-02-15 16:13:00": MarketStatus.post, // 下午收盘-后缓冲期
      "2023-02-15 16:16:00": MarketStatus.close, // 下午收盘
      "2023-02-15 17:16:00": MarketStatus.close, // 下午收盘
    };
    testList.forEach((mockTime, expected) {
      test("HK $mockTime -> $expected", () {
        Now.customTime = DateTime.parse(mockTime);
        expect(checkHkMarketStatus(), expected);
      });
    });
  });

  group('美股', () {
    var testList = {
      // 冬令时
      "2023-02-15 00:00:00": MarketStatus.open, // 开盘
      "2023-02-15 03:00:00": MarketStatus.open, // 开盘
      "2023-02-15 04:15:00": MarketStatus.open, // 开盘
      "2023-02-15 05:02:00": MarketStatus.post, // 盘后
      "2023-02-15 08:50:00": MarketStatus.post, // 盘后
      "2023-02-15 09:03:00": MarketStatus.post, // 盘后缓冲期
      "2023-02-15 09:04:00": MarketStatus.close, // 收盘
      "2023-02-15 11:58:00": MarketStatus.close, // 收盘
      "2023-02-15 16:30:00": MarketStatus.close, // 收盘
      "2023-02-15 16:57:00": MarketStatus.pre, // 盘前-缓冲期
      "2023-02-15 17:35:00": MarketStatus.pre, // 盘前
      "2023-02-15 21:28:00": MarketStatus.pre, // 盘前
      "2023-02-15 21:30:00": MarketStatus.pre, // 盘前
      "2023-02-15 22:27:00": MarketStatus.pre, // 盘前
      "2023-02-15 22:30:00": MarketStatus.open, // 开盘
      "2023-02-15 22:55:00": MarketStatus.open, // 下午开盘
      "2023-02-15 23:44:00": MarketStatus.open, // 下午开盘

      // 夏令时
      "2023-03-15 00:00:00": MarketStatus.open, // 开盘
      "2023-03-15 03:00:00": MarketStatus.open, // 开盘
      "2023-03-15 04:15:00": MarketStatus.post, // 开盘
      "2023-03-15 05:02:00": MarketStatus.post, // 盘后
      "2023-03-15 08:50:00": MarketStatus.close, // 盘后
      "2023-03-15 09:03:00": MarketStatus.close, // 盘后缓冲期
      "2023-03-15 09:04:00": MarketStatus.close, // 收盘
      "2023-03-15 11:58:00": MarketStatus.close, // 收盘
      "2023-03-15 16:30:00": MarketStatus.pre, // 收盘
      "2023-03-15 16:57:00": MarketStatus.pre, // 盘前-缓冲期
      "2023-03-15 17:35:00": MarketStatus.pre, // 盘前
      "2023-03-15 21:28:00": MarketStatus.pre, // 盘前
      "2023-03-15 21:30:00": MarketStatus.open, // 盘前
      "2023-03-15 22:27:00": MarketStatus.open, // 盘前
      "2023-03-15 22:30:00": MarketStatus.open, // 开盘
      "2023-03-15 22:55:00": MarketStatus.open, // 下午开盘
      "2023-03-15 23:44:00": MarketStatus.open, // 下午开盘
    };
    testList.forEach((mockTime, expected) {
      test("US $mockTime -> $expected", () {
        Now.customTime = DateTime.parse(mockTime);
        expect(checkUsMarketStatus(), expected);
      });
    });
  });
}
