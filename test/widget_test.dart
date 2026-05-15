import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/main.dart';

void main() {
  testWidgets('App shell shows foundation navigation', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Pulso'), findsOneWidget);
    expect(find.text('Feed'), findsOneWidget);
    expect(find.text('Create'), findsOneWidget);
    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('Bottom navigation opens core feature areas', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    expect(find.text('Create Post'), findsOneWidget);

    await tester.tap(find.text('Activity'));
    await tester.pumpAndSettle();
    expect(
      find.text('Thumbs-up reactions and realtime updates'),
      findsOneWidget,
    );
  });
}
