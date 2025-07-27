class Contact {
  final String id;
  final String name;
  final Map<String, int> items;
  final double credit;

  Contact({
    required this.id,
    required this.name,
    this.items = const {},
    this.credit = 0.0,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as String,
      name: json['name'] as String,
      items: Map<String, int>.from(json['items'] as Map),
      credit: json['credit'] as double,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'items': items,
      'credit': credit,
    };
  }

  // Helper method to create a new Contact with updated fields
  Contact copyWith({
    String? id,
    String? name,
    Map<String, int>? items,
    double? credit,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      items: items ?? this.items,
      credit: credit ?? this.credit,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Contact &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          items == other.items &&
          credit == other.credit;

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ items.hashCode ^ credit.hashCode;
}
