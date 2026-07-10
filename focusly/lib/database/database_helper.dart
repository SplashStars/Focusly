// âââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
// Database Helper â SQLite CRUD for tasks, habits, projects
// All data is stored locally on the phone. No internet needed.
// v1.1.0: DB version â 2 (adds target_days column to habits)
// âââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';
import '../models/habit_model.dart';
import '../models/project_model.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;
  static const _dbName = 'focusly.db';
  static const _dbVersion = 2; // v2: adds target_days to habits
  static final _uuid = Uuid();

  // Singleton pattern â only one database instance
  DatabaseHelper._();
  static DatabaseHelper get instance => _instance ??= DatabaseHelper._();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Migrate existing database to a newer version
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // v2: add target_days column to habits table
      // NULL = every day (backwards compatible with existing habits)
      await db.execute('ALTER TABLE habits ADD COLUMN target_days TEXT');
    }
  }

  /// Create all database tables on first launch
  Future<void> _onCreate(Database db, int version) async {
    // Projects table
    await db.execute('''
      CREATE TABLE projects (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color INTEGER NOT NULL,
        icon_name TEXT NOT NULL DEFAULT 'folder',
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // Tasks table
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        project_id TEXT,
        priority INTEGER NOT NULL DEFAULT 2,
        due_date TEXT,
        reminder_time TEXT,
        is_completed INTEGER NOT NULL DEFAULT 0,
        parent_task_id TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        completed_at TEXT,
        recurrence TEXT NOT NULL DEFAULT 'none'
      )
    ''');

    // Habits table (v2: includes target_days)
    await db.execute('''
      CREATE TABLE habits (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        color INTEGER NOT NULL,
        icon_name TEXT NOT NULL DEFAULT 'star',
        frequency TEXT NOT NULL DEFAULT 'daily',
        target_days TEXT,
        reminder_time TEXT,
        streak_count INTEGER NOT NULL DEFAULT 0,
        best_streak INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // Habit completions (one row per day a habit was done)
    await db.execute('''
      CREATE TABLE habit_completions (
        id TEXT PRIMARY KEY,
        habit_id TEXT NOT NULL,
        completed_date TEXT NOT NULL,
        FOREIGN KEY (habit_id) REFERENCES habits(id) ON DELETE CASCADE
      )
    ''');

    // Insert sample data on first launch (fixes Todoist's "empty state confusion" complaint)
    await _insertSampleData(db);
  }

  /// Sample data so new users immediately understand how the app works
  Future<void> _insertSampleData(Database db) async {
    final now = DateTime.now();

    // Sample project
    final projectId = _uuid.v4();
    await db.insert('projects', {
      'id': projectId,
      'name': 'Personal',
      'color': 0xFF7C3AED,
      'icon_name': 'favorite',
      'sort_order': 0,
      'created_at': now.toIso8601String(),
    });

    // Sample tasks
    final taskId1 = _uuid.v4();
    await db.insert('tasks', {
      'id': taskId1,
      'title': 'ð Welcome to Focusly! Tap to mark complete',
      'description': 'Swipe right to complete, swipe left to delete any task.',
      'project_id': projectId,
      'priority': 2,
      'due_date': now.toIso8601String(),
      'is_completed': 0,
      'sort_order': 1000,
      'created_at': now.toIso8601String(),
      'recurrence': 'none',
    });

    await db.insert('tasks', {
      'id': _uuid.v4(),
      'title': 'ð Add your first task using the + button',
      'project_id': projectId,
      'priority': 1,
      'due_date': now.toIso8601String(),
      'is_completed': 0,
      'sort_order': 999,
      'created_at': now.toIso8601String(),
      'recurrence': 'none',
    });

    // Sample habit
    await db.insert('habits', {
      'id': _uuid.v4(),
      'name': 'Morning Workout ðª',
      'description': 'Exercise for at least 20 minutes',
      'color': 0xFF2563EB,
      'icon_name': 'fitness_center',
      'frequency': 'daily',
      'streak_count': 3,
      'best_streak': 5,
      'sort_order': 0,
      'created_at': now.subtract(const Duration(days: 10)).toIso8601String(),
    });
  }

  // ââââââââââââââââââââââââââââ PROJECTS ââââââââââââââââââââââââââââââââââââââ

  Future<List<ProjectModel>> getProjects() async {
    final db = await database;
    final maps = await db.query('projects', orderBy: 'sort_order ASC, created_at ASC');
    final projects = maps.map(ProjectModel.fromMap).toList();

    // Count tasks per project
    for (final project in projects) {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM tasks WHERE project_id = ? AND is_completed = 0',
        [project.id],
      );
      project.taskCount = (result.first['count'] as int?) ?? 0;
    }

    return projects;
  }

  Future<void> insertProject(ProjectModel project) async {
    final db = await database;
    await db.insert('projects', project.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateProject(ProjectModel project) async {
    final db = await database;
    await db.update('projects', project.toMap(), where: 'id = ?', whereArgs: [project.id]);
  }

  Future<void> deleteProject(String id) async {
    final db = await database;
    // Unlink tasks from deleted project
    await db.update('tasks', {'project_id': null}, where: 'project_id = ?', whereArgs: [id]);
    await db.delete('projects', where: 'id = ?', whereArgs: [id]);
  }

  // ââââââââââââââââââââââââââââ TASKS âââââââââââââââââââââââââââââââââââââââââ

  /// Get all tasks (top-level only) with their subtasks attached
  Future<List<TaskModel>> getTasks({
    String? projectId,
    bool includeCompleted = false,
  }) async {
    final db = await database;

    String where = 'parent_task_id IS NULL';
    List<dynamic> whereArgs = [];

    if (projectId != null) {
      where += ' AND project_id = ?';
      whereArgs.add(projectId);
    }

    if (!includeCompleted) {
      where += ' AND is_completed = 0';
    }

    final maps = await db.query(
      'tasks',
      where: where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'sort_order DESC, created_at DESC', // Newest tasks at TOP (fixes Todoist complaint)
    );

    final tasks = maps.map(TaskModel.fromMap).toList();

    // Load subtasks for each task
    for (final task in tasks) {
      task.subtasks = await _getSubtasks(task.id);
    }

    return tasks;
  }

  /// Get tasks due today (for the Home screen)
  Future<List<TaskModel>> getTodayTasks() async {
    final db = await database;
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final maps = await db.rawQuery('''
      SELECT * FROM tasks
      WHERE parent_task_id IS NULL
        AND is_completed = 0
        AND (
          due_date LIKE '$todayStr%'
          OR due_date < '${today.toIso8601String()}'
        )
      ORDER BY priority ASC, sort_order DESC
    ''');

    final tasks = maps.map(TaskModel.fromMap).toList();
    for (final task in tasks) {
      task.subtasks = await _getSubtasks(task.id);
    }
    return tasks;
  }

  Future<List<TaskModel>> _getSubtasks(String parentId) async {
    final db = await database;
    final maps = await db.query(
      'tasks',
      where: 'parent_task_id = ?',
      whereArgs: [parentId],
      orderBy: 'sort_order DESC, created_at DESC',
    );
    return maps.map(TaskModel.fromMap).toList();
  }

  Future<void> insertTask(TaskModel task) async {
    final db = await database;
    await db.insert('tasks', task.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateTask(TaskModel task) async {
    final db = await database;
    await db.update('tasks', task.toMap(), where: 'id = ?', whereArgs: [task.id]);
  }

  Future<void> deleteTask(String id) async {
    final db = await database;
    // Delete subtasks first
    await db.delete('tasks', where: 'parent_task_id = ?', whereArgs: [id]);
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> completeTask(String id) async {
    final db = await database;
    await db.update(
      'tasks',
      {
        'is_completed': 1,
        'completed_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ââââââââââââââââââââââââââââ HABITS ââââââââââââââââââââââââââââââââââââââââ

  Future<List<HabitModel>> getHabits() async {
    final db = await database;
    final maps = await db.query('habits', orderBy: 'sort_order ASC, created_at ASC');
    final habits = maps.map(HabitModel.fromMap).toList();

    // Load completions for each habit (last 60 days)
    for (final habit in habits) {
      habit.completedDates = await _getHabitCompletions(habit.id);
    }

    return habits;
  }

  Future<List<DateTime>> _getHabitCompletions(String habitId) async {
    final db = await database;
    final cutoff = DateTime.now().subtract(const Duration(days: 60));
    final maps = await db.query(
      'habit_completions',
      where: 'habit_id = ? AND completed_date > ?',
      whereArgs: [habitId, cutoff.toIso8601String()],
      orderBy: 'completed_date DESC',
    );
    return maps.map((m) => DateTime.parse(m['completed_date'] as String)).toList();
  }

  Future<void> insertHabit(HabitModel habit) async {
    final db = await database;
    await db.insert('habits', habit.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateHabit(HabitModel habit) async {
    final db = await database;
    await db.update('habits', habit.toMap(), where: 'id = ?', whereArgs: [habit.id]);
  }

  Future<void> deleteHabit(String id) async {
    final db = await database;
    await db.delete('habit_completions', where: 'habit_id = ?', whereArgs: [id]);
    await db.delete('habits', where: 'id = ?', whereArgs: [id]);
  }

  /// Toggle today's completion for a habit
  Future<bool> toggleHabitCompletion(String habitId) async {
    final db = await database;
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // Check if already completed today
    final existing = await db.query(
      'habit_completions',
      where: "habit_id = ? AND completed_date LIKE '$todayStr%'",
      whereArgs: [habitId],
    );

    if (existing.isNotEmpty) {
      // Un-complete
      await db.delete(
        'habit_completions',
        where: "habit_id = ? AND completed_date LIKE '$todayStr%'",
        whereArgs: [habitId],
      );
      await _recalculateStreak(habitId);
      return false;
    } else {
      // Complete
      await db.insert('habit_completions', {
        'id': _uuid.v4(),
        'habit_id': habitId,
        'completed_date': now.toIso8601String(),
      });
      await _recalculateStreak(habitId);
      return true;
    }
  }

  /// Recalculate streak count after a completion toggle
  Future<void> _recalculateStreak(String habitId) async {
    final db = await database;
    final completions = await _getHabitCompletions(habitId);
    final completedDays = completions.map((d) => DateTime(d.year, d.month, d.day)).toSet();

    int streak = 0;
    DateTime day = DateTime.now();

    while (completedDays.contains(DateTime(day.year, day.month, day.day))) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }

    // Also check best streak
    final existing = await db.query('habits', where: 'id = ?', whereArgs: [habitId]);
    final currentBest = (existing.first['best_streak'] as int?) ?? 0;

    await db.update(
      'habits',
      {
        'streak_count': streak,
        'best_streak': streak > currentBest ? streak : currentBest,
      },
      where: 'id = ?',
      whereArgs: [habitId],
    );
  }
}
