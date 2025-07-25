// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timer_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceTimer _$DeviceTimerFromJson(Map<String, dynamic> json) => DeviceTimer(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      seconds: (json['seconds'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? false,
    );

Map<String, dynamic> _$DeviceTimerToJson(DeviceTimer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': instance.type,
      'seconds': instance.seconds,
      'isActive': instance.isActive,
    };

GroupTimer _$GroupTimerFromJson(Map<String, dynamic> json) => GroupTimer(
      id: json['id'] as String,
      colorValue: (json['color'] as num).toInt(),
      seconds: (json['seconds'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? false,
    );

Map<String, dynamic> _$GroupTimerToJson(GroupTimer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'color': instance.colorValue,
      'seconds': instance.seconds,
      'isActive': instance.isActive,
    };

Price _$PriceFromJson(Map<String, dynamic> json) => Price(
      pc: (json['pc'] as num?)?.toDouble() ?? 1000,
      ps4: (json['ps4'] as num?)?.toDouble() ?? 1500,
      cake: (json['cake'] as num?)?.toDouble() ?? 500,
      soda: (json['soda'] as num?)?.toDouble() ?? 300,
      hype: (json['hype'] as num?)?.toDouble() ?? 700,
    );

Map<String, dynamic> _$PriceToJson(Price instance) => <String, dynamic>{
      'pc': instance.pc,
      'ps4': instance.ps4,
      'cake': instance.cake,
      'soda': instance.soda,
      'hype': instance.hype,
    };
