import 'dart:async';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'timer_models.g.dart';

@JsonSerializable()
class DeviceTimer {
  final String id;
  final String name;
  final String type;
  @JsonKey(includeFromJson: false, includeToJson: false)
  Timer? timer;
  int seconds;
  bool isActive;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final IconData icon;

  DeviceTimer({
    required this.id,
    required this.name,
    required this.type,
    this.seconds = 0,
    this.isActive = false,
    this.timer,
    this.icon = Icons.desktop_windows,
  });

  factory DeviceTimer.fromJson(Map<String, dynamic> json) => _$DeviceTimerFromJson(json);
  Map<String, dynamic> toJson() => _$DeviceTimerToJson(this);
}

@JsonSerializable()
class GroupTimer {
  final String id;
  @JsonKey(includeFromJson: false, includeToJson: false)
  late final Color color;
  @JsonKey(name: 'color')
  final int colorValue;
  @JsonKey(includeFromJson: false, includeToJson: false)
  Timer? timer;
  int seconds;
  bool isActive;

  GroupTimer({
    required this.id,
    required this.colorValue,
    this.seconds = 0,
    this.isActive = false,
    this.timer,
  }) : color = Color(colorValue);

  factory GroupTimer.fromJson(Map<String, dynamic> json) => _$GroupTimerFromJson(json);
  Map<String, dynamic> toJson() => _$GroupTimerToJson(this);
}

@JsonSerializable()
class Price {
  double pc;
  double ps4;
  double cake;
  double soda;
  double hype;

  Price({
    this.pc = 1000,
    this.ps4 = 1500,
    this.cake = 500,
    this.soda = 300,
    this.hype = 700,
  });

  factory Price.fromJson(Map<String, dynamic> json) => _$PriceFromJson(json);
  Map<String, dynamic> toJson() => _$PriceToJson(this);
}
