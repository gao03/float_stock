import 'package:bruno/bruno.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'entity.dart';

void showLoadingDialog(BuildContext context, String message) {
  BrnLoadingDialog.show(context, content: message);
}

void closeLoadingDialog(BuildContext context) {
  BrnLoadingDialog.dismiss(context);
}

void showToast(
  BuildContext context,
  String text,
) {
  if (context.mounted) {
    BrnToast.show(text, context);
  }
}

Future<bool> showConfirmDialog(
  BuildContext context,
  String message, {
  String cancel = '取消',
  String confirm = '确定',
}) async {
  bool isConfirm = false;
  await showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      return BrnDialog(
        actionsText: [cancel, confirm],
        messageText: message,
        indexedActionCallback: (index) {
          Navigator.pop(context);
          isConfirm = (index == 1);
        },
      );
    },
  );
  return isConfirm;
}

enum MarketStatus {
  open,
  close,
  pre, // 盘前/盘前集合竞价
  post, // 盘后/盘后集合竞价
}

extension Now on DateTime {
  static DateTime? _customTime;

  static DateTime get n {
    return _customTime ?? DateTime.now();
  }

  static set customTime(DateTime customTime) {
    _customTime = customTime;
  }

  static void clearCustomTime() {
    _customTime = null;
  }
}

extension DateTimeExtension on DateTime {
  int get weekOfMonth {
    var date = this;
    final firstDayOfTheMonth = DateTime(date.year, date.month, 1);
    int sum = firstDayOfTheMonth.weekday - 1 + date.day;
    if (sum % 7 == 0) {
      return sum ~/ 7;
    } else {
      return sum ~/ 7 + 1;
    }
  }
}

// 判断是否开盘的左右偏移量，比如9:30-11:30开市，9:27-11:33 都算开市
int _globalTimeOffset = 3;

MarketStatus checkMarketStatus(String type) {
  var checkFuncMap = {
    "gb_": checkUsMarketStatus,
    "sz": checkDaMarketStatus,
    "sh": checkDaMarketStatus,
    "rt_hk": checkHkMarketStatus
  };
  var func = checkFuncMap[type];
  return func == null ? MarketStatus.open : func();
}

MarketStatus checkDaMarketStatus() {
  // 09:15 - 09:30 集合竞价; 09:30之后就是开市，所以endWithOffset: false
  if (checkNowBetween(9, 15, 9, 29, endWithOffset: false)) {
    return MarketStatus.pre;
  }

  // 14:57-15:00 集合竞价；14:57之前就是开市，所以startWithOffset: false
  if (checkNowBetween(14, 57, 15, 00, startWithOffset: false)) {
    return MarketStatus.post;
  }

  // 09：30 - 11：30, 13:00-14:57 开市
  // 开始之前的集合竞价时间段不算在offset
  if (checkNowBetween(9, 30, 11, 30, startWithOffset: false) || checkNowBetween(13, 00, 14, 57, endWithOffset: false)) {
    return MarketStatus.open;
  }

  return MarketStatus.close;
}

MarketStatus checkHkMarketStatus() {
  // https://www.futuhk.com/cn/support/topic294
  // 09:00-09:30 都算集合竞价
  if (checkNowBetween(9, 0, 9, 29, endWithOffset: false)) {
    return MarketStatus.pre;
  }
  // 09:30 - 12:00, 13:00-16:00 开市
  // 开始之前的集合竞价时间段不算在offset
  if (checkNowBetween(9, 30, 12, 0, startWithOffset: false) || checkNowBetween(13, 00, 16, 00, endWithOffset: false)) {
    return MarketStatus.open;
  }
  // 16:00-16:10 都是集合竞价
  if (checkNowBetween(16, 0, 16, 10, startWithOffset: false)) {
    return MarketStatus.post;
  }

  return MarketStatus.close;
}

MarketStatus checkUsMarketStatus() {
  // https://www.futuhk.com/cn/support/topic135?lang=zh-cn
  // 冬令时要晚1个小时
  int offset = isWinterTime(Now.n) ? -60 : 0;
  int now = Now.n.hour * 60 + Now.n.minute + offset;
  int openStartMinute = 21 * 60 + 30;
  int openEndMinute = 4 * 60;

  // 21:30～4:00 开市
  if (now >= openStartMinute) {
    return MarketStatus.open;
  }
  if (now <= openEndMinute) {
    return MarketStatus.open;
  }

  // 盘后 04:00-8:00
  if (checkNowBetween(4, 0, 8, 0, offset: offset)) {
    return MarketStatus.post;
  }

  // 盘前 16:00-20:00
  if (checkNowBetween(16, 0, 21, 30, offset: offset)) {
    return MarketStatus.pre;
  }
  // 暂时不考虑其他情况

  return MarketStatus.close;
}

bool checkNowBetween(int startHour, int startMinute, int endHour, int endMinute,
    {int offset = 0, bool startWithOffset = true, bool endWithOffset = true}) {
  int now = Now.n.hour * 60 + Now.n.minute + offset;

  return now + (startWithOffset ? _globalTimeOffset : 0) >= startHour * 60 + startMinute &&
      now - (endWithOffset ? _globalTimeOffset : 0) <= endHour * 60 + endMinute;
}

// 夏令时为每年3月的第二个星期日开始，到11月第一个星期日结束，
bool isWinterTime(DateTime dt) {
  var weekOfMonth = dt.weekOfMonth;
  var month = dt.month;

  if (month < 3 || month > 10) {
    return true;
  }

  if (month == 3 && weekOfMonth <= 2) {
    return true;
  }
  if (month == 11 && weekOfMonth == 1) {
    return true;
  }
  return false;
}



double? getShowDiff(StockInfo stock) {
  return null;
}

String formatNum(double? num) {
  if (num == null) {
    return '-';
  }

  // 有些情况下，数据是有3位小数的，这种时候要保留3位
  var ln = num.toStringAsFixed(3);
  if (ln[ln.length - 1] != '0') {
    return ln;
  }

  return num.toStringAsFixed(2);
}
