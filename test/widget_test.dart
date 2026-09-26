import 'package:flutter_test/flutter_test.dart';
import 'package:jogo_da_velha/main.dart';

void main() {
  testWidgets('Jogo Da Velha inicia', (tester) async {
    await tester.pumpWidget(const JogoDaVelhaApp());
    expect(find.text('Jogo Da Velha'), findsOneWidget);
  });
}
