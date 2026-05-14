import 'package:flutter/foundation.dart';
import 'package:splitease/models/expense_category.dart';
import 'package:splitease/models/user.dart';
import 'package:splitease/models/group.dart';
import 'package:splitease/models/expense.dart';
import 'package:splitease/models/balance.dart';
import 'package:splitease/services/api_service.dart';
import 'package:splitease/services/local_db_service.dart';

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

class AppProvider extends ChangeNotifier {
  User? _currentUser;
  List<User> users = List.unmodifiable(mockUsers);
  List<Group> groups = [];
  bool _loading = false;
  bool _authLoading = false;
  String? _authError;

  bool get loading => _loading;
  bool get authLoading => _authLoading;
  String? get authError => _authError;
  bool get isAuthenticated => _currentUser != null;
  User get currentUser => _currentUser ?? users.first;

  Future<void> loadData() async {
    _loading = true;
    notifyListeners();

    try {
      // 1. Try the backend API first
      final apiUsers = await ApiService().getUsers();
      final apiGroups = await ApiService().getGroups();
      if (apiUsers.isNotEmpty || apiGroups.isNotEmpty) {
        groups = apiGroups;
        users = apiUsers.isNotEmpty ? apiUsers : users;
        _ensureCurrentUserInUsers();
        // Cache to local DB
        _cacheToLocalDb(users, apiGroups);
        _loading = false;
        notifyListeners();
        return;
      }
    } catch (_) {
      // API unreachable — fall through to local cache
    }

    try {
      // 2. Try local SQLite cache
      final cachedUsers = await LocalDbService().getAllUsers();
      final cachedGroups = await LocalDbService().getAllGroups();
      if (cachedGroups.isNotEmpty) {
        groups = cachedGroups;
        users = cachedUsers;
        _ensureCurrentUserInUsers();
        _loading = false;
        notifyListeners();
        return;
      }
    } catch (_) {
      // Local DB unavailable — fall through to mock
    }

    // 3. Fallback: seed with mock data
    groups = createMockGroups();
    _ensureCurrentUserInUsers();
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

  Future<void> _completeAuth(User user) async {
    _authError = null;
    _currentUser = user;
    users = _upsertUser(users, user);
    await loadData();
    users = _upsertUser(users, user);
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

  Group addGroup(String name, String emoji, List<User> members) {
    final newGroup = Group(
      id: 'g${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      emoji: emoji,
      members: members,
      expenses: [],
      createdAt: DateTime.now().toIso8601String().split('T')[0],
    );
    groups = [...groups, newGroup];
    notifyListeners();

    // Sync to backend and persist locally (fire-and-forget)
    ApiService()
        .createGroup(name, emoji, members.map((m) => m.id).toList(),
            id: newGroup.id)
        .then((_) {})
        .catchError((_) {});
    _cacheToLocalDb(users, groups);
    return newGroup;
  }

  void updateGroup(
    String groupId, {
    String? name,
    String? emoji,
    List<User>? members,
  }) {
    groups = groups.map((g) {
      if (g.id != groupId) return g;
      return Group(
        id: g.id,
        name: name ?? g.name,
        emoji: emoji ?? g.emoji,
        members: members ?? g.members,
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
          memberIds: members?.map((m) => m.id).toList(),
        )
        .then((_) {})
        .catchError((_) {});
    _cacheToLocalDb(users, groups);
  }

  void deleteGroup(String groupId) {
    groups = groups.where((g) => g.id != groupId).toList();
    notifyListeners();

    ApiService().deleteGroup(groupId).then((_) {}).catchError((_) {});
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

    // Sync to backend with client-generated ID (fire-and-forget)
    ApiService()
        .addExpense(
          groupId: groupId,
          description: expense.description,
          amount: expense.amount,
          paidBy: expense.paidBy,
          splitBetween: expense.splitBetween,
          category: expense.category.name,
          date: expense.date,
          id: expense.id,
        )
        .then((_) {})
        .catchError((_) {});
    _cacheToLocalDb(users, groups);
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
        .then((_) {})
        .catchError((_) {});
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

    // Sync to backend and persist locally (fire-and-forget)
    ApiService()
        .deleteExpense(groupId, expenseId)
        .then((_) {})
        .catchError((_) {});
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

  List<Balance> calculateBalances(Group group) {
    final balanceMap = <String, double>{};
    for (final m in group.members) {
      balanceMap[m.id] = 0;
    }

    for (final expense in group.expenses) {
      final splitAmount = expense.amount / expense.splitBetween.length;
      balanceMap[expense.paidBy] =
          (balanceMap[expense.paidBy] ?? 0) + expense.amount;
      for (final userId in expense.splitBetween) {
        balanceMap[userId] = (balanceMap[userId] ?? 0) - splitAmount;
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
      for (final e in g.expenses) {
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

class _BalanceEntry {
  final String id;
  double amount;
  _BalanceEntry(this.id, this.amount);
}
