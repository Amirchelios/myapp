import 'dart:async';
import 'package:flutter/material.dart';

class DeviceCard extends StatefulWidget {
  final String name;

  const DeviceCard({
    super.key,
    required this.name,
  });

  @override
  State<DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends State<DeviceCard> {
  bool _isActive = false;
  Timer? _timer;
  Duration _duration = Duration.zero;

  void _toggleTimer() {
    setState(() {
      _isActive = !_isActive;
      if (_isActive) {
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _duration += const Duration(seconds: 1);
          });
        });
      } else {
        _timer?.cancel();
        _duration = Duration.zero;
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleTimer,
      child: Card(
        color: _isActive ? Colors.green.withAlpha((255 * 0.5).round()) : Theme.of(context).cardColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                if (_isActive)
                  Text(
                    _formatDuration(_duration),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
