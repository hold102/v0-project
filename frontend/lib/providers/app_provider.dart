/*
 * app_provider.dart — Central state management (ChangeNotifier)
 *
 * This is the "brain" of the app. It holds:
 *   - The current user and auth state
 *   - All groups and users
 *   - Business logic: CRUD operations, balance calculations, totals
 *
 * Data loading strategy (loadData):
 *   1. Try the backend API — if it returns data, use it and cache to SQLite
 *   2. If API fails, try the local SQLite cache
 *   3. If both fail, fall back to hardcoded mock data (createMockGroups)
 *
 * Mutations are optimistic: the UI updates immediately, then the API call
 * fires in the background (fire-and-forget). The local SQLite cache is
 * updated after every change.
 */
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:splitease/models/expense_category.dart';
import 'package:splitease/models/user.dart';
import 'package:splitease/models/group.dart';
import 'package:splitease/models/expense.dart';
import 'package:splitease/models/balance.dart';
import 'package:splitease/services/api_service.dart';
import 'package:splitease/services/local_db_service.dart';

// Hardcoded fallback users — shown only when both API and local DB are unavailable
const mockUsers = [
  User(id: 'u1', name: 'Me', avatar: '👤', email: 'me@example.com'),
  User(id: 'u2', name: 'Alex', avatar: '😎', email: 'ming@example.com'),
  User(id: 'u3', name: 'Bella', avatar: '😊', email: 'hong@example.com'),
  User(id: 'u4', name: 'Chris', avatar: '🤓', email: 'li@example.com'),
  User(id: 'u5', name: 'Dana', avatar: '😄', email: 'wang@example.com'),
];

List<Group> createMockGroups() {
  final u1 = mockUsers[0];
  final u2 = mockUsers[1];
  final u3 = mockUsers[2];
  final u4 = mockUsers[3];
  final u5 = mockUsers[4];

  return [
    Group(
      id: 'g1',
      name: 'Weekend Dinner',
      emoji: '🍕',
      members: [u1, u2, u3],
      createdAt: '2026-05-01',
      expenses: [
        Expense(
            id: 'e1',
            description: 'Hotpot Dinner',
            amount: 320,
            paidBy: 'u1',
            splitBetween: ['u1', 'u2', 'u3'],
            category: ExpenseCategory.food,
            date: '2026-05-10',
            groupId: 'g1'),
        Expense(
            id: 'e2',
            description: 'Ride Home',
            amount: 45,
            paidBy: 'u2',
            splitBetween: ['u1', 'u2', 'u3'],
            category: ExpenseCategory.transport,
            date: '2026-05-10',
            groupId: 'g1'),
      ],
    ),
    Group(
      id: 'g2',
      name: 'Penang Trip',
      emoji: '✈️',
      members: [u1, u2, u4, u5],
      createdAt: '2026-04-20',
      expenses: [
        Expense(
            id: 'e3',
            description: 'Hotel Booking',
            amount: 800,
            paidBy: 'u1',
            splitBetween: ['u1', 'u2', 'u4', 'u5'],
            category: ExpenseCategory.accommodation,
            date: '2026-04-25',
            groupId: 'g2'),
        Expense(
            id: 'e4',
            description: 'Attraction Tickets',
            amount: 240,
            paidBy: 'u4',
            splitBetween: ['u1', 'u2', 'u4', 'u5'],
            category: ExpenseCategory.entertainment,
            date: '2026-04-26',
            groupId: 'g2'),
        Expense(
            id: 'e5',
            description: 'Local Food',
            amount: 180,
            paidBy: 'u2',
            splitBetween: ['u1', 'u2', 'u4', 'u5'],
            category: ExpenseCategory.food,
            date: '2026-04-26',
            groupId: 'g2'),
      ],
    ),
    Group(
      id: 'g3',
      name: 'Shared Utilities',
      emoji: '🏠',
      members: [u1, u3, u4],
      createdAt: '2026-03-01',
      expenses: [
        Expense(
            id: 'e6',
            description: 'May Electricity Bill',
            amount: 150,
            paidBy: 'u3',
            splitBetween: ['u1', 'u3', 'u4'],
            category: ExpenseCategory.utilities,
            date: '2026-05-05',
            groupId: 'g3'),
      ],
    ),
  ];
}

