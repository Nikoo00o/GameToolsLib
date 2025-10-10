import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game_tools_lib/core/enums/input/input_enums.dart';
import 'package:game_tools_lib/core/utils/translation_string.dart';
import 'package:game_tools_lib/domain/game/game_window.dart';
import 'package:game_tools_lib/presentation/base/gt_base_widget.dart';

/// Used to configure config fields
class GTHotkeyField extends StatefulWidget {
  final BoardKey? initialValue;
  final void Function(BoardKey?) onChanged;

  const GTHotkeyField({super.key, required this.initialValue, required this.onChanged});

  @override
  State<GTHotkeyField> createState() => _GTHotkeyFieldState();
}

class _GTHotkeyFieldState extends State<GTHotkeyField> with GTBaseWidget {
  FocusNode focusNode = FocusNode();

  /// when user is currently entering key
  bool isInputting = false;

  /// needs to be cached with the down states
  LogicalKeyboardKey? keyPressed;

  bool shiftDown = false;
  bool ctrlDown = false;
  bool altDown = false;
  bool metaDown = false;

  /// The BoardKey used
  BoardKey? boardKey;

  String? character;

  @override
  void initState() {
    super.initState();
    boardKey = widget.initialValue;
    focusNode.addListener(onFocusChange);
  }

  @override
  void dispose() {
    focusNode.removeListener(onFocusChange);
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      onTapInside: (PointerDownEvent event) => focusNode.requestFocus(),
      onTapOutside: (PointerDownEvent event) => focusNode.unfocus(),
      child: KeyboardListener(
        focusNode: focusNode,
        onKeyEvent: onKeyEvent,
        child: Container(
          width: 250,
          height: 30,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(
              Radius.circular(20.0),
            ),
            color: isInputting ? colorPrimary(context) : colorPrimaryContainer(context),
          ),
          child: Center(
            child: buildTextForState(context),
          ),
        ),
      ),
    );
  }

  Widget buildTextForState(BuildContext context) {
    if (isInputting) {
      return Text(
        const TS("page.hotkeys.clear.esc").tl(context),
        style: textLabelSmall(context).copyWith(color: colorOnPrimary(context)),
      );
    } else if (boardKey != null) {
      return Text(boardKey!.keyCombinationText, style: textBodyMedium(context).copyWith(fontWeight: FontWeight.bold));
    } else {
      return Text(
        const TS("page.hotkeys.not.set").tl(context),
        style: textBodyMedium(context).copyWith(color: colorError(context)).copyWith(fontWeight: FontWeight.bold),
      );
    }
  }

  void onFocusChange() {
    setState(() {
      isInputting = focusNode.hasFocus;
    });
  }

  void setBoardKey() {
    setState(() {
      if (isInputting) {
        isInputting = false;
        if (keyPressed == null) {
          boardKey = null;
        } else {
          boardKey = BoardKey(
            keyPressed!,
            withShift: shiftDown ? shiftDown : null,
            withControl: ctrlDown ? ctrlDown : null,
            withAlt: altDown ? altDown : null,
            withMeta: metaDown ? metaDown : null,
            keyTextHint: character,
          );
        }
        shiftDown = false;
        ctrlDown = false;
        altDown = false;
        metaDown = false;
        keyPressed = null;
        character = null;
        focusNode.unfocus();
        widget.onChanged(boardKey);
      }
    });
  }

  bool _setModifierForEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      return true;
    } else if (event is KeyUpEvent) {
      return keyPressed != null;
    }
    return false;
  }

  void onKeyEvent(KeyEvent event) {
    final LogicalKeyboardKey key = event.logicalKey;
    if (key.isAnyShift) {
      shiftDown = _setModifierForEvent(event);
    } else if (key.isAnyControl) {
      ctrlDown = _setModifierForEvent(event);
    } else if (key.isAnyAlt) {
      altDown = _setModifierForEvent(event);
    } else if (key.isAnyMeta) {
      metaDown = _setModifierForEvent(event);
    } else if (event is KeyDownEvent) {
      keyPressed = key;
      character = event.character;
    } else if (event is KeyUpEvent) {
      if (key == BoardKey.escape.logicalKey) {
        keyPressed = null;
        setBoardKey();
      } else if (key == keyPressed) {
        setBoardKey();
      }
    }
  }
}
