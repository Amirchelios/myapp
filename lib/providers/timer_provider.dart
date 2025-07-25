import 'dart:async';
import 'package:flutter/material.dart';
import '../models/timer_models.dart';

class TimerProvider extends ChangeNotifier {
  final List<DeviceTimer> _devices = [
    DeviceTimer(id: 'pc1', name: 'R1', type: 'PC'),
    DeviceTimer(id: 'pc2', name: 'R2', type: 'PC'),
    DeviceTimer(id: 'pc3', name: 'R3', type: 'PC'),
    DeviceTimer(id: 'pc4', name: 'R4', type: 'PC'),
    DeviceTimer(id: 'pc5', name: 'L1', type: 'PC'),
    DeviceTimer(id: 'pc6', name: 'L2', type: 'PC'),
    DeviceTimer(id: 'pc7', name: 'L3', type: 'PC'),
    DeviceTimer(id: 'pc8', name: 'L4', type: 'PC'),
    DeviceTimer(id: 'ps1', name: 'PS1', type: 'PS4'),
    DeviceTimer(id: 'ps2', name: 'PS2', type: 'PS4'),
    DeviceTimer(id: 'ps3', name: 'PS3', type: 'PS4'),
    DeviceTimer(id: 'ps4', name: 'PS4', type: 'PS4'),
  ];

  final List<GroupTimer> _groups = [
    GroupTimer(id: 'red', color: Colors.red),
    GroupTimer(id: 'blue', color: Colors.blue),
    GroupTimer(id: 'green', color: Colors.green),
    GroupTimer(id: 'yellow', color: Colors.yellow),
  ];

  List<DeviceTimer> get devices => _devices;
  List<GroupTimer> get groups => _groups;

  bool get hasActiveTimers =>
      _devices.any((d) => d.isActive) || _groups.any((g) => g.isActive);

  void toggleDeviceTimer(String id) {
    final device = _devices.firstWhere((d) => d.id == id);
    if (device.isActive) {
      device.timer?.cancel();
      device.isActive = false;
    } else {
      device.seconds = 0;
      device.isActive = true;
      device.timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        device.seconds++;
        notifyListeners();
      });
    }
    notifyListeners();
  }

  void stopDeviceTimer(String id) {
    final device = _devices.firstWhere((d) => d.id == id);
    device.timer?.cancel();
    device.isActive = false;
    notifyListeners();
  }

  void toggleGroupTimer(String id) {
    final group = _groups.firstWhere((g) => g.id == id);
    if (group.isActive) {
      group.timer?.cancel();
      group.isActive = false;
    } else {
      group.seconds = 0;
      group.isActive = true;
      group.timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        group.seconds++;
        notifyListeners();
      });
    }
    notifyListeners();
  }

  void stopGroupTimer(String id) {
    final group = _groups.firstWhere((g) => g.id == id);
    group.timer?.cancel();
    group.isActive = false;
    notifyListeners();
  }
}
