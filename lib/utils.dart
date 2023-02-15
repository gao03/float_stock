import 'package:bruno/bruno.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
