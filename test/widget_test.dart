import 'package:flutter_test/flutter_test.dart';
import 'package:powerlog/main.dart';

void main() {
  testWidgets('PowerLog smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PowerLogApp());
  });
}
