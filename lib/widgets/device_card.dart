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
    return '${duration.inMinutes} دقیقه';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: device.isActive ? Colors.green.shade700 : Theme.of(context).cardColor,
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: FittedBox(
            fit: BoxFit.contain,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  device.icon,
                  size: 48,
                  color: device.isActive ? Colors.white : Theme.of(context).colorScheme.onSurface,
                ),
                const SizedBox(height: 4),
                Text(
                  device.name,
                  style: TextStyle(
                    color: device.isActive ? Colors.white : Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (device.isActive)
                  Text(
                    _formatDuration(Duration(seconds: device.seconds)),
                    style: TextStyle(
                      color: device.isActive ? Colors.white : Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
