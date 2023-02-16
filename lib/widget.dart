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
