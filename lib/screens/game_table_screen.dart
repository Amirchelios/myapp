import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/timer_provider.dart';
import '../widgets/device_card.dart';
import '../widgets/group_timer_card.dart';

class GameTableScreen extends StatelessWidget {
  const GameTableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TimerProvider>(
      builder: (context, timerProvider, child) {
        return Row(
          children: [
            Expanded(
              flex: 3,
              child: GridView.builder(
                padding: const EdgeInsets.all(16.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: 1.0,
                ),
                itemCount: timerProvider.devices.length,
                itemBuilder: (context, index) {
                  final device = timerProvider.devices[index];
                  return DeviceCard(
                    device: device,
                    onTap: () => _onDeviceTapped(context, device),
                  );
                },
              ),
            ),
            Expanded(
              flex: 1,
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: timerProvider.groups.length,
                itemBuilder: (context, index) {
                  final group = timerProvider.groups[index];
                  return GroupTimerCard(
                    group: group,
                    onTap: () => _onGroupTapped(context, group),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _onDeviceTapped(BuildContext context, DeviceTimer device) {
    // I will implement the logic for this later
  }

  void _onGroupTapped(BuildContext context, GroupTimer group) {
    // I will implement the logic for this later
  }
}
