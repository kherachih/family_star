import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/parent.dart';
import '../models/child.dart';
import '../models/task.dart';
import '../models/star_loss.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'family_star.db';
  static const int _databaseVersion = 1;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE parents (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        passwordHash TEXT NOT NULL,
        photoUrl TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE children (
        id TEXT PRIMARY KEY,
        parentId TEXT NOT NULL,
        name TEXT NOT NULL,
        age INTEGER NOT NULL,
        photoUrl TEXT,
        totalStars INTEGER DEFAULT 0,
        objectives TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (parentId) REFERENCES parents (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        childId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        starReward INTEGER NOT NULL,
        recurrence TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        completedAt TEXT,
        validatedAt TEXT,
        rejectionReason TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (childId) REFERENCES children (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE star_losses (
        id TEXT PRIMARY KEY,
        childId TEXT NOT NULL,
        type TEXT NOT NULL,
        description TEXT NOT NULL,
        starsCost INTEGER NOT NULL,
        reason TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (childId) REFERENCES children (id)
      )
    ''');
  }

  // Parent operations
  Future<int> insertParent(Parent parent) async {
    final db = await database;
    return await db.insert('parents', parent.toMap());
  }

  Future<Parent?> getParentByEmail(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'parents',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      return Parent.fromMap(maps.first);
    }
    return null;
  }

  Future<Parent?> getParentById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'parents',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Parent.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateParent(Parent parent) async {
    final db = await database;
    return await db.update(
      'parents',
      parent.toMap(),
      where: 'id = ?',
      whereArgs: [parent.id],
    );
  }

  // Child operations
  Future<int> insertChild(Child child) async {
    final db = await database;
    final childMap = child.toMap();
    childMap['objectives'] = child.objectives.join(',');
    return await db.insert('children', childMap);
  }

  Future<List<Child>> getChildrenByParentId(String parentId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'children',
      where: 'parentId = ?',
      whereArgs: [parentId],
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) {
      final map = Map<String, dynamic>.from(maps[i]);
      map['objectives'] = (maps[i]['objectives'] as String?)?.split(',') ?? [];
      return Child.fromMap(map);
    });
  }

  Future<Child?> getChildById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'children',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      final map = Map<String, dynamic>.from(maps.first);
      map['objectives'] = (maps.first['objectives'] as String?)?.split(',') ?? [];
      return Child.fromMap(map);
    }
    return null;
  }

  Future<int> updateChild(Child child) async {
    final db = await database;
    final childMap = child.toMap();
    childMap['objectives'] = child.objectives.join(',');
    return await db.update(
      'children',
      childMap,
      where: 'id = ?',
      whereArgs: [child.id],
    );
  }

  Future<int> deleteChild(String id) async {
    final db = await database;
    return await db.delete(
      'children',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Task operations
  Future<int> insertTask(Task task) async {
    final db = await database;
    return await db.insert('tasks', task.toMap());
  }

  Future<List<Task>> getTasksByChildId(String childId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'childId = ?',
      whereArgs: [childId],
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return Task.fromMap(maps[i]);
    });
  }

  Future<List<Task>> getTodayTasksByChildId(String childId) async {
    final db = await database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'childId = ? AND createdAt >= ? AND createdAt < ?',
      whereArgs: [
        childId,
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String(),
      ],
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return Task.fromMap(maps[i]);
    });
  }

  Future<int> updateTask(Task task) async {
    final db = await database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(String id) async {
    final db = await database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Star Loss operations
  Future<int> insertStarLoss(StarLoss starLoss) async {
    final db = await database;
    return await db.insert('star_losses', starLoss.toMap());
  }

  Future<List<StarLoss>> getStarLossesByChildId(String childId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'star_losses',
      where: 'childId = ?',
      whereArgs: [childId],
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return StarLoss.fromMap(maps[i]);
    });
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}