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
                    columnWidths: const {
                      0: FractionColumnWidth(0.6),
                      1: FractionColumnWidth(0.4),
                    },
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

class NormalFormGroup extends StatefulWidget {
  /// 录入项的唯一标识，主要用于录入类型页面框架中
  final String? label;

  /// 录入项类型，主要用于录入类型页面框架中
  final String type = BrnInputItemType.normalGroupType;

  /// 录入项标题
  final String title;

  /// 内部子项
  final List<Widget> children;

  /// form配置
  final BrnFormItemConfig themeData = BrnFormItemConfig();

  final ReorderCallback onReorder;

  NormalFormGroup({
    Key? key,
    this.label,
    this.title = "",
    required this.children,
    required this.onReorder,
  }) : super(key: key);

  @override
  NormalFormGroupState createState() {
    return NormalFormGroupState();
  }
}

class NormalFormGroupState extends State<NormalFormGroup> {
  @override
  void initState() {
    super.initState();
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
                    style: widget.themeData.headTitleTextStyle
                        .merge(BrnTextStyle(fontWeight: FontWeight.w600))
                        .generateTextStyle(),
                  )),
            ],
          ),
          ReorderableListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(top: 4),
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
