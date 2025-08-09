import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game_tools_lib/core/utils/translation_string.dart';
import 'package:game_tools_lib/presentation/base/gt_base_widget.dart';

/// This can be used to get text values from a text field with [T] being either [int], [double], or [String] and
/// build a related text input field for it!
final class SimpleTextField<T> extends StatefulWidget {
  final double width;
  final double height;
  final String initialValue;
  final void Function(String) onChanged;
  final bool autofocus;

  const SimpleTextField({
    required this.width,
    this.height = 40,
    required this.initialValue,
    required this.onChanged,
    this.autofocus = false,
  });

  @override
  State<SimpleTextField<T>> createState() => _SimpleTextFieldState<T>();
}

final class _SimpleTextFieldState<T> extends State<SimpleTextField<T>> with GTBaseWidget {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue.toString());
  }

  @override
  Widget build(BuildContext context) {
    final String hintKey = T == String ? "input.text" : "input.number";
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: TextField(
        autofocus: widget.autofocus,
        controller: _controller,
        maxLines: 1,
        keyboardType: T == String ? null : TextInputType.number,
        inputFormatters: T == String
            ? null
            : <TextInputFormatter>[
                if (T == double) FilteringTextInputFormatter.allow(RegExp(r"(^-?\d*[.,]?\d*)")),
                if (T == int) FilteringTextInputFormatter.allow(RegExp(r"(^-?\d*)")),
              ],
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          hintText: translate(TranslationString(hintKey), context),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          isDense: true,
          filled: true,
          isCollapsed: false,
        ),
      ),
    );
  }
}
