import 'package:flutter_test/flutter_test.dart';
import 'package:app_template/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());
  });
}
