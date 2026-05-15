/*
 * local_db_service.dart — SQLite offline cache
 *
 * When the API is reachable, fetched data is cached here so the app still
 * shows the last known state on the next launch even without network.
 * Uses the sqflite package. Tables mirror the API's data model:
 * users, groups_table, group_members, expenses, expense_splits,
 * expense_split_amounts.
 */
import 'package:flutter/foundation.dart' show kIsWeb;
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

  // sqflite is not supported on web — all methods no-op when running in a browser
  bool get _isSupported => !kIsWeb;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      join(dbPath, 'splitease.db'),
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _db!;
  }

  // Create all tables on first run
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY, name TEXT NOT NULL, avatar TEXT NOT NULL, email TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE groups_table (
        id TEXT PRIMARY KEY, name TEXT NOT NULL, emoji TEXT NOT NULL,
        description TEXT, created_at TEXT NOT NULL
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
    await _createSplitAmountsTable(db);
  }

  // Migrate an existing v1 database to v2 by adding the split-amounts table.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createSplitAmountsTable(db);
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE groups_table ADD COLUMN description TEXT');
    }
  }

  // Extracted so both onCreate and onUpgrade can call it without duplication.
  Future<void> _createSplitAmountsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS expense_split_amounts (
        expense_id TEXT NOT NULL,
        user_id    TEXT NOT NULL,
        amount     REAL NOT NULL,
        PRIMARY KEY (expense_id, user_id)
      )
    ''');
  }

  Future<void> insertUser(User user) async {
    if (!_isSupported) return;
    final db = await database;
    await db.insert('users', user.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertUsers(List<User> users) async {
    if (!_isSupported) return;
    final db = await database;
    final batch = db.batch();
    for (final u in users) {
      batch.insert('users', u.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<User>> getAllUsers() async {
    if (!_isSupported) return [];
    final db = await database;
    final rows = await db.query('users');
    return rows.map((r) => User.fromJson(r)).toList();
  }

  // Insert a group with all related data (members, expenses, splits) in a single transaction
  Future<void> insertGroup(Group group) async {
    if (!_isSupported) return;
    final db = await database;
    await db.transaction((txn) async {  // All-or-nothing: if any insert fails, everything rolls back
      await txn.insert(
        'groups_table',
        {
          'id': group.id,
          'name': group.name,
          'emoji': group.emoji,
          'description': group.description,
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
        // Persist custom per-user amounts when present (null = equal split).
        if (e.splitAmounts != null) {
          e.splitAmounts!.forEach((uid, amount) async {
            await txn.insert(
              'expense_split_amounts',
              {'expense_id': e.id, 'user_id': uid, 'amount': amount},
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          });
        }
      }
    });
  }

  Future<List<Group>> getAllGroups() async {
    if (!_isSupported) return [];
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
        final expenseId = eRow['id'] as String;
        final splitRows = await db.query('expense_splits',
            where: 'expense_id = ?', whereArgs: [expenseId]);
        final amountRows = await db.query('expense_split_amounts',
            where: 'expense_id = ?', whereArgs: [expenseId]);
        // Restore custom split amounts when present; null means equal split.
        final Map<String, double>? splitAmounts = amountRows.isEmpty
            ? null
            : {
                for (final r in amountRows)
                  r['user_id'] as String: (r['amount'] as num).toDouble(),
              };
        expenses.add(Expense(
          id: expenseId,
          description: eRow['description'] as String,
          amount: (eRow['amount'] as num).toDouble(),
          paidBy: eRow['paid_by'] as String,
          splitBetween: splitRows.map((s) => s['user_id'] as String).toList(),
          splitAmounts: splitAmounts,
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
        description: (gRow['description'] as String?) ?? '',
        createdAt: gRow['created_at'] as String,
        members: members,
        expenses: expenses,
      ));
    }
    return result;
  }

  // Wipe all cached data before re-caching fresh data from the API
  Future<void> clearAll() async {
    if (!_isSupported) return;
    final db = await database;
    // Delete child tables first to avoid foreign-key issues (if FK enforcement is enabled)
    await db.delete('expense_split_amounts');
    await db.delete('expense_splits');
    await db.delete('expenses');
    await db.delete('group_members');
    await db.delete('groups_table');
    await db.delete('users');
  }
}
