import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// TV 端焦点环颜色 — 朱砂 (Cinnabar)
const Color kTvFocusColor = Color(0xFFE24A1A);

/// TV 焦点包裹器 — 4dp 朱砂焦点环
class TvFocus extends StatefulWidget {
  const TvFocus({
    super.key,
    required this.child,
    this.autofocus = false,
    this.onTap,
    this.onKeyEvent,
    this.focusNode,
    this.borderRadius = 12,
  });

  final Widget child;
  final bool autofocus;
  final VoidCallback? onTap;
  final KeyEventResult Function(KeyEvent event)? onKeyEvent;
  final FocusNode? focusNode;
  final double borderRadius;

  @override
  State<TvFocus> createState() => _TvFocusState();
}

class _TvFocusState extends State<TvFocus> {
  late FocusNode _node;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _node = widget.focusNode ?? FocusNode();
    _node.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _node.dispose();
    } else {
      _node.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) setState(() => _focused = _node.hasFocus);
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (widget.onKeyEvent != null) {
      final result = widget.onKeyEvent!(event);
      if (result == KeyEventResult.handled) return result;
    }
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.select) {
        widget.onTap?.call();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _node,
      autofocus: widget.autofocus,
      onKeyEvent: _handleKey,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border:
                _focused ? Border.all(color: kTvFocusColor, width: 4) : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// TV 焦点遍历组 — 包裹整个页面, 自动管理方向键导航
class TvFocusGroup extends StatelessWidget {
  const TvFocusGroup({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: child,
    );
  }
}

/// P2-1: 一屏焦点上限 — ChatGPT 6/17 建议
///
/// TV 遥控器场景下, 一屏可聚焦项应限制在 7-9 个 (不能自由漂移).
/// 超出时 Row 自动折行, Column 自动截断.
///
/// 使用方式: 包裹 children 列表, 超出 [maxFocusable] 时在 debug 模式报 assert.
/// [TvFocusCapWrap] 提供 Row→Wrap 自动折行.
const int kTvMaxFocusablePerScreen = 9;

/// 包裹多个子组件, debug 模式下 assert 焦点项 <= [kTvMaxFocusablePerScreen].
///
/// 布局行为: 超出上限时截断 (只渲染前 N 项).
/// 如果需要折行, 用 [TvFocusCapWrap] 代替 Row.
class TvFocusCap extends StatelessWidget {
  const TvFocusCap({
    super.key,
    required this.children,
    this.maxFocusable = kTvMaxFocusablePerScreen,
  });

  final List<Widget> children;
  final int maxFocusable;

  @override
  Widget build(BuildContext context) {
    assert(
      children.length <= maxFocusable,
      'TV 一屏焦点项 ${children.length} 超出上限 $maxFocusable, '
      '请分页或用 Wrap 折行. '
      '(P2-1: ChatGPT 6/17 建议, 老板拍板)',
    );
    // 截断超出上限的项
    final visible = children.length <= maxFocusable
        ? children
        : children.sublist(0, maxFocusable);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: visible,
    );
  }
}

/// TV 焦点 Wrap 布局 — Row 超出上限时自动折行
///
/// 替代 Row + Expanded 组合, 当 children 超出 [maxPerRow] 时自动换行.
/// 每行最多 [maxPerRow] 个焦点项 (默认 9).
class TvFocusCapWrap extends StatelessWidget {
  const TvFocusCapWrap({
    super.key,
    required this.children,
    this.maxPerRow = kTvMaxFocusablePerScreen,
    this.spacing = 8,
    this.runSpacing = 8,
  });

  final List<Widget> children;
  final int maxPerRow;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    assert(
      children.length <= maxPerRow,
      'TV 焦点项 ${children.length} 超出单行上限 $maxPerRow, '
      '会自动折行. 建议分页控制在 $maxPerRow 以内.',
    );
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: children,
    );
  }
}
