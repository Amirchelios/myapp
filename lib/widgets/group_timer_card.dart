import 'package:flutter/material.dart';
import '../models/timer_models.dart';

class GroupTimerCard extends StatelessWidget {
  final GroupTimer group;
  final VoidCallback? onTap;

  const GroupTimerCard({
    super.key,
    required this.group,
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
        // Use color.withOpacity or color.withAlpha depending on exact need
        // Assuming withOpacity is the intended behavior based on original code
        color: group.isActive ? group.color.withAlpha((0.7 * 255).round()) : Theme.of(context).cardColor, // Use group color when active
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), // Adjusted padding
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between items
            children: [
              // Placeholder for the flag icon (you might need to add assets)
              Icon(
                Icons.flag, // Use a flag icon placeholder
                color: group.isActive ? Colors.white : group.color, // Icon color
                size: 32,
              ),
              const SizedBox(width: 16), // Spacing between icon and text
              Expanded(
                child: Text(
                  'گروه ${group.id.split(' ').last}', // Display group number
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                     color: group.isActive ? Colors.white : Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.right, // Align text to the right
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (group.isActive)
                Text(
                  _formatDuration(Duration(seconds: group.seconds)),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                     color: group.isActive ? Colors.white : Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.left, // Align time to the left
                ),
            ],
          ),
        ),
      ),
    );
  }
}
