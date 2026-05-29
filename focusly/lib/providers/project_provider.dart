// ─────────────────────────────────────────────────────────────────────────────
// Project Provider — manages project/category state
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/project_model.dart';
import '../database/database_helper.dart';

class ProjectProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  static final _uuid = Uuid();

  List<ProjectModel> _projects = [];
  bool _isLoading = false;

  List<ProjectModel> get projects => _projects;
  bool get isLoading => _isLoading;

  Future<void> loadProjects() async {
    _isLoading = true;
    notifyListeners();

    _projects = await _db.getProjects();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addProject({
    required String name,
    required int colorValue,
    required String iconName,
  }) async {
    final project = ProjectModel(
      id: _uuid.v4(),
      name: name,
      colorValue: colorValue,
      iconName: iconName,
      sortOrder: _projects.length,
      createdAt: DateTime.now(),
    );

    await _db.insertProject(project);
    await loadProjects();
  }

  Future<void> updateProject(ProjectModel project) async {
    await _db.updateProject(project);
    await loadProjects();
  }

  Future<void> deleteProject(String id) async {
    await _db.deleteProject(id);
    await loadProjects();
  }

  ProjectModel? getProjectById(String? id) {
    if (id == null) return null;
    try {
      return _projects.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
