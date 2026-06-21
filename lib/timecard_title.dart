import 'package:flutter/material.dart';

class TimecardTitle extends StatelessWidget {
  const TimecardTitle({super.key, this.child});
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: child,
      );
  }
}