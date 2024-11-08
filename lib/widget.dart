import 'dart:math';

import 'package:flutter/material.dart';

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
        Expanded(
            flex: 20,
            child: Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Text(title,
                  style: const TextStyle(
                      inherit: true,
                      color: Color(0xff222222),
                      fontSize: 16.0,
                      decoration: TextDecoration.none),
                  overflow: TextOverflow.ellipsis),
            )),
        Expanded(
          flex: 50,
          child: Slider(
            value: max(min(value, maxValue), minValue),
            divisions: 100,
            min: minValue,
            max: maxValue,
            onChanged: onChanged,
            label: label ?? '${(value * 100).round()}',
          ),
        ),
        Expanded(flex: 10, child: Text(label ?? '${(value * 100).round()}')),
      ],
    );
  }
}
