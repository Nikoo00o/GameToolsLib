import 'dart:io';

import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/core/enums/init_result.dart';
import 'package:game_tools_lib/core/utils/translation_string.dart';
import 'package:game_tools_lib/game_tools_lib.dart';

class ErrorApp extends StatelessWidget {
  final InitResult? errorCode;
  final Object? exception;

  const ErrorApp({
    super.key,
    required this.errorCode,
    required this.exception,
  });

  String _errorPart() {
    if (errorCode != null) {
      return "code $errorCode";
    } else if (exception != null) {
      return "exception $exception";
    } else {
      return "unknown";
    }
  }

  String _text() => "Critical startup error: ${_errorPart()}\nPlease look into the logs and restart the app!";

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                _text(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  exit(-1);
                },
                child: const Text("Exit App"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // todo: comment and also implement better when implementing file option
  static Future<void> selectFileAfterLogNotFound() async {
    final FileConfigOption configOption = GameLogWatcher.logWatcher().customUserPath;
    await configOption.onInit();
    await OverlayManager.overlayManager().showCustomDialog<void>(blockTouches: true, (BuildContext context) {
      return AlertDialog(
        title: Text(configOption.title.tl(context)),
        content: configOption.builder.buildProviderWithContent(context, calledFromInnerGroup: false),
        actions: <Widget>[
          ElevatedButton(
            onPressed: () async {
              exit(-1);
            },
            child: Text(const TS("input.ok").tl(context)),
          ),
        ],
      );
    });
  }
}
