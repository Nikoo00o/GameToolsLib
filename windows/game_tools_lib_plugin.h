#ifndef FLUTTER_PLUGIN_GAME_TOOLS_LIB_PLUGIN_H_
#define FLUTTER_PLUGIN_GAME_TOOLS_LIB_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace game_tools_lib {

class GameToolsLibPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  GameToolsLibPlugin();

  virtual ~GameToolsLibPlugin();

  // Disallow copy and assign.
  GameToolsLibPlugin(const GameToolsLibPlugin&) = delete;
  GameToolsLibPlugin& operator=(const GameToolsLibPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace game_tools_lib

#endif  // FLUTTER_PLUGIN_GAME_TOOLS_LIB_PLUGIN_H_
