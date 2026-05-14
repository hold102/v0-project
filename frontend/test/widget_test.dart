/*
 * widget_test.dart — Basic integration/smoke tests
 * Verifies that the app launches, key screens render, and navigation works.
 * Uses locally defined test fixtures rather than internal AppProvider helpers.
 */
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:splitease/main.dart';
import 'package:splitease/main_scaffold.dart';
import 'package:splitease/models/expense.dart';
import 'package:splitease/models/expense_category.dart';
import 'package:splitease/models/group.dart';
import 'package:splitease/models/user.dart';
import 'package:splitease/providers/app_provider.dart';

// ---------------------------------------------------------------------------
// Shared test fixtures
// ---------------------------------------------------------------------------

final _me = User(id: 'u1', name: 'Me', avatar: '😊', email: 'me@test.com');
final _bella = User(id: 'u2', name: 'Bella', avatar: '🌸', email: 'bella@test.com');
final _alex = User(id: 'u3', name: 'Alex', avatar: '🦊', email: 'alex@test.com');

final _testUsers = [_me, _bella, _alex];

List<Group> _buildTestGroups() => [
      Group(
        id: 'g1',
        name: 'Weekend Dinner',
        emoji: '🍕',
        members: _testUsers,
        createdAt: '2026-05-14',
        expenses: [
          Expense(
            id: 'e1',
            description: 'Pizza',
            amount: 90,
            paidBy: _me.id,
            splitBetween: [_me.id, _bella.id, _alex.id],
            category: ExpenseCategory.food,
            date: '2026-05-14',
            groupId: 'g1',
          ),
        ],
      ),
    ];

AppProvider _buildProvider() {
  final provider = AppProvider();
  provider.users = _testUsers;
  provider.groups = _buildTestGroups();
  return provider;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // Smoke test: does the app render the auth screen when not authenticated?
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    final provider = AppProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<AppProvider>.value(
        value: provider,
        child: const SplitEaseApp(),
      ),
    );

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });

  testWidgets('Homepage renders key sections', (WidgetTester tester) async {
    final provider = _buildProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<AppProvider>.value(
        value: provider,
        child: const MaterialApp(home: MainScaffold()),
      ),
    );

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('My Groups'), findsOneWidget);

    await tester.drag(find.byType(ListView).first, const Offset(0, -420));
    await tester.pumpAndSettle();

    expect(find.text('Recent Activity'), findsOneWidget);
  });

  testWidgets('Homepage group card opens detail page',
      (WidgetTester tester) async {
    final provider = _buildProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<AppProvider>.value(
        value: provider,
        child: const MaterialApp(home: MainScaffold()),
      ),
    );

    await tester.tap(find.text('Weekend Dinner'));
    await tester.pumpAndSettle();

    expect(find.text('Expenses'), findsOneWidget);
    expect(find.text('Balances'), findsOneWidget);
  });

  testWidgets('Homepage add button opens add expense flow',
      (WidgetTester tester) async {
    final provider = _buildProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<AppProvider>.value(
        value: provider,
        child: const MaterialApp(home: MainScaffold()),
      ),
    );

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Select Group'), findsOneWidget);
    expect(find.text('Create New Group'), findsOneWidget);
  });

  testWidgets('Group card does not show settled while members still owe',
      (WidgetTester tester) async {
    final provider = AppProvider();
    provider.users = _testUsers;
    provider.groups = [
      Group(
        id: 'g-unsettled',
        name: 'Roommates',
        emoji: '🏠',
        members: [_me, _bella, _alex],
        createdAt: '2026-05-14',
        expenses: [
          Expense(
            id: 'e-unsettled',
            description: 'Shared supplies',
            amount: 20,
            paidBy: _bella.id,
            splitBetween: [_bella.id, _alex.id],
            category: ExpenseCategory.shopping,
            date: '2026-05-14',
            groupId: 'g-unsettled',
          ),
        ],
      ),
    ];

    await tester.pumpWidget(
      ChangeNotifierProvider<AppProvider>.value(
        value: provider,
        child: const MaterialApp(home: MainScaffold()),
      ),
    );

    expect(find.text('Unsettled'), findsOneWidget);
    expect(find.text('Settled'), findsNothing);
  });

  testWidgets('Balances tab shows who owes who', (WidgetTester tester) async {
    final provider = _buildProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<AppProvider>.value(
        value: provider,
        child: const MaterialApp(home: MainScaffold()),
      ),
    );

    await tester.tap(find.text('Weekend Dinner'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Balances'));
    await tester.pumpAndSettle();

    expect(find.text('Bella owes Me'), findsOneWidget);
    expect(find.text('Alex owes Me'), findsOneWidget);
  });
}
