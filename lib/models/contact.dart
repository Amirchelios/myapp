import 'package:json_annotation/json_annotation.dart';

part 'contact.g.dart';

@JsonSerializable()
class Contact {
  String id;
  String name;
  Map<String, double> debt; // Changed to Map<String, double>
  double credit;

  Contact({
    required this.id,
    required this.name,
    this.debt = const {},
    this.credit = 0.0,
  });

  factory Contact.fromJson(Map<String, dynamic> json) => _$ContactFromJson(json);
  Map<String, dynamic> toJson() => _$ContactToJson(this);
}
