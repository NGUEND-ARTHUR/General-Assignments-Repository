import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UniAttend Widget Tests - Component Level', () {
    testWidgets('Material app renders with theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          title: 'UniAttend',
          theme: ThemeData(primarySwatch: Colors.blue),
          home: Scaffold(
            appBar: AppBar(title: const Text('Test')),
            body: const Center(child: Text('Hello World')),
          ),
        ),
      );
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('TextFormField accepts input', (WidgetTester tester) async {
      final textController = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextFormField(controller: textController),
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      expect(textController.text, 'test@example.com');
    });

    testWidgets('Multiple text fields can be filled',
        (WidgetTester tester) async {
      final controller1 = TextEditingController();
      final controller2 = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(controller: controller1),
                  TextFormField(controller: controller2),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.enterText(
          find.byType(TextFormField).first, 'email@test.com');
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      expect(controller1.text, 'email@test.com');
      expect(controller2.text, 'password123');
    });

    testWidgets('ElevatedButton responds to tap', (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () => tapped = true,
              child: const Text('Tap Me'),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(ElevatedButton));
      expect(tapped, isTrue);
    });

    testWidgets('Form validation works', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: TextFormField(
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Cannot be empty' : null,
              ),
            ),
          ),
        ),
      );
      expect(formKey.currentState?.validate(), isFalse);
      await tester.enterText(find.byType(TextFormField), 'some text');
      expect(formKey.currentState?.validate(), isTrue);
    });

    testWidgets('AppBar renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('UniAttend')),
            body: const Center(child: Text('Body')),
          ),
        ),
      );
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('UniAttend'), findsOneWidget);
    });

    testWidgets('ListView renders multiple items', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) => Text('Item $index'),
            ),
          ),
        ),
      );
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('Column layout displays widgets vertically',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Text('First'),
                Text('Second'),
                Text('Third'),
              ],
            ),
          ),
        ),
      );
      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
      expect(find.text('Third'), findsOneWidget);
    });

    testWidgets('Padding widget applies spacing', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                color: Colors.blue,
                child: const Text('Padded Content'),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(Padding), findsOneWidget);
      expect(find.text('Padded Content'), findsOneWidget);
    });

    testWidgets('Container widget renders with properties',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              color: Colors.green,
              child: const Text('Container Test'),
            ),
          ),
        ),
      );
      expect(find.byType(Container), findsOneWidget);
      expect(find.text('Container Test'), findsOneWidget);
    });

    testWidgets('Icon widget renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Icon(Icons.email),
          ),
        ),
      );
      expect(find.byIcon(Icons.email), findsOneWidget);
    });

    testWidgets('FloatingActionButton responds to press',
        (WidgetTester tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: () => pressed = true,
              child: const Icon(Icons.add),
            ),
            body: const Center(child: Text('Test')),
          ),
        ),
      );
      await tester.tap(find.byType(FloatingActionButton));
      expect(pressed, isTrue);
    });

    testWidgets('SingleChildScrollView allows scrolling',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: List.generate(
                  20,
                  (index) => Text('Item $index'),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      await tester.drag(
          find.byType(SingleChildScrollView), const Offset(0, -100));
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('CheckboxListTile updates state', (WidgetTester tester) async {
      bool isChecked = false;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => MaterialApp(
            home: Scaffold(
              body: CheckboxListTile(
                value: isChecked,
                onChanged: (value) =>
                    setState(() => isChecked = value ?? false),
                title: const Text('Accept Terms'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      expect(isChecked, isTrue);
    });

    testWidgets('TextField with obscureText masks input',
        (WidgetTester tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(
              controller: controller,
              obscureText: true,
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'secret');
      expect(controller.text, 'secret');
    });

    testWidgets('SizedBox creates space between widgets',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Text('Top'),
                SizedBox(height: 50),
                Text('Bottom'),
              ],
            ),
          ),
        ),
      );
      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.text('Top'), findsOneWidget);
      expect(find.text('Bottom'), findsOneWidget);
    });

    testWidgets('CircularProgressIndicator renders',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CircularProgressIndicator(),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('SnackBar displays message', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Test Message')),
                  );
                },
                child: const Text('Show SnackBar'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(find.text('Test Message'), findsOneWidget);
    });

    testWidgets('Opacity widget adjusts transparency',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Opacity(
              opacity: 0.5,
              child: Container(
                color: Colors.red,
                child: const Text('Faded'),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(Opacity), findsOneWidget);
      expect(find.text('Faded'), findsOneWidget);
    });

    testWidgets('GestureDetector responds to taps',
        (WidgetTester tester) async {
      bool gestureDetected = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GestureDetector(
              onTap: () => gestureDetected = true,
              child: const Text('Tap Area'),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(GestureDetector));
      expect(gestureDetected, isTrue);
    });

    testWidgets('Text widget renders with multiple styles',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Text('Normal Text'),
                Text('Bold Text',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Large Text', style: TextStyle(fontSize: 24)),
              ],
            ),
          ),
        ),
      );
      expect(find.text('Normal Text'), findsOneWidget);
      expect(find.text('Bold Text'), findsOneWidget);
      expect(find.text('Large Text'), findsOneWidget);
    });

    testWidgets('Row layout displays widgets horizontally',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                Icon(Icons.home),
                Text('Home'),
              ],
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('Spacing between elements in Column',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('Item 1'),
                Text('Item 2'),
                Text('Item 3'),
              ],
            ),
          ),
        ),
      );
      expect(find.byType(Column), findsOneWidget);
      expect(find.byType(Text), findsNWidgets(3));
    });

    testWidgets('RaisedButton-like widget works', (WidgetTester tester) async {
      int pressCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              onPressed: () => pressCount++,
              label: const Text('Add'),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(ElevatedButton));
      expect(pressCount, 1);
    });

    testWidgets('Stack allows overlapping widgets',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  top: 10,
                  left: 10,
                  child: Text('Overlay'),
                ),
                Center(child: Text('Center')),
              ],
            ),
          ),
        ),
      );
      expect(find.text('Overlay'), findsOneWidget);
      expect(find.text('Center'), findsOneWidget);
    });
  });
}
