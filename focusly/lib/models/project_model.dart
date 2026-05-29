// ─────────────────────────────────────────────────────────────────────────────
// Project Model — color-coded categories for tasks
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

class ProjectModel {
  final String id;
  String name;
  int colorValue;   // ARGB int
  String iconName;  // icon identifier
  int sortOrder;
  DateTime createdAt;
  int taskCount;    // populated when loading

  ProjectModel({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.iconName,
    this.sortOrder = 0,
    required this.createdAt,
    this.taskCount = 0,
  });

  Color get color => Color(colorValue);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': colorValue,
      'icon_name': iconName,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ProjectModel.fromMap(Map<String, dynamic> map) {
    return ProjectModel(
      id: map['id'] as String,
      name: map['name'] as String,
      colorValue: map['color'] as int,
      iconName: map['icon_name'] as String? ?? 'folder',
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  ProjectModel copyWith({
    String? name,
    int? colorValue,
    String? iconName,
    int? sortOrder,
    int? taskCount,
  }) {
    return ProjectModel(
      id: id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      iconName: iconName ?? this.iconName,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      taskCount: taskCount ?? this.taskCount,
    );
  }
}

/// Predefined icons for projects
class ProjectIcons {
  static const Map<String, IconData> icons = {
    'work': Icons.work_outline,
    'home': Icons.home_outlined,
    'school': Icons.school_outlined,
    'fitness_center': Icons.fitness_center,
    'favorite': Icons.favorite_border,
    'shopping_cart': Icons.shopping_cart_outlined,
    'travel_explore': Icons.travel_explore,
    'code': Icons.code,
    'brush': Icons.brush_outlined,
    'local_hospital': Icons.local_hospital_outlined,
    'attach_money': Icons.attach_money,
    'folder': Icons.folder_outlined,
  };

  static IconData getIcon(String name) {
    return icons[name] ?? Icons.folder_outlined;
  }
}

/// Predefined colors for projects
class ProjectColors {
  static const List<int> colorValues = [
    0xFF7C3AED, // Purple
    0xFF2563EB, // Blue
    0xFF059669, // Emerald
    0xFFDC2626, // Red
    0xFFD97706, // Amber
    0xFFDB2777, // Pink
    0xFF0891B2, // Cyan
    0xFF65A30D, // Lime
    0xFF9333EA, // Fuchsia
    0xFF0D9488, // Teal
  ];
}
