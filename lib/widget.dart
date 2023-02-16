import 'dart:math';

import 'package:bruno/bruno.dart';
import 'package:float_stock/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'entity.dart';

class SliderWidget extends StatelessWidget {
  /// 标题
  final String title;

  /// 子标题
  final double value;

  final ValueChanged<double> onChanged;

  final String? label;

  final double minValue;
  final double maxValue;

  const SliderWidget(
      {super.key,
      required this.title,
      required this.value,
      required this.onChanged,
      this.label,
      this.minValue = 0.0,
      this.maxValue = 1});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Text(title, style: BrnFormItemConfig().titleTextStyle.generateTextStyle()),
        ),
        Expanded(
          child: Slider(
            value: max(min(value, 1.0), minValue),
            divisions: 100,
            min: minValue,
            max: maxValue,
            onChanged: onChanged,
            label: label ?? '${(value * 100).round()}',
          ),
        ),
      ],
    );
  }
}

class StockInfoWidget extends StatelessWidget {
  /// 标题
  final StockInfo stock;

  final ValueChanged<bool>? onVisibleChange;

  const StockInfoWidget({super.key, required this.stock, this.onVisibleChange});

  @override
  Widget build(BuildContext context) {
    var diff = getShowDiff(stock) ?? 0;
    var color = diff > 0
        ? Colors.red
        : diff == 0
            ? Colors.black
            : Colors.green;
    return Container(
      padding: BrnDefaultConfigUtils.defaultFormItemConfig.formPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 100,
            ),
            child: Row(children: [
              const Divider(thickness: 10),
              Expanded(
                  flex: 7,
                  child: Table(
                    children: [
                      TableRow(children: [
                        Container(
                            padding: BrnDefaultConfigUtils.defaultFormItemConfig.titlePaddingLg,
                            child: Text(
                              stock.name,
                              style: BrnDefaultConfigUtils.defaultFormItemConfig.titleTextStyle.generateTextStyle(),
                              overflow: TextOverflow.ellipsis,
                            )),
                        Container(
                            padding: BrnDefaultConfigUtils.defaultFormItemConfig.titlePaddingLg,
                            child: Text(
                              formatNum(getShowPrice(stock)),
                              style: BrnDefaultConfigUtils.defaultFormItemConfig.titleTextStyle
                                  .copyWith(color: color)
                                  .generateTextStyle(),
                              overflow: TextOverflow.ellipsis,
                            )),
                      ]),
                      TableRow(children: [
                        Container(
                            padding: BrnDefaultConfigUtils.defaultFormItemConfig.subTitlePadding,
                            child: Text(
                              stock.code,
                              style: BrnDefaultConfigUtils.defaultFormItemConfig.subTitleTextStyle.generateTextStyle(),
                              overflow: TextOverflow.ellipsis,
                            )),
                        Container(
                            padding: BrnDefaultConfigUtils.defaultFormItemConfig.titlePaddingLg,
                            child: Text(
                              '${formatNum(getShowDiff(stock))}%',
                              style: BrnDefaultConfigUtils.defaultFormItemConfig.subTitleTextStyle
                                  .copyWith(color: color)
                                  .generateTextStyle(),
                              overflow: TextOverflow.ellipsis,
                            )),
                      ]),
                    ],
                  )),
              Expanded(
                  flex: 1,
                  child: Align(
                      widthFactor: 1,
                      heightFactor: 1,
                      child: BrnSwitchButton(
                        size: const Size(42, 25),
                        value: stock.showInFloat,
                        enabled: true,
                        onChanged: (bool value) {
                          if (onVisibleChange != null) {
                            onVisibleChange!(value);
                          }
                        },
                      )))
            ]),
          ),
        ],
      ),
    );
  }
}

///
/// 可展开收起组类型录入项
/// 内部可包含其他类型Widget
///
/// 包括"标题"、"副标题"、"错误信息提示"、"必填项提示"、"添加/删除按钮"、"消息提示"
///
// ignore: must_be_immutable
class MyBrnNormalFormGroup extends StatefulWidget {
  /// 录入项的唯一标识，主要用于录入类型页面框架中
  final String? label;

  /// 录入项类型，主要用于录入类型页面框架中
  final String type = BrnInputItemType.normalGroupType;

  /// 录入项标题
  final String title;

  /// 录入项子标题
  final String? subTitle;

  /// 录入项提示（问号图标&文案） 用户点击时触发onTip回调。
  /// 1. 若赋值为 空字符串（""）时仅展示"问号"图标，
  /// 2. 若赋值为非空字符串时 展示"问号图标&文案"，
  /// 3. 若不赋值或赋值为null时 不显示提示项
  /// 默认值为 3
  final String? tipLabel;

  /// 录入项错误提示
  final String error;

  /// 录入项是否为必填项（展示*图标） 默认为 false 不必填
  final bool isRequire;

  /// 录入项 是否可编辑
  final bool isEdit;

  /// 点击"-"图标回调
  final VoidCallback? onRemoveTap;

  /// 点击"？"图标回调
  final VoidCallback? onTip;

  /// 右侧文案
  final String? deleteLabel;

  /// 内部子项
  final List<Widget> children;

  /// form配置
  BrnFormItemConfig? themeData;

  final ReorderCallback onReorder;

  MyBrnNormalFormGroup({
    Key? key,
    this.label,
    this.title = "",
    this.subTitle,
    this.tipLabel,
    this.error = "",
    this.isEdit = true,
    this.isRequire = false,
    this.onRemoveTap,
    this.onTip,
    this.deleteLabel,
    required this.children,
    required this.onReorder,
  }) : super(key: key) {
    themeData ??= BrnFormItemConfig();
    themeData = BrnThemeConfigurator.instance.getConfig(configId: themeData!.configId).formItemConfig.merge(themeData);
  }

  @override
  MyBrnNormalFormGroupState createState() {
    return MyBrnNormalFormGroupState();
  }
}

class MyBrnNormalFormGroupState extends State<MyBrnNormalFormGroup> {
  @override
  void initState() {
    super.initState();
  }

  TextStyle getHeadTitleTextStyle(BrnFormItemConfig themeData, {bool isBold = false}) {
    if (isBold) {
      return themeData.headTitleTextStyle.merge(BrnTextStyle(fontWeight: FontWeight.w600)).generateTextStyle();
    }
    return themeData.headTitleTextStyle.generateTextStyle();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 14),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Container(
                  padding: const EdgeInsets.only(left: 20, right: 6),
                  child: Text(
                    widget.title,
                    style: getHeadTitleTextStyle(widget.themeData!, isBold: true),
                  )),
            ],
          ),
          // 副标题
          Container(
            alignment: Alignment.centerLeft,
            padding: widget.themeData!.subTitlePadding,
            child: Offstage(
              offstage: (widget.subTitle == null || widget.subTitle!.isEmpty),
              child: Text(
                widget.subTitle ?? "",
                style:widget.themeData!.subTitleTextStyle.generateTextStyle(),
              ),
            ),
          ),
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onReorder: widget.onReorder,
            children: getSubItem(),
          ),
        ],
      ),
    );
  }

  List<Widget> getSubItem() {
    List<Widget> result = <Widget>[];

    for (Widget w in widget.children) {
      result.add(Column(
        key: w.key,
        children: [BrnLine(), w],
      ));
    }

    if (result.isNotEmpty) {
      result.add(const SizedBox(height: 80, key: Key("expanded")));
    }

    return result;
  }
}
