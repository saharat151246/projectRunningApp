import 'package:flutter_test/flutter_test.dart';
import 'package:running_app/main.dart';

void main() {
  testWidgets('App loads splash screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const RunningApp());

    // Verify that RunMate app renders
    expect(find.byType(RunningApp), findsOneWidget);
  });
}

