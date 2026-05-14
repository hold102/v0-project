import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:splitease/models/user.dart';
import 'package:splitease/models/expense_category.dart';
import 'package:splitease/models/group.dart';
import 'package:splitease/models/expense.dart';

class LocalDbService {
  static final LocalDbService _instance = LocalDbService._();
  factory LocalDbService() => _instance;
  LocalDbService._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      join(dbPath, 'splitease.db'),
      version: 1,
      onCreate: _onCreate,
    );
    return _db!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY, name TEXT NOT NULL, avatar TEXT NOT NULL, email TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE groups_table (
        id TEXT PRIMARY KEY, name TEXT NOT NULL, emoji TEXT NOT NULL, created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE group_members (
        group_id TEXT NOT NULL, user_id TEXT NOT NULL,
        PRIMARY KEY (group_id, user_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY, description TEXT NOT NULL, amount REAL NOT NULL,
        paid_by TEXT NOT NULL, category TEXT NOT NULL, date TEXT NOT NULL,
        group_id TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE expense_splits (
        expense_id TEXT NOT NULL, user_id TEXT NOT NULL,
        PRIMARY KEY (expense_id, user_id)
      )
    ''');
  }

  Future<void> insertUser(User user) async {
    final db = await database;
    await db.insert('users', user.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertUsers(List<User> users) async {
    final db = await database;
    final batch = db.batch();
    for (final u in users) {
      batch.insert('users', u.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<User>> getAllUsers() async {
    final db = await database;
    final rows = await db.query('users');
    return rows.map((r) => User.fromJson(r)).toList();
  }

  Future<void> insertGroup(Group group) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert(
        'groups_table',
        {
          'id': group.id,
          'name': group.name,
          'emoji': group.emoji,
          'created_at': group.createdAt,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      for (final m in group.members) {
        await txn.insert(
          'group_members',
          {'group_id': group.id, 'user_id': m.id},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final e in group.expenses) {
        await txn.insert(
          'expenses',
          {
            'id': e.id,
            'description': e.description,
            'amount': e.amount,
            'paid_by': e.paidBy,
            'category': e.category.name,
            'date': e.date,
            'group_id': e.groupId,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        for (final uid in e.splitBetween) {
          await txn.insert(
            'expense_splits',
            {'expense_id': e.id, 'user_id': uid},
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });
  }

  Future<List<Group>> getAllGroups() async {
    final db = await database;
    final groupRows =
        await db.query('groups_table', orderBy: 'created_at DESC');
    final result = <Group>[];
    for (final gRow in groupRows) {
      final gId = gRow['id'] as String;
      final memberRows = await db.rawQuery(
          'SELECT u.* FROM users u JOIN group_members gm ON gm.user_id = u.id WHERE gm.group_id = ?',
          [gId]);
      final members = memberRows.map((r) => User.fromJson(r)).toList();

      final expRows =
          await db.query('expenses', where: 'group_id = ?', whereArgs: [gId]);
      final expenses = <Expense>[];
      for (final eRow in expRows) {
        final splitRows = await db.query('expense_splits',
            where: 'expense_id = ?', whereArgs: [eRow['id'] as String]);
        expenses.add(Expense(
          id: eRow['id'] as String,
          description: eRow['description'] as String,
          amount: (eRow['amount'] as num).toDouble(),
          paidBy: eRow['paid_by'] as String,
          splitBetween: splitRows.map((s) => s['user_id'] as String).toList(),
          category: ExpenseCategory.values.firstWhere(
              (c) => c.name == eRow['category'],
              orElse: () => ExpenseCategory.other),
          date: eRow['date'] as String,
          groupId: eRow['group_id'] as String,
        ));
      }
      result.add(Group(
        id: gId,
        name: gRow['name'] as String,
        emoji: gRow['emoji'] as String,
        createdAt: gRow['created_at'] as String,
        members: members,
        expenses: expenses,
      ));
    }
    return result;
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('expense_splits');
    await db.delete('expenses');
    await db.delete('group_members');
    await db.delete('groups_table');
    await db.delete('users');
  }
}