enum DataSource { loading, api, cache, mock }

class AppProvider extends ChangeNotifier {
  User? _currentUser;                               // null = not logged in
  DataSource _dataSource = DataSource.loading;
  List<User> users = List.unmodifiable(mockUsers);  // all known users
  List<Group> groups = [];                           // groups visible to current user
  bool _loading = false;                             // true while loadData is fetching
  bool _authLoading = false;                         // true while login/register is in progress
  String? _authError;                                // error message from last auth attempt
  String? _lastSyncError;                            // last backend write that failed, for UI banners

  bool get loading => _loading;
  bool get authLoading => _authLoading;
  String? get authError => _authError;
  String? get lastSyncError => _lastSyncError;
  DataSource get dataSource => _dataSource;
  bool get isUsingMockData => _dataSource == DataSource.mock;
  bool get isAuthenticated => _currentUser != null;
  User get currentUser => _currentUser ?? users.first;

  void clearSyncError() {
    if (_lastSyncError == null) return;
    _lastSyncError = null;
    notifyListeners();
  }

  // 3-tier loading: API → local cache → mock data
  Future<void> loadData() async {
    _loading = true;
    _dataSource = DataSource.loading;
    notifyListeners();

    Object? apiError;
    try {
      final apiUsers = await ApiService().getUsers();
      final apiGroups = await ApiService().getGroups();
      if (apiUsers.isNotEmpty || apiGroups.isNotEmpty) {
        groups = apiGroups;
        users = apiUsers.isNotEmpty ? apiUsers : users;
        // Sync the canonical "current user" from the backend so any writes
        // (create group, add expense) pass server-side currentUserId checks.
        // Skip if a real authenticated _currentUser is already set.
        if (_currentUser == null) {
          try {
            final id = await ApiService().getCurrentUserId();
            if (id != null) {
              final match = users.where((u) => u.id == id).toList();
              if (match.isNotEmpty) _currentUser = match.first;
            }
          } catch (e, s) {
            developer.log('loadData: getCurrentUserId failed',
                error: e, stackTrace: s, name: 'AppProvider');
          }
        }
        _ensureCurrentUserInUsers();
        _cacheToLocalDb(users, apiGroups);
        _dataSource = DataSource.api;
        _loading = false;
        notifyListeners();
        return;
      }
    } catch (e, s) {
      apiError = e;
      developer.log('loadData: API unreachable',
          error: e, stackTrace: s, name: 'AppProvider');
    }

    try {
      final cachedUsers = await LocalDbService().getAllUsers();
      final cachedGroups = await LocalDbService().getAllGroups();
      if (cachedGroups.isNotEmpty) {
        groups = cachedGroups;
        users = cachedUsers;
        _ensureCurrentUserInUsers();
        _dataSource = DataSource.cache;
        if (apiError != null) {
          _lastSyncError = 'Backend unreachable — showing cached data. ($apiError)';
        }
        _loading = false;
        notifyListeners();
        return;
      }
    } catch (e, s) {
      developer.log('loadData: local cache unavailable',
          error: e, stackTrace: s, name: 'AppProvider');
    }

    groups = createMockGroups();
    _ensureCurrentUserInUsers();
    _dataSource = DataSource.mock;
    _lastSyncError = apiError != null
        ? 'Backend unreachable — showing demo data. ($apiError)'
        : 'Showing demo data — no backend or cache available.';
    _loading = false;
    notifyListeners();
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setAuthLoading(true);

    try {
      final user = await ApiService().login(email: email, password: password);
      await _completeAuth(user);
      return true;
    } catch (error) {
      _authError = _authMessage(error, 'Unable to sign in.');
      _setAuthLoading(false);
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _setAuthLoading(true);

    try {
      final user = await ApiService().register(
        name: name,
        email: email,
        password: password,
      );
      await _completeAuth(user);
      return true;
    } catch (error) {
      if (error is! ApiException) {
        final localUser = User(
          id: 'u${DateTime.now().millisecondsSinceEpoch}',
          name: name.trim(),
          avatar: '👤',
          email: email.trim(),
        );
        await _completeAuth(localUser);
        return true;
      }

      _authError = _authMessage(error, 'Unable to create account.');
      _setAuthLoading(false);
      return false;
    }
  }

  // Post-login/register: set the current user, reload data, sync user into list
  Future<void> _completeAuth(User user) async {
    _authError = null;
    _currentUser = user;
    users = _upsertUser(users, user);  // Ensure the user exists in the list
    await loadData();                   // Fetch fresh data from API/cache
    users = _upsertUser(users, user);  // Re-upsert after data reload (loadData may replace users)
    _authLoading = false;
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _authError = null;
    notifyListeners();
  }

  void _setAuthLoading(bool value) {
    _authLoading = value;
    _authError = null;
    notifyListeners();
  }

  String _authMessage(Object error, String fallback) {
    if (error is ApiException) return error.message;
    return fallback;
  }

  // Replace user if same ID exists, otherwise add at the front
  List<User> _upsertUser(List<User> currentUsers, User user) {
    final updated = <User>[];
    var replaced = false;
    for (final candidate in currentUsers) {
      if (candidate.id == user.id) {
        updated.add(user);
        replaced = true;
      } else {
        updated.add(candidate);
      }
    }
    if (!replaced) updated.insert(0, user);
    return updated;
  }

  void _ensureCurrentUserInUsers() {
    final user = _currentUser;
    if (user != null) {
      users = _upsertUser(users, user);
    }
  }

  // Fire-and-forget: errors are silently ignored (cache is best-effort)
  void _cacheToLocalDb(List<User> usersList, List<Group> groupsList) {
    try {
      final db = LocalDbService();
      db.clearAll();
      db.insertUsers(usersList);
      for (final g in groupsList) {
        db.insertGroup(g);
      }
    } catch (_) {
      // Silently ignore cache failures
    }
  }

  // Optimistic add: update UI immediately, sync to backend in background.
  // The current user is auto-included in the member list — the backend requires
  // the logged-in user to be a member of any group they create.
  Group addGroup(String name, String emoji, List<User> members) {
    final me = currentUser;
    final dedupedMembers = [
      me,
      ...members.where((m) => m.id != me.id),
    ];

    final newGroup = Group(
      id: 'g${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      emoji: emoji,
      members: dedupedMembers,
      expenses: [],
      createdAt: DateTime.now().toIso8601String().split('T')[0],
    );
    groups = [...groups, newGroup];
    notifyListeners();

    // Sync to backend; on failure revert the optimistic add and expose the error
    // via lastSyncError so the UI can show a banner / snackbar.
    ApiService()
        .createGroup(name, emoji, dedupedMembers.map((m) => m.id).toList(),
            id: newGroup.id)
        .then((_) {
      _cacheToLocalDb(users, groups);
    }).catchError((Object e, StackTrace s) {
      developer.log('createGroup failed',
          error: e, stackTrace: s, name: 'AppProvider');
      groups = groups.where((g) => g.id != newGroup.id).toList();
      _lastSyncError = 'Could not save group "$name": $e';
      notifyListeners();
      _cacheToLocalDb(users, groups);
    });
    return newGroup;
  }

  void updateGroup(
    String groupId, {
    String? name,
    String? emoji,
    List<User>? members,
  }) {
    final me = currentUser;
    // Same backend constraint as addGroup: current user must remain a member.
    final dedupedMembers = members == null
        ? null
        : [me, ...members.where((m) => m.id != me.id)];

    final previousGroups = groups;
    groups = groups.map((g) {
      if (g.id != groupId) return g;
      return Group(
        id: g.id,
        name: name ?? g.name,
        emoji: emoji ?? g.emoji,
        members: dedupedMembers ?? g.members,
        expenses: g.expenses,
        createdAt: g.createdAt,
      );
    }).toList();
    notifyListeners();

    ApiService()
        .updateGroup(
          groupId: groupId,
          name: name,
          emoji: emoji,
          memberIds: dedupedMembers?.map((m) => m.id).toList(),
        )
        .then((_) {
      _cacheToLocalDb(users, groups);
    }).catchError((Object e, StackTrace s) {
      developer.log('updateGroup failed',
          error: e, stackTrace: s, name: 'AppProvider');
      groups = previousGroups;
      _lastSyncError = 'Could not update group: $e';
      notifyListeners();
      _cacheToLocalDb(users, groups);
    });
  }

  void deleteGroup(String groupId) {
    groups = groups.where((g) => g.id != groupId).toList();
    notifyListeners();

    ApiService().deleteGroup(groupId).catchError((Object e, StackTrace s) {
      developer.log('deleteGroup failed',
          error: e, stackTrace: s, name: 'AppProvider');
    });
    _cacheToLocalDb(users, groups);
  }

  void addExpense(String groupId, Expense expense) {
    groups = groups.map((g) {
      if (g.id == groupId) {
        return Group(
          id: g.id,
          name: g.name,
          emoji: g.emoji,
          members: g.members,
          expenses: [...g.expenses, expense],
          createdAt: g.createdAt,
        );
      }
      return g;
    }).toList();
    notifyListeners();

    // Sync to backend with client-generated ID (fire-and-forget — errors logged)
    ApiService()
        .addExpense(
          groupId: groupId,
          description: expense.description,
          amount: expense.amount,
          paidBy: expense.paidBy,
          splitBetween: expense.splitBetween,
          splitAmounts: expense.splitAmounts,
          category: expense.category.name,
          date: expense.date,
          id: expense.id,
        )
        .then((_) {
      _cacheToLocalDb(users, groups);
    }).catchError((Object e, StackTrace s) {
      developer.log('addExpense failed',
          error: e, stackTrace: s, name: 'AppProvider');
      // Revert the optimistic add so the UI matches reality.
      groups = groups.map((g) {
        if (g.id != groupId) return g;
        return Group(
          id: g.id,
          name: g.name,
          emoji: g.emoji,
          members: g.members,
          expenses: g.expenses.where((e) => e.id != expense.id).toList(),
          createdAt: g.createdAt,
        );
      }).toList();
      _lastSyncError = 'Could not save expense "${expense.description}": $e';
      notifyListeners();
      _cacheToLocalDb(users, groups);
    });
  }

  void updateExpense(String groupId, Expense expense) {
    groups = groups.map((g) {
      if (g.id == groupId) {
        return Group(
          id: g.id,
          name: g.name,
          emoji: g.emoji,
          members: g.members,
          expenses: g.expenses
              .map((existing) => existing.id == expense.id ? expense : existing)
              .toList(),
          createdAt: g.createdAt,
        );
      }
      return g;
    }).toList();
    notifyListeners();

    ApiService()
        .updateExpense(
          groupId: groupId,
          expenseId: expense.id,
          description: expense.description,
          amount: expense.amount,
          paidBy: expense.paidBy,
          splitBetween: expense.splitBetween,
          category: expense.category.name,
          date: expense.date,
        )
        .catchError((Object e, StackTrace s) {
      developer.log('updateExpense failed',
          error: e, stackTrace: s, name: 'AppProvider');
      return expense;
    });
    _cacheToLocalDb(users, groups);
  }

  void deleteExpense(String groupId, String expenseId) {
    groups = groups.map((g) {
      if (g.id == groupId) {
        return Group(
          id: g.id,
          name: g.name,
          emoji: g.emoji,
          members: g.members,
          expenses: g.expenses.where((e) => e.id != expenseId).toList(),
          createdAt: g.createdAt,
        );
      }
      return g;
    }).toList();
    notifyListeners();

    // Sync to backend and persist locally (fire-and-forget — errors logged)
    ApiService()
        .deleteExpense(groupId, expenseId)
        .catchError((Object e, StackTrace s) {
      developer.log('deleteExpense failed',
          error: e, stackTrace: s, name: 'AppProvider');
    });
    _cacheToLocalDb(users, groups);
  }

  Group? getGroupById(String id) {
    try {
      return groups.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  User? getUserById(String id) {
    try {
      return users.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  // Same greedy settlement algorithm as the backend's expenseService
  List<Balance> calculateBalances(Group group) {
    // Step 1: Initialise all member balances to 0
    final balanceMap = <String, double>{};
    for (final m in group.members) {
      balanceMap[m.id] = 0;
    }

    // Step 2: For each expense, credit the payer and debit each splitter.
    // Per-user share uses expense.splitAmounts when set, otherwise equal split.
    for (final expense in group.expenses) {
      balanceMap[expense.paidBy] =
          (balanceMap[expense.paidBy] ?? 0) + expense.amount;
      for (final userId in expense.splitBetween) {
        final share = expense.shareFor(userId);
        balanceMap[userId] = (balanceMap[userId] ?? 0) - share;
      }
    }

    final debtors = <_BalanceEntry>[];
    final creditors = <_BalanceEntry>[];

    balanceMap.forEach((userId, balance) {
      if (balance < -0.01) {
        debtors.add(_BalanceEntry(userId, -balance));
      } else if (balance > 0.01) {
        creditors.add(_BalanceEntry(userId, balance));
      }
    });

    debtors.sort((a, b) => b.amount.compareTo(a.amount));
    creditors.sort((a, b) => b.amount.compareTo(a.amount));

    final settlements = <Balance>[];
    int i = 0, j = 0;

    while (i < debtors.length && j < creditors.length) {
      final amount = debtors[i].amount < creditors[j].amount
          ? debtors[i].amount
          : creditors[j].amount;
      if (amount > 0.01) {
        settlements.add(Balance(
          from: debtors[i].id,
          to: creditors[j].id,
          amount: (amount * 100).roundToDouble() / 100,
        ));
      }
      debtors[i].amount -= amount;
      creditors[j].amount -= amount;
      if (debtors[i].amount < 0.01) i++;
      if (creditors[j].amount < 0.01) j++;
    }

    return settlements;
  }

  void recordSettlement(String groupId, String from, String to, double amount) {
    final now = DateTime.now().toIso8601String().split('T')[0];
    final settlementExpense = Expense(
      id: 'e${DateTime.now().millisecondsSinceEpoch}',
      description: 'Settlement',
      amount: amount,
      paidBy: from,
      splitBetween: [to],
      category: ExpenseCategory.settlement,
      date: now,
      groupId: groupId,
    );

    groups = groups.map((g) {
      if (g.id != groupId) return g;
      return Group(
        id: g.id,
        name: g.name,
        emoji: g.emoji,
        members: g.members,
        expenses: [...g.expenses, settlementExpense],
        createdAt: g.createdAt,
      );
    }).toList();
    notifyListeners();

    ApiService()
        .recordSettlement(
          groupId: groupId,
          from: from,
          to: to,
          amount: amount,
        )
        .catchError((Object e, StackTrace s) {
      developer.log('recordSettlement failed',
          error: e, stackTrace: s, name: 'AppProvider');
      return <String, dynamic>{};
    });
    _cacheToLocalDb(users, groups);
  }

  double getTotalOwed() {
    double total = 0;
    for (final group in groups) {
      final balances = calculateBalances(group);
      for (final b in balances) {
        if (b.to == currentUser.id) total += b.amount;
      }
    }
    return (total * 100).roundToDouble() / 100;
  }

  double getTotalOwing() {
    double total = 0;
    for (final group in groups) {
      final balances = calculateBalances(group);
      for (final b in balances) {
        if (b.from == currentUser.id) total += b.amount;
      }
    }
    return (total * 100).roundToDouble() / 100;
  }

  List<Map<String, dynamic>> getRecentActivity() {
    final all = <Map<String, dynamic>>[];
    for (final g in groups) {
      for (final e in g.expenses.where((e) => e.category != ExpenseCategory.settlement)) {
        all.add({
          'expense': e,
          'groupName': g.name,
          'groupEmoji': g.emoji,
          'groupId': g.id,
        });
      }
    }
    all.sort((a, b) {
      final aDate = (a['expense'] as Expense).date;
      final bDate = (b['expense'] as Expense).date;
      return bDate.compareTo(aDate);
    });
    return all.take(5).toList();
  }
}

// Mutable helper class used inside calculateBalances (private to this file)
class _BalanceEntry {
  final String id;
  double amount;  // Mutable — gets decremented as settlements are paired
  _BalanceEntry(this.id, this.amount);
}
