import 'dart:math';

import 'package:bruno/bruno.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

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
      this.maxValue = 0.5});

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
            max:maxValue,
            onChanged: onChanged,
            label: label ?? '${(value * 100).round()}%',
          ),
        ),
      ],
    );
  }
}
