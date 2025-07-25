// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Contact _$ContactFromJson(Map<String, dynamic> json) => Contact(
      id: json['id'] as String,
      name: json['name'] as String,
      debt: (json['debt'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toDouble()),
          ) ??
          const {},
      credit: (json['credit'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$ContactToJson(Contact instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'debt': instance.debt,
      'credit': instance.credit,
    };
