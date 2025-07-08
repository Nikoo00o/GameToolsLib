import 'package:flutter_test/flutter_test.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:integration_test/integration_test.dart';


void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('test', (WidgetTester tester) async {
    testGameToolsLib();
  });
}
