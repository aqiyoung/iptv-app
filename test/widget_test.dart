import 'package:flutter_test/flutter_test.dart';

import 'package:iptv_app/main.dart';

void main() {
  testWidgets(
    'IptvApp boots and demo page renders',
    (WidgetTester tester) async {
      await tester.pumpWidget(const IptvApp());
      await tester.pump();
      expect(find.text('三页直播'), findsOneWidget);
      expect(find.text('CCTV-1 综合'), findsOneWidget);
    },
  );
}
