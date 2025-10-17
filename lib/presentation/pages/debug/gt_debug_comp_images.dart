import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/enums/overlay_mode.dart';
import 'package:game_tools_lib/core/utils/bounds.dart';
import 'package:game_tools_lib/core/utils/file_utils.dart';
import 'package:game_tools_lib/core/utils/scaled_bounds.dart';
import 'package:game_tools_lib/core/utils/translation_string.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/overlay/ui_elements/compare_image.dart';
import 'package:game_tools_lib/presentation/pages/debug/gt_debug_comp_image_status.dart';
import 'package:game_tools_lib/presentation/pages/debug/gt_debug_page.dart';
import 'package:game_tools_lib/presentation/pages/settings/gt_list_editor.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// Only for testing/debugging used in [GTDebugPage]
final class GTDebugCompImages extends StatefulWidget {
  const GTDebugCompImages({super.key});

  @override
  State<GTDebugCompImages> createState() => _GTDebugCompImagesState();
}

final class _GTDebugCompImagesState extends State<GTDebugCompImages> {
  CompareImage? debugImg;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugImg = CompareImage(
        bounds: ScaledBounds<int>(
          Bounds<int>(x: 711, y: 454, width: 298, height: 239),
          creationWidth: 1096,
          creationHeight: 765,
        ),
        fileName: "debug_img",
      );
      debugImg!.ensureInitialized();
    }); // make sure to load
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GTListEditor<CompareImage>(
      title: TS.raw("Compare Images"),
      description: TS.raw("Edit UI directly with the button, or replace images below"),
      buildEditButtons: false,
      elements: OverlayManager.overlayManager().overlayElements.compareImages,
      onChange: () {},
      buildElement: (BuildContext context, CompareImage element, int elementNumber) {
        final String path = element.unscaledImage.path;
        return Row(
          children: <Widget>[
            Expanded(
              child: GTDebugCompImageStatus(path: path, element: element),
            ),
            const SizedBox(width: 20),
            FilledButton.tonal(
              onPressed: () {
                Logger.verbose("Saving file $path");
                element.storeNewImage();
              },
              child: const Text("Save"),
            ),
            const SizedBox(width: 10),
            FilledButton.tonal(
              onPressed: () {
                final String parentPath = FileUtils.parentPath(path);
                Logger.verbose("Opening $parentPath dir");
                FileUtils.createDirectory(parentPath);
                launchUrlString("file://$parentPath");
              },
              child: const Text("Open Dir"),
            ),
            const SizedBox(width: 15),
          ],
        );
      },
      buildCreateOrEditDialog: (_, _, _, _) => const SizedBox(),
      buildTopActions: (BuildContext context, bool isExpanded) {
        return <Widget>[
          IconButton(
            onPressed: () {
              // temp to pop debug page after editing comp images
              Navigator.pop(context); // todo: MULTI-WINDOW IN THE FUTURE: REMOVE THIS POP
              OverlayManager.overlayManager().changeMode(OverlayMode.EDIT_COMP_IMAGES);
            },
            icon: const Icon(Icons.settings),
            tooltip: TS.raw("Move Compare Images").tl(context),
          ),
        ];
      },
    );
  }
}
