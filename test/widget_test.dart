import 'package:flutter_test/flutter_test.dart';
import 'package:kalp_sagligi/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const KalpSagligiApp(isLoggedIn: false));
    expect(find.text('Kalp Sağlığı'), findsOneWidget);
  });
}
