
import 'package:flutter/foundation.dart';
import '../utils/formatter.dart';

class SettingsItem {
  int id;
  String name;
  String createdAt;
  String updatedAt;
  final String localKey;

  SettingsItem({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    String? localKey,
  }) : localKey = localKey ?? UniqueKey().toString();

  factory SettingsItem.fromJson(Map<String, dynamic> json) => SettingsItem(
    id: json['id'] is int
        ? json['id']
        : int.tryParse(json['id'].toString()) ?? 0,
    name: json['name'] ?? '',
    createdAt: formatDateTime(json['created_at'] ?? ''),
    updatedAt: formatDateTime(json['updated_at'] ?? ''),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}

class SettingsSection {
  int id;
  String title;
  List<SettingsItem> items;
  bool expanded;

  SettingsSection({
    required this.id,
    required this.title,
    required this.items,
    this.expanded = true,
  });

  factory SettingsSection.fromJson(Map<String, dynamic> json) =>
      SettingsSection(
        id: json['id'] is int
            ? json['id']
            : int.tryParse(json['id'].toString()) ?? 0,
        title: json['title'] ?? '',
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => SettingsItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        expanded: json['expanded'] ?? true,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'items': items.map((e) => e.toJson()).toList(),
    'expanded': expanded,
  };
}
