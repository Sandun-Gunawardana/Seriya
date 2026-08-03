import 'package:flutter_test/flutter_test.dart';
import 'package:seriya_app/app.dart';

void main() {
  testWidgets('shows the passenger transport dashboard', (tester) async {
    await tester.pumpWidget(const SeriyaApp());

    expect(find.text('Morning to office'), findsOneWidget);
    expect(find.text('Vehicle is on the way'), findsOneWidget);
    expect(find.text("I'm riding"), findsOneWidget);
    expect(find.text('Live map'), findsOneWidget);
  });

  testWidgets('allows the passenger to change attendance', (tester) async {
    await tester.pumpWidget(const SeriyaApp());

    await tester.tap(find.text("I'm riding"));
    await tester.pump();

    expect(find.text('Not riding'), findsOneWidget);
    expect(find.text('You are not travelling on this shift'), findsOneWidget);
  });

  testWidgets('opens the morning and evening shift picker', (tester) async {
    await tester.pumpWidget(const SeriyaApp());

    await tester.tap(find.text('Morning to office'));
    await tester.pumpAndSettle();

    expect(find.text('Choose today’s shift'), findsOneWidget);
    expect(find.text('Evening to home'), findsOneWidget);
  });
}
