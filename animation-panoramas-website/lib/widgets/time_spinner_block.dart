import 'package:flutter/material.dart';
import 'package:flutter_time_picker_spinner/flutter_time_picker_spinner.dart';
import 'package:time/time.dart';
import 'package:wheel_spinner/wheel_spinner.dart';

class TimeSpinnerBlock extends StatefulWidget {
  final ValueChanged<DateTime> onTime;
  final ValueChanged<int>? onDuration;
  const TimeSpinnerBlock({super.key, required this.onTime, this.onDuration});

  @override
  State<TimeSpinnerBlock> createState() => _TimeSpinnerBlockState();
}

class _TimeSpinnerBlockState extends State<TimeSpinnerBlock> {
  double _dur = 2;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(children: [
      TimePickerSpinner(
        time: DateTime.now() + 1.hours,
        is24HourMode: false,
        isForce2Digits: true,
        spacing: 30,
        itemHeight: 48,
        normalTextStyle: TextStyle(fontSize: 22, color: cs.onSurface.withOpacity(0.5)),
        highlightedTextStyle: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: cs.primary),
        onTimeChange: widget.onTime,
      ),
      const SizedBox(height: 8),
      SizedBox(
        height: 56,
        child: WheelSpinner(
          value: _dur,
          min: 1,
          max: 8,
          onSlideUpdate: (v) {
            setState(() => _dur = v);
            widget.onDuration?.call(v.round());
          },
          childBuilder: (v) => Center(child: Text('${v.round()} h', style: const TextStyle(fontWeight: FontWeight.bold))),
          theme: WheelSpinnerTheme.light(),
        ),
      ),
    ]);
  }
}
