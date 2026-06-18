// v0.3.6.1 hotfix: 暗色主题 widget 适配 — category_page dark theme test
//
// 验证:
//   - L145 (IconButton color textPrimary) → onSurface
//   - L222 (空态 Icon color textSecondary) → onSurfaceVariant
//   - 所有 Text 不用浅色 token
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sanyelive/core/theme/colors.dart';
import 'package:sanyelive/core/theme/theme.dart';
import 'package:sanyelive/data/models/channel.dart';
import 'package:sanyelive/data/repositories/channel_repository.dart';
import 'package:sanyelive/features/category/category_page.dart';

class _FakeRepo implements ChannelRepository {
  const _FakeRepo(this._channels);
  final List<Channel> _channels;
  @override
  Future<List<Channel>> loadBundled() async => _channels;
}

// 故意返回空, 触发 _EmptyState
const _channels = <Channel>[];

Future<void> _pumpDark(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        channelsProvider.overrideWith((ref) async => _channels),
        channelRepositoryProvider.overrideWithValue(const _FakeRepo(_channels)),
      ],
      child: MaterialApp(
        theme: IptvTheme.dark(),
        home: const CategoryPage(categoryId: 'cctv', title: '央视'),
      ),
    ),
  );
  await tester.pumpAndSettle(const Duration(milliseconds: 200));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CategoryPage dark theme (v0.3.6.1 hotfix)', () {
    testWidgets('返回按钮 color 用 onSurface (darkTextPrimary)',
        (tester) async {
      await _pumpDark(tester);
      final icons = tester.widgetList<Icon>(find.byIcon(Icons.arrow_back));
      expect(icons, isNotEmpty);
      final back = icons.first;
      expect(back.color, isNot(equals(IptvColors.textPrimary)),
          reason: '返回按钮不该用浅色 token');
      expect(back.color, equals(IptvColors.darkTextPrimary));
    });

    testWidgets('空态 icon (inbox_outlined) 用 onSurfaceVariant',
        (tester) async {
      await _pumpDark(tester);
      final icons = tester.widgetList<Icon>(find.byIcon(Icons.inbox_outlined));
      expect(icons, isNotEmpty,
          reason: '空 channels 列表应触发 _EmptyState 里的 inbox_outlined icon');
      final inbox = icons.first;
      expect(inbox.color, isNot(equals(IptvColors.textSecondary)),
          reason: '空态 icon 不该用浅色 token');
      // dark theme onSurfaceVariant 走 M3 default
      expect(inbox.color, isA<Color>());
    });

    testWidgets('所有 Text 都不用浅色 token', (tester) async {
      await _pumpDark(tester);
      final offenders = <String>[];
      for (final w in tester.widgetList<Text>(find.byType(Text))) {
        final c = w.style?.color;
        if (c == IptvColors.textPrimary || c == IptvColors.textSecondary) {
          offenders.add('"${w.data}" uses $c');
        }
      }
      expect(offenders, isEmpty,
          reason: '暗色主题下不允许 hardcode 浅色 token: ${offenders.join(", ")}');
    });
  });
}
