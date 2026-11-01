import 'package:flutter_test/flutter_test.dart';
import 'package:mandhoob_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MandhoobApp());
    expect(find.byType(MandhoobApp), findsOneWidget);
  });
}
