import 'package:flutter/material.dart';
import '../models/timer_models.dart';

class GroupTimerCard extends StatelessWidget {
  final GroupTimer group;
  final VoidCallback onTap;

  const GroupTimerCard({super.key, required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: group.isActive ? group.color.withOpacity(0.5) : group.color,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Text(
            group.isActive
                ? '${(group.seconds ~/ 60).toString().padLeft(2, '0')}:${(group.seconds % 60).toString().padLeft(2, '0')}'
                : '',
            style: const TextStyle(fontSize: 24, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
