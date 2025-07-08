#include "include/game_tools_lib/game_tools_lib_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "game_tools_lib_plugin.h"

void GameToolsLibPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  game_tools_lib::GameToolsLibPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
