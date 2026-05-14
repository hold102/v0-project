/*
 * widget_test.dart — Basic integration/smoke tests
 * Verifies that the app launches, key screens render, and navigation works.
 * Uses mock data created by AppProvider.createMockGroups().
 */
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:splitease/main.dart';
import 'package:splitease/main_scaffold.dart';
import 'package:splitease/models/expense.dart';
import 'package:splitease/models/expense_category.dart';
import 'package:splitease/models/group.dart';
import 'package:splitease/providers/app_provider.dart';

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
    final provider = AppProvider()..groups = createMockGroups();

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
    final provider = AppProvider()..groups = createMockGroups();

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
    final provider = AppProvider()..groups = createMockGroups();

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
    final provider = AppProvider()
      ..groups = [
        Group(
          id: 'g-unsettled',
          name: 'Roommates',
          emoji: '🏠',
          members: [mockUsers[0], mockUsers[1], mockUsers[2]],
          createdAt: '2026-05-14',
          expenses: [
            Expense(
              id: 'e-unsettled',
              description: 'Shared supplies',
              amount: 20,
              paidBy: mockUsers[1].id,
              splitBetween: [mockUsers[1].id, mockUsers[2].id],
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
    final provider = AppProvider()..groups = createMockGroups();

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
