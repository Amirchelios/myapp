import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/timer_models.dart';

class TimerProvider with ChangeNotifier {
  List<DeviceTimer> _devices = [];
  List<GroupTimer> _groups = [];

  List<DeviceTimer> get devices => _devices;
  List<GroupTimer> get groups => _groups;

  TimerProvider() {
    loadTimers();
  }

  Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/timers.json');
  }

  Future<void> loadTimers() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        if (contents.isNotEmpty) {
          final Map<String, dynamic> json = jsonDecode(contents);
          _devices = (json['devices'] as List).map((e) => DeviceTimer.fromJson(e)).toList();
          _groups = (json['groups'] as List).map((e) => GroupTimer.fromJson(e)).toList();
        } else {
          _initializeTimers();
        }
      } else {
        _initializeTimers();
      }
    } catch (e) {
      _initializeTimers();
    }
    notifyListeners();
  }

  void _initializeTimers() {
    _devices = [
      ...List.generate(8, (i) => DeviceTimer(id: 'PC${i + 1}', name: 'R${i + 1}', type: 'PC', icon: Icons.desktop_windows)),
      ...List.generate(4, (i) => DeviceTimer(id: 'PS${i + 1}', name: 'PS${i + 1}', type: 'PS4', icon: Icons.gamepad)),
    ];
    _groups = [
      GroupTimer(id: 'Group 1', colorValue: 0xFFF44336), // Colors.red
      GroupTimer(id: 'Group 2', colorValue: 0xFF2196F3), // Colors.blue
      GroupTimer(id: 'Group 3', colorValue: 0xFF4CAF50), // Colors.green
      GroupTimer(id: 'Group 4', colorValue: 0xFFFFEB3B), // Colors.yellow
    ];
  }

  Future<void> saveTimers() async {
    try {
      final file = await _localFile;
      final Map<String, dynamic> json = {
        'devices': _devices.map((e) => e.toJson()).toList(),
        'groups': _groups.map((e) => e.toJson()).toList(),
      };
      await file.writeAsString(jsonEncode(json));
    } catch (e) {
      // handle error
    }
  }

  void toggleDeviceTimer(String id) {
    final device = _devices.firstWhere((d) => d.id == id);
    device.isActive = !device.isActive;
    if (device.isActive) {
      device.seconds = 0; // Reset timer on start
      device.timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        device.seconds++;
        notifyListeners();
      });
    } else {
      device.timer?.cancel();
    }
    saveTimers();
    notifyListeners();
  }

  void stopDeviceTimer(String id) {
    final device = _devices.firstWhere((d) => d.id == id);
    device.isActive = false;
    device.timer?.cancel();
    // Logic to calculate cost and show payment dialog will be added here
    device.seconds = 0;
    saveTimers();
    notifyListeners();
  }

  void toggleGroupTimer(String id) {
    final group = _groups.firstWhere((g) => g.id == id);
    group.isActive = !group.isActive;
    if (group.isActive) {
      group.seconds = 0; // Reset timer on start
      group.timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        group.seconds++;
        notifyListeners();
      });
    } else {
      group.timer?.cancel();
      // Logic to show loser selection dialog will be added here
    }
    saveTimers();
    notifyListeners();
  }
}
