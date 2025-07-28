import 'package:flutter/material.dart';
import 'package:game_tools_lib/presentation/base/gt_base_widget.dart';

/// Used to display some information together (mostly used in config options)
final class SimpleCard extends StatelessWidget with GTBaseWidget {
  /// Translates and displays a short title translation key in a bigger font
  final String titleKey;

  /// Optional can display 1 to 2 lines of smaller font text as well
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
    final Widget? description = _buildDescription(context);
    return Card(
      child: ListTile(
        dense: false,
        contentPadding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
        leading: null,
        isThreeLine: description != null,
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

  Widget? _buildDescription(BuildContext context) {
    if (descriptionKey != null) {
      return Text(
        translate(context, descriptionKey!),
        maxLines: 2,
        style: textBodySmall(context).copyWith(color: theme(context).colorScheme.onSurfaceVariant),
      );
    } else {
      return null;
    }
  }
}
