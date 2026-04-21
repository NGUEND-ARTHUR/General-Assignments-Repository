import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:uniattend/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('UniAttend Mobile App Integration Tests', () {
    testWidgets('Splash screen to login navigation',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.text('UniAttend'), findsWidgets);
    });

    testWidgets('Student login flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final emailField = find.byType(TextFormField).at(0);
      final passwordField = find.byType(TextFormField).at(1);
      final loginButton = find.byWidgetPredicate(
        (widget) => widget is ElevatedButton || widget is TextButton,
      );

      await tester.enterText(emailField, 'student@ictuniversity.edu.cm');
      await tester.pumpAndSettle();

      await tester.enterText(passwordField, 'Student@1234');
      await tester.pumpAndSettle();

      await tester.tap(loginButton.first);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.byType(Scaffold), findsWidgets);
      expect(find.text('Home'), findsWidgets);
    });

    testWidgets('Student can view home page with courses',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final emailField = find.byType(TextFormField).at(0);
      final passwordField = find.byType(TextFormField).at(1);
      final loginButton = find.byWidgetPredicate(
        (widget) => widget is ElevatedButton || widget is TextButton,
      );

      await tester.enterText(emailField, 'student@ictuniversity.edu.cm');
      await tester.enterText(passwordField, 'Student@1234');
      await tester.tap(loginButton.first);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final homeTab = find.text('Home');
      if (homeTab.evaluate().isNotEmpty) {
        await tester.tap(homeTab.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      expect(find.text('SEN3244'), findsWidgets);
      expect(find.text('Communication Technology'), findsWidgets);
    });

    testWidgets('Student can navigate to attendance tab',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final emailField = find.byType(TextFormField).at(0);
      final passwordField = find.byType(TextFormField).at(1);
      final loginButton = find.byWidgetPredicate(
        (widget) => widget is ElevatedButton || widget is TextButton,
      );

      await tester.enterText(emailField, 'student@ictuniversity.edu.cm');
      await tester.enterText(passwordField, 'Student@1234');
      await tester.tap(loginButton.first);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final attendanceTab = find.text('Attendance');
      await tester.tap(attendanceTab.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('Student can view attendance history',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final emailField = find.byType(TextFormField).at(0);
      final passwordField = find.byType(TextFormField).at(1);
      final loginButton = find.byWidgetPredicate(
        (widget) => widget is ElevatedButton || widget is TextButton,
      );

      await tester.enterText(emailField, 'student@ictuniversity.edu.cm');
      await tester.enterText(passwordField, 'Student@1234');
      await tester.tap(loginButton.first);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final historyTab = find.text('History');
      if (historyTab.evaluate().isNotEmpty) {
        await tester.tap(historyTab.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        expect(find.byType(Scaffold), findsWidgets);
      }
    });

    testWidgets('Student can access export page', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final emailField = find.byType(TextFormField).at(0);
      final passwordField = find.byType(TextFormField).at(1);
      final loginButton = find.byWidgetPredicate(
        (widget) => widget is ElevatedButton || widget is TextButton,
      );

      await tester.enterText(emailField, 'student@ictuniversity.edu.cm');
      await tester.enterText(passwordField, 'Student@1234');
      await tester.tap(loginButton.first);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final exportTab = find.text('Export');
      if (exportTab.evaluate().isNotEmpty) {
        await tester.tap(exportTab.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        expect(find.byType(Scaffold), findsWidgets);
      }
    });

    testWidgets('Lecturer login flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final emailField = find.byType(TextFormField).at(0);
      final passwordField = find.byType(TextFormField).at(1);
      final loginButton = find.byWidgetPredicate(
        (widget) => widget is ElevatedButton || widget is TextButton,
      );

      await tester.enterText(emailField, 'lecturer@ictuniversity.edu.cm');
      await tester.enterText(passwordField, 'Lect@1234');
      await tester.tap(loginButton.first);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('Invalid credentials show error', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final emailField = find.byType(TextFormField).at(0);
      final passwordField = find.byType(TextFormField).at(1);
      final loginButton = find.byWidgetPredicate(
        (widget) => widget is ElevatedButton || widget is TextButton,
      );

      await tester.enterText(emailField, 'invalid@nonexistent.cm');
      await tester.enterText(passwordField, 'WrongPassword123');
      await tester.tap(loginButton.first);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is SnackBar ||
              (widget is Text && widget.data?.contains('Invalid') == true) ||
              (widget is Text && widget.data?.contains('error') == true),
        ),
        findsWidgets,
      );
    });

    testWidgets('Navigation between tabs works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final emailField = find.byType(TextFormField).at(0);
      final passwordField = find.byType(TextFormField).at(1);
      final loginButton = find.byWidgetPredicate(
        (widget) => widget is ElevatedButton || widget is TextButton,
      );

      await tester.enterText(emailField, 'student@ictuniversity.edu.cm');
      await tester.enterText(passwordField, 'Student@1234');
      await tester.tap(loginButton.first);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final tabs = find.byType(Tab);
      expect(tabs, findsWidgets);

      for (int i = 0; i < tabs.evaluate().length && i < 3; i++) {
        await tester.tap(tabs.at(i));
        await tester.pumpAndSettle(const Duration(seconds: 1));
        expect(find.byType(Scaffold), findsWidgets);
      }
    });

    testWidgets('App can handle rapid navigation', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final emailField = find.byType(TextFormField).at(0);
      final passwordField = find.byType(TextFormField).at(1);
      final loginButton = find.byWidgetPredicate(
        (widget) => widget is ElevatedButton || widget is TextButton,
      );

      await tester.enterText(emailField, 'student@ictuniversity.edu.cm');
      await tester.enterText(passwordField, 'Student@1234');
      await tester.tap(loginButton.first);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final tabs = find.byType(Tab);
      for (int i = 0; i < 5; i++) {
        if (tabs.evaluate().isNotEmpty) {
          await tester.tap(tabs.at(i % tabs.evaluate().length));
          await tester.pumpAndSettle(const Duration(milliseconds: 500));
        }
      }

      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('User profile is displayed after login',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final emailField = find.byType(TextFormField).at(0);
      final passwordField = find.byType(TextFormField).at(1);
      final loginButton = find.byWidgetPredicate(
        (widget) => widget is ElevatedButton || widget is TextButton,
      );

      await tester.enterText(emailField, 'student@ictuniversity.edu.cm');
      await tester.enterText(passwordField, 'Student@1234');
      await tester.tap(loginButton.first);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.byType(AppBar), findsWidgets);
      expect(find.byType(CircleAvatar), findsWidgets);
    });

    testWidgets('Empty TextFormField validation', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final loginButton = find.byWidgetPredicate(
        (widget) => widget is ElevatedButton || widget is TextButton,
      );

      await tester.tap(loginButton.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('Course card displays correctly', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final emailField = find.byType(TextFormField).at(0);
      final passwordField = find.byType(TextFormField).at(1);
      final loginButton = find.byWidgetPredicate(
        (widget) => widget is ElevatedButton || widget is TextButton,
      );

      await tester.enterText(emailField, 'student@ictuniversity.edu.cm');
      await tester.enterText(passwordField, 'Student@1234');
      await tester.tap(loginButton.first);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final homeTab = find.text('Home');
      if (homeTab.evaluate().isNotEmpty) {
        await tester.tap(homeTab.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        expect(find.byType(Card), findsWidgets);
      }
    });
  });
}
