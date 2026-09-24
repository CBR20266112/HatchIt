import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:hatchit/main.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('HatchIt app renders bottom navigation', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: HatchItApp(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('해칫 시간표'), findsOneWidget);
    expect(find.text('기상 & 미션'), findsOneWidget);
    expect(find.text('비서실'), findsOneWidget);
    expect(find.text('캠퍼스 오락실'), findsOneWidget);
  });
}
