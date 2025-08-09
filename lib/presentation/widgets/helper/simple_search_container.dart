import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/utils/translation_string.dart';
import 'package:game_tools_lib/presentation/base/gt_base_widget.dart';
import 'package:game_tools_lib/presentation/base/ui_helper.dart';

/// Builds a search bar that modifies a string provided further up
class SimpleSearchContainer extends StatelessWidget with GTBaseWidget {
  final double width;
  final double height;
  final TranslationString hintText;

  const SimpleSearchContainer({
    this.width = 280,
    this.height = 40,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: TextField(
        maxLines: 1,
        onChanged: (String newSearchText) => UIHelper.modifySimpleValue<String>(context).value = newSearchText,
        decoration: InputDecoration(
          isDense: true,
          prefixIcon: const Icon(Icons.search),
          hintText: translate(hintText, context),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(32)),
          fillColor: colorSurfaceContainer(context),
          filled: true,
        ),
      ),
    );
  }
}
