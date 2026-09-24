import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/romaji/kana_romaji.dart';

class TrainerScaffold extends StatefulWidget {
  const TrainerScaffold({
    super.key,
    required this.prompt,
    required this.accepted,
    required this.onCorrect,
    required this.onError,
    required this.onReveal,
    required this.settingsBuilder,
    this.subtitle,
    this.emptyMessage,
  });

  final String? prompt;
  final List<String> accepted;
  final String? subtitle;
  final String? emptyMessage;
  final VoidCallback onCorrect;
  final VoidCallback onError;
  final VoidCallback onReveal;
  final WidgetBuilder settingsBuilder;

  @override
  State<TrainerScaffold> createState() => _TrainerScaffoldState();
}

class _TrainerScaffoldState extends State<TrainerScaffold>
    with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  late final AnimationController _shake;
  late final AnimationController _success;
  String? _revealed;
  bool _green = false;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _success = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestFocus());
  }

  @override
  void didUpdateWidget(covariant TrainerScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.prompt != widget.prompt) {
      _controller.clear();
      _revealed = null;
      _green = false;
      _success.reset();
      WidgetsBinding.instance.addPostFrameCallback((_) => _requestFocus());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    _shake.dispose();
    _success.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.prompt == null) return;
    final text = _controller.text;
    if (text.trim().isEmpty) {
      setState(() {
        _revealed = widget.accepted.isEmpty
            ? null
            : widget.accepted.take(4).map(KanaRomaji.kanaToRomaji).join(' · ');
      });
      widget.onReveal();
      _requestFocus();
      return;
    }
    if (KanaRomaji.matches(text, widget.accepted)) {
      setState(() => _green = true);
      _success.forward(from: 0).whenComplete(() {
        if (mounted) widget.onCorrect();
      });
    } else {
      widget.onError();
      _shake.forward(from: 0);
      _requestFocus();
    }
  }

  Future<void> _openSettings() {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                bottom: MediaQuery.viewInsetsOf(ctx).bottom + 24,
              ),
              child: widget.settingsBuilder(ctx),
            ),
          ),
        );
      },
    ).whenComplete(_requestFocus);
  }

  void _requestFocus() {
    if (!mounted || widget.prompt == null) return;
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prompt = widget.prompt;

    return Column(
      children: [
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: prompt == null
                    ? Text(
                        widget.emptyMessage ??
                            'Нет символов для выбранных настроек.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium,
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              return ScaleTransition(
                                scale: animation,
                                child: child,
                              );
                            },
                            child: GestureDetector(
                              key: ValueKey<String?>(prompt), 
                              onLongPress: () => Clipboard.setData(ClipboardData(text: prompt)),
                              child: SelectableText(
                                prompt,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.displayLarge?.copyWith(
                                  fontSize: 128,
                                  fontWeight: FontWeight.w400,
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ),
                          if (widget.subtitle != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 8),
                              child: Text(
                                widget.subtitle!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          _InputField(
                            controller: _controller,
                            focusNode: _focus,
                            enabled: true,
                            shake: _shake,
                            success: _success,
                            green: _green,
                            onSubmitted: _submit,
                            onTapOutside: (_) => _requestFocus(),
                          ),
                          if (_revealed != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Text(
                                _revealed!,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Настройки тренажёра',
          onPressed: _openSettings,
          icon: const Icon(Icons.keyboard_arrow_up),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.shake,
    required this.success,
    required this.green,
    required this.onSubmitted,
    required this.onTapOutside,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final AnimationController shake;
  final AnimationController success;
  final bool green;
  final VoidCallback onSubmitted;
  final TapRegionCallback onTapOutside;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: Listenable.merge([shake, success]),
      builder: (context, _) {
        final dx = shake.isAnimating
            ? 10 *
                (1 - shake.value) *
                ((shake.value * 8).floor().isEven ? 1 : -1)
            : 0.0;
        final border = green
            ? Color.lerp(scheme.primary, const Color(0xFF2E7D32), 0.85)!
                .withValues(alpha: 0.35 + 0.55 * (1 - success.value))
            : null;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 250,
            ),
            child: TextField(
                controller: controller,
                focusNode: focusNode,
                enabled: enabled,
                autofocus: true,
                textAlign: TextAlign.center,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              enableSuggestions: false,
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'\n')),
              ],
              decoration: InputDecoration(
                hintText: 'Ромадзи',
                border: const OutlineInputBorder(),
                enabledBorder: border == null
                    ? null
                    : OutlineInputBorder(
                        borderSide: BorderSide(color: border, width: 2),
                      ),
                focusedBorder: border == null
                    ? null
                    : OutlineInputBorder(
                        borderSide: BorderSide(color: border, width: 2.4),
                      ),
              ),
              onSubmitted: (_) => onSubmitted(),
              onTapOutside: onTapOutside,
            ),
          ),
        );
      },
    );
  }
}
