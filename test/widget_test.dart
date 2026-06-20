import 'package:flutter_test/flutter_test.dart';
import 'package:virelo/main.dart';

void main() {
  testWidgets('VireloApp loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const VireloApp());

    // Verify that the showcase page is rendered
    expect(find.text('Virelo Design System'), findsOneWidget);
    expect(find.text('Typography'), findsOneWidget);
    expect(find.text('Buttons'), findsOneWidget);
  });
}
