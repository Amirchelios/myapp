import 'package:flutter/material.dart';
import '../models/timer_models.dart';

class DeviceCard extends StatelessWidget {
  final DeviceTimer device;
  final VoidCallback? onTap;

  const DeviceCard({
    super.key,
    required this.device,
    this.onTap,
  });

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: device.isActive ? Colors.green.withAlpha(128) : Theme.of(context).cardColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(device.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                if (device.isActive)
                  Text(
                    _formatDuration(Duration(seconds: device.seconds)),
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
