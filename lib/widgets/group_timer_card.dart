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

  @override
  Widget build(BuildContext context) {
    return Card(
      color: group.color.withAlpha(128),
      child: ListTile(
        title: Text('Group Timer ${group.id}'),
        subtitle: Text('Time: ${group.seconds}s'),
        onTap: onTap,
      ),
    );
  }
}
