import 'package:flutter_test/flutter_test.dart';

import 'package:local_ai/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LocalAiApp());
    expect(find.byType(LocalAiApp), findsOneWidget);
  });
}
