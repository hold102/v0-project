/*
 * app_provider_test.dart — Pure-logic tests for AppProvider.
 *
 * These run without a backend; they only validate the in-memory mutation
 * behavior the provider applies before/after API calls.
 */
import 'package:flutter_test/flutter_test.dart';
import 'package:splitease/models/expense.dart';
import 'package:splitease/models/expense_category.dart';
import 'package:splitease/providers/app_provider.dart';

void main() {
  group('AppProvider.addGroup', () {
    test('auto-includes the current user in members', () {
      final app = AppProvider();
      // currentUser defaults to users.first (mockUsers[0] = "Me", id "u1").
      final me = app.currentUser;
      final others = app.users.where((u) => u.id != me.id).take(2).toList();

      // Caller passes only the OTHER members — simulating the buggy UI path.
      final newGroup = app.addGroup('Trip', '✈️', others);

      // Auto-include guarantees: current user is present.
      expect(newGroup.members.any((m) => m.id == me.id), isTrue,
          reason: 'addGroup must add the current user to members');
      // Current user appears exactly once (no duplicate).
      expect(newGroup.members.where((m) => m.id == me.id).length, 1);
    });

    test('does not duplicate the current user if already passed in', () {
      final app = AppProvider();
      final me = app.currentUser;
      final withMe = [me, app.users[1]];

      final newGroup = app.addGroup('Trip', '✈️', withMe);

      expect(newGroup.members.where((m) => m.id == me.id).length, 1,
          reason: 'current user must appear exactly once');
    });

    test('adds the new group to the optimistic in-memory list', () {
      final app = AppProvider();
      final before = app.groups.length;
      app.addGroup('Trip', '✈️', [app.users[1], app.users[2]]);
      expect(app.groups.length, before + 1);
    });
  });

  group('Expense.shareFor', () {
    Expense make({Map<String, double>? splitAmounts}) => Expense(
          id: 'e1',
          description: 'x',
          amount: 100,
          paidBy: 'u1',
          splitBetween: const ['u1', 'u2', 'u3', 'u4'],
          splitAmounts: splitAmounts,
          category: ExpenseCategory.food,
          date: '2026-05-15',
          groupId: 'g1',
        );

    test('falls back to equal split when splitAmounts is null', () {
      final e = make();
      expect(e.shareFor('u1'), 25);
      expect(e.shareFor('u2'), 25);
    });

    test('returns the explicit amount per user when splitAmounts is set', () {
      final e = make(splitAmounts: {'u1': 40, 'u2': 30, 'u3': 20, 'u4': 10});
      expect(e.shareFor('u1'), 40);
      expect(e.shareFor('u4'), 10);
    });

    test('toJson/fromJson round-trip preserves splitAmounts', () {
      final e = make(splitAmounts: {'u1': 40, 'u2': 30, 'u3': 20, 'u4': 10});
      final restored = Expense.fromJson(e.toJson());
      expect(restored.splitAmounts, equals(e.splitAmounts));
    });
  });

  group('AppProvider.updateGroup', () {
    test('keeps the current user in members even if caller drops them', () {
      final app = AppProvider();
      final me = app.currentUser;
      final created =
          app.addGroup('Trip', '✈️', [app.users[1], app.users[2]]);

      // Simulate the edit screen un-ticking the current user.
      final without = created.members.where((m) => m.id != me.id).toList();
      app.updateGroup(created.id, members: without);

      final updated = app.groups.firstWhere((g) => g.id == created.id);
      expect(updated.members.any((m) => m.id == me.id), isTrue,
          reason: 'current user must remain a member after update');
    });
  });
}
