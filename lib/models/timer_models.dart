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
  double game;

  Price({
    this.pc = 850,
    this.ps4 = 850,
    this.cake = 20000,
    this.soda = 20000,
    this.hype = 30000,
    this.game = 10000,
  });

  factory Price.fromJson(Map<String, dynamic> json) {
    final price = _$PriceFromJson(json);
    // Manually handle the 'game' field as it's not in the generated file.
    if (json.containsKey('game')) {
      price.game = (json['game'] as num).toDouble();
    } else {
      price.game = 10000; // Default value
    }
    return price;
  }

  Map<String, dynamic> toJson() {
    final json = _$PriceToJson(this);
    // Manually add the 'game' field to the json output.
    json['game'] = game;
    return json;
  }
}
