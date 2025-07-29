import 'package:flutter/material.dart';
import 'package:game_tools_lib/presentation/base/gt_base_widget.dart';

/// Used to display some information together (mostly used in config options)
final class SimpleCard extends StatelessWidget with GTBaseWidget {
  /// Translates and displays a short title translation key in a bigger font (and also uses the [titleKey] for a
  /// unique [ValueKey])
  final String titleKey;

  /// Optional can display 1 to 2 lines of smaller font text as well (will auto wrap if longer than 90 chars with no \n)
  final String? descriptionKey;

  /// This contains the card specific actions at the right side
  final Widget trailingActions;

  const SimpleCard({
    required this.titleKey,
    this.descriptionKey,
    required this.trailingActions,
  });

  @override
  Widget build(BuildContext context) {
    final (Widget? description, int lines) = _buildDescription(context);
    return Card(
      key: ValueKey<String>(titleKey),
      child: ListTile(
        dense: false,
        contentPadding: const EdgeInsets.fromLTRB(10, 0, 8, 0),
        leading: null,
        isThreeLine: lines == 2,
        title: Text(
          translate(context, titleKey),
          maxLines: 1,
          style: textTitleMedium(context),
        ),
        subtitle: description,
        trailing: trailingActions,
        enabled: true,
      ),
    );
  }

  (Widget?, int) _buildDescription(BuildContext context) {
    if (descriptionKey != null) {
      String text = translate(context, descriptionKey!);
      final bool hasLineBreak = text.contains("\n");
      int lines = hasLineBreak ? 2 : 1;
      if (text.length > 90 && hasLineBreak == false) {
        for (int i = 90; i >= 0; i--) {
          if (text[i] == " ") {
            final StringBuffer buff = StringBuffer();
            buff.write(text.substring(0, i));
            buff.write("\n");
            buff.write(text.substring(i + 1));
            text = buff.toString();
            break;
          }
        }
        lines = 2;
      }

      final Widget widget = Text(
        text,
        maxLines: lines,
        overflow: TextOverflow.ellipsis,
        style: textBodySmall(context).copyWith(color: colorOnSurfaceVariant(context)),
      );
      return (widget, lines);
    } else {
      return (null, 1);
    }
  }
}
