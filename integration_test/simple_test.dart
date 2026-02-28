import 'package:flutter_test/flutter_test.dart';
import 'package:deskclaw/main.dart';
import 'package:deskclaw/src/rust/frb_generated.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => await RustLib.init());
  testWidgets('Can call rust function', (WidgetTester tester) async {
    await tester.pumpWidget(const DeskClawApp());
    expect(find.textContaining('DeskClaw'), findsWidgets);
  });
}
