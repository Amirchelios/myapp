import 'dart:async';
import 'package:flutter/material.dart';

class DeviceTimer {
  final String id;
  final String name;
  final String type;
  Timer? timer;
  int seconds = 0;
  bool isActive = false;

  DeviceTimer({required this.id, required this.name, required this.type});
}

class GroupTimer {
  final String id;
  final Color color;
  Timer? timer;
  int seconds = 0;
  bool isActive = false;

  GroupTimer({required this.id, required this.color});
}
