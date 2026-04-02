import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/main.dart';
import 'package:frontend/presentation/auth/login_screen.dart';
import 'package:frontend/providers/theme_provider.dart';

void main() {
  testWidgets('MyApp boots to login screen when session is empty', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final themeProvider = ThemeProvider();

    await tester.pumpWidget(MyApp(themeProvider: themeProvider));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
